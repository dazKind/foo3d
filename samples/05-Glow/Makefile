CONF = release
CFLAGS=
ifeq ($(CONF), debug)
	CFLAGS+= -debug
endif

HX=haxe -main Sample -cp ../Common
HXCPP=$(HX) -lib foo3d -lib format -D use_glut -D HXCPP_FLOAT32
LIME=haxelib run lime build project.lime.xml -Dfoo3d_use_lime

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
	$(HXCPP) -cpp Windows/ $(CFLAGS)

windows64:
	$(HXCPP) -cpp Windows64/ -D HXCPP_M64 $(CFLAGS)

linux:
	$(HXCPP) -cpp Linux/ $(CFLAGS)

linux64:
	$(HXCPP) -cpp Linux64/ -D HXCPP_M64 $(CFLAGS)

mac:
	$(HXCPP) -cpp Mac/ $(CFLAGS)

mac64:
	$(HXCPP) -cpp Mac64/ -D HXCPP_M64 $(CFLAGS)

windowslime:
	$(LIME) windows -32 $(CFLAGS)

windowslime64:
	$(LIME) windows -64 $(CFLAGS)

linuxlime:
	$(LIME) linux -32 $(CFLAGS)

linuxlime64:
	$(LIME) linux -64 $(CFLAGS)

maclime:
	$(LIME) mac -32 $(CFLAGS)

maclime64:
	$(LIME) mac -64 $(CFLAGS)

clean:
	rm -f js/Sample.js
	rm -f swf/Sample.swf
	rm -f js/Sample.js.map
	rm -rf Windows Windows64 Linux Linux64 Mac Mac64 lime

.PHONY: html5 flash android windows windows64 linux linux64 windowslime windowslime64 linuxlime linuxlime64 maclime maclime64 all
