#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar input
cd input && tar -xvf $1.tar && rm $1.tar && cd .. #for globus RD structure

# clone nextflow git repo
git clone https://github.com/zamanianlab/DNAseq-VC-nf.git

# run nextflow (QC, star)
export NXF_OPTS='-Xms1g -Xmx8g'
nextflow run DNAseq-VC-nf/Aeaeg-subsample.nf -w work -c DNAseq-VC-nf/chtc.config --dir $1\
  --rlen "150"

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1_sub.tar $1_sub && rm -r $1_sub && cd ..

# remove staging output tar if there from previous run (not needed for genome indexing)
#rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging *input* folder (will be used as input in future pipelines); avoid their transfer back to /home/{net-id}
mv output/$1_sub.tar /staging/groups/zamanian_group/input/
