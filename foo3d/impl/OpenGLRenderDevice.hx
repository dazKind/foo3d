package foo3d.impl;

import foo3d.RenderDevice;
import haxe.io.BytesData;

class OpenGLRenderDevice extends AbstractRenderDevice {
	
	public function new(_ctx:RenderContext)
        super(_ctx);

    override function init():Void {
        GL.init(m_caps);
        trace(m_caps.toString());
    }

	override public function createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = -1):Int {
		var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.VERTEX, 
            GL.createBuffer(),
            _size, 
            _usageHint);

        var old = GL.getIntegerv(GL.ARRAY_BUFFER_BINDING);
        GL.bindBuffer(buf.type, buf.glObj);
        GL.bufferData(buf.type, buf.size, _data, _usageHint);
        GL.bindBuffer(buf.type, old);
        
        m_bufferMem += buf.size;
        return m_buffers.add( buf );
	}

	override public function createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.INDEX, 
            GL.createBuffer(), 
            _size, 
            _usageHint);
        
        var old = GL.getIntegerv(GL.ELEMENT_ARRAY_BUFFER_BINDING);
        GL.bindBuffer(buf.type, buf.glObj);
        GL.bufferData(buf.type, buf.size, _data, _usageHint);
        GL.bindBuffer(buf.type, old);
        
        m_bufferMem += buf.size;
        return m_buffers.add( buf );
    }

    override public function destroyBuffer(_handle:Int):Void {
        if (_handle == 0) return;
        
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        GL.deleteBuffer(buf.glObj);
        
        m_bufferMem -= buf.size;
        m_buffers.remove(_handle);
    }

    override public function updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        var old = GL.getIntegerv(GL.ARRAY_BUFFER_BINDING);
        GL.bindBuffer(buf.type, buf.glObj);
        GL.bufferSubData(buf.type, _offset, _size, _data);
        GL.bindBuffer(buf.type, old);
    }
    
    override public function updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        var old = GL.getIntegerv(GL.ELEMENT_ARRAY_BUFFER_BINDING);
        GL.bindBuffer(buf.type, buf.glObj);
        GL.bufferSubData(buf.type, _offset, _size, _data);        
        GL.bindBuffer(buf.type, old);
        
        /*
        if(m_curIndexBuf != 0) // rebind the old one
            GL.bindBuffer(buf.type, m_buffers.getRef(m_curIndexBuf).glObj);
        else
            GL.bindBuffer(buf.type, 0);
        */
    }

    override public function createTexture(_type:Int, _width:Int, _height:Int, _format:Int, _hasMips:Bool, _genMips:Bool, _isCompressed:Bool):Int { 
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
        tex.isCompressed = _isCompressed;
        tex.glFmt = _format;

        tex.glObj = GL.createTexture();
        GL.activeTexture(GL.TEXTURE0+m_lastTexUnit);
        GL.bindTexture(_type, tex.glObj);

        tex.samplerState = 0;
        applySamplerState(tex);

        GL.bindTexture(_type, 0);
        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
            GL.bindTexture(t.type, t.glObj);
        }
        
        tex.memSize = calcTextureSize(tex.format, _width, _height);
        if (_hasMips || _genMips)
            tex.memSize += Std.int(tex.memSize * 1.0 / 3.0);
        if (_type == RDITextureTypes.TEXCUBE)
            tex.memSize *= 6;

        m_textureMem += tex.memSize;

        return m_textures.add( tex );
    }

    override public function uploadTextureData(_handle:Int, _slice:Int, _mipLevel:Int, _pixels:PixelData, ?_formatOverride:Int=0, ?_typeOverride:Int=0, ?_imageSize:Int=0):Void {
        var tex:RDITexture = m_textures.getRef(_handle);

        GL.activeTexture(GL.TEXTURE0+m_lastTexUnit);
        GL.bindTexture(tex.type, tex.glObj);

        var inputFormat:Int = GL.RGBA;
        var inputType:Int = GL.UNSIGNED_BYTE;

        if (_formatOverride != 0) {
            inputFormat = _formatOverride;
        } else {
            switch (tex.format)
            {
                case RDITextureFormats.RGB8:
                    inputFormat = GL.RGB;
                case RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F:
                    inputFormat = GL.RGBA;
                    inputType = GL.FLOAT;
                case RDITextureFormats.R16UI:
                    inputFormat = GL.RED;
                    inputType = GL.UNSIGNED_SHORT;
                case RDITextureFormats.R16F:
                    inputFormat = GL.RED;
                    inputType = GL.FLOAT;
                case RDITextureFormats.DEPTH:
                    inputFormat = GL.DEPTH_COMPONENT;
                    inputType = GL.FLOAT;
                case GL.DEPTH24_STENCIL8:
                    inputFormat = GL.DEPTH_STENCIL;
                    inputType = GL.UNSIGNED_INT_24_8;
            }
        }

        if (_typeOverride != 0) {
            inputType = _typeOverride;
        } else {
            switch (tex.format)
            {
                case RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F:
                    inputType = GL.FLOAT;
                case RDITextureFormats.R16UI:
                    inputType = GL.UNSIGNED_SHORT;
                case RDITextureFormats.R16F:
                    inputType = GL.FLOAT;
                case RDITextureFormats.DEPTH:
                    inputType = GL.FLOAT;
                case GL.DEPTH24_STENCIL8:
                    inputType = GL.UNSIGNED_INT_24_8;
            }
        }

        // Calculate size of next mipmap using "floor" convention
        var width:Int = Std.int(Math.max(tex.width >> _mipLevel, 1));
        var height:Int = Std.int(Math.max(tex.height >> _mipLevel, 1));

        var target:Int = (tex.type == RDITextureTypes.TEX2D) ? 
            RDITextureTypes.TEX2D : (GL.TEXTURE_CUBE_MAP_POSITIVE_X + _slice);

        if (_pixels == null) {// we wanna upload an empty buffer
            //if (tex.isCompressed == false)
            GL.texImage2D(target, _mipLevel, tex.glFmt, width, height, 0, inputFormat, inputType, null);
        } else {
            if (tex.isCompressed == true)
                GL.compressedTexImage2D(target, _mipLevel, inputFormat, width, height, 0, _imageSize, _pixels);
            else
                GL.texImage2D(target, _mipLevel, tex.glFmt, width, height, 0, inputFormat, inputType, _pixels);
        }

        // Note: for cube maps mips are only generated when the side with the highest index is uploaded
        if (tex.genMips && (tex.type != RDITextureTypes.TEXCUBE || _slice == 5))
            GL.generateMipmap(tex.type);

        GL.bindTexture(tex.type, 0);

        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
           GL.bindTexture(t.type, t.glObj);
        }
    }

    override public function destroyTexture(_handle:Int):Void {
        if (_handle == 0) return;
        
        var tex:RDITexture = m_textures.getRef(_handle);
        GL.deleteTexture(tex.glObj);
        
        m_textureMem -= tex.memSize;
        m_textures.remove(_handle);
    }

    override public function createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int {
        // create shaders
        var vs:Int = GL.createShader(GL.VERTEX_SHADER);
        GL.shaderSource(vs, _vertexShaderSrc);
        GL.compileShader(vs);

        var success:Bool = GL.getShaderiv(vs, GL.COMPILE_STATUS) == 1;
        if (!success)
        {
            trace("[Foo3D - Error] - Vertex Shader: " + GL.getShaderInfoLog(vs));
            GL.deleteShader(vs);
            return 0;
        }

        var fs:Int = GL.createShader(GL.FRAGMENT_SHADER);
        GL.shaderSource(fs, _fragmentShaderSrc);
        GL.compileShader(fs);
        var success:Bool = GL.getShaderiv(fs, GL.COMPILE_STATUS) == 1;
        if (!success)
        {
            trace(_fragmentShaderSrc);
            trace("[Foo3D - Error] - Fragment Shader: " + GL.getShaderInfoLog(fs));
            GL.deleteShader(vs);
            GL.deleteShader(fs);
            return 0;
        }

        // create program
        var prog:Int = GL.createProgram();
        GL.attachShader(prog, vs);
        GL.attachShader(prog, fs);
        GL.deleteShader(vs);
        GL.deleteShader(fs);

        // link program
        GL.linkProgram(prog);
        success = GL.getProgramiv(prog, GL.LINK_STATUS) == 1;
        if (!success)
        {
            trace("[Foo3D - Error] - Linking: " + GL.getProgramInfoLog(prog));
            GL.deleteProgram(prog);
            return 0;
        }

        var shader:RDIShaderProgram = new RDIShaderProgram();
        shader.oglProgramObj = prog;
        var attribCount:Int = GL.getProgramiv(prog, GL.ACTIVE_ATTRIBUTES);

        for (i in 0...m_numVertexLayouts)
        {
            var vl:RDIVertexLayout = m_vertexLayouts[i];
            var allAttribsFound:Bool = true;

            for (j in 0...16)
                shader.inputLayouts[i].attribIndices[j] = -1;

            for (j in 0...attribCount)
            {

                var info:RDIUniformInfo = new RDIUniformInfo();
                GL.getActiveAttrib(prog, j, info);

                var attribFound:Bool = false;
                for (k in 0...vl.numAttribs)
                {
                    if (vl.attribs[k].semanticName == info.name)
                    {
                        shader.inputLayouts[i].attribIndices[k] = GL.getAttribLocation(prog, info.name);
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

    override public function destroyProgram(_handle:Int):Void {
        if (_handle == 0) return;

        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        GL.deleteProgram(shader.oglProgramObj);
        m_shaders.remove(_handle);
    }

    override public function bindProgram(_handle:Int):Void {
        if (_handle != 0) {
            var shader:RDIShaderProgram = m_shaders.getRef(_handle);
            GL.useProgram(shader.oglProgramObj);
        }
        else
            GL.useProgram(0);

        m_curShaderId = _handle;
        m_pendingMask |= ARD.PM_VERTLAYOUT;
    }

    override public function getActiveUniformCount(_handle:Int):Int {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return GL.getProgramiv(shader.oglProgramObj, GL.ACTIVE_UNIFORMS);
    }

    override public function getActiveUniformInfo(_handle:Int, _index:Int):RDIUniformInfo {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        var info:RDIUniformInfo = new RDIUniformInfo();
        GL.getActiveUniform(shader.oglProgramObj, _index, info);
        return info;
    }

    override public function getUniformLoc(_handle:Int, _name:String):UniformLocationType {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return GL.getUniformLocation(shader.oglProgramObj, _name);
    }

    override public function getSamplerLoc(_handle:Int, _name:String):UniformLocationType {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return GL.getUniformLocation(shader.oglProgramObj, _name);
    }

    override public function setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void {
        switch (_type) {
            case RDIShaderConstType.FLOAT: GL.uniform1fv(_loc, _values.length, cast _values);
            case RDIShaderConstType.FLOAT2: GL.uniform2fv(_loc, Std.int(_values.length/2), cast _values);
            case RDIShaderConstType.FLOAT3: GL.uniform3fv(_loc, Std.int(_values.length/3), cast _values);
            case RDIShaderConstType.FLOAT4: GL.uniform4fv(_loc, Std.int(_values.length/4), cast _values);
            case RDIShaderConstType.FLOAT3x3: GL.uniformMatrix3fv(_loc, false, cast _values);
            case RDIShaderConstType.FLOAT4x4: GL.uniformMatrix4fv(_loc, false, cast _values);
            case RDIShaderConstType.FLOAT2x4: GL.uniformMatrix2x4fv(_loc, false, cast _values);
        }
    }

    override public function setSampler(_loc:UniformLocationType, _texUnit:Int):Void
        GL.uniform1i(_loc, _texUnit);

    override public function createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int 
    { 

		if ((_format == RDITextureFormats.RGBA16F || _format == RDITextureFormats.RGBA32F) && !m_caps.texFloatSupport)
            return 0;

        if (_numColBufs > m_caps.maxColorAttachments)
        	return 0;

        var maxSamples = 0;
        if (m_caps.rtMultisampling)
        	maxSamples = GL.getIntegerv(GL.MAX_SAMPLES);
        if (_samples > maxSamples) {
        	_samples = maxSamples;
        	trace("[Foo3D - WARNING] - GPU doesnt support desired multisampling quality for rendertarget!");
        }
        
        var rb:RDIRenderBuffer = new RDIRenderBuffer(_numColBufs);
        rb.width = _width;
        rb.height = _height;
        rb.samples = _samples;

        rb.fbo = GL.genFramebuffer();
        if (_samples > 0)
            rb.fboMS = GL.genFramebuffer();

        // Attach color buffers
        if (_numColBufs > 0) {
            for(j in 0..._numColBufs) {

                GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fbo);
                // create the color texture
                var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, _format, false, false, false);
                this.uploadTextureData(texObj, 0, 0, null);
                rb.colTexs[j] = texObj;
                var tex:RDITexture = m_textures.getRef(texObj);
                // attach to framebuffer
                GL.framebufferTexture2D(GL.COLOR_ATTACHMENT0+j, tex.glObj);

                if (_samples > 0) {
                    GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fboMS);
                    rb.colBufs[j] = GL.genRenderbuffer();
                    GL.bindRenderbuffer(GL.RENDERBUFFER, rb.colBufs[j]);
                    GL.renderbufferStorageMultisample(rb.samples, tex.glFmt, rb.width, rb.height);
                    GL.framebufferRenderbuffer(GL.COLOR_ATTACHMENT0+j, rb.colBufs[j]); 
                }
            }

            GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fbo);
            GL.drawBuffers(_numColBufs);

            if (_samples > 0) {
                GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fboMS);
                GL.drawBuffers(_numColBufs);
            }
        } else {
            GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fbo);
            GL.drawBuffer(GL.NONE);
            GL.readBuffer(GL.NONE);

            if (_samples > 0) {
                GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fboMS);
                GL.drawBuffer(GL.NONE);
                GL.readBuffer(GL.NONE);                
            }
        }

        // attach depth buffer
        if (_depth)
        {
            GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fbo);
            var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, RDITextureFormats.DEPTH, false, false, false);
            GL.texParameteri(RDITextureTypes.TEX2D, GL.TEXTURE_COMPARE_MODE, GL.NONE);
            this.uploadTextureData(texObj, 0, 0, null);
            rb.depthTex = texObj;
            var tex:RDITexture = m_textures.getRef(texObj);
            GL.framebufferTexture2D(GL.DEPTH_ATTACHMENT, tex.glObj);

            if (_samples > 0) {
                GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fboMS);
                rb.depthBufObj = GL.genRenderbuffer();
                GL.bindRenderbuffer(GL.RENDERBUFFER, rb.depthBufObj);
                GL.renderbufferStorageMultisample(rb.samples, RDITextureFormats.DEPTH, rb.width, rb.height);
                GL.framebufferRenderbuffer(GL.DEPTH_ATTACHMENT, rb.depthBufObj);
            }
        }

        var rbObj:Int = m_renBuffers.add(rb);

        // validate fbo
        var valid:Bool = true;
        var status = _validateRenderbuffer(rb.fbo);

        if (status != GL.FRAMEBUFFER_COMPLETE)
            valid = false;

        // check multisample fbo
        if (_samples > 0) {
            status = _validateRenderbuffer(rb.fboMS);
            if (status != GL.FRAMEBUFFER_COMPLETE)
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
        GL.bindFramebuffer(GL.FRAMEBUFFER, _buf);
        var status:Int = GL.checkFramebufferStatus();
        GL.bindFramebuffer(GL.FRAMEBUFFER, 0);

        switch (status) {
            case GL.FRAMEBUFFER_UNSUPPORTED: throw "[Foo3D - Error] - Framebuffer is not supported";
            case GL.FRAMEBUFFER_INCOMPLETE_ATTACHMENT: throw "[Foo3D - Error] - Framebuffer incomplete attachment";
            case GL.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: throw "[Foo3D - Error] - Framebuffer incomplete missing attachment";
        }
        return status;
    }

    override public function destroyRenderBuffer(_handle:Int):Void {
        var rb = m_renBuffers.getRef(_handle);

        GL.bindFramebuffer(GL.FRAMEBUFFER, 0);

        if (rb.depthTex != null && rb.depthTex != 0) destroyTexture(rb.depthTex);
        if (rb.depthBufObj != null && rb.depthBufObj != 0) GL.deleteRenderbuffer(rb.depthBufObj);
        rb.depthTex = rb.depthBufObj = 0;

        for (i in 0...m_caps.maxColorAttachments) {
            if (rb.colTexs[i] != 0) 
                this.destroyTexture(rb.colTexs[i]);
            if (rb.colBufs[i] != 0) 
                GL.deleteRenderbuffer(rb.colBufs[i]);
            rb.colTexs[i] = rb.colBufs[i] = 0;
        }

        if (rb.fbo != null && rb.fbo != 0)
            GL.deleteFramebuffer(rb.fbo);
        if (rb.fboMS != null && rb.fboMS != 0)
            GL.deleteFramebuffer(rb.fboMS);
        rb.fbo = rb.fboMS = 0;

        m_renBuffers.remove(_handle);
    }

    override public function getRenderBufferTex(_handle:Int, ?_bufIndex:Int=0):Int {
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

        GL.bindFramebuffer(GL.READ_FRAMEBUFFER, rb.fboMS);
        GL.bindFramebuffer(GL.DRAW_FRAMEBUFFER, rb.fbo);

        var depthResolved = false;
        for (i in 0...m_caps.maxColorAttachments) {
            if (rb.colBufs[i] != 0) {
                GL.readBuffer(GL.COLOR_ATTACHMENT0+i);
                GL.drawBuffer(GL.COLOR_ATTACHMENT0+i);

                var mask = GL.COLOR_BUFFER_BIT;
                if (!depthResolved && rb.depthBufObj != null && rb.depthBufObj != 0) {
                    mask |= GL.DEPTH_BUFFER_BIT | GL.STENCIL_BUFFER_BIT;
                    depthResolved = true;
                }
                GL.blitFramebuffer(rb.width, rb.height, mask);
            }
        }

        if (!depthResolved && rb.depthBufObj != null && rb.depthBufObj != 0) {
            GL.readBuffer(GL.NONE);
            GL.drawBuffer(GL.NONE);
            GL.blitFramebuffer(rb.width, rb.height, GL.DEPTH_BUFFER_BIT | GL.STENCIL_BUFFER_BIT);
        }

        GL.bindFramebuffer(GL.READ_FRAMEBUFFER, 0);
        GL.bindFramebuffer(GL.DRAW_FRAMEBUFFER, 0);
    }

    override public function bindRenderBuffer(_handle:Int):Void {
        if (m_curRenderBuffer != 0)
            _resolveRenderbuffer(m_curRenderBuffer);

        m_curRenderBuffer = _handle;

        if (_handle == 0)
        {
            // set to main backbuffer
            GL.bindFramebuffer(GL.FRAMEBUFFER, 0);
            GL.drawBuffer(0x0402); // BACK_LEFT
            GL.disable(GL.MULTISAMPLE);
        }
        else
        {
            // reset all texture bindings
            for (i in 0...m_caps.maxTextureUnits)
                this.setTexture(i, 0, 0); // TODO: optimize this!

            this.commitStates(ARD.PM_TEXTURES);

            var rb = m_renBuffers.getRef(_handle);

            GL.bindFramebuffer(GL.FRAMEBUFFER, rb.fboMS != null && rb.fboMS != 0 ? rb.fboMS : rb.fbo);

            if (rb.fboMS != null && rb.fboMS != 0)
                GL.enable(GL.MULTISAMPLE);
            else
                GL.disable(GL.MULTISAMPLE);
        }
    }

    override function applyVertexLayout():Bool {
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

                GL.bindBuffer(RDIBufferType.VERTEX, m_buffers.getRef(vbSlot.vbObj).glObj);
                GL.vertexAttribPointer(
                    attribIndex, 
                    attrib.size, 
                    attrib.type, 
                    false, 
                    vbSlot.stride, 
                    vbSlot.offset + attrib.offset
                );

                if (m_caps.drawInstancedSupport)
                    GL.vertexAttribDivisor(attribIndex, attrib.divisor);
                
                newVertexAttribMask |= 1 << attribIndex;
            }
        }

        for (i in 0...16) {
            var curBit:Int = 1 << i;
            if ((newVertexAttribMask & curBit) != (m_activeVertexAttribsMask & curBit)) {
                if ((newVertexAttribMask & curBit) == curBit) {
                    GL.enableVertexAttribArray(i);
                }
                else {
                    GL.disableVertexAttribArray(i);
                }
            }
        }
        m_activeVertexAttribsMask = newVertexAttribMask;
        
        return true;
    }

    static var magFilters:Array<Int>        = [GL.LINEAR, GL.LINEAR, GL.NEAREST];
    static var minFiltersMips:Array<Int>    = [GL.LINEAR_MIPMAP_NEAREST, GL.LINEAR_MIPMAP_LINEAR, GL.NEAREST_MIPMAP_NEAREST];
    static var wrapModes:Array<Int>         = [GL.CLAMP_TO_EDGE, GL.REPEAT, GL.MIRRORED_REPEAT];

    override function applySamplerState(_tex:RDITexture):Void {
        var state = _tex.samplerState;
        var target = _tex.type;       

        if (_tex.hasMips)
            GL.texParameteri(target, GL.TEXTURE_MIN_FILTER, minFiltersMips[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START]);
        else
            GL.texParameteri(target, GL.TEXTURE_MIN_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        
        GL.texParameteri( target, GL.TEXTURE_MAG_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        GL.texParameteri( target, GL.TEXTURE_WRAP_S, wrapModes[(state & AbstractRenderDevice.SS_ADDRU_MASK) >> AbstractRenderDevice.SS_ADDRU_START] );
        GL.texParameteri( target, GL.TEXTURE_WRAP_T, wrapModes[(state & AbstractRenderDevice.SS_ADDRV_MASK) >> AbstractRenderDevice.SS_ADDRV_START] );
    }

    override public function commitStates(?_filter:Int=0xFFFFFFFF):Bool {
        if ((m_pendingMask & _filter) != 0) {
            var mask:Int = m_pendingMask & _filter;

            // Set viewport
            if ((mask & ARD.PM_VIEWPORT) == ARD.PM_VIEWPORT) {
                GL.viewport(m_vpX, m_vpY, m_vpWidth, m_vpHeight);
                m_pendingMask &= ~ARD.PM_VIEWPORT;
            }

            // Set scissor rect
            if ((mask & ARD.PM_SCISSOR) == ARD.PM_SCISSOR) {
                if (m_scissorEnabled && m_scX == m_vpX && m_scY == m_vpY && m_scWidth == m_vpWidth && m_scHeight == m_vpHeight) {
                    GL.disable(GL.SCISSOR_TEST);
                    m_scissorEnabled = false;
                }
                else if (!m_scissorEnabled) {
                    GL.enable(GL.SCISSOR_TEST);
                    m_scissorEnabled = true;
                }
                GL.scissor(m_scX, m_scY, m_scWidth, m_scHeight);
                m_pendingMask &= ~ARD.PM_SCISSOR;
            }

            // Cullmode
            if ((mask & ARD.PM_CULLMODE) == ARD.PM_CULLMODE) {
                if (m_newCullMode != m_curCullMode) {
                    if (m_newCullMode == RDICullModes.NONE)
                        GL.disable(GL.CULL_FACE);
                    else {
                        GL.enable(GL.CULL_FACE);
                        GL.cullFace(m_newCullMode);
                    }
                    m_curCullMode = m_newCullMode;
                }
                m_pendingMask &= ~ARD.PM_CULLMODE;
            }

            // Depth Mask
            if ((mask & ARD.PM_DEPTH_MASK) == ARD.PM_DEPTH_MASK) 
            {
                if (m_newDepthMask != m_curDepthMask) {
                    GL.depthMask(m_newDepthMask);
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
                            GL.disable(GL.DEPTH_TEST);
                            m_depthTestEnabled = false;
                        }
                    }
                    else {
                        if (!m_depthTestEnabled) {
                            GL.enable(GL.DEPTH_TEST);
                            m_depthTestEnabled = true;
                        }
                        GL.depthFunc(m_newDepthTest);
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
                        GL.blendEquationBuffer(m_blendEqBuffer, m_newBlendEq);
                    else
                        GL.blendEquation(m_newBlendEq);

                    m_curBlendEq = m_newBlendEq;
                }

                m_pendingMask &= ~ARD.PM_BLEND_EQ;
            }

            // set blending
            if((mask & ARD.PM_BLEND) == ARD.PM_BLEND)
            {
                if (m_newSrcFactor != m_curSrcFactor || m_newDstFactor != m_curDstFactor) {
                    if (m_newSrcFactor == RDIBlendFactors.ONE && m_newDstFactor == RDIBlendFactors.ZERO)
                        GL.disable(GL.BLEND); // replace-function
                    else {
                        GL.enable(GL.BLEND);
                    }
                    GL.blendFunc(m_newSrcFactor, m_newDstFactor);
                    
                    m_curSrcFactor = m_newSrcFactor;
                    m_curDstFactor = m_newDstFactor;
                }
                m_pendingMask &= ~ARD.PM_BLEND;
            }

            // Bind textures and set sampler state
            if((mask & ARD.PM_TEXTURES) == ARD.PM_TEXTURES) 
            {
                for (i in 0...m_caps.maxTextureUnits) {
                    var slot = m_texSlots[i];

                    if (slot.texObj != 0) {
                        GL.activeTexture(GL.TEXTURE0+i);
                        if (!slot.active) {
                            GL.bindTexture(RDITextureTypes.TEXCUBE, 0);
                            GL.bindTexture(RDITextureTypes.TEX2D, 0);
                            slot.texObj = 0;
                        } else {                            
                            var tex:RDITexture = m_textures.getRef(slot.texObj);
                            GL.bindTexture(tex.type, tex.glObj);
                            if (tex.samplerState != slot.samplerState) {
                                tex.samplerState = slot.samplerState;
                                applySamplerState(tex);
                            }
                        }
                    }
                }

                m_pendingMask &= ~ARD.PM_TEXTURES;
            }

            // Bind index buffer
            if ((mask & ARD.PM_INDEXBUF) == ARD.PM_INDEXBUF)
            {
                if (m_newIndexBuf != m_curIndexBuf) {
                    if (m_newIndexBuf != 0)
                        GL.bindBuffer(RDIBufferType.INDEX, m_buffers.getRef(m_newIndexBuf).glObj);
                    else
                        GL.bindBuffer(RDIBufferType.INDEX, 0);
                    
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

    override public function resetStates():Void {
        for (i in 0...16)
            GL.disableVertexAttribArray(i);
        super.resetStates();
    }

    override public function isLost():Bool {
        return false;
    }

    override public function clear(_flags:Int, ?_r:Float = 0, ?_g:Float = 0, ?_b:Float = 0, ?_a:Float = 1, ?_depth:Float = 1):Void {
        var mask:Int = 0;
        if ((_flags & RDIClearFlags.DEPTH) == RDIClearFlags.DEPTH)
        {
            mask |= GL.DEPTH_BUFFER_BIT;
            GL.clearDepth(_depth);
            this.setDepthMask(true); // important: glClear(GL.DEPTH_BUFFER_BIT) needs depthmasking to work
        }
        if ((_flags & RDIClearFlags.COLOR) == RDIClearFlags.COLOR)
        {
            mask |= GL.COLOR_BUFFER_BIT;
            GL.clearColor(_r, _g, _b, _a);
        }
        if ((_flags & RDIClearFlags.ALL) == RDIClearFlags.ALL)
        {
            mask |= GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT | GL.STENCIL_BUFFER_BIT;
        }
        if (mask != 0)
        {
            commitStates( ARD.PM_VIEWPORT | ARD.PM_SCISSOR | ARD.PM_DEPTH_MASK );
            GL.clear(mask);
        }
    }

    override public function draw(_primType:Int, _type:Int, _numInds:Int, _offset:Int):Void {
        if (commitStates())
            GL.drawElements(_primType, _type, _numInds, _offset);
    }

    override public function drawArrays(_primType:Int, _offset:Int, _size:Int):Void {
        if (commitStates())
            GL.drawArrays(_primType, _offset, _size);
    }

    override public function drawInstanced(_primType:Int, _type:Int, _numInds:Int, _offset:Int, _primCount:Int):Void {
        if (!m_caps.drawInstancedSupport)
            trace("[Foo3D - WARNING] - Instanced drawing is not supported!");
        else 
            if (commitStates())
                GL.drawElementsInstanced(_primType, _type, _numInds, _offset, _primCount);
    }

    override public function drawArraysInstanced(_primType:Int, _offset:Int, _size:Int, _primCount:Int):Void {
        if (!m_caps.drawInstancedSupport)
            trace("[Foo3D - WARNING] - Instanced drawing is not supported!");
        else
            if (commitStates())
                GL.drawArraysInstanced(_primType, _offset, _size, _primCount);
    }
}

@:keep
@:include("foo3D.h")
@:buildXml("&<include name='${haxelib:foo3d}/Build.xml'/>")
extern class GL {

    inline public static function init(_caps:RDIDeviceCaps):Void {
        var version = getString(VERSION);
        var vendor = getString(VENDOR);
        var renderer = getString(RENDERER);

        trace("[Foo3D] - Initializing GL backend using OpenGL driver " + version + " by " + vendor + " on " + renderer);

        _caps.texFloatSupport = untyped __cpp__("GLEW_ARB_texture_float==1");
        _caps.texNPOTSupport = untyped __cpp__("GLEW_ARB_texture_non_power_of_two==1");
        _caps.rtMultisampling = untyped __cpp__("GLEW_EXT_framebuffer_multisample==1");
        _caps.drawInstancedSupport = untyped __cpp__("GLEW_ARB_instanced_arrays==1");

        var val:Int = 0;
        untyped __cpp__('glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &{0})', val);
        _caps.maxVertAttribs = val;
        
        untyped __cpp__('glGetIntegerv(GL_MAX_VERTEX_UNIFORM_COMPONENTS, &val)');
        _caps.maxVertUniforms = val;

        untyped __cpp__('glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &val)');
        _caps.maxTextureUnits = val;

        untyped __cpp__('glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &val)');
        _caps.maxColorAttachments = val;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    inline public static function getString(_enum:Int):String { // totally lifted from linc_opengl. Thx sven :)
        var res = untyped __cpp__("::String((const char*)glGetString({0}))", _enum);
        return res != null ? res : "";
    }



    /////////////////////////////////////////////////////////////////////////////////////////////
    inline public static function createBuffer():Int {
        var buf:cpp.UInt32 = -1;
        untyped __cpp__("glGenBuffers(1, &{0})", buf);
        return buf;
    }

    @:native("glBindBuffer")
    public static function bindBuffer(_type:Int, _handle:Int):Void;

    inline public static function bufferData(_type:Int, _size:Int, _data:BytesData, _usageHint:Int):Void
        untyped __cpp__("glBufferData({0}, {1}, (const void*)&({2}[0]), {3})", _type, _size, _data, _usageHint);

    inline public static function deleteBuffer(_handle:Int):Void {
        var tmp:cpp.UInt32 = _handle;
        untyped __cpp__("glDeleteBuffers(1, &{0})", tmp);
    }

    inline public static function bufferSubData(_type:Int, _offset:Int, _size:Int, _data:BytesData):Void
        untyped __cpp__("glBufferSubData({0}, {1}, {2}, (const void*)&({3}[0]))", _type, _offset, _size, _data);

    @:native("glActiveTexture")
    public static function activeTexture(_tex:Int):Void;

    @:native("glBindTexture")
    public static function bindTexture(_target:Int, _tex:Int):Void;

    inline public static function vertexAttribPointer(_index:Int, _size:Int, _type:Int, _normalized:Bool, _stride:Int, _offset:Int):Void
        untyped __cpp__("glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (char*)0+{5})", _index, _size, _type, _normalized, _stride, _offset);
    
    @:native("glVertexAttribDivisor")
    public static function vertexAttribDivisor(_index:Int, _divisor:Int):Void;

    @:native("glEnableVertexAttribArray")
    public static function enableVertexAttribArray(_index:Int):Void;

    @:native("glDisableVertexAttribArray")
    public static function disableVertexAttribArray(_index:Int):Void;

    @:native("glTexParameteri")
    public static function texParameteri(_target:Int, _pname:Int, _param:Int):Void;

    @:native("glClearDepth")
    public static function clearDepth(_depth:Float):Void;

    @:native("glClearColor")
    public static function clearColor(_r:Float, _g:Float, _b:Float, _a:Float):Void;

    @:native("glClear")
    public static function clear(_mask:Int):Void;

    inline public static function createTexture():Int {
        var buf:cpp.UInt32 = -1;
        untyped __cpp__("glGenTextures(1, &{0})", buf);
        return buf;
    }

    inline public static function texImage2D(_target:Int, _mipLevel:Int, _format:Int, _width:Int, _height:Int, _border:Int, _inputFormat:Int, _inputType:Int, _data:BytesData):Void {
        var tmp = _data;
        untyped __cpp__("glTexImage2D({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}==null()?NULL:(const void*)&({8}[0]))", 
            _target, _mipLevel, _format, _width, _height, _border, _inputFormat, _inputType, tmp);
    }

    inline public static function compressedTexImage2D(_target:Int, _mipLevel:Int, _format:Int, _width:Int, _height:Int, _border:Int, _imageSize:Int, _data:BytesData):Void {
        var tmp = _data;
        untyped __cpp__("glCompressedTexImage2D({0}, {1}, {2}, {3}, {4}, {5}, {6}, (const void*)&({7}[0]))", 
            _target, _mipLevel, _format, _width, _height, _border, _imageSize, tmp);
    }

    @:native("glGenerateMipmap")
    public static function generateMipmap(_target:Int):Void;

    inline public static function deleteTexture(_handle:Int):Void {
        var tmp:cpp.UInt32 = _handle;
        untyped __cpp__("glDeleteTextures(1, &{0})", tmp);
    }

    @:native("glCreateShader")
    public static function createShader(_type:Int):Int;

    @:native("glDeleteShader")
    public static function deleteShader(_handle:Int):Void;

    @:native("glCompileShader")
    public static function compileShader(_handle:Int):Void;

    inline public static function shaderSource(_handle:Int, _src:String):Void
        untyped __cpp__("glShaderSource({0}, 1, (const char**)&{1}, NULL)", _handle, cpp.NativeString.c_str(_src));

    inline public static function getShaderiv(_handle:Int, _pname:Int):Int {
        var tmp:cpp.Int32 = 0;
        untyped __cpp__("glGetShaderiv({0}, {1}, &{2})", _handle, _pname, tmp);
        return tmp;
    }

    inline public static function getShaderInfoLog(_handle:Int):String {
        var res = "";
        var ilLength:Int = getShaderiv(_handle, 0x8B84);
        if (ilLength > 1) {
            var cWritten:cpp.Int32 = 0;
            var iLog:cpp.RawPointer<cpp.Char> = untyped __cpp__("new char[{0}]", ilLength);
            untyped __cpp__('glGetShaderInfoLog({0}, {1}, &{2}, (char*){3});', _handle, ilLength, cWritten, iLog);
            res = untyped __cpp__("::String({0})", iLog);
            untyped __cpp__("delete[] {0}; {0} = NULL", iLog);
        }
        return res;
    }

    @:native("glCreateProgram")
    public static function createProgram():Int;

    @:native("glDeleteProgram")
    public static function deleteProgram(_handle:Int):Void;

    @:native("glLinkProgram")
    public static function linkProgram(_handle:Int):Void;

    inline public static function getProgramiv(_handle:Int, _pname:Int):Int {
        var tmp:cpp.Int32 = 0;
        untyped __cpp__("glGetProgramiv({0}, {1}, &{2})", _handle, _pname, tmp);
        return tmp;
    }

    inline public static function getProgramInfoLog(_handle:Int):String {
        var res = "";
        var ilLength:Int = getProgramiv(_handle, 0x8B84);
        if (ilLength > 1) {
            var cWritten:cpp.Int32 = 0;
            var iLog:cpp.RawPointer<cpp.Char> = untyped __cpp__("new char[{0}]", ilLength);
            untyped __cpp__('glGetProgramInfoLog({0}, {1}, &{2}, (char*){3});', _handle, ilLength, cWritten, iLog);
            res = untyped __cpp__("::String({0})", iLog);
            untyped __cpp__("delete[] {0}; {0} = NULL", iLog);
        }
        return res;
    }

    @:native("glAttachShader")
    public static function attachShader(_prog:Int, _shader:Int):Void;

    inline public static function getActiveAttrib(_program:Int, _index:Int, _value:RDIUniformInfo):Void {
        var maxLength = getProgramiv(_program, 0x8B8A);
        var name:cpp.RawPointer<cpp.Char> = untyped __cpp__("new char[{0}]", maxLength);
        var size:cpp.UInt32 = 0;
        var type:cpp.UInt32 = 0;
        untyped __cpp__("glGetActiveAttrib({0}, {1}, {2}, NULL, (int*)&{3}, &{4}, (char*){5})", _program, _index, maxLength, size, type, name);
        _value.name = untyped __cpp__("::String({0})", name);
        _value.type = type;
        untyped __cpp__("delete[] {0}; {0} = NULL", name);
    }

    @:native("glGetAttribLocation")
    public static function getAttribLocation(_prog:Int, _name:String):Int;

    @:native("glUseProgram")
    public static function useProgram(_handle:Int):Void;

    inline public static function getActiveUniform(_program:Int, _index:Int, _value:RDIUniformInfo):Void {
        var maxLength = getProgramiv(_program, 0x8B87);
        var name:cpp.RawPointer<cpp.Char> = untyped __cpp__("new char[{0}]", maxLength);
        var size:cpp.UInt32 = 0;
        var type:cpp.UInt32 = 0;
        untyped __cpp__("glGetActiveUniform({0}, {1}, {2}, NULL, (int*)&{3}, &{4}, (char*){5})", _program, _index, maxLength, size, type, name);
        _value.name = untyped __cpp__("::String({0})", name);
        _value.type = type;
        untyped __cpp__("delete[] {0}; {0} = NULL", name);
    }

    @:native("glGetUniformLocation")
    public static function getUniformLocation(_prog:Int, _name:String):Int;

    inline static function uniform1fv(_loc:Int, _count:Int, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniform1fv({0}, {1}, (const GLfloat*)&({2}[0]))", _loc, _count, tmp);
    }

    inline static function uniform1iv(_loc:Int, _count:Int, _value:Array<Int>):Void
        untyped __cpp__("glUniform1iv({0}, {1}, (const GLint*)&({2}[0]))", _loc, _count, _value);

    inline static function uniform2fv(_loc:Int, _count:Int, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniform2fv({0}, {1}, (const GLfloat*)&({2}[0]))", _loc, _count, tmp);
    }

    inline static function uniform2iv(_loc:Int, _count:Int, _value:Array<Int>):Void
        untyped __cpp__("glUniform2iv({0}, {1}, (const GLint*)&({2}[0]))", _loc, _count, _value);

    inline static function uniform3fv(_loc:Int, _count:Int, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniform3fv({0}, {1}, (const GLfloat*)&({2}[0]))", _loc, _count, tmp);
    }

    inline static function uniform3iv(_loc:Int, _count:Int, _value:Array<Int>):Void
        untyped __cpp__("glUniform3iv({0}, {1}, (const GLint*)&({2}[0]))", _loc, _count, _value);

    inline static function uniform4fv(_loc:Int, _count:Int, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniform4fv({0}, {1}, (const GLfloat*)&({2}[0]))", _loc, _count, tmp);
    }

    inline static function uniform4iv(_loc:Int, _count:Int, _value:Array<Int>):Void
        untyped __cpp__("glUniform4iv({0}, {1}, (const GLint*)&({2}[0]))", _loc, _count, _value);

    inline static function uniformMatrix3fv(_loc:Int, _transpose:Bool, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniformMatrix3fv({0}, {1}, {2}, (const GLfloat*)&({3}[0]))", _loc, tmp.length/9, _transpose, tmp);
    }

    inline static function uniformMatrix4fv(_loc:Int, _transpose:Bool, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniformMatrix4fv({0}, {1}, {2}, (const GLfloat*)&({3}[0]))", _loc, tmp.length/16, _transpose, tmp);
    }

    inline static function uniformMatrix2x4fv(_loc:Int, _transpose:Bool, _value:Array<Float>):Void {
        var tmp:Array<cpp.Float32> = cast _value;
        untyped __cpp__("glUniformMatrix2x4fv({0}, {1}, {2}, (const GLfloat*)&({3}[0]))", _loc, tmp.length/8, _transpose, tmp);
    }

    @:native("glUniform1i")
    public static function uniform1i(_loc:Int, _data:Int):Void;

    inline public static function drawElements(_primType:Int, _type:Int, _numInds:Int, _offset:Int):Void
        untyped __cpp__("glDrawElements({0}, {1}, {2}, (const void*)({3}))", _primType, _numInds, _type, _offset);

    @:native("glDrawArrays")
    public static function drawArrays(_primType:Int, _offset:Int, _size:Int):Void;

    inline public static function drawElementsInstanced(_primType:Int, _type:Int, _numInds:Int, _offset:Int, _primCount:Int):Void
        untyped __cpp__("glDrawElementsInstanced({0}, {1}, {2}, (const void*)({3}), {4})", 
            _primType, _numInds, _type, _offset, _primCount);

    @:native("glDrawArraysInstanced")
    public static function drawArraysInstanced(_primType:Int, _offset:Int, _size:Int, _primCount:Int):Void;

    inline public static function getIntegerv(_target:Int):Int {
        var res:cpp.Int32 = 0;
        untyped __cpp__("glGetIntegerv({0}, &{1})", _target, res);
        return res;
    }

    inline public static function genFramebuffer():Int {
        var buf:cpp.UInt32 = 0;
        untyped __cpp__("glGenFramebuffers(1, &{0})", buf);
        return buf;
    }

    inline public static function genRenderbuffer():Int {
        var buf:cpp.UInt32 = 0;
        untyped __cpp__("glGenRenderbuffers(1, &{0})", buf);
        return buf;
    }

    @:native("glBindFramebuffer")
    public static function bindFramebuffer(_mode:Int, _target:Int):Void;

    @:native("glBindRenderbuffer")
    public static function bindRenderbuffer(_mode:Int, _target:Int):Void;

    inline public static function framebufferTexture2D(_attachment:Int, _tex:Int):Void 
        untyped __cpp__("glFramebufferTexture2D(GL_FRAMEBUFFER, {0}, GL_TEXTURE_2D, {1}, 0)", _attachment, _tex);

    inline public static function renderbufferStorageMultisample(_samples:Int, _format:Int, _width:Int, _height:Int):Void
        untyped __cpp__("glRenderbufferStorageMultisample(GL_RENDERBUFFER, {0}, {1}, {2}, {3})", _samples, _format, _width, _height);

    inline public static function framebufferRenderbuffer(_attachment:Int, _target:Int):Void
        untyped __cpp__("glFramebufferRenderbuffer(GL_FRAMEBUFFER, {0}, GL_RENDERBUFFER, {1})", _attachment, _target);

    @:native("glDrawBuffer")
    public static function drawBuffer(_mode:Int):Void;

    inline public static function drawBuffers(_numColBufs:Int):Void
        untyped __cpp__("glDrawBuffers({0}, foo3d::color_buffers)", _numColBufs);

    @:native("glReadBuffer")
    public static function readBuffer(_mode:Int):Void;

    inline public static function checkFramebufferStatus():Int 
        return untyped __cpp__("glCheckFramebufferStatus(GL_FRAMEBUFFER)");

    inline public static function deleteRenderbuffer(_handle:Int):Void {
        var tmp:cpp.UInt32 = _handle;
        untyped __cpp__("glDeleteRenderbuffers(1, &{0})", tmp);
    }

    inline public static function deleteFramebuffer(_handle:Int):Void {
        var tmp:cpp.UInt32 = _handle;
        untyped __cpp__("glDeleteFramebuffers(1, &{0})", tmp);
    }

    inline public static function blitFramebuffer(_width:Int, _height:Int, _mask:Int):Void 
        untyped __cpp__("glBlitFramebuffer(0,0,{0},{1},0,0,{0},{1},{2},GL_NEAREST)", _width, _height, _mask);

    @:native("glViewport")
    public static function viewport(_x:Int, _y:Int, _width:Int, _height:Int):Void;

    @:native("glScissor")
    public static function scissor(_x:Int, _y:Int, _width:Int, _height:Int):Void;

    @:native("glEnable")
    public static function enable(_cap:Int):Void;

    @:native("glDisable")
    public static function disable(_cap:Int):Void;

    @:native("glCullFace")
    public static function cullFace(_mode:Int):Void;

    @:native("glDepthFunc")
    public static function depthFunc(_func:Int):Void;

    @:native("glBlendFunc")
    public static function blendFunc(_src:Int, _dst:Int):Void;

    @:native("glDepthMask")
    public static function depthMask(_flag:Bool):Void;

    @:native("glBlendEquation")
    public static function blendEquation(_mode:Int):Void;

    @:native("glBlendEquationi")
    public static function blendEquationBuffer(_buffer:Int, _mode:Int):Void;

    inline public static var VENDOR:Int =      0x1F00;
    inline public static var RENDERER:Int =    0x1F01;
    inline public static var VERSION:Int =     0x1F02;
    inline public static var EXTENSIONS:Int =  0x1F03;

    inline public static var ARRAY_BUFFER_BINDING:Int = 0x8894;
    inline public static var ELEMENT_ARRAY_BUFFER_BINDING:Int = 0x8895;
    inline public static var BYTE:Int = 0x1400;
    inline public static var UNSIGNED_BYTE:Int = 0x1401;
    inline public static var UNSIGNED_SHORT:Int = 0x1403;
    inline public static var FLOAT:Int = 0x1406;
    inline public static var RED:Int = 0x1903;    
    inline public static var RGB:Int = 0x1907;    
    inline public static var RGBA:Int = 0x1908;
    inline public static var CULL_FACE:Int = 0x0B44;
    inline public static var DEPTH_TEST:Int = 0x0B71;
    inline public static var SCISSOR_TEST:Int = 0x0C11;
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
    inline public static var DEPTH_STENCIL_ATTACHMENT:Int = 0x821A;
    inline public static var DEPTH24_STENCIL8:Int = 0x88F0;
    inline public static var DEPTH_STENCIL:Int = 0x84F9;
    inline public static var UNSIGNED_INT_24_8:Int = 0x84FA;
    inline public static var COMPRESSED_RED_RGTC1:Int = 0x8DBB;
    inline public static var COMPRESSED_SIGNED_RED_RGTC1:Int = 0x8DBC;
    inline public static var COMPRESSED_RG_RGTC2:Int = 0x8DBD;
    inline public static var COMPRESSED_SIGNED_RG_RGTC2:Int = 0x8DBE;
    inline public static var COMPRESSED_RGBA_BPTC_UNORM:Int = 0x8E8C;
    inline public static var COMPRESSED_SRGB_ALPHA_BPTC_UNORM:Int = 0x8E8D;
    inline public static var COMPRESSED_RGB_BPTC_SIGNED_FLOAT:Int = 0x8E8E;
    inline public static var COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT:Int = 0x8E8F;
    inline public static var COMPRESSED_RGB8_ETC2:Int = 0x9274;
    inline public static var COMPRESSED_SRGB8_ETC2:Int = 0x9275;
    inline public static var COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2:Int = 0x9276;
    inline public static var COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:Int = 0x9277;
    inline public static var COMPRESSED_RGBA8_ETC2_EAC:Int = 0x9278;
    inline public static var COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:Int = 0x9279;
    inline public static var COMPRESSED_R11_EAC:Int = 0x9270;
    inline public static var COMPRESSED_SIGNED_R11_EAC:Int = 0x9271;
    inline public static var COMPRESSED_RG11_EAC:Int = 0x9272;
    inline public static var COMPRESSED_SIGNED_RG11_EAC:Int = 0x9273;
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
}