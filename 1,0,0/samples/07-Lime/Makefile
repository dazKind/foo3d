CONF = release
CFLAGS=
ifeq ($(CONF), debug)
	CFLAGS+=-debug
endif

all: 
	haxelib run lime build project.lime.xml windows $(CFLAGS)

html5:
	haxelib run lime build project.lime.xml html5 $(CFLAGS)

clean:
	rm -r Export/*

run:
	haxelib run lime test windows $(CFLAGS)

.PHONY: all clean run html5