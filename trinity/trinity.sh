#!/bin/bash
mkdir input work output

cp -r /staging/groups/zamanian_group/input/sra_reads.tar work
cd work

#unzip the tar of input files
tar -xf sra_reads.tar

cd sra_files_output

# make a comma-separated list of left reads
LEFT_READS=$(ls *_1.fastq | paste -sd,)

# make a comma-separated list of right reads
RIGHT_READS=$(ls *_2.fastq | paste -sd,)

#copy the lists to the work directory
cp -r LEFT_READS work
cp -r RIGHT_READS work

# go back to the work directory
cd ..

# Run Trinity
docker run -it --rm \
  -v "$(pwd)":/data \
  trinityrnaseq/trinityrnaseq \
  Trinity --seqType fq --max_memory 10G \
  --left /data/sra_files_output/${LEFT_READS} \
  --right /data/sra_files_output/${RIGHT_READS} \
  --CPU 4 --output /data/trinity_out_dir

# Compress the Trinity output directory
tar -czf trinity_out_dir.tar.gz trinity_out_dir

mv trinity_out_dir.tar.gz ../output/

# Go back to root
cd ..

# Remove input + work directories
rm -r work input

# Tar output and name it sra_reads.tar
tar -cvf trinity_output.tar output

# Remove the original output
rm -r output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/trinity_ouput.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv trinity_ouput.tar /staging/groups/zamanian_group/output/
