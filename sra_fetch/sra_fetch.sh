#!/bin/bash
mkdir input work output

cp -r /staging/groups/zamanian_group/input/accession_list.txt work
cd work

while read -r acc; do
  acc=$(echo "$acc" | xargs)  # strips leading/trailing whitespace
  
  echo "$acc"
  
  prefetch "$acc" -O sra_files

  fasterq-dump "sra_files/$acc.sra" -O . --split-files 

  # Move resulting FASTQ files to the output directory (one level up)
  mv "${acc}"_*.fastq ../output/ 2>/dev/null

done < accession_list.txt

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf sra_reads.tar sra_reads && rm -r sra_reads && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/sra_reads.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/sra_reads.tar /staging/groups/zamanian_group/output/

#move the output into a different folder named sra
