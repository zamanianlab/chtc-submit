#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
# mkdir input metadata work output
# mkdir output/$1
# mkdir work/$1

git clone https://github.com/wheelern/CellProfiler_Pipelines.git
mkdir CellProfiler_Pipelines/projects
mkdir CellProfiler_Pipelines/projects/$1
mkdir CellProfiler_Pipelines/projects/$1/raw_images
input="CellProfiler_Pipelines/projects/$1/raw_images"
echo $input

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar CellProfiler_Pipelines/projects/$1/raw_images
cd CellProfiler_Pipelines/projects/$1/raw_images && tar --strip-components 5 -xvf $1.tar && cd ../../../..

# transfer and decompress metadata from staging ($1 is ${dir} from args)
# cp -r /staging/groups/zamanian_group/metadata/$1.tar metadata
# cd metadata && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd ..

# get basename and plate IX metadata (from HTD file)
base=`echo $1 | cut -d"_" -f1`
time_points=`grep "TimePoints" $input/$base.HTD | cut -d',' -f2`
columns=`grep "XWells" $input/$base.HTD | cut -d',' -f2`
rows=`grep "YWells" $input/$base.HTD | cut -d',' -f2`
x_sites=`grep "XSites" $input/$base.HTD | cut -d',' -f2`
y_sites=`grep "YSites" $input/$base.HTD | cut -d',' -f2`
NWavelengths=`grep "NWavelengths" $input/$base.HTD | cut -d',' -f2`
WaveNames=`grep "WaveName" $input/$base.HTD | cut -d',' -f2`
echo "base name: ${base}"
echo "time_points: ${time_points}"
echo "columns: ${columns}"
echo "rows: ${rows}"
echo "x_sites: ${x_sites}"
echo "y_sites: ${y_sites}"
echo "NWavelengths: ${NWavelengths}"
echo "WaveNames: ${WaveNames}"

# run script
cd CellProfiler_Pipelines
cellprofiler -c -r -p batch_files/$1.h5 -f 1 -l 10

# rm files you don't want transferred back to /home/{net-id}
# rm -r work input metadata

# tar output folder and delete it
cd CellProfiler_Pipelines && tar -cvf $1.tar output && rm -r output && cd /CellProfiler_Pipelines

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/
