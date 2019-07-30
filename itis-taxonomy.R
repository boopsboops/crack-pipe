#!/usr/bin/env Rscript

library("taxize")
library("ape")
library("tidyverse")
library("parallel")
library("magrittr")

# R script to run a hidden markov model on a sequence
run_hmmer3 <- function(dir, infile, hmm, prefix, evalue, coords){#
    string.hmmer <- paste0("nhmmer -E ", evalue, " --incE ", evalue, " --dfamtblout ", dir, "/", prefix, ".hmmer.tbl ", "assets/", prefix, ".hmm ", dir, "/", infile)
    system(command=string.hmmer, ignore.stdout=TRUE)
    hmm.tbl <- read_delim(file=paste0(dir, "/", prefix, ".hmmer.tbl"), delim=" ", col_names=FALSE, trim_ws=TRUE, progress=FALSE, comment="#", col_types=cols(), guess_max=100000)
    names(hmm.tbl) <- c("targetName","acc","queryName","bits","eValue","bias","hmmStart","hmmEnd","strand","aliStart","aliEnd","envStart","envEnd","sqLen","descriptionTarget")
    hmm.tbl %<>% filter(strand=="+") %>% distinct(targetName, .keep_all=TRUE) %>% mutate(coords=paste(envStart,envEnd,sep=":"))
    mtdna <- read.FASTA(file=paste0(dir,"/",infile))
    mtdna.sub <- as.character(mtdna[match(hmm.tbl$targetName,names(mtdna))])
    if(coords=="env"){
    mtdna.sub.coords <- as.DNAbin(mapply(function(x,y,z) x[y:z], mtdna.sub, hmm.tbl$envStart, hmm.tbl$envEnd, SIMPLIFY=TRUE, USE.NAMES=TRUE))
    } else if(coords=="ali"){
    mtdna.sub.coords <- as.DNAbin(mapply(function(x,y,z) x[y:z], mtdna.sub, hmm.tbl$aliStart, hmm.tbl$aliEnd, SIMPLIFY=TRUE, USE.NAMES=TRUE))
    } else {
    stop("Please provide 'env' or 'ali' as arguments to coords")
    }
    return(mtdna.sub.coords)
}

# read in mtDNA, save hmm frag
refseq.frag <- run_hmmer3(dir="temp/reference-library", infile="temp/reference-library/mitochondrion.genomic.fna", prefix="12s.miya.primers", evalue="10", coords="env")
write.FASTA(refseq.frag, file="temp/reference-library/refseq.frag.fasta")

# run cutadapt from R
cut.com <- "cutadapt -n 1 -e 0.3 -O 10 -g GTCGGTAAAACTCGTGCCAGC --discard-untrimmed reflib/refseq.frag.fasta | cutadapt --minimum-length 120 -n 1 -e 0.3 -O 10 -a CAAACTGGGATTAGATACCCCACTATG --discard-untrimmed -o reflib/refseq.frag.trimmed.fasta - "
system(command=cut.com, ignore.stdout=TRUE)

# read in the trimmed reflib
mt <- read.FASTA("temp/reference-library/refseq.frag.trimmed.fasta")
accs <- names(mt)#str_split_fixed(names(mt)," ",2)[,1]

# get genbank gis
gis <- genbank2uid(accs)
length(gis) == length(accs)
table(sapply(gis, function(x) grepl("Error",x)[1]))
gis.list <- mapply(function(x) x[1], gis, USE.NAMES=FALSE)

# get ncbi species
ncbi.tables <- classification(gis.list,db="ncbi")
length(gis) == length(ncbi.tables)
ncbi.tables.merged <- as_tibble(rbind(ncbi.tables))
ncbi.tables.merged %<>% filter(rank=="species") %>% rename(gi=query)

# merge tables
ncbi.tables.merged <- left_join(tibble(accession=accs,gi=gis.list), ncbi.tables.merged) %>% filter(!is.na(name))

# get itis taxonomy and merge
itis.tables <- classification(pull(ncbi.tables.merged,name), db="itis")
itis.tables.merged <- as_tibble(rbind(itis.tables))

# pull out ranks
itis.tables.merged %<>% group_by(query) %>% 
    mutate(fullTax=if_else("kingdom"%in%rank & "phylum"%in%rank & "class"%in%rank & "order"%in%rank & "family"%in%rank & "genus"%in%rank,TRUE,FALSE)) %>% 
    filter(fullTax==TRUE) %>% 
    ungroup()
    
# trim and spread
itis.tables.merged %<>% 
    select(name,rank,query) %>% 
    distinct() %>% 
    spread(key=rank,value=name) %>%
    select(query,kingdom,phylum,class,order,family,genus) %>% 
    rename(species=query)

# reduce and rename
ncbi.tables.merged %<>% select(accession,gi,name) %>%
    rename(species=name) 

# join and arrange
taxonomy.table <- left_join(ncbi.tables.merged, itis.tables.merged) %>% filter(!is.na(kingdom)) %>% arrange(kingdom,phylum,class,order,family,genus,species)

# write out 
write_csv(taxonomy.table, path="assets/taxonomy-table.csv")
# read in
taxonomy.table <- read_csv(file="assets/taxonomy-table.csv")

# rename teleosts and elasmos to match fishbase if required
taxonomy.table %<>% mutate(class=str_replace_all(class,"Chondrichthyes","Elasmobranchii"), class=str_replace_all(class,"Teleostei","Actinopterygii"))

# create the labels
taxonomy.table %<>% mutate(label=paste0(accession,";tax=k:",kingdom,",p:",phylum,",c:",class,",o:",order,",f:",family,",g:",genus,",s:",species)) %>% mutate(label=str_replace_all(label," ","_"))

# subset the mtDNA and rename
mt.sub <- mt[which(names(mt) %in% pull(taxonomy.table,accession))]
names(mt.sub) <- pull(taxonomy.table,label)[match(names(mt.sub), pull(taxonomy.table,accession))]

# write out 
write.FASTA(mt.sub,file="temp/reference-library/refseq-mtdna-with-taxonomy.fasta")
# copy into assets
