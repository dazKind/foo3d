#define IMPLEMENT_API
#include "Foo3D.h"
#include <gl/glew.h>
#include <iostream>

using namespace std;

namespace foo3D {	

	// renderdevice calls
	void hx_rd_init(value _caps) {

		GLenum err = glewInit();
		if (err != GLEW_OK) {
			cout<<"[Foo3D] - [ERROR] - glewInit failed, aborting."<<endl;
			return;
		}
		cout << "[Foo3D] - Using GLEW " << glewGetString(GLEW_VERSION) << endl;

		char* vendor = (char*)glGetString(GL_VENDOR);
		char* renderer = (char*)glGetString(GL_RENDERER);
		char* version = (char*)glGetString(GL_VERSION);

		cout << "[Foo3D] - Initializing GL backend using OpenGL driver " << version << " by " << vendor << " on " << renderer << endl;

		/*
		// must have
		if (!GLEW_EXT_framebuffer_object) {
			cout << "[Foo3D] - [ERROR] - EXT_framebuffer_object not supported" << endl;
		}
		if (!GLEW_EXT_texture_filter_anisotropic) {
			cout << "[Foo3D] - [ERROR] - EXT_texture_filter_anisotropic not supported" << endl;
		}
		if (!GLEW_EXT_texture_compression_s3tc) {
			cout << "[Foo3D] - [ERROR] - EXT_texture_compression_s3tc not supported" << endl;
		}
		if (!GLEW_EXT_texture_sRGB) {
			cout << "[Foo3D] - [ERROR] - EXT_texture_sRGB not supported" << endl;
		}
		*/

		// optional
		alloc_field(_caps, val_id("texFloatSupport"), alloc_bool(GLEW_ARB_texture_float == 1));
		alloc_field(_caps, val_id("texNPOTSupport"), alloc_bool(GLEW_ARB_texture_non_power_of_two == 1));
		alloc_field(_caps, val_id("rtMultisampling"), alloc_bool(GLEW_EXT_framebuffer_multisample == 1));

		// info
		int val;
		glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &val);
		alloc_field(_caps, val_id("maxVertAttribs"), alloc_int(val));
		glGetIntegerv(GL_MAX_VERTEX_UNIFORM_VECTORS, &val);
		alloc_field(_caps, val_id("maxVertUniforms"), alloc_int(val));
		glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &val);
		alloc_field(_caps, val_id("maxColorAttachments"), alloc_int(val));

	}
	DEFINE_PRIM(hx_rd_init, 1);

	// actual gl calls
	value hx_gl_createBuffer() {
		unsigned int buf;
		glGenBuffers(1, &buf);
		return alloc_int(buf);
	}
	DEFINE_PRIM(hx_gl_createBuffer, 0);

	void hx_gl_bindBuffer(value _type, value _handle) {
		glBindBuffer(val_int(_type), val_int(_handle));
	}
	DEFINE_PRIM(hx_gl_bindBuffer, 2);

	void hx_gl_bufferData(value _type, value _size, value _data, value _usageHint) {
		float* f = val_array_float(_data);
		if (f)
			glBufferData(val_int(_type), val_int(_size), (void*)f, val_int(_usageHint));
		else {
			int* i = val_array_int(_data);
			glBufferData(val_int(_type), val_int(_size), (void*)i, val_int(_usageHint));
		}
	}
	DEFINE_PRIM(hx_gl_bufferData, 4);

	void hx_gl_deleteBuffer(value _handle) {
		GLuint h = val_int(_handle);
		glDeleteBuffers(1, &h);
	}
	DEFINE_PRIM(hx_gl_deleteBuffer, 1);

	void hx_gl_bufferSubData(value _type, value _offset, value _size, value _data) {
		float* f = val_array_float(_data);
		if (f)
			glBufferSubData(val_int(_type), val_int(_offset), val_int(_size), (void*)f);
		else {
			int* i = val_array_int(_data);
			glBufferSubData(val_int(_type), val_int(_offset), val_int(_size), (void*)i);
		}
	}
	DEFINE_PRIM(hx_gl_bufferSubData, 4);

	void hx_gl_viewport(value _x, value _y, value _width, value _height) {
		glViewport(val_int(_x), val_int(_y), val_int(_width), val_int(_height));
	}
	DEFINE_PRIM(hx_gl_viewport, 4);

	void hx_gl_scissor(value _x, value _y, value _width, value _height) {
		glScissor(val_int(_x), val_int(_y), val_int(_width), val_int(_height));
	}
	DEFINE_PRIM(hx_gl_scissor, 4);

	void hx_gl_enable(value _cap) {
		glEnable((GLenum)val_int(_cap));
	}
	DEFINE_PRIM(hx_gl_enable, 1);

	void hx_gl_disable(value _cap) {
		glDisable((GLenum)val_int(_cap));
	}
	DEFINE_PRIM(hx_gl_disable, 1);

	void hx_gl_cullFace(value _mode) {
		glCullFace((GLenum)val_int(_mode));
	}
	DEFINE_PRIM(hx_gl_cullFace, 1);

	void hx_gl_depthFunc(value _func) {
		glDepthFunc((GLenum)val_int(_func));
	}
	DEFINE_PRIM(hx_gl_depthFunc, 1);

	void hx_gl_blendFunc(value _src, value _dst) {
		glBlendFunc((GLenum)val_int(_src), (GLenum)val_int(_dst));
	}
	DEFINE_PRIM(hx_gl_blendFunc, 2);

	void hx_gl_activeTexture(value _tex) {
		glActiveTexture((GLenum)val_int(_tex));
	}
	DEFINE_PRIM(hx_gl_activeTexture, 1);

	void hx_gl_bindTexture(value _target, value _tex) {
		glBindTexture((GLenum)val_int(_target), val_int(_tex));
	}
	DEFINE_PRIM(hx_gl_bindTexture, 2);

	void hx_gl_vertexAttribPointer(value *args, int nargs) {
		const value &index = *args++;
		const value &size = *args++;
		const value &type = *args++;
		const value &normalized = *args++;
		const value &stride = *args++;
		const value &offset = *args;

		glVertexAttribPointer(
			val_int(index), 
			val_int(size), 
			val_int(type), 
			val_bool(normalized),
			val_int(stride),
			(char*)0+val_int(offset)
		);
	}
	DEFINE_PRIM_MULT(hx_gl_vertexAttribPointer);

	void hx_gl_enableVertexAttribArray(value _index) {
		glEnableVertexAttribArray((GLuint)val_int(_index));
	}
	DEFINE_PRIM(hx_gl_enableVertexAttribArray, 1);

	void hx_gl_disableVertexAttribArray(value _index) {
		glDisableVertexAttribArray((GLuint)val_int(_index));
	}
	DEFINE_PRIM(hx_gl_disableVertexAttribArray, 1);

	void hx_gl_texParameteri(value _target, value _pname, value param) {
		glTexParameteri((GLenum)val_int(_target), (GLenum)val_int(_pname), (GLint)val_int(param));
	}
	DEFINE_PRIM(hx_gl_texParameteri, 3);

	void hx_gl_clearDepth(value _depth) {
		glClearDepth((GLfloat)val_float(_depth));
	}
	DEFINE_PRIM(hx_gl_clearDepth, 1);

	void hx_gl_clearColor(value _r, value _g, value _b, value _a) {
		glClearColor(
			(GLfloat)val_float(_r),
			(GLfloat)val_float(_g),
			(GLfloat)val_float(_b),
			(GLfloat)val_float(_a)
		);
	}
	DEFINE_PRIM(hx_gl_clearColor, 4);

	void hx_gl_clear(value _mask) {
		glClear(val_int(_mask));
	}
	DEFINE_PRIM(hx_gl_clear, 1);

	value hx_gl_createTexture() {
		unsigned int tex;
		glGenTextures(1, &tex);
		return alloc_int(tex);
	}
	DEFINE_PRIM(hx_gl_createTexture, 0);

	void hx_gl_texImage2D(value *args, int nargs) {
		const value &target = *args++;
		const value &mipLevel = *args++;
		const value &format = *args++;
		const value &width = *args++;
		const value &height = *args++;
		const value &border = *args++;
		const value &inputFormat = *args++;
		const value &inputType = *args++;
		const value &data = *args;

		glTexImage2D(
			val_int(target), 
			val_int(mipLevel), 
			val_int(format), 
			val_int(width), 
			val_int(height),
			val_int(border),
			val_int(inputFormat),
			val_int(inputType),
			data == NULL ? NULL : (void*)buffer_data(val_to_buffer(data))
		);
	}
	DEFINE_PRIM_MULT(hx_gl_texImage2D);

	void hx_gl_generateMipmap(value _target) {
		glGenerateMipmap(val_int(_target));
	}
	DEFINE_PRIM(hx_gl_generateMipmap, 1);

	void hx_gl_deleteTexture(value _target) {
		GLuint h = val_int(_target);
		glDeleteTextures(1, &h);
	}
	DEFINE_PRIM(hx_gl_deleteTexture, 1);



	value hx_gl_createShader(value _type) {
		return alloc_int(glCreateShader(val_int(_type)));
	}
	DEFINE_PRIM(hx_gl_createShader, 1);

	void hx_gl_deleteShader(value _handle) {
		glDeleteShader(val_int(_handle));
	}
	DEFINE_PRIM(hx_gl_deleteShader, 1);

	void hx_gl_compileShader(value _handle) {
		glCompileShader(val_int(_handle));
	}
	DEFINE_PRIM(hx_gl_compileShader, 1);

	void hx_gl_shaderSource(value _handle, value _src) {
		const char* src = val_string(_src);
		glShaderSource(val_int(_handle), 1, &src, NULL);
	}
	DEFINE_PRIM(hx_gl_shaderSource, 2);

	value hx_gl_getShaderiv(value _handle, value _pname) {
		int res;
		glGetShaderiv(val_int(_handle), val_int(_pname), &res);
		return alloc_int(res);
	}
	DEFINE_PRIM(hx_gl_getShaderiv, 2);

	value hx_gl_getShaderInfoLog(value _handle) {
		value res;
		int infoLogLength = 0;			
		int sh = val_int(_handle);
		glGetShaderiv(sh, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 1) {
			int charsWritten = 0;
			char *infoLog = new char[infoLogLength];
			glGetShaderInfoLog(sh, infoLogLength, &charsWritten, infoLog);
			res = alloc_string(infoLog);
			delete[] infoLog;
			infoLog = NULL;
		}
		return res;
	}
	DEFINE_PRIM(hx_gl_getShaderInfoLog, 1);

	value hx_gl_createProgram() {
		return alloc_int(glCreateProgram());
	}
	DEFINE_PRIM(hx_gl_createProgram, 0);

	void hx_gl_deleteProgram(value _handle) {
		glDeleteProgram(val_int(_handle));
	}
	DEFINE_PRIM(hx_gl_deleteProgram, 1);

	void hx_gl_linkProgram(value _handle) {
		glLinkProgram(val_int(_handle));
	}
	DEFINE_PRIM(hx_gl_linkProgram, 1);

	value hx_gl_getProgramiv(value _handle, value _pname) {
		int res;
		glGetProgramiv(val_int(_handle), val_int(_pname), &res);
		return alloc_int(res);
	}
	DEFINE_PRIM(hx_gl_getProgramiv, 2);

	value hx_gl_getProgramInfoLog(value _handle) {
		value res;
		int infoLogLength = 0;			
		int sh = val_int(_handle);
		glGetProgramiv(sh, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 1) {
			int charsWritten = 0;
			char *infoLog = new char[infoLogLength];
			glGetProgramInfoLog(sh, infoLogLength, &charsWritten, infoLog);
			res = alloc_string(infoLog);
			delete[] infoLog;
			infoLog = NULL;
		}
		return res;
	}
	DEFINE_PRIM(hx_gl_getProgramInfoLog, 1);

	void hx_gl_attachShader(value _prog, value _shader) {
		glAttachShader(val_int(_prog), val_int(_shader));
	}
	DEFINE_PRIM(hx_gl_attachShader, 2);

	void hx_gl_getActiveAttrib(value _program, value _index, value _info) {
		char name[32];
		unsigned int size, type;
		glGetActiveAttrib( 
			val_int(_program), 
			val_int(_index),
			32,
			NULL,
			(int *)&size, 
			&type, 
			name
		);
		alloc_field(_info, val_id("name"), alloc_string(name));
		alloc_field(_info, val_id("type"), alloc_int(type));
	}
	DEFINE_PRIM(hx_gl_getActiveAttrib, 3);

	value hx_gl_getAttribLocation(value _prog, value _name) {
		return alloc_int(glGetAttribLocation(val_int(_prog), val_string(_name)));
	}
	DEFINE_PRIM(hx_gl_getAttribLocation, 2);

	void hx_gl_useProgram(value _handle) {
		glUseProgram(val_int(_handle));
	}
	DEFINE_PRIM(hx_gl_useProgram, 1);

	void hx_gl_getActiveUniform(value _program, value _index, value _info) {
		char name[32];
		unsigned int size, type;
		glGetActiveUniform( 
			val_int(_program), 
			val_int(_index),
			32,
			NULL,
			(int *)&size, 
			&type, 
			name
		);
		alloc_field(_info, val_id("name"), alloc_string(name));
		alloc_field(_info, val_id("type"), alloc_int(type));
	}
	DEFINE_PRIM(hx_gl_getActiveUniform, 3);

	value hx_gl_getUniformLocation(value _prog, value _name) {
		return alloc_int(glGetUniformLocation(val_int(_prog), val_string(_name)));
	}
	DEFINE_PRIM(hx_gl_getUniformLocation, 2);

	void hx_gl_uniform1fv(value _loc, value _data) {
		glUniform1fv(val_int(_loc), val_array_size(_data), (float*)val_array_float(_data));
	}
	DEFINE_PRIM(hx_gl_uniform1fv, 2);

	void hx_gl_uniform2fv(value _loc, value _data) {
		glUniform2fv(val_int(_loc), val_array_size(_data)/2, (float*)val_array_float(_data));
	}
	DEFINE_PRIM(hx_gl_uniform2fv, 2);

	void hx_gl_uniform3fv(value _loc, value _data) {
		glUniform3fv(val_int(_loc), val_array_size(_data)/3, (float*)val_array_float(_data));
	}
	DEFINE_PRIM(hx_gl_uniform3fv, 2);

	void hx_gl_uniform4fv(value _loc, value _data) {
		glUniform4fv(val_int(_loc), val_array_size(_data)/4, (float*)val_array_float(_data));
	}
	DEFINE_PRIM(hx_gl_uniform4fv, 2);

	void hx_gl_uniformMatrix3fv(value _loc, value _transpose, value _data) {
		glUniformMatrix3fv(val_int(_loc), val_array_size(_data)/9, val_bool(_transpose), (float*)val_array_float(_data));
	}
	DEFINE_PRIM(hx_gl_uniformMatrix3fv, 3);

	void hx_gl_uniformMatrix4fv(value _loc, value _transpose, value _data) {
		glUniformMatrix4fv(val_int(_loc), val_array_size(_data)/16, val_bool(_transpose), (float*)val_array_float(_data));
	}
	DEFINE_PRIM(hx_gl_uniformMatrix4fv, 3);

	void hx_gl_uniform1i(value _loc, value _data) {
		glUniform1i(val_int(_loc), val_int(_data));
	}
	DEFINE_PRIM(hx_gl_uniform1i, 2);

	void hx_gl_drawRangeElements(value _primType, value _numInds, value _offset) {
		int count = val_int(_numInds);
		int start = val_int(_offset);
		int end = start + count;
		glDrawRangeElements(
			val_int(_primType), 
			start, 
			end, 
			count, 
			GL_UNSIGNED_INT, // TODO: optimize this!
			(char *)0 + (start*4)
		);
	}
	DEFINE_PRIM(hx_gl_drawRangeElements, 3);

	void hx_gl_drawArrays(value _primType, value _offset, value _size) {
		glDrawArrays(val_int(_primType), val_int(_offset), val_int(_size));
	}
	DEFINE_PRIM(hx_gl_drawArrays, 3);

	value hx_gl_getIntegerv(value _target) {
		int res;
		glGetIntegerv(val_int(_target), &res);
		return alloc_int(res);
	}
	DEFINE_PRIM(hx_gl_getIntegerv, 1);



	value hx_gl_genFramebuffer() {
		unsigned int res;
		glGenFramebuffers(1, &res);
		return alloc_int(res);
	}
	DEFINE_PRIM(hx_gl_genFramebuffer, 0);

	value hx_gl_genRenderbuffer() {
		unsigned int res;
		glGenRenderbuffers(1, &res);
		return alloc_int(res);
	}
	DEFINE_PRIM(hx_gl_genRenderbuffer, 0);

	void hx_gl_bindFramebuffer(value _mode, value _target) {
		glBindFramebuffer(val_int(_mode), val_int(_target));
	}
	DEFINE_PRIM(hx_gl_bindFramebuffer, 2);

	void hx_gl_bindRenderbuffer(value _mode,value _target) {
		glBindRenderbuffer(val_int(_mode), val_int(_target));
	}
	DEFINE_PRIM(hx_gl_bindRenderbuffer, 2);

	void hx_gl_framebufferTexture2D(value _attachment, value tex) {
		glFramebufferTexture2D(GL_FRAMEBUFFER, val_int(_attachment), GL_TEXTURE_2D, val_int(tex), 0);
	}
	DEFINE_PRIM(hx_gl_framebufferTexture2D, 2);

	void hx_gl_renderbufferStorageMultisample(value _samples, value _format, value _width, value _height) {
		glRenderbufferStorageMultisample(GL_RENDERBUFFER, val_int(_samples), val_int(_format), val_int(_width), val_int(_height));
	}
	DEFINE_PRIM(hx_gl_renderbufferStorageMultisample, 4);

	void hx_gl_framebufferRenderbuffer(value _attachment, value _target) {
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, val_int(_attachment), GL_RENDERBUFFER, val_int(_target));
	}
	DEFINE_PRIM(hx_gl_framebufferRenderbuffer, 2);

	void hx_gl_drawBuffer(value _mode) {
		glDrawBuffer(val_int(_mode));
	}
	DEFINE_PRIM(hx_gl_drawBuffer, 1);

	const unsigned int color_buffers[] = {
		GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3,  
		GL_COLOR_ATTACHMENT4, GL_COLOR_ATTACHMENT5, GL_COLOR_ATTACHMENT6, GL_COLOR_ATTACHMENT7,  
		GL_COLOR_ATTACHMENT8, GL_COLOR_ATTACHMENT9, GL_COLOR_ATTACHMENT10, GL_COLOR_ATTACHMENT11,  
		GL_COLOR_ATTACHMENT12, GL_COLOR_ATTACHMENT13, GL_COLOR_ATTACHMENT14, GL_COLOR_ATTACHMENT15  
	};
	void hx_gl_drawBuffers(value _numColBufs) {
		glDrawBuffers(val_int(_numColBufs), color_buffers);
	}
	DEFINE_PRIM(hx_gl_drawBuffers, 1);

	void hx_gl_readBuffer(value _mode) {
		glReadBuffer(val_int(_mode));
	}
	DEFINE_PRIM(hx_gl_readBuffer, 1);

	value hx_gl_checkFrameBufferStatus() {
		return alloc_int(glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}
	DEFINE_PRIM(hx_gl_checkFrameBufferStatus, 0);

	void hx_gl_deleteRenderbuffer(value _target) {
		unsigned int t = val_int(_target);
		glDeleteRenderbuffers(1, &t);
	}
	DEFINE_PRIM(hx_gl_deleteRenderbuffer, 1);

	void hx_gl_deleteFramebuffer(value _target) {
		unsigned int t = val_int(_target);
		glDeleteFramebuffers(1, &t);
	}
	DEFINE_PRIM(hx_gl_deleteFramebuffer, 1);

	void hx_gl_blitFramebuffer(value _width, value _height, value _mask) {
		int w = val_int(_width);
		int h = val_int(_height);
		int mask = val_int(_mask);
		glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, mask, GL_NEAREST);
	}
	DEFINE_PRIM(hx_gl_blitFramebuffer, 3);


	void hx_gl_depthMask(value _flag) {
		glDepthMask(val_int(_flag));
	}
	DEFINE_PRIM(hx_gl_depthMask, 1);

	void hx_gl_blendEquation(value _mode) {
		glBlendEquation(val_int(_mode));
	}
	DEFINE_PRIM(hx_gl_blendEquation, 1);

	void hx_gl_blendEquationBuffer(value _buffer, value _mode) {
		glBlendEquationi(val_int(_buffer), val_int(_mode));
	}
	DEFINE_PRIM(hx_gl_blendEquationBuffer, 2);
}
