#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
# cp -r /staging/groups/zamanian_group/input/$1.tar $HOME
# cd $HOME && tar -xvf $1.tar && rm $1.tar

# clone nextflow git repo
git clone https://github.com/zamanianlab/Phylogenetics.git

# cd $HOME
# echo $(ls -lh)

# run script
#bash Phylogenetics/Tocris/pipeline.sh

#insert pipeline
echo $1 > output/temp.line.txt
#seqtk subseq $proteomes/HsUniProt_nr.fasta output/temp.line.txt > $seeds/Hs_seeds.target.fasta

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
tar -cvf $1.tar output && rm -r output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
