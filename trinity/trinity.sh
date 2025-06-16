#!/bin/bash
mkdir input work output

cp -r /staging/groups/zamanian_group/input/sra_files.tar work
cd work

# Run Trinity
docker run -it --rm \
  -v pwd:/data \
  trinityrnaseq/trinityrnaseq \
  Trinity --seqType fq --max_memory 10G \
  --left /data/*_1.fastq \
  --right /data/*_2.fastq \
  --CPU 4 --output /data/trinity_out_dir


# Go back to root
cd ..

# Remove input + work directories
rm -r work input

# Tar output and name it sra_reads.tar
tar -cvf trinity_ouput.tar output
# Remove the original output
rm -r output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/trinity_ouput.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv trinity_ouput.tar /staging/groups/zamanian_group/output/
