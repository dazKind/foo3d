package ;

import foo3d.RenderDevice;
import foo3d.RenderContext;

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
            new RDIVertexLayoutAttrib("vUv", 0, 2, 12),
        ]);
        vbFsQuad = _rd.createVertexBuffer(
            20*4, 
            haxe.io.Float32Array.fromArray([   
                0.0, 1.0, 0.0,     0.0, 0.0,
                1.0, 0.0, 0.0,     1.0, 1.0,
                1.0, 1.0, 0.0,     1.0, 0.0,
                0.0, 0.0, 0.0,     0.0, 1.0
            ]).view.buffer.getData(),
            RDIBufferUsage.STATIC, 
            5
        );
        uvFsQuad = _rd.createVertexBuffer(
            8*4, 
            haxe.io.Float32Array.fromArray([0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0]).view.buffer.getData(),
            RDIBufferUsage.STATIC, 
            2
        );
        ibFsQuad = _rd.createIndexBuffer(
            6*2,
            haxe.io.UInt16Array.fromArray([1, 3, 0, 2, 1, 0]).view.buffer.getData(),
            RDIBufferUsage.STATIC
        );
    }

    public function cleanUpDefaults(_rd:RenderDevice):Void
    {
        _rd.destroyBuffer(vbFsQuad);
        _rd.destroyBuffer(uvFsQuad);
        _rd.destroyBuffer(ibFsQuad);
    }
}