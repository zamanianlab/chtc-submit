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
cd input && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd .. #for RD structure
#cd input && tar -xvf $1.tar && rm $1.tar && cd .. #for brc transfer no file structure

# clone nextflow git repo
git clone https://github.com/zamanianlab/DNAseq-VC-nf.git

# run nextflow (QC, star)
export NXF_OPTS='-Xms1g -Xmx8g'
nextflow run DNAseq-VC-nf/Aeaeg-vc.nf -w work -c DNAseq-VC-nf/chtc.config --dir $1\
  --rlen "150"

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/
