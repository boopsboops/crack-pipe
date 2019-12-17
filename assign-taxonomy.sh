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
cutadapt -n 1 -e 0.2 -O 10 -g GTCGGTAAAACTCGTGCCAGC temp/reference-library/custom-references-annotated.fasta | cutadapt --minimum-length "$MINLEN" -n 1 -e 0.2 -O 10 -a CAAACTGGGATTAGATACCCCACTATG -o temp/reference-library/custom-references-annotated.trimmed.fasta -

# merge with refseq
cat temp/reference-library/custom-references-annotated.trimmed.fasta assets/refseq-mtdna-with-taxonomy.fasta > results/reference-library.fasta

# run sintax
vsearch --threads "$THREADS" --sintax results/cleaned-reads.fasta --db results/reference-library.fasta --sintax_cutoff "$CUTOFF" --tabbedout temp/blast-dump/sintax-output.tsv

# report
printf "...\n...\n...\nNow running BLAST\n..."

# run BLAST 
# make blast db (only need to do this step once)
makeblastdb -in temp/reference-library/references-blast.fasta -parse_seqids -dbtype nucl -blastdb_version 5

# get better hits with smaller word size
blastn -task blastn -num_threads 4 -evalue 1000 -word_size 7 -max_target_seqs 500 -db temp/reference-library/references-blast.fasta -outfmt "6 qseqid sseqid evalue length pident nident score bitscore" -out temp/blast-dump/blast.out -query results/cleaned-reads.fasta

# join the header
printf "qseqid\tsseqidLocal\tevalueLocal\tlengthLocal\tpidentLocal\tnidentLocal\tscoreLocal\tbitscoreLocal\n" > temp/blast-dump/headers
cat temp/blast-dump/headers temp/blast-dump/blast.out > temp/blast-dump/blast-result.tsv
rm temp/blast-dump/blast.out
rm temp/blast-dump/headers

# report
printf "...\n...\n...\nMinimum length of fragment is: $MINLEN bp\n"

#./assign-taxonomy.sh -t 8 -a 170 -p 0.7 -c 0.7
