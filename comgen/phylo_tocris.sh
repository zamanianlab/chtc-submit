#!/bin/bash

# set home () and mk dirs
export HOME=$PWD

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# clone nextflow git repo
git clone https://github.com/zamanianlab/Phylogenetics.git

# cd $HOME
# echo $(ls -lh)

# run script
bash Phylogenetics/Tocris/pipeline.sh

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
tar -cvf $line_sub.tar "$line_sub"_output && rm -r "$line_sub"_output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/"$line_sub".tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $line_sub.tar /staging/groups/zamanian_group/output/
