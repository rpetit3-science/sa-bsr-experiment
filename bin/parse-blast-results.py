#! /usr/bin/env python
import argparse as ap

if __name__ == '__main__':
    parser = ap.ArgumentParser(
        prog='parse-blast-results.py', conflict_handler='resolve',
        description="Print blast results with cluster membership."
    )

    parser.add_argument('query', type=str, metavar="QUERY_BLAST",
                        help=('Blast results against clusters.'))
    parser.add_argument('mapping', type=str, metavar="CLUSTER_MAPPING",
                        help=('Cluster mappings.'))

    args = parser.parse_args()

    # Columns
    # 0: sseqid     3: bitscore     6: qlen      9: mismatch
    # 1: qseqid     4: pident       7: length
    # 2: evalue     5: slen         8: nident

    clusters = {}
    with open(args.mapping, 'r') as f:
        for line in f:
            line = line.rstrip()
            cols = line.split('\t')
            clusters[cols[0]] = cols[1]

    with open(args.query, 'r') as f:
        qseqid = None
        print '\t'.join([
            'sseqid', 'qseqid', 'bitscore', 'slen', 'qlen', 'member_of',
            'top_hit'
        ])
        for line in f:
            line = line.rstrip()
            cols = line.split('\t')

            # sseqid, qseqid, bitscore, evalue, slen, qlen, length
            # pident, fpident
            tmp_qseqid = cols[1].split('-')[0]
            member_of = 'True' if clusters[tmp_qseqid] == cols[0] else 'False'

            top_hit = 'False'
            if qseqid != cols[1]:
                qseqid = cols[1]
                top_hit = 'True'
            print '\t'.join([
                cols[0], cols[1], cols[3], cols[5], cols[6], member_of, top_hit
            ])
