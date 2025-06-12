#!/bin/bash
mkdir input work output

cp -r /staging/groups/zamanian_group/input/accession_list.txt work
cd work

# Run Trinity
docker run -it --rm \
  -v pwd:/data \
  trinityrnaseq/trinityrnaseq \
  Trinity --seqType fq --max_memory 10G \
  --left /data/*_1.fastq \
  --right /data/*_2.fastq \
  --CPU 4 --output /data/trinity_out_dir

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/