#!/usr/bin/env Rscript

# load libs
suppressMessages(library("tidyverse"))
suppressMessages(library("lulu"))

# install
#library("devtools")
#install_github("tobiasgf/lulu")

# load otu table using base R!
otutab <- read.csv("results/otu-table-raw.csv",sep=",",header=TRUE,as.is=TRUE,row.names=1)

# load blast table using base R!
matchlist <- read.table("temp/blast-dump/reads-blasted.tsv",sep="\t",header=FALSE,as.is=TRUE,stringsAsFactors=FALSE)

# fix the names
matchlist[,1] <- str_split_fixed(matchlist[,1],";",2)[,1]
matchlist[,2] <- str_split_fixed(matchlist[,2],";",2)[,1]

# run lulu
curated.result <- lulu(otutab,matchlist)

writeLines("\n\n\n\nNumber OTUs kept by lulu:")
curated.result$curated_count

writeLines("\nNumber OTUs discarded by lulu:")
curated.result$discarded_count

# read in taxon data
tax.ass.df <- suppressMessages(suppressWarnings(read_csv("results/taxonomy-assignments.tsv")))

# make an annotated raw table combining assigments
curated.result$curated_table %>% rownames_to_column(var="mother") %>% as_tibble() %>% 
    mutate(size=pull(tax.ass.df,size)[match(mother,pull(tax.ass.df,md5))],
    bestId=pull(tax.ass.df,bestId)[match(mother,pull(tax.ass.df,md5))],
    matchLength=pull(tax.ass.df,matchLength)[match(mother,pull(tax.ass.df,md5))],
    identity=pull(tax.ass.df,identity)[match(mother,pull(tax.ass.df,md5))],
    blastId=pull(tax.ass.df,blastId)[match(mother,pull(tax.ass.df,md5))]) %>% 
    select(mother,size,bestId,matchLength,identity,blastId,everything()) %>%
    arrange(bestId,desc(size)) %>%
    write_csv(path="results/otu-table-raw-annotated-lulu.csv")
