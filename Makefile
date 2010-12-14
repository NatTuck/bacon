


all: Bacon/Parser.pm doc

Bacon/Parser.pm: Bacon/grammar.yp
	yapp -v -m Bacon::Parser -o Bacon/Parser.pm Bacon/grammar.yp
	mv Bacon/grammar.output Bacon/yapp.output

doc:
	(cd doc && make)

prereqs:
	sudo apt-get install libparse-yapp-perl libfile-slurp-perl libmoose-perl libnamespace-autoclean-perl

test: all
	./bacon add.bc && cat gen/add.cl

clean:
	rm -f Bacon/Parser.pm Bacon/yapp.output *~ Bacon/*~
	rm -rf gen
	(cd doc && make clean)

.PHONY: all clean prereqs test doc
