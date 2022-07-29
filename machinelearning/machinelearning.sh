#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input
mkdir metadata
mkdir output/
mkdir work/

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
tar -xf /staging/groups/zamanian_group/input/model_data.tar -C input/

# run the wrapper
Rscript docking_evaluation.R

# tar output folder and delete it
mv output model_output
tar -cvf model_output.tar model_output && rm -r model_output

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv model_output.tar /staging/groups/zamanian_group/output/
