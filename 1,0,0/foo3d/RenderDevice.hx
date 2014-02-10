package foo3d;

#if js

    typedef BufferObjectType = js.html.webgl.Buffer;
    typedef TextureObjectType = js.html.webgl.Texture;
    typedef TextureFormatType = Null<Int>;
    typedef ShaderProgramType = js.html.webgl.Program;
    typedef UniformLocationType = js.html.webgl.UniformLocation;
    typedef FrameBufferObjectType = js.html.webgl.Framebuffer;
    typedef RenderBufferObjectType = js.html.webgl.Renderbuffer;

    typedef VertexBufferData = haxe.io.Bytes;
    typedef IndexBufferData = haxe.io.Bytes;
    typedef PixelData = Dynamic;

    typedef RenderDevice = foo3d.impl.WebGLRenderDevice;

#elseif (flash)

    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.VertexBuffer3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.TextureBase;
    import flash.display3D.Program3D;

    typedef BufferObjectType = { vbuf:VertexBuffer3D, ibuf:IndexBuffer3D };
    typedef TextureObjectType = TextureBase;
    typedef TextureFormatType = Context3DTextureFormat;
    typedef ShaderProgramType = { prog:Program3D, vsInfo:Dynamic, fsInfo:Dynamic };
    typedef UniformLocationType = { vsLoc:Null<Int>, fsLoc:Null<Int> };
    typedef FrameBufferObjectType = Dynamic;
    typedef RenderBufferObjectType = Null<Bool>;

    typedef VertexBufferData = haxe.io.Bytes;
    typedef IndexBufferData = haxe.io.Bytes;
    typedef PixelData = flash.display.BitmapData; //flash.utils.ByteArray;

    typedef RenderDevice = foo3d.impl.Stage3DRenderDevice;

#elseif cpp

    typedef BufferObjectType = Null<Int>;
    typedef TextureObjectType = Null<Int>;
    typedef TextureFormatType = Null<Int>;
    typedef ShaderProgramType = Null<Int>;
    typedef UniformLocationType = Null<Int>;
    typedef FrameBufferObjectType = Null<Int>;
    typedef RenderBufferObjectType = Null<Int>;

    typedef VertexBufferData = haxe.io.Bytes;
    typedef IndexBufferData = haxe.io.Bytes;
    typedef PixelData = haxe.io.BytesData;

    #if foo3d_use_lime
        typedef RenderDevice = foo3d.impl.LimeRenderDevice;
    #else
        typedef RenderDevice = foo3d.impl.OpenGLRenderDevice;
    #end

#end

typedef ARD = AbstractRenderDevice;

class RDIObjects<T>
{
    var m_objects:Array<T>;
    var m_freeList:Array<Int>;
    
    public function new()
    {
        m_objects = [];
        m_freeList = [];
    }

    inline public function add(_obj:T):Int
    {
        var index:Int = -1;
        if (m_freeList.length > 0)
        {
            index = m_freeList.pop();
            m_objects[index] = _obj;
            index += 1;
        }
        else
        {
            m_objects.push(_obj);
            index = m_objects.length;
        }
        return index;
    }
    
    inline public function remove(_handle:Int):Void
    {
        var index:Int = _handle-1;
        m_objects[index] = null; // Destruct and replace with default object
        m_freeList.push(index);
    }
    
    inline public function getRef(_handle:Int):T
    {
        return m_objects[_handle-1];
    }
}

class RDIDeviceCaps
{
    public var texFloatSupport:Bool;
    public var texNPOTSupport:Bool;
    public var rtMultisampling:Bool;
    public var maxVertAttribs:Int;
    public var maxVertUniforms:Int;
    public var maxColorAttachments:Int; 
    
    public function new()
    {
        texFloatSupport = false;
        texNPOTSupport = false;
        maxVertAttribs = 0;
        maxVertUniforms = 0;
        maxColorAttachments = 1; // no mrt?
    }

