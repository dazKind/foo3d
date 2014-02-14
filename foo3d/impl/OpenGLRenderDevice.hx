package foo3d.impl;

import foo3d.RenderDevice;

class OpenGLRenderDevice extends AbstractRenderDevice {

	inline public static var UNSIGNED_BYTE:Int = 0x1401;
	inline public static var FLOAT:Int = 0x1406;
	inline public static var RGBA:Int = 0x1908;
	inline public static var CULL_FACE:Int = 0x0B44;
	inline public static var DEPTH_TEST:Int = 0x0B71;
	inline public static var BLEND:Int = 0x0BE2;
	inline public static var LINEAR:Int = 0x2601;
	inline public static var NEAREST:Int = 0x2600;
	inline public static var CLAMP_TO_EDGE:Int = 0x812F;
	inline public static var REPEAT:Int = 0x2901;
	inline public static var MIRRORED_REPEAT:Int = 0x8370;
	inline public static var LINEAR_MIPMAP_NEAREST:Int = 0x2701;
	inline public static var LINEAR_MIPMAP_LINEAR:Int = 0x2703;
	inline public static var NEAREST_MIPMAP_NEAREST:Int = 0x2700;
	inline public static var TEXTURE_MIN_FILTER:Int = 0x2801;
	inline public static var TEXTURE_MAG_FILTER:Int = 0x2800;
	inline public static var TEXTURE_WRAP_S:Int = 0x2802;
	inline public static var TEXTURE_WRAP_T:Int = 0x2803;
	inline public static var TEXTURE0:Int = 0x84C0;
	inline public static var TEXTURE_CUBE_MAP_POSITIVE_X:Int = 0x8515;
	inline public static var DEPTH_BUFFER_BIT:Int = 0x00000100;
	inline public static var COLOR_BUFFER_BIT:Int = 0x00004000;
	inline public static var STENCIL_BUFFER_BIT:Int = 0x00000400;
	inline public static var DEPTH_COMPONENT:Int = 0x1902;
	inline public static var VERTEX_SHADER:Int = 0x8B31;
	inline public static var FRAGMENT_SHADER:Int = 0x8B30;
	inline public static var COMPILE_STATUS:Int = 0x8B81;
	inline public static var LINK_STATUS:Int = 0x8B82;
	inline public static var ACTIVE_ATTRIBUTES:Int = 0x8B89;
	inline public static var ACTIVE_UNIFORMS:Int = 0x8B86;
	inline public static var MAX_SAMPLES:Int = 0x8D57;
    inline public static var COLOR_ATTACHMENT0:Int = 0x8CE0;
    inline public static var DEPTH_ATTACHMENT:Int = 0x8D00;
    inline public static var NONE:Int = 0;
	inline public static var TEXTURE_COMPARE_MODE:Int = 0x884C;
    inline public static var FRAMEBUFFER:Int = 0x8D40;
    inline public static var RENDERBUFFER:Int = 0x8D41;
    inline public static var DRAW_FRAMEBUFFER:Int = 0x8CA9;
    inline public static var READ_FRAMEBUFFER:Int = 0x8CA8;
    inline public static var FRAMEBUFFER_UNSUPPORTED:Int = 0x8CDD;
    inline public static var FRAMEBUFFER_INCOMPLETE_ATTACHMENT:Int = 0x8CD6;
    inline public static var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:Int = 0x8CD7;
    inline public static var FRAMEBUFFER_COMPLETE:Int = 0x8CD5;
    inline public static var MULTISAMPLE:Int = 0x809D;

	
	public function new(_ctx:RenderContext)
    {
        super(_ctx);
    }

    override function init():Void
    {
        #if !HXCPP_FLOAT32
            throw "[Foo3D - ERROR] - Using Doubles! Foo3d only supports 32bit Floats! Compile your project with -DHXCPP_FLOAT32!";
        #end

        hx_rd_init(m_caps);

        trace(m_caps.toString());

        resetStates();
    }

