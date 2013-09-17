package ;

class SampleShaders 
{	
	public static var vsFsQuad:String =
#if (js || cpp)
	"
	attribute vec3 vPos;
	attribute vec2 vUv;
	uniform mat4 viewProjMat;
	varying vec2 uv;
	void main() {
		uv = vUv;
		gl_Position = viewProjMat * vec4(vPos, 1.0);
	}
	"
#elseif flash
	'
	{"agalasm":"mov v0, vc0\\nmov v0.xy, va0.xyyy\\nmov vt0.w, vc0.x\\nmov vt0.xyz, va1.xyzz\\nm44 op, vt0, vc1\\n","consts":{"vc0":[1,0,0,0]},"varnames":{"gl_Position":"op0","vUv":"va0","unnamed_0":"vc0","uv":"v0","vPos":"va1","viewProjMat":"vc1","unnamed_1":"vt0"},"info":"","types":{"op0":"vec4","v0":"vec2","va0":"vec2","va1":"vec3","vc1":"mat4"},"storage":{"op0":"ir_var_out","v0":"ir_var_out","va0":"ir_var_in","va1":"ir_var_in","vc1":"ir_var_uniform"}}
	'
#end
	;

	public static var fsRed:String =
#if (js || cpp)
	"
	#ifdef GL_ES
    precision highp float;
    #endif
    void main() {
        gl_FragColor = vec4(0.8, 0, 0, 1);
    }
    "
#elseif flash
	'
	{"agalasm":"mov oc, fc0\\n","consts":{"fc0":[0.8,0,0,1]},"varnames":{"gl_FragColor":"oc0","unnamed_0":"fc0"},"info":"","types":{"oc0":"vec4"},"storage":{"oc0":"ir_var_out"}}
	'
#end
	;

	public static var fsOneTex:String = 
#if (js || cpp)
	"
	#ifdef GL_ES
    precision mediump float;
    #endif
    varying vec2 uv;
    uniform sampler2D tex;
    uniform float time;
    void main() {
        gl_FragColor = texture2D(tex, uv+time);
    }
	"
#elseif flash
	'
{
  "storage": {
    "oc0": "ir_var_out",
    "v0": "ir_var_in",
    "fs0": "ir_var_uniform",
    "fc1": "ir_var_uniform"
  },
  "info": "",
  "varnames": {
    "tex": "fs0",
    "unnamed_0": "fc0",
    "unnamed_1": "ft0",
    "time": "fc1",
    "uv": "v0",
    "gl_FragColor": "oc0"
  },
  "consts": {
    "fc0": [
      0,
      0,
      0,
      0
    ]
  },
  "agalasm": "add ft0.xy, v0.xyyy, fc1.x\\ntex oc, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\n",
  "types": {
    "oc0": "vec4",
    "v0": "vec2",
    "fs0": "sampler2D",
    "fc1": "float"
  }
}
	'
#end
	;

	public static var vsMd2:String = 
#if (js || cpp)
	"
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
    }
	"
#elseif flash
	'
	{"agalasm":"mov v0, vc0\\nmov v0.xy, va0.xyyy\\nmov vt0.w, vc0.x\\nsub vt1.xyz, va1.xyzz, va2.xyzz\\nmul vt1.xyz, vt1.xyzz, vc1.x\\nadd vt0.xyz, va2.xyzz, vt1.xyzz\\nm44 vt1, vt0, vc2\\nm44 op, vt1, vc6\\n","consts":{"vc0":[1,0,0,0]},"varnames":{"gl_Position":"op0","unnamed_2":"vt1","interp":"vc1","unnamed_0":"vc0","vPosSrc":"va2","worldMat":"vc2","uv":"v0","viewProjMat":"vc6","unnamed_1":"vt0","vPosDst":"va1","vUv":"va0"},"info":"","types":{"va1":"vec3","v0":"vec2","va0":"vec2","op0":"vec4","vc6":"mat4","vc2":"mat4","vc1":"float","va2":"vec3"},"storage":{"va1":"ir_var_in","v0":"ir_var_out","va0":"ir_var_in","op0":"ir_var_out","vc6":"ir_var_uniform","vc2":"ir_var_uniform","vc1":"ir_var_uniform","va2":"ir_var_in"}}
	'
