CONF = release
GLUT = 0
CFLAGS=

ifeq ($(CONF), debug)
	CFLAGS+=-Ddebug
endif

ifeq ($(GLUT), 1)
	CFLAGS+=-Duse_glut
endif

#-DHXCPP_M64
#libgl1-mesa-dev
#libglu1-mesa-dev
#libglew-dev
#freeglut3-dev

#libgl1-mesa-dev:i386
#libglu1-mesa-dev:i386
#libglew-dev:i386
#freeglut3-dev:i386

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
