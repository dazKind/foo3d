package foo3d;

#if js
typedef RenderContext = js.html.webgl.RenderingContext;

#elseif flash
typedef RenderContext = flash.display3D.Context3D;

#elseif cpp
typedef RenderContext = Null<Int>;

#end