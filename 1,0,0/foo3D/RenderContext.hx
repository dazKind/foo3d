package foo3D;

#if js

typedef RenderContext = js.html.webgl.RenderingContext;

#elseif (flash || nme)

typedef RenderContext = flash.display3D.Context3D;

#elseif cpp

typedef RenderContext = Null<Int>;

#end