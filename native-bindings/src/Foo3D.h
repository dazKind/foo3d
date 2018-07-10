
#ifndef __FOO3D_H__
#define __FOO3D_H__

#if defined(HX_ANDROID)
    #include <GLES2/gl2.h>
    #include <GLES2/gl2ext.h>
	#define FOO3D_GLES 1
#elif defined(IPHONE) || defined(__IPHONEOS__) || defined(APPLETVOS) || defined(APPLETVSIM)
    #include <OpenGLES/ES2/gl.h>
    #include <OpenGLES/ES2/glext.h>
	#define FOO3D_GLES 1
#else
    #include <GL/glew.h>
#endif


namespace foo3d {

    const unsigned int color_buffers[] = {
        GL_COLOR_ATTACHMENT0, 
        #if !defined(FOO3D_GLES)
	        GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3,  
	        GL_COLOR_ATTACHMENT4, GL_COLOR_ATTACHMENT5, GL_COLOR_ATTACHMENT6, GL_COLOR_ATTACHMENT7,  
	        GL_COLOR_ATTACHMENT8, GL_COLOR_ATTACHMENT9, GL_COLOR_ATTACHMENT10, GL_COLOR_ATTACHMENT11,  
	        GL_COLOR_ATTACHMENT12, GL_COLOR_ATTACHMENT13, GL_COLOR_ATTACHMENT14, GL_COLOR_ATTACHMENT15  
	    #endif
    };
}

#endif /* __FOO3D_H__ */
