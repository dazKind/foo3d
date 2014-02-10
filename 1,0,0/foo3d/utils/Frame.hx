package foo3D.utils;

import foo3D.utils.Signal;

#if js

import js.Browser;
import js.html.CanvasElement;
import WebGLUtils;

#elseif (flash||nme)

import flash.Lib;
import flash.events.Event;
import Firebug;

#end

typedef RenderContextConfig = {
	name:String,
	width:Int,
	height:Int
}

class Frame {

	static var ctx = null;
	static public var time:Float = haxe.Timer.stamp();
    static public var deltaTime:Float;

	public static var onCtxCreated:Signal<Dynamic> = new Signal<Dynamic>();
	public static var onCtxLost:Signal<Dynamic> = new Signal<Dynamic>();
	public static var onCtxUpdate:Signal<Dynamic> = new Signal<Dynamic>();
	public static var onCtxReshape:Signal<Dynamic> = new Signal<Dynamic>();

	public static function requestContext(_config:RenderContextConfig) {
#if js
		var container = Browser.document.getElementById(_config.name);
		var canvas:Dynamic = Browser.document.createElement("canvas");
		canvas.width = _config.width;
		canvas.height = _config.height;
		container.appendChild(canvas);
		
		ctx = WebGLUtils.setupWebGL(canvas);
#if debug
        var logGLCall = function(functionName, args) {
            trace("gl." + functionName + "(" + untyped __js__("WebGLDebugUtils.glFunctionArgsToString(functionName, args)") + ")");
        };
        
        var logGLError = function(err, funcName, args) {
            throw "[Foo3D - ERROR] - " + funcName + " -> " + untyped __js__("WebGLDebugUtils.glEnumToString(err)");
        };
        
        untyped __js__("ctx = WebGLDebugUtils.makeDebugContext(this.m_ctx, logGLError, undefined);");
#end
		(cast canvas).addEventListener("webglcontextlost", function(_evt) {
	        trace("[Foo3D] - context lost");
	        onCtxLost.dispatch(ctx);
	        _evt.preventDefault();
	    }, false);

	    (cast canvas).addEventListener("webglcontextrestored", function(_evt) {
	    	trace("[Foo3D] - context restored");
	        onCtxCreated.dispatch(ctx);
	    }, false);

	    onCtxCreated.dispatch(ctx);
	    // handle frame updates
	    update();
#elseif (flash||nme)   
		if (Firebug.detect())
            Firebug.redirectTraces();

	    Lib.current.stage.stage3Ds[0].addEventListener( Event.CONTEXT3D_CREATE, 
            function(_evt:Event) {
                if (ctx != null)
                {
                    trace("[Foo3D] - context lost");
                    onCtxLost.dispatch(ctx);
                }
                ctx = _evt.target.context3D;
                onCtxCreated.dispatch(ctx);

                Lib.current.removeEventListener(Event.ENTER_FRAME, update);
                Lib.current.addEventListener(Event.ENTER_FRAME, update);
            });
        Lib.current.stage.stage3Ds[0].requestContext3D();
#elseif cpp
		ctx = hx_glut_Setup(_config.name, _config.width, _config.height, update);
		onCtxCreated.dispatch(ctx);
		hx_glut_MainLoop();
#end
	}

	static function update(#if (flash||nme) _evt:Dynamic #end):Void {
        var curTime = (haxe.Timer.stamp());
        deltaTime = curTime - time;
#if js
        onCtxUpdate.dispatch();
        (cast Browser.window).requestAnimFrame(update);
#elseif (flash||nme)
        if (ctx != null && ctx.driverInfo != "Disposed")
            onCtxUpdate.dispatch();
        ctx.present();
#elseif cpp
		onCtxUpdate.dispatch();
#end
        time = curTime;
	}

#if cpp
	static var hx_glut_Setup = cpp.Lib.load("foo3D", "hx_glut_Setup", 4);
	static var hx_glut_MainLoop = cpp.Lib.load("foo3D", "hx_glut_MainLoop", 0);
#end

}