#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work
printf '%s\n' $1
echo $1 > work/temp.line.txt
line_sub=$(echo $1 | awk 'BEGIN { FS = "|" } ; { print $3 }')
mkdir "$line_sub"_output

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
mkdir work/1_Hs_seeds
seeds=work/1_Hs_seeds
mkdir work/2_Hs_targets
Hs_targets=work/2_Hs_targets
mkdir "$line_sub"_output/alignments
alignments="$line_sub"_output/alignments
mv Phylogenetics/Tocris/parasite_db.list.txt work
mkdir work/3_Para_targets
Para_targets=work/3_Para_targets
mkdir work/4_Para_recip
Para_recip=work/4_Para_recip
mkdir "$line_sub"_output/5_Para_final
Para_final="$line_sub"_output/5_Para_final

# Get IDs and sequences of hits
seqtk subseq $proteomes/HsUniProt_nr.fasta work/temp.line.txt > $seeds/Hs_seeds.$line_sub.fasta
rm work/temp.line.txt

# blast seed to human proteome to expand targets
blastp -query $seeds/Hs_seeds."$line_sub".fasta -db $proteomes/HsUniProt_nr.fasta -out $Hs_targets/"$line_sub".out -outfmt 6 -max_hsps 1 -evalue 1E-3 -num_threads 4
cat $Hs_targets/"$line_sub".out | awk '$3>40.000 && $11<1E-3 {print $2}' | sort | uniq > $Hs_targets/"$line_sub".list.txt
seqtk subseq $proteomes/HsUniProt_nr.fasta $Hs_targets/"$line_sub".list.txt > $Hs_targets/"$line_sub".ext.fasta
rm $Hs_targets/*.out

cat $Hs_targets/"$line_sub".ext.fasta | sed 's/>/>Homo_sapiens|/g' > $alignments/"$line_sub".combined.fasta
while IFS= read -r paradb; do
    #blast expanded human targets against parasite dbs
    para_name=$(echo "$paradb" | awk 'BEGIN { FS = "." } ; { print $1 }')
    blastp -query $Hs_targets/"$line_sub".ext.fasta -db $proteomes/$paradb -out $Para_targets/"$line_sub"."$para_name".out -outfmt 6 -max_hsps 1 -evalue 1E-1 -num_threads 4
		cat $Para_targets/"$line_sub"."$para_name".out | awk '$3>40.000 && $11<1E-3 {print $2}' | sort | uniq > $Para_targets/"$line_sub"."$para_name".list.txt
		seqtk subseq $proteomes/$paradb $Para_targets/"$line_sub"."$para_name".list.txt > $Para_targets/"$line_sub"."$para_name".fasta
    #blast parasite hits against human db
    blastp -query $Para_targets/"$line_sub"."$para_name".fasta -db $proteomes/HsUniProt_nr.fasta -out $Para_recip/"$line_sub"."$para_name".out -outfmt 6 -max_hsps 1 -evalue 1E-3 -num_threads 4
    cat $Para_recip/"$line_sub"."$para_name".out | awk '$3>40.000 && $11<1E-3 {print $1, $2}' | sort | uniq  > $Para_recip/"$line_sub"."$para_name".list.txt
    #compare to original human list to find surviving parasite targets
    grep -Ff $Hs_targets/"$line_sub".list.txt $Para_recip/"$line_sub"."$para_name".list.txt | awk '{print $1}' | sort | uniq > $Para_final/"$line_sub"."$para_name".list.txt
    seqtk subseq $proteomes/$paradb $Para_final/"$line_sub"."$para_name".list.txt > $Para_final/"$line_sub"."$para_name".fasta
    cat $Para_final/"$line_sub"."$para_name".fasta | sed 's/>/>'$para_name'|/g' >> $alignments/"$line_sub".combined.fasta
    #align mafft
    einsi --reorder --thread 2 $alignments/"$line_sub".combined.fasta > $alignments/"$line_sub".combined.aln
    #trim
    trimal -gt 0.7 -in $alignments/"$line_sub".combined.aln -out $alignments/"$line_sub".combined_trim.aln
    trimal -resoverlap 0.70 -seqoverlap 70 -in $alignments/"$line_sub".combined_trim.aln -out $alignments/"$line_sub".combined_final.aln
    #tree-building
    iqtree -s $alignments/"$line_sub".combined_final.aln -nt 4 -alrt 1000 -bb 1000 -redo
done < work/parasite_db.list.txt

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
tar -cvf $line_sub.tar "$line_sub"_output && rm -r "$line_sub"_output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/"$line_sub".tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $line_sub.tar /staging/groups/zamanian_group/output/
