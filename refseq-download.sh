#!/usr/bin/env sh

# download
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/RELEASE_NUMBER -P temp/reference-library
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/README -P temp/reference-library
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/mitochondrion.1.1.genomic.fna.gz -P temp/reference-library
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/mitochondrion.2.1.genomic.fna.gz -P temp/reference-library

# unzip
gzip -d temp/reference-library/mitochondrion.1.1.genomic.fna.gz 
gzip -d temp/reference-library/mitochondrion.2.1.genomic.fna.gz 

# join
cat temp/reference-library/mitochondrion.1.1.genomic.fna temp/reference-library/mitochondrion.2.1.genomic.fna > temp/reference-library/mitochondrion.genomic.fna
rm temp/reference-library/mitochondrion.1.1.genomic.fna temp/reference-library/mitochondrion.2.1.genomic.fna

# clean
sed -i -e 's/ .*//g' temp/reference-library/mitochondrion.genomic.fna
