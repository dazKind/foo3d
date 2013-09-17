CONF = release

CFLAGS=

ifeq ($(CONF), debug)
	CFLAGS+=-debug
endif

all: 
	haxelib run hxcpp Build.xml $(CFLAGS)

.PHONY: all