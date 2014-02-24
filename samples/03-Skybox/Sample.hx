package ;

import foo3d.utils.Frame;
import foo3d.RenderDevice;
import foo3d.RenderContext;
import math.Mat44;

class Sample 
{
    // data
    static var cubeVerts:Array<Float> = [
        1,1,-1,1,1,1,1,-1,1,1,-1,-1,-1,-1,-1,-1,-1,1,-1,1,1,-1,1,-1,-1,1,1,1,1,1,1,1,-1,-1,1,-1,-1,-1,-1,1,-1,-1,1,-1,1,-1,-1,1,1,-1,1,1,1,1,-1,1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1,-1,-1,-1,-1
    ];
    
    static var cubeIndices:Array<Int> = [
        0,1,3,1,2,3,4,5,7,5,6,7,8,9,11,9,10,11,12,13,15,13,14,15,16,17,19,17,18,19,20,21,23,21,22,23
    ];
    
#if (js || cpp)

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

#elseif flash

    static var vsSrc:String = '{"agalasm":"mov v0, vc0\\nmov v0.xyz, va0.xyzz\\nmov vt0.w, vc0.x\\nmov vt0.xyz, va0.xyzz\\nm44 vt0, vt0, vc1\\nm44 op, vt0, vc5\\n","consts":{"vc0":[1,0,0,0]},"varnames":{"uv":"v0","worldMat":"vc1","vPos":"va0","unnamed_1":"vt0","unnamed_0":"vc0","viewProjMat":"vc5","gl_Position":"op0"},"info":"","types":{"vc1":"mat4","op0":"vec4","v0":"vec3","vc5":"mat4","va0":"vec3"},"storage":{"vc1":"ir_var_uniform","op0":"ir_var_out","v0":"ir_var_out","vc5":"ir_var_uniform","va0":"ir_var_in"}}';
    
    static var fsSrc:String = '{"agalasm":"tex oc, v0.xyzz, fs0 <linear mipdisable clamp cube>\\n","consts":{},"varnames":{"gl_FragColor":"oc0","uv":"v0","uSampler":"fs0"},"info":"","types":{"v0":"vec3","oc0":"vec4","fs0":"samplerCube"},"storage":{"v0":"ir_var_in","oc0":"ir_var_out","fs0":"ir_var_uniform"}}
';

#end
    
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
        mProj = Mat44.createPerspLH(60, 800/600, 0.1, 1000.0);
        mWorld = new Mat44();

        // create the buffers and the shaderprogram
        // bind the necessary buffers for rendering
        vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
        ]);
        vBuf = rd.createVertexBuffer(24*3*4, ByteTools.floats(cubeVerts), RDIBufferUsage.STATIC, 3);
        iBuf = rd.createIndexBuffer(36*2, ByteTools.uShorts(cubeIndices), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // create a texture
        tex = rd.createTexture(RDITextureTypes.TEXCUBE, 512, 512, RDITextureFormats.RGBA8, false, true);
        for (i in 0...6)
        {
            rd.uploadTextureData(tex, i, 0, null);
            ImageLoader.loadImage(#if !lime "../../Common/" + #end "resources/hills_" + i + ".png", function(_data:Dynamic):Void {
                rd.uploadTextureData(tex, i, 0, _data);
            });
        }

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        var loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT44, mProj.rawData);

        mWorldLoc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT44, mWorld.rawData);

        loc = rd.getSamplerLoc(prog, "uSampler");
        rd.setSampler(loc, 0); // assign texUnit0 to uSampler

        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuf);
        rd.setIndexBuffer(iBuf);
        rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0
        rd.setCullMode(RDICullModes.NONE); // we render inner box
    }

    static function onCtxLost(_ctx:RenderContext):Void
    {
        // clean up the resources
        rd.destroyBuffer(vBuf);
        rd.destroyBuffer(iBuf);
        rd.destroyProgram(prog);
        rd.destroyTexture(tex);
    }

    static var rot:Float = 0;
    static var deltaTime:Float = 0;
    static var time:Float = 0;
    static function onCtxUpdate(_):Void
    {
        var curTime = (haxe.Timer.stamp());
        deltaTime = curTime - time;

        // rotate the skybox around
        rot += 10 * deltaTime;
        mWorld.setOrientation(math.Quat.rotateY(rot));
        rd.setUniform(mWorldLoc, RDIShaderConstType.FLOAT44, mWorld.rawData);

        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, 36, 0);

        time = curTime;
    }
}