    public function toString():String {
        var res:String = "[Foo3D] - Device Capabilities:\n";

        //for (key in Reflect.fields(this))
            //res += key + " = " + Reflect.field(this, key) + "\n";

        res += "texFloatSupport = " + texFloatSupport + "\n";
        res += "texNPOTSupport = " + texNPOTSupport + "\n";
        res += "rtMultisampling = " + rtMultisampling + "\n";
        res += "maxVertAttribs = " + maxVertAttribs + "\n";
        res += "maxVertUniforms = " + maxVertUniforms + "\n";
        res += "maxColorAttachments = " + maxColorAttachments + "\n";
        
        return res;
    }
}


// ---------------------------------------------------------
// Vertex layout
// ---------------------------------------------------------

class RDIVertexLayoutAttrib
{
    public var semanticName:String;
    public var vbSlot:Int;
    public var size:Int;
    public var offset:Int;
    
    public function new(?_semanticName:String = "", ?_vbSlot:Int = 0, ?_size:Int = 0, ?_offset:Int = 0)
    {
        semanticName = _semanticName;
        vbSlot = _vbSlot;
        size = _size;
        offset = _offset;
    }
}

class RDIVertexLayout
{
    public var numAttribs:Int;
    public var attribs:Array<RDIVertexLayoutAttrib>;
    
    public function new()
    {
        numAttribs = 0;
        //attribs = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // 16
        attribs = [];
        for (i in 0...16)
            attribs.push(new RDIVertexLayoutAttrib());
    }
}


// ---------------------------------------------------------
// Buffers
// ---------------------------------------------------------

class RDIBufferUsage
{
    inline public static var STATIC:Int     = 0x88E4;
    inline public static var DYNAMIC:Int    = 0x88E8;
}

class RDIBufferType
{
    inline public static var VERTEX:Int     = 0x8892;
    inline public static var INDEX:Int      = 0x8893;
}

class RDIBuffer
{
    public var type:Int;
    public var glObj:BufferObjectType;
    public var size:Int;
    public var usage:Int;
    
    public function new(_type:Int, _glObj:BufferObjectType, _size:Int, _usageHint:Int)
    {
        type = _type;
        glObj = _glObj;
        size = _size;
        usage = _usageHint;
    }
}

class RDIVertBufSlot
{
    public var vbObj:Int;
    public var offset:Int;
    public var stride:Int;
    
    public function new(?_vbObj = 0, ?_offset = 0, ?_stride = 0)
    {
        vbObj = _vbObj;
        offset = _offset;
        stride = _stride;
    }
}


// ---------------------------------------------------------
// Textures
// ---------------------------------------------------------

class RDITextureTypes
{
    inline public static var TEX2D:Int       = 0x0DE1;
    inline public static var TEXCUBE:Int     = 0x8513;
}

class RDITextureFormats
{
    inline public static var RGBA8:Int = 0x8058;
    inline public static var RGBA16F:Int = 0x881A;
    inline public static var RGBA32F:Int = 0x8814;
    inline public static var DEPTH:Int = 0x81A6;
}

class RDITexture
{
    public var glObj:TextureObjectType;
    public var glFmt:TextureFormatType;
    
    public var type:Int;
    public var format:Int;
    
    public var width:Int;
    public var height:Int;
    public var memSize:Int;
    public var samplerState:Int;
    
    public var hasMips:Bool;
    public var genMips:Bool;
    
    public function new()
    {
        glObj = null;
        glFmt = null;
        type = 0;
        format = 0;
        width = 0;
        height = 0;
        memSize = 0;
        samplerState = 0;
        hasMips = false;
        genMips = false;
    }
}

class RDITexSlot
{
    public var texObj:Int;
    public var samplerState:Int;
    
    public function new(?_texObj = 0, ?_samplerState = 0)
    {
        texObj = _texObj;
        samplerState = _samplerState;
    }
}

// ---------------------------------------------------------
// Shaders
// ---------------------------------------------------------

