#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output
mkdir output/$1

# transfer and decompress input data from staging ($1 is ${dir} from args)
cp -r /staging/groups/zamanian_group/input/$1.tar input
cd input && tar -xvf $1.tar && rm $1.tar && mv */*/* $1 && cd .. #for RD structure
#cd input && tar -xvf $1.tar && rm $1.tar && cd .. #for brc transfer no file structure

# rm non-fastq files from input directory
cd input/$1
find . -type f ! -name '*.fastq.gz' -delete
cd .. && cd ..


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

# extend 3' UTRs by set length (geneset.gtf > geneset.3ext.gtf)
wget https://raw.githubusercontent.com/zamanianlab/Core_RNAseq-nf/master/auxillary/sc_scripts/gtf_process.R
Rscript --vanilla gtf_process.R 400

# make a filtered version of the gtf without any pseudogenes etc.
#cellranger mkgtf geneset.3ext.gtf geneset.cellranger.gtf \
#    --attribute=gene_biotype:protein_coding

# cellranger make reference
cellranger mkref --nthreads 60 \
    --genome="$species" \
    --fasta=reference.fa \
    --genes=geneset.3ext.gtf
  #  --genes=geneset.cellranger.gtf

# run cellranger
cd .. && cd output
cellranger count --id=$1 \
                   --transcriptome=../work/$species \
                   --fastqs=../input/$1/ \
                   --sample=tBM,utBM \
                   #--lanes=1 \
                   --include-introns \
                  # --force-cells=10000 \
                   --localcores=60 \
                   --localmem=290
cd ..

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar output folder and delete it
cd output && tar -cvf $1.tar $1 && rm -r $1 && cd ..

# remove staging output tar if there from previous run
rm -f /staging/groups/zamanian_group/output/$1.tar

# mv large output files to staging output folder; avoid their transfer back to /home/{net-id}
mv output/$1.tar /staging/groups/zamanian_group/output/
