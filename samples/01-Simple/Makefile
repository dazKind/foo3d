CONF = release
CFLAGS=
ifeq ($(CONF), debug)
	CFLAGS+=--debug
endif

all:

desktop:
	haxelib run flow build $(CFLAGS)

web:
	haxelib run flow build web $(CFLAGS)

clean:
	rm -rf bin

.PHONY: all clean desktop web