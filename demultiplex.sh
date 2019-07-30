#!/usr/bin/env sh

# set params #
while getopts f:r: option
do
case "${option}"
in
f) FWD=${OPTARG};;
r) REVCOMP=${OPTARG};;
esac
done

# dmplx
cutadapt --no-indels --error-rate 0.1 --overlap 10 --action=none -g file:temp/fastq/barcodes.fas -o temp/demultiplexed/{name}.fastq.gz --untrimmed-output temp/trash/nofwdbarcode.fastq.gz temp/reorientated/reorientated.fastq.gz

# trim with cutadapt
FILES="$(ls temp/demultiplexed/*.fastq.gz | sed --expression='s/\.fastq\.gz//g' | sed --expression='s/unknown//g' | sed --expression="s/temp\/demultiplexed\///g" | uniq)"

# check
#for j in $FILES; do echo "$j"; done
# now run
#for i in $FILES; do 
#cutadapt -n 5 --error-rate 0.15 -g "$FWD" -a "$REVCOMP" -o temp/trimmed/"$i".fastq.gz --discard-untrimmed temp/demultiplexed/"$i".fastq.gz &
#done; wait
for i in $FILES; do 
cutadapt -n 5 --error-rate 0.15 -g "$FWD" --discard-untrimmed temp/demultiplexed/"$i".fastq.gz | cutadapt -n 5 --error-rate 0.15 -a "$REVCOMP" -o temp/trimmed/"$i".fastq.gz --discard-untrimmed - &
done; wait

# ./demultiplex.sh -f GTCGGTAAAACTCGTGCCAGC -r CAAACTGGGATTAGATACCCCACTATG

