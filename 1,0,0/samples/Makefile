
CONF = release

CFLAGS=

ifeq ($(CONF), debug)
	CFLAGS+=-debug
endif

all: 
	cd ./01-Simple; haxe $(CFLAGS) ./compile-swf.hxml; haxe $(CFLAGS) ./compile-js.hxml; haxe $(CFLAGS) ./compile-cpp.hxml
	cd ./02-Textures; haxe $(CFLAGS) ./compile-swf.hxml; haxe $(CFLAGS) ./compile-js.hxml; haxe $(CFLAGS) ./compile-cpp.hxml
	cd ./03-Skybox; haxe $(CFLAGS) ./compile-swf.hxml; haxe $(CFLAGS) ./compile-js.hxml; haxe $(CFLAGS) ./compile-cpp.hxml
	cd ./04-Md2; haxe $(CFLAGS) ./compile-swf.hxml; haxe $(CFLAGS) ./compile-js.hxml; haxe $(CFLAGS) ./compile-cpp.hxml
	cd ./05-Glow; haxe $(CFLAGS) ./compile-swf.hxml; haxe $(CFLAGS) ./compile-js.hxml; haxe $(CFLAGS) ./compile-cpp.hxml
	cd ./06-Openfl; haxelib run openfl build html5 $(CFLAGS); haxelib run openfl build windows $(CFLAGS)

.PHONY: all