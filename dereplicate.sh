#!/usr/bin/env sh

# qc filter
FILES="$(ls temp/trimmed/*.fastq.gz | sed --expression='s/\.merged\.fastq\.gz//g' | sed --expression='s/temp\/trimmed\///g')"
# check
for f in $FILES; do echo "$f"; done
# now run
for i in $FILES; do
    vsearch --fastq_filter temp/trimmed/"$i".merged.fastq.gz --fastq_maxee 2 --fastq_minlen 105 --fastq_maxlen 200 --fastq_maxns 0 --fastaout temp/filtered/"$i".fasta --fasta_width 0 &
done; wait

# derep
FILES="$(ls temp/filtered/*.fasta | sed --expression='s/\.fasta//g' | sed --expression='s/temp\/filtered\///g')"
# check
for f in $FILES; do echo "$f"; done
# now run
for i in $FILES; do
    vsearch --derep_fulllength temp/filtered/"$i".fasta --minuniquesize 1 --output temp/dereplicated/"$i".fasta --relabel_md5 --sizeout --fasta_width 0 &
done; wait

# ./dereplicate.sh