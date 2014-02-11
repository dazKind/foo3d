CONF = release

CFLAGS=

ifeq ($(CONF), debug)
	CFLAGS+=-debug
endif

all: 
	haxelib run hxcpp Build.xml $(CFLAGS)

install:
	cp -rf platforms/* ../ndll

clean:
	rm -rf obj
	rm -rf platforms
	rm -f *.pdb
	rm -f all_objs

.PHONY: all clean