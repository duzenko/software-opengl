unit gl;

interface uses
  Windows, Types, OpenGL;

procedure glBegin (mode: GLenum); stdcall;
procedure glClear (mask: GLbitfield); stdcall;
procedure glClearColor (red, green, blue, alpha: GLclampf); stdcall;
procedure glColor3f (red, green, blue: GLfloat); stdcall;
procedure glDisable (cap: GLenum); stdcall;
procedure glEnable (cap: GLenum); stdcall;
procedure glEnd; stdcall;
procedure glEvalCoord1f (u: GLfloat); stdcall;
procedure glEvalCoord2f (u,v: GLfloat); stdcall;
procedure glEvalMesh1 (mode: GLenum; i1, i2: GLint); stdcall;
procedure glEvalMesh2 (mode: GLenum; i1, i2, j1, j2: GLint); stdcall;
procedure glEvalPoint2 (i,j: GLint); stdcall;
function  glGetError: GLenum; stdcall;
procedure glGetFloatv (pname: GLenum; params: PGLfloat); stdcall;
procedure glGetIntegerv (pname: GLenum; params: PGLint); stdcall;
function  glGetString (name: GLenum): PAnsiChar; stdcall;
procedure glFlush; stdcall;
procedure glFrustum (left, right, bottom, top, zNear, zFar: GLdouble); stdcall;
procedure glLoadIdentity; stdcall;
procedure glMap1f (target: GLenum; u1,u2: GLfloat; stride, order: GLint;
  Points: PGLfloat); stdcall;
procedure glMap2f (target: GLenum;
  u1,u2: GLfloat; ustride, uorder: GLint;
  v1,v2: GLfloat; vstride, vorder: GLint; Points: PGLfloat); stdcall;
procedure glMapGrid1f (un: GLint; u1, u2: GLfloat); stdcall;
procedure glMapGrid2d (un: GLint; u1, u2: GLdouble;
                       vn: GLint; v1, v2: GLdouble); stdcall;
procedure glMatrixMode (mode: GLenum); stdcall;
procedure glMultMatrixd (m: PGLdouble); stdcall;
procedure glMultMatrixf (m: PGLfloat); stdcall;
procedure glNormal3f (nx, ny, nz: GLFloat); stdcall;
procedure glNormal3fv (v: PGLfloat); stdcall;
procedure glOrtho (left, right, bottom, top, zNear, zFar: GLdouble); stdcall;
procedure glPixelStorei (pname: GLenum; param: GLint); stdcall;
procedure glPointSize (size: GLfloat); stdcall;
procedure glPolygonMode (face, mode: GLenum); stdcall;
procedure glPopAttrib; stdcall;
procedure glPopMatrix; stdcall;
procedure glPushAttrib(mask: GLbitfield); stdcall;
procedure glPushMatrix; stdcall;
procedure glScalef (x,y,z: GLfloat); stdcall;
procedure glTexCoord2f (s,t: GLfloat); stdcall;
procedure glTexImage1D (target: GLenum; level, components: GLint;
  width: GLsizei; border: GLint; format, _type: GLenum; pixels: Pointer); stdcall;
procedure glTexImage2D (target: GLenum; level, components: GLint;
  width, height: GLsizei; border: GLint; format, _type: GLenum; pixels: Pointer); stdcall;
procedure glTranslated (x,y,z: GLdouble); stdcall;
procedure glTranslatef (x,y,z: GLfloat); stdcall;
procedure glVertex3f (x,y,z: GLfloat); stdcall;
procedure glVertex3fv (v: PGLfloat); stdcall;
procedure glVertex3i (x,y,z: GLint); stdcall;
//procedure glVertex4f (x,y,z,w: GLfloat); stdcall;
procedure glViewport (x,y: GLint; width, height: GLsizei); stdcall;

implementation uses
  Graphics, SysUtils, Math, Utils, soft3d, Vector3DHelper, Parallel;

procedure glBegin (mode: GLenum); stdcall;
begin
  CurrentMode := mode;
end;

procedure glClear (mask: GLbitfield); stdcall;
begin
//  FillMem32(BackBuffer.Canvas.Brush.Color, PixelData, BackBuffer.Height*BackBuffer.Width);
//  FillMem32($ff7fffff, DepthBuffer, Length(DepthBuffer));
  TGlThread.FillMem32(BackBuffer.Canvas.Brush.Color, PixelData, BackBuffer.Height*BackBuffer.Width);
  TGlThread.FillMem32($ff7fffff, DepthBuffer, Length(DepthBuffer));
  TGlThread.Wait;
end;

procedure glClearColor (red, green, blue, alpha: GLclampf);
begin
  BackBuffer.Canvas.Brush.Color :=
    Round(alpha * $ff) shl 24 +
    Round(red * $ff) shl 16 +
    Round(green * $ff) shl 8 +
    Round(blue * $ff);
end;

procedure glColor3f (red, green, blue: GLfloat); stdcall;
begin
  CurrentColor :=
    Round({alpha * }$ff) shl 24 +
    Round(Max(0, Min(1, red)) * $ff) shl 16 +
    Round(Max(0, Min(1, green)) * $ff) shl 8 +
    Round(Max(0, Min(1, blue)) * $ff);
end;

