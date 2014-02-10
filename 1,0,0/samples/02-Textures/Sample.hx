package ;

import foo3d.utils.Frame;
import foo3d.RenderDevice;
import foo3d.RenderContext;
import math.Mat44;

class Sample 
{
    // data
    static var quadVerts:Array<Float> = [ // position + uv
        -1.0, -1.0, 1.0,    0, 0,
        1.0, -1.0, 1.0,     1, 0,
        1.0, 1.0, 1.0,      1, 1,
        -1.0, 1.0, 1.0,     0, 1,
    ];

    static var quadIndices:Array<Int> = 
        [0, 1, 2, 0, 2, 3];
    
#if (js || cpp)

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

#elseif flash

    static var vsSrc:String = '{"varnames":{"gl_Position":"op0","unnamed_0":"vc0","worldMat":"vc1","vPos":"va1","uv":"v0","viewProjMat":"vc5","vUv":"va0","unnamed_1":"vt0"},"agalasm":"mov v0, vc0\\nmov v0.xy, va0.xyyy\\nmov vt0.w, vc0.x\\nmov vt0.xyz, va1.xyzz\\nm44 vt0, vt0, vc1\\nm44 op, vt0, vc5\\n","info":"","storage":{"op0":"ir_var_out","va1":"ir_var_in","v0":"ir_var_out","va0":"ir_var_in","vc5":"ir_var_uniform","vc1":"ir_var_uniform"},"types":{"op0":"vec4","va1":"vec3","v0":"vec2","va0":"vec2","vc5":"mat4","vc1":"mat4"},"consts":{"vc0":[1,0,0,0]}}';
    
    static var fsSrc:String = '{"varnames":{"uv":"v0","uSampler":"fs0","gl_FragColor":"oc0"},"agalasm":"tex oc, v0.xyyy, fs0 <linear mipdisable repeat 2d>\\n","info":"","storage":{"v0":"ir_var_in","fs0":"ir_var_uniform","oc0":"ir_var_out"},"types":{"v0":"vec2","fs0":"sampler2D","oc0":"vec4"},"consts":{}}';

#end
    
    static var rd:RenderDevice;
    static var base:SampleBase;

    // handles
    static var vBuf:Int;
    static var iBuf:Int;
    static var vertLayout:Int;
    static var prog:Int;
    static var tex:Int;

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
        var mWorld:Mat44 = new Mat44();
        mWorld.setTranslation(0, 0, -5);

        // create the buffers and the shaderprogram
        // bind the necessary buffers for rendering
        vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
            new RDIVertexLayoutAttrib("vUv", 0, 2, 3),
        ]);
        vBuf = rd.createVertexBuffer(20*4, ByteTools.floats(quadVerts), RDIBufferUsage.STATIC, 5);
        iBuf = rd.createIndexBuffer(6*2, ByteTools.uShorts(quadIndices), RDIBufferUsage.STATIC);
        prog = rd.createProgram(vsSrc, fsSrc);

        // create a texture
        var texSrc:String = #if !lime "../../Common/" + #end "resources/uv.png";
        tex = rd.createTexture(RDITextureTypes.TEX2D, 256, 256, RDITextureFormats.RGBA8, false, true);
        rd.uploadTextureData(tex, 0, 0, null);

        ImageLoader.loadImage(texSrc, function(_data:Dynamic):Void {
            rd.uploadTextureData(tex, 0, 0, _data);
        });

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        var loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT44, mProj.rawData);

        loc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT44, mWorld.rawData);

        loc = rd.getSamplerLoc(prog, "uSampler");
        rd.setSampler(loc, 0); // assign texUnit0 to uSampler

        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuf, 0, 5);
        rd.setIndexBuffer(iBuf);
        rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0
    }

    static function onCtxLost(_ctx:RenderContext):Void
    {
        // clean up the resources
        rd.destroyBuffer(vBuf);
        rd.destroyBuffer(iBuf);
        rd.destroyProgram(prog);
        rd.destroyTexture(tex);
    }

    static function onCtxUpdate(_):Void
    {
        // clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, 6, 0);
    }
}