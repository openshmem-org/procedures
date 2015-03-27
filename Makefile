# LaTeX -*-Makefile-*-
#
# $HEADER$
# 

# MAIN_TEX: In order to build your document, fill in the MAIN_TEX
# macro with the name of your main .tex file -- the one that you
# invoke LaTeX on.

MAIN_TEX	= procedures.tex

# OTHER_SRC_FILES: Put in the names of all the other .tex files that
# this document depends on in the OTHER_SRC_FILES macro.  This is
# ensure that whenever one of the "other" files changes, "make" will
# rebuild your paper.

OTHER_SRC_FILES	= terms.tex voting.tex voters.tex proposers.tex

# BibTeX sources.  The bibliography will automatically be re-generated
# if these files change.

BIBTEX_SOURCES = 

# xfig figures.  Will be converted to .eps and .pdf as necessary.

FIG_FILES      = 

# Files that alredy exist as .png.  Will be converted to .eps and .pdf
# as necessary.

PNG_FILES      = 

# Files that alredy exist as .eps.  Will be converted to .pdf as
# necessary.

EPS_FILES	=

# Required commands and options

PDFLATEX	= pdflatex
MAKEINDEX	= makeindex
BIBTEX		= bibtex
FIG2DEV		= fig2dev
PNGTOPNM	= pngtopnm
PNMTOPS		= pnmtops
PS2PDF          = ps2pdf
PS2PDF_OPTIONS  = -sPaperSize=letter -dAutoFilterGrayImages=false \
		-dGrayDownSample=false -sGrayImageFilter=LZWEncode \
		-dAutoFilterColorImages=false -sColorImageFilter=LZWEncode \
		-dColorDownSample=false -dEmbedAllFonts=true \
		-dSubsetFonts=true

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

.SUFFIXES:	.tex .pdf .fig .eps .png

MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)
MAIN_BBL	= $(MAIN_TEX:.tex=.bbl)
MAIN_BASENAME	= $(MAIN_TEX:.tex=)
EPS_PNG_FILES	= $(PNG_FILES:.png=.eps)
EPS_FIG_FILES	= $(FIG_FILES:.fig=.eps)
PDF_FIG_FILES	= $(FIG_FILES:.fig=.pdf)
PDF_EPS_FILES	= $(EPS_FILES:.eps=.pdf)

#
# Some common target names
# Note that the default target is "ps"
#

pdf: $(MAIN_PDF)

#
# Make the dependencies so that things build when they need to
#

$(MAIN_PDF): $(MAIN_TEX) $(CITE_TEX) $(OTHER_SRC_FILES) $(PDF_FIG_FILES) $(PNG_FILES) $(MAIN_BBL) $(PDF_EPS_FILES)

#
# Search strings
#

REFERENCES = "(There were undefined references|Rerun to get (cross-references|the bars) right|No file *[aux|toc|lof|lot])"
NEEDINDEX = "Writing index file"
RERUNBIB = "No file.*\.bbl|LaTeX Warning: Citation|LaTeX Warning: Label\(s\) may"

#
# General rules
#

.fig.eps:
	$(FIG2DEV) -L eps $< $@

.fig.pdf:
	$(FIG2DEV) -L pdf $< $@

.eps.pdf:
	@if ( which $(DISTILL) > /dev/null 2>&1 ); then \
		cmd="$(DISTILL) $(DISTILL_OPTIONS) $*.eps $*.pdf" ; \
                echo $$cmd ; \
                eval $$cmd ;\
	elif ( which $(PS2PDF) > /dev/null 2>&1 ); then \
		cmd="$(PS2PDF) $(PS2PDF_OPTIONS) $*.eps $*.pdf" ; \
                echo $$cmd ; \
                eval $$cmd ;\
	else \
		echo "Cannot find ps to pdf converter :-("; \
	fi

.png.eps:
	$(PNGTOPNM) $< | $(PNMTOPS) -noturn > $*.eps

# Only run bibtex if latex has already been run (i.e., if there is
# already a .aux file).  If .aux file does not exist, then bibtex will
# be run during the .tex.pdf rules.  We don't run latex here to
# generate the .aux file because a) we don't know whether to run latex
# or pdflatex, and b) the dependencies are wrong for pdflatex because
# we may need to generate some pdf images first.

$(MAIN_BBL): $(BIBTEX_SOURCES)
	@if (test -n "$(BIBTEX_SOURCES)" -a -f $(MAIN_BASENAME).aux); then \
		echo "### Running BibTex"; \
		$(BIBTEX) $(MAIN_BASENAME); \
	fi

# Macro to handle when running "latex" fails -- ensure to kill the
# .aux file so that the next time we run "make", the .tex.pdf rule
# fires, not the .bbl rule.

PDF_FAIL = ($(RM) $(MAIN_BASENAME).aux && false)

# Main workhorse for .tex -> .pdf.  Run latex, makeindex, and bibtex
# as necessary.  

.tex.pdf:
	echo "### Running pdfLaTeX (1)"
	$(PDFLATEX) $* || $(PDF_FAIL)
	@if (egrep $(REFERENCES) $*.log > /dev/null); then \
		echo "### Running pdfLaTeX to fix references (2)"; \
		($(PDFLATEX) $*) || $(PDF_FAIL); \
	fi
	@if (egrep $(NEEDINDEX) $*.log >/dev/null); then \
		echo "### Running makeindex to generate index"; \
		$(MAKEINDEX) $*; \
		echo "### Running pdfLaTeX after generating index"; \
		($(PDFLATEX) $*) || $(PDF_FAIL); \
	fi
	@if (egrep $(RERUNBIB) $*.log >/dev/null); then \
		echo "### Running BibTex because references changed"; \
		$(BIBTEX) $(MAIN_BASENAME); \
		echo "### Running pdfLaTeX after generating bibtex"; \
		($(PDFLATEX) $*) || $(PDF_FAIL); \
	fi
	@if (egrep $(REFERENCES) $*.log > /dev/null); then \
		echo "### Running pdfLaTeX to fix references (3)"; \
		($(PDFLATEX) $*) || $(PDF_FAIL); \
	fi
	@if (egrep $(REFERENCES) $*.log > /dev/null); then \
		echo "### Running pdfLaTeX to fix references (4)"; \
		($(PDFLATEX) $*) || $(PDF_FAIL); \
	fi


#
# Standard targets
#

clean:
	$(RM) *~ *.bak *%
	$(RM) *.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot \
		*.idx *.ilg *.int *.out */*.aux \
		$(EPS_PNG_FILES) $(EPS_FIG_FILES) $(PDF_FIG_FILES) \
		 $(PDF_EPS_FILES)

distclean: clean
	$(RM) $(MAIN_PDF)
