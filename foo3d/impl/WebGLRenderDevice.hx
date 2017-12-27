package foo3d.impl;

import foo3d.RenderDevice;

#if js

import js.html.webgl.RenderingContext;
import js.html.Float32Array;
import js.html.Uint8Array;
import js.html.Uint16Array;
import js.html.ArrayBuffer;
import js.html.webgl.Shader;
import js.html.webgl.Program;
import js.html.webgl.ActiveInfo;

class WebGLRenderDevice extends AbstractRenderDevice
{
    var isWebGL2:Bool = false;
    
    var instancedExtANGLE:Dynamic;

    public function new(_ctx:RenderContext)
    {
        super(_ctx);
    }
    
    override function init():Void
    {   
        var version = m_ctx.getParameter(RenderingContext.VERSION);
        isWebGL2 = version.indexOf("WebGL 2") != -1;

        trace("[Foo3D] - " + version + " // " + 
              m_ctx.getParameter(RenderingContext.SHADING_LANGUAGE_VERSION) + " // " + 
              m_ctx.getParameter(RenderingContext.VENDOR));

        // set default capabilities
        m_caps.texFloatSupport = false;
        m_caps.texNPOTSupport = true;
        m_caps.rtMultisampling = false;
        m_caps.drawInstancedSupport = false;

        m_caps.maxVertAttribs = m_ctx.getParameter(RenderingContext.MAX_VERTEX_ATTRIBS);
        m_caps.maxVertUniforms = m_ctx.getParameter(RenderingContext.MAX_VERTEX_UNIFORM_VECTORS);
        m_caps.maxTextureUnits = m_ctx.getParameter(RenderingContext.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
        m_caps.maxColorAttachments = 1;
        

        var supportedExtensions:Array<String> = m_ctx.getSupportedExtensions();
        var e:String = "[Foo3D] - Supported extensions by browser:\n";
        for (s in supportedExtensions) {
            e += s + "\n";
            m_ctx.getExtension(s); // TODO: HACK!!!
        }

        // check for further caps
        if (isWebGL2) {
            m_caps.texFloatSupport = true;
            m_caps.drawInstancedSupport = true;
        } else {
            m_caps.texFloatSupport = m_ctx.getExtension("OES_texture_float") == null ? false : true;

            instancedExtANGLE = m_ctx.getExtension("ANGLE_instanced_arrays");
            if (instancedExtANGLE != null)
                m_caps.drawInstancedSupport = true;
        }

        trace(m_caps.toString());
        trace(e);
    }

    override public function createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = -1):Int
    {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.VERTEX, 
            m_ctx.createBuffer(), 
            _size, 
            _usageHint);

        m_ctx.bindBuffer(buf.type, buf.glObj);
        m_ctx.bufferData(buf.type, _data, _usageHint);
        m_ctx.bindBuffer(buf.type, null);
        
        m_bufferMem += buf.size;

