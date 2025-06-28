#!/bin/bash

# Set up working structure
mkdir -p input work output

# Copy input archive to work directory
cp -r /staging/groups/zamanian_group/input/sra_reads.tar work
cd work

# Unzip the tar of input files
tar -xf sra_reads.tar

cd sra_files_output

# Run Trinity
Trinity --seqType fq --max_memory 10G \
  --left SRR3110748_1.fastq,SRR3111433_1.fastq,SRR3111490_1.fastq,SRR3111494_1.fastq,SRR7825596_1.fastq,SRR7825597_1.fastq,SRR3111497_1.fastq,SRR3111501_1.fastq \
  --right SRR3110748_2.fastq,SRR3111433_2.fastq,SRR3111490_2.fastq,SRR3111494_2.fastq,SRR7825596_2.fastq,SRR7825597_2.fastq,SRR3111497_2.fastq,SRR3111501_2.fastq \
  --CPU 4 --output trinity_out_dir

# Compress the Trinity output directory
tar -czf trinity_out_dir.tar trinity_out_dir

mv trinity_out_dir.tar ../../output/

# Go back to root
cd ../../

# Remove input + work directories
rm -r work input

# Tar output and name it sra_reads.tar
tar -cvf trinity_output.tar output

# Remove the original output
rm -r output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/trinity_output.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv trinity_output.tar /staging/groups/zamanian_group/output/
