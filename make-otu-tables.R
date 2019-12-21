#!/usr/bin/env Rscript
suppressMessages(library("ape"))
suppressMessages(library("tidyverse"))
suppressMessages(library("parallel"))
suppressMessages(library("magrittr"))
# ./make-otu-table.R

# load drep fasta and clean
fas.list <- list.files(path="temp/dereplicated",pattern=".fasta")
fas.all <- mcmapply(function(x) read.FASTA(file=x), paste0("temp/dereplicated/",fas.list), mc.cores=4)
names(fas.all) <- str_replace_all(fas.list,".fasta","")

# extract names and adundances per sample
samples.tabulated <- mcmapply(function(x,y) tibble(md5=str_split_fixed(names(x),";size=",2)[,1], size=str_split_fixed(names(x),";size=",2)[,2], sample=y), fas.all, names(fas.all), mc.cores=4, SIMPLIFY=FALSE)
samples.tabulated.joined <- bind_rows(samples.tabulated)

# load up swarm results 
swarms <- read_lines(file="temp/clustered/swarm.clusters.tsv",)
mothers <- mcmapply(function(x) x[1], str_split(swarms," "), mc.cores=4)
daughters <- mcmapply(function(x) paste(x[-1],collapse=" "), str_split(swarms," "), mc.cores=4)

# make a nested table of daughters and then flatten
daughters.unlist <- mcmapply(function(x) unlist(str_split(x," ",simplify=FALSE)), daughters, mc.cores=4, USE.NAMES=FALSE)
all.swarms <- tibble(mother=mothers, daughter=daughters.unlist) %>% unnest(cols=c(daughter))

# collapse and join by sample
samples.merged <- samples.tabulated.joined %>% 
    mutate(mother=all.swarms$mother[match(md5,all.swarms$daughter)]) %>% 
    mutate(mother=if_else(is.na(mother),md5,mother)) %>% 
    group_by(sample,mother) %>% 
    summarise(sum=sum(as.numeric(size))) %>%
    ungroup()

# load up the final cleaned reads
keeps <- read.FASTA(file="results/cleaned-reads.fasta")
keeps.names <- str_replace_all(names(keeps),";size=[0-9]*","")

# filter just good seqs
samples.kept <- samples.merged %>% filter(mother %in% keeps.names) 

# check numbers are the same
#print("read numbers are the same?")
#samples.kept %>% pull(sum) %>% sum == sum(as.numeric(str_replace_all(names(keeps),".*;size=","")))

# read in samples df to check for missing samples with zero reads
samples.df <- suppressMessages(suppressWarnings(read_csv("temp/samples/sample-plates.csv")))

# make an id
samples.df %<>% mutate(sample=paste(well,sampleID,sep="."))

# get the ones that are not present in the otus
samples.missing <- samples.df %>% filter(!sample %in% unique(pull(samples.kept,sample))) %>% select(sample) %>% mutate(mother=NA,sum=0)

# add them
samples.kept %<>% bind_rows(samples.missing)

# create an otu table and write out
samples.kept %>% spread(key=sample,value=sum,fill=0) %>%
    filter(!is.na(mother)) %>%
    write_csv(path="results/otu-table-raw.csv")

# read in taxonomy assignment
tax.ass.df <- suppressMessages(suppressWarnings(read_tsv(file="temp/blast-dump/sintax-output.tsv",col_names=c("otu","idsProbs","strand","ids"),guess_max=999999)))

# clean md5 and extract best IDs
tax.ass.df %<>% mutate(md5=str_replace_all(otu,";size=[0-9]*",""), size=as.numeric(str_replace_all(otu,".*;size=","")), bestId=str_replace_all(map(str_split(pull(tax.ass.df,ids),":"), last),"_"," ")) %>% 
    mutate(isFish=if_else(grepl("Cephalaspidomorphi",idsProbs) | grepl("Elasmobranchii",idsProbs) | grepl("Actinopterygii",idsProbs), TRUE, FALSE))

# add BLAST results
# load blast result
local.db.blast <- suppressMessages(suppressWarnings(read_tsv("temp/blast-dump/blast-result.tsv",guess_max=999999)))

