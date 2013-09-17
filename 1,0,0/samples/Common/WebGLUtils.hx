package ;

import haxe.Timer;
//import UserAgentContext;

/**
 * ...
 * @author mib
 */

extern class WebGLUtils 
{
    public static function makeFailHTML(_msg:String):String;
    public static function setupWebGL(_canvas:Dynamic, ?_opt_attribs:Dynamic, ?_opt_onError:Dynamic):Dynamic;
    public static function create3DContext(_canvas:Dynamic, ?_opt_attribs:Dynamic):Dynamic;
}