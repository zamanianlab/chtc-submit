#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer input data from staging ($1 is vcf ${file} from args)
cp -r /staging/groups/zamanian_group/input/$1 input

# transfer and decompress mosquito genome index data from staging 
cp -r /staging/groups/zamanian_group/input/Aeaegypti_ref.tar input
cd input && tar -xvf Aeaegypti_ref.tar && rm Aeaegypti_ref.tar && cd ..

# clone nextflow git repo
git clone https://github.com/zamanianlab/DNAseq-VC-nf.git

# run nextflow (QC, star)
export NXF_OPTS='-Xms1g -Xmx8g'
nextflow run DNAseq-VC-nf/Aeaeg-filter-snpeff.nf -w work -c DNAseq-VC-nf/chtc.config --dir dnavc_fil

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf dnavc_fil.tar dnavc_fil && rm -r dnavc_fil && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/dnavc_fil.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/dnavc_fil.tar /staging/groups/zamanian_group/output/
