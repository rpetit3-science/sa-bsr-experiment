#! /bin/bash
# Create a BLASTDB for each FASTA file in a given directory
FASTA_DIR=$1
BLASTDB_DIR=$2
DBTYPE=$3
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Create Blast DB directory
mkdir -p ${BLASTDB_DIR}

for fasta in ${FASTA_DIR}/*; do
    BASENAME=$(basename "$fasta")
    ${DIR}/makeblastdb -in $fasta -out ${BLASTDB_DIR}/${BASENAME} -dbtype ${DBTYPE}
done
