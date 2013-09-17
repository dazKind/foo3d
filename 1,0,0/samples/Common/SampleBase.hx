package ;

import foo3D.RenderDevice;
import foo3D.RenderContext;

#if js

import js.Browser;
import WebGLUtils;

#elseif (flash||nme)

import flash.Lib;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;

#end

class SampleBase
{
    public var vlPosUv:Int;
    public var vbFsQuad:Int;
    public var uvFsQuad:Int;
    public var ibFsQuad:Int;

    public function new() {}

    public function initDefaults(_rd:RenderDevice):Void
    {
        vlPosUv = _rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
            new RDIVertexLayoutAttrib("vUv", 0, 2, 3),
        ]);
        vbFsQuad = _rd.createVertexBuffer(
            20, 
            [   0.0, 1.0, 0.0,     0.0, 0.0,
                1.0, 0.0, 0.0,     1.0, 1.0,
                1.0, 1.0, 0.0,     1.0, 0.0,
                0.0, 0.0, 0.0,     0.0, 1.0], 
            RDIBufferUsage.STATIC, 
            5
        );
        uvFsQuad = _rd.createVertexBuffer(
            8, 
            [0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0], 
            RDIBufferUsage.STATIC, 
            2
        );
        ibFsQuad = _rd.createIndexBuffer(
            6,
            [1, 3, 0, 2, 1, 0],
            RDIBufferUsage.STATIC
        );
    }

    public function cleanUpDefaults(_rd:RenderDevice):Void
    {
        _rd.destroyBuffer(vbFsQuad);
        _rd.destroyBuffer(uvFsQuad);
        _rd.destroyBuffer(ibFsQuad);
    }

    public function registerOnClick(_cb:Dynamic->Void):Void
    {
#if js    
        (cast Browser.window).addEventListener("click", _cb, false);
#elseif (flash||nme)
        Lib.current.stage.addEventListener(MouseEvent.CLICK, _cb);
#end
    }

    public function registerOnKeyDown(_cb:Dynamic->Void):Void
    {
#if js    
        (cast Browser.window).addEventListener("keydown", _cb, false);
#elseif (flash||nme)
        Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, _cb);
#end
    }
}