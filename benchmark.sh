#!/usr/bin/env sh

#./prepare.sh

./merge-reads.sh -t 8 -f temp/fastq/12S-mifishu-benchmark-R1.fastq.gz -r temp/fastq/12S-mifishu-benchmark-R2.fastq.gz

./reorientate.sh -f GTCGGTAAAACTCGTGCCAGC -r CATAGTGGGGTATCTAATCCCAGTTTG -m 21 -n 27

./demultiplex.sh -t 8 -f GTCGGTAAAACTCGTGCCAGC -r CAAACTGGGATTAGATACCCCACTATG

./dereplicate.sh -a 170 -p 0.15 -e 0.5

./cluster.sh -t 8 -u 0.000005

./annotate-taxonomy.R

./assign-taxonomy.sh -t 8 -a 170 -p 0.7 -c 0.7

./make-otu-tables.R

./generate-stats.sh -f temp/fastq/12S-mifishu-benchmark-R1.fastq.gz

# seqkit sample -n 1000000 -s 42 -o 12S-mifishu-benchmark-R1.fastq.gz 12S-mifishu-R1.fastq.gz
# seqkit sample -n 1000000 -s 42 -o 12S-mifishu-benchmark-R2.fastq.gz 12S-mifishu-R2.fastq.gz
# rm -r temp/

# rm -r temp/clustered temp/demultiplexed temp/dereplicated temp/filtered temp/merged temp/reorientated temp/trash temp/trimmed
# ./prepare.sh

# run 
# time ./benchmark.sh
# real	2m9.759s

# MIYA
#FWD="GTCGGTAAAACTCGTGCCAGC"
#REV="CATAGTGGGGTATCTAATCCCAGTTTG"
#REVCOMP="CAAACTGGGATTAGATACCCCACTATG"
#MINLEN="21"
