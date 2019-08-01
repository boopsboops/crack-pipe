#!/usr/bin/env sh

#./prepare.sh

./merge-reads.sh -t 8 -f temp/fastq/12S-mifishu-benchmark-R1.fastq.gz -r temp/fastq/12S-mifishu-benchmark-R2.fastq.gz

./reorientate.sh -f GTCGGTAAAACTCGTGCCAGC -r CATAGTGGGGTATCTAATCCCAGTTTG -m 21 -n 27

./demultiplex2.sh -t 8 -f GTCGGTAAAACTCGTGCCAGC -r CAAACTGGGATTAGATACCCCACTATG

./dereplicate.sh

./cluster.sh -t 8 -n 145 -x 196 -u 5

./annotate-taxonomy.R

./assign-taxonomy.sh -t 8 -c 0.7

./make-otu-tables.R

./generate-stats.sh -f temp/fastq/12S-mifishu-benchmark-R1.fastq.gz

# seqkit sample -n 1000000 -s 42 -o 12S-mifishu-benchmark-R1.fastq.gz 12S-mifishu-R1.fastq.gz
# seqkit sample -n 1000000 -s 42 -o 12S-mifishu-benchmark-R2.fastq.gz 12S-mifishu-R2.fastq.gz
# rm -r temp/

# run 
# time ./benchmark.sh
# real	3m5.273s 
