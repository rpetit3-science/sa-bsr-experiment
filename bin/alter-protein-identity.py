#! /usr/bin/env python
import argparse as ap
from numpy import random
from Bio import SeqIO
from Bio.Data.IUPACData import protein_letters


def mutate_base(aa):
    return random.choice(list(protein_letters.replace(aa, '')), 1)[0]

if __name__ == '__main__':
    parser = ap.ArgumentParser(
        prog='alter-protein-identity.py', conflict_handler='resolve',
        description="Reduces protein identities, prints sequences to STDOUT."
    )

    parser.add_argument('reference', type=str, metavar="REFERENCE_FASTA",
                        help=('Input list of reference bitscores.'))
    parser.add_argument('--min_identity', default=0, type=int, metavar="INT",
                        help=('Minimum seq identity to test. (Default: 0)'))
    parser.add_argument('--seed', default=0, type=int, metavar="INT",
                        help=('A seed to set for reproducible results.'))

    args = parser.parse_args()

    if args.seed:
        random.seed(args.seed)

    for seq in SeqIO.parse(args.reference, "fasta"):
        # Get maximum number of bases to mutate
        max_bases = len(seq)
        if args.min_identity:
            max_bases = int(len(seq) * (1 - (args.min_identity / 100.00)))

        mutated_seq = list(seq.seq)
        mutations = 0
        positions = random.choice(len(seq), max_bases, replace=False)
        print '>{0}\n{1}'.format(
            seq.id, ''.join(mutated_seq)
        )
        for pos in positions:
            mutated_seq[pos] = mutate_base(mutated_seq[pos])
            mutations += 1
            print '>{0}_{1}\n{2}'.format(
                seq.id, mutations, ''.join(mutated_seq)
            )
