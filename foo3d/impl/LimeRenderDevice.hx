package foo3d.impl;

import foo3d.RenderDevice;
import lime.utils.Libs;

class LimeRenderDevice extends AbstractRenderDevice
{   
    inline public static var UNSIGNED_BYTE:Int = 0x1401;
    inline public static var UNSIGNED_SHORT:Int = 0x1403;
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
    inline public static var MAX_VERTEX_ATTRIBS:Int = 0x8869;
    inline public static var MAX_VERTEX_UNIFORM_VECTORS:Int = 0x8DFB;
    inline public static var MAX_COLOR_ATTACHMENTS:Int = 0x8CDF;
    inline public static var FRAMEBUFFER_BINDING:Int = 0x8CA6;
    inline public static var MAX_COMBINED_TEXTURE_IMAGE_UNITS:Int = 0x8B4D;

    var _defaultFbo:Int;
 
    public function new(_ctx:RenderContext)
    {
        _defaultFbo = 0;
        super(_ctx);
    }
    
    override function init():Void
    {        
        _defaultFbo = lime_gl_get_parameter(FRAMEBUFFER_BINDING);

        m_caps.texFloatSupport = false;
        m_caps.texNPOTSupport = false;
        m_caps.rtMultisampling = false;

        m_caps.maxVertAttribs = lime_gl_get_parameter(MAX_VERTEX_ATTRIBS);
        m_caps.maxVertUniforms = lime_gl_get_parameter(MAX_VERTEX_UNIFORM_VECTORS);
        m_caps.maxTextureUnits = lime_gl_get_parameter(MAX_COMBINED_TEXTURE_IMAGE_UNITS);
        m_caps.maxColorAttachments = 1;

        var supportedExtensions:Array<String> = new Array<String>();
        lime_gl_get_supported_extensions(supportedExtensions);

        for (s in supportedExtensions) {
            if (s == "GL_ARB_texture_float")
                m_caps.texFloatSupport = true;
            else if (s == "GL_EXT_framebuffer_multisample")
                m_caps.rtMultisampling = true;
            else if (s == "GL_ARB_texture_non_power_of_two")
                m_caps.texNPOTSupport = true;
        }
        trace(m_caps.toString());
    }

