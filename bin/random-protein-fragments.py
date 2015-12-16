#! /usr/bin/env python
import argparse as ap
from numpy import random
from Bio import SeqIO

if __name__ == '__main__':
    parser = ap.ArgumentParser(
        prog='random-protein-fragment.py', conflict_handler='resolve',
        description="Randomly split input proteins to smaller fragments."
    )

    parser.add_argument('fasta', type=str, metavar="FASTA",
                        help=('Protein sequences in FASTA format.'))
    parser.add_argument('--seed', type=int, default=0, metavar="INT",
                        help=('Seed value for random numbers.'))
    parser.add_argument('--min-length', type=int, default=10, metavar="INT",
                        help=('Minimum length for protein sequence. '
                              '(Default 10aa)'))
    parser.add_argument('--num-fragments', type=int, default=20, metavar="INT",
                        help=('Number of times to fragment a protein sequence.'
                              ' (Default 20 times)'))

    args = parser.parse_args()

    if args.seed:
        random.seed(args.seed)

    for seq in SeqIO.parse(args.fasta, "fasta"):
        sequence = list(seq.seq)
        seq_len = len(seq)
        lengths = random.choice(
            xrange(args.min_length, seq_len),
            min(args.num_fragments, seq_len - args.min_length),
            replace=False
        )
        for length in lengths:
            start = random.choice(seq_len - length, 1)[0]
            fragment = ''.join(sequence[start:start + length])
            print '>{0}-{1}\n{2}'.format(seq.id, length, fragment)
