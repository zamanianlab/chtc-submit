#!/bin/bash
mkdir input work sra_files_output

accession_list=$(ls /staging/groups/zamanian_group/input/*_acc_list.txt)
basename=$(basename "$accession_list" .txt | sed 's/_acc_list$//')

cp -r "$accession_list" work
cd work

while read -r acc; do
  acc=$(echo "$acc" | xargs)  # strips leading/trailing whitespace
  
  prefetch "$acc"    # downloads acc.sra into ./ncbi/public/sra by default
  fasterq-dump "$acc" --split-files -O . --temp ./tmp

  # remove the .sra file once conversion succeeds
  rm -f "${acc}.sra" ./ncbi/public/sra/"${acc}.sra"

  # Move resulting FASTQ files to the output directory (one level up)
  mv "${acc}"_*.fastq ../sra_files_output/ 2>/dev/null
done < "$(basename "$accession_list")"

#while read -r acc; do
#  acc=$(echo "$acc" | xargs)
#  
#  fasterq-dump "$acc" \
#    --split-files \
#    -O ./ \
#    --temp ./tmp \
#    --threads 4
#
#  mv "${acc}"_*.fastq ../sra_files_output/ 2>/dev/null
#done < "$(basename "$accession_list")"

# Go back to root
cd ..

# Remove input + work directories
rm -r work input

# Tar output and name it whatever you named your accession list.txt but its a .tar
tar -cvf "${basename}.tar" sra_files_output

# Remove the original output
rm -r sra_files_output

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/input/"${basename}.tar"

# mv large output files to staging input folder; avoid their transfer back to /home/{net-id}
mv "${basename}.tar" /staging/groups/zamanian_group/input/

# Optional: move the output into a folder named "sra"
# mkdir -p sra
# mv "/staging/groups/zamanian_group/output/${basename}.tar" sra/
