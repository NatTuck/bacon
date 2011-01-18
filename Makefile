


all: Bacon/Parser.pm doc

Bacon/Parser.pm: Bacon/grammar.yp
	yapp -v -m Bacon::Parser -o Bacon/Parser.pm Bacon/grammar.yp
	mv Bacon/grammar.output Bacon/yapp.output

doc:
	(cd doc && make)

prereqs:
	sudo apt-get install libparse-yapp-perl libfile-slurp-perl libmoose-perl libnamespace-autoclean-perl libtext-template-perl

examples: all
	find examples -maxdepth 1 -mindepth 1 -type d \
		        -exec sh -c '(cd {} && make)' \;

test: examples
	prove examples/*/t/*.t

clean:
	rm -f Bacon/Parser.pm Bacon/yapp.output *~ Bacon/*~
	rm -rf gen
	(cd doc && make clean)
	find examples -maxdepth 1 -mindepth 1 -type d \
		-exec sh -c '(cd {} && make clean)' \;
	find . -name "*~" -exec rm {} \; 

.PHONY: all clean prereqs test doc
