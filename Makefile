TOP_DIR := $(shell pwd)
BIN_DIR := $(TOP_DIR)/bin/
DATA_DIR := $(TOP_DIR)/data/
SRC_DIR := $(TOP_DIR)/src/

.PHONY: ${CLUSTERS}
all: programs dl-genomes

programs: blast cdhit

#### Download BLAST 2.2.31+ ####
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

#### Download CD-HIT 4.6.4 ####
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

#### Download Protein Sequences From Completed S. aureus Genomes ####
$(DATA_DIR)/completed_genomes.txt:
	mkdir -p $(DATA_DIR)completed_genomes/
	$(BIN_DIR)/download_completed_genomes.py

dl-genomes: $(DATA_DIR)/completed_genomes.txt


#### Create clusters, based on UniRef construction. ####
$(DATA_DIR)/completed_genomes.faa: $(DATA_DIR)/completed_genomes.txt
	cat $(DATA_DIR)completed_genomes/*.faa > $(DATA_DIR)/completed_genomes.faa

NAME := 50 60 70 80 90 100
IDENTITY := 0.50 0.60 0.70 0.80 0.90 1.00
WORD_SIZE := 3 3 5 5 5 5
COVERAGE ?= 0.80
NUM_THREADS ?= 1
CLUSTERS := $(addprefix cluster-, $(join $(NAME), $(join $(addprefix -, $(IDENTITY)), $(addprefix -, $(WORD_SIZE)))))
name = $(firstword $(subst -, ,$*))
identity = $(wordlist 2, 2, $(subst -, ,$*))
word_size = $(lastword $(subst -, ,$*))
cluster_proteins: ${CLUSTERS}

${CLUSTERS}: cluster-%: $(DATA_DIR)/completed_genomes.faa
	@echo $@
	mkdir -p $(DATA_DIR)/clusters/SA$(name)
	$(BIN_DIR)/cd-hit -T $(NUM_THREADS) -i $^ -o $(DATA_DIR)/clusters/SA$(name)/SA$(name) \
	                  -c $(identity) -aL $(COVERAGE) -n $(word_size) -d 0

#### Clean Up Everything ####
clean:
	rm -rf $(SRC_DIR) $(BIN_DIR) $(DATA_DIR)
