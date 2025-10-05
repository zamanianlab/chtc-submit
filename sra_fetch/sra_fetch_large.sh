#!/bin/bash
set -euo pipefail

# Arguments: accession list (optional), single accession (required)
ACC=$1

echo "=== Starting SRA fetch for accession: ${ACC} ==="

# Make clean directories
mkdir -p work sra_files_output tmp
cd work

# Fetch and convert SRA -> FASTQ
echo "Running fasterq-dump for ${ACC} ..."
fasterq-dump "${ACC}" \
  --split-files \
  -O ./ \
  --temp ./tmp \
  --threads 4

# Move results to output folder
mv "${ACC}"_*.fastq ../sra_files_output/ 2>/dev/null

# Clean temp directories
rm -rf ./tmp ./ncbi || true

cd ..

# Tar the output fastqs
tar -cvf "${ACC}.tar" sra_files_output
rm -rf sra_files_output work

# Move tarball to staging area
STAGING="/staging/groups/zamanian_group/input"
rm -f "${STAGING}/${ACC}.tar"  # remove any previous tar
mv "${ACC}.tar" "${STAGING}/"

echo "=== Finished ${ACC} successfully ==="
