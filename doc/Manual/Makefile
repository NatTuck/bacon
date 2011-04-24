
all: BaconManual.pdf

BaconManual.pdf: BaconManual.tex
	pdflatex BaconManual.tex > build.log
	pdflatex BaconManual.tex >> build.log

clean:
	rm -f *.dvi *.pdf *.aux *.log

.PHONY: all clean
