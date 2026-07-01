#
# Makefile to build Internet Drafts from markdown using mmark
#
# There is now a separate "Makefile-docker" file with info about how
# to run mmark using the Docker image.
#

SRC  := $(wildcard draft-*.md)
TXT  := $(patsubst %.md,%.txt,$(SRC))
HTML := $(patsubst %.md,%.html,$(SRC))
XML  := $(patsubst %.md,%.xml,$(SRC))
CWD  := `pwd`

# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

all: $(TXT) $(HTML) $(XML)

%.txt: %.xml
	xml2rfc --text -o $@ $<

%.html: %.xml
	xml2rfc --html -o $@ $<

%.xml: %.md
	~/Desktop/IETF/auth-delegation-types/mmark  < $< > $@

clean:
	rm -f draft-*.txt draft-*.html draft-*.xml metadata.min.js
