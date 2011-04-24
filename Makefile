
BACON="./bin/bacon"
LIB=libbacon.so
HDRS=include/ocl/Bacon/Array.cl

all: Bacon/Parser.pm doc lib/$(LIB) $(HDRS)

Bacon/Parser.pm: Bacon/grammar.yp
	yapp -v -m Bacon::Parser -o Bacon/Parser.pm Bacon/grammar.yp
	mv Bacon/grammar.output Bacon/yapp.output

lib/$(LIB): src/$(LIB)
	mkdir -p lib
	cp src/$(LIB) lib/$(LIB)

src/$(LIB):
	(cd src && make)

doc:
	(cd doc && make)

$(HDRS): Bacon/Parser.pm
	$(BACON) --genstdlib include

prereqs:
	sudo apt-get install build-essential libboost-dev libparse-yapp-perl libfile-slurp-perl libmoose-perl libnamespace-autoclean-perl libtext-template-perl texlive-latex-base libclone-perl libdata-section-perl libdevel-cover-perl indent

examples: all
	find examples -maxdepth 1 -mindepth 1 -type d \
		        -exec sh -c '(cd {} && make)' \;

test: examples
	prove examples/*/t/*.t

clean:
	rm -f Bacon/Parser.pm Bacon/yapp.output *~ Bacon/*~
	rm -f lib/$(LIB) $(HDRS)
	(cd src && make clean)
	(cd doc && make clean)
	find examples -maxdepth 1 -mindepth 1 -type d \
		-exec sh -c '(cd {} && make clean)' \;
	find . -name "*~" -exec rm {} \; 

.PHONY: all clean prereqs test doc stdlib
