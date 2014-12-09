
![foo3D](http://foo3d.developium.net/img/logo4.png)


Visit the website: http://foo3d.developium.net/

Visit the api-docs: http://foo3d.developium.net/docs/

You may install using:
```
haxelib git foo3d https://github.com/dazKind/foo3d
```
or
```
git clone https://github.com/dazKind/foo3d
haxelib dev foo3d foo3d
```

#### Notes:
* The flash target needs AGAL shaders while the rest of the targets use glsl!
* Make sure you got foo3d.ndll in your path/sample-folders. It's compiled via hxcpp. Check the content of the "native-bindings"-folder.
* Foo3D uses GLUT for the optional creation of the window and the context. Make sure you got glut32.dll in your path if you use the Frame-Class(like most of the samples).
* On older systems Webgl can be blacklisted in your browser. Try setting "webgl.force-enabled;true" via "about:config".

<a rel="license" href="http://opensource.org/licenses/MIT">
<img alt="MIT license" height="40" src="http://upload.wikimedia.org/wikipedia/commons/c/c3/License_icon-mit.svg" /></a>

This content is released under the [MIT](http://opensource.org/licenses/MIT) License.
