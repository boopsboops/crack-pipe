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
all.swarms <- tibble(mother=mothers, daughter=daughters.unlist) %>% unnest()

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
print("read numbers are the same?")
samples.kept %>% pull(sum) %>% sum == sum(as.numeric(str_replace_all(names(keeps),".*;size=","")))

# create an otu table and write out
samples.kept %>% spread(key=sample,value=sum,fill=0) %>%
    write_csv(path="results/otu-table-raw.csv")


# read in taxonomy assignment
tax.ass.df <- suppressMessages(suppressWarnings(read_tsv(file="results/taxonomy-assignments.tsv",col_names=c("md5","idsProbs","strand","ids"))))

# clean md5 and extract best IDs
tax.ass.df %<>% mutate(md5=str_replace_all(md5,";size=[0-9]*",""), bestId=str_replace_all(map(str_split(tax.ass.df$ids,":"), last),"_"," ")) %>% 
    mutate(isFish=if_else(grepl("Cephalaspidomorphi",idsProbs) | grepl("Elasmobranchii",idsProbs) | grepl("Actinopterygii",idsProbs), TRUE, FALSE))

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
    filter(isFish==TRUE) %>%
    group_by(sample,assignment) %>%
    summarise(sum=sum(sum)) %>%
    ungroup() %>% 
    spread(key=sample,value=sum,fill=0) %>% 
    write_csv(path="results/otu-table-fish.csv")

# get total number fish reads
assigned.all %>%
    filter(isFish==TRUE) %>%
    pull(sum) %>%
    sum() %>% 
    write("temp/reference-library/nfishreads.txt")