#!/usr/bin/env sh

# set params #
while getopts t:c: option
do
case "${option}"
in
c) CUTOFF=${OPTARG};;
t) THREADS=${OPTARG};;
esac
done

# trim primers from the custom reference library
cutadapt -n 1 -e 0.3 -O 10 -g GTCGGTAAAACTCGTGCCAGC temp/reference-library/custom-references-annotated.fasta | cutadapt --minimum-length 120 -n 1 -e 0.3 -O 10 -a CAAACTGGGATTAGATACCCCACTATG -o temp/reference-library/custom-references-annotated.trimmed.fasta -

# merge with refseq
cat temp/reference-library/custom-references-annotated.trimmed.fasta assets/refseq-mtdna-with-taxonomy.fasta > results/reference-library.fasta

# run sintax
vsearch --threads "$THREADS" --sintax results/cleaned-reads.fasta --db results/reference-library.fasta --sintax_cutoff "$CUTOFF" --tabbedout results/taxonomy-assignments.tsv
