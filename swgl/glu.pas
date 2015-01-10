unit glu;

interface uses
  gl;

function gluErrorString (errCode: GLenum): PAnsiChar; stdcall;
procedure gluLookAt(eyex, eyey, eyez,
  centerx, centery, centerz, upx, upy, upz: GLdouble); stdcall;
procedure gluOrtho2D(left, right, bottom, top: GLdouble); stdcall;

implementation uses
  Windows, Types, Utils,
  soft3d;

function gluErrorString (errCode: GLenum): PAnsiChar;
begin
  Result := 'N/A';
end;

procedure gluLookAt(eyex, eyey, eyez,
  centerx, centery, centerz,
  upx, upy, upz: GLdouble); stdcall;
var
  forward, side, up: TVec3D;
  center3D: TVec3D absolute centerx;
  eyePosition3D: TVec3D absolute eyex;
  upVector3D: TVec3D absolute upx;
begin
   forward[0] := center3D[0] - eyePosition3D[0];
   forward[1] := center3D[1] - eyePosition3D[1];
   forward[2] := center3D[2] - eyePosition3D[2];
   NormalizeVector(forward);
   //------------------
   //Side = forward x up
   ComputeNormalOfPlane(forward, upVector3D, side);
   NormalizeVector(side);
   //------------------
   //Recompute up as: up = side x forward
   ComputeNormalOfPlane(side, forward, up);
   //------------------
   matModelView.m11 := side[0];
   matModelView.m12 := side[1];
   matModelView.m13 := side[2];
   matModelView.m14 := 0;
   //------------------
   matModelView.m21 := up[0];
   matModelView.m22 := up[1];
   matModelView.m23 := up[2];
   matModelView.m24 := 0;
   //------------------
   matModelView.m31 := forward[0];
   matModelView.m32 := forward[1];
   matModelView.m33 := forward[2];
   matModelView.m34 := 0;
   //------------------
   matModelView.m41 := 0;
   matModelView.m42 := 0;
   matModelView.m43 := 0;
   matModelView.m44 := 1.0;
   //------------------
   MatTranslate(matModelView, -eyePosition3D[0], -eyePosition3D[1], -eyePosition3D[2]);
//   MultiplyMatrices4by4OpenGL_FLOAT(resultMatrix, matrix, matModelView);
//   glhTranslatef2(matModelView, -eyePosition3D[0], -eyePosition3D[1], -eyePosition3D[2]);
//   memcpy(matrix, resultMatrix, 16*sizeof(float));
end;

procedure gluOrtho2D(left, right, bottom, top: GLdouble);
begin

end;

end.