class RDIShaderConstType
{
    inline public static var FLOAT:Int = 0x1406;
    inline public static var FLOAT2:Int = 0x8B50;
    inline public static var FLOAT3:Int = 0x8B51;
    inline public static var FLOAT4:Int = 0x8B52;
    inline public static var FLOAT33:Int = 0x8B5B;
    inline public static var FLOAT44:Int = 0x8B5C;
    inline public static var SAMPLER_2D:Int = 0x8B5E;
    inline public static var SAMPLER_CUBE:Int = 0x8B60;
}

class RDIUniformInfo {
    public var name:String;
    public var type:Int;

    public function new() {}
}

class RDIShaderInputLayout
{
    public var valid:Bool;
    public var attribIndices:Array<Int>;
    
    public function new()
    {
        valid = false;
        attribIndices = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // 16
    }
}

class RDIShaderProgram
{
    public var oglProgramObj:ShaderProgramType;
    public var inputLayouts:Array<RDIShaderInputLayout>; // 16
    
    public function new()
    {
        oglProgramObj = null;
        inputLayouts = []; 
        for (i in 0...16)
            inputLayouts.push(new RDIShaderInputLayout());
    }
}


// ---------------------------------------------------------
// Render buffers
// ---------------------------------------------------------

class RDIRenderBuffer
{
    public var fbo:FrameBufferObjectType;
    public var colTexs:Array<Int>;
        
    public var width:Int;
    public var height:Int;
    
    public var depthTex:TextureObjectType;
    public var depthBufObj:RenderBufferObjectType;    

    // optional multisampling
    public var samples:Int;
    public var fboMS:FrameBufferObjectType; 
    public var colBufs:Array<Int>;
    
    public function new(_numColBufs:Int)
    {
        fbo = null;
        fboMS = null;

        width = 0;
        height = 0;

        depthTex = null;
        depthBufObj = null;

        samples = 0;

        colTexs = [];
        colBufs = [];
        for (i in 0..._numColBufs)
        {
            colTexs.push(0);
            colBufs.push(0);
        }
    }
}

typedef RDIRenderBufferData = {
    width:Int,
    height:Int,
    data:PixelData,
};


// ---------------------------------------------------------
// Sampler states
// ---------------------------------------------------------

class RDISamplerState
{
    inline public static var FILTER_BILINEAR:Int   = 0x0;
    inline public static var FILTER_TRILINEAR:Int  = 0x0001;
    inline public static var FILTER_POINT:Int      = 0x0002;

    inline public static var ADDRU_CLAMP:Int       = 0x0;
    inline public static var ADDRU_WRAP:Int        = 0x0040;
    inline public static var ADDRU_MIRRORED_REPEAT:Int    = 0x0080;
    
    inline public static var ADDRV_CLAMP:Int       = 0x0;
    inline public static var ADDRV_WRAP:Int        = 0x0100;
    inline public static var ADDRV_MIRRORED_REPEAT:Int    = 0x0200;

    inline public static var ADDR_CLAMP:Int        = ADDRU_CLAMP | ADDRV_CLAMP;
    inline public static var ADDR_WRAP:Int         = ADDRU_WRAP | ADDRV_WRAP;
    inline public static var ADDR_MIRRORED_REPEAT:Int     = ADDRU_MIRRORED_REPEAT | ADDRV_MIRRORED_REPEAT;
    //inline public static var COMP_LEQUAL:Int       = 0x1000;
}

// ---------------------------------------------------------
// Blendequation
// ---------------------------------------------------------

class RDIBlendEquationModes
{
    inline public static var ADD:Int = 0x8006;
    inline public static var SUBTRACT:Int = 0x800A;
    inline public static var REVERSE_SUBTRACT:Int = 0x800B;
    inline public static var MIN:Int = 0x8007;
    inline public static var MAX:Int = 0x8008;
}

// ---------------------------------------------------------
// Blend Factors
// ---------------------------------------------------------

class RDIBlendFactors
{
    inline public static var ZERO:Int                   = 0;
    inline public static var ONE:Int                    = 1;
    inline public static var SRC_COLOR:Int              = 0x0300;
    inline public static var ONE_MINUS_SRC_COLOR:Int    = 0x0301;
    inline public static var SRC_ALPHA:Int              = 0x0302;
    inline public static var ONE_MINUS_SRC_ALPHA:Int    = 0x0303;
    inline public static var DST_ALPHA:Int              = 0x0304;
    inline public static var ONE_MINUS_DST_ALPHA:Int    = 0x0305;
    inline public static var DST_COLOR:Int              = 0x0306;
    inline public static var ONE_MINUS_DST_COLOR:Int    = 0x0307;
}


