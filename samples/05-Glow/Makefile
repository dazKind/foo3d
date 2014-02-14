CONF = release
CFLAGS=
ifeq ($(CONF), debug)
	CFLAGS+=-debug
endif

all: html5 flash windows windowslime android

html5:
	haxe -main Sample -cp ../Common -js js/Sample.js -lib foo3d $(CFLAGS)

flash:
	haxe -main Sample -cp ../Common -swf-version 11 -swf swf/Sample.swf -swf-header 800:600:60:ccccff -lib foo3d $(CFLAGS) -resource ../Common/resources/tekkblade.md2@../../Common/resources/tekkblade.md2

windows:
	haxe -main Sample -cp ../Common -cpp cpp -lib foo3d -lib format -D use_glut -D HXCPP_FLOAT32 $(CFLAGS)

windowslime:
	haxelib run lime build project.lime.xml windows $(CFLAGS)

android:
	haxelib run lime build project.lime.xml android $(CFLAGS)

clean:
	rm -f js/Sample.js
	rm -f swf/Sample.swf
	rm -f js/Sample.js.map
	rm -rf cpp
	rm -rf android
	rm -rf windows

.PHONY: html5 flash windows android all