    override public function createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = -1):Int
    {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.VERTEX, 
            lime_gl_create_buffer(), 
            _size, 
            _usageHint);

        lime_gl_bind_buffer(buf.type, buf.glObj);
        lime_gl_buffer_data(buf.type, lime.utils.ByteArray.fromBytes(_data), 0, buf.size, _usageHint);
        lime_gl_bind_buffer(buf.type, null);
        
        m_bufferMem += buf.size;

        return m_buffers.add( buf );
    }

    override public function createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int 
    {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.INDEX, 
            lime_gl_create_buffer(), 
            _size, 
            _usageHint);
        
        lime_gl_bind_buffer(buf.type, buf.glObj);
        lime_gl_buffer_data(buf.type, lime.utils.ByteArray.fromBytes(_data), 0, buf.size, _usageHint);
        lime_gl_bind_buffer(buf.type, null);
        
        m_bufferMem += buf.size;
        return m_buffers.add( buf );
    }

    override public function destroyBuffer(_handle:Int):Void
    {
        if (_handle == 0) return;
        
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        lime_gl_delete_buffer(buf.glObj);
        
        m_bufferMem -= buf.size;
        m_buffers.remove(_handle);
    }

    override public function updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        lime_gl_bind_buffer(buf.type, buf.glObj);
        lime_gl_buffer_sub_data(buf.type, _offset, lime.utils.ByteArray.fromBytes(_data), 0, _size);
        lime_gl_bind_buffer(buf.type, null);
    }
    
    override public function updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        lime_gl_bind_buffer(buf.type, buf.glObj);
        lime_gl_buffer_sub_data(buf.type, _offset, lime.utils.ByteArray.fromBytes(_data), 0, _size);  
        
        if(m_curIndexBuf != 0) // rebind the old one
            lime_gl_bind_buffer(buf.type, m_buffers.getRef(m_curIndexBuf).glObj);
        else
            lime_gl_bind_buffer(buf.type, null);
    }

    override public function createTexture(_type:Int, _width:Int, _height:Int, _format:Int, _hasMips:Bool, _genMips:Bool, ?_hintIsRenderTarget:Bool=false):Int
    {
        var tex = new RDITexture();
        tex.type = _type;
        tex.format = _format;
        tex.width = _width;
        tex.height = _height;
        tex.genMips = _genMips;
        tex.hasMips = _hasMips;

        switch (_format)
        {
            case RDITextureFormats.RGBA8, RDITextureFormats.RGBA16F: tex.glFmt = RGBA;
            case RDITextureFormats.DEPTH: tex.glFmt = DEPTH_COMPONENT;
        }        

        tex.glObj = lime_gl_create_texture();
        lime_gl_active_texture(TEXTURE0+m_lastTexUnit);
        lime_gl_bind_texture(_type, tex.glObj);

        tex.samplerState = 0;
        applySamplerState(tex);

        lime_gl_bind_texture(_type, null);
        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
            lime_gl_bind_texture(t.type, t.glObj);
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

        lime_gl_active_texture(TEXTURE0+m_lastTexUnit);
        lime_gl_bind_texture(tex.type, tex.glObj);

        var inputFormat:Int = RGBA;
        var inputType:Int = UNSIGNED_BYTE;

        switch (tex.format)
        {
            case RDITextureFormats.RGBA16F:
                inputFormat = RGBA;
                inputType = FLOAT;
            case RDITextureFormats.DEPTH: 
                //inputFormat = DEPTH_COMPONENT;
                //inputType = FLOAT;
                throw "[Foo3D - ERROR] - TextureFormats.DEPTH not supported yet";
        }

        // Calculate size of next mipmap using "floor" convention
        var width:Int = Std.int(Math.max(tex.width >> _mipLevel, 1));
        var height:Int = Std.int(Math.max(tex.height >> _mipLevel, 1));

        var target:Int = (tex.type == RDITextureTypes.TEX2D) ? 
            RDITextureTypes.TEX2D : (TEXTURE_CUBE_MAP_POSITIVE_X + _slice);

        if (_pixels == null) // we wanna upload an empty buffer
            lime_gl_tex_image_2d(target, _mipLevel, tex.glFmt, width, height, 0, inputFormat, inputType, null, 0);
        else
            lime_gl_tex_image_2d(target, _mipLevel, tex.glFmt, width, height, 0, inputFormat, inputType, lime.utils.ByteArray.fromBytes(haxe.io.Bytes.ofData(_pixels)), 0);

        // Note: for cube maps mips are only generated when the side with the highest index is uploaded
        if (tex.genMips && (tex.type != RDITextureTypes.TEXCUBE || _slice == 5))
        {
            lime_gl_generate_mipmap(tex.type);
        }

        lime_gl_bind_texture(tex.type, null);

        if (m_texSlots[m_lastTexUnit].texObj > 0)
        {
            var t:RDITexture = m_textures.getRef(m_texSlots[m_lastTexUnit].texObj);
            lime_gl_bind_texture(t.type, t.glObj);
        }
    }

    override public function destroyTexture(_handle:Int):Void 
    {
        if (_handle == 0) return;
        
        var tex:RDITexture = m_textures.getRef(_handle);
        lime_gl_delete_texture(tex.glObj);
        
        m_textureMem -= tex.memSize;
        m_textures.remove(_handle);
    }

    override public function createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int
    {
        // create shaders
        var vs:Int = lime_gl_create_shader(VERTEX_SHADER);
        lime_gl_shader_source(vs, _vertexShaderSrc);
        lime_gl_compile_shader(vs);
        var success:Int = lime_gl_get_shader_parameter(vs, COMPILE_STATUS);
        if (success == 0)
        {
            trace("[Vertex Shader] " + lime_gl_get_shader_info_log(vs));
            lime_gl_delete_shader(vs);
            return 0;
        }

        var fs:Int = lime_gl_create_shader(FRAGMENT_SHADER);
        lime_gl_shader_source(fs, _fragmentShaderSrc);
        lime_gl_compile_shader(fs);
        success = lime_gl_get_shader_parameter(fs, COMPILE_STATUS);
        if (success == 0)
        {
            trace("[Fragment Shader] " + lime_gl_get_shader_info_log(fs));
            lime_gl_delete_shader(vs);
            lime_gl_delete_shader(fs);
            return 0;
        }
        
        // create program
        var prog:Int = lime_gl_create_program();
        lime_gl_attach_shader(prog, vs);
        lime_gl_attach_shader(prog, fs);
        lime_gl_delete_shader(vs);
        lime_gl_delete_shader(fs);

        // link program
        lime_gl_link_program(prog);
        success = lime_gl_get_program_parameter(prog, LINK_STATUS);
        if (success == 0)
        {
            trace("[LINKING] " + lime_gl_get_program_info_log(prog));
            lime_gl_delete_program(prog);
            return 0;
        }

        var shader:RDIShaderProgram = new RDIShaderProgram();
        shader.oglProgramObj = prog;
        var attribCount:Int = lime_gl_get_program_parameter(prog, ACTIVE_ATTRIBUTES);

        for (i in 0...m_numVertexLayouts)
        {
            var vl:RDIVertexLayout = m_vertexLayouts[i];
            var allAttribsFound:Bool = true;

            for (j in 0...16)
                shader.inputLayouts[i].attribIndices[j] = -1;

            for (j in 0...attribCount)
            {
                var info:RDIUniformInfo = new RDIUniformInfo();
                var d = lime_gl_get_active_attrib(prog, j);
                info.type = d.type;
                info.name = d.name;

                var attribFound:Bool = false;
                for (k in 0...vl.numAttribs)
                {
                    if (vl.attribs[k].semanticName == info.name)
                    {
                        shader.inputLayouts[i].attribIndices[k] = lime_gl_get_attrib_location(prog, info.name);
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
        lime_gl_delete_program(shader.oglProgramObj);
        m_shaders.remove(_handle);
    }

    override public function bindProgram(_handle:Int):Void
    {
        if (_handle != 0)
        {
            var shader:RDIShaderProgram = m_shaders.getRef(_handle);
            lime_gl_use_program(shader.oglProgramObj);
        }
        else
            lime_gl_use_program(null);

        m_curShaderId = _handle;
        m_pendingMask |= ARD.PM_VERTLAYOUT;
    }

    override public function getActiveUniformCount(_handle:Int):Int 
    { 
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return lime_gl_get_program_parameter(shader.oglProgramObj, ACTIVE_UNIFORMS);
    }

    override public function getActiveUniformInfo(_handle:Int, _index:Int):RDIUniformInfo 
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        var res:RDIUniformInfo = new RDIUniformInfo();        
        var info:Dynamic = lime_gl_get_active_uniform(shader.oglProgramObj, _index);        
        res.name = info.name;
        res.type = info.type;
        return res;        
    }

    override public function getUniformLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return lime_gl_get_uniform_location(shader.oglProgramObj, _name);
    }

    override public function getSamplerLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        return lime_gl_get_uniform_location(shader.oglProgramObj, _name);
    }

    override public function setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void 
    { 
        switch (_type)
        {   
            case RDIShaderConstType.FLOAT: lime_gl_uniform1fv(_loc, _values);
            case RDIShaderConstType.FLOAT2: lime_gl_uniform2fv(_loc, _values);
            case RDIShaderConstType.FLOAT3: lime_gl_uniform3fv(_loc, _values);
            case RDIShaderConstType.FLOAT4: lime_gl_uniform4fv(_loc, _values);
            case RDIShaderConstType.FLOAT33, RDIShaderConstType.FLOAT44: {
                var out:haxe.io.BytesOutput = new haxe.io.BytesOutput();
                for (f in _values)
                    out.writeFloat(f);
                lime_gl_uniform_matrix(_loc, false, lime.utils.ByteArray.fromBytes(out.getBytes()), _type==RDIShaderConstType.FLOAT33 ? 3 : 4);
            }
        }
    }

    override public function setSampler(_loc:UniformLocationType, _texUnit:Int):Void 
    {
        lime_gl_uniform1i( _loc, _texUnit );        
    }

    override public function createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int 
    { 
        if (_format == RDITextureFormats.RGBA16F || _numColBufs > m_caps.maxColorAttachments)
            return 0;

        var rb:RDIRenderBuffer = new RDIRenderBuffer(_numColBufs);
        rb.width = _width;
        rb.height = _height;
        rb.fbo = lime_gl_create_framebuffer();

        // Attach color buffers
        if (_numColBufs > 0)
        {
            for(j in 0..._numColBufs)
            {
                lime_gl_bind_framebuffer(FRAMEBUFFER, rb.fbo);
                // create the color texture
                var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, _format, false, false, true);
                this.uploadTextureData(texObj, 0, 0, null);
                rb.colTexs[j] = texObj;
                var tex:RDITexture = m_textures.getRef(texObj);
                // attach to framebuffer
                lime_gl_framebuffer_texture2D(FRAMEBUFFER, COLOR_ATTACHMENT0 + j, RDITextureTypes.TEX2D, tex.glObj, 0);
            }
        }
        // attach depth buffer
        if (_depth)
        {
            lime_gl_bind_framebuffer(FRAMEBUFFER, rb.fbo);
            // create the depth buffer
            rb.depthBufObj = lime_gl_create_render_buffer();
            lime_gl_bind_renderbuffer(RENDERBUFFER, rb.depthBufObj);
            lime_gl_renderbuffer_storage(RENDERBUFFER, RDITextureFormats.DEPTH, rb.width, rb.height);
            // attach it
            lime_gl_framebuffer_renderbuffer(FRAMEBUFFER, DEPTH_ATTACHMENT, RENDERBUFFER, rb.depthBufObj);
        }

        var rbObj:Int = m_renBuffers.add(rb);

        // validate fbo
        var status:Int = lime_gl_check_framebuffer_status(FRAMEBUFFER);
        switch(status) {
            case FRAMEBUFFER_UNSUPPORTED: throw "Framebuffer is not supported";
            case FRAMEBUFFER_INCOMPLETE_ATTACHMENT: throw "Framebuffer incomplete attachment";
            case FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: throw "Framebuffer incomplete missing attachment";
        }
        if (status != FRAMEBUFFER_COMPLETE)
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
            lime_gl_delete_render_buffer(rb.depthBufObj);
        rb.depthBufObj = null;

        for (i in 0...m_caps.maxColorAttachments)
        {
            if (rb.colTexs[i] != 0) 
                lime_gl_delete_texture(rb.colTexs[i]);
            rb.colTexs[i] = 0;
        }

        if (rb.fbo != null)
            lime_gl_delete_framebuffer(rb.fbo);
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
            lime_gl_bind_framebuffer(FRAMEBUFFER, _defaultFbo);
        }
        else
        {
            // reset all texture bindings
            for (i in 0...m_caps.maxTextureUnits)
                this.setTexture(i, 0, 0);
            this.commitStates(ARD.PM_TEXTURES);

            var rb = m_renBuffers.getRef(_handle);

            lime_gl_bind_framebuffer(FRAMEBUFFER, rb.fbo);
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
        for (i in 0...vl.numAttribs)
        {
            var attribIndex:Int = inputLayout.attribIndices[i];
            if (attribIndex >= 0)
            {
                var attrib:RDIVertexLayoutAttrib = vl.attribs[i];
                var vbSlot:RDIVertBufSlot = m_vertBufSlots[attrib.vbSlot];

                lime_gl_bind_buffer(RDIBufferType.VERTEX, m_buffers.getRef(vbSlot.vbObj).glObj);
                lime_gl_vertex_attrib_pointer(
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

        for (i in 0...m_caps.maxVertAttribs)
        {
            var curBit:Int = 1 << i;
            if ((newVertexAttribMask & curBit) != (m_activeVertexAttribsMask & curBit))
            {
                if ((newVertexAttribMask & curBit) == curBit)
                    lime_gl_enable_vertex_attrib_array(i);
                else
                    lime_gl_enable_vertex_attrib_array(i);
            }
        }
        m_activeVertexAttribsMask = newVertexAttribMask;
        
        return true;
    }

    private static var magFilters:Array<Int>        = [LINEAR, LINEAR, NEAREST];
    private static var minFiltersMips:Array<Int>    = [LINEAR_MIPMAP_NEAREST, LINEAR_MIPMAP_LINEAR, NEAREST_MIPMAP_NEAREST];
    private static var wrapModes:Array<Int>         = [CLAMP_TO_EDGE, REPEAT, MIRRORED_REPEAT];

    override function applySamplerState(_tex:RDITexture):Void
    {
        var state = _tex.samplerState;
        var target = _tex.type;

        if (_tex.hasMips)
            lime_gl_tex_parameteri(target, TEXTURE_MIN_FILTER, minFiltersMips[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START]);
        else
            lime_gl_tex_parameteri(target, TEXTURE_MIN_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        
        lime_gl_tex_parameteri( target, TEXTURE_MAG_FILTER, magFilters[(state & AbstractRenderDevice.SS_FILTER_MASK) >> AbstractRenderDevice.SS_FILTER_START] );
        lime_gl_tex_parameteri( target, TEXTURE_WRAP_S, wrapModes[(state & AbstractRenderDevice.SS_ADDRU_MASK) >> AbstractRenderDevice.SS_ADDRU_START] );
        lime_gl_tex_parameteri( target, TEXTURE_WRAP_T, wrapModes[(state & AbstractRenderDevice.SS_ADDRV_MASK) >> AbstractRenderDevice.SS_ADDRV_START] );
    }

    override public function commitStates(?_filter:Int=0xFFFFFFFF):Bool
    {
        if ((m_pendingMask & _filter) != 0)
        {
            var mask:Int = m_pendingMask & _filter;

            // Set viewport
            if ((mask & ARD.PM_VIEWPORT) == ARD.PM_VIEWPORT)
            {
                lime_gl_viewport(m_vpX, m_vpY, m_vpWidth, m_vpHeight);
                m_pendingMask &= ~ARD.PM_VIEWPORT;
            }

            // Set scissor rect
            if ((mask & ARD.PM_SCISSOR) == ARD.PM_SCISSOR)
            {
                lime_gl_scissor(m_scX, m_scY, m_scWidth, m_scHeight);
                m_pendingMask &= ~ARD.PM_SCISSOR;
            }

            // Cullmode
            if ((mask & ARD.PM_CULLMODE) == ARD.PM_CULLMODE)
            {
                if (m_newCullMode != m_curCullMode)
                {
                    if (m_newCullMode == RDICullModes.NONE)
                        lime_gl_disable(CULL_FACE);
                    else
                    {
                        lime_gl_enable(CULL_FACE);
                        lime_gl_cull_face(m_newCullMode);
                    }
                    m_curCullMode = m_newCullMode;
                }
                m_pendingMask &= ~ARD.PM_CULLMODE;
            }

            // Depth Mask
            if ((mask & ARD.PM_DEPTH_MASK) == ARD.PM_DEPTH_MASK) 
            {
                if (m_newDepthMask != m_curDepthMask) {
                    lime_gl_depth_mask(m_newDepthMask);
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
                            lime_gl_disable(DEPTH_TEST);
                            m_depthTestEnabled = false;
                        }
                    }
                    else
                    {
                        if (!m_depthTestEnabled)
                        {
                            lime_gl_enable(DEPTH_TEST);
                            m_depthTestEnabled = true;
                        }

                        lime_gl_depth_func(m_newDepthTest);
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

                    lime_gl_blend_equation(m_newBlendEq);
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
                        lime_gl_disable(BLEND); // replace-function
                    else 
                    {
                        lime_gl_enable(BLEND);
                        lime_gl_blend_func(m_newSrcFactor, m_newDstFactor);
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
                    lime_gl_active_texture(TEXTURE0+i);

                    if (m_texSlots[i].texObj != 0)
                    {
                        var tex:RDITexture = m_textures.getRef(m_texSlots[i].texObj);
                        lime_gl_bind_texture(tex.type, tex.glObj);

                        if (tex.samplerState != m_texSlots[i].samplerState)
                        {
                            tex.samplerState = m_texSlots[i].samplerState;
                            applySamplerState(tex);
                        }
                    }
                    else
                    {
                        lime_gl_bind_texture(RDITextureTypes.TEXCUBE, null);
                        lime_gl_bind_texture(RDITextureTypes.TEX2D, null);
                    }
                }

                m_pendingMask &= ~ARD.PM_TEXTURES;
            }

            // Bind index buffer
            if ((mask & ARD.PM_INDEXBUF) == ARD.PM_INDEXBUF)
            {
                if (m_newIndexBuf != m_curIndexBuf)
                {
                    if (m_newIndexBuf != 0)
                        lime_gl_bind_buffer(RDIBufferType.INDEX, m_buffers.getRef(m_newIndexBuf).glObj);
                    else
                        lime_gl_bind_buffer(RDIBufferType.INDEX, null);
                    
                    m_curIndexBuf = m_newIndexBuf;
                }
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
        for (i in 0...m_caps.maxVertAttribs)
            lime_gl_disable_vertex_attrib_array(i);

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
            lime_gl_clear_depth(_depth);
        }
        if ((_flags & RDIClearFlags.COLOR) == RDIClearFlags.COLOR)
        {
            mask |= COLOR_BUFFER_BIT;
            lime_gl_clear_color(_r, _g, _b, _a);
        }
        if ((_flags & RDIClearFlags.ALL) == RDIClearFlags.ALL)
        {
            mask |= COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT | STENCIL_BUFFER_BIT;
        }
        if (mask != 0)
        {
            commitStates( ARD.PM_VIEWPORT | ARD.PM_SCISSOR );
            lime_gl_clear(mask);
        }
    }

    override public function draw(_primType:Int, _numInds:Int, _offset:Int):Void
    {
        if (commitStates())
            lime_gl_draw_elements(_primType, _numInds, UNSIGNED_SHORT, _offset*2);
    }

    override public function drawArrays(_primType:Int, _offset:Int, _size:Int):Void
    {
        if (commitStates())
            lime_gl_draw_arrays(_primType, _offset, _size);
    }

    private static var lime_gl_active_texture = Libs.load("lime", "lime_gl_active_texture", 1);
    private static var lime_gl_attach_shader = Libs.load("lime", "lime_gl_attach_shader", 2);
    private static var lime_gl_bind_attrib_location = Libs.load("lime", "lime_gl_bind_attrib_location", 3);
    private static var lime_gl_bind_bitmap_data_texture = Libs.load("lime", "lime_gl_bind_bitmap_data_texture", 1);
    private static var lime_gl_bind_buffer = Libs.load("lime", "lime_gl_bind_buffer", 2);
    private static var lime_gl_bind_framebuffer = Libs.load("lime", "lime_gl_bind_framebuffer", 2);
    private static var lime_gl_bind_renderbuffer = Libs.load("lime", "lime_gl_bind_renderbuffer", 2);
    private static var lime_gl_bind_texture = Libs.load("lime", "lime_gl_bind_texture", 2);
    private static var lime_gl_blend_color = Libs.load("lime", "lime_gl_blend_color", 4);
    private static var lime_gl_blend_equation = Libs.load("lime", "lime_gl_blend_equation", 1);
    private static var lime_gl_blend_equation_separate = Libs.load("lime", "lime_gl_blend_equation_separate", 2);
    private static var lime_gl_blend_func = Libs.load("lime", "lime_gl_blend_func", 2);
    private static var lime_gl_blend_func_separate = Libs.load("lime", "lime_gl_blend_func_separate", 4);
    private static var lime_gl_buffer_data = Libs.load("lime", "lime_gl_buffer_data", 5);
    private static var lime_gl_buffer_sub_data = Libs.load("lime", "lime_gl_buffer_sub_data", 5);
    private static var lime_gl_check_framebuffer_status = Libs.load("lime", "lime_gl_check_framebuffer_status", 1);
    private static var lime_gl_clear = Libs.load("lime", "lime_gl_clear", 1);
    private static var lime_gl_clear_color = Libs.load("lime", "lime_gl_clear_color", 4);
    private static var lime_gl_clear_depth = Libs.load("lime", "lime_gl_clear_depth", 1);
    private static var lime_gl_clear_stencil = Libs.load("lime", "lime_gl_clear_stencil", 1);
    private static var lime_gl_color_mask = Libs.load("lime", "lime_gl_color_mask", 4);
    private static var lime_gl_compile_shader = Libs.load("lime", "lime_gl_compile_shader", 1);
    private static var lime_gl_compressed_tex_image_2d = Libs.load("lime", "lime_gl_compressed_tex_image_2d", -1);
    private static var lime_gl_compressed_tex_sub_image_2d = Libs.load("lime", "lime_gl_compressed_tex_sub_image_2d", -1);
    private static var lime_gl_copy_tex_image_2d = Libs.load("lime", "lime_gl_copy_tex_image_2d", -1);
    private static var lime_gl_copy_tex_sub_image_2d = Libs.load("lime", "lime_gl_copy_tex_sub_image_2d", -1);
    private static var lime_gl_create_buffer = Libs.load("lime", "lime_gl_create_buffer", 0);
    private static var lime_gl_create_framebuffer = Libs.load("lime", "lime_gl_create_framebuffer", 0);
    private static var lime_gl_create_program = Libs.load("lime", "lime_gl_create_program", 0);
    private static var lime_gl_create_render_buffer = Libs.load("lime", "lime_gl_create_render_buffer", 0);
    private static var lime_gl_create_shader = Libs.load("lime", "lime_gl_create_shader", 1);
    private static var lime_gl_create_texture = Libs.load("lime", "lime_gl_create_texture", 0);
    private static var lime_gl_cull_face = Libs.load("lime", "lime_gl_cull_face", 1);
    private static var lime_gl_delete_buffer = Libs.load("lime", "lime_gl_delete_buffer", 1);
    private static var lime_gl_delete_framebuffer = Libs.load("lime","lime_gl_delete_framebuffer", 1);
    private static var lime_gl_delete_program = Libs.load("lime", "lime_gl_delete_program", 1);
    private static var lime_gl_delete_render_buffer = Libs.load("lime","lime_gl_delete_render_buffer", 1);
    private static var lime_gl_delete_shader = Libs.load("lime", "lime_gl_delete_shader", 1);
    private static var lime_gl_delete_texture = Libs.load("lime", "lime_gl_delete_texture", 1);
    private static var lime_gl_depth_func = Libs.load("lime", "lime_gl_depth_func", 1);
    private static var lime_gl_depth_mask = Libs.load("lime", "lime_gl_depth_mask", 1);
    private static var lime_gl_depth_range = Libs.load("lime", "lime_gl_depth_range", 2);
    private static var lime_gl_detach_shader = Libs.load("lime", "lime_gl_detach_shader", 2);
    private static var lime_gl_disable = Libs.load("lime", "lime_gl_disable", 1);
    private static var lime_gl_disable_vertex_attrib_array = Libs.load("lime", "lime_gl_disable_vertex_attrib_array", 1);
    private static var lime_gl_draw_arrays = Libs.load("lime", "lime_gl_draw_arrays", 3);
    private static var lime_gl_draw_elements = Libs.load("lime", "lime_gl_draw_elements", 4);
    private static var lime_gl_enable = Libs.load("lime", "lime_gl_enable", 1);
    private static var lime_gl_enable_vertex_attrib_array = Libs.load("lime", "lime_gl_enable_vertex_attrib_array", 1);
    private static var lime_gl_finish = Libs.load("lime", "lime_gl_finish", 0);
    private static var lime_gl_flush = Libs.load("lime", "lime_gl_flush", 0);
    private static var lime_gl_framebuffer_renderbuffer = Libs.load("lime", "lime_gl_framebuffer_renderbuffer", 4);
    private static var lime_gl_framebuffer_texture2D = Libs.load("lime", "lime_gl_framebuffer_texture2D", 5);
    private static var lime_gl_front_face = Libs.load("lime", "lime_gl_front_face", 1);
    private static var lime_gl_generate_mipmap = Libs.load("lime", "lime_gl_generate_mipmap", 1);
    private static var lime_gl_get_active_attrib = Libs.load("lime", "lime_gl_get_active_attrib", 2);
    private static var lime_gl_get_active_uniform = Libs.load("lime", "lime_gl_get_active_uniform", 2);
    private static var lime_gl_get_attrib_location = Libs.load("lime", "lime_gl_get_attrib_location", 2);
    private static var lime_gl_get_buffer_paramerter = Libs.load("lime", "lime_gl_get_buffer_paramerter", 2);
    private static var lime_gl_get_context_attributes = Libs.load("lime", "lime_gl_get_context_attributes", 0);
    private static var lime_gl_get_error = Libs.load("lime", "lime_gl_get_error", 0);
    private static var lime_gl_get_framebuffer_attachment_parameter = Libs.load("lime", "lime_gl_get_framebuffer_attachment_parameter", 3);
    private static var lime_gl_get_parameter = Libs.load("lime", "lime_gl_get_parameter", 1);
    // private static var lime_gl_get_extension = Libs.load("lime", "lime_gl_get_extension", 1);    
    private static var lime_gl_get_program_info_log = Libs.load("lime", "lime_gl_get_program_info_log", 1);
    private static var lime_gl_get_program_parameter = Libs.load("lime", "lime_gl_get_program_parameter", 2);
    private static var lime_gl_get_render_buffer_parameter = Libs.load("lime", "lime_gl_get_render_buffer_parameter", 2);
    private static var lime_gl_get_shader_info_log = Libs.load("lime", "lime_gl_get_shader_info_log", 1);
    private static var lime_gl_get_shader_parameter = Libs.load("lime", "lime_gl_get_shader_parameter", 2);
    private static var lime_gl_get_shader_precision_format = Libs.load("lime", "lime_gl_get_shader_precision_format", 2);
    private static var lime_gl_get_shader_source = Libs.load("lime", "lime_gl_get_shader_source", 1);
    private static var lime_gl_get_supported_extensions = Libs.load("lime", "lime_gl_get_supported_extensions", 1);
    private static var lime_gl_get_tex_parameter = Libs.load("lime", "lime_gl_get_tex_parameter", 2);
    private static var lime_gl_get_uniform = Libs.load("lime", "lime_gl_get_uniform", 2);
    private static var lime_gl_get_uniform_location = Libs.load("lime", "lime_gl_get_uniform_location", 2);
    private static var lime_gl_get_vertex_attrib = Libs.load("lime", "lime_gl_get_vertex_attrib", 2);
    private static var lime_gl_get_vertex_attrib_offset = Libs.load("lime", "lime_gl_get_vertex_attrib_offset", 2);
    private static var lime_gl_hint = Libs.load("lime", "lime_gl_hint", 2);
    private static var lime_gl_is_buffer = Libs.load("lime", "lime_gl_is_buffer", 1);
    private static var lime_gl_is_enabled = Libs.load("lime", "lime_gl_is_enabled", 1);
    private static var lime_gl_is_framebuffer = Libs.load("lime", "lime_gl_is_framebuffer", 1);
    private static var lime_gl_is_program = Libs.load("lime", "lime_gl_is_program", 1);
    private static var lime_gl_is_renderbuffer = Libs.load("lime", "lime_gl_is_renderbuffer", 1);
    private static var lime_gl_is_shader = Libs.load("lime", "lime_gl_is_shader", 1);
    private static var lime_gl_is_texture = Libs.load("lime", "lime_gl_is_texture", 1);
    private static var lime_gl_line_width = Libs.load("lime", "lime_gl_line_width", 1);
    private static var lime_gl_link_program = Libs.load("lime", "lime_gl_link_program", 1);
    private static var lime_gl_pixel_storei = Libs.load("lime", "lime_gl_pixel_storei", 2);
    private static var lime_gl_polygon_offset = Libs.load("lime", "lime_gl_polygon_offset", 2);
    private static var lime_gl_renderbuffer_storage = Libs.load("lime", "lime_gl_renderbuffer_storage", 4);
    private static var lime_gl_sample_coverage = Libs.load("lime", "lime_gl_sample_coverage", 2);
    private static var lime_gl_scissor = Libs.load("lime", "lime_gl_scissor", 4);
    private static var lime_gl_shader_source = Libs.load("lime", "lime_gl_shader_source", 2);
    private static var lime_gl_stencil_func = Libs.load("lime", "lime_gl_stencil_func", 3);
    private static var lime_gl_stencil_func_separate = Libs.load("lime", "lime_gl_stencil_func_separate", 4);
    private static var lime_gl_stencil_mask = Libs.load("lime", "lime_gl_stencil_mask", 1);
    private static var lime_gl_stencil_mask_separate = Libs.load("lime", "lime_gl_stencil_mask_separate", 2);
    private static var lime_gl_stencil_op = Libs.load("lime", "lime_gl_stencil_op", 3);
    private static var lime_gl_stencil_op_separate = Libs.load("lime", "lime_gl_stencil_op_separate", 4);
    private static var lime_gl_tex_image_2d = Libs.load("lime", "lime_gl_tex_image_2d", -1);
    private static var lime_gl_tex_parameterf = Libs.load("lime", "lime_gl_tex_parameterf", 3);
    private static var lime_gl_tex_parameteri = Libs.load("lime", "lime_gl_tex_parameteri", 3);
    private static var lime_gl_tex_sub_image_2d = Libs.load("lime", "lime_gl_tex_sub_image_2d", -1);
    private static var lime_gl_uniform1f = Libs.load("lime", "lime_gl_uniform1f", 2);
    private static var lime_gl_uniform1fv = Libs.load("lime", "lime_gl_uniform1fv", 2);
    private static var lime_gl_uniform1i = Libs.load("lime", "lime_gl_uniform1i", 2);
    private static var lime_gl_uniform1iv = Libs.load("lime", "lime_gl_uniform1iv", 2);
    private static var lime_gl_uniform2f = Libs.load("lime", "lime_gl_uniform2f", 3);
    private static var lime_gl_uniform2fv = Libs.load("lime", "lime_gl_uniform2fv", 2);
    private static var lime_gl_uniform2i = Libs.load("lime", "lime_gl_uniform2i", 3);
    private static var lime_gl_uniform2iv = Libs.load("lime", "lime_gl_uniform2iv", 2);
    private static var lime_gl_uniform3f = Libs.load("lime", "lime_gl_uniform3f", 4);
    private static var lime_gl_uniform3fv = Libs.load("lime", "lime_gl_uniform3fv", 2);
    private static var lime_gl_uniform3i = Libs.load("lime", "lime_gl_uniform3i", 4);
    private static var lime_gl_uniform3iv = Libs.load("lime", "lime_gl_uniform3iv", 2);
    private static var lime_gl_uniform4f = Libs.load("lime", "lime_gl_uniform4f", 5);
    private static var lime_gl_uniform4fv = Libs.load("lime", "lime_gl_uniform4fv", 2);
    private static var lime_gl_uniform4i = Libs.load("lime", "lime_gl_uniform4i", 5);
    private static var lime_gl_uniform4iv = Libs.load("lime", "lime_gl_uniform4iv", 2);
    private static var lime_gl_uniform_matrix = Libs.load("lime", "lime_gl_uniform_matrix", 4);
    private static var lime_gl_use_program = Libs.load("lime", "lime_gl_use_program", 1);
    private static var lime_gl_validate_program = Libs.load("lime", "lime_gl_validate_program", 1);
    private static var lime_gl_version = Libs.load("lime", "lime_gl_version", 0);
    private static var lime_gl_vertex_attrib1f = Libs.load("lime", "lime_gl_vertex_attrib1f", 2);
    private static var lime_gl_vertex_attrib1fv = Libs.load("lime", "lime_gl_vertex_attrib1fv", 2);
    private static var lime_gl_vertex_attrib2f = Libs.load("lime", "lime_gl_vertex_attrib2f", 3);
    private static var lime_gl_vertex_attrib2fv = Libs.load("lime", "lime_gl_vertex_attrib2fv", 2);
    private static var lime_gl_vertex_attrib3f = Libs.load("lime", "lime_gl_vertex_attrib3f", 4);
    private static var lime_gl_vertex_attrib3fv = Libs.load("lime", "lime_gl_vertex_attrib3fv", 2);
    private static var lime_gl_vertex_attrib4f = Libs.load("lime", "lime_gl_vertex_attrib4f", 5);
    private static var lime_gl_vertex_attrib4fv = Libs.load("lime", "lime_gl_vertex_attrib4fv", 2);
    private static var lime_gl_vertex_attrib_pointer = Libs.load("lime", "lime_gl_vertex_attrib_pointer", -1);
    private static var lime_gl_viewport = Libs.load("lime", "lime_gl_viewport", 4);
}