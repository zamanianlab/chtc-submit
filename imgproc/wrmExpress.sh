#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir metadata
mkdir output/
mkdir work/

git clone https://github.com/zamanianlab/Core_imgproc.git
input="input/$1"
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

# run the wrapper
python Core_imgproc/wrapper.py Core_imgproc/parameters.yml

# tar output folder and delete it
mv output $1
tar -cvf $1.tar $1 && rm -r $1

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