procedure glDisable (cap: GLenum); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glEnable (cap: GLenum); stdcall;
begin
  case cap of
  GL_LIGHTING:
    Lighting := true;
  GL_LIGHT0..GL_LIGHT7:
    Lights[cap].On := true;
  GL_DEPTH_TEST:
    DepthTest := true;
  else
    raise Exception.Create('Not implemented');
  end;
end;

procedure glEnd; stdcall;
begin           // exit;
  DrawPrimitives;
end;

procedure glEvalCoord1f (u: GLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glEvalCoord2f (u,v: GLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glEvalMesh1 (mode: GLenum; i1, i2: GLint); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glEvalMesh2 (mode: GLenum; i1, i2, j1, j2: GLint); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glEvalPoint2 (i,j: GLint); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glFlush;
begin
  TGlThread.Wait;
//  raise Exception.Create('Not implemented');
end;

procedure glFrustum (left, right, bottom, top, zNear, zFar: GLdouble); stdcall;
begin
  HorizontalCorrection := 0.5 * bottom / left;
  VerticalCorrection := 0.5;
end;

function  glGetError: GLenum;
begin
  Result := 0;
end;

procedure glGetFloatv (pname: GLenum; params: PGLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glGetIntegerv (pname: GLenum; params: PGLint); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

function  glGetString (name: GLenum): PAnsiChar; stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glLoadIdentity;
var
  i: Integer;
begin
  ZeroMemory(CurrentMatrix, SizeOf(CurrentMatrix^));
  for i := 0 to 3 do
    CurrentMatrix.M[i].V[i] := 1;
end;

procedure glMap1f (target: GLenum; u1,u2: GLfloat; stride, order: GLint;
  Points: PGLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glMap2f (target: GLenum;
  u1,u2: GLfloat; ustride, uorder: GLint;
  v1,v2: GLfloat; vstride, vorder: GLint; Points: PGLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glMapGrid1f (un: GLint; u1, u2: GLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glMapGrid2d (un: GLint; u1, u2: GLdouble;
                       vn: GLint; v1, v2: GLdouble); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glMatrixMode (mode: GLenum);
begin
  case mode of
  GL_PROJECTION:  CurrentMatrix := @matProjection;
  GL_MODELVIEW:   CurrentMatrix := @matModelView;
  else
    raise Exception.Create('Not implemented');
  end;
end;

procedure glMultMatrixd (m: PGLdouble); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glMultMatrixf (m: PGLfloat); stdcall;
var
  mat: PMatrix3D absolute m;
begin
//  gluLookAt(5,5,5, 0,0,0, 0,0,1);
  CurrentMatrix.MulMat(mat^);
end;

procedure glNormal3f (nx, ny, nz: GLFloat); stdcall;
var
  n: TVector3D absolute nx;
begin
  CurrentNormal := n;
  CurrentNormal.W := 0;
end;

procedure glNormal3fv (v: PGLfloat); stdcall;
begin
  CurrentNormal := PVector3D(v)^;
  CurrentNormal.W := 0;
end;

procedure glOrtho (left, right, bottom, top, zNear, zFar: GLdouble); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glPixelStorei (pname: GLenum; param: GLint); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glPointSize (size: GLfloat); stdcall;
begin
  PointSize := Round(size);
end;

procedure glPolygonMode (face, mode: GLenum); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glPopAttrib; stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glPopMatrix; stdcall;
begin
  CurrentMatrix^ := MatrixStack[High(MatrixStack)];
  SetLength(MatrixStack, Length(MatrixStack) - 1);
end;

procedure glPushAttrib(mask: GLbitfield); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glPushMatrix; stdcall;
begin
  SetLength(MatrixStack, Length(MatrixStack) + 1);
  MatrixStack[High(MatrixStack)] := CurrentMatrix^;
end;

procedure glScalef (x,y,z: GLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glTexCoord2f (s,t: GLfloat); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glTexImage1D (target: GLenum; level, components: GLint;
  width: GLsizei; border: GLint; format, _type: GLenum; pixels: Pointer); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glTexImage2D (target: GLenum; level, components: GLint;
  width, height: GLsizei; border: GLint; format, _type: GLenum; pixels: Pointer); stdcall;
begin
  raise Exception.Create('Not implemented');
end;

procedure glViewport (x,y: GLint; width, height: GLsizei);
begin
  BackBuffer.Width := width;
  BackBuffer.Height := height;
  PixelSize.Width := width;
  PixelSize.Height := height;
  PixelData := BackBuffer.ScanLine[BackBuffer.Height-1];
  SetLength(DepthBuffer, width*height);
  BackBuffer.Canvas.Lock;
end;

procedure glTranslated (x,y,z: GLdouble); stdcall;
begin
  CurrentMatrix.Translate(x, y, z);
end;

procedure glTranslatef (x,y,z: GLfloat); stdcall;
begin
  CurrentMatrix.Translate(x, y, z);
end;

procedure glVertex3f (x,y,z: GLfloat); stdcall;
var
  v: TVector3D absolute x;
begin
  AddVertex3f(v);
end;

procedure glVertex3fv (v: PGLfloat); stdcall;
begin
  AddVertex3f(PVector3D(v)^);
end;

procedure glVertex3i (x,y,z: GLint); stdcall;
begin
  glVertex3f(x, y, z);
end;

end.