# add taxonomy
custom.db <- suppressMessages(suppressWarnings(read_csv("temp/reference-library/custom-references-annotated.csv",guess_max=999999)))
refseq.db <- suppressMessages(suppressWarnings(read_csv("assets/taxonomy-table.csv")))

custom.db %<>% select(code,sciName) %>% rename(gi=code,species=sciName)
refseq.db %<>% select(gi,species) %>% mutate(gi=as.character(gi))
combined.db <- bind_rows(custom.db,refseq.db)

# annotate species names
local.db.blast %<>% mutate(sciName=pull(combined.db,species)[match(sseqidLocal,pull(combined.db,gi))])

# chose "best" hit based on bitscore
# also add scinames
local.db.blast.sorted <- local.db.blast %>% 
    group_by(qseqid) %>%
    arrange(desc(bitscoreLocal),.by_group=TRUE) %>%
    filter(bitscoreLocal==max(bitscoreLocal)) %>%
    arrange(sciName,.by_group=TRUE) %>%
    mutate(sciName=paste(unique(sciName),collapse="; ")) %>%
    slice(1) %>% 
    ungroup()

# add to results df
tax.ass.df %<>% mutate(blastId=pull(local.db.blast.sorted,sciName)[match(otu,pull(local.db.blast.sorted,qseqid))],
    matchLength=pull(local.db.blast.sorted,lengthLocal)[match(otu,pull(local.db.blast.sorted,qseqid))],
    identity=pull(local.db.blast.sorted,pidentLocal)[match(otu,pull(local.db.blast.sorted,qseqid))]) 

# write out
tax.ass.df %>% select(md5,size,bestId,matchLength,identity,blastId) %>% 
    arrange(bestId,desc(size)) %>% 
    write_csv("results/taxonomy-assignments.tsv")

# match to OTU table
assigned.all <- samples.kept %>% mutate(assignment=pull(tax.ass.df,bestId)[match(mother,pull(tax.ass.df,md5))]) %>%
    mutate(isFish=pull(tax.ass.df,isFish)[match(mother,pull(tax.ass.df,md5))]) %>%
    mutate(assignment=if_else(is.na(assignment),"unassigned",assignment)) 

# collapse by ID
assigned.all %>%
    group_by(sample,assignment) %>%
    summarise(sum=sum(sum)) %>% 
    ungroup() %>% 
    spread(key=sample,value=sum,fill=0) %>% 
    write_csv(path="results/otu-table-all.csv")

# fish only, and collapse by all
assigned.all %>%
    mutate(assignment=if_else(isFish==TRUE,assignment,"NA"),sum=if_else(isFish==TRUE,sum,0)) %>%
    group_by(sample,assignment) %>%
    summarise(sum=sum(sum)) %>%
    ungroup() %>% 
    spread(key=sample,value=sum,fill=0) %>% 
    filter(assignment!="NA") %>%
    write_csv(path="results/otu-table-fish.csv")

# get total number fish reads
assigned.all %>%
    filter(isFish==TRUE) %>%
    pull(sum) %>%
    sum() %>% 
    write("temp/reference-library/nfishreads.txt")

# make an annotated raw table combining assigments
samples.kept %>% spread(key=sample,value=sum,fill=0) %>% 
    mutate(size=pull(tax.ass.df,size)[match(mother,pull(tax.ass.df,md5))],
    bestId=pull(tax.ass.df,bestId)[match(mother,pull(tax.ass.df,md5))],
    matchLength=pull(tax.ass.df,matchLength)[match(mother,pull(tax.ass.df,md5))],
    identity=pull(tax.ass.df,identity)[match(mother,pull(tax.ass.df,md5))],
    blastId=pull(tax.ass.df,blastId)[match(mother,pull(tax.ass.df,md5))]) %>% 
    select(mother,size,bestId,matchLength,identity,blastId,everything()) %>%
    arrange(bestId,desc(size)) %>%
    filter(!is.na(mother)) %>%
    write_csv(path="results/otu-table-raw-annotated.csv")
