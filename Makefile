SCHEME := scheme48-1.9.2

all: $(SCHEME).tgz \
     $(SCHEME) \
     $(SCHEME)/c/prescheme-io.h \
     $(SCHEME)/prescheme.pc \
     $(SCHEME)/prescheme \
     $(SCHEME)/scheme48vm \
     $(SCHEME)/c/libprescheme.a \
     $(SCHEME)/prescheme.image

$(SCHEME).tgz:
	wget https://s48.org/1.9.2/$(SCHEME).tgz

$(SCHEME): $(SCHEME).tgz
	tar xvzf $<

$(SCHEME)/c/prescheme-io.h: $(SCHEME)
	echo "9.2" > $(SCHEME)/ps-compiler/minor-version-number
	cp $(SCHEME)/c/io.h $(SCHEME)/c/prescheme-io.h
	sed -i 's/#include "io.h"/#include "prescheme-io.h"/' $(SCHEME)/c/prescheme.h

$(SCHEME)/prescheme.pc: $(SCHEME)
	cp templates/prescheme.pc $(SCHEME)/prescheme.pc

$(SCHEME)/prescheme: $(SCHEME)
	cp templates/prescheme $(SCHEME)/prescheme

$(SCHEME)/scheme48vm: $(SCHEME)
	cd $(SCHEME) && ./configure && make

$(SCHEME)/c/libprescheme.a: $(SCHEME)
	cd $(SCHEME)/c && ar rcs libprescheme.a unix/io.o unix/misc.o

.ONESHELL:
$(SCHEME)/prescheme.image: $(SCHEME)
	cd $(SCHEME)/ps-compiler && scheme48 <<EOF
	,batch
	,config ,load ../scheme/prescheme/interface.scm
	,config ,load ../scheme/prescheme/package-defs.scm
	,exec ,load load-ps-compiler.scm
	,in prescheme-compiler prescheme-compiler
	,user (define prescheme-compiler ##)
	,dump ../prescheme.image "(Pre-Scheme 1.9.2)"
	,exit
	EOF

example/hello.c: example/packages.scm $(SCHEME)
	cd example && \
        echo "(prescheme-compiler 'hello '(\"$(notdir $<)\") 'hello-init \"$(notdir $@)\")" | \
        scheme48 -i ../$(SCHEME)/prescheme.image -a batch

example/hello: example/hello.c
	$(CC) -I$(SCHEME)/c $< -o $@ -L$(SCHEME)/c -lprescheme

example: example/hello

.PHONY: install
install:
	mkdir -p /usr/local/bin \
             /usr/local/lib/$(SCHEME) \
             /usr/local/include \
             /usr/local/lib/pkgconfig \
             /usr/local/share/$(SCHEME)
	cp $(SCHEME)/prescheme /usr/local/bin
	cp $(SCHEME)/prescheme.image /usr/local/lib/$(SCHEME)
	cp $(SCHEME)/prescheme.pc /usr/local/lib/pkgconfig
	cp $(SCHEME)/c/prescheme.h $(SCHEME)/c/prescheme-io.h /usr/local/include
	cp $(SCHEME)/c/libprescheme.a /usr/local/lib/$(SCHEME)
	rm -f /usr/local/share/$(SCHEME)/ps-compiler/compile-*.scm

.PHONY: clean
clean:
	rm -rf $(SCHEME).tgz $(SCHEME)
	rm -f example/hello.c example/hello
