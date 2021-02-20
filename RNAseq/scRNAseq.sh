#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output
mkdir output/$1

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar input
#cd input && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd .. #for RD structure
cd input && tar -xvf $1.tar && rm $1.tar && cd .. #for brc transfer no file structure


# download the genome and the brugia annotation gtf
species="brugia_malayi"
release="WBPS15"
prjn="PRJNA10729"
prefix="ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/${release}/species/${species}/${prjn}"

echo '${prefix}'
wget -c ${prefix}/${species}.${prjn}.${release}.canonical_geneset.gtf.gz -O work/geneset.gtf.gz
wget -c ${prefix}/${species}.${prjn}.${release}.genomic.fa.gz -O work/reference.fa.gz

cd work
zcat reference.fa.gz > reference.fa
zcat geneset.gtf.gz > geneset.gtf

# make a filtered version of the gtf without any pseudogenes etc.
cellranger mkgtf geneset.gtf geneset.cellranger.gtf \
    --attribute=gene_biotype:protein_coding

# cellranger make reference
cellranger mkref --nthreads 40 \
    --genome="$species" \
    --fasta=reference.fa \
    --genes=geneset.cellranger.gtf

# run cellranger
cd ..
cellranger count --id=$1 \
                   --transcriptome=work/$species \
                   --fastqs=input/$1/ \
                   --sample=$1 \
                   --expect-cells=10,000 \
                   --localcores=40 \
                   --localmem=256

# mkdir STAR_index
# STAR --runThreadN 12 --runMode genomeGenerate  --genomeDir STAR_index \
#   --genomeFastaFiles reference.fa \
#   --sjdbGTFfile geneset.gtf \
#   --genomeSAindexNbases 12 \
#   --sjdbOverhang 150
# cd ..
#
# # align trimmed reads to genome
# STAR --runThreadN 12 --runMode alignReads --genomeDir work/STAR_index \
#   --outSAMtype BAM Unsorted --readFilesCommand zcat \
#   --outFileNamePrefix output/$1/singlecell. --readFilesIn work/out.R1.fq.gz work/out.R2.fq.gz \
#   --peOverlapNbasesMin 10 \
#   --quantMode GeneCounts --outSAMattrRGline ID:sc
# cd output/$1
# samtools sort -@ 12 -m 12G -o singlecell.bam singlecell.Aligned.out.bam
# rm *.Aligned.out.bam
# samtools index -@ 12 -b singlecell.bam
# samtools flagstat singlecell.bam > singlecell.flagstat.txt
# cat singlecell.ReadsPerGene.out.tab | cut -f 1,2 > singlecell.ReadsPerGene.tab
# cd ~
#
# # rm files you don't want transferred back to /home/{net-id}
# rm -r work input
#
# # tar output folder and delete it
# cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..
#
# # remove staging output tar if there from previous run
# rm -f /staging/groups/zamanian_group/output/$1.tar
#
# # mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
# mv output/$1.tar /staging/groups/zamanian_group/output/
