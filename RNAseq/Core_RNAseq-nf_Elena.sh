# !/bin/bash

# set home () and mk dirs
export HOME=$PWD
mkdir input work output

# echo core, thread, and memory
# echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
# grep 'cpu cores' /proc/cpuinfo | uniq
# echo $(free -g)

# copy and extract all input tar files
for sample in "$@"; do
    echo "Processing sample: $sample"
    cp -r /staging/groups/zamanian_group/input/${sample}.tar input/
    cd input
    tar -xvf ${sample}.tar
    rm ${sample}.tar
    cd ..
done

# clone nextflow git repo
git clone https://github.com/zamanianlab/Core_RNAseq-nf.git

# run nextflow (QC, star) for Diro workflow
export NXF_OPTS='-Xms1g -Xmx8g'

#if one file
# nextflow run Core_RNAseq-nf/WB-pe.nf -w work -c Core_RNAseq-nf/chtc.config --dir $1\
# if multiple files
nextflow run Core_RNAseq-nf/WB-pe.nf -w work -c Core_RNAseq-nf/chtc.config --dir input \
#   --star --release "WBPS19" --species "schistosoma_mansoni" --prjn "PRJEA36577" --rlen "50"
#   --star --release "WBPS18" --species "dirofilaria_immitis" --prjn "PRJNA723804" --rlen "150"
#  --star --release "WBPS18" --species "dirofilaria_immitis" --prjn "PRJEB1797" --rlen "150"
  --star --release "WBPS19" --species "brugia_malayi" --prjn "PRJNA10729" --rlen "150"

# rm files you don't want transferred back to /home/{net-id}
rm -r work input

# tar and move output (use a combined name)
output_name="combined_inputs_$(date +%Y%m%d_%H%M%S)"
cd output
tar -cvf ${output_name}.tar ./*
cd ..

# remove any old copy, then move tarball to staging
STAGING_OUT="/staging/groups/zamanian_group/output"
rm -f ${STAGING_OUT}/${output_name}.tar
mv output/${output_name}.tar ${STAGING_OUT}/

# move to staging area
rm -f /staging/groups/zamanian_group/output/${output_name}.tar
mv output/${output_name}.tar /staging/groups/zamanian_group/output/
