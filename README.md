foo3d
=====

#### Crossplatform lowlevel 3D rendering API in Haxe

![foo3D](http://developium.net/pics/w00t3.jpg)

Foo3D is a crossplatform low-level rendering API written in Haxe. It's not a 3D engine. It's supposed to be a crossplatform groundlayer for more sophisticated 3D engines written in Haxe.

Foo3D doesnt make any assumptions about your project-setup. All it needs is a 3D-context in order to work. You are free to allocate a context on your own and hand it over to Foo3D's RenderDevice via DI. Alternatively you can use the supplied utility-classes to receive a window/canvas/stage + context to render to.

You may install using:

	haxelib git foo3d https://github.com/dazKind/foo3d
	
Or:

	git clone https://github.com/dazKind/foo3d
	haxelib dev foo3d foo3d


#### Features:
* Haxe3 ready!
* a common interface across different targets.
* available primitives:
  * Vertexbuffers
  * Textures
  * ShaderPrograms
  * Renderbuffers
* low-level management of GPU-resources
* low-level renderstatemanagement
* optional 3D-context creation(canvas3d, stage3d, glut)
* many samples

#### Targets:
* js(webgl)
* flash(stage3D)
* cpp(windows-x86&ogl)
* cpplime(lime&ogl)
* android(lime&gles2)

#### Notes:
* Documentation is almost non-existant. I'm currently fixing this. Up until then please refer to the samples.
* The flash target needs AGAL shaders while the rest of the targets use glsl!
* Make sure you got foo3d.ndll in your path/sample-folders. It's compiled via hxcpp. Check the content of the "native-bindings"-folder.
* Foo3D uses GLUT for the optional creation of the window and the context. Make sure you got glut32.dll in your path if you use the Frame-Class(like most of the samples).
* On older systems Webgl can be blacklisted in your browser. Try setting "webgl.force-enabled;true" via "about:config".

#### Samples:

##### 06-Openfl - "Openfl SimpleOpenglView + foo3D"
> ![Openfl](http://developium.net/projects/foo3d/06-Openfl/s_200.jpg)
> * See the sample live: [html5](http://developium.net/projects/foo3d/06-Openfl/Export/html5/bin)
> * See the code: [code](https://github.com/dazKind/foo3D/blob/master/1%2C0%2C0/samples/06-Openfl/Source/Main.hx)

##### 05-Glow - "Post-process glow via FBOs"
> ![Glow](http://developium.net/projects/foo3d/05-Glow/s_200.jpg)
> * See the sample live: [html5](http://developium.net/projects/foo3d/05-Glow/js) | [flash](http://developium.net/projects/foo3d/05-Glow/swf)
> * See the code: [code](https://github.com/dazKind/foo3D/blob/master/1%2C0%2C0/samples/05-Glow/Sample.hx)

##### 04-Md2 - "Md2 Loading and animation"
> ![Md2](http://developium.net/projects/foo3d/04-Md2/s_200.jpg)
> * See the sample live: [html5](http://developium.net/projects/foo3d/04-Md2/js) | [flash](http://developium.net/projects/foo3d/04-Md2/swf)
> * See the code: [code](https://github.com/dazKind/foo3D/blob/master/1%2C0%2C0/samples/04-Md2/Sample.hx)

##### 03-Skybox - "Skybox-Cubemap"
> ![Skybox](http://developium.net/projects/foo3d/03-Skybox/s_200.jpg)
> * See the sample live: [html5](http://developium.net/projects/foo3d/03-Skybox/js) | [flash](http://developium.net/projects/foo3d/03-Skybox/swf)
> * See the code: [code](https://github.com/dazKind/foo3D/blob/master/1%2C0%2C0/samples/03-Skybox/Sample.hx)

##### 02-Textures - "Textures"
> ![Textures](http://developium.net/projects/foo3d/02-Textures/s_200.jpg)
> * See the sample live: [html5](http://developium.net/projects/foo3d/02-Textures/js) | [flash](http://developium.net/projects/foo3d/02-Textures/swf)
> * See the code: [code](https://github.com/dazKind/foo3D/blob/master/1%2C0%2C0/samples/02-Textures/Sample.hx)

##### 01-Simple - "Green quad on a blue background"
> ![Textures](http://developium.net/projects/foo3d/01-Simple/s_200.jpg)
> * See the sample live: [html5](http://developium.net/projects/foo3d/01-Simple/js) | [flash](http://developium.net/projects/foo3d/01-Simple/swf)
> * See the code: [code](https://github.com/dazKind/foo3D/blob/master/1%2C0%2C0/samples/01-Simple/Sample.hx)
