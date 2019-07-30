#!/usr/bin/env sh

while getopts f: option
do
case "${option}"
in
f) R1=${OPTARG};;
esac
done

echo "Total number raw reads:"
fqtools count "$R1"
echo ""

echo "Total number merged reads:"
fqtools count temp/merged/reads.assembled.fastq.gz
echo ""

echo "Total number reorientated reads:"
fqtools count temp/reorientated/reorientated.fastq.gz
echo ""

echo "Total number demultiplexed reads:"
cat temp/demultiplexed/*.fastq.gz | fqtools count
echo ""

echo "Total number trimmed reads:"
cat temp/trimmed/*.fastq.gz | fqtools count
echo ""

echo "Total number filtered reads:"
cat temp/filtered/*.fasta | grep -c  ">"
echo ""

echo "Total number cleaned reads"
grep ";size=" results/cleaned-reads.fasta | sed -e 's/.*;size=//g' | awk '{ SUM += $1} END { print SUM }'
echo ""

echo "Total number fish reads:"
cat temp/reference-library/nfishreads.txt
echo ""

# ./generate-stats.sh -f temp/fastq/12S-mifishu-R1.fastq.gz
