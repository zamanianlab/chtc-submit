#!/bin/bash
mkdir input work output

cp -r /staging/groups/zamanian_group/input/accession_list.txt work
cd work

while read -r acc; do
  prefetch "$acc" -O sra_files

  fasterq-dump "output/$acc/$acc.sra" -O . --split-files 

done < accession_list.txt

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/

#move the output into a different folder named sra
