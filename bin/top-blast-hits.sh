#! /bin/bash
# Blast each file against CDHIT cluster database
FASTA=$1
BLASTDB=$2
OUT_DIR=$3
BLAST_HITS=$4
NUM_CPU=$5
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create Blast results directory
mkdir -p ${OUT_DIR}

BASENAME=$(basename "$BLASTDB")

TEMP=($(ls -ln ${FASTA}))
SIZE=${TEMP[4]}
BSIZE=`awk 'BEGIN{print int(("'"${SIZE}"'"/"'"${NUM_CPU}"'")+0.5)}'`

cat $FASTA | parallel --gnu --plain -j ${NUM_CPU} --block ${BSIZE} --recstart '>' --pipe \
"${DIR}/blastp -query - -db ${BLASTDB} -max_target_seqs ${BLAST_HITS} -evalue 1000 \
-outfmt '6 sseqid qseqid evalue bitscore pident slen qlen length nident mismatch'" > ${OUT_DIR}/${BASENAME}.txt
