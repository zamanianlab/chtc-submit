#!/bin/bash

# Run Trinity
docker run -it --rm \
  -v pwd:/data \
  trinityrnaseq/trinityrnaseq \
  Trinity --seqType fq --max_memory 10G \
  --left /data/*_1.fastq \
  --right /data/*_2.fastq \
  --CPU 4 --output /data/trinity_out_dir

echo "Trinity de novo assembly complete. Output: $assembly_dir"
