#!/usr/bin/env Rscript

# load libs
library("ape")
library("tidyverse")
library("magrittr")

# load spreadsheet of samples
samples.df <- suppressMessages(suppressWarnings(read_csv("temp/user-data/sample-plates.csv")))

# trim barcodes to 10 bp
samples.df %<>% mutate(barcodesFwd=str_replace_all(oligoFwd,"N",""), 
    barcodesFwd=str_trunc(barcodesFwd, width=10, side="right", ellipsis=""),
    barcodesRev=str_replace_all(oligoRev,"N",""),
    barcodesRev=str_trunc(barcodesRev, width=10, side="right", ellipsis=""),
    labelFwd=paste(well,sampleID,sep="."))

# now revcomp the rev barcodes
barcodes.rev <- as.DNAbin(strsplit(pull(samples.df,barcodesRev),""))
barcodes.revcomp <- toupper(mapply(paste,collapse="",as.character(ape::complement(barcodes.rev)),SIMPLIFY=TRUE,USE.NAMES=FALSE))

# add to df
samples.df %<>% mutate(barcodesRevComp=barcodes.revcomp)
    
# assemble a fasta for barcodes
barcodes.lines <- paste0(">",pull(samples.df,well),".",pull(samples.df,sampleID),"\n",pull(samples.df,barcodesFwd),"...",pull(samples.df,barcodesRevComp))

# write out
writeLines(barcodes.lines,con="temp/samples/barcodes.fas")
