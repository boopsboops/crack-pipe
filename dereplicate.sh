#!/usr/bin/env sh

# set params #
while getopts e:a:p: option
do
case "${option}"
in
a) AVG=${OPTARG};;
p) PROP=${OPTARG};;
e) MEE=${OPTARG};;
esac
done

MINLEN=$(awk "function ceil(x, y){y=int(x); return(x>y?y+1:y)} BEGIN { pc=${AVG}-${AVG}*${PROP}; i=ceil(pc); print i }")
MAXLEN=$(awk "function ceil(x, y){y=int(x); return(x>y?y+1:y)} BEGIN { pc=${AVG}+${AVG}*${PROP}; i=ceil(pc); print i }")

# qc filter
FILES="$(ls temp/trimmed/*.fastq.gz | sed --expression='s/\.merged\.fastq\.gz//g' | sed --expression='s/temp\/trimmed\///g')"
# check
#for f in $FILES; do echo "$f"; done
# now run
for i in $FILES; do
    vsearch --fastq_filter temp/trimmed/"$i".merged.fastq.gz --fastq_maxee "$MEE" --fastq_minlen "$MINLEN" --fastq_maxlen "$MAXLEN" --fastq_maxns 0 --fastaout temp/filtered/"$i".fasta --fasta_width 0 &
done; wait

# derep
FILES="$(ls temp/filtered/*.fasta | sed --expression='s/\.fasta//g' | sed --expression='s/temp\/filtered\///g')"
# check
#for f in $FILES; do echo "$f"; done
# now run
for i in $FILES; do
    vsearch --derep_fulllength temp/filtered/"$i".fasta --minuniquesize 1 --output temp/dereplicated/"$i".fasta --relabel_md5 --sizeout --fasta_width 0 &
done; wait

#printf "...\n...\n...\nFinished!\n"
printf "...\nMinimum length of fragment is: $MINLEN bp\n"
printf "...\nMaximum length of fragment is: $MAXLEN bp\n"

# ./dereplicate.sh -a 170 -p 0.15