// ---------------------------------------------------------
// Depth Test Modes
// ---------------------------------------------------------

class RDITestModes
{
    inline public static var DISABLE:Int    = 0;
    inline public static var NEVER:Int      = 0x0200;
    inline public static var LESS:Int       = 0x0201;
    inline public static var EQUAL:Int      = 0x0202;
    inline public static var LEQUAL:Int     = 0x0203;
    inline public static var GREATER:Int    = 0x0204;
    inline public static var NOTEQUAL:Int   = 0x0205;
    inline public static var GEQUAL:Int     = 0x0206;
    inline public static var ALWAYS:Int     = 0x0207;
}


// ---------------------------------------------------------
// Cull Modes
// ---------------------------------------------------------

class RDICullModes
{
    inline public static var FRONT:Int          = 0x0404;
    inline public static var BACK:Int           = 0x0405;    
    inline public static var FRONT_AND_BACK:Int = 0x0408;
    inline public static var NONE:Int           = 0;
}


// ---------------------------------------------------------
// Draw calls and clears
// ---------------------------------------------------------

class RDIClearFlags
{
    inline public static var NONE:Int = 0x0;
    inline public static var COLOR:Int = 0x00000001;
    inline public static var DEPTH:Int = 0x00000002;
    inline public static var ALL:Int = 0xFFFFFFFF;
}

/*
class RDIIndexFormat
{
    inline public static var FMT_16:Int = 0x1403;
    inline public static var FMT_32:Int = 0x1404;
}
*/

class RDIPrimType
{
    inline public static var LINES:Int = 0x0001;
    inline public static var TRIANGLES:Int = 0x0004;
    inline public static var TRISTRIP:Int = 0x0005;
    inline public static var QUADS:Int = 0x0007;
}

// =================================================================================================

class AbstractRenderDevice
{
    // Sampler State Access Masks
    inline public static var SS_FILTER_START:Int = 0;
    inline public static var SS_FILTER_MASK:Int = RDISamplerState.FILTER_BILINEAR | RDISamplerState.FILTER_TRILINEAR | RDISamplerState.FILTER_POINT;
    
    inline public static var SS_ADDRU_START:Int = 6;
    inline public static var SS_ADDRU_MASK:Int = RDISamplerState.ADDRU_CLAMP | RDISamplerState.ADDRU_WRAP | RDISamplerState.ADDRU_MIRRORED_REPEAT;
    
    inline public static var SS_ADDRV_START:Int = 8;
    inline public static var SS_ADDRV_MASK:Int = RDISamplerState.ADDRV_CLAMP | RDISamplerState.ADDRV_WRAP | RDISamplerState.ADDRV_MIRRORED_REPEAT;
    
    inline public static var SS_ADDR_START:Int = 6;
    inline public static var SS_ADDR_MASK:Int = RDISamplerState.ADDR_CLAMP | RDISamplerState.ADDR_WRAP | RDISamplerState.ADDR_MIRRORED_REPEAT;
    
    inline public static var PM_VIEWPORT:Int    = (1 << 0);
    inline public static var PM_INDEXBUF:Int    = (1 << 1);
    inline public static var PM_VERTLAYOUT:Int  = (1 << 2);
    inline public static var PM_TEXTURES:Int    = (1 << 3);
    inline public static var PM_SCISSOR:Int     = (1 << 4);
    inline public static var PM_BLEND:Int       = (1 << 5);
    inline public static var PM_CULLMODE:Int    = (1 << 6);
    inline public static var PM_DEPTH_TEST:Int  = (1 << 7);
    inline public static var PM_BLEND_EQ:Int    = (1 << 8);
    inline public static var PM_DEPTH_MASK:Int  = (1 << 9);

