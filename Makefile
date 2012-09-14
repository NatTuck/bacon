
BACON="./bin/bacon"

all: parser lib hdrs
	cp src/cl_perror.hh include

parser:
	(cd perl && make)

lib:
	(cd src && make)
	mkdir -p lib
	cp src/*.so lib

hdrs: parser
	$(BACON) --genstdlib include

prereqs:
	sudo apt-get install build-essential libboost-dev libparse-yapp-perl libfile-slurp-perl libmoose-perl libnamespace-autoclean-perl libtext-template-perl libclone-perl libdata-section-perl libdevel-cover-perl indent mesa-common-dev libperl-dev libdevel-size-perl

examples: all
	find examples -maxdepth 1 -mindepth 1 -type d \
		        -exec sh -c '(cd {} && make)' \;

test: examples
	prove examples/*/t/*.t

clean:
	find . -name "*~" -exec rm {} \;
	(cd perl && make clean)
	rm -f lib/*.so
	rm -f include/cl_perror.hh include/ocl/Bacon/Array.cl
	(cd src && make clean)
	find examples -maxdepth 1 -mindepth 1 -type d \
		-exec sh -c '(cd {} && make clean)' \;

.PHONY: all parser lib hdrs prereqs examples test clean
