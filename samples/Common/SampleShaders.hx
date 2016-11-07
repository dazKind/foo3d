package ;

class SampleShaders 
{	
	public static var vsFsQuad:String =
	"
	attribute vec3 vPos;
	attribute vec2 vUv;
	uniform mat4 viewProjMat;
	varying vec2 uv;
	void main() {
		uv = vUv;
		gl_Position = viewProjMat * vec4(vPos, 1.0);
	}
	";

	public static var fsRed:String =
	"
	#ifdef GL_ES
    precision highp float;
    #endif
    void main() {
        gl_FragColor = vec4(0.8, 0, 0, 1);
    }
  ";

	public static var fsOneTex:String = 
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
	";

	public static var vsMd2:String = 
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
	";

	public static var fsBlurHorizontal:String = 
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
	";

	public static var fsBlurVertical:String = 
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
	";
}