    public var m_ctx:RenderContext;
    var m_caps:RDIDeviceCaps;

    // viewport rect
    var m_vpX:Int;
    var m_vpY:Int;
    var m_vpWidth:Int;
    var m_vpHeight:Int;

    // scissor rect
    var m_scX:Int;
    var m_scY:Int;
    var m_scWidth:Int;
    var m_scHeight:Int;
    
    var m_curShaderId:Int;
    var m_prevShaderId:Int;
    var m_newVertLayout:Int;

    var m_curIndexBuf:Int;
    var m_newIndexBuf:Int;

    var m_curBlendEq:Int;
    var m_newBlendEq:Int;
    var m_blendEqBuffer:Int;

    var m_curSrcFactor:Int;
    var m_newSrcFactor:Int;

    var m_curDstFactor:Int;
    var m_newDstFactor:Int;

    var m_curCullMode:Int;
    var m_newCullMode:Int;

    var m_curDepthMask:Bool;
    var m_newDepthMask:Bool;

    var m_depthTestEnabled:Bool;
    var m_curDepthTest:Int;
    var m_newDepthTest:Int;

    var m_curRenderBuffer:Int;

    var m_pendingMask:Int;
    var m_activeVertexAttribsMask:Int;

    var m_bufferMem:Int;
    var m_textureMem:Int;
    
    // data
    var m_buffers:RDIObjects<RDIBuffer>;
    var m_textures:RDIObjects<RDITexture>;
    var m_shaders:RDIObjects<RDIShaderProgram>;
    var m_renBuffers:RDIObjects<RDIRenderBuffer>;

    var m_vertBufSlots:Array<RDIVertBufSlot>; // 16
    var m_vertexLayouts:Array<RDIVertexLayout>; // 16
    var m_texSlots:Array<RDITexSlot>; // 16

    var m_numVertexLayouts:Int;
    
    private function new(_ctx:RenderContext)
    {
        m_ctx = _ctx;

        m_vpX = 0;
        m_vpY = 0;
        m_vpWidth = 320;
        m_vpHeight = 240;

        m_scX = 0;
        m_scY = 0;
        m_scWidth = 320;
        m_scHeight = 240;

        m_curShaderId = 0;
        m_prevShaderId = 0;
        m_newVertLayout = 0;

        m_curIndexBuf = 1;
        m_newIndexBuf = 0;

        m_curBlendEq = RDIBlendEquationModes.SUBTRACT;
        m_newBlendEq = RDIBlendEquationModes.ADD;
        m_blendEqBuffer = -1;

        m_curSrcFactor = RDIBlendFactors.ZERO;
        m_newSrcFactor = RDIBlendFactors.ONE;
        m_curDstFactor = RDIBlendFactors.ONE;
        m_newDstFactor = RDIBlendFactors.ZERO;

        m_curCullMode = RDICullModes.NONE;
        m_newCullMode = RDICullModes.BACK;

        m_curDepthMask = false;
        m_newDepthMask = true;

        m_depthTestEnabled = false;
        m_curDepthTest = RDITestModes.GREATER;
        m_newDepthTest = RDITestModes.LESS;

        m_curRenderBuffer = 0;

        m_pendingMask = 0;
        m_activeVertexAttribsMask = 0;
        m_bufferMem = 0;
        m_textureMem = 0;
        m_caps = new RDIDeviceCaps();

        m_buffers = new RDIObjects<RDIBuffer>();
        m_textures = new RDIObjects<RDITexture>();
        m_shaders = new RDIObjects<RDIShaderProgram>();
        m_renBuffers = new RDIObjects<RDIRenderBuffer>();
        
        m_vertBufSlots = [];
        m_vertexLayouts = [];
        m_texSlots = [];
        for (i in 0...16)
        {
            m_vertBufSlots.push(null);
            m_texSlots.push(new RDITexSlot());
            m_vertexLayouts.push(new RDIVertexLayout());
        }
        
        m_numVertexLayouts = 0;

        init();
    }
    
    function init():Void
    {
        throw "NOT IMPLEMENTED";
    }

