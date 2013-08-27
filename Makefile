# For the user
#
# Add to this variable any other .md files in the directory that you do
# not want processed into tex files

NON_SYLLABUS_FILES := README.md

#
#
# End of user configuration

.DEFAULT_GOAL := syllabus.pdf

# The Haskell cleaner script
# If you don't want to install ghc, then by all means do the following:
# 1. use pandoc's ability to read and write its syntax tree in JSON
# 2. rewrite the cleaner script in something friendlier, like Perl
# 3. generate pull request
html_clean: html_clean.hs
	ghc --make $<

mds := $(wildcard *.md)
mds := $(filter-out $(NON_SYLLABUS_FILES),$(mds))

input_dir := input
texs := $(patsubst %.md,$(input_dir)/%.tex,$(mds))

$(texs): $(input_dir)/%.tex: %.md
	mkdir -p $(input_dir)
	pandoc -o $@ $<

vc:
	./vc

# also, in order to ensure ./vc script is run, dependency on phony vc target
syllabus.pdf: syllabus.tex $(texs) course.bib vc
	xelatex $<
	biber $(basename $<)
	xelatex $<

4ht_src := 4ht
4ht_texs := $(patsubst $(input_dir)/%.tex,$(4ht_src)/%.tex,$(texs))

# kludge to deal with tex4ht having trouble with \begin{enumerate}[1.]
# generated by pandoc.
# we'll just spit out "4ht" versions of what we need
# TODO proper fix
$(4ht_texs): $(4ht_src)/%.tex: $(input_dir)/%.tex
	mkdir -p $(4ht_src)
	sed 's/enumerate}\[..\]/enumerate}/' $< > $@

# In order to get a successful tex4ht run in conjunction with biblatex,
# we have to first generate the needed auxiliary files, so even though
# syllabus-4ht.pdf is not needed, we make it for its side effects.
#
# NB tex4ht does not support xelatex, really, so our base tex file
# is instead tweaked for pdflatex
#
# kludge again: need to clear aux file every time for some reason
# TODO solve bug
syllabus-4ht.pdf: syllabus-4ht.tex $(4ht_texs) course.bib
	rm -f $(<:tex=aux)
	pdflatex $<
	biber $(basename $<)

syllabus-4ht.html: syllabus-4ht.pdf syllabus-4ht.cfg
	htlatex syllabus-4ht.tex syllabus-4ht.cfg " -cunihtf -utf8" "-cvalidate"

# syllabus.html is the cleaned-up version
syllabus.html: syllabus-4ht.html html_clean
	./html_clean < $< > $@

#I like to keep my bibliography in Zotero. This will dump the entire Zotero library into a bib file.
course.bib:
	perl zoteroImport/getBibTexFromZotero.pl > course.bib


clean:
	rm -f *.aux *.log
	# generated TeX sources
	rm -rf $(input_dir)
	# vc
	rm -f vc.tex
	# hyperref
	rm -f *.out 
	# biber
	rm -f *.bbl *.bcf *.blg *.run.xml
	# tex4ht
	rm -f *.4ct *.4tc *.dvi *.idv *.lg *.tmp *.xref
	# ghc
	rm -f *.hi *.ho *.o
	# tex4ht: specific files
	rm -f syllabus-4ht.css syllabus-4ht.pdf syllabus-4ht.html
	# tex4ht-tweaked sources
	rm -rf $(4ht_src)

clean_outputs:
	# final outputs
	rm -f syllabus.pdf syllabus.html html_clean

reallyclean: clean clean_outputs

# Edit this target for automated uploads
publish: syllabus.html
	pbcopy < syllabus.html

all: syllabus.pdf syllabus.html

.PHONY: all vc clean clean_outputs reallyclean publish
