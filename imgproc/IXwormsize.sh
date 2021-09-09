#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir metadata
# mkdir output/$1
# mkdir work/$1

git clone https://github.com/zamanianlab/Core_imgproc.git
mkdir Core_imgproc/CP/projects
mkdir Core_imgproc/CP/projects/$1
mkdir Core_imgproc/CP/projects/$1/raw_images
input="Core_imgproc/CP/projects/$1/raw_images"
echo $input

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar $input
cd $input && tar --strip-components 5 -xvf $1.tar && cd $HOME

# transfer and decompress metadata from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/metadata/$1.tar metadata
cd metadata && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd $HOME

# get basename and plate IX metadata (from HTD file)
base=`echo $1 | cut -d"_" -f1`
time_points=`grep "TimePoints" $input/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
columns=`grep "XWells" $input/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
rows=`grep "YWells" $input/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
x_sites=`grep "XSites" $input/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
y_sites=`grep "YSites" $input/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
NWavelengths=`grep "NWavelengths" $input/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
# iterate over all wavenames and concatenate into single string separated by "_"
WaveNames=''
for i in $(seq 1 $NWavelengths); do
  WaveName=`grep "WaveName${i}" $input/$base.HTD | cut -d',' -f2 | sed 's/\"//g' | sed 's/ //g' | sed 's/\r//g'`
  echo ${WaveName}
  WaveNames="${WaveNames}${WaveName}_"
done
WaveNames=`echo $WaveNames | rev | cut -c 2- | rev`
echo "base name: ${base}"
echo "time_points: ${time_points}"
echo "columns: ${columns}"
echo "rows: ${rows}"
echo "x_sites: ${x_sites}"
echo "y_sites: ${y_sites}"
echo "NWavelengths: ${NWavelengths}"
echo "WaveNames: ${WaveNames}"

# generate the CSV of files + metadata
Rscript Core_imgproc/CP/scripts/generate_filelist_wormsize.R $1

# run script
cellprofiler -c -r -p Core_imgproc/CP/pipelines/wormsize.cppipe --data-file=Core_imgproc/CP/metadata/image_paths_wormsize.csv

# join metatdata, tar output folder, and delete it
mv metadata output
Rscript Core_imgproc/CP/scripts/metadata_join_wormsize.R $1
rm -r output/metadata
mv output $1
tar -cvf $1.tar $1 && rm -r $1

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
