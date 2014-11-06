package ;

import foo3d.utils.Frame;
import foo3d.RenderDevice;
import foo3d.RenderContext;
import math.Mat44;
import lime.app.Application;
import lime.graphics.RenderContext;

class Sample #if lime extends Application #end {
    // data
    static var quadVerts:Array<Float> = [ // interleaved position + uv
        -0.5, -0.5, 1.0,    0, 1,
        -0.5, 0.5, 1.0,     0, 0,
        0.5, 0.5, 1.0,      1, 0,
        0.5, -0.5, 1.0,     1, 1,
    ];

    static var quadIndices:Array<Int> = 
        [0, 1, 2, 0, 2, 3];
    
    static var vsSrc:String = "
        attribute vec3 vPos;
        attribute vec2 vUv;

        uniform mat4 viewProjMat;

        varying vec2 uv;

        void main() {
            uv = vUv;
            gl_Position = (viewProjMat * vec4(vPos, 1.0));
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
    static var base:SampleBase;

    // handles
    static var vBuf:Int;
    static var iBuf:Int;
    static var vertLayout:Int;
    static var prog:Int;
    static var tex:Int;
    static var offscreenFBO:Int;

    public function new () {
#if lime        
        super ();
#end        
    }

#if lime
    public override function render (context:RenderContext):Void {
        switch (context) {           
            case OPENGL (gl):
                if (rd == null || (rd != null && rd.m_ctx == null)) // init foo3d
                    onCtxCreated(gl);
            default:            
        }
    }
#else
    static function main() 
    {
        Frame.onCtxCreated.add(onCtxCreated);
        Frame.onCtxLost.add(onCtxLost);
        
        Frame.requestContext({name:"foo3d-stage", width:800, height:600});
    }
#end
    static function onCtxCreated(_ctx:Dynamic):Void
    {        
        var time:Int = Std.int(haxe.Timer.stamp()*1000);

        // load the image and then render it into offscreen buffer
        // offscreen buffer has the same size of the image!
        var texSrc:String = #if !lime "../../Common/" + #end "resources/uv.png";
        ImageLoader.loadImage(texSrc, function(_data:Dynamic, ?_width:Int, ?_height:Int):Void {

            // create device and basic settings
            rd = new RenderDevice(_ctx);
            rd.setViewport(0, 0, _width, _height);
            rd.setScissorRect(0, 0, _width, _height);

            // create the matrices for the scene
            var mProj:Mat44 = Mat44.createOrthoLH(-0.5, 0.5, -0.5, 0.5, -1000.0, 1000.0);
            
            // create the buffers and the shaderprogram
            // bind the necessary buffers for rendering
            vertLayout = rd.registerVertexLayout([
                new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
                new RDIVertexLayoutAttrib("vUv", 0, 2, 3*4),
            ]);
            vBuf = rd.createVertexBuffer(20*4, ByteTools.floats(quadVerts), RDIBufferUsage.STATIC, 5);
            iBuf = rd.createIndexBuffer(6*2, ByteTools.uShorts(quadIndices), RDIBufferUsage.STATIC);
            prog = rd.createProgram(vsSrc, fsSrc);
            
            // create a texture
            tex = rd.createTexture(RDITextureTypes.TEX2D, _width, _height, RDITextureFormats.RGBA8, false, false); 
            rd.uploadTextureData(tex, 0, 0, _data);
        
            // bind the shader, query the locations of the uniforms and upload new data
            rd.bindProgram(prog);
            var loc = rd.getUniformLoc(prog, "viewProjMat");
            rd.setUniform(loc, RDIShaderConstType.FLOAT4x4, mProj.rawData);

            loc = rd.getSamplerLoc(prog, "uSampler");
            rd.setSampler(loc, 0); // assign texUnit0 to uSampler

            // create the offscreen buffer
            offscreenFBO = rd.createRenderBuffer(_width, _height, RDITextureFormats.RGBA8, true, 1, 0);
            rd.bindRenderBuffer(offscreenFBO);

            // set everything for draw
            rd.setVertexLayout(vertLayout);
            rd.setVertexBuffer(0, vBuf, 0, 5*4);
            rd.setIndexBuffer(iBuf);
            rd.setTexture(0, tex, RDISamplerState.FILTER_BILINEAR); // assign texture to texUnit0

            // clear framebuffer and draw the bound resources
            rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);            
            rd.draw(RDIPrimType.TRIANGLES, RDIDataType.UNSIGNED_SHORT, 6, 0);

            // read FBO
            var res = rd.getRenderBufferData(offscreenFBO);
            
            saveImg("test.png", res.width, res.height, haxe.io.Bytes.ofData(res.data));

            trace("Done: " + (Std.int(haxe.Timer.stamp()*1000) - time) + "ms");
        });             
        
    }

    static function onCtxLost(_ctx:RenderContext):Void
    {
        // clean up the resources
        rd.destroyBuffer(vBuf);
        rd.destroyBuffer(iBuf);
        rd.destroyProgram(prog);
        rd.destroyTexture(tex);
        rd.destroyRenderBuffer(offscreenFBO);
    }

    static function saveImg(_name:String, _width:Int, _height:Int, _bytes:haxe.io.Bytes) {
        // normalize data (rgba -> argb)
        var tmp:haxe.io.Bytes = haxe.io.Bytes.alloc(_bytes.length);
        var stride:Int = Std.int(_bytes.length/_height);
        for (y in 0..._height) {
            var line = _bytes.sub((_height-y-1)*stride, stride);
            for (x in 0..._width) {
                var a = line.get(x*4);
                var b = line.get((x*4)+1);
                var c = line.get((x*4)+2);
                var d = line.get((x*4)+3);
                line.set(x*4,       d);
                line.set((x*4)+1,   a);
                line.set((x*4)+2,   b);
                line.set((x*4)+3,   c);
            }
            tmp.blit(y*stride, line, 0, stride);
        }
        var data = format.png.Tools.build32ARGB(_width, _height, tmp);
        var out = sys.io.File.write(_name,true);
        new format.png.Writer(out).write(data);
    }
}