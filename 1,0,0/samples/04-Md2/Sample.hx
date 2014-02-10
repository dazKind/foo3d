package ;

import math.Mat44;
import Binary;
import Md2Parser;

import foo3d.utils.Frame;
import foo3d.RenderDevice;
import foo3d.RenderContext;

class Sample 
{

#if (js || cpp)

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

#elseif flash

    static var vsSrc:String = '{"agalasm":"mov v0, vc0\\nmov v0.xy, va0.xyyy\\nmov vt0.w, vc0.x\\nsub vt1.xyz, va1.xyzz, va2.xyzz\\nmul vt1.xyz, vt1.xyzz, vc1.x\\nadd vt0.xyz, va2.xyzz, vt1.xyzz\\nm44 vt1, vt0, vc2\\nm44 op, vt1, vc6\\n","consts":{"vc0":[1,0,0,0]},"varnames":{"vPosDst":"va1","viewProjMat":"vc6","unnamed_0":"vc0","worldMat":"vc2","unnamed_1":"vt0","uv":"v0","gl_Position":"op0","interp":"vc1","unnamed_2":"vt1","vPosSrc":"va2","vUv":"va0"},"info":"","storage":{"va1":"ir_var_in","vc6":"ir_var_uniform","va0":"ir_var_in","vc1":"ir_var_uniform","vc2":"ir_var_uniform","op0":"ir_var_out","v0":"ir_var_out","va2":"ir_var_in"},"types":{"va1":"vec3","vc6":"mat4","va0":"vec2","vc1":"float","vc2":"mat4","op0":"vec4","v0":"vec2","va2":"vec3"}}';
    
    static var fsSrc:String = '{"agalasm":"tex oc, v0.xyyy, fs0 <linear mipdisable repeat 2d>\\n","consts":{},"storage":{"fs0":"ir_var_uniform","v0":"ir_var_in","oc0":"ir_var_out"},"varnames":{"uSampler":"fs0","uv":"v0","gl_FragColor":"oc0"},"info":"","types":{"fs0":"sampler2D","v0":"vec2","oc0":"vec4"}}';

#end

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

#if lime
    public function ready (lime:lime.Lime):Void {
        onCtxCreated(lime.render.direct_renderer_handle);
    }
    private function render ():Void {
        onCtxUpdate(null);
    }
#else
    static function main() 
    {
        Frame.onCtxCreated.add(onCtxCreated);
        Frame.onCtxLost.add(onCtxLost);
        Frame.onCtxUpdate.add(onCtxUpdate);
        
        Frame.requestContext({name:"foo3d-stage", width:800, height:600});
    }
#end

    static function onCtxCreated(_ctx:RenderContext):Void
    {
        // create device and basic settings
        rd = new RenderDevice(_ctx);
        rd.setViewport(0, 0, 800, 600);
        rd.setScissorRect(0, 0, 800, 600);

        // create the matrices for the scene
        var mProj:Mat44 = Mat44.createPerspLH(60, 800/600, 0.1, 1000.0);
        mWorld = new Mat44();

        // parse the modeldata
        md2 = Md2Parser.run(Binary.load(#if !lime "../../Common/" + #end "resources/tekkblade.md2"));

        // move all frames into individual VBOs
        vBuffers = [];
        for (i in 0...md2.header.numFrames)
        {
            var f = md2.frames[i];            
            var verts:Array<Float> = [];
            for (j in 0...md2.header.numTris)
            {
                verts.push(f.verts[md2.triangles[j].vertInds[0]].x);
                verts.push(f.verts[md2.triangles[j].vertInds[0]].y);
                verts.push(f.verts[md2.triangles[j].vertInds[0]].z);

                verts.push(f.verts[md2.triangles[j].vertInds[1]].x);
                verts.push(f.verts[md2.triangles[j].vertInds[1]].y);
                verts.push(f.verts[md2.triangles[j].vertInds[1]].z);

                verts.push(f.verts[md2.triangles[j].vertInds[2]].x);
                verts.push(f.verts[md2.triangles[j].vertInds[2]].y);
                verts.push(f.verts[md2.triangles[j].vertInds[2]].z);
            }
            vBuffers.push(rd.createVertexBuffer(verts.length*4, ByteTools.floats(verts), RDIBufferUsage.STATIC, 3));
        }
        // move the uvs into a VBO
        var uv:Array<Float> = [];
        for (i in 0...md2.header.numTris)
        {
            uv.push(md2.uv[md2.triangles[i].uvInds[0]].x);
            uv.push(md2.uv[md2.triangles[i].uvInds[0]].y);
            uv.push(md2.uv[md2.triangles[i].uvInds[1]].x);
            uv.push(md2.uv[md2.triangles[i].uvInds[1]].y);
            uv.push(md2.uv[md2.triangles[i].uvInds[2]].x);
            uv.push(md2.uv[md2.triangles[i].uvInds[2]].y);
        }
        // make a simple IBO
        var ind:Array<Int> = [];
        for (i in 0...md2.header.numTris*3)
            ind.push(i);

        // register our layout
        var vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPosSrc", 0, 3, 0),
            new RDIVertexLayoutAttrib("vPosDst", 1, 3, 0),
            new RDIVertexLayoutAttrib("vUv", 2, 2, 0),
        ]);
        uvBuf = rd.createVertexBuffer(uv.length*4, ByteTools.floats(uv), RDIBufferUsage.STATIC, 2);
        iBuf = rd.createIndexBuffer(ind.length*2, ByteTools.uShorts(ind), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // create and load the skin for the model
        var texSrc:String = #if !lime "../../Common/" + #end "resources/tekkblade.png";
        tex = rd.createTexture(RDITextureTypes.TEX2D, 256, 256, RDITextureFormats.RGBA8, false, false);
        rd.uploadTextureData(tex, 0, 0, null);

        ImageLoader.loadImage(texSrc, function(_data:Dynamic):Void {
            rd.uploadTextureData(tex, 0, 0, _data);
        });

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        var loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT44, mProj.rawData);

        mWorldLoc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT44, mWorld.rawData);

        interpLoc = rd.getUniformLoc(prog, "interp");
        rd.setUniform(interpLoc, RDIShaderConstType.FLOAT, [0.0]);

        loc = rd.getSamplerLoc(prog, "uSampler");
        rd.setSampler(loc, 0); // assign texUnit0 to uSampler

        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuffers[curFrame]);
        rd.setVertexBuffer(1, vBuffers[nextFrame]);
        rd.setVertexBuffer(2, uvBuf);
        rd.setIndexBuffer(iBuf);
        rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0
    }

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

    static var rot:Float = 0;
    static var fpsTimer:Float = 0;
    static var animFPS:Float = 0.1;
    static var deltaTime:Float = 0;
    static var time:Float = haxe.Timer.stamp();
    static function onCtxUpdate(_):Void
    {
        var curTime = (haxe.Timer.stamp());
        deltaTime = curTime - time;

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
        rd.setVertexBuffer(0, vBuffers[curFrame]);
        rd.setVertexBuffer(1, vBuffers[nextFrame]);

        // rotate the model
        rot += 10 * deltaTime;
        mWorld.recompose(
            math.Quat.rotateY(rot),
            math.Vec3.create(0.1, 0.1, 0.1),
            math.Vec3.create(0, -1, -7.5)
        );
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT44, mWorld.rawData);

        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, md2.header.numTris * 3, 0);

        time = curTime;
    }
}