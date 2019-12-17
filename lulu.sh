#!/usr/bin/env sh

# copy file 
cp results/cleaned-reads.fasta temp/blast-dump/cleaned-reads.fasta

# make db
makeblastdb -in temp/blast-dump/cleaned-reads.fasta -parse_seqids -dbtype nucl

# blast 
blastn -db temp/blast-dump/cleaned-reads.fasta -outfmt '6 qseqid sseqid pident' -out temp/blast-dump/reads-blasted.tsv -qcov_hsp_perc 80 -perc_identity 84 -query temp/blast-dump/cleaned-reads.fasta

# run lulu
./lulu.R

# clean up after lulu
mv lulu.log* temp/blast-dump
