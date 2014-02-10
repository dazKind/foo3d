package foo3D.impl;

import foo3D.RenderDevice;


#if (flash || nme)

import com.ktxsoftware.flash.utils.AGALMiniAssembler;

import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DClearMask;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.Texture;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import flash.Vector;



class Stage3DRenderDevice extends AbstractRenderDevice
{
    public function new(_ctx:RenderContext)
    {
#if debug
        _ctx.enableErrorChecking = true;
#end
        super(_ctx);
    }
    
    override function init():Void
    {
        m_caps.texFloatSupport = false;
        m_caps.texNPOTSupport = false;
        m_caps.rtMultisampling = false;

        m_caps.maxVertAttribs = 8;
        m_caps.maxVertUniforms = 128;
        m_caps.maxColorAttachments = 1;

        trace(m_caps.toString());

        resetStates();
    }

    override public function createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = 1):Int
    {
        var numVerts:Int = Std.int(_size/_strideHint);
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.VERTEX, 
            {vbuf:m_ctx.createVertexBuffer(numVerts, _strideHint), ibuf:null}, 
            _size * 4,
            _usageHint);
        
        buf.glObj.vbuf.uploadFromVector(Vector.ofArray(_data), 0, numVerts);

        m_bufferMem += buf.size;
        return m_buffers.add( buf );
    }

    override public function createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int 
    {
        var buf:RDIBuffer = new RDIBuffer(
            RDIBufferType.INDEX, 
            {vbuf:null, ibuf:m_ctx.createIndexBuffer(_size)}, 
            _size * 4,
            _usageHint);
        
        buf.glObj.ibuf.uploadFromVector(Vector.ofArray(cast _data), 0, _size);

        m_bufferMem += buf.size;
        return m_buffers.add( buf );
    }

    override public function destroyBuffer(_handle:Int):Void
    {
        if (_handle == 0) return;
        
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        
        switch (buf.type)
        {
            case RDIBufferType.VERTEX: buf.glObj.vbuf.dispose();
            case RDIBufferType.INDEX: buf.glObj.ibuf.dispose();
        }
        
        m_bufferMem -= buf.size;
        m_buffers.remove(_handle);
    }

    override public function updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        buf.glObj.vbuf.uploadFromVector(Vector.ofArray(_data), _offset, _size);
    }
    
    override public function updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void 
    {
        var buf:RDIBuffer = m_buffers.getRef(_handle);
        buf.glObj.ibuf.uploadFromVector(Vector.ofArray(cast _data), _offset, _size);
    }

    override public function createTexture(_type:Int, _width:Int, _height:Int, _format:Int, 
        _hasMips:Bool, _genMips:Bool, ?_hintIsRenderTarget=false):Int
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
            case RDITextureFormats.RGBA8, RDITextureFormats.RGBA16F: 
                tex.glFmt = Context3DTextureFormat.BGRA;
            case RDITextureFormats.DEPTH: 
                throw "TextureFormats.DEPTH not supported";
        }

        switch (_type)
        {
            case RDITextureTypes.TEX2D: 
                tex.glObj = m_ctx.createTexture(tex.width, tex.height, tex.glFmt, _hintIsRenderTarget);
            case RDITextureTypes.TEXCUBE: 
                tex.height = tex.width; // only square ones allowed
                tex.glObj = m_ctx.createCubeTexture(tex.width, tex.glFmt, _hintIsRenderTarget);
        }

        
        tex.samplerState = 0;
        applySamplerState(tex);

        tex.memSize = calcTextureSize(tex.format, _width, _height);
        if (_type == RDITextureTypes.TEXCUBE)
            tex.memSize *= 6;
        m_textureMem += tex.memSize;

        return m_textures.add( tex );
    }

    override public function uploadTextureData(_handle:Int, _slice:Int, _mipLevel:Int, _pixels:PixelData):Void
    {
        var tex:RDITexture = m_textures.getRef(_handle);

        var pixData:PixelData = _pixels;

        if (_pixels == null) // we wanna upload an empty buffer
            pixData = new BitmapData( tex.width, tex.height, true );

        if (tex.genMips)
        {
            // auto
            var mipWidth:Int = tex.width;
            var mipHeight:Int = tex.height;
            var mipLevel:Int = 0;
            var mipImage:BitmapData = new BitmapData( tex.width, tex.height, true );
            var scaleTransform:flash.geom.Matrix = new flash.geom.Matrix();

            while ( mipWidth > 0 && mipHeight > 0 )
            {
                mipImage.draw( pixData, scaleTransform, null, null, null, true );
                switch (tex.type)
                {
                    case RDITextureTypes.TEX2D: 
                        cast(tex.glObj, Texture).uploadFromBitmapData(mipImage, mipLevel);
                    case RDITextureTypes.TEXCUBE:
                        cast(tex.glObj, CubeTexture).uploadFromBitmapData(mipImage, _slice, mipLevel);
                }
                scaleTransform.scale( 0.5, 0.5 );
                mipLevel++;
                mipWidth >>= 1;
                mipHeight >>= 1;
            }

            mipImage.dispose();
        }
        else
        {
            // manual upload
            switch (tex.type)
            {
                case RDITextureTypes.TEX2D: 
                    cast(tex.glObj, Texture).uploadFromBitmapData(pixData, _mipLevel);
                case RDITextureTypes.TEXCUBE:
                    cast(tex.glObj, CubeTexture).uploadFromBitmapData(pixData, _slice, _mipLevel);
            }
        }

        
    }

    override public function destroyTexture(_handle:Int):Void 
    {
        if (_handle == 0) return;
        
        var tex:RDITexture = m_textures.getRef(_handle);
        tex.glObj.dispose();
                
        m_textureMem -= tex.memSize;
        m_textures.remove(_handle);
    }

    function _commitConstants(_type:Context3DProgramType, _consts:Dynamic):Void
    {
        for (k in Reflect.fields(_consts))
        {
            var values:Array<Float> = Reflect.field(_consts, k);
            m_ctx.setProgramConstantsFromVector(
                _type, 
                Std.parseInt(k.substr(2)), 
                Vector.ofArray(values),
                Std.int(values.length / 4)
            );
        }
    }

    override public function createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int
    {
        var vsObj:Dynamic = haxe.Json.parse(_vertexShaderSrc);
        var fsObj:Dynamic = haxe.Json.parse(_fragmentShaderSrc);

        var vsBin:ByteArray = (new AGALMiniAssembler()).assemble(Context3DProgramType.VERTEX, vsObj.agalasm);
        var fsBin:ByteArray = (new AGALMiniAssembler()).assemble(Context3DProgramType.FRAGMENT, fsObj.agalasm);

        var prog = m_ctx.createProgram();
        prog.upload(vsBin, fsBin);

        var shader:RDIShaderProgram = new RDIShaderProgram();
        shader.oglProgramObj = {prog:prog, vsInfo:vsObj, fsInfo:fsObj};

        var attribCount = 0;
        for (k in Reflect.fields(vsObj.types))
            if (StringTools.startsWith(k, "va"))
                attribCount++;

        for (i in 0...m_numVertexLayouts)
        {
            var vl:RDIVertexLayout = m_vertexLayouts[i];
            var allAttribsFound:Bool = true;

            for (j in 0...16)
                shader.inputLayouts[i].attribIndices[j] = -1;
            
            for (j in 0...attribCount)
            {
                var attribFound:Bool = false;
                for (k in 0...vl.numAttribs)
                {
                    var attrib:String = Reflect.field(vsObj.varnames, vl.attribs[k].semanticName);
                    if (attrib != null)
                    {
                        shader.inputLayouts[i].attribIndices[k] = Std.parseInt(attrib.substr(2));
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
        shader.oglProgramObj.prog.dispose();
        
        m_shaders.remove(_handle);
    }

    override public function bindProgram(_handle:Int):Void
    {
        if (_handle != 0)
        {
            var shader:RDIShaderProgram = m_shaders.getRef(_handle);
            m_ctx.setProgram(shader.oglProgramObj.prog);

            // commit hardcoded constants
            _commitConstants(Context3DProgramType.VERTEX,   shader.oglProgramObj.vsInfo.consts);
            _commitConstants(Context3DProgramType.FRAGMENT, shader.oglProgramObj.fsInfo.consts);
        }
        else
            m_ctx.setProgram(null);

        m_curShaderId = _handle;
        m_pendingMask |= ARD.PM_VERTLAYOUT;
    }

    override public function getActiveUniformCount(_handle:Int):Int 
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);

        var count = 0;
        for (k in Reflect.fields(shader.oglProgramObj.vsInfo.types))
            if (StringTools.startsWith(k, "vc") || StringTools.startsWith(k, "fs"))
                count++;

        return count; // todo: cache this!
    }

    override public function getUniformLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        
        var v:String = Reflect.field(shader.oglProgramObj.vsInfo.varnames, _name);
        var f:String = Reflect.field(shader.oglProgramObj.fsInfo.varnames, _name);

        return {
            vsLoc: (v!=null) ? Std.parseInt(v.substr(2)) : null, 
            fsLoc: (f!=null) ? Std.parseInt(f.substr(2)) : null
        };
    }

    override public function getSamplerLoc(_handle:Int, _name:String):UniformLocationType
    {
        var shader:RDIShaderProgram = m_shaders.getRef(_handle);
        
        var f:String = Reflect.field(shader.oglProgramObj.fsInfo.varnames, _name);

        return {
            vsLoc: null, 
            fsLoc: (f!=null) ? Std.parseInt(f.substr(2)) : null
        };
    }

    function _setProgConst(_progType:Context3DProgramType, _type:Int, _firstRegister:Int, _values:Array<Float>):Void
    {
        switch (_type)
        {
            case RDIShaderConstType.FLOAT: m_ctx.setProgramConstantsFromVector(_progType, _firstRegister, Vector.ofArray([_values[0], 0, 0, 0]), 1);
            case RDIShaderConstType.FLOAT2: m_ctx.setProgramConstantsFromVector(_progType, _firstRegister, Vector.ofArray([_values[0], _values[1], 0, 0]), 1);
            case RDIShaderConstType.FLOAT3: m_ctx.setProgramConstantsFromVector(_progType, _firstRegister, Vector.ofArray([_values[0], _values[1], _values[3], 0]), 1);
            case RDIShaderConstType.FLOAT4: m_ctx.setProgramConstantsFromVector(_progType, _firstRegister, Vector.ofArray(_values), 1);
            case RDIShaderConstType.FLOAT33: m_ctx.setProgramConstantsFromVector(_progType, _firstRegister, Vector.ofArray(_values), 3);
            case RDIShaderConstType.FLOAT44: m_ctx.setProgramConstantsFromMatrix(_progType, _firstRegister, new flash.geom.Matrix3D(Vector.ofArray(_values)), true);
        }
    }

    override public function setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void 
    {
        if (_loc.vsLoc != null)
            _setProgConst(Context3DProgramType.VERTEX, _type, _loc.vsLoc, _values);
        if (_loc.fsLoc != null)
            _setProgConst(Context3DProgramType.FRAGMENT, _type, _loc.fsLoc, _values);
    }

    override public function setSampler(_loc:UniformLocationType, _texUnit:Int):Void 
    {
        // override, even though this is not necessary on this target
    }

    function nearest_pow(_num:Int):Int
    {
        var n:Int = _num > 0 ? _num - 1 : 0;

        n |= n >> 1;
        n |= n >> 2;
        n |= n >> 4;
        n |= n >> 8;
        n |= n >> 16;
        n++;

        return n;
    }

    override public function createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int
    {
        if (_format == RDITextureFormats.RGBA16F || _numColBufs > m_caps.maxColorAttachments)
            return 0;

        var rb:RDIRenderBuffer = new RDIRenderBuffer(_numColBufs);
        rb.width = nearest_pow(_width);
        rb.height = nearest_pow(_height);

        // Attach color buffers
        if (_numColBufs > 0)
        {
            for(j in 0..._numColBufs)
            {
                // create the color texture
                var texObj:Int = this.createTexture(RDITextureTypes.TEX2D, rb.width, rb.height, _format, false, false, true);
                this.uploadTextureData(texObj, 0, 0, null);
                rb.colTexs[j] = texObj;
            }
        }
        rb.depthBufObj = _depth;

        var rbObj:Int = m_renBuffers.add(rb);

        return rbObj;
    }

    override public function destroyRenderBuffer(_handle:Int):Void 
    {
        var rb = m_renBuffers.getRef(_handle);
        for (i in 0...m_caps.maxColorAttachments)
        {
            if (rb.colTexs[i] != 0) 
                this.destroyTexture(rb.colTexs[i]);
            rb.colTexs[i] = 0;
        }
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
            m_ctx.setRenderToBackBuffer();
        }
        else
        {
            // reset all texture bindings
            for (i in 0...16)
                this.setTexture(i, 0, 0);
            
            var rb = m_renBuffers.getRef(_handle);

            this.commitStates(ARD.PM_TEXTURES|ARD.PM_SCISSOR);

            m_ctx.setRenderToTexture(m_textures.getRef(rb.colTexs[0]).glObj, rb.depthBufObj);
        }
    }

    override public function getRenderBufferData(_handle:Int, ?_bufIndex:Int=0):RDIRenderBufferData
    {
        var res:RDIRenderBufferData = {width:0, height:0, data:null};
        var w:Int = 0;
        var h:Int = 0;

        if (_handle == 0)
        {
            // read from backbuffer
            res.width = w = m_vpWidth;
            res.height = h = m_vpHeight;
        }
        else
        {
            var rb = m_renBuffers.getRef(_handle);
            if (_bufIndex >= m_caps.maxColorAttachments || rb.colTexs[_bufIndex] == 0)
                return null;
            res.width = w = rb.width;
            res.height = h = rb.height;
        }

        res.data = new BitmapData(w, h, true);
        m_ctx.drawToBitmapData(res.data);
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

                m_ctx.setVertexBufferAt(
                    attribIndex, 
                    m_buffers.getRef(vbSlot.vbObj).glObj.vbuf, 
                    vbSlot.offset + attrib.offset,
                    cast "float" + attrib.size
                );
                
                newVertexAttribMask |= 1 << attribIndex;
            }
        }

        for (i in 0...16)
        {
            var curBit:Int = 1 << i;
            if ((newVertexAttribMask & curBit) != (m_activeVertexAttribsMask & curBit))
            {
                if ((newVertexAttribMask & curBit) != curBit)
                    m_ctx.setVertexBufferAt(i, null);
            }
        }
        m_activeVertexAttribsMask = newVertexAttribMask;
        
        return true;
    }

    override function applySamplerState(_tex:RDITexture):Void
    {
        // this is done in the fragment shader
    }

    override public function commitStates(?_filter=0xFFFFFFFF):Bool
    {
        if ((m_pendingMask & _filter) != 0)
        {
            var mask:Int = m_pendingMask & _filter;

            // Set viewport
            if ((mask & ARD.PM_VIEWPORT) == ARD.PM_VIEWPORT)
            {
                m_ctx.configureBackBuffer(m_vpWidth, m_vpHeight, 2, true);
                m_pendingMask &= ~ARD.PM_VIEWPORT;
            }

            // Set scissor rect
            if ((mask & ARD.PM_SCISSOR) == ARD.PM_SCISSOR)
            {
                m_ctx.setScissorRectangle(new flash.geom.Rectangle(m_scX, m_scY, m_scWidth, m_scHeight));
                m_pendingMask &= ~ARD.PM_SCISSOR;
            }

            // Cullmode
            if ((mask & ARD.PM_CULLMODE) == ARD.PM_CULLMODE)
            {
                if (m_newCullMode != m_curCullMode)
                {
                    switch(m_newCullMode)
                    {
                        case RDICullModes.NONE:
                            m_ctx.setCulling(Context3DTriangleFace.NONE);
                        case RDICullModes.FRONT:
                            m_ctx.setCulling(Context3DTriangleFace.FRONT);
                        case RDICullModes.BACK:
                            m_ctx.setCulling(Context3DTriangleFace.BACK);
                        case RDICullModes.FRONT_AND_BACK:
                            m_ctx.setCulling(Context3DTriangleFace.FRONT_AND_BACK);
                    }
                    m_curCullMode = m_newCullMode;
                }
                m_pendingMask &= ~ARD.PM_CULLMODE;
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
                            m_ctx.setDepthTest(false, Context3DCompareMode.LESS);
                            m_depthTestEnabled = false;
                        }
                    }
                    else
                    {
                        if (!m_depthTestEnabled)
                            m_depthTestEnabled = true;
                        
                        var mode:Context3DCompareMode = null;
                        switch(m_newDepthTest)
                        {
                            case RDITestModes.NEVER: mode = Context3DCompareMode.NEVER;
                            case RDITestModes.LESS: mode = Context3DCompareMode.LESS;
                            case RDITestModes.EQUAL: mode = Context3DCompareMode.EQUAL;
                            case RDITestModes.LEQUAL: mode = Context3DCompareMode.LESS_EQUAL;
                            case RDITestModes.GREATER: mode = Context3DCompareMode.GREATER;
                            case RDITestModes.NOTEQUAL: mode = Context3DCompareMode.NOT_EQUAL;
                            case RDITestModes.GEQUAL: mode = Context3DCompareMode.GREATER_EQUAL;
                            case RDITestModes.ALWAYS: mode = Context3DCompareMode.ALWAYS;
                        }
                        m_ctx.setDepthTest(true, mode);
                    }

                    m_curDepthTest = m_newDepthTest;
                }                    
                
                m_pendingMask &= ~ARD.PM_DEPTH_TEST;
            }

            // set blending
            if((mask & ARD.PM_BLEND) == ARD.PM_BLEND)
            {
                if (m_newSrcFactor != m_curSrcFactor || m_newDstFactor != m_curDstFactor)
                {
                    m_ctx.setBlendFactors(
                        _translateBlendFactor(m_newSrcFactor), 
                        _translateBlendFactor(m_newDstFactor)
                    );
                    
                    m_curSrcFactor = m_newSrcFactor;
                    m_curDstFactor = m_newDstFactor;
                }
                m_pendingMask &= ~ARD.PM_BLEND;
            }

            // Bind textures and set sampler state
            if((mask & ARD.PM_TEXTURES) == ARD.PM_TEXTURES)
            {
                //for (i in 0...16)
                for (i in 0...8) // flash only supports 8 texunits
                {
                    if (m_texSlots[i].texObj != 0)
                    {
                        var tex:RDITexture = m_textures.getRef(m_texSlots[i].texObj);

                        m_ctx.setTextureAt(i, tex.glObj);
                    }
                    else
                    {
                        m_ctx.setTextureAt(i, null);
                    }
                }

                m_pendingMask &= ~ARD.PM_TEXTURES;
            }

            // Bind index buffer
            if ((mask & ARD.PM_INDEXBUF) == ARD.PM_INDEXBUF)
            {
                if (m_newIndexBuf != m_curIndexBuf)
                    m_curIndexBuf = m_newIndexBuf;
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

    function _translateBlendFactor(_m:Int):Context3DBlendFactor
    {
        var res:Context3DBlendFactor = null;
        switch (_m)
        {
            case RDIBlendFactors.ZERO: 
                res = Context3DBlendFactor.ZERO;
            case RDIBlendFactors.ONE: 
                res = Context3DBlendFactor.ONE;
            case RDIBlendFactors.SRC_COLOR: 
                res = Context3DBlendFactor.SOURCE_COLOR;
            case RDIBlendFactors.ONE_MINUS_SRC_COLOR: 
                res = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
            case RDIBlendFactors.SRC_ALPHA: 
                res = Context3DBlendFactor.SOURCE_ALPHA;
            case RDIBlendFactors.ONE_MINUS_SRC_ALPHA: 
                res = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            case RDIBlendFactors.DST_ALPHA: 
                res = Context3DBlendFactor.DESTINATION_ALPHA;
            case RDIBlendFactors.ONE_MINUS_DST_ALPHA: 
                res = Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA;
            case RDIBlendFactors.DST_COLOR: 
                res = Context3DBlendFactor.DESTINATION_COLOR;
            case RDIBlendFactors.ONE_MINUS_DST_COLOR: 
                res = Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR;
        }
        return res;
    }

    override public function isLost():Bool 
    {
        return (m_ctx == null || m_ctx.driverInfo == "Disposed");
    }

    override public function clear(_flags:Int, ?_r:Float = 0, ?_g:Float = 0, ?_b:Float = 0, ?_a:Float = 1, ?_depth:Float = 1):Void
    {
        var mask:Int = 0;
        if ((_flags & RDIClearFlags.DEPTH) == RDIClearFlags.DEPTH)
        {
            mask |= Context3DClearMask.DEPTH;
        }
        if ((_flags & RDIClearFlags.COLOR) == RDIClearFlags.COLOR)
        {
            mask |= Context3DClearMask.COLOR;
        }
        if ((_flags & RDIClearFlags.ALL) == RDIClearFlags.ALL)
        {
            mask |= Context3DClearMask.ALL;
        }
        if (mask != 0)
        {
            commitStates( ARD.PM_VIEWPORT | ARD.PM_SCISSOR );
            m_ctx.clear(_r, _g, _b, _a, _depth, 0, mask);
        }
    }

    override public function draw(_primType:Int, _numInds:Int, _offset:Int):Void
    {
        if (commitStates())
        {
            var indexBuf:RDIBuffer = m_buffers.getRef(m_curIndexBuf);
            m_ctx.drawTriangles(indexBuf.glObj.ibuf, _offset, Std.int(_numInds/3));
        }
    }
}

#end