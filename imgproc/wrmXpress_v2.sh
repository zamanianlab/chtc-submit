#!/bin/bash

# set home () and mk dirs
ls && cd /home
export HOME=$PWD
mkdir input metadata output work

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# transfer and decompress input data from staging ($1 is ${dir} from args)
tar -xf /staging/groups/zamanian_group/input/$1.tar -C input/

# transfer and decompress metadata from staging ($1 is ${dir} from args)
tar -xf /staging/groups/zamanian_group/metadata/$1.tar -C metadata

# run the wrapper
python /root/wrmXpress/wrapper.py $1.yml $1

# tar output folder and delete it
mv output $1
mv $1.yml $1
tar -cvf $1.tar $1 && rm -r $1

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