#end
	;

	public static var fsBlurHorizontal:String = 
#if (js || cpp)
	"
	#ifdef GL_ES
    precision mediump float;
    #endif

    varying vec2 uv;
    uniform sampler2D tex;

    const float sigma = 0.75;

    void main() {

    	vec2 du1 = vec2(0, 1.7229/512.0*sigma);
    	vec2 du2 = vec2(0, 3.8697/512.0*sigma);

    	vec4 filtered = texture2D(tex, uv - du2) + 
    					texture2D(tex, uv - du1) + 
    					texture2D(tex, uv) + 
    					texture2D(tex, uv + du1) + 
    					texture2D(tex, uv + du2);

    	gl_FragColor = filtered/5.0;
    }
	"
#elseif flash
	'
  {
    "types": {
      "fs0": "sampler2D",
      "v0": "vec2",
      "oc0": "vec4"
    },
    "info": "",
    "storage": {
      "fs0": "ir_var_uniform",
      "v0": "ir_var_in",
      "oc0": "ir_var_out"
    },
    "consts": {
      "fc2": [
        5,
        0,
        0,
        0
      ],
      "fc0": [
        0.005669,
        0,
        0,
        0
      ],
      "fc1": [
        0.002524,
        0,
        0,
        0
      ]
    },
    "agalasm": "sub ft0.xy, v0.xyyy, fc0.yxyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nmov ft1, ft0\\nsub ft0.xy, v0.xyyy, fc1.yxyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\ntex ft0, v0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\nadd ft0.xy, v0.xyyy, fc1.yxyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\nadd ft0.xy, v0.xyyy, fc0.yxyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\ndiv oc, ft1, fc2.x\\n",
    "varnames": {
      "tex": "fs0",
      "unnamed_0": "fc0",
      "unnamed_2": "fc2",
      "uv": "v0",
      "unnamed_4": "ft1",
      "unnamed_3": "ft0",
      "gl_FragColor": "oc0",
      "unnamed_1": "fc1",
      "unnamed_5": "ft2"
    }
  }
	'
#end
	;

	public static var fsBlurVertical:String = 
#if (js || cpp)
	"
	#ifdef GL_ES
    precision mediump float;
    #endif

    varying vec2 uv;
    uniform sampler2D tex;

    const float sigma = 0.75;

    void main() {

    	vec2 du1 = vec2(1.7229/512.0*sigma, 0);
    	vec2 du2 = vec2(3.8697/512.0*sigma, 0);

    	vec4 filtered = texture2D(tex, uv - du2) + 
    					texture2D(tex, uv - du1) + 
    					texture2D(tex, uv) + 
    					texture2D(tex, uv + du1) + 
    					texture2D(tex, uv + du2);

    	gl_FragColor = filtered/5.0;
    }
	"
#elseif flash
	'
  {
    "types": {
      "fs0": "sampler2D",
      "v0": "vec2",
      "oc0": "vec4"
    },
    "info": "",
    "storage": {
      "fs0": "ir_var_uniform",
      "v0": "ir_var_in",
      "oc0": "ir_var_out"
    },
    "consts": {
      "fc2": [
        5,
        0,
        0,
        0
      ],
      "fc0": [
        0.005669,
        0,
        0,
        0
      ],
      "fc1": [
        0.002524,
        0,
        0,
        0
      ]
    },
    "agalasm": "sub ft0.xy, v0.xyyy, fc0.xyyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nmov ft1, ft0\\nsub ft0.xy, v0.xyyy, fc1.xyyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\ntex ft0, v0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\nadd ft0.xy, v0.xyyy, fc1.xyyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\nadd ft0.xy, v0.xyyy, fc0.xyyy\\ntex ft0, ft0.xyyy, fs0 <linear mipdisable repeat 2d>\\nadd ft1, ft1, ft0\\ndiv oc, ft1, fc2.x\\n",
    "varnames": {
      "tex": "fs0",
      "unnamed_0": "fc0",
      "unnamed_2": "fc2",
      "uv": "v0",
      "unnamed_4": "ft1",
      "unnamed_3": "ft0",
      "gl_FragColor": "oc0",
      "unnamed_1": "fc1",
      "unnamed_5": "ft2"
    }
  }
	'
#end
	;
}