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

        uniform mat4 viewProjMat;
        uniform mat4 worldMat;

        varying vec3 uv;

        void main() {
            uv = vPos;
            gl_Position = (viewProjMat * (worldMat * vec4(vPos, 1.0) ));
        }";

    static var fsSrc:String = "
        #ifdef GL_ES
        precision highp float;
        #endif        
        
        varying vec3 uv;

        uniform samplerCube uSampler;
        
        void main() {
            gl_FragColor = textureCube(uSampler, uv);
        }";
    
    static var rd:RenderDevice;
 
     // handles
    static var vBuf:Int;
    static var iBuf:Int;
    static var vertLayout:Int;
    static var prog:Int;
    static var tex:Int;

    static var mProj:Mat44;
    static var mWorld:Mat44;

    static var mWorldLoc:Dynamic;

    public function new() {}

    override function config( config:AppConfig ) : AppConfig {
        config.window.title = "03-Skybox";
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
        mProj = Mat44.createPerspLH(60, width/height, 0.1, 1000.0);
        mWorld = new Mat44();

        // create the buffers and the shaderprogram
        // bind the necessary buffers for rendering
        vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
        ]);

        var qVerts = haxe.io.Float32Array.fromArray([
            1.0,1.0,-1.0,1.0,1.0,1.0,1.0,-1.0,1.0,1.0,-1.0,-1.0,-1.0,-1.0,-1.0,-1.0,-1.0,1.0,-1.0,1.0,1.0,-1.0,1.0,-1.0,-1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,-1.0,-1.0,1.0,-1.0,-1.0,-1.0,-1.0,1.0,-1.0,-1.0,1.0,-1.0,1.0,-1.0,-1.0,1.0,1.0,-1.0,1.0,1.0,1.0,1.0,-1.0,1.0,1.0,-1.0,-1.0,1.0,-1.0,1.0,-1.0,1.0,1.0,-1.0,1.0,-1.0,-1.0,-1.0,-1.0,-1.0
        ]);
        var qInds = haxe.io.UInt16Array.fromArray([
            0,1,3,1,2,3,4,5,7,5,6,7,8,9,11,9,10,11,12,13,15,13,14,15,16,17,19,17,18,19,20,21,23,21,22,23
        ]);

        vBuf = rd.createVertexBuffer(qVerts.view.byteLength, qVerts.view.buffer.getData(), RDIBufferUsage.STATIC);
        iBuf = rd.createIndexBuffer(qInds.view.byteLength, qInds.view.buffer.getData(), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // create a texture
        tex = rd.createTexture(RDITextureTypes.TEXCUBE, 512, 512, RDITextureFormats.RGBA8, false, true);
        for (i in 0...6) {
            rd.uploadTextureData(tex, i, 0, null);
            this.app.assets.image("resources/hills_" + i + ".png").then(function(_tmp:AssetImage) {
                rd.uploadTextureData(tex, i, 0, _tmp.image.pixels.toBytes().getData());
            });
        }

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        var loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mProj.rawData);

        mWorldLoc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT4x4, mWorld.rawData);

        loc = rd.getSamplerLoc(prog, "uSampler");
        rd.setSampler(loc, 0); // assign texUnit0 to uSampler

        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuf, 0, 12);
        rd.setIndexBuffer(iBuf);
        rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0
        rd.setCullMode(RDICullModes.NONE); // we render inner box
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
    static var rot:Float = 0;
    override function update( delta:Float ) {
        // rotate the skybox around
        rot += 10 * delta;
        mWorld.setOrientation(math.Quat.rotateY(rot));
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT4x4, mWorld.rawData);

        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, RDIDataType.UNSIGNED_SHORT, 36, 0);
    }
}