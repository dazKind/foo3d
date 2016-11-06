package foo3d;

#if js
typedef RenderContext = js.html.webgl.RenderingContext;

#elseif cpp
typedef RenderContext = Null<Int>;

#end