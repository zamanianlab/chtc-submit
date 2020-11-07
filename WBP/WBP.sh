#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)


# Generate list of species hosted at WBP
curl -l ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/current/species/ > output/species_all.txt
species=output/species_all.txt


# Download data ----------------------------------------------------------------
wbp_prefix="ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/WBP15/species"

# -N: only download newer versions
# -nc: no clobber; ignore server files that aren't newer than the local version
# -r: recursive
# -nH: don't mimick the server's directory structure
# -cut-dirs=7: ignore everything from pub to species in the recursive search
# --no-parent: don't ascend to the parent directory during a recursive search
# -A: comma-separated list of names to accept
# -P:
while IFS= read -r line
do
  species_dl="$wbp_prefix/$line/"
  printf ${species_dl}"\n"
  wget -nc -r -nH --cut-dirs=7 --no-parent --reject="index.html*" -A 'canonical_geneset.gtf.gz','genomic_masked.fa.gz','protein.fa.gz','CDS_transcripts.fa.gz' $species_dl -P output
done <"$species"

# Make BLAST databases ---------------------------------------------------------
while IFS= read -r line
do
  # split the line into an array with species + BioProject
  array=($(echo "$line" | sed 's/\// /g'))
  species_folder=output/${array[0]}/${array[1]}
  gunzip -k $species_folder/*.genomic*.gz
  makeblastdb -in $species_folder/*.genomic*.fa -dbtype nucl
  rm $species_folder/*.genomic*.fa

  gunzip -k $species_folder/*.protein*.gz
  makeblastdb -in $species_folder/*.protein.fa -dbtype prot
  rm $species_folder/*.protein.fa
done <"$species"

# make BLAST databases of concatenated FASTA files
mkdir output/all
find output -name '*.genomic*.gz' -exec cat {} + > output/all/all.genomic_masked.fa.gz
gunzip -k output/all/all.genomic_masked.fa.gz
makeblastdb -in output/all/all.genomic_masked.fa -dbtype nucl
rm output/all/all.genomic_masked.fa

find output -name '*.protein.fa.gz' -exec cat {} + > output/all/all.protein.fa.gz
gunzip -k output/all/all.protein.fa.gz
makeblastdb -in output/all/all.protein.fa -dbtype prot
rm output/all/all.protein.fa

# Create GTF and exon RDS files ------------------------------------------------

# load in R script
curl https://raw.githubusercontent.com/zamanianlab/CHTC-submit/main/WBP/parse_GTF.R > input/parase_GTF.R

while IFS= read -r line
do
  # split the line into an array with species + BioProject
  array=($(echo "$line" | sed 's/\// /g'))
  species_folder=output/${array[0]}/${array[1]}
  gunzip -k $species_folder/*.gtf.gz
  Rscript input/parse_GTF.R $species_folder/*.gtf ${array[0]}
  rm $species_folder/*.gtf
done <"$species"

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
tar -cvf WBP.tar output && rm -r output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/WBP.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv WBP.tar /staging/groups/zamanian_group/
