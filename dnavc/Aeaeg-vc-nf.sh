#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir1}, $2 is ${dir2} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar input
cd input && tar -xvf $1.tar && rm $1.tar && cd ..
cp -r /staging/groups/zamanian_group/input/$2.tar input
cd input && tar -xvf $2.tar && rm $2.tar && cd ..

# transfer fastq files to a common input folder (fqs)
cd input && mkdir fqs
mv $1/*.gz fqs && mv $2/*.gz fqs

# transfer and decompress mosquito genome index data from staging 
cp -r /staging/groups/zamanian_group/input/Aeaegypti_ref.tar input
cd input && tar -xvf Aeaegypti_ref.tar && rm Aeaegypti_ref.tar && cd ..

# clone nextflow git repo
git clone https://github.com/zamanianlab/DNAseq-VC-nf.git

# run nextflow (QC, star)
export NXF_OPTS='-Xms1g -Xmx8g'
nextflow run DNAseq-VC-nf/Aeaeg-vc.nf -w work -c DNAseq-VC-nf/chtc.config --dir $1_$2 --rlen "150" --qc

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1_$2.tar $1_$2 && rm -r $1_$2 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1_$2.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1_$2.tar /staging/groups/zamanian_group/output/
