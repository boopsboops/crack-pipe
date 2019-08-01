#!/usr/bin/env sh

while getopts f: option
do
case "${option}"
in
f) R1=${OPTARG};;
esac
done

printf "Total number raw reads:\n"
seqkit stats -b "$R1"
printf "\n\n"

printf "Total number merged reads:\n"
seqkit stats -b temp/merged/merged.fastq.gz
printf "\n\n"

printf "Total number reorientated reads:\n"
seqkit stats -b temp/reorientated/reorientated.fastq.gz
printf "\n\n"

printf "Total number demultiplexed reads:\n"
cat temp/demultiplexed/*.fastq.gz | seqkit stats
printf "\n\n"

printf "Total number trimmed reads:\n"
cat temp/trimmed/*.fastq.gz | seqkit stats
printf "\n\n"

printf "Total number filtered reads:\n"
cat temp/filtered/*.fasta | seqkit stats
printf "\n\n"

printf "Total number cleaned reads:\n"
grep ";size=" results/cleaned-reads.fasta | sed -e 's/.*;size=//g' | awk '{ SUM += $1} END { print SUM }'
printf "\n\n"

printf "Total number fish reads:\n"
cat temp/reference-library/nfishreads.txt
printf "\n\n"

# ./generate-stats.sh -f temp/fastq/12S-mifishu-R1.fastq.gz
