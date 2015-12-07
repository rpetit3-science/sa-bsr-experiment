TOP_DIR := $(shell pwd)
BIN_DIR := $(TOP_DIR)/bin/
SRC_DIR := $(TOP_DIR)/src/

all: dl-blast

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

dl-blast: $(BLAST_DIR)

#### Clean Up Everything ####
clean:
	rm -rf $(SRC_DIR) $(BIN_DIR)
