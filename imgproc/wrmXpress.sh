#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input
mkdir metadata
mkdir output/
mkdir work/

git clone  --branch packagify https://github.com/zamanianlab/Core_imgproc.git

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
tar -xf /staging/groups/zamanian_group/input/$1.tar -C input/

# deprecated
# cp -r /staging/groups/zamanian_group/input/$1.tar input
# cd $input && tar --strip-components 5 -xvf $1.tar && cd $HOME

# transfer and decompress metadata from staging ($1 is ${dir} from args)
tar -xf /staging/groups/zamanian_group/metadata/$1.tar -C metadata

# deprecated
# cd metadata && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd $HOME

# run the wrapper
python wrmXpress/wrapper.py $1.yml $1

# tar output folder and delete it
mv output $1
mv $1.yml $1
tar -cvf $1.tar $1 && rm -r $1

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
