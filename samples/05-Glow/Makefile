CONF = release
CFLAGS=
ifeq ($(CONF), debug)
	CFLAGS+= -debug
endif

HX=haxe -main Sample -cp ../Common
LIME=haxelib run lime build project.lime.xml

all: 
	@echo "Available targets:"
	@echo "html5, flash, android, ios, windowslime windowslime64 linuxlime linuxlime64 maclime maclime64 windows windows64 linux linux64"

html5:
	$(HX) -js js/Sample.js -lib foo3d $(CFLAGS)

flash:
	$(HX) -swf-version 11 -swf swf/Sample.swf -swf-header 800:600:60:ccccff -lib foo3d $(CFLAGS) \
	-resource ../Common/resources/tekkblade.md2@../../Common/resources/tekkblade.md2

android:
	$(LIME) android $(CFLAGS)

ios:
	$(LIME) ios $(CFLAGS)

windows:
	$(HX) -cpp windows/ -lib foo3d -lib format -D use_glut -D HXCPP_FLOAT32 $(CFLAGS)

windows64:
	$(HX) -cpp windows64/ -lib foo3d -lib format -D use_glut -D HXCPP_M64 -D HXCPP_FLOAT32 $(CFLAGS)

linux:
	$(HX) -cpp linux/ -lib foo3d -lib format -D use_glut -D HXCPP_FLOAT32 $(CFLAGS)

linux64:
	$(HX) -cpp linux64/ -lib foo3d -lib format -D use_glut -D HXCPP_M64 -D HXCPP_FLOAT32 $(CFLAGS)

windowslime:
	$(LIME) windows $(CFLAGS)

windowslime64:
	$(LIME) windows -64 $(CFLAGS)

linuxlime:
	$(LIME) linux $(CFLAGS)

linuxlime64:
	$(LIME) linux -64 $(CFLAGS)

maclime:
	$(LIME) mac $(CFLAGS)

maclime64:
	$(LIME) mac -64 $(CFLAGS)

clean:
	rm -f js/Sample.js
	rm -f swf/Sample.swf
	rm -f js/Sample.js.map
	rm -rf android windows windows64 linux linux64 lime

.PHONY: html5 flash android windows windows64 linux linux64 windowslime windowslime64 linuxlime linuxlime64 maclime maclime64 all
