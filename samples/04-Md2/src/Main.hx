package ;

import foo3d.RenderDevice;
import foo3d.RenderContext;
import math.Mat44;
import Md2Parser;

import snow.types.Types;

typedef UserConfig = {}

@:log_as('app')
class Main extends snow.App.App {

    static var vsSrc:String = "
        attribute vec3 vPosSrc;
        attribute vec3 vPosDst;
        attribute vec2 vUv;

        uniform mat4 viewProjMat;
        uniform mat4 worldMat;
        uniform float interp;

        varying vec2 uv;

        void main() {
            uv = vUv;
            vec3 delta = vPosDst - vPosSrc;
            vec3 pos = vPosSrc + (delta * vec3(interp, interp, interp));
            gl_Position = (viewProjMat * (worldMat * vec4(pos, 1.0) ));
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

    static var md2:Md2Model;

    static var curFrame:Int = 0;    
    static var nextFrame:Int = 1;

    static var vBuffers:Array<Int>;
    static var iBuf:Int;
    static var uvBuf:Int;
    static var prog:Int;
    static var tex:Int;

    static var mWorld:Mat44;

    static var mWorldLoc:UniformLocationType;
    static var interpLoc:UniformLocationType;

    public function new() {}

    override function config( config:AppConfig ) : AppConfig {
        config.window.title = "03-Skybox";
        config.window.width = 960;
        config.window.height = 480;
        config.render.stencil = 8;
        config.render.depth = 24;
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
        mWorld = new Mat44();

        // parse the modeldata
        md2 = Md2Parser.run(Binary.load("resources/tekkblade.md2"));

        // move all frames into individual VBOs
        vBuffers = [];
        for (i in 0...md2.header.numFrames)
        {
            var f = md2.frames[i];            
            var verts = new haxe.io.Float32Array(md2.header.numTris*9);
            for (j in 0...md2.header.numTris)
            {
                verts[(j*9)+0] = f.verts[md2.triangles[j].vertInds[0]].x;
                verts[(j*9)+1] = f.verts[md2.triangles[j].vertInds[0]].y;
                verts[(j*9)+2] = f.verts[md2.triangles[j].vertInds[0]].z;

                verts[(j*9)+3] = f.verts[md2.triangles[j].vertInds[1]].x;
                verts[(j*9)+4] = f.verts[md2.triangles[j].vertInds[1]].y;
                verts[(j*9)+5] = f.verts[md2.triangles[j].vertInds[1]].z;

                verts[(j*9)+6] = f.verts[md2.triangles[j].vertInds[2]].x;
                verts[(j*9)+7] = f.verts[md2.triangles[j].vertInds[2]].y;
                verts[(j*9)+8] = f.verts[md2.triangles[j].vertInds[2]].z;
            }
            vBuffers.push(rd.createVertexBuffer(verts.view.byteLength, verts.view.buffer.getData(), RDIBufferUsage.STATIC));
        }
        // move the uvs into a VBO
        var uv = new haxe.io.Float32Array(md2.header.numTris*6);
        for (i in 0...md2.header.numTris)
        {
            uv[(i*6)+0] = md2.uv[md2.triangles[i].uvInds[0]].x;
            uv[(i*6)+1] = md2.uv[md2.triangles[i].uvInds[0]].y;
            uv[(i*6)+2] = md2.uv[md2.triangles[i].uvInds[1]].x;
            uv[(i*6)+3] = md2.uv[md2.triangles[i].uvInds[1]].y;
            uv[(i*6)+4] = md2.uv[md2.triangles[i].uvInds[2]].x;
            uv[(i*6)+5] = md2.uv[md2.triangles[i].uvInds[2]].y;
        }
        // make a simple IBO
        var ind = new haxe.io.UInt16Array(md2.header.numTris*3);
        for (i in 0...md2.header.numTris*3)
            ind[i] = i;

        // register our layout
        var vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPosSrc", 0, 3, 0),
            new RDIVertexLayoutAttrib("vPosDst", 1, 3, 0),
            new RDIVertexLayoutAttrib("vUv", 2, 2, 0),
        ]);
        uvBuf = rd.createVertexBuffer(uv.view.byteLength, uv.view.buffer.getData(), RDIBufferUsage.STATIC);
        iBuf = rd.createIndexBuffer(ind.view.byteLength, ind.view.buffer.getData(), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // create and load the skin for the model
        tex = rd.createTexture(RDITextureTypes.TEX2D, 256, 256, RDITextureFormats.RGBA8, false, false);
        rd.uploadTextureData(tex, 0, 0, null);

        this.app.assets.image("resources/tekkblade.png").then(function(_tmp:AssetImage) {           
            rd.uploadTextureData(tex, 0, 0, _tmp.image.pixels.toBytes().getData());
        });

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        var loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mProj.rawData);

        mWorldLoc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT4x4, mWorld.rawData);

        interpLoc = rd.getUniformLoc(prog, "interp");
        rd.setUniform(interpLoc, RDIShaderConstType.FLOAT, [0.0]);

        loc = rd.getSamplerLoc(prog, "uSampler");
        rd.setSampler(loc, 0); // assign texUnit0 to uSampler

        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuffers[curFrame], 0, 12);
        rd.setVertexBuffer(1, vBuffers[nextFrame], 0, 12);
        rd.setVertexBuffer(2, uvBuf, 0, 8);
        rd.setIndexBuffer(iBuf);
        rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0

        rd.setCullMode(RDICullModes.NONE); // we render inner box
    }
/*
    static function onCtxLost(_ctx:RenderContext):Void
    {
        // clean up the resources
        for (i in vBuffers)
            rd.destroyBuffer(i);
        rd.destroyBuffer(uvBuf);
        rd.destroyBuffer(iBuf);
        rd.destroyProgram(prog);
        rd.destroyTexture(tex);
    }
*/
    static var rot:Float = 0;
    static var fpsTimer:Float = 0;
    static var animFPS:Float = 0.1;
    override function update( deltaTime:Float ) {

        // animate the model
        fpsTimer += deltaTime;
        if (fpsTimer >= animFPS)
        {
            curFrame = (curFrame + 1 >= md2.header.numFrames) ? 0 : curFrame + 1;
            nextFrame = (nextFrame + 1 >= md2.header.numFrames) ? 0 : nextFrame + 1;
            fpsTimer -= animFPS;
        }
        var t:Float = fpsTimer/animFPS;
        if (t < 0) t = 0.0;
        if (t > 1) t = 1.0;

        rd.setUniform(interpLoc, RDIShaderConstType.FLOAT, [t]);
        rd.setVertexBuffer(0, vBuffers[curFrame], 0, 12);
        rd.setVertexBuffer(1, vBuffers[nextFrame], 0, 12);

        // rotate the model
        rot += 10 * deltaTime;
        mWorld.recompose(
            math.Quat.rotateY(rot),
            math.Vec3.create(0.1, 0.1, 0.1),
            math.Vec3.create(0, -1, -7.5)
        );
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT4x4, mWorld.rawData);

        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, RDIDataType.UNSIGNED_SHORT, md2.header.numTris * 3, 0);
    }
}