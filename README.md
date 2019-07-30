# A crack pipe

*A la* The A-Team, I have assembled a crack squad of mercinaries (programs) to process metabarcoding data. Just like the A-Team, this pipeline is quick and dirty, but will process your reads quicker than you can say "I love it when a plan comes together". Currently for the MiFish 12S primer set only.


## Step 1: Prepare your machine

The following programs need to be installed on your machine: [pear](https://www.h-its.org/downloads/pear-academic/), [cutadapt](https://cutadapt.readthedocs.io/en/stable/index.html), [vsearch](https://github.com/torognes/vsearch), [swarm](https://github.com/torognes/swarm), [hmmer](http://hmmer.org/), and [R](https://cran.r-project.org/). 

For R, you will also need the packages: 'tidyverse', 'ape', 'taxize', 'magrittr' and 'parallel'.

The programs all need to be on your $PATH, meaning that a program can be run anywhere, just by typing its name, for example 'vsearch'. See [here](https://opensource.com/article/17/6/set-path-linux).


## Step 2: Prepare your working area

1. Obtain these scripts by either cloning this git repository, or using the [download link above](https://github.com/boopsboops/crackpipe/archive/master.zip).

2. Run `./prepare.sh` to create all the necessary subdirectories.   

2. Put your raw R1 and R2 metabarcoding reads (FASTQ format) into `temp/fastq`.  
3. Put your sample barcodes (FASTA format) into `temp/fastq/barcodes.fas`. These barcodes should be 10 bp in length, and therefore will contain your 7/8 bp tag, plus two or three bases of your forward PCR primer to anchor the barcode. The FASTA header will contain your sample identification codes like so:
```
>sample1
TCTCTTGGTC
```

4. Put your custom reference library (FASTA format) into `temp/reference-library/custom-references.fasta`. Your custom reference library should be unaligned sequences containing no Ns, hyphens, or question marks. The FASTA header will contain the tissue identification code separated from the species name by a pipe. Genus and species should be separated by a space. Be sure to remove any trailing whitespace (spaces or tabs) from the ends of the lines.
```
>RC1587|Tinca tinca
CACCGCGGTTAAACGAGAGGCCCTAGTTGATATTACTACGGCGTAAAGGGT
```


## Step 3: Merge your reads

Merge the reads by running the following command: 

```
./merge-reads.sh -f temp/fastq/your-reads.R1.fastq.gz -r temp/fastq/your-reads.R2.fastq.gz
```


## Step 4: Reorientate your reads

The reads are in a mixture of directions, approximately 50/50 5'-3' and 3'-5'. They all need to be reorientated into 5'-3'. This step also removes reads without a high quality 5' PCR primer. The -f and -r arguments are the forward and reverse PCR primers respectively. The -m and -n arguments are the lengths of those primers respectively. Change as appropriate for your data.

```
./reorientate.sh -f GTCGGTAAAACTCGTGCCAGC -r CATAGTGGGGTATCTAATCCCAGTTTG -m 21 -n 27
```

Step creates a file `temp/reorientated/reorientated.fastq.gz`.


## Step 5: Demultiplex your reads

Now the reads can be demultiplexed by your sample barcodes in `temp/fastq/barcodes.fas`. The -f and -r arguments are the forward PCR primer and the reverse complement of the reverse PCR primer, respectively. Change as appropriate for your data.

The reads are also trimmed of PCR primers and barcodes.
```
./demultiplex.sh -f GTCGGTAAAACTCGTGCCAGC -r CAAACTGGGATTAGATACCCCACTATG
```

Step creates files `temp/demultiplexed/*.fastq.gz` and `temp/trimmed/*.fastq.gz`.


## Step 6: Dereplicate your reads

Reads are now dereplicated (collapsed into unique sequences) on a per sample basis. Reads are also quality filtered to remove low quality sequences.
```
./dereplicate.sh
```

Step creates files `temp/filtered/*.fasta` and `temp/dereplicated/*.fasta`.


## Step 7: Cluster your reads

This step performs several functions. First it merges all the samples and dereplicates again. Next, it clusters the sequences into biologically useful groups using the Swarm algorithm. This collapses a most of the sequencing and PCR errors. Next, it removes sequences that could be chimaeric, i.e. partial sequences grafted together due to PCR or library prep errors. Next, it performs a quality filter; here, the -n and -x arguments are respectively the minimum and maximum sequence lengths allowed, and -u is the minimum adundance of a sequence, i.e. sequences with less than n total representatives are removed, because they likely to be spurious sequences. These values are good starting point, but change as appropriate for your data.
```
./cluster.sh -n 145 -x 196 -u 5
```

Step creates files `results/cleaned.reads.fasta` and `temp/clustered/swarm.clusters.tsv`.


## Step 8: Assemble your reference library

This step takes your custom reference at `temp/reference-library/custom-references.fasta` and annotates it with taxonomic information from [FishBase](https://www.fishbase.se/search.php). This is a more sensible and predictable taxonomy than from [NCBI](https://www.ncbi.nlm.nih.gov/taxonomy).

```
./annotate-taxonomy.R
```

Step creates files `results/cleaned-reads.fasta` and `temp/clustered/swarm.clusters.tsv`.


## Step 9: Assign taxonomy

This step assigns taxonomy to your cleaned reads using the custom reference library and an annotated NCBI REFSEQ mitochondrial DNA database of 4,571 sequences. The -c argument is the bootstrap value for reporting an identification (range 0-1). Lower values will be more precise but less accurate identifications, but vice versa for higher values  (e.g. family level versus species). Experiment to see how this value affects the identifications with your data.

```
./assign-taxonomy.sh -c 0.7
```

Step creates files `results/reference-library.fasta` and `results/taxonomy-assignments.tsv`.


## Step 10: Make the OTU tables

This final step creates your OTU tables, which are the basis for further analyses. 

```
./make-otu-tables.R
```

Step creates files `results/otu-table-raw.csv` (table with md5sums that can be matched back to `results/cleaned-reads.fasta`), `results/otu-table-all.csv` (all taxa including unassigned), and `results/otu-table-fish.csv` (only  reads identified as fish).


## Step 11: Pipeline statistics

Once last step. This generates stats for the numbers of reads at each stage. The -f argument is the path to your raw R1 reads file. This enables you to track your losses of reads at each step.

```
./generate-stats.sh -f temp/fastq/your-reads.R1.fastq.gz
```