    //=============================================================================
    // vertex and index buffers
    //=============================================================================
    public function createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = -1):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function destroyBuffer(_handle:Int):Void { throw "NOT IMPLEMENTED"; }
    public function updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void { throw "NOT IMPLEMENTED"; }
    public function updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void { throw "NOT IMPLEMENTED"; }
    public function registerVertexLayout(_attribs:Array<RDIVertexLayoutAttrib>):Int
    {
        if (m_numVertexLayouts == 16) return 0; // TODO: WTF? does this make sense?
        m_vertexLayouts[m_numVertexLayouts].numAttribs = _attribs.length;
        for (i in 0..._attribs.length)
            m_vertexLayouts[m_numVertexLayouts].attribs[i] = _attribs[i];        
        return ++m_numVertexLayouts;
    }
    inline public function getBufferMem():Int { return m_bufferMem; }

    //=============================================================================
    // textures
    //=============================================================================
    public function createTexture(_type:Int, _width:Int, _height:Int, _format:Int, _hasMips:Bool, _genMips:Bool, ?_hintIsRenderTarget=false):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function uploadTextureData(_handle:Int, _slice:Int, _mipLevel:Int, _pixels:PixelData):Void { throw "NOT IMPLEMENTED"; }
    public function destroyTexture(_handle:Int):Void { throw "NOT IMPLEMENTED"; }
    public function calcTextureSize(_format:Int, _width:Int, _height:Int):Int
    {
        var s:Int = 0;
        switch (_format)
        {
            case RDITextureFormats.RGBA8: s = _width * _height * 4;
            case RDITextureFormats.RGBA16F: s = _width * _height * 8;
        }
        return s;
    }
    inline public function getTextureMem():Int { return m_textureMem; }

    //=============================================================================
    // shader programs
    //=============================================================================
    public function createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function destroyProgram(_handle:Int):Void { throw "NOT IMPLEMENTED"; }
    public function bindProgram(_handle:Int):Void { throw "NOT IMPLEMENTED"; }
    public function getActiveUniformCount(_handle:Int):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function getActiveUniformInfo(_handle:Int, _index:Int):RDIUniformInfo { throw "NOT IMPLEMENTED"; return null; }
    public function getUniformLoc(_handle:Int, _name:String):UniformLocationType { throw "NOT IMPLEMENTED"; return null; }
    public function getSamplerLoc(_handle:Int, _name:String):UniformLocationType { throw "NOT IMPLEMENTED"; return null; }
    public function setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void { throw "NOT IMPLEMENTED"; }
    public function setSampler(_loc:UniformLocationType, _texUnit:Int):Void { throw "NOT IMPLEMENTED"; }

    //=============================================================================
    // renderbuffers
    //=============================================================================
    public function createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function destroyRenderBuffer(_handle:Int):Void { throw "NOT IMPLEMENTED"; }
    public function getRenderBufferTex(_handle:Int, ?_bufIndex:Int=0):Int { throw "NOT IMPLEMENTED"; return 0; }
    public function bindRenderBuffer(_handle:Int):Void { throw "NOT IMPLEMENTED"; }
    public function getRenderBufferData(_handle:Int, ?_bufIndex:Int=0):RDIRenderBufferData { throw "NOT IMPLEMENTED"; return null; }

    //=============================================================================
    // state handling
    //=============================================================================
    public function commitStates(?_filter=0xFFFFFFFF):Bool { throw "NOT IMPLEMENTED"; return false; }
    public function resetStates():Void { 
        m_curIndexBuf = 1;
        m_newIndexBuf = 0;

        m_curBlendEq = RDIBlendEquationModes.SUBTRACT;
        m_newBlendEq = RDIBlendEquationModes.ADD;
        m_blendEqBuffer = -1;

        m_curSrcFactor = RDIBlendFactors.ZERO;
        m_newSrcFactor = RDIBlendFactors.ONE;

        m_curDstFactor = RDIBlendFactors.ONE;
        m_newDstFactor = RDIBlendFactors.ZERO;

        m_curCullMode = RDICullModes.NONE;
        m_newCullMode = RDICullModes.BACK;

        m_curDepthMask = false;
        m_newDepthMask = true;
        
        m_depthTestEnabled = false;
        m_curDepthTest = RDITestModes.GREATER;
        m_newDepthTest = RDITestModes.LESS;

        for (i in 0...16)
            setTexture(i, 0, 0);

        m_activeVertexAttribsMask = 0;

        m_pendingMask = 0xFFFFFFFF;
        commitStates();
    }
    public function isLost():Bool { throw "NOT IMPLEMENTED"; return true; }

    function applyVertexLayout():Bool { throw "NOT IMPLEMENTED"; return false; }
    function applySamplerState(_tex:RDITexture):Void { throw "NOT IMPLEMENTED"; }

    //=============================================================================
    // drawcalls and clears
    //=============================================================================
    public function clear(_flags:Int, ?_r:Float = 0, ?_g:Float = 0, ?_b:Float = 0, ?_a:Float = 1, ?_depth:Float = 1):Void { throw "NOT IMPLEMENTED"; }
    public function draw(_primType:Int, _numInds:Int, _offset:Int):Void { throw "NOT IMPLEMENTED"; }
    public function drawArrays(_primType:Int, _offset:Int, _size:Int):Void { throw "NOT IMPLEMENTED"; }

    //=============================================================================
    // commands
    //=============================================================================
    public function setViewport(_x:Int, _y:Int, _width:Int, _height:Int):Void
    {
        m_vpX = _x; m_vpY = _y; 
        m_vpWidth = _width; m_vpHeight = _height;
        m_pendingMask |= ARD.PM_VIEWPORT;
    }
    public function setScissorRect(_x:Int, _y:Int, _width:Int, _height:Int):Void
    {
        m_scX = _x; m_scY = _y; 
        m_scWidth = _width; m_scHeight = _height;
        m_pendingMask |= ARD.PM_SCISSOR;
    }
    public function setIndexBuffer(_handle:Int):Void
    {
        m_newIndexBuf = _handle;
        m_pendingMask |= ARD.PM_INDEXBUF;
    }
    public function setVertexBuffer(_slot:Int, _handle:Int, ?_offset:Int = 0, ?_stride:Int = 0):Void
    {
        m_vertBufSlots[_slot] = new RDIVertBufSlot(_handle, _offset, _stride);
        m_pendingMask |= ARD.PM_VERTLAYOUT;
    }
    public function setVertexLayout(_vlObj:Int):Void
    {
        m_newVertLayout = _vlObj;
    }
    public function setTexture(_slot:Int, _handle:Int, _samplerState:Int):Void
    {
        m_texSlots[_slot] = new RDITexSlot(_handle, _samplerState);
        m_pendingMask |= ARD.PM_TEXTURES;
    }
    public function setBlendEquation(?_mode:Int=RDIBlendEquationModes.ADD, ?_bufIndex:Int=-1) 
    {
        m_newBlendEq = _mode;
        m_blendEqBuffer = _bufIndex;
        m_pendingMask |= ARD.PM_BLEND_EQ;
    }
    public function setBlendFunc(?_srcFactor:Int=RDIBlendFactors.ONE, ?_dstFactor:Int=RDIBlendFactors.ZERO):Void 
    { 
        m_newSrcFactor = _srcFactor;
        m_newDstFactor = _dstFactor;
        m_pendingMask |= ARD.PM_BLEND;
    }
    public function setCullMode(_mode:Int):Void
    {
        m_newCullMode = _mode;
        m_pendingMask |= ARD.PM_CULLMODE;
    }
    public function setDepthMask(_enable:Bool):Void {
        m_newDepthMask = _enable;
        m_pendingMask |= ARD.PM_DEPTH_MASK;
    }
    public function setDepthFunc(_mode:Int=RDITestModes.LESS):Void
    {
        m_newDepthTest = _mode;
        m_pendingMask |= ARD.PM_DEPTH_TEST;
    }
    inline public function getDeviceCaps():RDIDeviceCaps {
        return m_caps;
    }
}

