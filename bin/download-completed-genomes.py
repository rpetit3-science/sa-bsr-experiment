#! /usr/bin/env python
"""
     Author: Robert A Petit III
       Date: 12/07/2015

    Search NCBI RefSeq Nucleotide database for completed Staphyloccocus aureus
    genomes and download the GenBank file for each genome.
"""
import os
import time
from Bio import Entrez, SeqIO
Entrez.email = 'robert.petit@emory.edu'

if __name__ == '__main__':
    db = 'nuccore'
    term = ('((Staphylococcus aureus[Organism]) AND "complete+genome"[Title]) '
            'NOT plasmid[Title] AND srcdb_refseq[PROP]')
    retmax = 1000
    outdir = './data/completed_genomes'

    # For different Types and Modes See The Following Link:
    # http://www.ncbi.nlm.nih.gov/books/NBK25499/table/\
    #        chapter4.T._valid_values_of__retmode_and/?report=objectonly
    rettype = 'gbwithparts'
    retmode = 'text'

    print "Database: {0}".format(db)
    print "Max Records: {0}".format(retmax)
    print "Output Directory: {0}".format(outdir)
    print "Query: {0}".format(term)
    print "----------"

    print "Searching for records..."
    handle = Entrez.esearch(db=db, retmax=retmax, term=term)
    esearch = Entrez.read(handle)
    print "\tFound {0} records.\n".format(esearch["Count"])

    print "Downloading records..."

    accessions = []
    for uuid in esearch['IdList']:
        handle = Entrez.esummary(db=db, id=uuid)
        esummary = Entrez.read(handle)
        accessions.append(esummary[0]["Caption"])

        # CDS as AA
        out_faa = '{0}/{1}.faa'.format(outdir, esummary[0]["Caption"])
        if not os.path.isfile(out_faa):
            print '\tDownloading {0}'.format(esummary[0]["Caption"])
            efetch = Entrez.efetch(db=db, id=uuid, rettype=rettype,
                                   retmode=retmode)
            with open(out_faa, 'w') as fh:
                record = SeqIO.read(efetch, "genbank")
                for feature in record.features:
                    if feature.type == "CDS":
                        if 'translation' in feature.qualifiers:
                            fh.write('>{0}\n{1}\n'.format(
                                feature.qualifiers['locus_tag'][0],
                                feature.qualifiers['translation'][0]
                            ))
            efetch.close()
        else:
            print '\tSkip existing {0}'.format(esummary[0]["Caption"])

        # Don't get office banned! (again...)
        print '\tSleeping for 5 seconds...'
        time.sleep(5)

    print "Outputting list of completed genomes..."
    with open('./data/completed_genomes.txt', 'w') as fh:
        fh.write('\n'.join(accessions))