        return m_buffers.add( buf );
    }

    override public function createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int 
    {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.INDEX, 
            m_ctx.createBuffer(), 
            _size, 
            _usageHint);

        m_ctx.bindBuffer(buf.type, buf.glObj);
        m_ctx.bufferData(buf.type, _data, _usageHint);
        m_ctx.bindBuffer(buf.type, null);
        
        m_bufferMem += buf.size;
        return m_buffers.add( buf );
    }

    override public function destroyBuffer(_handle:Int):Void
    {
        if (_handle == 0) return;
        
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        m_ctx.deleteBuffer(buf.glObj);
        
        m_bufferMem -= buf.size;
        m_buffers.remove(_handle);
    }

    override public function updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        m_ctx.bindBuffer(buf.type, buf.glObj);
        m_ctx.bufferSubData(buf.type, _offset, _data);
        m_ctx.bindBuffer(buf.type, null);
    }
    
    override public function updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        m_ctx.bindBuffer(buf.type, buf.glObj);
        m_ctx.bufferSubData(buf.type, _offset, _data);
        
        if(m_curIndexBuf != 0) // rebind the old one
            m_ctx.bindBuffer(buf.type, m_buffers.getRef(m_curIndexBuf).glObj);
        else
            m_ctx.bindBuffer(buf.type, null);
    }

    override public function createTexture(_type:Int, _width:Int, _height:Int, _format:Int, _hasMips:Bool, _genMips:Bool, _isCompressed:Bool):Int
    {
        var tex = new RDITexture();
        tex.type = _type;
        tex.format = _format;
        tex.width = _width;
        tex.height = _height;
        tex.genMips = _genMips;
        tex.hasMips = _hasMips;
        tex.isCompressed = _isCompressed;
        tex.glFmt = _format;

        tex.glObj = m_ctx.createTexture();
        m_ctx.activeTexture(RenderingContext.TEXTURE0+m_lastTexUnit);
        m_ctx.bindTexture(_type, tex.glObj);

        tex.samplerState = 0;
        applySamplerState(tex);

        m_ctx.bindTexture(_type, null);
        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
            m_ctx.bindTexture(t.type, t.glObj);
        }
        
        tex.memSize = calcTextureSize(tex.format, _width, _height);
        if (_hasMips || _genMips) 
            tex.memSize += Std.int(tex.memSize * 1.0 / 3.0);
        if (_type == RDITextureTypes.TEXCUBE)
            tex.memSize *= 6;

        m_textureMem += tex.memSize;

        return m_textures.add( tex );
    }

    override public function uploadTextureData(_handle:Int, _slice:Int, _mipLevel:Int, _pixels:PixelData, ?_formatOverride:Int=0, ?_typeOverride:Int=0, ?_imageSize:Int=0):Void
    {
        var tex:RDITexture = m_textures.getRef(_handle);

        m_ctx.activeTexture(RenderingContext.TEXTURE0+m_lastTexUnit);
        m_ctx.bindTexture(tex.type, tex.glObj);

        m_ctx.pixelStorei(RenderingContext.UNPACK_FLIP_Y_WEBGL, 0);

        // RGBA8
        var inputFormat:Int = RenderContext.RGBA;
        var inputType:Int = RenderContext.UNSIGNED_BYTE;

        if (_formatOverride != 0) {
            inputFormat = _formatOverride;
        } else {
            switch (tex.format)
            {
                case RDITextureFormats.RGB8:
                    inputFormat = RenderContext.RGB;
                case RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F:
                    inputFormat = RenderContext.RGBA;
                    inputType = RenderContext.FLOAT;
                case RDITextureFormats.DEPTH:
                    inputFormat = RenderContext.DEPTH_COMPONENT;
                    inputType = RenderContext.FLOAT;
            }
        }

        if (_typeOverride != 0) {
            inputType = _typeOverride;
        } else {
            switch (tex.format)
            {
                case RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F:
                    inputType = RenderContext.FLOAT;
                case RDITextureFormats.DEPTH:
                    inputType = RenderContext.FLOAT;
            }
        }

        // Calculate size of next mipmap using "floor" convention
        var width:Int = Std.int(Math.max(tex.width >> _mipLevel, 1));
        var height:Int = Std.int(Math.max(tex.height >> _mipLevel, 1));

        var target:Int = (tex.type == RDITextureTypes.TEX2D) ? 
            RenderContext.TEXTURE_2D : (RenderContext.TEXTURE_CUBE_MAP_POSITIVE_X + _slice);

        if (_pixels == null) // we wanna upload an empty buffer
            m_ctx.texImage2D(target, _mipLevel, inputFormat, width, height, 0, inputFormat, inputType, null);
        else
            if (tex.isCompressed == true) {
                if (inputType == RenderContext.FLOAT)
                    m_ctx.compressedTexImage2D(target, _mipLevel, inputFormat, width, height, 0, new js.html.Float32Array(_pixels));
                else
                    m_ctx.compressedTexImage2D(target, _mipLevel, inputFormat, width, height, 0, new js.html.Uint8Array(_pixels));
            }
            else {
                if (inputType == RenderContext.FLOAT)
                    m_ctx.texImage2D(target, _mipLevel, inputFormat, width, height, 0, inputFormat, inputType, new js.html.Float32Array(_pixels));
                else
                    m_ctx.compressedTexImage2D(target, _mipLevel, inputFormat, width, height, 0, new js.html.Uint8Array(_pixels));
            }

        // Note: for cube maps mips are only generated when the side with the highest index is uploaded
        if (tex.genMips && (tex.type != RDITextureTypes.TEXCUBE || _slice == 5)) {
            m_ctx.generateMipmap(tex.type);
        }

        m_ctx.bindTexture(tex.type, null);

        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
            m_ctx.bindTexture(t.type, t.glObj);
        }
    }

    override public function destroyTexture(_handle:Int):Void 
    {
        if (_handle == 0) return;
        
        var tex:RDITexture = m_textures.getRef(_handle);
        m_ctx.deleteTexture(tex.glObj);
        
        m_textureMem -= tex.memSize;
        m_textures.remove(_handle);
    }

    override public function createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int
    {
        // create shaders
        var vs:Shader = m_ctx.createShader(RenderContext.VERTEX_SHADER);
        m_ctx.shaderSource(vs, _vertexShaderSrc);
        m_ctx.compileShader(vs);
        var success:Bool = m_ctx.getShaderParameter(vs, RenderContext.COMPILE_STATUS);
        if (!success && !m_ctx.isContextLost())
        {
            trace("[Vertex Shader] " + m_ctx.getShaderInfoLog(vs));
            trace("[Vertex Shader Source] " + _vertexShaderSrc);
            m_ctx.deleteShader(vs);
            return 0;
        }

        var fs:Shader = m_ctx.createShader(RenderContext.FRAGMENT_SHADER);
        m_ctx.shaderSource(fs, _fragmentShaderSrc);
        m_ctx.compileShader(fs);
        var success:Bool = m_ctx.getShaderParameter(fs, RenderContext.COMPILE_STATUS);
        if (!success && !m_ctx.isContextLost())
        {
            trace("[Fragment Shader] " + m_ctx.getShaderInfoLog(fs));
            trace("[Fragment Shader Source] " + _fragmentShaderSrc);
            m_ctx.deleteShader(vs);
            m_ctx.deleteShader(fs);
            return 0;
        }

        // create program
        var prog:Program = m_ctx.createProgram();
        m_ctx.attachShader(prog, vs);
        m_ctx.attachShader(prog, fs);
        m_ctx.deleteShader(vs);
        m_ctx.deleteShader(fs);

        // link program
        m_ctx.linkProgram(prog);
        success = m_ctx.getProgramParameter(prog, RenderContext.LINK_STATUS);
        if (!success && !m_ctx.isContextLost())
        {
            trace("[LINKING] " + m_ctx.getProgramInfoLog(prog));
            m_ctx.deleteProgram(prog);
            return 0;
        }

        var shader:RDIShaderProgram = new RDIShaderProgram();
        shader.oglProgramObj = prog;
        var attribCount:Int = m_ctx.getProgramParameter(prog, RenderContext.ACTIVE_ATTRIBUTES);

        for (i in 0...m_numVertexLayouts)
        {
            var vl:RDIVertexLayout = m_vertexLayouts[i];
            var allAttribsFound:Bool = true;

            for (j in 0...16)
                shader.inputLayouts[i].attribIndices[j] = -1;

            for (j in 0...attribCount)
            {
                var info:ActiveInfo = m_ctx.getActiveAttrib(prog, j);

                var attribFound:Bool = false;
                for (k in 0...vl.numAttribs)
                {
                    if (vl.attribs[k].semanticName == info.name)
                    {
                        shader.inputLayouts[i].attribIndices[k] = m_ctx.getAttribLocation(prog, info.name);
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
        m_ctx.deleteProgram(shader.oglProgramObj);
        m_shaders.remove(_handle);
    }

    override public function bindProgram(_handle:Int):Void
    {
        if (m_curShaderId != _handle) {
            if (_handle != 0)
            {
                var shader:RDIShaderProgram = m_shaders.getRef(_handle);
                m_ctx.useProgram(shader.oglProgramObj);
            }
            else
                m_ctx.useProgram(null);

            m_curShaderId = _handle;
            m_pendingMask |= ARD.PM_VERTLAYOUT;
        }
    }

    override public function getActiveUniformCount(_handle:Int):Int 
    { 
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return m_ctx.getProgramParameter(shader.oglProgramObj, RenderContext.ACTIVE_UNIFORMS);
    }

    override public function getActiveUniformInfo(_handle:Int, _index:Int):RDIUniformInfo 
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        var res:RDIUniformInfo = new RDIUniformInfo();
        var info:ActiveInfo = m_ctx.getActiveUniform(shader.oglProgramObj, _index);
        res.name = info.name;
        res.type = info.type;
        return res;        
    }

    override public function getUniformLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return m_ctx.getUniformLocation(shader.oglProgramObj, _name);
    }

    override public function getSamplerLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return m_ctx.getUniformLocation(shader.oglProgramObj, _name);
    }

    override public function setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void 
    { 
        switch (_type)
        {   // TODO: optimize (http://learningwebgl.com/blog/?p=1606)
            case RDIShaderConstType.FLOAT: m_ctx.uniform1fv(_loc, new Float32Array(untyped _values));
            case RDIShaderConstType.FLOAT2: m_ctx.uniform2fv(_loc, new Float32Array(untyped _values));
            case RDIShaderConstType.FLOAT3: m_ctx.uniform3fv(_loc, new Float32Array(untyped _values));
            case RDIShaderConstType.FLOAT4: m_ctx.uniform4fv(_loc, new Float32Array(untyped _values));
            case RDIShaderConstType.FLOAT3x3: m_ctx.uniformMatrix3fv(_loc, false, new Float32Array(untyped _values));
            case RDIShaderConstType.FLOAT4x4: m_ctx.uniformMatrix4fv(_loc, false, new Float32Array(untyped _values));
            case RDIShaderConstType.FLOAT2x4: untyped m_ctx.uniformMatrix2x4fv(_loc, false, new Float32Array(untyped _values));
        }
    }

    override public function setSampler(_loc:UniformLocationType, _texUnit:Int):Void 
    {
        m_ctx.uniform1i( _loc, _texUnit );        
    }

    override public function createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int 
    { 
        if (_format == RDITextureFormats.RGBA16F || _numColBufs > m_caps.maxColorAttachments)
            return 0;

        var rb:RDIRenderBuffer = new RDIRenderBuffer(_numColBufs);
        rb.width = _width;
        rb.height = _height;
        rb.fbo = m_ctx.createFramebuffer();

        // Attach color buffers
        if (_numColBufs > 0)
        {
            for(j in 0..._numColBufs)
            {
                m_ctx.bindFramebuffer(RenderContext.FRAMEBUFFER, rb.fbo);
                // create the color texture
                var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, _format, false, false, true);
                this.uploadTextureData(texObj, 0, 0, null);
                rb.colTexs[j] = texObj;
                var tex:RDITexture = m_textures.getRef(texObj);
                // attach to framebuffer
                m_ctx.framebufferTexture2D(RenderContext.FRAMEBUFFER, RenderContext.COLOR_ATTACHMENT0 + j, RenderContext.TEXTURE_2D, tex.glObj, 0);
            }
        }
        // attach depth buffer
        if (_depth)
        {
            m_ctx.bindFramebuffer(RenderContext.FRAMEBUFFER, rb.fbo);
            // create the depth buffer
            rb.depthBufObj = m_ctx.createRenderbuffer();
            m_ctx.bindRenderbuffer(RenderContext.RENDERBUFFER, rb.depthBufObj);
            m_ctx.renderbufferStorage(RenderContext.RENDERBUFFER, RenderContext.DEPTH_COMPONENT16, rb.width, rb.height);
            // attach it
            m_ctx.framebufferRenderbuffer(RenderContext.FRAMEBUFFER, RenderContext.DEPTH_ATTACHMENT, RenderContext.RENDERBUFFER, rb.depthBufObj);
        }

        var rbObj:Int = m_renBuffers.add(rb);

        // validate fbo
        var status:Int = m_ctx.checkFramebufferStatus(RenderContext.FRAMEBUFFER);
        switch(status)
        {
            case RenderContext.FRAMEBUFFER_UNSUPPORTED: throw "Framebuffer is not supported";
            case RenderContext.FRAMEBUFFER_INCOMPLETE_ATTACHMENT: throw "Framebuffer incomplete attachment";
            case RenderContext.FRAMEBUFFER_INCOMPLETE_DIMENSIONS: throw "Framebuffer incomplete dimensions";
            case RenderContext.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: throw "Framebuffer incomplete missing attachment";
        }
        if (status != RenderContext.FRAMEBUFFER_COMPLETE)
        {
            this.destroyRenderBuffer(rbObj);
            return 0;
        }
        return rbObj;
    }

    override public function destroyRenderBuffer(_handle:Int):Void 
    {
        var rb = m_renBuffers.getRef(_handle);
        if (rb.depthBufObj != null) 
            m_ctx.deleteRenderbuffer(rb.depthBufObj);
        rb.depthBufObj = null;

        for (i in 0...m_caps.maxColorAttachments)
        {
            if (rb.colTexs[i] != 0) 
                this.destroyTexture(rb.colTexs[i]);
            rb.colTexs[i] = 0;
        }

        if (rb.fbo != null)
            m_ctx.deleteFramebuffer(rb.fbo);
        rb.fbo = null;

        m_renBuffers.remove(_handle);
    }

    override public function getRenderBufferTex(_handle:Int, ?_bufIndex:Int=0):Int
    {
        var rb = m_renBuffers.getRef(_handle);
        if (_bufIndex < m_caps.maxColorAttachments)
            return rb.colTexs[_bufIndex];
        else
            return 0;
    }

    override public function bindRenderBuffer(_handle:Int):Void
    {
        m_curRenderBuffer = _handle;

        if (_handle == 0)
        {
            // set to main backbuffer
            m_ctx.bindFramebuffer(RenderContext.FRAMEBUFFER, null);
        }
        else
        {
            // reset all texture bindings
            for (i in 0...m_caps.maxTextureUnits)
                this.setTexture(i, 0, 0);
            this.commitStates(ARD.PM_TEXTURES);

            var rb = m_renBuffers.getRef(_handle);

            m_ctx.bindFramebuffer(RenderContext.FRAMEBUFFER, rb.fbo);
        }
    }

    override public function getRenderBufferData(_handle:Int, ?_bufIndex:Int=0):RDIRenderBufferData
    {
        var res:RDIRenderBufferData = {width:0, height:0, data:null};
        var x:Int = 0;
        var y:Int = 0;
        var w:Int = 0;
        var h:Int = 0;

        var format:Int = RenderContext.RGBA;
        var type:Int = RenderContext.UNSIGNED_BYTE;

        if (_handle == 0)
        {
            // read from backbuffer
            res.width = w = m_vpWidth;
            res.height = h = m_vpHeight;
            x = m_vpX;
            y = m_vpY;

            m_ctx.bindFramebuffer(RenderContext.FRAMEBUFFER, null);
        }
        else
        {
            var rb = m_renBuffers.getRef(_handle);
            if (_bufIndex >= m_caps.maxColorAttachments || rb.colTexs[_bufIndex] == 0)
                return null;
            res.width = w = rb.width;
            res.height = h = rb.height;

            m_ctx.bindFramebuffer(RenderContext.FRAMEBUFFER, rb.fbo);
        }

        m_ctx.finish();
        res.data = cast new js.html.Uint8ClampedArray(w * h);
        m_ctx.readPixels(x, y, w, h, format, type, cast res.data);
        return res;
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
        for (i in 0...vl.numAttribs)
        {
            var attribIndex:Int = inputLayout.attribIndices[i];
            if (attribIndex >= 0)
            {
                var attrib:RDIVertexLayoutAttrib = vl.attribs[i];
                var vbSlot:RDIVertBufSlot = m_vertBufSlots[attrib.vbSlot];

                m_ctx.bindBuffer(RenderingContext.ARRAY_BUFFER, m_buffers.getRef(vbSlot.vbObj).glObj);
                m_ctx.vertexAttribPointer(
                    attribIndex, 
                    attrib.size, 
                    attrib.type, 
                    false, 
                    vbSlot.stride, 
                    vbSlot.offset + attrib.offset
                );

                if (m_caps.drawInstancedSupport)
                    if (isWebGL2)
                        untyped m_ctx.vertexAttribDivisor(attribIndex, attrib.divisor);
                    else
                        instancedExtANGLE.vertexAttribDivisorANGLE(attribIndex, attrib.divisor);
                
                newVertexAttribMask |= 1 << attribIndex;
            }
        }

        for (i in 0...16)
        {
            var curBit:Int = 1 << i;
            if ((newVertexAttribMask & curBit) != (m_activeVertexAttribsMask & curBit))
            {
                if ((newVertexAttribMask & curBit) == curBit)
                    m_ctx.enableVertexAttribArray(i);
                else
                    m_ctx.disableVertexAttribArray(i);
            }
        }
        m_activeVertexAttribsMask = newVertexAttribMask;
        
        return true;
    }

    private static var magFilters:Array<Int>        = [RenderingContext.LINEAR, RenderingContext.LINEAR, RenderingContext.NEAREST];
    private static var minFiltersMips:Array<Int>    = [RenderingContext.LINEAR_MIPMAP_NEAREST, RenderingContext.LINEAR_MIPMAP_LINEAR, RenderingContext.NEAREST_MIPMAP_NEAREST];
    private static var wrapModes:Array<Int>         = [RenderingContext.CLAMP_TO_EDGE, RenderingContext.REPEAT, RenderingContext.MIRRORED_REPEAT];

    override function applySamplerState(_tex:RDITexture):Void
    {
        var state = _tex.samplerState;
        var target = _tex.type;

        if (_tex.hasMips)
            m_ctx.texParameteri(target, RenderingContext.TEXTURE_MIN_FILTER, minFiltersMips[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START]);
        else
            m_ctx.texParameteri(target, RenderingContext.TEXTURE_MIN_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );

        m_ctx.pixelStorei(RenderingContext.UNPACK_FLIP_Y_WEBGL, 1);
        
        m_ctx.texParameteri( target, RenderingContext.TEXTURE_MAG_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        m_ctx.texParameteri( target, RenderingContext.TEXTURE_WRAP_S, wrapModes[(state & AbstractRenderDevice.SS_ADDRU_MASK) >> AbstractRenderDevice.SS_ADDRU_START] );
        m_ctx.texParameteri( target, RenderingContext.TEXTURE_WRAP_T, wrapModes[(state & AbstractRenderDevice.SS_ADDRV_MASK) >> AbstractRenderDevice.SS_ADDRV_START] );
    }

    override public function commitStates(?_filter:Int=0xFFFFFFFF):Bool
    {
        if ((m_pendingMask & _filter) != 0)
        {
            var mask:Int = m_pendingMask & _filter;

            // Set viewport
            if ((mask & ARD.PM_VIEWPORT) == ARD.PM_VIEWPORT)
            {
                m_ctx.viewport(m_vpX, m_vpY, m_vpWidth, m_vpHeight);
                m_pendingMask &= ~ARD.PM_VIEWPORT;
            }

            // Set scissor rect
            if ((mask & ARD.PM_SCISSOR) == ARD.PM_SCISSOR)
            {
                if (m_scissorEnabled && m_scX == m_vpX && m_scY == m_vpY && m_scWidth == m_vpWidth && m_scHeight == m_vpHeight) {
                    m_ctx.disable(RenderingContext.SCISSOR_TEST);
                    m_scissorEnabled = false;
                }
                else if (!m_scissorEnabled) {
                    m_ctx.enable(RenderingContext.SCISSOR_TEST);
                    m_scissorEnabled = true;
                }
                m_ctx.scissor(m_scX, m_scY, m_scWidth, m_scHeight);
                m_pendingMask &= ~ARD.PM_SCISSOR;
            }

            // Cullmode
            if ((mask & ARD.PM_CULLMODE) == ARD.PM_CULLMODE)
            {
                if (m_newCullMode != m_curCullMode)
                {
                    if (m_newCullMode == RDICullModes.NONE)
                        m_ctx.disable(RenderingContext.CULL_FACE);
                    else
                    {
                        m_ctx.enable(RenderingContext.CULL_FACE);
                        m_ctx.cullFace(m_newCullMode);
                    }
                    m_curCullMode = m_newCullMode;
                }
                m_pendingMask &= ~ARD.PM_CULLMODE;
            }

            // Depth Mask
            if ((mask & ARD.PM_DEPTH_MASK) == ARD.PM_DEPTH_MASK) 
            {
                if (m_newDepthMask != m_curDepthMask) {
                    m_ctx.depthMask(m_newDepthMask);
                    m_curDepthMask = m_newDepthMask;
                }
                m_pendingMask &= ~ARD.PM_DEPTH_MASK;
            }

            // Depth Test
            if ((mask & ARD.PM_DEPTH_TEST) == ARD.PM_DEPTH_TEST)
            {
                if (m_newDepthTest != m_curDepthTest)
                {
                    if (m_newDepthTest == RDITestModes.DISABLE)
                    {
                        if (m_depthTestEnabled)
                        {
                            m_ctx.disable(RenderingContext.DEPTH_TEST);
                            m_depthTestEnabled = false;
                        }
                    }
                    else
                    {
                        if (!m_depthTestEnabled)
                        {
                            m_ctx.enable(RenderingContext.DEPTH_TEST);
                            m_depthTestEnabled = true;
                        }

                        m_ctx.depthFunc(m_newDepthTest);
                    }                    

                    m_curDepthTest = m_newDepthTest;
                }                    
                
                m_pendingMask &= ~ARD.PM_DEPTH_TEST;
            }

            // set blendequation
            if((mask & ARD.PM_BLEND_EQ) == ARD.PM_BLEND_EQ)
            {
                if (m_newBlendEq != m_curBlendEq) {

                    //if (m_blendEqBuffer != -1)
                        //hx_gl_blendEquationBuffer(m_blendEqBuffer, m_newBlendEq);
                    //else

                    m_ctx.blendEquation(m_newBlendEq);
                    m_curBlendEq = m_newBlendEq;
                }

                m_pendingMask &= ~ARD.PM_BLEND_EQ;
            }

            // set blending
            if((mask & ARD.PM_BLEND) == ARD.PM_BLEND)
            {
                if (m_newSrcFactor != m_curSrcFactor || m_newDstFactor != m_curDstFactor)
                {
                    if (m_newSrcFactor == RDIBlendFactors.ONE && m_newDstFactor == RDIBlendFactors.ZERO)
                        m_ctx.disable(RenderingContext.BLEND); // replace-function
                    else 
                    {
                        m_ctx.enable(RenderingContext.BLEND);
                        m_ctx.blendFunc(m_newSrcFactor, m_newDstFactor);
                    }
                    
                    m_curSrcFactor = m_newSrcFactor;
                    m_curDstFactor = m_newDstFactor;
                }
                m_pendingMask &= ~ARD.PM_BLEND;
            }

            // Bind textures and set sampler state
            if((mask & ARD.PM_TEXTURES) == ARD.PM_TEXTURES)
            {
                for (i in 0...m_caps.maxTextureUnits)
                {
                    var slot = m_texSlots[i];

                    if (slot.texObj != 0) {
                        m_ctx.activeTexture(RenderingContext.TEXTURE0+i);
                        if (!slot.active) {
                            m_ctx.bindTexture(RDITextureTypes.TEXCUBE, null);
                            m_ctx.bindTexture(RDITextureTypes.TEX2D, null);
                            slot.texObj = 0;
                        } else {                            
                            var tex:RDITexture = m_textures.getRef(slot.texObj);
                            if (tex == null) continue;
                            m_ctx.bindTexture(tex.type, tex.glObj);
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
                //if (m_newIndexBuf != m_curIndexBuf) {
                    if (m_newIndexBuf != 0)
                        m_ctx.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, m_buffers.getRef(m_newIndexBuf).glObj);
                    else
                        m_ctx.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, null);
                    
                    m_curIndexBuf = m_newIndexBuf;
                //}
                m_pendingMask &= ~ARD.PM_INDEXBUF;
            }

            // Bind vertex buffers
            if ((mask & ARD.PM_VERTLAYOUT) == ARD.PM_VERTLAYOUT)
            {
                if (!applyVertexLayout())
                    return false;
                m_prevShaderId = m_curShaderId;
                m_pendingMask &= ~ARD.PM_VERTLAYOUT;
            }
        }
        return true;
    }

    override public function resetStates():Void
    {
        for (i in 0...16)
            m_ctx.disableVertexAttribArray(i);

        super.resetStates();
    }

    override public function isLost():Bool 
    {
        return m_ctx.isContextLost();
    }

    override public function clear(_flags:Int, ?_r:Float = 0, ?_g:Float = 0, ?_b:Float = 0, ?_a:Float = 1, ?_depth:Float = 1):Void
    {
        var mask:Int = 0;
        if ((_flags & RDIClearFlags.DEPTH) == RDIClearFlags.DEPTH)
        {
            mask |= RenderContext.DEPTH_BUFFER_BIT;
            m_ctx.clearDepth(_depth);
            this.setDepthMask(true); // important: glClear(GL.DEPTH_BUFFER_BIT) needs depthmasking to work
        }
        if ((_flags & RDIClearFlags.COLOR) == RDIClearFlags.COLOR)
        {
            mask |= RenderContext.COLOR_BUFFER_BIT;
            m_ctx.clearColor(_r, _g, _b, _a);
        }
        if ((_flags & RDIClearFlags.ALL) == RDIClearFlags.ALL)
        {
            mask |= RenderContext.COLOR_BUFFER_BIT | RenderContext.DEPTH_BUFFER_BIT | RenderContext.STENCIL_BUFFER_BIT;
        }
        if (mask != 0)
        {
            commitStates( ARD.PM_VIEWPORT | ARD.PM_SCISSOR | ARD.PM_DEPTH_MASK );
            m_ctx.clear(mask);
        }
    }

    override public function draw(_primType:Int, _type:Int, _numInds:Int, _offset:Int):Void
    {   
        if (commitStates())
            m_ctx.drawElements(_primType, _numInds, _type, _offset);
    }

    override public function drawArrays(_primType:Int, _offset:Int, _size:Int):Void
    {
        if (commitStates())
            m_ctx.drawArrays(_primType, _offset, _size);
    }

    override public function drawInstanced(_primType:Int, _type:Int, _numInds:Int, _offset:Int, _primCount:Int):Void {
        if (!m_caps.drawInstancedSupport)
            trace("[Foo3D - WARNING] - Instanced drawing is not supported!");
        else 
            if (commitStates()) {
                if (isWebGL2)
                    untyped m_ctx.drawElementsInstanced(_primType, _type, _numInds, _offset, _primCount);
                else
                    instancedExtANGLE.drawElementsInstancedANGLE(_primType, _type, _numInds, _offset, _primCount);
            }
    }

    override public function drawArraysInstanced(_primType:Int, _offset:Int, _size:Int, _primCount:Int):Void {
        if (!m_caps.drawInstancedSupport)
            trace("[Foo3D - WARNING] - Instanced drawing is not supported!");
        else
            if (commitStates()) {
                if (isWebGL2)
                    untyped m_ctx.drawArraysInstanced(_primType, _offset, _size, _primCount);
                else
                    instancedExtANGLE.drawArraysInstancedANGLE(_primType, _offset, _size, _primCount);
            }

    }
}

#end
