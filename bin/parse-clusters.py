#! /usr/bin/env python
import argparse as ap

if __name__ == '__main__':
    parser = ap.ArgumentParser(
        prog='parse-clusters.py', conflict_handler='resolve',
        description="Print cluster mappings from CDHIT."
    )

    parser.add_argument('cluster', type=str, metavar="CLUSTERS",
                        help=('.clstr output from CDHIT.'))

    args = parser.parse_args()

    clusters = {}
    with open(args.cluster, 'r') as f:
        cluster = None
        for line in f:
            line = line.rstrip()
            '''
            Example
            >Cluster 0
            0   10498aa, >SACOL_RS07510... at 80.44%
            1   10746aa, >SAR_RS07395... *
            2   9904aa, >MW_RS07115... at 61.52%
            '''
            if line.startswith('>'):
                cluster = line
                clusters[cluster] = {'seed': None, 'members': []}
            else:
                member = line.split('>')[1].split('...')[0]
                if line.endswith('*'):
                    clusters[cluster]['seed'] = member
                clusters[cluster]['members'].append(member)

    for key, value in clusters.iteritems():
        seed = clusters[key]['seed']
        for member in clusters[key]['members']:
            print '{0}\t{1}'.format(member, seed)
