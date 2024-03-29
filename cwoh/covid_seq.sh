#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/CWOHC_data/input/$1.tar input
cd input && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd $HOME

# clone nextflow git repo
git clone https://github.com/alceballosa/cw_onehealth_protocols.git

# run nextflow (QC, star)
# export NXF_OPTS='-Xms1g -Xmx8g'
# nextflow -v
 nextflow run cw_onehealth_protocols/covid_dsl2.nf \
    -c cw_onehealth_protocols/covid-chtc.conf -w work \
    --source_folder $HOME/input/$1 --output_folder $HOME/output/$1 \
    --primers_folder cw_onehealth_protocols/protocol_input_files/primer_schemes/nCoV-2019/V3

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd $HOME

# remove staging output tar if there from previous run
rm -f /staging/groups/CWOHC_data/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/CWOHC_data/output/
