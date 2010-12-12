


all: Bacon/Parser.pm doc

Bacon/Parser.pm: Bacon/grammar.yp
	yapp -v -m Bacon::Parser -o Bacon/Parser.pm Bacon/grammar.yp

doc:
	(cd doc && make)

prereqs:
	sudo apt-get install libparse-yapp-perl libfile-slurp-perl libmoose-perl libnamespace-autoclean-perl
	sudo bash -c "yes | cpan -i MooseX::Method::Signatures"
	sudo bash -c "yes | cpan -i Moose::Util::TypeConstraints"

clean:
	rm -f Bacon/Parser.pm Bacon/grammar.output *~ Bacon/*~
	rm -rf gen
	(cd doc && make clean)

.PHONY: all clean prereqs doc
