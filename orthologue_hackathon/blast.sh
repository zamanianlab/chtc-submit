#!/bin/bash

line_sub=$1

UP_prefix="https://rest.uniprot.org/uniprotkb/stream?format=fasta&query=proteome:"

species=species_list.txt

# dowload parasite proteomes
mkdir input output
proteomes=input

#while IFS= read -r line
#do
#  species_dl="$UP_prefix/$line/"
#  printf ${species_dl}"\n"
#  wget -nc -r -nH --cut-dirs=10 --no-parent --reject="index.html*" -A 'protein.fa.gz' $species_dl -P $proteomes
#done <"$species"
cd input 

while read proteome_id; do
    echo "Downloading $proteome_id ..."
    wget -q "https://rest.uniprot.org/uniprotkb/stream?format=fasta&query=proteome:${proteome_id}" -O "${proteome_id}.fasta"
done < proteomes.txt

cd ..

cat input/UP*.fasta > combined_proteomes.fasta

# make blast database
makeblastdb -in combined_proteomes.fasta -dbtype prot -out combined_db

# do blasting
blastp -query combined_proteomes.fasta -db combined_db -out blastp_results_combined.out 

# move blast output to output folder
mv "blastp_results_combined.out" /staging/groups/zamanian_group/output/
