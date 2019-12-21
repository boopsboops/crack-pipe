#!/usr/bin/env sh

# set params #
while getopts t:f:r: option
do
case "${option}"
in
f) FWD=${OPTARG};;
r) REVCOMP=${OPTARG};;
t) THREADS=${OPTARG};;
e) ERR=${OPTARG};;
esac
done

# split the FASTQ
# create tmp folders
#THREADS=8
for i in `seq 1 "$THREADS"`; do
  mkdir temp/demultiplexed/reorientated.part_00"$i"
done

# split the files
# https://bioinf.shenwei.me/seqkit/
seqkit split2 -f temp/reorientated/reorientated.fastq.gz -p "$THREADS" 

# get file names - also see `basename`
FILES="$(ls temp/reorientated/reorientated.fastq.gz.split/*.fastq.gz | sed -e 's/\.fastq\.gz//g' | sed -e 's/temp\/reorientated\/reorientated.split\///g')"

# run demultiplex loop
for i in $FILES; do 
cutadapt --no-indels --error-rate "$ERR" --overlap 10 --action=none -g file:temp/samples/barcodes.fas -o temp/demultiplexed/"$i"/{name}.fastq.gz --discard-untrimmed temp/reorientated/reorientated.fastq.gz.split/"$i".fastq.gz &
done; wait

# now cat all of the files back into the same files - 
find temp/demultiplexed -type f -name "*.fastq.gz" | while read F; do basename ${F%.fastq.gz}; done | sort | uniq | while read P; do find temp/demultiplexed/reorientated* -type f -name "${P}*.fastq.gz" -exec cat '{}' ';' > temp/demultiplexed/${P}.merged.fastq.gz; done

# trim with cutadapt
FILES="$(ls temp/demultiplexed/*.fastq.gz | sed -e 's/\.fastq\.gz//g' | sed -e 's/temp\/demultiplexed\///g')"

# check
#for j in $FILES; do echo "$j"; done
# now run
for i in $FILES; do 
cutadapt -n 5 --error-rate 0.15 -g "$FWD" --discard-untrimmed temp/demultiplexed/"$i".fastq.gz | cutadapt -n 5 --error-rate 0.15 -a "$REVCOMP" -o temp/trimmed/"$i".fastq.gz --discard-untrimmed - &
done; wait

printf "...\n...\n...\nFinished!\n"

# ./demultiplex.sh -t 8 -f GTCGGTAAAACTCGTGCCAGC -r CAAACTGGGATTAGATACCCCACTATG
