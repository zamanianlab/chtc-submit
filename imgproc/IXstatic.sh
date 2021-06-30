#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output
mkdir output/$1
mkdir work/$1

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar input
cd input && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd ..

# for testing
# scp -r njwheeler@transfer.chtc.wisc.edu:/staging/groups/zamanian_group/subsampled/20201118-p01-MZ_172_sub.tar subsampled/
# cd subsampled && tar -xvf 20201118-p01-MZ_172_sub.tar && rm 20201118-p01-MZ_172_sub.tar && cd

# get basename and plate IX metadata (from HTD file)
base=`echo $1 | cut -d"_" -f1`
time_points=`grep "TimePoints" input/$1/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
columns=`grep "XWells" input/$1/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
rows=`grep "YWells" input/$1/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
x_sites=`grep "XSites" input/$1/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
y_sites=`grep "YSites" input/$1/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
NWavelengths=`grep "NWavelengths" input/$1/$base.HTD | cut -d',' -f2 | sed 's/ //g' | sed 's/\r//g'`
# iterate over all wavenames and concatenate into single string separated by "_"
WaveNames=''
for i in $(seq 1 $NWavelengths); do
  WaveName=`grep "WaveName${i}" input/$1/$base.HTD | cut -d',' -f2 | sed 's/\"//g' | sed 's/ //g' | sed 's/\r//g'`
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

# clone nextflow git repo
git clone https://github.com/zamanianlab/BrugiaMotilityAnalysis.git

# run script
python BrugiaMotilityAnalysis/chtc-ix_optical_flow.py \
  input/$1 \
  output/$1 \
  work/$1 \
  $rows \
  $columns \
  $time_points #\
  #--reorganize

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/
