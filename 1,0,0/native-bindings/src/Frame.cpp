#include "Foo3D.h"
#include <gl/glut.h>

namespace foo3D {
	// this is the wrapper for the foo3d render call
	AutoGCRoot *onRender;
	void render() {
		val_call0(onRender->get());
	    glutSwapBuffers();
	}

	// window and rendercontext setup
	value hx_glut_Setup(value _windowName, value _width, value _height, value _onPaint) {
		onRender = new AutoGCRoot(_onPaint);

		int argc = 1, handle = -1;
		char* windowName = (char*)val_string(_windowName);
		char* argv[] = {windowName, NULL};
		
		glutInit(&argc, argv);
		glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
		glutInitWindowSize(val_int(_width),val_int(_height));
		
		handle = glutCreateWindow(windowName);
		glutDisplayFunc(render);
		glutIdleFunc(render);
		
		return alloc_int(handle);
	}
	DEFINE_PRIM(hx_glut_Setup, 4);

	void hx_glut_MainLoop() {
		glutMainLoop();
	}
	DEFINE_PRIM(hx_glut_MainLoop, 0);
}