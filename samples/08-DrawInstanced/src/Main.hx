package ;

import foo3d.RenderDevice;
import foo3d.RenderContext;
import math.Mat44;

import snow.types.Types;

typedef UserConfig = {}

@:log_as('app')
class Main extends snow.App.App {

    static var vsSrc:String = "
        attribute vec3 vPos;
        attribute vec3 vColor;
        attribute vec3 vOffset;

        uniform mat4 viewProjMat;
        uniform mat4 worldMat;

        varying vec3 color;

        void main() {
            color = vColor;
            gl_Position = (viewProjMat * (worldMat * vec4(vPos+vOffset, 1.0) ));
        }";

    static var fsSrc:String = "
        #ifdef GL_ES
        precision highp float;
        #endif        
        
        uniform vec4 uColor;

        varying vec3 color;
        
        void main() {
            gl_FragColor = vec4(color, 1.0);
        }";
    
    static var rd:RenderDevice;

    // handles
    static var vBuf:Int;
    static var oBuf:Int;
    static var vertLayout:Int;
    static var prog:Int;

    public function new () {}

    override function config( config:AppConfig ) : AppConfig {
        config.window.title = "08-DrawInstanced";
        config.window.width = 960;
        config.window.height = 480;

        config.render.webgl.version = 2;

        return config;
    }

    override function ready() {
        // create device and basic settings
        var width = this.app.runtime.window_width();
        var height = this.app.runtime.window_height();

        rd = new RenderDevice(#if js snow.modules.opengl.GL.gl #else null #end);
        rd.setViewport(0, 0, width, height);
        rd.setScissorRect(0, 0, width, height);
        

        // create the matrices for the scene
        var mProj:Mat44 = Mat44.createPerspLH(60, width/height, 0.1, 1000.0);
        var mWorld:Mat44 = new Mat44();
        mWorld.setTranslation(0, 0, -25);

        // create the buffers and the shaderprogram
        vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
            new RDIVertexLayoutAttrib("vColor", 0, 3, 12),
            new RDIVertexLayoutAttrib("vOffset", 1, 3, 0, RDIDataType.FLOAT, 1)
        ]);

        var qVerts = haxe.io.Float32Array.fromArray([
            // Positions     // Colors
            -0.5,  0.5, 0, 1.0, 0.0, 0.0,
             0.5, -0.5, 0, 0.0, 1.0, 0.0,
            -0.5, -0.5, 0, 0.0, 0.0, 1.0,

            -0.5,  0.5, 0, 1.0, 0.0, 0.0,
             0.5, -0.5, 0, 0.0, 1.0, 0.0,   
             0.5,  0.5, 0, 0.0, 1.0, 1.0
        ]);

        var offsets:Array<Float> = [];
        for (y in 0...10)
            for (x in 0...10) {
                offsets.push(x);
                offsets.push(y);
                offsets.push(0);
            }
        var qOffsets = haxe.io.Float32Array.fromArray(offsets);

        vBuf = rd.createVertexBuffer(24*6, qVerts.view.buffer.getData(), RDIBufferUsage.STATIC);
        oBuf = rd.createVertexBuffer(12*100, qOffsets.view.buffer.getData(), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        
        var loc = rd.getUniformLoc(prog, "uColor");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4, [0.0, 1.0, 0.0, 1.0]);

        loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mProj.rawData);

        loc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mWorld.rawData);

        // bind the necessary buffers for rendering
        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuf, 0, 24);
        rd.setVertexBuffer(1, oBuf, 0, 12);
        rd.setCullMode(0);
    }
/*
    static function onCtxLost(_ctx:RenderContext):Void
    {
        // clean up the resources
        rd.destroyBuffer(vBuf);
        rd.destroyProgram(prog);
    }
*/
    override function update( delta:Float ) {
        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.drawArraysInstanced(RDIPrimType.TRIANGLES, 0, 6, 100);
    }
}