#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# adapter-trimming
fastp -i input/1_S1_L001_R1_001.fastq.gz -I input/1_S1_L001_R2_001.fastq.gz -o work/out.R1.fq.gz -O work/out.R2.fq.gz

# download the genome and the brugia annotation gtf
wget -c ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/WBPS15/species/brugia_malayi/PRJNA10729/brugia_malayi.PRJNA10729.WBPS15.genomic.fa.gz -O work/reference.fa.gz
wget -c ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/WBPS15/species/brugia_malayi/PRJNA10729/brugia_malayi.PRJNA10729.WBPS15.canonical_geneset.gtf.gz -O work/geneset.gtf.gz

# index genome with STAR
cd work
zcat reference.fa.gz > reference.fa
zcat geneset.gtf.gz > geneset.gtf

mkdir STAR_index
STAR --runThreadN 12 --runMode genomeGenerate  --genomeDir STAR_index \
  --genomeFastaFiles reference.fa \
  --sjdbGTFfile geneset.gtf \
  --sjdbOverhang 150

# align trimmed reads to genome
cd ..
STAR --runThreadN 12 --runMode alignReads --genomeDir work/STAR_index\
  --outSAMtype BAM Unsorted --readFilesCommand zcat \
  --outFileNamePrefix output/singlecell. --readFilesIn work/out.R1.fq.gz work/out.R2.fq.gz\
  --peOverlapNbasesMin 10 \
  --quantMode GeneCounts --outSAMattrRGline ID:singlecell
cd output
samtools sort -@ 12 -m 64G -o singlecell.bam singlecell.Aligned.out.bam
rm *.Aligned.out.bam
samtools index -@ 12 -b singlecell.bam
samtools flagstat singlecell.bam > singlecell.flagstat.txt
cat singlecell.ReadsPerGene.out.tab | cut -f 1,2 > singlecell.ReadsPerGene.tab
cd ..

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/
