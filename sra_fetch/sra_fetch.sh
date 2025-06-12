#!/bin/bash
mkdir input work sra_files_output

cp -r /staging/groups/zamanian_group/input/accession_list.txt work
cd work

while read -r acc; do
  acc=$(echo "$acc" | xargs)  # strips leading/trailing whitespace
  
  prefetch "$acc"    # no -O
  fasterq-dump "$acc" --split-files -O .

  # echo "$acc"
  # prefetch "$acc" -O sra_files
  # fasterq-dump "sra_files/$acc.sra" -O . --split-files 

  # Move resulting FASTQ files to the output directory (one level up)
  mv "${acc}"_*.fastq ../sra_files_output/ 2>/dev/null

done < accession_list.txt

# Go back to root
cd ..

# Remove input + work directories
rm -r work input

# Tar output and name it sra_reads.tar
tar -cvf sra_reads.tar sra_files_output
# Remove the original output
rm -r sra_files_output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/sra_reads.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv sra_reads.tar /staging/groups/zamanian_group/output/

#move the output into a different folder named sra
