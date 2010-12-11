
all: BaconManual.pdf

BaconManual.pdf: BaconManual.tex
	pdflatex BaconManual.tex
	pdflatex BaconManual.tex

clean:
	rm -f *.dvi *.pdf *.aux *.log

.PHONY: all clean
