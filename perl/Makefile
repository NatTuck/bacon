
all: Bacon/Parser.pm

Bacon/Parser.pm: Bacon/grammar.yp
	yapp -v -m Bacon::Parser -o Bacon/Parser.pm Bacon/grammar.yp
	mv Bacon/grammar.output Bacon/yapp.output

clean:
	rm -f Bacon/Parser.pm Bacon/yapp.output


.PHONY: all clean
