#!/bin/bash

# have job exit if any command returns with non-zero exit status (aka failure)
set -e

# setup conda env
ENVNAME=cellpose
ENVDIR=$ENVNAME
export PATH
mkdir $ENVDIR
tar -xzf /staging/groups/zamanian_group/envs/$ENVNAME.tar.gz -C $ENVDIR
. $ENVDIR/bin/activate

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

# transfer and extract input data from staging ($1 is ${dir} from args)
tar -xf /staging/groups/zamanian_group/input/cellpose_training.tar -C input/

# do the training
python -m cellpose --train --train_size --use_gpu --look_one_level_down --dir ~/input/cellpose_training/ --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/lta_1p2p_mixed --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/lta_1p2p_small --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/lta_1p2p_untreated --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/lta_naaz_mixed --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/lta_naaz_small --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/lta_naaz_untreated --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/plate_naaz_big --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/plate_naaz_mixed --pretrained_model None --mask_filter _seg.npy --verbose
python -m cellpose --train --train_size --use_gpu --dir ~/input/cellpose_training/plate_naaz_small --pretrained_model None --mask_filter _seg.npy --verbose

# tar output folder and delete it
mv output $1
mv $1.yml $1
tar -cvf $1.tar $1 && rm -r $1

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv $1.tar /staging/groups/zamanian_group/output/
