#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir}, $2 is ${aedesgenome} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar input
cd input && tar -xvf $1.tar && rm $1.tar && cd ..

# transfer and decompress mosquito genome index data from staging 
cp -r /staging/groups/zamanian_group/input/$2.tar input
cd input && tar -xvf $2.tar && rm $2.tar && cd ..

# clone nextflow git repo
git clone https://github.com/zamanianlab/RNAseq-VC-nf.git

# run nextflow (QC, star)
export NXF_OPTS='-Xms1g -Xmx8g'
nextflow run RNAseq-VC-nf/call_variants.nf -w work -c RNAseq-VC-nf/chtc.config --dir $1 --aedesgenome $2

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/
