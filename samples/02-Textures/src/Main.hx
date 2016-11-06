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
        attribute vec2 vUv;

        uniform mat4 viewProjMat;
        uniform mat4 worldMat;

        varying vec2 uv;

        void main() {
            uv = vUv;
            gl_Position = (viewProjMat * (worldMat * vec4(vPos, 1.0) ));
        }";

    static var fsSrc:String = "
        #ifdef GL_ES
        precision highp float;
        #endif        
        
        varying vec2 uv;

        uniform sampler2D uSampler;
        
        void main() {
            gl_FragColor = texture2D(uSampler, uv);
        }";

    static var rd:RenderDevice;

    // handles
    static var vBuf:Int;
    static var iBuf:Int;
    static var vertLayout:Int;
    static var prog:Int;
    static var tex:Int;

    public function new() {}

    override function config( config:AppConfig ) : AppConfig {
        config.window.title = "01-Simple";
        config.window.width = 960;
        config.window.height = 480;
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
        mWorld.setTranslation(0, 0, -5);

        // create the buffers and the shaderprogram
        // bind the necessary buffers for rendering
        vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
            new RDIVertexLayoutAttrib("vUv", 0, 2, 12),
        ]);
        
        var qVerts = haxe.io.Float32Array.fromArray([ // position + uv
            -1.0, -1.0, 1.0,    0, 0,
            1.0, -1.0, 1.0,     1, 0,
            1.0, 1.0, 1.0,      1, 1,
            -1.0, 1.0, 1.0,     0, 1,
        ]);
        var qInds = haxe.io.UInt16Array.fromArray([0, 1, 2, 0, 2, 3]);
        
        vBuf = rd.createVertexBuffer(20*4, qVerts.view.buffer.getData(), RDIBufferUsage.STATIC, 5);
        iBuf = rd.createIndexBuffer(6*2, qInds.view.buffer.getData(), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // create a texture
        tex = rd.createTexture(RDITextureTypes.TEX2D, 256, 256, RDITextureFormats.RGBA8, false, true);
        rd.uploadTextureData(tex, 0, 0, null);

        this.app.assets.bytes("resources/uv.png").then(function(_tmp:AssetBytes) {
            var imgBytes = haxe.io.Bytes.ofData(_tmp.bytes.toBytes().getData());
            var png = new format.png.Reader(new haxe.io.BytesInput(imgBytes)).read();
            rd.uploadTextureData(tex, 0, 0, format.png.Tools.extract32(png, null, #if js false #else true #end).getData());
        });

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        var loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mProj.rawData);

        loc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mWorld.rawData);

        loc = rd.getSamplerLoc(prog, "uSampler");
        rd.setSampler(loc, 0); // assign texUnit0 to uSampler

        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuf, 0, 20);
        rd.setIndexBuffer(iBuf);
        rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0
    }
/*
    static function onCtxLost(_ctx:RenderContext):Void
    {
        // clean up the resources
        rd.destroyBuffer(vBuf);
        rd.destroyBuffer(iBuf);
        rd.destroyProgram(prog);
        rd.destroyTexture(tex);
    }
*/

    override function update( delta:Float ) {
        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, RDIDataType.UNSIGNED_SHORT, 6, 0);
    }
}