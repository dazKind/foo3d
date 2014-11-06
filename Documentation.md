# api documentation


foo3d.AbstractRenderDevice
---

This class is the abstract parent of all renderdevice implementations.

### createVertexBuffer(...)

```haxe
createVertexBuffer(_size:Int, _data:VertexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC, ?_strideHint = -1):Int
```

Creates a vertexbuffer.

__Parameters:__

 * _size:Int -- length of data in bytes.
 * _data:[VertexBufferData](#foo3d-vertexbufferdata) -- a buffer holding the data to be uploaded. Right now we assume this buffer contains only floats as bytes.
 * _usageHint:Int -- RDIBufferUsage.STREAM, RDIBufferUsage.STATIC or RDIBufferUsage.DYNAMIC. There is no guarantee the backend will listen to this.
 * _strideHint:Int -- count of elements(not bytes) a vertex will use in the buffer.

__Returns:__

 * Integer -- Unique Handle of buffer

### createIndexBuffer(...)

```haxe
createIndexBuffer(_size:Int, _data:IndexBufferData, ?_usageHint:Int = RDIBufferUsage.STATIC):Int
```

Creates an indexbuffer.

__Parameters:__

 * _size:Int -- length of data in bytes.
 * _data:[IndexBufferData](#foo3d-indexbufferdata) -- a buffer holding the data to be uploaded. Right now we assume this buffer contains only unsigned shorts as bytes.
 * _usageHing:Int -- RDIBufferUsage.STREAM, RDIBufferUsage.STATIC or RDIBufferUsage.DYNAMIC. There is no guarantee the backend will listen to this.

__Returns:__

 * Integer -- Unique Handle of buffer

### destroyBuffer(...)

```haxe
destroyBuffer(_handle:Int):Void
```

Destroys the buffer(vertex or index) with the specified handle.

__Parameters:__

 * _handle:Int -- unique handle of buffer that was returned when creating the buffer.


### updateVertexBufferData(...)

```haxe
updateVertexBufferData(_handle:Int, _offset:Int, _size:Int, _data:VertexBufferData):Void
```

Updates the content of an existing vertexbuffer.

__Parameters:__

 * _handle:Int -- Unique handle of a previously created buffer.
 * _offset:Int -- start of the data to be updated in bytes.
 * _size:Int -- length of data to be updated in bytes.
 * _data:[VertexBufferData](#foo3d-vertexbufferdata) -- the buffer containing the new data.


### updateIndexBufferData(...)

```haxe
updateIndexBufferData(_handle:Int, _offset:Int, _size:Int, _data:IndexBufferData):Void
```

Updates the content of an existing indexbuffer.

__Parameters:__

 * _handle:Int -- Unique handle of a previously created buffer.
 * _offset:Int -- start of the data to be updated in bytes.
 * _size:Int -- length of data to be updated in bytes.
 * _data:[IndexBufferData](#foo3d-indexbufferdata) -- the buffer containing the new data.


### registerVertexLayout(...)

```haxe
registerVertexLayout(_attribs:Array<RDIVertexLayoutAttrib>):Int
```

Registers a layout of vertex attributes in the system. These are required in order to match the contents of a vertexbuffer to the constant semantics in a vertexshader.

__Parameters:__

 * _attribs:Array<[RDIVertexLayoutAttrib](#foo3d-rdivertexlayoutattrib)> -- a valid Array containing RDIVertexLayoutAttrib.
 
__Returns:__

 * Integer -- Unique id of slot where the layout is stored.

__Example:__
```haxe
skinnedVertexLayout = myRenderDevice.registerVertexLayout([
    new RDIVertexLayoutAttrib("vPos", 0, 3, 0),
    new RDIVertexLayoutAttrib("vNormal", 0, 3, 3),
    new RDIVertexLayoutAttrib("vTangent", 0, 3, 6),
    new RDIVertexLayoutAttrib("vBitangent", 0, 3, 9),
    new RDIVertexLayoutAttrib("vUv", 0, 2, 12),
    new RDIVertexLayoutAttrib("vUv2", 0, 2, 14),
    new RDIVertexLayoutAttrib("vJointIndices", 0, 4, 16),
    new RDIVertexLayoutAttrib("vWeights", 0, 4, 20)
]);
```

### getBufferMem(...)

```haxe
getBufferMem():Int
```

Returns the size of the allocated memory for all buffers.

__Returns:__

 * Integer -- The count of bytes all buffers in the system use.


### createTexture(...)

```haxe
createTexture(_type:Int, _width:Int, _height:Int, _format:Int, _hasMips:Bool, _genMips:Bool, ?_hintIsRenderTarget=false):Int
```

Creates a texture.

__Parameters:__

 * _type:Int -- RDITextureTypes.TEX2D or RDITextureTypes.TEXCUBE
 * _width:Int -- Width of the texture
 * _height:Int -- Height of the texture
 * _format:Int -- RDITextureFormats.RGBA8, RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F or RDITextureFormats.DEPTH. <b>You need to make sure your target supports the format!</b>
 * _hasMips:Bool -- Does the texture contain mipmaps?
 * _genMips:Bool -- Should we generate the mipmaps?
 * _hintIsRenderTarget:Bool -- Hint for the system that this texture might be a rendertarget. There is no guarantee the system listens for this.

__Returns:__

 * Integer -- Unique handle of the texture.


### uploadTextureData(...)

```haxe
uploadTextureData(_handle:Int, _slice:Int, _mipLevel:Int, _pixels:PixelData):Void
```

Upload imagedata to a texture.

__Parameters:__

 * _handle:Int -- Unique handle of a previously created texture.
 * _slice:Int -- if this a Cubemap define the slice you want to upload, otherwise always 0.
 * _mipLevel:Int -- to which miplevel you want to upload.
 * _pixels:[PixelData](#foo3d-pixeldata) -- The actual pixeldata you want to upload.



### destroyTexture(...)

```haxe
destroyTexture(_handle:Int):Void
```

Destroy a texture.

__Parameters:__

 * _handle:Int -- Unique handle of a previously created texture.
 

### getTextureMem(...)

```haxe
getTextureMem():Int
```

Returns the memory of all allocated textures.

__Returns:__

 * Integer -- The count of bytes all texures in the system use.

### createProgram(...)
```haxe
createProgram(_vertexShaderSrc:String, _fragmentShaderSrc:String):Int
```
Creates a shader program from a vertex and fragment shader

__Parameters:__

 * _vertexShader:String -- Should be the source of a valid vertexshader
 * _fragmentShader:String -- Should be the source of a valid fragmentshader

__Returns:__

* Integer -- Unique handle of program

### destroyProgram(...)
```haxe
destroyProgram(_handle:Int):Void
```

Destroys a shader program

__Parameters:__

* _handle:Int -- Unique ID of a previously created program

### bindProgram(...)
```haxe
bindProgram(_handle:Int):Void
```

Binds the specified program to the pipeline

__Parameters:__

 * _handle:Int -- Unique ID of a shader program


### getActiveUniformCount(...)
```haxe
getActiveUniformCount(_handle:Int):Int
```

Gets the count of active uniforms from shaderprogram.

__Parameters:__

 * _handle:Int -- Unique handle of previously created buffer

__Returns:__

 * Integer -- Count of active uniforms

### getActiveUniformInfo(...)
```haxe
getActiveUniformInfo(_handle:Int, _index:Int):RDIUniformInfo
```

Get the info from the specified program at the given index. 

__Parameters:__

 * _handle:Int -- Unique handle of program to query
 * _index:Int -- Uniformindex. The index has be in the range of 0 and getActiveUniformCount().

__Returns:__

 * [RDIUniformInfo](#foo3d-rdiuniforminfo) -- Structure containing the details about the uniform.


### getUniformLoc(...)
```haxe
getUniformLoc(_handle:Int, _name:String):UniformLocationType
```

Get the location of the uniform in the program. This is later used to set a uniform of a bound program.

__Parameters:__

 * _handle:Int -- Unique handle of the program you want to query.
 * _name:String -- Name of the semantic you wanna query.

__Returns:__

 * [UniformLocationType](#foo3d-uniformlocationtype) -- Structure representing the location of the uniform.

### getSamplerLoc(...)
```haxe
getSamplerLoc(_handle:Int, _name:String):UniformLocationType
```

Get the location of the sampler in the program. This is later used to set a sampler of a bound program.

__Parameters:__
 
 * _handle:Int -- Unique handle of program.
 * _name:String -- Name of the sampler you wanna query.

__Returns:__

 * [UniformLocationType](#foo3d-uniformlocationtype) -- Structure representing the location of the sampler.

### setUniform(...)
```haxe
setUniform(_loc:UniformLocationType, _type:Int, _values:Array<Float>):Void
```

Set the data for a uniforms. <b>NOTE: Only floats are supported at the moment.</b>

__Parameters:__

 * _loc:[UniformLocationType](#foo3d-uniformlocationtype) -- Location previously queried with [getUniformLoc](foo3d-getuniformloc).
 * _type:Int -- Should indicate the type of data you wanna set. Can be RDIShaderConstType.FLOAT, RDIShaderConstType.FLOAT2, RDIShaderConstType.FLOAT3, RDIShaderConstType.FLOAT4, RDIShaderConstType.FLOAT33 or RDIShaderConstType.FLOAT44.
 * _values:Array<Float> -- Array containing the float data.


### setSampler(...)
```haxe
setSampler(_loc:UniformLocationType, _texUnit:Int):Void
```

Link an uniform-location to an active Textureunit.

__Parameters:__

 * _loc:[UniformLocationType](#foo3d-uniformlocationtype) -- Location previously queried with [getSamplerLoc](foo3d-getsamplerloc).
 * _texUnit:Int -- id of the texture-unit to link

### createRenderBuffer(...)
```haxe
createRenderBuffer(_width:Int, _height:Int, _format:Int, _depth:Bool, ?_numColBufs:Int=1, ?_samples:Int = 0):Int
```

Create a new renderbuffer from the supplied settings.

__Parameters:__

 * _width:Int -- width in texels.
 * _height:Int -- height in texels.
 * _format:Int -- RDITextureFormats.RGBA8, RDITextureFormats.RGBA16F, RDITextureFormats.RGBA32F or RDITextureFormats.DEPTH. <b>You need to make sure your target supports the format!</b>
 * _depth:Bool -- Whether you want a depthbuffer or not.
 * _numColBufs:Int -- Set the count of colorbuffers the renderbuffer should have. This is used for MRT. <b>You need to make sure your target supports a count > 1!</b>
 * _samples:Int -- If your target supports multisampling you can set amount of sampling here.

__Results:__

 * Integer -- Unique handle of renderbuffer.

### destroyRenderBuffer(...)
```haxe
destroyRenderBuffer(_handle:Int):Void
```

Destroys a previously created Renderbuffer.

__Parameters:__

 * _handle:Int -- Unique handle of a renderbuffer.

### getRenderBufferTex(...)
```haxe
getRenderBufferTex(_handle:Int, ?_bufIndex:Int=0):Int
```

Get the texture of the renderbuffer. That's usefull if you want to bind the content of a renderbuffer to a texunit.

__Parameters:__

 * _handle:Int -- Unique handle of a renderbuffer.
 * _bufIndex:Int -- Index of the colorbuffer to get. Usefull if your target supports MRT.

__Returns:__

 * Integer -- Unique id of texture.

### bindRenderBuffer(...)
```haxe
bindRenderBuffer(_handle:Int):Void
```

Bind the specified renderbuffer to the pipeline.

__Parameters:__

 * _handle:Int -- Unique id of renderbuffer.

### getRenderBufferData(...)
```haxe
getRenderBufferData(_handle:Int, ?_bufIndex:Int=0):RDIRenderBufferData
```

Get the specified colorbuffer from the renderbuffer as raw-data. <b>Warning: This might impact your performance since it's a read on the GPU!</b>

__Parameters:__

 * _handle:Int -- Unique handle of renderbuffer.
 * _bufIndex:Int -- Index of the colorbuffer to get. Usefull if your target supports MRT.

__Result:__

* [RDIRenderBufferData](#foo3d-rdirenderbufferdata) -- structure containing the raw-data of the specified colorbuffer of the renderbuffer.

### commitStates(...)
```haxe
commitStates(?_filter:Int=0xFFFFFFFF):Bool
```

Commit all previously set state to the pipeline. This function applies "Lazy evaluation" to minimize pipeline statechanges. Only the state that changed since the last commit is updated! This function is called internally before each drawcall.

__Parameters:__

 * _filter:Int -- Bitmask. Can contain the following flags: RenderDevice.PM_VIEWPORT, RenderDevice.PM_INDEXBUF, RenderDevice.PM_VERTLAYOUT, RenderDevice.PM_TEXTURES, RenderDevice.PM_SCISSOR, RenderDevice.PM_BLEND, RenderDevice.PM_CULLMODE, RenderDevice.PM_DEPTH_TEST, RenderDevice.PM_BLEND_EQ or RenderDevice.PM_DEPTH_MASK.

__Returns:__

 * Bool -- If the commit was successfull.

### resetStates()
```haxe
resetStates()
```

Reset the pipeline-state back to its defaults.



### isLost()
```haxe
isLost():Bool
```

Query the state of the context. <b>This might not work on all platforms.</b>

__Returns:__

 * Bool -- true/false if context was lost


### clear(...)
```haxe
clear(_flags:Int, ?_r:Float = 0, ?_g:Float = 0, ?_b:Float = 0, ?_a:Float = 1, ?_depth:Float = 1):Void
```

Clear the color and/or depthbuffer with the specified values.

__Parameters:__

 * _flags:Int -- What to clear. One of RDIClearFlags.NONE, RDIClearFlags.COLOR, RDIClearFlags.DEPTH and RDIClearFlags.ALL
 * _r:Float -- red value
 * _g:Float -- green value
 * _b:Float -- blue value
 * _a:Float -- alpha value
 * _depth:Float -- depth value


### setViewport(...)
```haxe
setViewport(_x:Int, _y:Int, _width:Int, _height:Int):Void
```

Set the viewport rectangle of the buffer to render to. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _x:Int -- x-axis position of the rectangle.
 * _y:Int -- y-axis position of the rectangle.
 * _width:Int -- width of the rectangle.
 * _height:Int -- height of the rectangle.


### setScissorRect(...)
```haxe
setScissorRect(_x:Int, _y:Int, _width:Int, _height:Int):Void
```

Set the scissor rectangle of the buffer to render to. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _x:Int -- x-axis position of the rectangle.
 * _y:Int -- y-axis position of the rectangle.
 * _width:Int -- width of the rectangle.
 * _height:Int -- height of the rectangle.


### setIndexBuffer(...)
```haxe
setIndexBuffer(_handle:Int):Void
```

Set the current indexbuffer for the next drawcall. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _handle:Int -- Unique handle of previously created indexbuffer.


### setVertexBuffer(...)
```haxe
setVertexBuffer(_slot:Int, _handle:Int, ?_offset:Int = 0, ?_stride:Int = 0):Void
```

Assign the current vertexbuffer to the specified slot for the next drawcall. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _slot:Int -- id of bufferunit to assign the specified buffer to.
 * _handle:Int -- Unique handle of previously created vertexbuffer.
 * _offset:Int -- Offset from the start of the vertexbuffer in elements. You can use this to bind a partial buffer.
 * _stride:Int -- Count of elements per vertexdata.

### setVertexLayout(...)
```haxe
setVertexLayout(_vlObj:Int):Void
```

Set the current vertexlayout you want to use with your bound vertexbuffer. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _vlObj:Int -- Unique handle of a previously created layout.


### setTexture(...)
```haxe
setTexture(_slot:Int, _handle:Int, _samplerState:Int):Void
```

Assign the current texture to the specified textureunit for the next drawcall. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _slot:Int -- id of textureunit to assign the specified texture to.
 * _handle:Int -- Unique handle of a previously created texture.
 * _samplerState:Int -- Bitmask. Can contain the following 
   * RDISamplerState.FILTER_BILINEAR
   * RDISamplerState.FILTER_TRILINEAR
   * RDISamplerState.FILTER_POINT 
   * RDISamplerState.ADDR_CLAMP 
   * RDISamplerState.ADDR_WRAP 
   * RDISamplerState.ADDR_MIRRORED_REPEAT 
   * RDISamplerState.ADDRU_CLAMP 
   * RDISamplerState.ADDRU_WRAP 
   * RDISamplerState.ADDRU_MIRRORED_REPEAT 
   * RDISamplerState.ADDRV_CLAMP 
   * RDISamplerState.ADDRV_WRAP 
   * RDISamplerState.ADDRV_MIRRORED_REPEAT

### setBlendEquation(...)
```haxe
setBlendEquation(?_mode:Int=RDIBlendEquationModes.ADD, ?_bufIndex:Int=-1) 
```

Set the current blending equation. <b>You can specify different equations for different colorbuffers if your target supports MRT!</b> Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _mode:Int -- Can be one of the following RDIBlendEquationModes.ADD, RDIBlendEquationModes.SUBTRACT, RDIBlendEquationModes.REVERSE_SUBTRACT, RDIBlendEquationModes.MIN or RDIBlendEquationModes.MAX. <b>MIN or MAX are not supported on Opengl ES 2.0 based targets!</b>
 * _bufIndex -- Buffer for which to set the equation.


### setBlendFunc(...)
```haxe
setBlendFunc(?_srcFactor:Int=RDIBlendFactors.ONE, ?_dstFactor:Int=RDIBlendFactors.ZERO):Void 
```

Set the blendfunction for your next drawcall. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _srcFactor:Int -- Can be one of the following:
   * RDIBlendFactors.ZERO
   * RDIBlendFactors.ONE
   * RDIBlendFactors.SRC_COLOR
   * RDIBlendFactors.ONE_MINUS_SRC_COLOR
   * RDIBlendFactors.SRC_ALPHA
   * RDIBlendFactors.ONE_MINUS_SRC_ALPHA
   * RDIBlendFactors.DST_ALPHA
   * RDIBlendFactors.ONE_MINUS_DST_ALPHA
   * RDIBlendFactors.DST_COLOR
   * RDIBlendFactors.ONE_MINUS_DST_COLOR
 * _dstFactor:Int -- Can be one of the following:
   * RDIBlendFactors.ZERO
   * RDIBlendFactors.ONE
   * RDIBlendFactors.SRC_COLOR
   * RDIBlendFactors.ONE_MINUS_SRC_COLOR
   * RDIBlendFactors.SRC_ALPHA
   * RDIBlendFactors.ONE_MINUS_SRC_ALPHA
   * RDIBlendFactors.DST_ALPHA
   * RDIBlendFactors.ONE_MINUS_DST_ALPHA
   * RDIBlendFactors.DST_COLOR
   * RDIBlendFactors.ONE_MINUS_DST_COLOR

### setCullMode(...)
```haxe
setCullMode(_mode:Int):Void
```

Set the current geometry-cullmode. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _mode:Int -- Can be one of the following:
   * RDICullModes.FRONT
   * RDICullModes.BACK
   * RDICullModes.FRONT_AND_BACK
   * RDICullModes.NONE


### setDepthMask(...)
```haxe
setDepthMask(_mode:Int):Void
```

Enable/Disable depthmasking. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _enable:Int -- true/false.


### setDepthFunc(...)
```haxe
setDepthFunc(?_mode:Int=RDITestModes.LESS):Void
```

Set the current depthfunc. Calling this function doesnt apply the state directly. It is evaluated lazily through [commitStates](#foo3d-commitstates) or right before each drawcall.

__Parameters:__

 * _mode:Int -- Can be one of the following:
   * RDITestModes.DISABLE
   * RDITestModes.NEVER
   * RDITestModes.LESS
   * RDITestModes.EQUAL
   * RDITestModes.LEQUAL
   * RDITestModes.GREATER
   * RDITestModes.NOTEQUAL
   * RDITestModes.GEQUAL
   * RDITestModes.ALWAYS

### getDeviceCaps(...)
```haxe
getDeviceCaps():RDIDeviceCaps
```

Query the capabilites of your renderdevice.

__Returns:__
 
 * [RDIDeviceCaps](#foo3d-rdidevicecaps) -- structure containing details about the capabilities of the renderdevice.

### draw(...)
```haxe
draw(_primType:Int, _type:Int, _numInds:Int, _offset:Int):Void
```

Draw the currently bound primitives. <b>Make sure your target supports the primitiveType!</b>

__Parameters:__

 * _primType:Int -- Can be one of the following: 
   * RDIPrimType.LINES
   * RDIPrimType.TRIANGLES
   * RDIPrimType.TRISTRIP
   * RDIPrimType.QUADS
 * _type:Int -- Needs to match the indexbuffer data that is bound. Can be one of the following:
   * RDIDataType.UNSIGNED_BYTE
   * RDIDataType.UNSIGNED_SHORT
   * RDIDataType.UNSIGNED_INT
   * RDIDataType.FLOAT
 * _numInds:Int -- Number of elements in the indexbuffer to use for the drawcall.
 * _offset:Int -- Offset from the start of the indexbuffer in elements.


foo3d.RenderDevice
---
```haxe
#if js
    typedef RenderDevice = foo3d.impl.WebGLRenderDevice;
#elseif flash
    typedef RenderDevice = foo3d.impl.Stage3DRenderDevice;
#elseif cpp
    #if foo3d_use_lime
        typedef RenderDevice = foo3d.impl.LimeRenderDevice;
    #else
        typedef RenderDevice = foo3d.impl.OpenGLRenderDevice;
    #end
#end
```

foo3d.impl.LimeRenderDevice
---
__Inheritance:__ foo3d.impl.LimeRenderDevice --> foo3d.AbstractRenderDevice

This renderdevice can be used on all targets. It follows the OpenGL ES 2.0 spec.

foo3d.impl.OpenGLRenderDevice
---
__Inheritance:__ foo3d.impl.OpenGLRenderDevice --> foo3d.AbstractRenderDevice

This renderdevice is an advanced backend dedicated to desktop-platforms. It uses GLEW for feature discovery and allows the usage of multiple rendertargets(MRT) and multisampling.

foo3d.impl.Stage3DRenderDevice
---
__Inheritance:__ foo3d.impl.Stage3DRenderDevice --> foo3d.AbstractRenderDevice

This renderdevice implements the flash11 Stage3D-API and consumes AGAL-shaders.

#THIS IMPLEMENTATION IS DEPRECATED. DONT USE.

foo3d.impl.WebGLRenderDevice
---
__Inheritance:__ foo3d.impl.WebGLRenderDevice --> foo3d.AbstractRenderDevice

This renderdevice implements webgl which corresponds the OpenGL ES 2.0 spec.


foo3d.RDIDeviceCaps
---

Contains capabilities of the current renderdevice. Use this to determine feature-usage on your target. It's the result of a [getDeviceCaps(...)](#getdevicecaps) query.

__Members:__

```haxe
    public var texFloatSupport:Bool;
    public var texNPOTSupport:Bool;
    public var rtMultisampling:Bool;
    public var maxVertAttribs:Int;
    public var maxVertUniforms:Int;
    public var maxColorAttachments:Int;
    public var maxTextureUnits:Int;
```


foo3d.RDIRenderBufferData
---

Contains the raw and metadata of a colorbuffer of a renderbuffer. It's the result of a [getRenderBufferData(...)](#getrenderbufferdata) query.

__Members:__

```haxe
    public var width:Int;
    public var height:Int;
    public var data:PixelData;
```


foo3d.RDIUniformInfo
---

Contains the name and type of an shader program uniform. Is the result of a [getActiveUniformInfo(...)](#getactiveuniforminfo) query.

__Members:__

```haxe
    public var name:String;
    public var type:Int;
```


foo3d.RDIVertexLayoutAttrib
---

### new(...)
```haxe
new(?_semanticName:String = "", ?_vbSlot:Int = 0, ?_size:Int = 0, ?_offset:Int = 0)
```

__Parameters:__

 * _semanticName:String -- Name of of semantic in the shader.
 * _vbSlot:Int -- id of slot where the corresponding vertexbuffer is bound
 * _size:Int -- count of elements this attribute should contain. "vec3" corresponds to 3 floats, thus a size of 3.
 * _offset:Int -- offset from the start of the of the buffer in elements.

foo3d.RenderContext
---
```haxe
#if js
    typedef RenderContext = js.html.webgl.RenderingContext;
#elseif flash
    typedef RenderContext = flash.display3D.Context3D;
#elseif cpp
    typedef RenderContext = Null<Int>;
#end
```

foo3d.BufferObjectType
---
```haxe
#if js
    typedef BufferObjectType = js.html.webgl.Buffer;
#elseif flash
    typedef BufferObjectType = { vbuf:VertexBuffer3D, ibuf:IndexBuffer3D };
#elseif cpp
    typedef BufferObjectType = Null<Int>;
#end
```

foo3d.TextureObjectType
---
```haxe
#if js
    typedef TextureObjectType = js.html.webgl.Texture;
#elseif flash
    typedef TextureObjectType = flash.display3D.textures.TextureBase;
#elseif cpp
    typedef TextureObjectType = Null<Int>;
#end
```

foo3d.TextureFormatType
---
```haxe
#if js
    typedef TextureFormatType = Null<Int>;
#elseif flash
    typedef TextureFormatType = flash.display3D.Context3DTextureFormat;
#elseif cpp
    typedef TextureFormatType = Null<Int>;
#end
```

foo3d.ShaderProgramType
---
```haxe
#if js
    typedef ShaderProgramType = js.html.webgl.Program;
#elseif flash
    typedef ShaderProgramType = { prog:Program3D, vsInfo:Dynamic, fsInfo:Dynamic };
#elseif cpp
    typedef ShaderProgramType = Null<Int>;
#end
```

foo3d.UniformLocationType
---
```haxe
#if js
    typedef UniformLocationType = js.html.webgl.UniformLocation;
#elseif flash
    typedef UniformLocationType = { vsLoc:Null<Int>, fsLoc:Null<Int> };
#elseif cpp
    typedef UniformLocationType = Null<Int>;
#end
```

foo3d.FrameBufferObjectType
---
```haxe
#if js
    typedef FrameBufferObjectType = js.html.webgl.Framebuffer;
#elseif flash
    typedef FrameBufferObjectType = Dynamic;
#elseif cpp
    typedef FrameBufferObjectType = Null<Int>;
#end
```

foo3d.RenderBufferObjectType
---
```haxe
#if js
    typedef RenderBufferObjectType = js.html.webgl.Renderbuffer;
#elseif flash
    typedef RenderBufferObjectType = Null<Bool>;
#elseif cpp
    typedef RenderBufferObjectType = Null<Int>;
#end
```


foo3d.VertexBufferData
---
```haxe
typedef VertexBufferData = haxe.io.Bytes;
```

foo3d.IndexBufferData
---
```haxe
typedef IndexBufferData = haxe.io.Bytes;
```

foo3d.PixelData
---
```haxe
#if js
    typedef PixelData = Dynamic; // this should be an image-tag!
#elseif flash
    typedef PixelData = flash.display.BitmapData;
#elseif cpp
    typedef PixelData = haxe.io.BytesData;
#end
```






