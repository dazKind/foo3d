CONF = release
GLUT = 0
CFLAGS=

ifeq ($(CONF), debug)
	CFLAGS+=-Ddebug
endif

ifeq ($(GLUT), 1)
	CFLAGS+=-Duse_glut
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

.PHONY: all clean install
