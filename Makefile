PREFIX  ?= /usr
DESTDIR ?=
CC      ?= cc
CFLAGS  ?= -O2 -Wall -Wextra
LIBDIR   = $(PREFIX)/lib/starline-master-coalesce

all: coalesce_read.so

coalesce_read.so: coalesce_read.c
	$(CC) $(CFLAGS) -fPIC -shared -o $@ $< -ldl

install: coalesce_read.so
	install -Dm755 coalesce_read.so $(DESTDIR)$(LIBDIR)/coalesce_read.so
	install -Dm755 starline-master-coalesce $(DESTDIR)$(PREFIX)/bin/starline-master-coalesce
	install -Dm644 README.md $(DESTDIR)$(PREFIX)/share/doc/starline-master-coalesce/README.md

clean:
	rm -f coalesce_read.so

.PHONY: all install clean
