
Paper.pdf: Paper.tex Makefile bacon.bib
	pdflatex Paper.tex
	bibtex Paper
	pdflatex Paper.tex
	pdflatex Paper.tex

clean:
	rm -f *.pdf *.log *.aux *.bbl *.blg *~