	override public function createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = -1):Int { 

		var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.VERTEX, 
            hx_gl_createBuffer(), 
            _size, 
            _usageHint);

        hx_gl_bindBuffer(buf.type, buf.glObj);
        hx_gl_bufferData(buf.type, buf.size, _data.getData(), _usageHint);
        hx_gl_bindBuffer(buf.type, null);
        
        m_bufferMem += buf.size;
        return m_buffers.add( buf );
	}

	 override public function createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int 
    {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.INDEX, 
            hx_gl_createBuffer(), 
            _size, 
            _usageHint);
        
        hx_gl_bindBuffer(buf.type, buf.glObj);
        hx_gl_bufferData(buf.type, buf.size, _data.getData(), _usageHint);
        hx_gl_bindBuffer(buf.type, null);
        
        m_bufferMem += buf.size;
        return m_buffers.add( buf );
    }

    override public function destroyBuffer(_handle:Int):Void
    {
        if (_handle == 0) return;
        
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        hx_gl_deleteBuffer(buf.glObj);
        
        m_bufferMem -= buf.size;
        m_buffers.remove(_handle);
    }

    override public function updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        hx_gl_bindBuffer(buf.type, buf.glObj);
        hx_gl_bufferSubData(buf.type, _offset, _size, _data.getData());
        hx_gl_bindBuffer(buf.type, null);
    }
    
    override public function updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        hx_gl_bindBuffer(buf.type, buf.glObj);
        hx_gl_bufferSubData(buf.type, _offset, _size, _data.getData());        
        
        if(m_curIndexBuf != 0) // rebind the old one
            hx_gl_bindBuffer(buf.type, m_buffers.getRef(m_curIndexBuf).glObj);
        else
            hx_gl_bindBuffer(buf.type, null);
    }

    override public function createTexture(_type:Int, _width:Int, _height:Int, _format:Int, _hasMips:Bool, _genMips:Bool, ?_hintIsRenderTarget=false):Int { 
    	
    	if (!m_caps.texNPOTSupport) {
    		if( (_width & (_width-1)) != 0 || (_height & (_height-1)) != 0 )
    			trace("[Foo3D - WARNING] - Texture has non-power-of-two dimensions! GPU has no support for that!");
    	}

    	var tex = new RDITexture();
        tex.type = _type;
        tex.format = _format;
        tex.width = _width;
        tex.height = _height;
        tex.genMips = _genMips;
        tex.hasMips = _hasMips;
        tex.glFmt = _format;

        tex.glObj = hx_gl_createTexture();
        hx_gl_activeTexture(TEXTURE0+m_lastTexUnit);
        hx_gl_bindTexture(_type, tex.glObj);

        tex.samplerState = 0;
        applySamplerState(tex);

        hx_gl_bindTexture(_type, null);
        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
            hx_gl_bindTexture(t.type, t.glObj);
        }
        
        tex.memSize = calcTextureSize(tex.format, _width, _height);
        if (_hasMips || _genMips) 
            tex.memSize += Std.int(tex.memSize * 1.0 / 3.0);
        if (_type == RDITextureTypes.TEXCUBE)
            tex.memSize *= 6;

        m_textureMem += tex.memSize;

        return m_textures.add( tex );
    }

    override public function uploadTextureData(_handle:Int, _slice:Int, _mipLevel:Int, _pixels:PixelData):Void
    {
        var tex:RDITexture = m_textures.getRef(_handle);

        hx_gl_activeTexture(TEXTURE0+m_lastTexUnit);
        hx_gl_bindTexture(tex.type, tex.glObj);

        var inputFormat:Int = RGBA;
        var inputType:Int = UNSIGNED_BYTE;

        switch (tex.format)
        {
            case RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F:
                inputFormat = RGBA;
                inputType = FLOAT;
            case RDITextureFormats.DEPTH:
                inputFormat = DEPTH_COMPONENT;
                inputType = FLOAT;
        }

        // Calculate size of next mipmap using "floor" convention
        var width:Int = Std.int(Math.max(tex.width >> _mipLevel, 1));
        var height:Int = Std.int(Math.max(tex.height >> _mipLevel, 1));

        var target:Int = (tex.type == RDITextureTypes.TEX2D) ? 
            RDITextureTypes.TEX2D : (TEXTURE_CUBE_MAP_POSITIVE_X + _slice);

        if (_pixels == null) // we wanna upload an empty buffer
            hx_gl_texImage2D(target, _mipLevel, tex.glFmt, width, height, 0, inputFormat, inputType, null);
        else
            hx_gl_texImage2D(target, _mipLevel, tex.glFmt, width, height, 0, inputFormat, inputType, _pixels);

        // Note: for cube maps mips are only generated when the side with the highest index is uploaded
        if (tex.genMips && (tex.type != RDITextureTypes.TEXCUBE || _slice == 5))
        {
            hx_gl_generateMipmap(tex.type);
        }

        hx_gl_bindTexture(tex.type, null);

        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
           hx_gl_bindTexture(t.type, t.glObj);
        }
    }

    override public function destroyTexture(_handle:Int):Void 
    {
        if (_handle == 0) return;
        
        var tex:RDITexture = m_textures.getRef(_handle);
        hx_gl_deleteTexture(tex.glObj);
        
        m_textureMem -= tex.memSize;
        m_textures.remove(_handle);
    }

    override public function createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int
    {
        // create shaders
        var vs:Int = hx_gl_createShader(VERTEX_SHADER);
        hx_gl_shaderSource(vs, _vertexShaderSrc);
        hx_gl_compileShader(vs);
        var success:Bool = hx_gl_getShaderiv(vs, COMPILE_STATUS) == 1;
        if (!success)
        {
            trace("[Foo3D - Error] - Vertex Shader: " + hx_gl_getShaderInfoLog(vs));
            hx_gl_deleteShader(vs);
            return 0;
        }

        var fs:Int = hx_gl_createShader(FRAGMENT_SHADER);
        hx_gl_shaderSource(fs, _fragmentShaderSrc);
        hx_gl_compileShader(fs);
        var success:Bool = hx_gl_getShaderiv(fs, COMPILE_STATUS) == 1;
        if (!success)
        {
            trace("[Foo3D - Error] - Fragment Shader: " + hx_gl_getShaderInfoLog(fs));
            hx_gl_deleteShader(vs);
            hx_gl_deleteShader(fs);
            return 0;
        }

        // create program
        var prog:Int = hx_gl_createProgram();
        hx_gl_attachShader(prog, vs);
        hx_gl_attachShader(prog, fs);
        hx_gl_deleteShader(vs);
        hx_gl_deleteShader(fs);

        // link program
        hx_gl_linkProgram(prog);
        success = hx_gl_getProgramiv(prog, LINK_STATUS) == 1;
        if (!success)
        {
            trace("[Foo3D - Error] - Linking: " + hx_gl_getProgramInfoLog(prog));
            hx_gl_deleteProgram(prog);
            return 0;
        }

        var shader:RDIShaderProgram = new RDIShaderProgram();
        shader.oglProgramObj = prog;
        var attribCount:Int = hx_gl_getProgramiv(prog, ACTIVE_ATTRIBUTES);

        for (i in 0...m_numVertexLayouts)
        {
            var vl:RDIVertexLayout = m_vertexLayouts[i];
            var allAttribsFound:Bool = true;

            for (j in 0...16)
                shader.inputLayouts[i].attribIndices[j] = -1;

            for (j in 0...attribCount)
            {

                var info:RDIUniformInfo = new RDIUniformInfo();
                hx_gl_getActiveAttrib(prog, j, info);

                var attribFound:Bool = false;
                for (k in 0...vl.numAttribs)
                {
                    if (vl.attribs[k].semanticName == info.name)
                    {
                        shader.inputLayouts[i].attribIndices[k] = hx_gl_getAttribLocation(prog, info.name);
                        attribFound = true;
                    }
                }
                if (!attribFound)
                {
                    allAttribsFound = false;
                    break;
                }
            }

            shader.inputLayouts[i].valid = allAttribsFound;
        }

        return m_shaders.add(shader);
    }

    override public function destroyProgram(_handle:Int):Void 
    {
        if (_handle == 0) return;

        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        hx_gl_deleteProgram(shader.oglProgramObj);
        m_shaders.remove(_handle);
    }

    override public function bindProgram(_handle:Int):Void
    {
        if (_handle != 0)
        {
            var shader:RDIShaderProgram = m_shaders.getRef(_handle);
            hx_gl_useProgram(shader.oglProgramObj);
        }
        else
            hx_gl_useProgram(null);

        m_curShaderId = _handle;
        m_pendingMask |= ARD.PM_VERTLAYOUT;
    }

    override public function getActiveUniformCount(_handle:Int):Int 
    { 
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return hx_gl_getProgramiv(shader.oglProgramObj, ACTIVE_UNIFORMS);
    }

    override public function getActiveUniformInfo(_handle:Int, _index:Int):RDIUniformInfo 
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        var info:RDIUniformInfo = new RDIUniformInfo();
        hx_gl_getActiveUniform(shader.oglProgramObj, _index, info);
        return info;
    }

    override public function getUniformLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return hx_gl_getUniformLocation(shader.oglProgramObj, _name);
    }

    override public function getSamplerLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return hx_gl_getUniformLocation(shader.oglProgramObj, _name);
    }

    override public function setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void 
    { 
        switch (_type)
        {
            case RDIShaderConstType.FLOAT: hx_gl_uniform1fv(_loc, _values);
            case RDIShaderConstType.FLOAT2: hx_gl_uniform2fv(_loc, _values);
            case RDIShaderConstType.FLOAT3: hx_gl_uniform3fv(_loc, _values);
            case RDIShaderConstType.FLOAT4: hx_gl_uniform4fv(_loc, _values);
            case RDIShaderConstType.FLOAT33: hx_gl_uniformMatrix3fv(_loc, false, _values);
            case RDIShaderConstType.FLOAT44: hx_gl_uniformMatrix4fv(_loc, false, _values);
        }
    }

    override public function setSampler(_loc:UniformLocationType, _texUnit:Int):Void 
    {
        hx_gl_uniform1i( _loc, _texUnit );
    }

    override public function createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int 
    { 
		if ((_format == RDITextureFormats.RGBA16F || _format == RDITextureFormats.RGBA32F) && !m_caps.texFloatSupport)
            return 0;

        if (_numColBufs > m_caps.maxColorAttachments)
        	return 0;

        var maxSamples = 0;
        if (m_caps.rtMultisampling)
        	maxSamples = hx_gl_getIntegerv(MAX_SAMPLES);
        if (_samples > maxSamples) {
        	_samples = maxSamples;
        	trace("[Foo3D - WARNING] - GPU doesnt support desired multisampling quality for rendertarget!");
        }
        
        var rb:RDIRenderBuffer = new RDIRenderBuffer(_numColBufs);
        rb.width = _width;
        rb.height = _height;
        rb.samples = _samples;

        rb.fbo = hx_gl_genFramebuffer();
        if (_samples > 0)
            rb.fboMS = hx_gl_genFramebuffer();

        // Attach color buffers
        if (_numColBufs > 0) {
            for(j in 0..._numColBufs) {

                hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fbo);
                // create the color texture
                var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, _format, false, false, true);
                this.uploadTextureData(texObj, 0, 0, null);
                rb.colTexs[j] = texObj;
                var tex:RDITexture = m_textures.getRef(texObj);
                // attach to framebuffer
                hx_gl_framebufferTexture2D(COLOR_ATTACHMENT0+j, tex.glObj);

                if (_samples > 0) {
                    hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fboMS);
                    rb.colBufs[j] = hx_gl_genRenderbuffer();
                    hx_gl_bindRenderbuffer(RENDERBUFFER, rb.colBufs[j]);
                    hx_gl_renderbufferStorageMultisample(rb.samples, tex.glFmt, rb.width, rb.height);
                    hx_gl_framebufferRenderbuffer(COLOR_ATTACHMENT0+j, rb.colBufs[j]); 
                }
            }

            hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fbo);
            hx_gl_drawBuffers(_numColBufs);

            if (_samples > 0) {
                hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fboMS);
                hx_gl_drawBuffers(_numColBufs);
            }
        } else {
            hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fbo);
            hx_gl_drawBuffer(NONE);
            hx_gl_readBuffer(NONE);

            if (_samples > 0) {
                hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fboMS);
                hx_gl_drawBuffer(NONE);
                hx_gl_readBuffer(NONE);                
            }
        }

        // attach depth buffer
        if (_depth)
        {
            hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fbo);
            var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, RDITextureFormats.DEPTH, false, false, true);
            hx_gl_texParameteri(RDITextureTypes.TEX2D, TEXTURE_COMPARE_MODE, NONE);
            this.uploadTextureData(texObj, 0, 0, null);
            rb.depthTex = texObj;
            var tex:RDITexture = m_textures.getRef(texObj);
            hx_gl_framebufferTexture2D(DEPTH_ATTACHMENT, tex.glObj);

            if (_samples > 0) {
                hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fboMS);
                rb.depthBufObj = hx_gl_genRenderbuffer();
                hx_gl_bindRenderbuffer(RENDERBUFFER, rb.depthBufObj);
                hx_gl_renderbufferStorageMultisample(rb.samples, RDITextureFormats.DEPTH, rb.width, rb.height);
                hx_gl_framebufferRenderbuffer(DEPTH_ATTACHMENT, rb.depthBufObj);
            }
        }

        var rbObj:Int = m_renBuffers.add(rb);

        // validate fbo
        var valid:Bool = true;
        var status = _validateRenderbuffer(rb.fbo);

        if (status != FRAMEBUFFER_COMPLETE)
            valid = false;

        // check multisample fbo
        if (_samples > 0) {
            status = _validateRenderbuffer(rb.fboMS);
            if (status != FRAMEBUFFER_COMPLETE)
                valid = false;
        }

        if (!valid)
        {
            trace("[Foo3D - WARNING] - Framebuffer was somehow broken!");
            this.destroyRenderBuffer(rbObj);
            return 0;
        }

        return rbObj;
    }

    inline function _validateRenderbuffer(_buf:Int):Int {
        hx_gl_bindFramebuffer(FRAMEBUFFER, _buf);
        var status:Int = hx_gl_checkFrameBufferStatus();
        hx_gl_bindFramebuffer(FRAMEBUFFER, 0);

        switch (status) {
            case FRAMEBUFFER_UNSUPPORTED: throw "[Foo3D - Error] - Framebuffer is not supported";
            case FRAMEBUFFER_INCOMPLETE_ATTACHMENT: throw "[Foo3D - Error] - Framebuffer incomplete attachment";
            case FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: throw "[Foo3D - Error] - Framebuffer incomplete missing attachment";
        }
        return status;
    }

    override public function destroyRenderBuffer(_handle:Int):Void 
    {
        var rb = m_renBuffers.getRef(_handle);

        hx_gl_bindFramebuffer(FRAMEBUFFER, 0);

        if (rb.depthTex != null && rb.depthTex != 0) destroyTexture(rb.depthTex);
        if (rb.depthBufObj != null && rb.depthBufObj != 0) hx_gl_deleteRenderbuffer(rb.depthBufObj);
        rb.depthTex = rb.depthBufObj = 0;

        for (i in 0...m_caps.maxColorAttachments) {
            if (rb.colTexs[i] != 0) 
                this.destroyTexture(rb.colTexs[i]);
            if (rb.colBufs[i] != 0) 
                hx_gl_deleteRenderbuffer(rb.colBufs[i]);
            rb.colTexs[i] = rb.colBufs[i] = 0;
        }

        if (rb.fbo != null && rb.fbo != 0)
            hx_gl_deleteFramebuffer(rb.fbo);
        if (rb.fboMS != null && rb.fboMS != 0)
            hx_gl_deleteFramebuffer(rb.fboMS);
        rb.fbo = rb.fboMS = 0;

        m_renBuffers.remove(_handle);
    }

    override public function getRenderBufferTex(_handle:Int, ?_bufIndex:Int=0):Int
    {
        var rb = m_renBuffers.getRef(_handle);
        if (_bufIndex < m_caps.maxColorAttachments)
            return rb.colTexs[_bufIndex];
        else if (_bufIndex == 32)
            return rb.depthTex;
        else
            return 0;
    }

    function _resolveRenderbuffer(_handle:Int):Void {
        var rb = m_renBuffers.getRef(_handle);
        if (rb.fboMS == null || rb.fboMS == 0)
            return;

        hx_gl_bindFramebuffer(READ_FRAMEBUFFER, rb.fboMS);
        hx_gl_bindFramebuffer(DRAW_FRAMEBUFFER, rb.fbo);

        var depthResolved = false;
        for (i in 0...m_caps.maxColorAttachments) {
            if (rb.colBufs[i] != 0) {
                hx_gl_readBuffer(COLOR_ATTACHMENT0+i);
                hx_gl_drawBuffer(COLOR_ATTACHMENT0+i);

                var mask = COLOR_BUFFER_BIT;
                if (!depthResolved && rb.depthBufObj != null && rb.depthBufObj != 0) {
                    mask |= DEPTH_BUFFER_BIT | STENCIL_BUFFER_BIT;
                    depthResolved = true;
                }
                hx_gl_blitFramebuffer(rb.width, rb.height, mask);
            }
        }

        if (!depthResolved && rb.depthBufObj != null && rb.depthBufObj != 0) {
            hx_gl_readBuffer(NONE);
            hx_gl_drawBuffer(NONE);
            hx_gl_blitFramebuffer(rb.width, rb.height, DEPTH_BUFFER_BIT | STENCIL_BUFFER_BIT);
        }

        hx_gl_bindFramebuffer(READ_FRAMEBUFFER, 0);
        hx_gl_bindFramebuffer(DRAW_FRAMEBUFFER, 0);
    }

    override public function bindRenderBuffer(_handle:Int):Void
    {
        if (m_curRenderBuffer != 0)
            _resolveRenderbuffer(m_curRenderBuffer);

        m_curRenderBuffer = _handle;

        if (_handle == 0)
        {
            // set to main backbuffer
            hx_gl_bindFramebuffer(FRAMEBUFFER, 0);
            hx_gl_drawBuffer(0x0402); // BACK_LEFT
            hx_gl_disable(MULTISAMPLE);
        }
        else
        {
            // reset all texture bindings
            for (i in 0...m_caps.maxTextureUnits)
                this.setTexture(i, 0, 0); // TODO: optimize this!

            this.commitStates(ARD.PM_TEXTURES);

            var rb = m_renBuffers.getRef(_handle);

            hx_gl_bindFramebuffer(FRAMEBUFFER, rb.fboMS != null && rb.fboMS != 0 ? rb.fboMS : rb.fbo);

            if (rb.fboMS != null && rb.fboMS != 0)
                hx_gl_enable(MULTISAMPLE);
            else
                hx_gl_disable(MULTISAMPLE);
        }
    }

    override function applyVertexLayout():Bool
    {
        if (m_newVertLayout == 0 || m_curShaderId == 0)
            return false;

        var vl:RDIVertexLayout = m_vertexLayouts[m_newVertLayout - 1];
        var shader:RDIShaderProgram = m_shaders.getRef(m_curShaderId);
        var inputLayout:RDIShaderInputLayout = shader.inputLayouts[m_newVertLayout - 1];

        if (!inputLayout.valid)
            return false;

        var newVertexAttribMask:Int = 0;
        for (i in 0...vl.numAttribs) {
            var attribIndex:Int = inputLayout.attribIndices[i];
            if (attribIndex >= 0) {
                var attrib:RDIVertexLayoutAttrib = vl.attribs[i];
                var vbSlot:RDIVertBufSlot = m_vertBufSlots[attrib.vbSlot];

                hx_gl_bindBuffer(RDIBufferType.VERTEX, m_buffers.getRef(vbSlot.vbObj).glObj);
                hx_gl_vertexAttribPointer(
                    attribIndex, 
                    attrib.size, 
                    FLOAT, 
                    false, 
                    vbSlot.stride*4, 
                    (vbSlot.offset + attrib.offset)*4
                );
                
                newVertexAttribMask |= 1 << attribIndex;
            }
        }

        for (i in 0...16) {
            var curBit:Int = 1 << i;
            if ((newVertexAttribMask & curBit) != (m_activeVertexAttribsMask & curBit)) {
                if ((newVertexAttribMask & curBit) == curBit)
                    hx_gl_enableVertexAttribArray(i);
                else
                    hx_gl_disableVertexAttribArray(i);
            }
        }
        m_activeVertexAttribsMask = newVertexAttribMask;
        
        return true;
    }

    static var magFilters:Array<Int>        = [LINEAR, LINEAR, NEAREST];
    static var minFiltersMips:Array<Int>    = [LINEAR_MIPMAP_NEAREST, LINEAR_MIPMAP_LINEAR, NEAREST_MIPMAP_NEAREST];
    static var wrapModes:Array<Int>         = [CLAMP_TO_EDGE, REPEAT, MIRRORED_REPEAT];

    override function applySamplerState(_tex:RDITexture):Void
    {
        var state = _tex.samplerState;
        var target = _tex.type;       

        if (_tex.hasMips)
            hx_gl_texParameteri(target, TEXTURE_MIN_FILTER, minFiltersMips[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START]);
        else
            hx_gl_texParameteri(target, TEXTURE_MIN_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        
        hx_gl_texParameteri( target, TEXTURE_MAG_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        hx_gl_texParameteri( target, TEXTURE_WRAP_S, wrapModes[(state & AbstractRenderDevice.SS_ADDRU_MASK) >> AbstractRenderDevice.SS_ADDRU_START] );
        hx_gl_texParameteri( target, TEXTURE_WRAP_T, wrapModes[(state & AbstractRenderDevice.SS_ADDRV_MASK) >> AbstractRenderDevice.SS_ADDRV_START] );
    }

    override public function commitStates(?_filter=0xFFFFFFFF):Bool
    {
        if ((m_pendingMask & _filter) != 0) {
            var mask:Int = m_pendingMask & _filter;

            // Set viewport
            if ((mask & ARD.PM_VIEWPORT) == ARD.PM_VIEWPORT) {
                hx_gl_viewport(m_vpX, m_vpY, m_vpWidth, m_vpHeight);
                m_pendingMask &= ~ARD.PM_VIEWPORT;
            }

            // Set scissor rect
            if ((mask & ARD.PM_SCISSOR) == ARD.PM_SCISSOR) {
                hx_gl_scissor(m_scX, m_scY, m_scWidth, m_scHeight);
                m_pendingMask &= ~ARD.PM_SCISSOR;
            }

            // Cullmode
            if ((mask & ARD.PM_CULLMODE) == ARD.PM_CULLMODE) {
                if (m_newCullMode != m_curCullMode) {
                    if (m_newCullMode == RDICullModes.NONE)
                        hx_gl_disable(CULL_FACE);
                    else {
                        hx_gl_enable(CULL_FACE);
                        hx_gl_cullFace(m_newCullMode);
                    }
                    m_curCullMode = m_newCullMode;
                }
                m_pendingMask &= ~ARD.PM_CULLMODE;
            }

            // Depth Mask
            if ((mask & ARD.PM_DEPTH_MASK) == ARD.PM_DEPTH_MASK) 
            {
                if (m_newDepthMask != m_curDepthMask) {
                    hx_gl_depthMask(m_newDepthMask == true ? 1 : 0);
                    m_curDepthMask = m_newDepthMask;
                }
                m_pendingMask &= ~ARD.PM_DEPTH_MASK;
            }

            // Depth Test
            if ((mask & ARD.PM_DEPTH_TEST) == ARD.PM_DEPTH_TEST) 
            {
                if (m_newDepthTest != m_curDepthTest) {
                    if (m_newDepthTest == RDITestModes.DISABLE) {
                        if (m_depthTestEnabled) {
                            hx_gl_disable(DEPTH_TEST);
                            m_depthTestEnabled = false;
                        }
                    }
                    else {
                        if (!m_depthTestEnabled) {
                            hx_gl_enable(DEPTH_TEST);
                            m_depthTestEnabled = true;
                        }
                        hx_gl_depthFunc(m_newDepthTest);
                    }                    
                    m_curDepthTest = m_newDepthTest;
                }                    
                m_pendingMask &= ~ARD.PM_DEPTH_TEST;
            }

            // set blendequation
            if((mask & ARD.PM_BLEND_EQ) == ARD.PM_BLEND_EQ)
            {
                if (m_newBlendEq != m_curBlendEq) {

                    if (m_blendEqBuffer != -1)
                        hx_gl_blendEquationBuffer(m_blendEqBuffer, m_newBlendEq);
                    else
                        hx_gl_blendEquation(m_newBlendEq);

                    m_curBlendEq = m_newBlendEq;
                }

                m_pendingMask &= ~ARD.PM_BLEND_EQ;
            }

            // set blending
            if((mask & ARD.PM_BLEND) == ARD.PM_BLEND)
            {
                if (m_newSrcFactor != m_curSrcFactor || m_newDstFactor != m_curDstFactor) {
                    if (m_newSrcFactor == RDIBlendFactors.ONE && m_newDstFactor == RDIBlendFactors.ZERO)
                        hx_gl_disable(BLEND); // replace-function
                    else {
                        hx_gl_enable(BLEND);
                    }
                    hx_gl_blendFunc(m_newSrcFactor, m_newDstFactor);
                    
                    m_curSrcFactor = m_newSrcFactor;
                    m_curDstFactor = m_newDstFactor;
                }
                m_pendingMask &= ~ARD.PM_BLEND;
            }

            // Bind textures and set sampler state
            if((mask & ARD.PM_TEXTURES) == ARD.PM_TEXTURES) 
            {
                for (i in 0...m_caps.maxTextureUnits) {
                    hx_gl_activeTexture(TEXTURE0+i);

                    if (m_texSlots[i].texObj != 0) {
                        var tex:RDITexture = m_textures.getRef(m_texSlots[i].texObj);
                        hx_gl_bindTexture(tex.type, tex.glObj);

                        if (tex.samplerState != m_texSlots[i].samplerState) {
                            tex.samplerState = m_texSlots[i].samplerState;
                            applySamplerState(tex);
                        }
                    }
                    else {
                        hx_gl_bindTexture(RDITextureTypes.TEXCUBE, null);
                        hx_gl_bindTexture(RDITextureTypes.TEX2D, null);
                    }
                }

                m_pendingMask &= ~ARD.PM_TEXTURES;
            }

            // Bind index buffer
            if ((mask & ARD.PM_INDEXBUF) == ARD.PM_INDEXBUF)
            {
                if (m_newIndexBuf != m_curIndexBuf) {
                    if (m_newIndexBuf != 0)
                        hx_gl_bindBuffer(RDIBufferType.INDEX, m_buffers.getRef(m_newIndexBuf).glObj);
                    else
                        hx_gl_bindBuffer(RDIBufferType.INDEX, null);
                    
                    m_curIndexBuf = m_newIndexBuf;
                }
                m_pendingMask &= ~ARD.PM_INDEXBUF;
            }

            // Bind vertex buffers
            if ((mask & ARD.PM_VERTLAYOUT) == ARD.PM_VERTLAYOUT)
            {
                if (!applyVertexLayout()) {
                    return false;
                }
                m_prevShaderId = m_curShaderId;
                m_pendingMask &= ~ARD.PM_VERTLAYOUT;
            }
        }
        return true;
    }

    override public function resetStates():Void
    {
        for (i in 0...m_caps.maxVertAttribs)
            hx_gl_disableVertexAttribArray(i);

        super.resetStates();
    }

    override public function isLost():Bool 
    {
        return false;
    }

    override public function clear(_flags:Int, ?_r:Float = 0, ?_g:Float = 0, ?_b:Float = 0, ?_a:Float = 1, ?_depth:Float = 1):Void
    {
        var mask:Int = 0;
        if ((_flags & RDIClearFlags.DEPTH) == RDIClearFlags.DEPTH)
        {
            mask |= DEPTH_BUFFER_BIT;
            hx_gl_clearDepth(_depth);
        }
        if ((_flags & RDIClearFlags.COLOR) == RDIClearFlags.COLOR)
        {
            mask |= COLOR_BUFFER_BIT;
            hx_gl_clearColor(_r, _g, _b, _a);
        }
        if ((_flags & RDIClearFlags.ALL) == RDIClearFlags.ALL)
        {
            mask |= COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT | STENCIL_BUFFER_BIT;
        }
        if (mask != 0)
        {
            commitStates( ARD.PM_VIEWPORT | ARD.PM_SCISSOR );
            hx_gl_clear(mask);
        }
    }

    override public function draw(_primType:Int, _numInds:Int, _offset:Int):Void
    {
        if (commitStates())
            hx_gl_drawElements(_primType, _numInds, _offset);
    }

    override public function drawArrays(_primType:Int, _offset:Int, _size:Int):Void
    {
        if (commitStates())
            hx_gl_drawArrays(_primType, _offset, _size);
    }

	// Native Interface
    public static var hx_gl_activeTexture = cpp.Lib.load("foo3d", "hx_gl_activeTexture", 1);
    public static var hx_gl_attachShader = cpp.Lib.load("foo3d", "hx_gl_attachShader", 2);
    
    public static var hx_gl_bindBuffer = cpp.Lib.load("foo3d", "hx_gl_bindBuffer", 2);
    public static var hx_gl_bindFramebuffer = cpp.Lib.load("foo3d", "hx_gl_bindFramebuffer", 2);
    public static var hx_gl_bindRenderbuffer = cpp.Lib.load("foo3d", "hx_gl_bindRenderbuffer", 2);
    public static var hx_gl_bindTexture = cpp.Lib.load("foo3d", "hx_gl_bindTexture", 2);    
    public static var hx_gl_blendEquation = cpp.Lib.load("foo3d", "hx_gl_blendEquation", 1);
    public static var hx_gl_blendEquationBuffer = cpp.Lib.load("foo3d", "hx_gl_blendEquationBuffer", 2);
    public static var hx_gl_blendFunc = cpp.Lib.load("foo3d", "hx_gl_blendFunc", 2);    
    public static var hx_gl_blitFramebuffer = cpp.Lib.load("foo3d", "hx_gl_blitFramebuffer", 3);
    public static var hx_gl_bufferData = cpp.Lib.load("foo3d", "hx_gl_bufferData", 4);
    public static var hx_gl_bufferSubData = cpp.Lib.load("foo3d", "hx_gl_bufferSubData", 4);
    
    public static var hx_gl_checkFrameBufferStatus = cpp.Lib.load("foo3d", "hx_gl_checkFrameBufferStatus", 0);
    public static var hx_gl_clearDepth = cpp.Lib.load("foo3d", "hx_gl_clearDepth", 1);
    public static var hx_gl_clearColor = cpp.Lib.load("foo3d", "hx_gl_clearColor", 4);
    public static var hx_gl_clear = cpp.Lib.load("foo3d", "hx_gl_clear", 1);
    public static var hx_gl_compileShader = cpp.Lib.load("foo3d", "hx_gl_compileShader", 1);
    public static var hx_gl_createBuffer = cpp.Lib.load("foo3d", "hx_gl_createBuffer", 0);
    public static var hx_gl_createProgram = cpp.Lib.load("foo3d", "hx_gl_createProgram", 0);
    public static var hx_gl_createShader = cpp.Lib.load("foo3d", "hx_gl_createShader", 1);
    public static var hx_gl_createTexture = cpp.Lib.load("foo3d", "hx_gl_createTexture", 0);
    public static var hx_gl_cullFace = cpp.Lib.load("foo3d", "hx_gl_cullFace", 1);

    public static var hx_gl_deleteBuffer = cpp.Lib.load("foo3d", "hx_gl_deleteBuffer", 1);
    public static var hx_gl_deleteFramebuffer = cpp.Lib.load("foo3d", "hx_gl_deleteFramebuffer", 1);
    public static var hx_gl_deleteRenderbuffer = cpp.Lib.load("foo3d", "hx_gl_deleteRenderbuffer", 1);
    public static var hx_gl_deleteProgram = cpp.Lib.load("foo3d", "hx_gl_deleteProgram", 1);
    public static var hx_gl_deleteShader = cpp.Lib.load("foo3d", "hx_gl_deleteShader", 1);
    public static var hx_gl_deleteTexture = cpp.Lib.load("foo3d", "hx_gl_deleteTexture", 1);
    public static var hx_gl_depthFunc = cpp.Lib.load("foo3d", "hx_gl_depthFunc", 1);
    public static var hx_gl_depthMask = cpp.Lib.load("foo3d", "hx_gl_depthMask", 1);
    public static var hx_gl_disable = cpp.Lib.load("foo3d", "hx_gl_disable", 1);
    public static var hx_gl_disableVertexAttribArray = cpp.Lib.load("foo3d", "hx_gl_disableVertexAttribArray", 1);
    public static var hx_gl_drawArrays = cpp.Lib.load("foo3d", "hx_gl_drawArrays", 3);
    public static var hx_gl_drawBuffer = cpp.Lib.load("foo3d", "hx_gl_drawBuffer", 1);
    public static var hx_gl_drawBuffers = cpp.Lib.load("foo3d", "hx_gl_drawBuffers", 1);
    public static var hx_gl_drawElements = cpp.Lib.load("foo3d", "hx_gl_drawElements", 3);
    
    public static var hx_gl_enable = cpp.Lib.load("foo3d", "hx_gl_enable", 1);
    public static var hx_gl_enableVertexAttribArray = cpp.Lib.load("foo3d", "hx_gl_enableVertexAttribArray", 1);

    public static var hx_gl_framebufferRenderbuffer = cpp.Lib.load("foo3d", "hx_gl_framebufferRenderbuffer", 2);
    public static var hx_gl_framebufferTexture2D = cpp.Lib.load("foo3d", "hx_gl_framebufferTexture2D", 2);

    public static var hx_gl_genFramebuffer = cpp.Lib.load("foo3d", "hx_gl_genFramebuffer", 0);
    public static var hx_gl_generateMipmap = cpp.Lib.load("foo3d", "hx_gl_generateMipmap", 1);
    public static var hx_gl_genRenderbuffer = cpp.Lib.load("foo3d", "hx_gl_genRenderbuffer", 0);
    public static var hx_gl_getActiveAttrib = cpp.Lib.load("foo3d", "hx_gl_getActiveAttrib", 3);
    public static var hx_gl_getActiveUniform = cpp.Lib.load("foo3d", "hx_gl_getActiveUniform", 3);  
    public static var hx_gl_getAttribLocation = cpp.Lib.load("foo3d", "hx_gl_getAttribLocation", 2);
    public static var hx_gl_getIntegerv = cpp.Lib.load("foo3d", "hx_gl_getIntegerv", 1);
    public static var hx_gl_getProgramiv = cpp.Lib.load("foo3d", "hx_gl_getProgramiv", 2);
    public static var hx_gl_getProgramInfoLog = cpp.Lib.load("foo3d", "hx_gl_getProgramInfoLog", 1);
    public static var hx_gl_getShaderiv = cpp.Lib.load("foo3d", "hx_gl_getShaderiv", 2);
    public static var hx_gl_getShaderInfoLog = cpp.Lib.load("foo3d", "hx_gl_getShaderInfoLog", 1);
    public static var hx_gl_getUniformLocation = cpp.Lib.load("foo3d", "hx_gl_getUniformLocation", 2);
	
	public static var hx_gl_linkProgram = cpp.Lib.load("foo3d", "hx_gl_linkProgram", 1);	
	
	public static var hx_gl_readBuffer = cpp.Lib.load("foo3d", "hx_gl_readBuffer", 1);
    public static var hx_gl_renderbufferStorageMultisample = cpp.Lib.load("foo3d", "hx_gl_renderbufferStorageMultisample", 4);
	public static var hx_gl_scissor = cpp.Lib.load("foo3d", "hx_gl_scissor", 4);
    public static var hx_gl_shaderSource = cpp.Lib.load("foo3d", "hx_gl_shaderSource", 2);
	
	public static var hx_gl_texParameteri = cpp.Lib.load("foo3d", "hx_gl_texParameteri", 3);   
    public static var hx_gl_texImage2D = cpp.Lib.load("foo3d", "hx_gl_texImage2D", -1);	
	
	public static var hx_gl_vertexAttribPointer = cpp.Lib.load("foo3d", "hx_gl_vertexAttribPointer", -1);
	
	public static var hx_gl_uniform1fv = cpp.Lib.load("foo3d", "hx_gl_uniform1fv", 2);
    public static var hx_gl_uniform2fv = cpp.Lib.load("foo3d", "hx_gl_uniform2fv", 2);
    public static var hx_gl_uniform3fv = cpp.Lib.load("foo3d", "hx_gl_uniform3fv", 2);
    public static var hx_gl_uniform4fv = cpp.Lib.load("foo3d", "hx_gl_uniform4fv", 2);
    public static var hx_gl_uniformMatrix3fv = cpp.Lib.load("foo3d", "hx_gl_uniformMatrix3fv", 3);
    public static var hx_gl_uniformMatrix4fv = cpp.Lib.load("foo3d", "hx_gl_uniformMatrix4fv", 3);
    public static var hx_gl_uniform1i = cpp.Lib.load("foo3d", "hx_gl_uniform1i", 2);	
	public static var hx_gl_useProgram = cpp.Lib.load("foo3d", "hx_gl_useProgram", 1);	

	public static var hx_gl_viewport = cpp.Lib.load("foo3d", "hx_gl_viewport", 4);
	
	public static var hx_rd_init = cpp.Lib.load("foo3d", "hx_rd_init", 1);
}