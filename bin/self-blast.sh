#! /bin/bash
# Blast each file against itself to get reference BSR
FASTA_DIR=$1
BLASTDB_DIR=$2
OUT_DIR=$3
NUM_CPU=$4
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create Blast results directory
mkdir -p ${OUT_DIR}

for fasta in ${FASTA_DIR}/*; do
    BASENAME=$(basename "$fasta")
    RECORDS=`grep -c '^>' $fasta`

    TEMP=($(ls -ln $fasta))
    SIZE=${TEMP[4]}
    BSIZE=`awk 'BEGIN{print int(("'"${SIZE}"'"/"'"${NUM_CPU}"'")+0.5)}'`

    cat $fasta | parallel --gnu --plain -j ${NUM_CPU} --block ${BSIZE} --recstart '>' --pipe \
       "${DIR}/blastp -query - -db ${BLASTDB_DIR}/${BASENAME} -max_hsps 1 -max_target_seqs 1 \
       -evalue 1000 -outfmt '6 sseqid qseqid bitscore'" > ${OUT_DIR}/${BASENAME}.txt
done
