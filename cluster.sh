#!/usr/bin/env sh

# set params #
while getopts t:n:x:u: option
do
case "${option}"
in
n) MINLEN=${OPTARG};;
x) MAXLEN=${OPTARG};;
u) UNIQS=${OPTARG};;
t) THREADS=${OPTARG};;
esac
done

# cat all fasta
cat temp/dereplicated/*.fasta > temp/clustered/combined.derep.fasta

# gloabl derep
vsearch --derep_fulllength temp/clustered/combined.derep.fasta --sizein --sizeout --fasta_width 0 --output temp/clustered/combined.glob.derep.fasta

# swarm
swarm -t "$THREADS" -d 1 -z -f -o temp/clustered/swarm.clusters.out -w temp/clustered/swarm.clusters.fasta temp/clustered/combined.glob.derep.fasta

# Sort representatives
vsearch --fasta_width 0 --sortbysize temp/clustered/swarm.clusters.fasta --output temp/clustered/swarm.clusters.sorted.fasta
  
# chimaera search
vsearch --fasta_width 0 --uchime_denovo temp/clustered/swarm.clusters.sorted.fasta --uchimeout temp/clustered/swarm.cleaned.uchime --nonchimeras temp/clustered/swarm.cleaned.fasta

# remove singletons and length filter at approx 15% of read avg length
vsearch --derep_fulllength temp/clustered/swarm.cleaned.fasta --sizein --sizeout --fasta_width 0 --minuniquesize "$UNIQS" --maxseqlength "$MAXLEN" --minseqlength "$MINLEN" --output results/cleaned-reads.fasta

# homology search
#hmmsearch -E 0.01 --incE 0.01 hmms/12s.miya.primers.hmm temp/clustered/swarm.cleaned.rmsingletons.fasta | grep ">> " | sed -e 's/>> //g' -e 's/[[:space:]]//g' | sort | uniq > temp/clustered/hmm-out.txt
#sed -e 's/;size=[0-9]*//g' temp/clustered/swarm.clusters.out | nl -w 1 | sed -e 's/^/swarm/g' -e 's/ /\t/g' > temp/clustered/swarm.clusters.tsv

sed -e 's/;size=[0-9]*//g' temp/clustered/swarm.clusters.out > temp/clustered/swarm.clusters.tsv

#./cluster.sh -n 145 -x 196 -u 5
