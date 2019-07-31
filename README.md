# A (crack) pipe

![The A-Team](https://upload.wikimedia.org/wikipedia/en/9/93/Ateam.jpg)

*A la* The A-Team, I have assembled a crack squad of mercenaries (programs) to process your metabarcoding data. Just like the A-Team, this pipeline is quick and dirty, but will process your reads quicker than you can say "I love it when a plan comes together". Currently for the MiFish 12S primer set only.


## Step 1: Prepare your machine

The following programs need to be installed on your machine: [pear](https://www.h-its.org/downloads/pear-academic/), [cutadapt](https://cutadapt.readthedocs.io/en/stable/index.html), [vsearch](https://github.com/torognes/vsearch), [swarm](https://github.com/torognes/swarm), and [R](https://cran.r-project.org/). 

For R, you will also need the packages: 'tidyverse', 'ape', 'rfishbase', 'magrittr' and 'parallel'.

The programs all need to be on your $PATH, meaning that a program can be run in any directory, just by typing its name (e.g. 'vsearch -h'). See [here](https://opensource.com/article/17/6/set-path-linux) for a better explanation. Effectively, this means putting a line of code at the bottom of your terminal session startup scripts pointing to wherever you compiled the programs (don't make them with sudo). The startup scripts are in `~/.bashrc` (Ubuntu) and `~/.bash_profile` (Mac). The dot before the name means they are hidden files. Add:

```
export PATH=~/Software/swarm/bin:$PATH
```


## Step 2: Prepare your working area

1. Obtain these scripts by either cloning this git repository, or using the [download link above](https://github.com/boopsboops/crack-pipe/archive/master.zip).

2. Run a script to create all the necessary subdirectories:

```
./prepare.sh
```

3. Put your raw R1 and R2 metabarcoding reads (FASTQ format) into `temp/fastq`.  
4. Put your sample barcodes (FASTA format) into `temp/fastq/barcodes.fas`. These barcodes should be 10 bp in length, and therefore will contain your 7/8 bp tag, plus two or three bases of your forward PCR primer to anchor the barcode. The FASTA header will contain your sample identification codes, like so:

```
>sample1
TCTCTTGGTC
```

5. Put your custom reference library (FASTA format) into `temp/reference-library/custom-references.fasta`. Your custom reference library should be unaligned sequences containing no Ns, hyphens, or question marks. The FASTA header will contain the tissue identification code separated from the species name by a pipe. Genus and species should be separated by a space. Be sure to remove any trailing whitespace (spaces or tabs) from the ends of the lines. For example:

```
>RC1587|Tinca tinca
CACCGCGGTTAAACGAGAGGCCCTAGTTGATATTACTACGGCGTAAAGGGT
```


## Step 3: Merge your reads

First processing step is to merge the reads by running command below in the terminal (open at the root of this project directory). The -f and -r arguments are the locations of your raw R1 and R2 reads respectively. The -t argument is the number of processor cores of your machine. If in doubt, set to four.

```
./merge-reads.sh -t 8 -f temp/fastq/your-reads.R1.fastq.gz -r temp/fastq/your-reads.R2.fastq.gz
```

This step creates a file named `temp/merged/reads.assembled.fastq`.


## Step 4: Reorientate your reads

With the PCR-free library prep method we used, reads are in a mixture of directions, approximately 50/50 at 5'-3' and 3'-5'. They all need to be reorientated into 5'-3'. This step also removes reads without a high quality 5' PCR primer. The -f and -r arguments are the forward and reverse PCR primers respectively. The -m and -n arguments are the lengths of those primers respectively. Change as appropriate for your data.

```
./reorientate.sh -f GTCGGTAAAACTCGTGCCAGC -r CATAGTGGGGTATCTAATCCCAGTTTG -m 21 -n 27
```

This step creates a file named `temp/reorientated/reorientated.fastq.gz`.


## Step 5: Demultiplex your reads

Now the reads can be demultiplexed by your sample barcodes in `temp/fastq/barcodes.fas`. The -f and -r arguments are the forward PCR primer and the reverse complement of the reverse PCR primer, respectively. Change as appropriate for your data. The reads are also trimmed of PCR primers and barcodes.

```
./demultiplex.sh -f GTCGGTAAAACTCGTGCCAGC -r CAAACTGGGATTAGATACCCCACTATG
```

This step creates files named `temp/demultiplexed/*.fastq.gz` and `temp/trimmed/*.fastq.gz`.


## Step 6: Dereplicate your reads

Reads can now be dereplicated (collapsed into unique sequences) on a per-sample basis. Reads are also quality filtered to remove low quality sequences.

```
./dereplicate.sh
```

This step creates files named `temp/filtered/*.fasta` and `temp/dereplicated/*.fasta`.


## Step 7: Cluster your reads

This step performs several functions. First it merges all the samples and dereplicates again globally. Next, it clusters the sequences into biologically useful groups using the Swarm algorithm. This collapses most of the Illumina sequencing and PCR errors. Next, it removes sequences that could be chimaeric, i.e. partial sequences grafted together due to PCR or library prep errors. Next, it performs a quality filter; here, the -n and -x arguments are respectively the minimum and maximum sequence lengths allowed, and -u is the minimum adundance of a sequence, i.e. sequences with less than n total representatives are removed, because they likely to be spurious sequences. These values are good starting point, but change as appropriate for your data. The -t argument is the number of processor cores of your machine. If in doubt, set to four.

```
./cluster.sh -t 8 -n 145 -x 196 -u 5
```

This step creates files named `results/cleaned.reads.fasta` and `temp/clustered/swarm.clusters.tsv`.


## Step 8: Assemble your reference library

This step takes your custom reference library at `temp/reference-library/custom-references.fasta` and annotates it with taxonomic information from [FishBase](https://www.fishbase.se/search.php). This is a more sensible and predictable taxonomy than from [NCBI](https://www.ncbi.nlm.nih.gov/taxonomy).

```
./annotate-taxonomy.R
```

Step creates files `results/cleaned-reads.fasta` and `temp/clustered/swarm.clusters.tsv`.


## Step 9: Assign taxonomy

This step assigns taxonomy to your cleaned reads using the custom reference library and an annotated NCBI REFSEQ mitochondrial DNA database of 4,571 sequences. The -c argument is the bootstrap value for reporting an identification (range 0-1). Lower values will give more precise but less accurate identifications, and vice versa for higher values (e.g. family level instead of species level). Experiment to see how this value affects the identifications using your data. The -t argument is the number of processor cores of your machine. If in doubt, set to four.

```
./assign-taxonomy.sh -t 8 -c 0.7
```

This step creates files named `results/reference-library.fasta` and `results/taxonomy-assignments.tsv`.


## Step 10: Make the OTU tables

This final step creates your OTU tables, which are the basis for further analyses. 

```
./make-otu-tables.R
```

This step creates files named `results/otu-table-raw.csv` (table with md5sums that can be matched back to `results/cleaned-reads.fasta`), `results/otu-table-all.csv` (all taxa including unassigned), and `results/otu-table-fish.csv` (only  reads identified as fishes).


## Step 11: Pipeline statistics

One last step. This generates stats for the numbers of reads at each stage. The -f argument is the path to your raw R1 reads file. This enables you to track your losses of reads at each step.

```
./generate-stats.sh -f temp/fastq/your-reads.R1.fastq.gz
```


## Step 12: Done!

Have a cigar with Hannibal.