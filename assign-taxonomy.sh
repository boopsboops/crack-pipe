#!/usr/bin/env sh

# set params #
while getopts a:p:t:c: option
do
case "${option}"
in
c) CUTOFF=${OPTARG};;
t) THREADS=${OPTARG};;
a) AVG=${OPTARG};;
p) PROP=${OPTARG};;
esac
done

# calculate minlen
MINLEN=$(awk "function ceil(x, y){y=int(x); return(x>y?y+1:y)} BEGIN { pc=${AVG}*${PROP}; i=ceil(pc); print i }")

# trim primers from the custom reference library
cutadapt -n 1 -e 0.3 -O 10 -g GTCGGTAAAACTCGTGCCAGC temp/reference-library/custom-references-annotated.fasta | cutadapt --minimum-length "$MINLEN" -n 1 -e 0.3 -O 10 -a CAAACTGGGATTAGATACCCCACTATG -o temp/reference-library/custom-references-annotated.trimmed.fasta -

# merge with refseq
cat temp/reference-library/custom-references-annotated.trimmed.fasta assets/refseq-mtdna-with-taxonomy.fasta > results/reference-library.fasta

# run sintax
vsearch --threads "$THREADS" --sintax results/cleaned-reads.fasta --db results/reference-library.fasta --sintax_cutoff "$CUTOFF" --tabbedout results/taxonomy-assignments.tsv

# report
printf "...\n...\n...\nMinimum length of fragment is: $MINLEN bp\n"

#./assign-taxonomy.sh -t 8 -a 170 -p 0.7 -c 0.7
