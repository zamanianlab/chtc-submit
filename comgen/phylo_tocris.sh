#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# clone nextflow git repo
git clone https://github.com/zamanianlab/Phylogenetics.git

# cd $HOME
# echo $(ls -lh)

# run script
# bash Phylogenetics/Tocris/pipeline.sh

# INSERT PIPELINE
wbp_prefix="ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/current/species/"

species=Phylogenetics/Tocris/parasite.list.txt

# dowload parasite proteomes
mkdir input/proteomes
proteomes=input/proteomes

while IFS= read -r line
do
  species_dl="$wbp_prefix/$line/"
  printf ${species_dl}"\n"
  wget -nc -r -nH --cut-dirs=10 --no-parent --reject="index.html*" -A 'protein.fa.gz' $species_dl -P $proteomes
done <"$species"

# add human proteome
mv Phylogenetics/Tocris/HsUniProt_nr.fasta $proteomes

# make blast databases
while IFS= read -r line
do
  species_prjn="$(echo $line | sed 's/\//\./g')"
  echo $species_prjn > work/temp.txt
  gunzip -k $proteomes/"$species_prjn".*.protein.fa.gz
  makeblastdb -in $proteomes/"$species_prjn".*.protein.fa -dbtype prot
done <"$species"

rm $proteomes/*.protein*.gz

makeblastdb -in $proteomes/HsUniProt_nr.fasta -dbtype prot

# set up directories and move files
mv Phylogenetics/Tocris/Hs_seeds.list.txt work
mkdir output/1_Hs_seeds
seeds=output/1_Hs_seeds
mkdir work/2_Hs_targets
Hs_targets=work/2_Hs_targets
mkdir output/alignments
alignments=output/alignments
mv Phylogenetics/Tocris/parasite_db.list.txt work
mkdir work/3_Para_targets
Para_targets=work/3_Para_targets
mkdir work/4_Para_recip
Para_recip=work/4_Para_recip
mkdir output/5_Para_final
Para_final=output/5_Para_final

# Get IDs and sequences of hits
printf '%s\n' $1
echo $1 > output/temp.line.txt
line_sub=$(echo $1 | awk 'BEGIN { FS = "|" } ; { print $3 }')
seqtk subseq $proteomes/HsUniProt_nr.fasta output/temp.line.txt > $seeds/Hs_seeds.$line_sub.fasta
# rm work/temp.line.txt

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
tar -cvf $line_sub.tar output && rm -r output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$line_sub.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $line_sub.tar /staging/groups/zamanian_group/output/
