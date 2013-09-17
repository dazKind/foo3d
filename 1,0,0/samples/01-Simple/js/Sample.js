(function () { "use strict";
function $extend(from, fields) {
	function inherit() {}; inherit.prototype = from; var proto = new inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var List = function() {
	this.length = 0;
};
List.__name__ = true;
List.prototype = {
	iterator: function() {
		return { h : this.h, hasNext : function() {
			return this.h != null;
		}, next : function() {
			if(this.h == null) return null;
			var x = this.h[0];
			this.h = this.h[1];
			return x;
		}};
	}
	,remove: function(v) {
		var prev = null;
		var l = this.h;
		while(l != null) {
			if(l[0] == v) {
				if(prev == null) this.h = l[1]; else prev[1] = l[1];
				if(this.q == l) this.q = prev;
				this.length--;
				return true;
			}
			prev = l;
			l = l[1];
		}
		return false;
	}
	,push: function(item) {
		var x = [item,this.h];
		this.h = x;
		if(this.q == null) this.q = x;
		this.length++;
	}
	,__class__: List
}
var Reflect = function() { }
Reflect.__name__ = true;
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && !(f.__name__ || f.__ename__);
}
Reflect.compareMethods = function(f1,f2) {
	if(f1 == f2) return true;
	if(!Reflect.isFunction(f1) || !Reflect.isFunction(f2)) return false;
	return f1.scope == f2.scope && f1.method == f2.method && f1.method != null;
}
var Sample = function() { }
Sample.__name__ = true;
Sample.main = function() {
	foo3D.utils.Frame.onCtxCreated.add(Sample.onCtxCreated);
	foo3D.utils.Frame.onCtxLost.add(Sample.onCtxLost);
	foo3D.utils.Frame.onCtxUpdate.add(Sample.onCtxUpdate);
	foo3D.utils.Frame.requestContext({ name : "foo3D-stage", width : 800, height : 600});
}
Sample.onCtxCreated = function(_ctx) {
	Sample.rd = new foo3D.impl.WebGLRenderDevice(_ctx);
	Sample.rd.setViewport(0,0,800,600);
	Sample.rd.setScissorRect(0,0,800,600);
	var mProj = math.Mat44.createPerspLH(60,800 / 600,0.1,1000.0);
	var mWorld = new math.Mat44();
	mWorld.rawData[12] = 0;
	mWorld.rawData[13] = 0;
	mWorld.rawData[14] = -5;
	Sample.vertLayout = Sample.rd.registerVertexLayout([new foo3D.RDIVertexLayoutAttrib("vPos",0,3,0)]);
	Sample.vBuf = Sample.rd.createVertexBuffer(12,Sample.quadVerts,35044,3);
	Sample.iBuf = Sample.rd.createIndexBuffer(6,Sample.quadIndices,35044);
	Sample.prog = Sample.rd.createProgram(Sample.vsSrc,Sample.fsSrc);
	Sample.rd.bindProgram(Sample.prog);
	var loc = Sample.rd.getUniformLoc(Sample.prog,"uColor");
	Sample.rd.setUniform(loc,35666,[0.0,1.0,0.0,1.0]);
	loc = Sample.rd.getUniformLoc(Sample.prog,"viewProjMat");
	Sample.rd.setUniform(loc,35675,mProj.rawData);
	loc = Sample.rd.getUniformLoc(Sample.prog,"worldMat");
	Sample.rd.setUniform(loc,35675,mWorld.rawData);
	Sample.rd.setVertexLayout(Sample.vertLayout);
	Sample.rd.setVertexBuffer(0,Sample.vBuf);
	Sample.rd.setIndexBuffer(Sample.iBuf);
}
Sample.onCtxLost = function(_ctx) {
	Sample.rd.destroyBuffer(Sample.vBuf);
	Sample.rd.destroyBuffer(Sample.iBuf);
	Sample.rd.destroyProgram(Sample.prog);
}
Sample.onCtxUpdate = function(_) {
	Sample.rd.clear(-1,0,0,0.8);
	Sample.rd.draw(4,6,0);
}
var Std = function() { }
Std.__name__ = true;
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
}
var foo3D = {}
foo3D.RDIObjects = function() {
	this.m_objects = [];
	this.m_freeList = [];
};
foo3D.RDIObjects.__name__ = true;
foo3D.RDIObjects.prototype = {
	getRef: function(_handle) {
		return this.m_objects[_handle - 1];
	}
	,remove: function(_handle) {
		var index = _handle - 1;
		this.m_objects[index] = null;
		this.m_freeList.push(index);
	}
	,add: function(_obj) {
		var index = -1;
		if(this.m_freeList.length > 0) {
			index = this.m_freeList.pop();
			this.m_objects[index] = _obj;
			index += 1;
		} else {
			this.m_objects.push(_obj);
			index = this.m_objects.length;
		}
		return index;
	}
	,__class__: foo3D.RDIObjects
}
foo3D.RDIDeviceCaps = function() {
	this.texFloatSupport = false;
	this.texNPOTSupport = false;
	this.maxVertAttribs = 0;
	this.maxVertUniforms = 0;
	this.maxColorAttachments = 1;
};
foo3D.RDIDeviceCaps.__name__ = true;
foo3D.RDIDeviceCaps.prototype = {
	toString: function() {
		var res = "[Foo3D] - Device Capabilities:\n";
		res += "texFloatSupport = " + Std.string(this.texFloatSupport) + "\n";
		res += "texNPOTSupport = " + Std.string(this.texNPOTSupport) + "\n";
		res += "rtMultisampling = " + Std.string(this.rtMultisampling) + "\n";
		res += "maxVertAttribs = " + this.maxVertAttribs + "\n";
		res += "maxVertUniforms = " + this.maxVertUniforms + "\n";
		res += "maxColorAttachments = " + this.maxColorAttachments + "\n";
		return res;
	}
	,__class__: foo3D.RDIDeviceCaps
}
foo3D.RDIVertexLayoutAttrib = function(_semanticName,_vbSlot,_size,_offset) {
	if(_offset == null) _offset = 0;
	if(_size == null) _size = 0;
	if(_vbSlot == null) _vbSlot = 0;
	if(_semanticName == null) _semanticName = "";
	this.semanticName = _semanticName;
	this.vbSlot = _vbSlot;
	this.size = _size;
	this.offset = _offset;
};
foo3D.RDIVertexLayoutAttrib.__name__ = true;
foo3D.RDIVertexLayoutAttrib.prototype = {
	__class__: foo3D.RDIVertexLayoutAttrib
}
foo3D.RDIVertexLayout = function() {
	this.numAttribs = 0;
	this.attribs = [];
	var _g = 0;
	while(_g < 16) {
		var i = _g++;
		this.attribs.push(new foo3D.RDIVertexLayoutAttrib());
	}
};
foo3D.RDIVertexLayout.__name__ = true;
foo3D.RDIVertexLayout.prototype = {
	__class__: foo3D.RDIVertexLayout
}
foo3D.RDIBufferUsage = function() { }
foo3D.RDIBufferUsage.__name__ = true;
foo3D.RDIBufferType = function() { }
foo3D.RDIBufferType.__name__ = true;
foo3D.RDIBuffer = function(_type,_glObj,_size,_usageHint) {
	this.type = _type;
	this.glObj = _glObj;
	this.size = _size;
	this.usage = _usageHint;
};
foo3D.RDIBuffer.__name__ = true;
foo3D.RDIBuffer.prototype = {
	__class__: foo3D.RDIBuffer
}
foo3D.RDIVertBufSlot = function(_vbObj,_offset,_stride) {
	if(_stride == null) _stride = 0;
	if(_offset == null) _offset = 0;
	if(_vbObj == null) _vbObj = 0;
	this.vbObj = _vbObj;
	this.offset = _offset;
	this.stride = _stride;
};
foo3D.RDIVertBufSlot.__name__ = true;
foo3D.RDIVertBufSlot.prototype = {
	__class__: foo3D.RDIVertBufSlot
}
foo3D.RDITextureTypes = function() { }
foo3D.RDITextureTypes.__name__ = true;
foo3D.RDITextureFormats = function() { }
foo3D.RDITextureFormats.__name__ = true;
foo3D.RDITexture = function() {
	this.glObj = null;
	this.glFmt = null;
	this.type = 0;
	this.format = 0;
	this.width = 0;
	this.height = 0;
	this.memSize = 0;
	this.samplerState = 0;
	this.hasMips = false;
	this.genMips = false;
};
foo3D.RDITexture.__name__ = true;
foo3D.RDITexture.prototype = {
	__class__: foo3D.RDITexture
}
foo3D.RDITexSlot = function(_texObj,_samplerState) {
	if(_samplerState == null) _samplerState = 0;
	if(_texObj == null) _texObj = 0;
	this.texObj = _texObj;
	this.samplerState = _samplerState;
};
foo3D.RDITexSlot.__name__ = true;
foo3D.RDITexSlot.prototype = {
	__class__: foo3D.RDITexSlot
}
foo3D.RDIShaderConstType = function() { }
foo3D.RDIShaderConstType.__name__ = true;
foo3D.RDIUniformInfo = function() {
};
foo3D.RDIUniformInfo.__name__ = true;
foo3D.RDIUniformInfo.prototype = {
	__class__: foo3D.RDIUniformInfo
}
foo3D.RDIShaderInputLayout = function() {
	this.valid = false;
	this.attribIndices = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
};
foo3D.RDIShaderInputLayout.__name__ = true;
foo3D.RDIShaderInputLayout.prototype = {
	__class__: foo3D.RDIShaderInputLayout
}
foo3D.RDIShaderProgram = function() {
	this.oglProgramObj = null;
	this.inputLayouts = [];
	var _g = 0;
	while(_g < 16) {
		var i = _g++;
		this.inputLayouts.push(new foo3D.RDIShaderInputLayout());
	}
};
foo3D.RDIShaderProgram.__name__ = true;
foo3D.RDIShaderProgram.prototype = {
	__class__: foo3D.RDIShaderProgram
}
foo3D.RDIRenderBuffer = function(_numColBufs) {
	this.fbo = null;
	this.fboMS = null;
	this.width = 0;
	this.height = 0;
	this.depthTex = null;
	this.depthBufObj = null;
	this.samples = 0;
	this.colTexs = [];
	this.colBufs = [];
	var _g = 0;
	while(_g < _numColBufs) {
		var i = _g++;
		this.colTexs.push(0);
		this.colBufs.push(0);
	}
};
foo3D.RDIRenderBuffer.__name__ = true;
foo3D.RDIRenderBuffer.prototype = {
	__class__: foo3D.RDIRenderBuffer
}
foo3D.RDISamplerState = function() { }
foo3D.RDISamplerState.__name__ = true;
foo3D.RDIBlendFactors = function() { }
foo3D.RDIBlendFactors.__name__ = true;
foo3D.RDITestModes = function() { }
foo3D.RDITestModes.__name__ = true;
foo3D.RDICullModes = function() { }
foo3D.RDICullModes.__name__ = true;
foo3D.RDIClearFlags = function() { }
foo3D.RDIClearFlags.__name__ = true;
foo3D.RDIPrimType = function() { }
foo3D.RDIPrimType.__name__ = true;
foo3D.AbstractRenderDevice = function(_ctx) {
	this.m_ctx = _ctx;
	this.m_vpX = 0;
	this.m_vpY = 0;
	this.m_vpWidth = 320;
	this.m_vpHeight = 240;
	this.m_scX = 0;
	this.m_scY = 0;
	this.m_scWidth = 320;
	this.m_scHeight = 240;
	this.m_curShaderId = 0;
	this.m_prevShaderId = 0;
	this.m_newVertLayout = 0;
	this.m_curIndexBuf = 1;
	this.m_newIndexBuf = 0;
	this.m_curSrcFactor = 0;
	this.m_newSrcFactor = 1;
	this.m_curDstFactor = 1;
	this.m_newDstFactor = 0;
	this.m_curCullMode = 0;
	this.m_newCullMode = 1029;
	this.m_depthTestEnabled = false;
	this.m_curDepthTest = 516;
	this.m_newDepthTest = 513;
	this.m_curRenderBuffer = 0;
	this.m_pendingMask = 0;
	this.m_activeVertexAttribsMask = 0;
	this.m_bufferMem = 0;
	this.m_textureMem = 0;
	this.m_caps = new foo3D.RDIDeviceCaps();
	this.m_buffers = new foo3D.RDIObjects();
	this.m_textures = new foo3D.RDIObjects();
	this.m_shaders = new foo3D.RDIObjects();
	this.m_renBuffers = new foo3D.RDIObjects();
	this.m_vertBufSlots = [];
	this.m_vertexLayouts = [];
	this.m_texSlots = [];
	var _g = 0;
	while(_g < 16) {
		var i = _g++;
		this.m_vertBufSlots.push(null);
		this.m_texSlots.push(new foo3D.RDITexSlot());
		this.m_vertexLayouts.push(new foo3D.RDIVertexLayout());
	}
	this.m_numVertexLayouts = 0;
	this.init();
};
foo3D.AbstractRenderDevice.__name__ = true;
foo3D.AbstractRenderDevice.prototype = {
	setDepthFunc: function(_mode) {
		if(_mode == null) _mode = 513;
		this.m_newDepthTest = _mode;
		this.m_pendingMask |= 128;
	}
	,setCullMode: function(_mode) {
		this.m_newCullMode = _mode;
		this.m_pendingMask |= 64;
	}
	,setBlendFunc: function(_srcFactor,_dstFactor) {
		if(_dstFactor == null) _dstFactor = 0;
		if(_srcFactor == null) _srcFactor = 1;
		this.m_newSrcFactor = _srcFactor;
		this.m_newDstFactor = _dstFactor;
		this.m_pendingMask |= 32;
	}
	,setTexture: function(_slot,_handle,_samplerState) {
		this.m_texSlots[_slot] = new foo3D.RDITexSlot(_handle,_samplerState);
		this.m_pendingMask |= 8;
	}
	,setVertexLayout: function(_vlObj) {
		this.m_newVertLayout = _vlObj;
	}
	,setVertexBuffer: function(_slot,_handle,_offset,_stride) {
		if(_stride == null) _stride = 0;
		if(_offset == null) _offset = 0;
		this.m_vertBufSlots[_slot] = new foo3D.RDIVertBufSlot(_handle,_offset,_stride);
		this.m_pendingMask |= 4;
	}
	,setIndexBuffer: function(_handle) {
		this.m_newIndexBuf = _handle;
		this.m_pendingMask |= 2;
	}
	,setScissorRect: function(_x,_y,_width,_height) {
		this.m_scX = _x;
		this.m_scY = _y;
		this.m_scWidth = _width;
		this.m_scHeight = _height;
		this.m_pendingMask |= 16;
	}
	,setViewport: function(_x,_y,_width,_height) {
		this.m_vpX = _x;
		this.m_vpY = _y;
		this.m_vpWidth = _width;
		this.m_vpHeight = _height;
		this.m_pendingMask |= 1;
	}
	,drawArrays: function(_primType,_offset,_size) {
		throw "NOT IMPLENTED";
	}
	,draw: function(_primType,_numInds,_offset) {
		throw "NOT IMPLENTED";
	}
	,clear: function(_flags,_r,_g,_b,_a,_depth) {
		if(_depth == null) _depth = 1;
		if(_a == null) _a = 1;
		if(_b == null) _b = 0;
		if(_g == null) _g = 0;
		if(_r == null) _r = 0;
		throw "NOT IMPLENTED";
	}
	,applySamplerState: function(_tex) {
		throw "NOT IMPLENTED";
	}
	,applyVertexLayout: function() {
		throw "NOT IMPLENTED";
		return false;
	}
	,isLost: function() {
		throw "NOT IMPLENTED";
		return true;
	}
	,resetStates: function() {
		throw "NOT IMPLENTED";
	}
	,commitStates: function(_filter) {
		if(_filter == null) _filter = -1;
		throw "NOT IMPLENTED";
		return false;
	}
	,getRenderBufferData: function(_handle,_bufIndex) {
		if(_bufIndex == null) _bufIndex = 0;
		throw "NOT IMPLENTED";
		return null;
	}
	,bindRenderBuffer: function(_handle) {
		throw "NOT IMPLENTED";
	}
	,getRenderBufferTex: function(_handle,_bufIndex) {
		if(_bufIndex == null) _bufIndex = 0;
		throw "NOT IMPLENTED";
		return 0;
	}
	,destroyRenderBuffer: function(_handle) {
		throw "NOT IMPLENTED";
	}
	,createRenderBuffer: function(_width,_height,_format,_depth,_numColBufs,_samples) {
		if(_samples == null) _samples = 0;
		if(_numColBufs == null) _numColBufs = 1;
		throw "NOT IMPLENTED";
		return 0;
	}
	,setSampler: function(_loc,_texUnit) {
		throw "NOT IMPLENTED";
	}
	,setUniform: function(_loc,_type,_values) {
		throw "NOT IMPLENTED";
	}
	,getSamplerLoc: function(_handle,_name) {
		throw "NOT IMPLENTED";
		return null;
	}
	,getUniformLoc: function(_handle,_name) {
		throw "NOT IMPLENTED";
		return null;
	}
	,getActiveUniformInfo: function(_handle,_index) {
		throw "NOT IMPLENTED";
		return null;
	}
	,getActiveUniformCount: function(_handle) {
		throw "NOT IMPLENTED";
		return 0;
	}
	,bindProgram: function(_handle) {
		throw "NOT IMPLENTED";
	}
	,destroyProgram: function(_handle) {
		throw "NOT IMPLENTED";
	}
	,createProgram: function(_vertexShaderSrc,_fragmentShaderSrc) {
		throw "NOT IMPLENTED";
		return 0;
	}
	,getTextureMem: function() {
		return this.m_textureMem;
	}
	,calcTextureSize: function(_format,_width,_height) {
		var s = 0;
		switch(_format) {
		case 32856:
			s = _width * _height * 4;
			break;
		case 34842:
			s = _width * _height * 8;
			break;
		}
		return s;
	}
	,destroyTexture: function(_handle) {
		throw "NOT IMPLEMENTED";
	}
	,uploadTextureData: function(_handle,_slice,_mipLevel,_pixels) {
		throw "NOT IMPLENTED";
	}
	,createTexture: function(_type,_width,_height,_format,_hasMips,_genMips,_hintIsRenderTarget) {
		if(_hintIsRenderTarget == null) _hintIsRenderTarget = false;
		throw "NOT IMPLEMENTED";
		return 0;
	}
	,getBufferMem: function() {
		return this.m_bufferMem;
	}
	,registerVertexLayout: function(_attribs) {
		if(this.m_numVertexLayouts == 16) return 0;
		this.m_vertexLayouts[this.m_numVertexLayouts].numAttribs = _attribs.length;
		var _g1 = 0, _g = _attribs.length;
		while(_g1 < _g) {
			var i = _g1++;
			this.m_vertexLayouts[this.m_numVertexLayouts].attribs[i] = _attribs[i];
		}
		return ++this.m_numVertexLayouts;
	}
	,updateIndexBufferData: function(_handle,_offset,_size,_data) {
		throw "NOT IMPLEMENTED";
	}
	,updateVertexBufferData: function(_handle,_offset,_size,_data) {
		throw "NOT IMPLEMENTED";
	}
	,destroyBuffer: function(_handle) {
		throw "NOT IMPLEMENTED";
	}
	,createIndexBuffer: function(_size,_data,_usageHint) {
		if(_usageHint == null) _usageHint = 35044;
		throw "NOT IMPLEMENTED";
		return 0;
	}
	,createVertexBuffer: function(_size,_data,_usageHint,_strideHint) {
		if(_strideHint == null) _strideHint = -1;
		if(_usageHint == null) _usageHint = 35044;
		throw "NOT IMPLEMENTED";
		return 0;
	}
	,init: function() {
		throw "NOT IMPLENTED";
	}
	,__class__: foo3D.AbstractRenderDevice
}
foo3D.impl = {}
foo3D.impl.WebGLRenderDevice = function(_ctx) {
	foo3D.AbstractRenderDevice.call(this,_ctx);
};
foo3D.impl.WebGLRenderDevice.__name__ = true;
foo3D.impl.WebGLRenderDevice.__super__ = foo3D.AbstractRenderDevice;
foo3D.impl.WebGLRenderDevice.prototype = $extend(foo3D.AbstractRenderDevice.prototype,{
	drawArrays: function(_primType,_offset,_size) {
		if(this.commitStates()) this.m_ctx.drawArrays(_primType,_offset,_size);
	}
	,draw: function(_primType,_numInds,_offset) {
		if(this.commitStates()) this.m_ctx.drawElements(_primType,_numInds,5123,_offset);
	}
	,clear: function(_flags,_r,_g,_b,_a,_depth) {
		if(_depth == null) _depth = 1;
		if(_a == null) _a = 1;
		if(_b == null) _b = 0;
		if(_g == null) _g = 0;
		if(_r == null) _r = 0;
		var mask = 0;
		if((_flags & 2) == 2) {
			mask |= 256;
			this.m_ctx.clearDepth(_depth);
		}
		if((_flags & 1) == 1) {
			mask |= 16384;
			this.m_ctx.clearColor(_r,_g,_b,_a);
		}
		if((_flags & -1) == -1) mask |= 17664;
		if(mask != 0) {
			this.commitStates(17);
			this.m_ctx.clear(mask);
		}
	}
	,isLost: function() {
		return this.m_ctx.isContextLost();
	}
	,resetStates: function() {
		this.m_curIndexBuf = 1;
		this.m_newIndexBuf = 0;
		this.m_curSrcFactor = 0;
		this.m_newSrcFactor = 1;
		this.m_curDstFactor = 1;
		this.m_newDstFactor = 0;
		this.m_curCullMode = 0;
		this.m_newCullMode = 1029;
		this.m_depthTestEnabled = false;
		this.m_curDepthTest = 516;
		this.m_newDepthTest = 513;
		var _g = 0;
		while(_g < 16) {
			var i = _g++;
			this.setTexture(i,0,0);
		}
		this.m_activeVertexAttribsMask = 0;
		var _g1 = 0, _g = this.m_caps.maxVertAttribs;
		while(_g1 < _g) {
			var i = _g1++;
			this.m_ctx.disableVertexAttribArray(i);
		}
		this.m_pendingMask = -1;
		this.commitStates();
	}
	,commitStates: function(_filter) {
		if(_filter == null) _filter = -1;
		if((this.m_pendingMask & _filter) != 0) {
			var mask = this.m_pendingMask & _filter;
			if((mask & 1) == 1) {
				this.m_ctx.viewport(this.m_vpX,this.m_vpY,this.m_vpWidth,this.m_vpHeight);
				this.m_pendingMask &= -2;
			}
			if((mask & 16) == 16) {
				this.m_ctx.scissor(this.m_scX,this.m_scY,this.m_scWidth,this.m_scHeight);
				this.m_pendingMask &= -17;
			}
			if((mask & 64) == 64) {
				if(this.m_newCullMode != this.m_curCullMode) {
					if(this.m_newCullMode == 0) this.m_ctx.disable(2884); else {
						this.m_ctx.enable(2884);
						this.m_ctx.cullFace(this.m_newCullMode);
					}
					this.m_curCullMode = this.m_newCullMode;
				}
				this.m_pendingMask &= -65;
			}
			if((mask & 128) == 128) {
				if(this.m_newDepthTest != this.m_curDepthTest) {
					if(this.m_newDepthTest == 0) {
						if(this.m_depthTestEnabled) {
							this.m_ctx.disable(2929);
							this.m_depthTestEnabled = false;
						}
					} else {
						if(!this.m_depthTestEnabled) {
							this.m_ctx.enable(2929);
							this.m_depthTestEnabled = true;
						}
						this.m_ctx.depthFunc(this.m_newDepthTest);
					}
					this.m_curDepthTest = this.m_newDepthTest;
				}
				this.m_pendingMask &= -129;
			}
			if((mask & 2) == 2) {
				if(this.m_newIndexBuf != this.m_curIndexBuf) {
					if(this.m_newIndexBuf != 0) this.m_ctx.bindBuffer(34963,this.m_buffers.m_objects[this.m_newIndexBuf - 1].glObj); else this.m_ctx.bindBuffer(34963,null);
					this.m_curIndexBuf = this.m_newIndexBuf;
				}
				this.m_pendingMask &= -3;
			}
			if((mask & 4) == 4) {
				if(!this.applyVertexLayout()) return false;
				this.m_prevShaderId = this.m_curShaderId;
				this.m_pendingMask &= -5;
			}
			if((mask & 32) == 32) {
				if(this.m_newSrcFactor != this.m_curSrcFactor || this.m_newDstFactor != this.m_curDstFactor) {
					if(this.m_newSrcFactor == 1 && this.m_newDstFactor == 0) this.m_ctx.disable(3042); else {
						this.m_ctx.enable(3042);
						this.m_ctx.blendFunc(this.m_newSrcFactor,this.m_newDstFactor);
					}
					this.m_curSrcFactor = this.m_newSrcFactor;
					this.m_curDstFactor = this.m_newDstFactor;
				}
				this.m_pendingMask &= -33;
			}
			if((mask & 8) == 8) {
				var _g = 0;
				while(_g < 16) {
					var i = _g++;
					this.m_ctx.activeTexture(33984 + i);
					if(this.m_texSlots[i].texObj != 0) {
						var tex = this.m_textures.m_objects[this.m_texSlots[i].texObj - 1];
						this.m_ctx.bindTexture(tex.type,tex.glObj);
						if(tex.samplerState != this.m_texSlots[i].samplerState) {
							tex.samplerState = this.m_texSlots[i].samplerState;
							this.applySamplerState(tex);
						}
					} else {
						this.m_ctx.bindTexture(34067,null);
						this.m_ctx.bindTexture(3553,null);
					}
				}
				this.m_pendingMask &= -9;
			}
		}
		return true;
	}
	,applySamplerState: function(_tex) {
		var state = _tex.samplerState;
		var target = _tex.type;
		if(_tex.hasMips) this.m_ctx.texParameteri(target,10241,foo3D.impl.WebGLRenderDevice.minFiltersMips[state & 3]); else this.m_ctx.texParameteri(target,10241,foo3D.impl.WebGLRenderDevice.magFilters[state & 3]);
		this.m_ctx.texParameteri(target,10240,foo3D.impl.WebGLRenderDevice.magFilters[state & 3]);
		this.m_ctx.texParameteri(target,10242,foo3D.impl.WebGLRenderDevice.wrapModes[(state & 192) >> 6]);
		this.m_ctx.texParameteri(target,10243,foo3D.impl.WebGLRenderDevice.wrapModes[(state & 768) >> 8]);
	}
	,applyVertexLayout: function() {
		if(this.m_newVertLayout == 0 || this.m_curShaderId == 0) return false;
		var vl = this.m_vertexLayouts[this.m_newVertLayout - 1];
		var shader = this.m_shaders.m_objects[this.m_curShaderId - 1];
		var inputLayout = shader.inputLayouts[this.m_newVertLayout - 1];
		if(!inputLayout.valid) return false;
		var newVertexAttribMask = 0;
		var _g1 = 0, _g = vl.numAttribs;
		while(_g1 < _g) {
			var i = _g1++;
			var attribIndex = inputLayout.attribIndices[i];
			if(attribIndex >= 0) {
				var attrib = vl.attribs[i];
				var vbSlot = this.m_vertBufSlots[attrib.vbSlot];
				this.m_ctx.bindBuffer(34962,this.m_buffers.m_objects[vbSlot.vbObj - 1].glObj);
				this.m_ctx.vertexAttribPointer(attribIndex,attrib.size,5126,false,vbSlot.stride * 4,(vbSlot.offset + attrib.offset) * 4);
				newVertexAttribMask |= 1 << attribIndex;
			}
		}
		var _g = 0;
		while(_g < 16) {
			var i = _g++;
			var curBit = 1 << i;
			if((newVertexAttribMask & curBit) != (this.m_activeVertexAttribsMask & curBit)) {
				if((newVertexAttribMask & curBit) == curBit) this.m_ctx.enableVertexAttribArray(i); else this.m_ctx.disableVertexAttribArray(i);
			}
		}
		this.m_activeVertexAttribsMask = newVertexAttribMask;
		return true;
	}
	,getRenderBufferData: function(_handle,_bufIndex) {
		if(_bufIndex == null) _bufIndex = 0;
		var res = { width : 0, height : 0, data : []};
		var x = 0;
		var y = 0;
		var w = 0;
		var h = 0;
		var format = 6408;
		var type = 5121;
		if(_handle == 0) {
			res.width = w = this.m_vpWidth;
			res.height = h = this.m_vpHeight;
			x = this.m_vpX;
			y = this.m_vpY;
			this.m_ctx.bindFramebuffer(36160,null);
		} else {
			var rb = this.m_renBuffers.m_objects[_handle - 1];
			if(_bufIndex >= this.m_caps.maxColorAttachments || rb.colTexs[_bufIndex] == 0) return null;
			res.width = w = rb.width;
			res.height = h = rb.height;
			this.m_ctx.bindFramebuffer(36160,rb.fbo);
		}
		this.m_ctx.finish();
		this.m_ctx.readPixels(x,y,w,h,format,type,res.data);
		return res;
	}
	,bindRenderBuffer: function(_handle) {
		this.m_curRenderBuffer = _handle;
		if(_handle == 0) this.m_ctx.bindFramebuffer(36160,null); else {
			var _g = 0;
			while(_g < 16) {
				var i = _g++;
				this.setTexture(i,0,0);
			}
			this.commitStates(8);
			var rb = this.m_renBuffers.m_objects[_handle - 1];
			this.m_ctx.bindFramebuffer(36160,rb.fbo);
		}
	}
	,getRenderBufferTex: function(_handle,_bufIndex) {
		if(_bufIndex == null) _bufIndex = 0;
		var rb = this.m_renBuffers.m_objects[_handle - 1];
		if(_bufIndex < this.m_caps.maxColorAttachments) return rb.colTexs[_bufIndex]; else return 0;
	}
	,destroyRenderBuffer: function(_handle) {
		var rb = this.m_renBuffers.m_objects[_handle - 1];
		if(rb.depthBufObj != null) this.m_ctx.deleteRenderbuffer(rb.depthBufObj);
		rb.depthBufObj = null;
		var _g1 = 0, _g = this.m_caps.maxColorAttachments;
		while(_g1 < _g) {
			var i = _g1++;
			if(rb.colTexs[i] != 0) this.destroyTexture(rb.colTexs[i]);
			rb.colTexs[i] = 0;
		}
		if(rb.fbo != null) this.m_ctx.deleteFramebuffer(rb.fbo);
		rb.fbo = null;
		this.m_renBuffers.remove(_handle);
	}
	,createRenderBuffer: function(_width,_height,_format,_depth,_numColBufs,_samples) {
		if(_samples == null) _samples = 0;
		if(_numColBufs == null) _numColBufs = 1;
		if(_format == 34842 || _numColBufs > this.m_caps.maxColorAttachments) return 0;
		var rb = new foo3D.RDIRenderBuffer(_numColBufs);
		rb.width = _width;
		rb.height = _height;
		rb.fbo = this.m_ctx.createFramebuffer();
		if(_numColBufs > 0) {
			var _g = 0;
			while(_g < _numColBufs) {
				var j = _g++;
				this.m_ctx.bindFramebuffer(36160,rb.fbo);
				var texObj = this.createTexture(3553,rb.width,rb.height,_format,false,false,true);
				this.uploadTextureData(texObj,0,0,null);
				rb.colTexs[j] = texObj;
				var tex = this.m_textures.m_objects[texObj - 1];
				this.m_ctx.framebufferTexture2D(36160,36064 + j,3553,tex.glObj,0);
			}
		}
		if(_depth) {
			this.m_ctx.bindFramebuffer(36160,rb.fbo);
			rb.depthBufObj = this.m_ctx.createRenderbuffer();
			this.m_ctx.bindRenderbuffer(36161,rb.depthBufObj);
			this.m_ctx.renderbufferStorage(36161,33189,rb.width,rb.height);
			this.m_ctx.framebufferRenderbuffer(36160,36096,36161,rb.depthBufObj);
		}
		var rbObj = this.m_renBuffers.add(rb);
		var status = this.m_ctx.checkFramebufferStatus(36160);
		switch(status) {
		case 36061:
			throw "Framebuffer is not supported";
			break;
		case 36054:
			throw "Framebuffer incomplete attachment";
			break;
		case 36057:
			throw "Framebuffer incomplete dimensions";
			break;
		case 36055:
			throw "Framebuffer incomplete missing attachment";
			break;
		}
		if(status != 36053) {
			this.destroyRenderBuffer(rbObj);
			return 0;
		}
		return rbObj;
	}
	,setSampler: function(_loc,_texUnit) {
		this.m_ctx.uniform1i(_loc,_texUnit);
	}
	,setUniform: function(_loc,_type,_values) {
		switch(_type) {
		case 5126:
			this.m_ctx.uniform1fv(_loc,new Float32Array(_values));
			break;
		case 35664:
			this.m_ctx.uniform2fv(_loc,new Float32Array(_values));
			break;
		case 35665:
			this.m_ctx.uniform3fv(_loc,new Float32Array(_values));
			break;
		case 35666:
			this.m_ctx.uniform4fv(_loc,new Float32Array(_values));
			break;
		case 35676:
			this.m_ctx.uniformMatrix3fv(_loc,false,new Float32Array(_values));
			break;
		case 35675:
			this.m_ctx.uniformMatrix4fv(_loc,false,new Float32Array(_values));
			break;
		}
	}
	,getSamplerLoc: function(_handle,_name) {
		var shader = this.m_shaders.m_objects[_handle - 1];
		return this.m_ctx.getUniformLocation(shader.oglProgramObj,_name);
	}
	,getUniformLoc: function(_handle,_name) {
		var shader = this.m_shaders.m_objects[_handle - 1];
		return this.m_ctx.getUniformLocation(shader.oglProgramObj,_name);
	}
	,getActiveUniformInfo: function(_handle,_index) {
		var shader = this.m_shaders.m_objects[_handle - 1];
		var res = new foo3D.RDIUniformInfo();
		var info = this.m_ctx.getActiveUniform(shader.oglProgramObj,_index);
		res.name = info.name;
		res.type = info.type;
		return res;
	}
	,getActiveUniformCount: function(_handle) {
		var shader = this.m_shaders.m_objects[_handle - 1];
		return this.m_ctx.getProgramParameter(shader.oglProgramObj,35718);
	}
	,bindProgram: function(_handle) {
		if(_handle != 0) {
			var shader = this.m_shaders.m_objects[_handle - 1];
			this.m_ctx.useProgram(shader.oglProgramObj);
		} else this.m_ctx.useProgram(null);
		this.m_curShaderId = _handle;
		this.m_pendingMask |= 4;
	}
	,destroyProgram: function(_handle) {
		if(_handle == 0) return;
		var shader = this.m_shaders.m_objects[_handle - 1];
		this.m_ctx.deleteProgram(shader.oglProgramObj);
		this.m_shaders.remove(_handle);
	}
	,createProgram: function(_vertexShaderSrc,_fragmentShaderSrc) {
		var vs = this.m_ctx.createShader(35633);
		this.m_ctx.shaderSource(vs,_vertexShaderSrc);
		this.m_ctx.compileShader(vs);
		var success = this.m_ctx.getShaderParameter(vs,35713);
		if(!success && !this.m_ctx.isContextLost()) {
			console.log("[Vertex Shader] " + this.m_ctx.getShaderInfoLog(vs));
			this.m_ctx.deleteShader(vs);
			return 0;
		}
		var fs = this.m_ctx.createShader(35632);
		this.m_ctx.shaderSource(fs,_fragmentShaderSrc);
		this.m_ctx.compileShader(fs);
		var success1 = this.m_ctx.getShaderParameter(fs,35713);
		if(!success1 && !this.m_ctx.isContextLost()) {
			console.log("[Fragment Shader] " + this.m_ctx.getShaderInfoLog(fs));
			this.m_ctx.deleteShader(vs);
			this.m_ctx.deleteShader(fs);
			return 0;
		}
		var prog = this.m_ctx.createProgram();
		this.m_ctx.attachShader(prog,vs);
		this.m_ctx.attachShader(prog,fs);
		this.m_ctx.deleteShader(vs);
		this.m_ctx.deleteShader(fs);
		this.m_ctx.linkProgram(prog);
		success1 = this.m_ctx.getProgramParameter(prog,35714);
		if(!success1 && !this.m_ctx.isContextLost()) {
			console.log("[LINKING] " + this.m_ctx.getProgramInfoLog(prog));
			this.m_ctx.deleteProgram(prog);
			return 0;
		}
		var shader = new foo3D.RDIShaderProgram();
		shader.oglProgramObj = prog;
		var attribCount = this.m_ctx.getProgramParameter(prog,35721);
		var _g1 = 0, _g = this.m_numVertexLayouts;
		while(_g1 < _g) {
			var i = _g1++;
			var vl = this.m_vertexLayouts[i];
			var allAttribsFound = true;
			var _g2 = 0;
			while(_g2 < 16) {
				var j = _g2++;
				shader.inputLayouts[i].attribIndices[j] = -1;
			}
			var _g2 = 0;
			while(_g2 < attribCount) {
				var j = _g2++;
				var info = this.m_ctx.getActiveAttrib(prog,j);
				var attribFound = false;
				var _g4 = 0, _g3 = vl.numAttribs;
				while(_g4 < _g3) {
					var k = _g4++;
					if(vl.attribs[k].semanticName == info.name) {
						shader.inputLayouts[i].attribIndices[k] = this.m_ctx.getAttribLocation(prog,info.name);
						attribFound = true;
					}
				}
				if(!attribFound) {
					allAttribsFound = false;
					break;
				}
			}
			shader.inputLayouts[i].valid = allAttribsFound;
		}
		return this.m_shaders.add(shader);
	}
	,destroyTexture: function(_handle) {
		if(_handle == 0) return;
		var tex = this.m_textures.m_objects[_handle - 1];
		this.m_ctx.deleteTexture(tex.glObj);
		this.m_textureMem -= tex.memSize;
		this.m_textures.remove(_handle);
	}
	,uploadTextureData: function(_handle,_slice,_mipLevel,_pixels) {
		var tex = this.m_textures.m_objects[_handle - 1];
		this.m_ctx.activeTexture(33999);
		this.m_ctx.bindTexture(tex.type,tex.glObj);
		var inputFormat = 6408;
		var inputType = 5121;
		switch(tex.format) {
		case 34842:
			inputFormat = 6408;
			inputType = 5126;
			break;
		case 33190:
			throw "[Foo3D - ERROR] - TextureFormats.DEPTH not supported yet";
			break;
		}
		var target = tex.type == 3553?3553:34069 + _slice;
		if(_pixels == null) {
			var width = Math.max(tex.width >> _mipLevel,1) | 0;
			var height = Math.max(tex.height >> _mipLevel,1) | 0;
			this.m_ctx.texImage2D(target,_mipLevel,tex.glFmt,width,height,0,inputFormat,inputType,null);
		} else this.m_ctx.texImage2D(target,_mipLevel,tex.glFmt,inputFormat,inputType,_pixels);
		if(tex.genMips && (tex.type != 34067 || _slice == 5)) this.m_ctx.generateMipmap(tex.type);
		this.m_ctx.bindTexture(tex.type,null);
		if(this.m_texSlots[15].texObj > 0) {
			var t = this.m_textures.m_objects[this.m_texSlots[15].texObj - 1];
			this.m_ctx.bindTexture(t.type,t.glObj);
		}
	}
	,createTexture: function(_type,_width,_height,_format,_hasMips,_genMips,_hintIsRenderTarget) {
		if(_hintIsRenderTarget == null) _hintIsRenderTarget = false;
		var tex = new foo3D.RDITexture();
		tex.type = _type;
		tex.format = _format;
		tex.width = _width;
		tex.height = _height;
		tex.genMips = _genMips;
		tex.hasMips = _hasMips;
		switch(_format) {
		case 32856:case 34842:
			tex.glFmt = 6408;
			break;
		case 33190:
			tex.glFmt = 6402;
			break;
		}
		tex.glObj = this.m_ctx.createTexture();
		this.m_ctx.activeTexture(33999);
		this.m_ctx.bindTexture(_type,tex.glObj);
		tex.samplerState = 0;
		this.applySamplerState(tex);
		this.m_ctx.bindTexture(_type,null);
		if(this.m_texSlots[15].texObj > 0) {
			var t = this.m_textures.m_objects[this.m_texSlots[15].texObj - 1];
			this.m_ctx.bindTexture(t.type,t.glObj);
		}
		tex.memSize = this.calcTextureSize(tex.format,_width,_height);
		if(_hasMips || _genMips) tex.memSize += tex.memSize * 1.0 / 3.0 | 0;
		if(_type == 34067) tex.memSize *= 6;
		this.m_textureMem += tex.memSize;
		return this.m_textures.add(tex);
	}
	,updateIndexBufferData: function(_handle,_offset,_size,_data) {
		var buf = this.m_buffers.m_objects[_handle - 1];
		this.m_ctx.bindBuffer(buf.type,buf.glObj);
		this.m_ctx.bufferSubData(buf.type,_offset,js.Boot.__cast(_data , ArrayBuffer));
		this.m_ctx.bindBuffer(buf.type,null);
	}
	,updateVertexBufferData: function(_handle,_offset,_size,_data) {
		var buf = this.m_buffers.m_objects[_handle - 1];
		this.m_ctx.bindBuffer(buf.type,buf.glObj);
		this.m_ctx.bufferSubData(buf.type,_offset,js.Boot.__cast(_data , ArrayBuffer));
		this.m_ctx.bindBuffer(buf.type,null);
	}
	,destroyBuffer: function(_handle) {
		if(_handle == 0) return;
		var buf = this.m_buffers.m_objects[_handle - 1];
		this.m_ctx.deleteBuffer(buf.glObj);
		this.m_bufferMem -= buf.size;
		this.m_buffers.remove(_handle);
	}
	,createIndexBuffer: function(_size,_data,_usageHint) {
		if(_usageHint == null) _usageHint = 35044;
		var buf = new foo3D.RDIBuffer(34963,this.m_ctx.createBuffer(),_size * 4,_usageHint);
		this.m_ctx.bindBuffer(buf.type,buf.glObj);
		this.m_ctx.bufferData(buf.type,new Uint16Array(_data),_usageHint);
		this.m_ctx.bindBuffer(buf.type,null);
		this.m_bufferMem += buf.size;
		return this.m_buffers.add(buf);
	}
	,createVertexBuffer: function(_size,_data,_usageHint,_strideHint) {
		if(_strideHint == null) _strideHint = -1;
		if(_usageHint == null) _usageHint = 35044;
		var buf = new foo3D.RDIBuffer(34962,this.m_ctx.createBuffer(),_size * 4,_usageHint);
		this.m_ctx.bindBuffer(buf.type,buf.glObj);
		this.m_ctx.bufferData(buf.type,new Float32Array(_data),_usageHint);
		this.m_ctx.bindBuffer(buf.type,null);
		this.m_bufferMem += buf.size;
		return this.m_buffers.add(buf);
	}
	,init: function() {
		this.m_caps.texFloatSupport = this.m_ctx.getExtension("OES_texture_float") == null?false:true;
		this.m_caps.texNPOTSupport = true;
		this.m_caps.rtMultisampling = false;
		this.m_caps.maxVertAttribs = this.m_ctx.getParameter(34921);
		this.m_caps.maxVertUniforms = this.m_ctx.getParameter(36347);
		this.m_caps.maxColorAttachments = 1;
		console.log(this.m_caps.toString());
		this.resetStates();
	}
	,__class__: foo3D.impl.WebGLRenderDevice
});
foo3D.utils = {}
foo3D.utils.Signal = function() {
	this.m_listener = new List();
};
foo3D.utils.Signal.__name__ = true;
foo3D.utils.Signal.prototype = {
	dispatch: function(_data) {
		var $it0 = this.m_listener.iterator();
		while( $it0.hasNext() ) {
			var l = $it0.next();
			l(_data);
		}
	}
	,has: function(_func) {
		var found = false;
		var $it0 = this.m_listener.iterator();
		while( $it0.hasNext() ) {
			var l = $it0.next();
			if(Reflect.compareMethods(l,_func)) {
				found = true;
				break;
			}
		}
		return found;
	}
	,remove: function(_func) {
		var $it0 = this.m_listener.iterator();
		while( $it0.hasNext() ) {
			var f = $it0.next();
			if(Reflect.compareMethods(f,_func)) {
				if(this.m_listener.remove(f) == false) throw "WTF?";
				break;
			}
		}
	}
	,add: function(_func) {
		var $it0 = this.m_listener.iterator();
		while( $it0.hasNext() ) {
			var l = $it0.next();
			if(Reflect.compareMethods(l,_func)) {
				throw "NO DOUBLE ADD";
				return;
			}
		}
		this.m_listener.push(_func);
	}
	,__class__: foo3D.utils.Signal
}
var haxe = {}
haxe.Timer = function() { }
haxe.Timer.__name__ = true;
haxe.Timer.stamp = function() {
	return new Date().getTime() / 1000;
}
foo3D.utils.Frame = function() { }
foo3D.utils.Frame.__name__ = true;
foo3D.utils.Frame.requestContext = function(_config) {
	var container = js.Browser.document.getElementById(_config.name);
	var canvas = js.Boot.__cast(js.Browser.document.createElement("canvas") , HTMLCanvasElement);
	canvas.width = _config.width;
	canvas.height = _config.height;
	container.appendChild(canvas);
	foo3D.utils.Frame.ctx = WebGLUtils.setupWebGL(canvas);
	canvas.addEventListener("webglcontextlost",function(_evt) {
		console.log("[Foo3D] - context lost");
		foo3D.utils.Frame.onCtxLost.dispatch(foo3D.utils.Frame.ctx);
		_evt.preventDefault();
	},false);
	canvas.addEventListener("webglcontextrestored",function(_evt) {
		console.log("[Foo3D] - context restored");
		foo3D.utils.Frame.onCtxCreated.dispatch(foo3D.utils.Frame.ctx);
	},false);
	foo3D.utils.Frame.onCtxCreated.dispatch(foo3D.utils.Frame.ctx);
	foo3D.utils.Frame.update();
}
foo3D.utils.Frame.update = function() {
	var curTime = haxe.Timer.stamp();
	foo3D.utils.Frame.deltaTime = curTime - foo3D.utils.Frame.time;
	foo3D.utils.Frame.onCtxUpdate.dispatch();
	js.Browser.window.requestAnimFrame(foo3D.utils.Frame.update);
	foo3D.utils.Frame.time = curTime;
}
var js = {}
js.Boot = function() { }
js.Boot.__name__ = true;
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2, _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i;
			var str = "[";
			s += "\t";
			var _g = 0;
			while(_g < l) {
				var i1 = _g++;
				str += (i1 > 0?",":"") + js.Boot.__string_rec(o[i1],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) { ;
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
}
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0, _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
}
js.Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) {
					if(cl == Array) return o.__enum__ == null;
					return true;
				}
				if(js.Boot.__interfLoop(o.__class__,cl)) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
}
js.Boot.__cast = function(o,t) {
	if(js.Boot.__instanceof(o,t)) return o; else throw "Cannot cast " + Std.string(o) + " to " + Std.string(t);
}
js.Browser = function() { }
js.Browser.__name__ = true;
var math = {}
math.Mat44 = function() {
	this.rawData = new Array();
	this.rawData[0] = 1;
	this.rawData[1] = 0;
	this.rawData[2] = 0;
	this.rawData[3] = 0;
	this.rawData[4] = 0;
	this.rawData[5] = 1;
	this.rawData[6] = 0;
	this.rawData[7] = 0;
	this.rawData[8] = 0;
	this.rawData[9] = 0;
	this.rawData[10] = 1;
	this.rawData[11] = 0;
	this.rawData[12] = 0;
	this.rawData[13] = 0;
	this.rawData[14] = 0;
	this.rawData[15] = 1;
};
math.Mat44.__name__ = true;
math.Mat44.create = function(_m) {
	var m = new math.Mat44();
	if(_m != null) m.rawData = _m;
	return m;
}
math.Mat44.createOrthoLH = function(_l,_r,_t,_b,_n,_f) {
	var m = new math.Mat44();
	m.rawData[0] = 2 / (_r - _l);
	m.rawData[5] = 2 / (_t - _b);
	m.rawData[10] = -2 / (_f - _n);
	m.rawData[12] = -(_r + _l) / (_r - _l);
	m.rawData[13] = -(_t + _b) / (_t - _b);
	m.rawData[14] = -(_f + _n) / (_f - _n);
	return m;
}
math.Mat44.createPerspLH = function(_fov,_aspect,_nz,_fz) {
	var ymax = _nz * Math.tan(0.0087266462599716478846184538424431 * _fov);
	var xmax = ymax * _aspect;
	return math.Mat44.createPerspOffCenterLH(xmax,ymax,_nz,_fz);
}
math.Mat44.createPerspOffCenterLH = function(_maxX,_maxY,_nz,_fz) {
	var m = new math.Mat44();
	m.rawData[0] = 2 * _nz / (_maxX * 2);
	m.rawData[5] = 2 * _nz / (_maxY * 2);
	m.rawData[8] = 0;
	m.rawData[9] = 0;
	m.rawData[10] = -(_fz + _nz) / (_fz - _nz);
	m.rawData[11] = -1;
	m.rawData[14] = -2 * _fz * _nz / (_fz - _nz);
	m.rawData[15] = 0;
	return m;
}
math.Mat44.createTranslation = function(_x,_y,_z) {
	var m = new math.Mat44();
	m.rawData[12] = _x;
	m.rawData[13] = _y;
	m.rawData[14] = _z;
	return m;
}
math.Mat44.mult = function(_m1,_m2) {
	var r = new math.Mat44();
	r.rawData[0] = _m1.rawData[0] * _m2.rawData[0] + _m1.rawData[4] * _m2.rawData[1] + _m1.rawData[8] * _m2.rawData[2] + _m1.rawData[12] * _m2.rawData[3];
	r.rawData[1] = _m1.rawData[1] * _m2.rawData[0] + _m1.rawData[5] * _m2.rawData[1] + _m1.rawData[9] * _m2.rawData[2] + _m1.rawData[13] * _m2.rawData[3];
	r.rawData[2] = _m1.rawData[2] * _m2.rawData[0] + _m1.rawData[6] * _m2.rawData[1] + _m1.rawData[10] * _m2.rawData[2] + _m1.rawData[14] * _m2.rawData[3];
	r.rawData[3] = _m1.rawData[3] * _m2.rawData[0] + _m1.rawData[7] * _m2.rawData[1] + _m1.rawData[11] * _m2.rawData[2] + _m1.rawData[15] * _m2.rawData[3];
	r.rawData[4] = _m1.rawData[0] * _m2.rawData[4] + _m1.rawData[4] * _m2.rawData[5] + _m1.rawData[8] * _m2.rawData[6] + _m1.rawData[12] * _m2.rawData[7];
	r.rawData[5] = _m1.rawData[1] * _m2.rawData[4] + _m1.rawData[5] * _m2.rawData[5] + _m1.rawData[9] * _m2.rawData[6] + _m1.rawData[13] * _m2.rawData[7];
	r.rawData[6] = _m1.rawData[2] * _m2.rawData[4] + _m1.rawData[6] * _m2.rawData[5] + _m1.rawData[10] * _m2.rawData[6] + _m1.rawData[14] * _m2.rawData[7];
	r.rawData[7] = _m1.rawData[3] * _m2.rawData[4] + _m1.rawData[7] * _m2.rawData[5] + _m1.rawData[11] * _m2.rawData[6] + _m1.rawData[15] * _m2.rawData[7];
	r.rawData[8] = _m1.rawData[0] * _m2.rawData[8] + _m1.rawData[4] * _m2.rawData[9] + _m1.rawData[8] * _m2.rawData[10] + _m1.rawData[12] * _m2.rawData[11];
	r.rawData[9] = _m1.rawData[1] * _m2.rawData[8] + _m1.rawData[5] * _m2.rawData[9] + _m1.rawData[9] * _m2.rawData[10] + _m1.rawData[13] * _m2.rawData[11];
	r.rawData[10] = _m1.rawData[2] * _m2.rawData[8] + _m1.rawData[6] * _m2.rawData[9] + _m1.rawData[10] * _m2.rawData[10] + _m1.rawData[14] * _m2.rawData[11];
	r.rawData[11] = _m1.rawData[3] * _m2.rawData[8] + _m1.rawData[7] * _m2.rawData[9] + _m1.rawData[11] * _m2.rawData[10] + _m1.rawData[15] * _m2.rawData[11];
	r.rawData[12] = _m1.rawData[0] * _m2.rawData[12] + _m1.rawData[4] * _m2.rawData[13] + _m1.rawData[8] * _m2.rawData[14] + _m1.rawData[12] * _m2.rawData[15];
	r.rawData[13] = _m1.rawData[1] * _m2.rawData[12] + _m1.rawData[5] * _m2.rawData[13] + _m1.rawData[9] * _m2.rawData[14] + _m1.rawData[13] * _m2.rawData[15];
	r.rawData[14] = _m1.rawData[2] * _m2.rawData[12] + _m1.rawData[6] * _m2.rawData[13] + _m1.rawData[10] * _m2.rawData[14] + _m1.rawData[14] * _m2.rawData[15];
	r.rawData[15] = _m1.rawData[3] * _m2.rawData[12] + _m1.rawData[7] * _m2.rawData[13] + _m1.rawData[11] * _m2.rawData[14] + _m1.rawData[15] * _m2.rawData[15];
	return r;
}
math.Mat44.prototype = {
	inverted: function() {
		var m00 = this.rawData[0];
		var m01 = this.rawData[1];
		var m02 = this.rawData[2];
		var m03 = this.rawData[3];
		var m10 = this.rawData[4];
		var m11 = this.rawData[5];
		var m12 = this.rawData[6];
		var m13 = this.rawData[7];
		var m20 = this.rawData[8];
		var m21 = this.rawData[9];
		var m22 = this.rawData[10];
		var m23 = this.rawData[11];
		var m30 = this.rawData[12];
		var m31 = this.rawData[13];
		var m32 = this.rawData[14];
		var m33 = this.rawData[15];
		var v0 = m20 * m31 - m21 * m30;
		var v1 = m20 * m32 - m22 * m30;
		var v2 = m20 * m33 - m23 * m30;
		var v3 = m21 * m32 - m22 * m31;
		var v4 = m21 * m33 - m23 * m31;
		var v5 = m22 * m33 - m23 * m32;
		var t00 = v5 * m11 - v4 * m12 + v3 * m13;
		var t10 = -(v5 * m10 - v2 * m12 + v1 * m13);
		var t20 = v4 * m10 - v2 * m11 + v0 * m13;
		var t30 = -(v3 * m10 - v1 * m11 + v0 * m12);
		var invDet = 1 / (t00 * m00 + t10 * m01 + t20 * m02 + t30 * m03);
		var d00 = t00 * invDet;
		var d10 = t10 * invDet;
		var d20 = t20 * invDet;
		var d30 = t30 * invDet;
		var d01 = -(v5 * m01 - v4 * m02 + v3 * m03) * invDet;
		var d11 = (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
		var d21 = -(v4 * m00 - v2 * m01 + v0 * m03) * invDet;
		var d31 = (v3 * m00 - v1 * m01 + v0 * m02) * invDet;
		v0 = m10 * m31 - m11 * m30;
		v1 = m10 * m32 - m12 * m30;
		v2 = m10 * m33 - m13 * m30;
		v3 = m11 * m32 - m12 * m31;
		v4 = m11 * m33 - m13 * m31;
		v5 = m12 * m33 - m13 * m32;
		var d02 = (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
		var d12 = -(v5 * m00 - v2 * m02 + v1 * m03) * invDet;
		var d22 = (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
		var d32 = -(v3 * m00 - v1 * m01 + v0 * m02) * invDet;
		v0 = m21 * m10 - m20 * m11;
		v1 = m22 * m10 - m20 * m12;
		v2 = m23 * m10 - m20 * m13;
		v3 = m22 * m11 - m21 * m12;
		v4 = m23 * m11 - m21 * m13;
		v5 = m23 * m12 - m22 * m13;
		var d03 = -(v5 * m01 - v4 * m02 + v3 * m03) * invDet;
		var d13 = (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
		var d23 = -(v4 * m00 - v2 * m01 + v0 * m03) * invDet;
		var d33 = (v3 * m00 - v1 * m01 + v0 * m02) * invDet;
		var m = new math.Mat44();
		m.rawData[0] = d00;
		m.rawData[1] = d01;
		m.rawData[2] = d02;
		m.rawData[3] = d03;
		m.rawData[4] = d10;
		m.rawData[5] = d11;
		m.rawData[6] = d12;
		m.rawData[7] = d13;
		m.rawData[8] = d20;
		m.rawData[9] = d21;
		m.rawData[10] = d22;
		m.rawData[11] = d23;
		m.rawData[12] = d30;
		m.rawData[13] = d31;
		m.rawData[14] = d32;
		m.rawData[15] = d33;
		return m;
	}
	,determinant: function() {
		return (this.rawData[0] * this.rawData[5] - this.rawData[1] * this.rawData[4]) * (this.rawData[10] * this.rawData[15] - this.rawData[11] * this.rawData[14]) - (this.rawData[0] * this.rawData[6] - this.rawData[2] * this.rawData[4]) * (this.rawData[9] * this.rawData[15] - this.rawData[11] * this.rawData[13]) + (this.rawData[0] * this.rawData[7] - this.rawData[3] * this.rawData[4]) * (this.rawData[9] * this.rawData[14] - this.rawData[10] * this.rawData[13]) + (this.rawData[1] * this.rawData[6] - this.rawData[2] * this.rawData[5]) * (this.rawData[8] * this.rawData[15] - this.rawData[11] * this.rawData[12]) - (this.rawData[1] * this.rawData[7] - this.rawData[3] * this.rawData[5]) * (this.rawData[8] * this.rawData[14] - this.rawData[10] * this.rawData[12]) + (this.rawData[2] * this.rawData[7] - this.rawData[3] * this.rawData[6]) * (this.rawData[8] * this.rawData[13] - this.rawData[9] * this.rawData[12]);
	}
	,recompose: function(_o,_s,_t) {
		var rot = new math.Mat44();
		rot.setOrientation(_o);
		var scale = new math.Mat44();
		scale.rawData[0] = _s.x;
		scale.rawData[5] = _s.y;
		scale.rawData[10] = _s.z;
		this.rawData = math.Mat44.mult(rot,scale).rawData;
		this.rawData[12] = _t.x;
		this.rawData[13] = _t.y;
		this.rawData[14] = _t.z;
	}
	,getTranslation: function() {
		return math.Vec3.create(this.rawData[12],this.rawData[13],this.rawData[14]);
	}
	,setTranslation: function(_x,_y,_z) {
		this.rawData[12] = _x;
		this.rawData[13] = _y;
		this.rawData[14] = _z;
	}
	,appendTranslation: function(_x,_y,_z) {
		this.rawData[12] += _x;
		this.rawData[13] += _y;
		this.rawData[14] += _z;
	}
	,setScale: function(_x,_y,_z) {
		this.rawData[0] = _x;
		this.rawData[5] = _y;
		this.rawData[10] = _z;
	}
	,appendScale: function(_x,_y,_z) {
		this.rawData[0] *= _x;
		this.rawData[5] *= _y;
		this.rawData[10] *= _z;
	}
	,setOrientation: function(_q) {
		var Tx = 2 * _q.x;
		var Ty = 2 * _q.y;
		var Tz = 2 * _q.z;
		var Twx = Tx * _q.w;
		var Twy = Ty * _q.w;
		var Twz = Tz * _q.w;
		var Txx = Tx * _q.x;
		var Txy = Ty * _q.x;
		var Txz = Tz * _q.x;
		var Tyy = Ty * _q.y;
		var Tyz = Tz * _q.y;
		var Tzz = Tz * _q.z;
		this.rawData[0] = 1 - (Tyy + Tzz);
		this.rawData[1] = Txy - Twz;
		this.rawData[2] = Txz + Twy;
		this.rawData[4] = Txy + Twz;
		this.rawData[5] = 1 - (Txx + Tzz);
		this.rawData[6] = Tyz - Twx;
		this.rawData[8] = Txz - Twy;
		this.rawData[9] = Tyz + Twx;
		this.rawData[10] = 1 - (Txx + Tyy);
	}
	,transform: function(_v) {
		var d = 1 / (this.rawData[3] * _v.x + this.rawData[7] * _v.y + this.rawData[11] * _v.z + this.rawData[15]);
		var v = new math.Vec3();
		v.x = (_v.x * this.rawData[0] + _v.y * this.rawData[4] + _v.z * this.rawData[8] + this.rawData[12]) * d;
		v.y = (_v.x * this.rawData[1] + _v.y * this.rawData[5] + _v.z * this.rawData[9] + this.rawData[13]) * d;
		v.z = (_v.x * this.rawData[2] + _v.y * this.rawData[6] + _v.z * this.rawData[10] + this.rawData[14]) * d;
		return v;
	}
	,get: function(_i,_j) {
		return this.rawData[_i * 4 + _j];
	}
	,clone: function() {
		var m = new math.Mat44();
		m.rawData[0] = this.rawData[0];
		m.rawData[1] = this.rawData[1];
		m.rawData[2] = this.rawData[2];
		m.rawData[3] = this.rawData[3];
		m.rawData[4] = this.rawData[4];
		m.rawData[5] = this.rawData[5];
		m.rawData[6] = this.rawData[6];
		m.rawData[7] = this.rawData[7];
		m.rawData[8] = this.rawData[8];
		m.rawData[9] = this.rawData[9];
		m.rawData[10] = this.rawData[10];
		m.rawData[11] = this.rawData[11];
		m.rawData[12] = this.rawData[12];
		m.rawData[13] = this.rawData[13];
		m.rawData[14] = this.rawData[14];
		m.rawData[15] = this.rawData[15];
		return m;
	}
	,__class__: math.Mat44
}
math.MathUtils = function() { }
math.MathUtils.__name__ = true;
math.MathUtils.toScreen = function(_v,_width,_height) {
	var v = new math.Vec3();
	v.x = (_width - 1) * (_v.x + 1) * 0.5;
	v.y = _height - (_height - 1) * (_v.y + 1) * 0.5;
	v.z = _v.z;
	return v;
}
math.MathUtils.toScreenX = function(_x,_width) {
	return (_width - 1) * (_x + 1) * 0.5;
}
math.MathUtils.toScreenY = function(_y,_height) {
	return _height - (_height - 1) * (_y + 1) * 0.5;
}
math.MathUtils.getRelativeYaw = function(vDir,m) {
	var fFront = vDir.x * m.rawData[2] - vDir.y * m.rawData[6] - vDir.z * m.rawData[10];
	var fLeft = vDir.x * m.rawData[0] - vDir.y * m.rawData[4] - vDir.z * m.rawData[8];
	return Math.atan2(fLeft,fFront);
}
math.MathUtils.getRelativePitch = function(vDir,m) {
	var fFront = vDir.x * m.rawData[2] - vDir.y * m.rawData[6] - vDir.z * m.rawData[10];
	var fUp = -vDir.x * m.rawData[1] + vDir.y * m.rawData[5] + vDir.z * m.rawData[9];
	return Math.atan2(fUp,fFront);
}
math.MathUtils.getRelativeRoll = function(vDir,m) {
	var fLeft = vDir.x * m.rawData[0] - vDir.y * m.rawData[4] - vDir.z * m.rawData[8];
	var fUp = -vDir.x * m.rawData[1] + vDir.y * m.rawData[5] + vDir.z * m.rawData[9];
	return Math.atan2(fUp,fLeft);
}
math.MathUtils.polarToCartesian = function(_pol) {
	return math.Vec3.create(_pol.x * Math.sin(_pol.z + 1.5707963267948966) * Math.sin(_pol.y),_pol.x * Math.cos(_pol.z + 1.5707963267948966),_pol.x * Math.sin(_pol.z + 1.5707963267948966) * Math.cos(_pol.y));
}
math.MathUtils.cartesianToPolar = function(_cart) {
	return math.Vec3.create(Math.sqrt(_cart.x * _cart.x + _cart.y * _cart.y + _cart.z * _cart.z),Math.atan2(_cart.z,_cart.x),Math.acos(_cart.y / _cart.x) - 1.5707963267948966);
}
math.Quat = function() {
	this.x = 0;
	this.y = 0;
	this.z = 0;
	this.w = 1;
};
math.Quat.__name__ = true;
math.Quat.create = function(_x,_y,_z,_w) {
	var q = new math.Quat();
	q.x = _x;
	q.y = _y;
	q.z = _z;
	q.w = _w;
	return q;
}
math.Quat.createFromAxisAngle = function(_x,_y,_z,_angle) {
	var q = new math.Quat();
	var hAng = _angle * 0.0087266462599716478846184538424431;
	var fSin = Math.sin(hAng);
	q.x = _x * fSin;
	q.y = _y * fSin;
	q.z = _z * fSin;
	q.w = Math.cos(hAng);
	return q;
}
math.Quat.createFromEulers = function(_eulerX,_eulerY,_eulerZ) {
	var h = _eulerY * 0.0087266462599716478846184538424431;
	var a = _eulerZ * 0.0087266462599716478846184538424431;
	var b = _eulerX * 0.0087266462599716478846184538424431;
	var c1 = Math.cos(h);
	var s1 = Math.sin(h);
	var c2 = Math.cos(a);
	var s2 = Math.sin(a);
	var c3 = Math.cos(b);
	var s3 = Math.sin(b);
	var c1c2 = c1 * c2;
	var s1s2 = s1 * s2;
	var q = math.Quat.create(c1c2 * s3 + s1s2 * c3,s1 * c2 * c3 + c1 * s2 * s3,c1 * s2 * c3 - s1 * c2 * s3,c1c2 * c3 - s1s2 * s3);
	q.normalize();
	return q;
}
math.Quat.createFromMat44 = function(_mat) {
	var q = new math.Quat();
	var ftrace = _mat.rawData[0] + _mat.rawData[5] + _mat.rawData[10];
	var froot = 0;
	if(ftrace > 0.0) {
		froot = Math.sqrt(ftrace + 1.0);
		q.w = 0.5 * froot;
		froot = 0.5 / froot;
		q.x = (_mat.rawData[9] - _mat.rawData[6]) * froot;
		q.y = (_mat.rawData[2] - _mat.rawData[8]) * froot;
		q.z = (_mat.rawData[4] - _mat.rawData[1]) * froot;
	} else {
		var s_iNext = [1,2,0];
		var i = 0;
		if(_mat.rawData[5] > _mat.rawData[0]) i = 1;
		if(_mat.rawData[10] > _mat.rawData[i * 4 + i]) i = 2;
		var j = s_iNext[i];
		var k = s_iNext[j];
		froot = Math.sqrt(_mat.rawData[i * 4 + i] - _mat.rawData[j * 4 + j] - _mat.rawData[k * 4 + k] + 1.0);
		var apkQuat = [0.0,0.0,0.0];
		apkQuat[i] = 0.5 * froot;
		froot = 0.5 / froot;
		q.w = (_mat.rawData[k * 4 + j] - _mat.rawData[j * 4 + k]) * froot;
		apkQuat[j] = (_mat.rawData[j * 4 + i] + _mat.rawData[i * 4 + j]) * froot;
		apkQuat[k] = (_mat.rawData[k * 4 + i] + _mat.rawData[i * 4 + k]) * froot;
		q.x = apkQuat[0];
		q.y = apkQuat[1];
		q.z = apkQuat[2];
	}
	return q;
}
math.Quat.mult = function(_q0,_q1) {
	var q = new math.Quat();
	q.x = _q0.y * _q1.z - _q0.z * _q1.y + _q1.x * _q0.w + _q0.x * _q1.w;
	q.y = _q0.z * _q1.x - _q0.x * _q1.z + _q1.y * _q0.w + _q0.y * _q1.w;
	q.z = _q0.x * _q1.y - _q0.y * _q1.x + _q1.z * _q0.w + _q0.z * _q1.w;
	q.w = _q0.w * _q1.w - (_q0.x * _q1.x + _q0.y * _q1.y + _q0.z * _q1.z);
	return q;
}
math.Quat.add = function(_q0,_q1) {
	var q = new math.Quat();
	q.x = _q0.x + _q1.x;
	q.y = _q0.y + _q1.y;
	q.z = _q0.z + _q1.z;
	q.w = _q0.w + _q1.w;
	return q;
}
math.Quat.subtract = function(_q0,_q1) {
	var q = new math.Quat();
	q.x = _q0.x - _q1.x;
	q.y = _q0.y - _q1.y;
	q.z = _q0.z - _q1.z;
	q.w = _q0.w - _q1.w;
	return q;
}
math.Quat.dot = function(_v0,_v1) {
	return _v0.x * _v1.x + _v0.y * _v1.y + _v0.z * _v1.z + _v0.w * _v1.w;
}
math.Quat.slerp = function(_q0,_q1,_t) {
	var res = math.Quat.create(_q1.x,_q1.y,_q1.z,_q1.w);
	var cTheta = _q0.x * _q1.x + _q0.y * _q1.y + _q0.z * _q1.z + _q0.w * _q1.w;
	if(cTheta < 0) {
		cTheta = -cTheta;
		res.x = -_q1.x;
		res.y = -_q1.y;
		res.z = -_q1.z;
		res.w = -_q1.w;
	}
	var scale0 = 1 - _t;
	var scale1 = _t;
	if(1 - cTheta > 0.001) {
		var theta = Math.acos(cTheta);
		var sinTheta = Math.sin(theta);
		scale0 = Math.sin((1 - _t) * theta / sinTheta);
		scale1 = Math.sin(_t * theta / sinTheta);
	}
	return math.Quat.create(_q0.x * scale0 + res.x * scale1,_q0.y * scale0 + res.y * scale1,_q0.z * scale0 + res.z * scale1,_q0.w * scale0 + res.w * scale1);
}
math.Quat.nlerp = function(_q0,_q1,_t) {
	var res = null;
	var cTheta = _q0.x * _q1.x + _q0.y * _q1.y + _q0.z * _q1.z + _q0.w * _q1.w;
	if(cTheta < 0) res = math.Quat.create(_q0.x + (-_q1.x - _q0.x) * _t,_q0.y + (-_q1.y - _q0.y) * _t,_q0.z + (-_q1.z - _q0.z) * _t,_q0.w + (-_q1.w - _q0.w) * _t); else res = math.Quat.create(_q0.x + (_q1.x - _q0.x) * _t,_q0.y + (_q1.y - _q0.y) * _t,_q0.z + (_q1.z - _q0.z) * _t,_q0.w + (_q1.w - _q0.w) * _t);
	var inv = 1.0 / (res.x * res.x + res.y * res.y + res.z * res.z + res.w * res.w);
	res.x *= inv;
	res.y *= inv;
	res.z *= inv;
	res.w *= inv;
	return res;
}
math.Quat.rotateX = function(_a) {
	var a = _a * 0.0087266462599716478846184538424431;
	var q = new math.Quat();
	q.x = Math.sin(a);
	q.y = q.z = 0;
	q.w = Math.cos(a);
	return q;
}
math.Quat.rotateY = function(_a) {
	var a = _a * 0.0087266462599716478846184538424431;
	var q = new math.Quat();
	q.y = Math.sin(a);
	q.x = q.z = 0;
	q.w = Math.cos(a);
	return q;
}
math.Quat.rotateZ = function(_a) {
	var a = _a * 0.0087266462599716478846184538424431;
	var q = new math.Quat();
	q.z = Math.sin(a);
	q.x = q.y = 0;
	q.w = Math.cos(a);
	return q;
}
math.Quat.prototype = {
	getRoll: function(_reprojectAxis) {
		var res = 0;
		if(_reprojectAxis) {
			var fTx = 2.0 * this.x;
			var fTy = 2.0 * this.y;
			var fTz = 2.0 * this.z;
			var fTwz = fTz * this.w;
			var fTxy = fTy * this.x;
			var fTyy = fTy * this.y;
			var fTzz = fTz * this.z;
			res = Math.atan2(fTxy + fTwz,1.0 - (fTyy + fTzz));
		} else res = Math.atan2(2 * (this.x * this.y + this.w * this.z),this.w * this.w + this.x * this.x - this.y * this.y - this.z * this.z);
		return res;
	}
	,getYaw: function(_reprojectAxis) {
		var res = 0;
		if(_reprojectAxis) {
			var fTx = 2.0 * this.x;
			var fTy = 2.0 * this.y;
			var fTz = 2.0 * this.z;
			var fTwy = fTy * this.w;
			var fTxx = fTx * this.x;
			var fTxz = fTz * this.x;
			var fTyy = fTy * this.y;
			res = Math.atan2(fTxz + fTwy,1.0 - (fTxx + fTyy));
		} else res = Math.asin(-2 * (this.x * this.z - this.w * this.y));
		return res;
	}
	,getPitch: function(_reprojectAxis) {
		var res = 0;
		if(_reprojectAxis) {
			var fTx = 2.0 * this.x;
			var fTy = 2.0 * this.y;
			var fTz = 2.0 * this.z;
			var fTwx = fTx * this.w;
			var fTxx = fTx * this.x;
			var fTyz = fTz * this.y;
			var fTzz = fTz * this.z;
			res = Math.atan2(fTyz + fTwx,1.0 - (fTxx + fTzz));
		} else res = Math.atan2(2 * (this.y * this.z + this.w * this.x),this.w * this.w - this.x * this.x - this.y * this.y + this.z * this.z);
		return res;
	}
	,transform: function(_v) {
		var qvec = new math.Vec3();
		qvec.x = this.x;
		qvec.y = this.y;
		qvec.z = this.z;
		var uv = math.Vec3.mult(qvec,_v);
		var uuv = math.Vec3.mult(qvec,uv);
		uv = math.Vec3.mult_scalar(uv,2 * this.w);
		uuv = math.Vec3.mult_scalar(uuv,2);
		return math.Vec3.add(_v,math.Vec3.add(uv,uuv));
	}
	,inverted: function() {
		var q = null;
		var norm = this.w * this.w + this.x * this.x + this.y * this.y + this.z * this.z;
		if(norm > 0.0) {
			var invNorm = 1.0 / norm;
			q = math.Quat.create(-this.x * invNorm,-this.y * invNorm,-this.z * invNorm,this.w * invNorm);
		}
		return q;
	}
	,clone: function() {
		return math.Quat.create(this.x,this.y,this.z,this.w);
	}
	,normalize: function() {
		var len = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
		this.x /= len;
		this.y /= len;
		this.z /= len;
		this.w /= len;
		return len;
	}
	,__class__: math.Quat
}
math.Vec3 = function() {
	this.x = 0;
	this.y = 0;
	this.z = 0;
};
math.Vec3.__name__ = true;
math.Vec3.create = function(_x,_y,_z) {
	var v = new math.Vec3();
	v.x = _x;
	v.y = _y;
	v.z = _z;
	return v;
}
math.Vec3.mult = function(_v0,_v1) {
	var v = new math.Vec3();
	v.x = _v0.y * _v1.z - _v0.z * _v1.y;
	v.y = _v0.z * _v1.x - _v0.x * _v1.z;
	v.z = _v0.x * _v1.y - _v0.y * _v1.x;
	return v;
}
math.Vec3.mult_scalar = function(_v0,_s) {
	var v = new math.Vec3();
	v.x = _v0.x * _s;
	v.y = _v0.y * _s;
	v.z = _v0.z * _s;
	return v;
}
math.Vec3.mult_scalarVect = function(_v0,_v1) {
	var v = new math.Vec3();
	v.x = _v0.x * _v1.x;
	v.y = _v0.y * _v1.y;
	v.z = _v0.z * _v1.z;
	return v;
}
math.Vec3.dot = function(_v0,_v1) {
	return _v0.x * _v1.x + _v0.y * _v1.y + _v0.z * _v1.z;
}
math.Vec3.add = function(_v0,_v1) {
	var v = new math.Vec3();
	v.x = _v0.x + _v1.x;
	v.y = _v0.y + _v1.y;
	v.z = _v0.z + _v1.z;
	return v;
}
math.Vec3.subtract = function(_v0,_v1) {
	var v = new math.Vec3();
	v.x = _v0.x - _v1.x;
	v.y = _v0.y - _v1.y;
	v.z = _v0.z - _v1.z;
	return v;
}
math.Vec3.equals = function(_v0,_v1) {
	return _v0.x == _v1.x && _v0.y == _v1.y && _v0.z == _v1.z;
}
math.Vec3.equals2 = function(_v0,_v1,_tol) {
	return Math.abs(_v0.x - _v1.x) < _tol && Math.abs(_v0.y - _v1.y) < _tol && Math.abs(_v0.z - _v1.z) < _tol;
}
math.Vec3.lerp = function(_v0,_v1,_t) {
	return math.Vec3.create(_v0.x + (_v1.x - _v0.x) * _t,_v0.y + (_v1.y - _v0.y) * _t,_v0.z + (_v1.z - _v0.z) * _t);
}
math.Vec3.prototype = {
	set: function(_x,_y,_z) {
		this.x = _x;
		this.y = _y;
		this.z = _z;
	}
	,lengthSquared: function() {
		return this.x * this.x + this.y * this.y + this.z * this.z;
	}
	,length: function() {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
	}
	,normalize: function() {
		var len = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
		this.x /= len;
		this.y /= len;
		this.z /= len;
		return len;
	}
	,clone: function() {
		return math.Vec3.create(this.x,this.y,this.z);
	}
	,__class__: math.Vec3
}
Math.__name__ = ["Math"];
Math.NaN = Number.NaN;
Math.NEGATIVE_INFINITY = Number.NEGATIVE_INFINITY;
Math.POSITIVE_INFINITY = Number.POSITIVE_INFINITY;
Math.isFinite = function(i) {
	return isFinite(i);
};
Math.isNaN = function(i) {
	return isNaN(i);
};
String.prototype.__class__ = String;
String.__name__ = true;
Array.prototype.__class__ = Array;
Array.__name__ = true;
Date.prototype.__class__ = Date;
Date.__name__ = ["Date"];
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
Sample.quadVerts = [-0.5,0.5,0,0.5,-0.5,0,0.5,0.5,0,-0.5,-0.5,0];
Sample.quadIndices = [0,1,2,0,3,1];
Sample.vsSrc = "\r\n        attribute vec3 vPos;\r\n\r\n        uniform mat4 viewProjMat;\r\n        uniform mat4 worldMat;\r\n\r\n        void main() {\r\n            gl_Position = (viewProjMat * (worldMat * vec4(vPos, 1.0) ));\r\n        }";
Sample.fsSrc = "\r\n        #ifdef GL_ES\r\n        precision highp float;\r\n        #endif        \r\n        \r\n        uniform vec4 uColor;\r\n        \r\n        void main() {\r\n            gl_FragColor = uColor;\r\n        }";
foo3D.RDIBufferUsage.STATIC = 35044;
foo3D.RDIBufferUsage.DYNAMIC = 35048;
foo3D.RDIBufferType.VERTEX = 34962;
foo3D.RDIBufferType.INDEX = 34963;
foo3D.RDITextureTypes.TEX2D = 3553;
foo3D.RDITextureTypes.TEXCUBE = 34067;
foo3D.RDITextureFormats.RGBA8 = 32856;
foo3D.RDITextureFormats.RGBA16F = 34842;
foo3D.RDITextureFormats.RGBA32F = 34836;
foo3D.RDITextureFormats.DEPTH = 33190;
foo3D.RDIShaderConstType.FLOAT = 5126;
foo3D.RDIShaderConstType.FLOAT2 = 35664;
foo3D.RDIShaderConstType.FLOAT3 = 35665;
foo3D.RDIShaderConstType.FLOAT4 = 35666;
foo3D.RDIShaderConstType.FLOAT44 = 35675;
foo3D.RDIShaderConstType.FLOAT33 = 35676;
foo3D.RDIShaderConstType.SAMPLER_2D = 35678;
foo3D.RDIShaderConstType.SAMPLER_CUBE = 35680;
foo3D.RDISamplerState.FILTER_BILINEAR = 0;
foo3D.RDISamplerState.FILTER_TRILINEAR = 1;
foo3D.RDISamplerState.FILTER_POINT = 2;
foo3D.RDISamplerState.ADDRU_CLAMP = 0;
foo3D.RDISamplerState.ADDRU_WRAP = 64;
foo3D.RDISamplerState.ADDRU_MIRRORED_REPEAT = 128;
foo3D.RDISamplerState.ADDRV_CLAMP = 0;
foo3D.RDISamplerState.ADDRV_WRAP = 256;
foo3D.RDISamplerState.ADDRV_MIRRORED_REPEAT = 512;
foo3D.RDISamplerState.ADDR_CLAMP = 0;
foo3D.RDISamplerState.ADDR_WRAP = 320;
foo3D.RDISamplerState.ADDR_MIRRORED_REPEAT = 640;
foo3D.RDIBlendFactors.ZERO = 0;
foo3D.RDIBlendFactors.ONE = 1;
foo3D.RDIBlendFactors.SRC_COLOR = 768;
foo3D.RDIBlendFactors.ONE_MINUS_SRC_COLOR = 769;
foo3D.RDIBlendFactors.SRC_ALPHA = 770;
foo3D.RDIBlendFactors.ONE_MINUS_SRC_ALPHA = 771;
foo3D.RDIBlendFactors.DST_ALPHA = 772;
foo3D.RDIBlendFactors.ONE_MINUS_DST_ALPHA = 773;
foo3D.RDIBlendFactors.DST_COLOR = 774;
foo3D.RDIBlendFactors.ONE_MINUS_DST_COLOR = 775;
foo3D.RDITestModes.DISABLE = 0;
foo3D.RDITestModes.NEVER = 512;
foo3D.RDITestModes.LESS = 513;
foo3D.RDITestModes.EQUAL = 514;
foo3D.RDITestModes.LEQUAL = 515;
foo3D.RDITestModes.GREATER = 516;
foo3D.RDITestModes.NOTEQUAL = 517;
foo3D.RDITestModes.GEQUAL = 518;
foo3D.RDITestModes.ALWAYS = 519;
foo3D.RDICullModes.FRONT = 1028;
foo3D.RDICullModes.BACK = 1029;
foo3D.RDICullModes.FRONT_AND_BACK = 1032;
foo3D.RDICullModes.NONE = 0;
foo3D.RDIClearFlags.COLOR = 1;
foo3D.RDIClearFlags.DEPTH = 2;
foo3D.RDIClearFlags.ALL = -1;
foo3D.RDIPrimType.TRIANGLES = 4;
foo3D.RDIPrimType.TRISTRIP = 5;
foo3D.AbstractRenderDevice.SS_FILTER_START = 0;
foo3D.AbstractRenderDevice.SS_FILTER_MASK = 3;
foo3D.AbstractRenderDevice.SS_ADDRU_START = 6;
foo3D.AbstractRenderDevice.SS_ADDRU_MASK = 192;
foo3D.AbstractRenderDevice.SS_ADDRV_START = 8;
foo3D.AbstractRenderDevice.SS_ADDRV_MASK = 768;
foo3D.AbstractRenderDevice.SS_ADDR_START = 6;
foo3D.AbstractRenderDevice.SS_ADDR_MASK = 960;
foo3D.AbstractRenderDevice.PM_VIEWPORT = 1;
foo3D.AbstractRenderDevice.PM_INDEXBUF = 2;
foo3D.AbstractRenderDevice.PM_VERTLAYOUT = 4;
foo3D.AbstractRenderDevice.PM_TEXTURES = 8;
foo3D.AbstractRenderDevice.PM_SCISSOR = 16;
foo3D.AbstractRenderDevice.PM_BLEND = 32;
foo3D.AbstractRenderDevice.PM_CULLMODE = 64;
foo3D.AbstractRenderDevice.PM_DEPTH_TEST = 128;
foo3D.impl.WebGLRenderDevice.magFilters = [9729,9729,9728];
foo3D.impl.WebGLRenderDevice.minFiltersMips = [9985,9987,9984];
foo3D.impl.WebGLRenderDevice.wrapModes = [33071,10497,33648];
foo3D.utils.Frame.time = haxe.Timer.stamp();
foo3D.utils.Frame.onCtxCreated = new foo3D.utils.Signal();
foo3D.utils.Frame.onCtxLost = new foo3D.utils.Signal();
foo3D.utils.Frame.onCtxUpdate = new foo3D.utils.Signal();
foo3D.utils.Frame.onCtxReshape = new foo3D.utils.Signal();
js.Browser.window = typeof window != "undefined" ? window : null;
js.Browser.document = typeof window != "undefined" ? window.document : null;
math.MathUtils.DEG2RAD = 0.017453292519943295769236907684886;
math.MathUtils.HALF_DEG2RAD = 0.0087266462599716478846184538424431;
math.MathUtils.RAD2DEG = 57.295779513082320876798154814105;
math.MathUtils.PIHALF = 1.5707963267948966;
math.Vec3.LEFT = math.Vec3.create(1,0,0);
math.Vec3.UP = math.Vec3.create(0,1,0);
math.Vec3.FORWARD = math.Vec3.create(0,0,1);
Sample.main();
})();
