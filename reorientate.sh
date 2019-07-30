#!/usr/bin/env sh

# set params #
while getopts f:r:m:n: option
do
case "${option}"
in
f) FWD=${OPTARG};;
r) REV=${OPTARG};;
m) MINLENF=${OPTARG};;
n) MINLENR=${OPTARG};;
esac
done

# MIYA
#FWD="GTCGGTAAAACTCGTGCCAGC"
#REV="CATAGTGGGGTATCTAATCCCAGTTTG"
#REVCOMP="CAAACTGGGATTAGATACCCCACTATG"
#MINLEN="21"

# extract fwd and rev
cutadapt --error-rate 0.15 --overlap "$MINLENF" --action=none -g fwd="$FWD" --untrimmed-output temp/trash/nofwd.fastq.gz -o temp/trash/fwd.fastq.gz temp/merged/reads.assembled.fastq.gz
cutadapt --error-rate 0.15 --overlap "$MINLENR" --action=none -g rev="$REV" --untrimmed-output temp/trash/norev.fastq.gz -o temp/trash/rev.fastq.gz temp/trash/nofwd.fastq.gz

# revcomp the rev
vsearch --fastx_revcomp temp/trash/rev.fastq.gz --fastqout temp/trash/rev.revcomp.fastq
gzip temp/trash/rev.revcomp.fastq
# join 
cat temp/trash/fwd.fastq.gz temp/trash/rev.revcomp.fastq.gz > temp/reorientated/reorientated.fastq.gz

# ./reorientate.sh -f GTCGGTAAAACTCGTGCCAGC -r CATAGTGGGGTATCTAATCCCAGTTTG -m 21 -n 27
