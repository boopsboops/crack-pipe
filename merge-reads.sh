#!/usr/bin/env sh

while getopts t:f:r: option
do
case "${option}"
in
f) R1=${OPTARG};;
r) R2=${OPTARG};;
t) THREADS=${OPTARG};;
esac
done

# run pear and gzip results
pear -j "$THREADS" -f "$R1" -r "$R2" -o temp/merged/reads
gzip temp/merged/reads.assembled.fastq

# ./merge-reads.sh -f temp/fastq/12S-mifishu-R1.fastq.gz -r temp/fastq/12S-mifishu-R2.fastq.gz
