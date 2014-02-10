package;

import Binary;
import foo3d.RenderDevice;
import foo3d.RenderContext;
import haxe.io.BytesOutput;
import lime.Lime;
import math.Mat44;
import Md2Parser;

class Main {
	
	// data
    static var quadVerts:Array<Float> = [
        -0.5, 0.5, 0,
        0.5,-0.5, 0,
        0.5, 0.5, 0,        
        -0.5,-0.5, 0
    ];
    
    static var quadIndices:Array<Int> = 
        [0, 1, 2, 0, 3, 1];
    
#if (js || cpp)

    static var vsSrc:String = "
        attribute vec3 vPos;

        uniform mat4 viewProjMat;
        uniform mat4 worldMat;

        void main() {
            gl_Position = (viewProjMat * (worldMat * vec4(vPos, 1.0) ));
        }";

    static var fsSrc:String = "
        #ifdef GL_ES
        precision highp float;
        #endif        
        
        uniform vec4 uColor;
        
        void main() {
            gl_FragColor = uColor;
        }";

#elseif flash

    static var vsSrc:String = '{"varnames":{"viewProjMat":"vc5","gl_Position":"op0","unnamed_0":"vc0","worldMat":"vc1","vPos":"va0","unnamed_1":"vt0"},"agalasm":"mov vt0.w, vc0.x\\nmov vt0.xyz, va0.xyzz\\nm44 vt0, vt0, vc1\\nm44 op, vt0, vc5\\n","info":"","storage":{"va0":"ir_var_in","op0":"ir_var_out","vc5":"ir_var_uniform","vc1":"ir_var_uniform"},"types":{"va0":"vec3","op0":"vec4","vc5":"mat4","vc1":"mat4"},"consts":{"vc0":[1,0,0,0]}}';
    
    static var fsSrc:String = '{"consts":{},"varnames":{"uColor":"fc0","gl_FragColor":"oc0"},"agalasm":"mov oc, fc0\\n","storage":{"oc0":"ir_var_out","fc0":"ir_var_uniform"},"info":"","types":{"oc0":"vec4","fc0":"vec4"}}';

#end
    
    static var rd:RenderDevice;

    // handles
    static var vBuf:Int;
    static var iBuf:Int;
    static var vertLayout:Int;
    static var prog:Int;

	public function new () {}
	
	public function ready (lime:Lime):Void {
		
		// create device and basic settings
        rd = new RenderDevice(lime.render.direct_renderer_handle);
        rd.setViewport(0, 0, 800, 600);
        rd.setScissorRect(0, 0, 800, 600);

        // create the matrices for the scene
        var mProj:Mat44 = Mat44.createPerspLH(60, 800/600, 0.1, 1000.0);
        var mWorld:Mat44 = new Mat44();
        mWorld.setTranslation(0, 0, -5);

        // create the buffers and the shaderprogram
        vertLayout = rd.registerVertexLayout([
            new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
        ]);
        vBuf = rd.createVertexBuffer(12, ByteTools.floats(quadVerts), RDIBufferUsage.STATIC, 3);
        iBuf = rd.createIndexBuffer(6, ByteTools.uShorts(quadIndices), RDIBufferUsage.STATIC);
        
        prog = rd.createProgram(vsSrc, fsSrc);

        // bind the shader, query the locations of the uniforms and upload new data
        rd.bindProgram(prog);
        
        var loc = rd.getUniformLoc(prog, "uColor");
        rd.setUniform(loc, RDIShaderConstType.FLOAT4, [0.0, 1.0, 0.0, 1.0]);

        loc = rd.getUniformLoc(prog, "viewProjMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT44, mProj.rawData);

        loc = rd.getUniformLoc(prog, "worldMat");
        rd.setUniform(loc, RDIShaderConstType.FLOAT44, mWorld.rawData);

        // bind the necessary buffers for rendering
        rd.setVertexLayout(vertLayout);
        rd.setVertexBuffer(0, vBuf);
        rd.setIndexBuffer(iBuf);
	}

	static var time:Float = haxe.Timer.stamp();
    static var deltaTime:Float;
    static var rot:Float = 0;
    static var fpsTimer:Float = 0;
    static var animFPS:Float = 0.25;    
    static var scrollTimer:Float = 0;
    static var scrollFPS:Float = 1.0;
	
	private function render ():Void {

		// clear framebuffer and draw the bound resources
        rd.clear(RDIClearFlags.ALL, 0, 0, 0.8);
        rd.draw(RDIPrimType.TRIANGLES, 6, 0);
	}
}