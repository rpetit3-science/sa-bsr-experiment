#! /usr/bin/env python
from __future__ import print_function
import sys
import argparse as ap

if __name__ == '__main__':
    parser = ap.ArgumentParser(
        prog='parse-blast-results.py', conflict_handler='resolve',
        description="Print blast results with BSR."
    )

    parser.add_argument('reference', type=str, metavar="REFERENCE_BLAST",
                        help=('Blast results of self hits.'))
    parser.add_argument('query', type=str, metavar="QUERY_BLAST",
                        help=('Blast results against clusters.'))
    parser.add_argument('mapping', type=str, metavar="CLUSTER_MAPPING",
                        help=('Cluster mappings.'))

    args = parser.parse_args()

    # Columns
    # 0: sseqid     3: bitscore     6: qlen      9: mismatch
    # 1: qseqid     4: pident       7: length
    # 2: evalue     5: slen         8: nident

    reference_bitscores = {}
    with open(args.reference, 'r') as f:
        for line in f:
            line = line.rstrip()
            cols = line.split('\t')
            reference_bitscores[cols[1]] = float(cols[2])
            if cols[0] != cols[1]:
                print(
                    ('Please check {0}--{1}, best hit is not to itself! '
                     'Assuming multiple copy gene.').format(cols[0], cols[1]),
                    file=sys.stderr
                )

    clusters = {}
    with open(args.mapping, 'r') as f:
        for line in f:
            line = line.rstrip()
            cols = line.split('\t')
            clusters[cols[0]] = cols[1]

    with open(args.query, 'r') as f:
        for line in f:
            line = line.rstrip()
            cols = line.split('\t')

            # sseqid, qseqid, bitscore, evalue, bsr, pident, fpident
            bsr = float(cols[3]) / reference_bitscores[cols[0]]
            fpident = float(cols[8]) / int(cols[5])
            member_of = 'True' if clusters[cols[1]] == cols[0] else 'False'
            print('{0}\t{1}\t{2}\t{3}\t{4:.4f}\t{5}\t{6:.2f}\t{7}'.format(
                cols[0], cols[1], cols[3], cols[2], bsr, cols[4],
                fpident * 100, member_of
            ))
