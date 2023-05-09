all: cloudsuite.pdf cloudsuite.tex

.DELETE_ON_ERROR:

%.pdf: %.eps
	epstopdf $<

cloudsuite.eps cloudsuite.tex: cloudsuite.gnuplot cloudsuite.dat
	gnuplot $<

cloudsuite.dat: process.py $(wildcard data/*/*/*.log)
	python3 process.py data > $@

clean::
	$(RM) cloudsuite.eps cloudsuite.tex cloudsuite.pdf cloudsuite.dat
