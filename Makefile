.PHONY: default demo
default: oblivion

ML = obl_utf8.ml obl_html.ml obl_types.ml obl_lexer.ml obl_print.ml obl_main.ml

obl_lexer.ml: obl_lexer.mll
	ocamllex $<

oblivion: $(ML)
	ocamlopt -o $@ $(ML)

demo: oblivion
	./oblivion example.js -o example.out
	cat example.out

ifndef PREFIX
  PREFIX = $(HOME)
endif

ifndef BINDIR
  BINDIR = $(PREFIX)/bin
endif

.PHONY: install
install:
	cp oblivion $(BINDIR)

.PHONY: clean
clean:
	rm -f *.o *.cm* *~ obl_lexer.ml oblivion
	rm -f example.out
