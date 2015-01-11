library OpenGL32;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  System.SysUtils,
  System.Classes,
  gl in 'gl.pas',
  wgl in 'wgl.pas',
  soft3d in 'soft3d.pas',
  Utils in 'Utils.pas',
  Vector3DHelper in 'Vector3DHelper.pas',
  Parallel in 'Parallel.pas';

{$R *.res}

exports
  glBegin,
  glClear,
  glClearColor,
  glColor3f,
  glDisable,
  glEnable,
  glEnd,
  glEvalCoord1f, glEvalCoord2f,
  glEvalMesh1, glEvalMesh2,
  glEvalPoint2,
  glFlush,
  glFrustum,
  glGetError,
  glGetFloatv, glGetIntegerv, glGetString,
  glLoadIdentity,
  glMap1f, glMap2f,
  glMapGrid1f, glMapGrid2d,
  glMatrixMode,
  glMultMatrixd, glMultMatrixf,
  glNormal3f, glNormal3fv,
  glOrtho,
  glPixelStorei,
  glPointSize,
  glPolygonMode,
  glPopAttrib,
  glPopMatrix,
  glPushAttrib,
  glPushMatrix,
  glScalef,
  glTexCoord2f,
  glTexImage1D, glTexImage2D,
  glTranslatef, glTranslated,
  glVertex3f, glVertex3fv, glVertex3i,
  glViewport,

  wglCreateContext,
  wglMakeCurrent,
  wglDeleteContext,
  wglChoosePixelFormat,
  wglSwapBuffers;

begin
end.
