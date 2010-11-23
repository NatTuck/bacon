


all: Bacon/Parser.pm

Bacon/Parser.pm: Bacon/grammar.yp
	yapp -v -m Bacon::Parser -o Bacon/Parser.pm Bacon/grammar.yp

clean:
	rm -f Bacon/Parser.pm Bacon/grammar.output *~ Bacon/*~

.PHONY: all clean
