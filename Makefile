#
#
TOP_DIR := $(shell pwd)
BIN_DIR := $(TOP_DIR)/bin/
DATA_DIR := $(TOP_DIR)/data/
SRC_DIR := $(TOP_DIR)/src/
NUM_CPU ?= 1

.PHONY: ${CLUSTERS}
all: programs dl-genomes reference-bitscores cat-proteins cluster-proteins

programs: blast cdhit


###############################################################################
###############################################################################
###############################################################################
#### Download BLAST 2.2.31+
BLAST_DIR := $(SRC_DIR)/ncbi-blast-2.2.31+/

$(SRC_DIR)/ncbi-blast-2.2.31+-x64-linux.tar.gz:
	mkdir -p $(SRC_DIR)
	wget -O $@ ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.31/ncbi-blast-2.2.31+-x64-linux.tar.gz

$(BLAST_DIR): $(SRC_DIR)/ncbi-blast-2.2.31+-x64-linux.tar.gz
	tar -C $(SRC_DIR) -xzvf $^
	find $@/ -exec touch {} \;
	mkdir -p $(BIN_DIR)
	ln -s  $@/bin/blastp $(BIN_DIR)/blastp
	ln -s  $@/bin/makeblastdb $(BIN_DIR)/makeblastdb

blast: $(BLAST_DIR)

###############################################################################
###############################################################################
###############################################################################
#### Download CD-HIT 4.6.4
CDHIT_DIR := $(SRC_DIR)/cd-hit-v4.6.4-2015-0603/
$(SRC_DIR)/cd-hit-v4.6.4-2015-0603.tar.gz:
	mkdir -p $(SRC_DIR)
	wget -O $@ https://github.com/weizhongli/cdhit/releases/download/V4.6.4/cd-hit-v4.6.4-2015-0603.tar.gz

$(CDHIT_DIR): $(SRC_DIR)/cd-hit-v4.6.4-2015-0603.tar.gz
	tar -C $(SRC_DIR) -xzvf $^
	find $@/ -exec touch {} \;
	mkdir -p $(BIN_DIR)
	make -C $(CDHIT_DIR)
	ln -s  $@/cd-hit $(BIN_DIR)/cd-hit

cdhit: $(CDHIT_DIR)


###############################################################################
###############################################################################
###############################################################################
#### Download Protein Sequences From Completed S. aureus Genomes
GENOMES_DIR := $(DATA_DIR)/completed-genomes
MAX_GENOMES ?= 0
$(GENOMES_DIR)/completed-genomes.txt:
	mkdir -p $(GENOMES_DIR)/fasta
	$(BIN_DIR)/download-completed-genomes.py --retmax=$(MAX_GENOMES)
	find $(GENOMES_DIR)/fasta -empty -type f -delete

dl-genomes: $(GENOMES_DIR)/completed-genomes.txt


###############################################################################
###############################################################################
###############################################################################
#### Make Blast Database and get reference bitscores (hits against themselves)
BLASTDB_DIR := $(GENOMES_DIR)/blastdb
SELF_HITS_DIR := $(GENOMES_DIR)/blast-self
$(BLASTDB_DIR)/makeblastdb.txt: $(GENOMES_DIR)/completed-genomes.txt
	mkdir -p $(BLASTDB_DIR)
	$(BIN_DIR)/fasta-to-blastdb.sh $(GENOMES_DIR)/fasta $(BLASTDB_DIR) prot > $@

$(GENOMES_DIR)/reference-bitscores.txt: $(BLASTDB_DIR)/makeblastdb.txt
	mkdir -p $(SELF_HITS_DIR)
	$(BIN_DIR)/self-blast.sh $(GENOMES_DIR)/fasta $(BLASTDB_DIR) $(SELF_HITS_DIR) $(NUM_CPU)
	cat $(SELF_HITS_DIR)/*.txt > $(GENOMES_DIR)/reference-bitscores.txt

reference-bitscores: $(GENOMES_DIR)/reference-bitscores.txt


###############################################################################
###############################################################################
###############################################################################
#### Create clusters, based on UniRef construction
$(GENOMES_DIR)/completed-genomes.faa: $(GENOMES_DIR)/completed-genomes.txt
	cat $(GENOMES_DIR)/fasta/*.faa > $@

cat-proteins: $(GENOMES_DIR)/completed-genomes.faa

NAME := 50 60 70 80 90 100
IDENTITY := 0.50 0.60 0.70 0.80 0.90 1.00
WORD_SIZE := 3 3 5 5 5 5
COVERAGE ?= 0.80

CLUSTERS := $(addprefix cluster-, $(join $(NAME), $(join $(addprefix -, $(IDENTITY)), $(addprefix -, $(WORD_SIZE)))))
name = $(firstword $(subst -, ,$*))
identity = $(wordlist 2, 2, $(subst -, ,$*))
word_size = $(lastword $(subst -, ,$*))
cluster-proteins: ${CLUSTERS}

${CLUSTERS}: cluster-%: $(GENOMES_DIR)/completed-genomes.faa
	@echo $@
	mkdir -p $(GENOMES_DIR)/clusters/sa$(name)
	$(eval BASE_PREFIX=$(GENOMES_DIR)/clusters/sa$(name)/sa$(name))
	# Cluster proteins based on percent identity and coverage of alignment
	$(BIN_DIR)/cd-hit -T $(NUM_CPU) -i $^ -o $(BASE_PREFIX) -c $(identity) \
	                  -aL $(COVERAGE) -n $(word_size) -d 0 -g 1\
	                  > $(BASE_PREFIX).out 2> $(BASE_PREFIX).err
	# Parse clstr file to a more readable format
	$(BIN_DIR)/parse-clusters.py $(BASE_PREFIX).clstr > $(BASE_PREFIX).mappings
	# Make Blast Database of the clusters
	$(BIN_DIR)/makeblastdb -in $(BASE_PREFIX) -dbtype prot
	# Get top two hits
	$(BIN_DIR)/top-two-blast-hits.sh \
	    $(GENOMES_DIR)/completed-genomes.faa \
	    $(BASE_PREFIX) \
	    $(GENOMES_DIR)/blast-clusters \
	    $(NUM_CPU)
	# Parse the results
	$(BIN_DIR)/parse-blast-results.py \
	    $(GENOMES_DIR)/reference-bitscores.txt \
	    $(GENOMES_DIR)/blast-clusters/sa$(name).txt \
	    $(BASE_PREFIX).mappings \
	    > $(GENOMES_DIR)/blast-clusters/sa$(name).bsr.txt \
	    2> $(GENOMES_DIR)/blast-clusters/sa$(name).dupes.txt

###############################################################################
###############################################################################
###############################################################################
#### Clean Up Everything
clean:
	rm -rf $(SRC_DIR) $(BIN_DIR)/makeblastdb $(BIN_DIR)/blastp $(BIN_DIR)/cd-hit $(DATA_DIR)
