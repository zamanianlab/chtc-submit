#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# transfer input data from staging
cp -r /staging/{net-id}/input/$1 input

# clone nextflow git repo
git clone https://github.com/zamanianlab/Core_RNAseq-nf.git

# run nextflow
export NXF_OPTS='-Xms1g -Xmx8g'
nextflow run Core_RNAseq-nf/WB-pe.nf -w work -c Core_RNAseq-nf/chtc.config --dir $1 --release "WBPS14" --species "brugia_malayi" --prjn "PRJNA10729" --rlen "150"

# rm files you don't want transferred back to /home/{net-id}
rm -r work
rm -r input

# mv large output files to staging to avoid their transfer back to /home/{net-id}
mv output/$1/ /staging/{net-id}/output/
