#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir metadata
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
cp -r /staging/groups/zamanian_group/metadata/$1.tar metadata
cd metadata && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd ..

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

# generate the CSV of files + metadata
Rscript CellProfiler_Pipelines/scripts/generate_filelist.R $1 well_mask.png

# run script
cellprofiler -c -r -p CellProfiler_Pipelines/pipelines/batch_project.cppipe --data-file=CellProfiler_Pipelines/metadata/image_paths.csv

# join metatdata, tar output folder, and delete it
mv metadata output
Rscript CellProfiler_Pipelines/scripts/metadata_join.R $1
rm -r output/metadata
mv output $1
tar -cvf $1.tar $1 && rm -r $1

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
