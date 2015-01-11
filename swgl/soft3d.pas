unit soft3d;

interface uses
  Types, Graphics, OpenGL, gl;

type
  TVertexData = record
    n: TVector3D;
    case byte of
    0:
    (
      c: TColor;
      v: TVector3D
    );
    1:
    (
      r, g, b, a: Byte;
      p: TPoint
    );
  end;

procedure AddVertex3f(const v: TVector3D);
procedure DrawPrimitives();
procedure DrawTriangle2D(v1, v2, v3: TVertexData);

{procedure DrawPoints();
procedure DrawLines();
procedure DrawTriangles();
procedure DrawTriangleFan();
procedure DrawQuads();
procedure DrawQuadStrip();

procedure DrawPixel(const v: TVertexData);    }

type
  PMatrix3D = ^TMatrix3D;

var
  BackBuffer: TBitmap;
  PixelData: Pointer;
  PixelSize: TSize;
  DepthBuffer: array of Single;

  matModelView, matProjection: TMatrix3D;
  CurrentMatrix: PMatrix3D = @matProjection;
  MatrixStack: array of TMatrix3D;

  PointSize: Integer = 1;
  CurrentColor: DWORD = $ffffffff;
  CurrentNormal: TVector3D;
  CurrentMode: GLenum; // points, lines, triangles...
  DepthTest: Boolean;

  Lighting: Boolean;
  Lights: array[GL_LIGHT0..GL_LIGHT7] of record
    On: Boolean;
    SpotDirection: TVector3D;
  end = (
    (SpotDirection: (Z: -1)), (), (), (), (), (), (), ()
  );

  HorizontalCorrection, VerticalCorrection: Single;
  VertUsed: Integer;

implementation uses
  SysUtils, Math, Utils, Vector3DHelper, Parallel;

type
  TPixelArray = array of TColor;

var
  Vertices: array of TVertexData;

procedure AddVertex3f(const v: TVector3D);
begin
  if VertUsed = Length(Vertices) then begin
    SetLength(Vertices, Length(Vertices) + 1024);
  end;
  Vertices[VertUsed].n := CurrentNormal;
  Vertices[VertUsed].c := CurrentColor;
  Vertices[VertUsed].v := v;
  Vertices[VertUsed].v.W := 1;
  Inc(VertUsed);
end;

procedure DrawPixel(const v: TVertexData);
begin
  if DepthTest and (DepthBuffer <> nil)
    and (DepthBuffer[v.p.Y*PixelSize.Width+v.p.X] > v.v.Z)
  then
    Exit;
  TPixelArray(PixelData)[v.p.Y*PixelSize.Width+v.p.X] := v.c;
  if DepthTest and (DepthBuffer <> nil) then
    DepthBuffer[v.p.Y*PixelSize.Width+v.p.X] := v.v.Z;
end;

procedure DrawPoint(var v: TVertexData);
var
  k: Integer;
  r: TVector3D;
begin
  matModelView.MulVec(v.v, r);
  if r.Z >= 0 then
    Exit;
  v.p.X := Round((0.5 - r.X/r.Z*HorizontalCorrection)*PixelSize.Width);
  v.p.Y := Round((0.5 - r.Y/r.Z*VerticalCorrection)*PixelSize.Height);
  if (v.p.X < 0) or (v.p.X >= PixelSize.Width) then
    Exit;
  if (v.p.Y < 0) or (v.p.Y >= PixelSize.Height) then
    Exit;
  if PointSize = 1 then
    DrawPixel(v)
  else
    for k := Max(0, v.p.Y-PointSize div 2) to Min(PixelSize.Height, v.p.Y+PointSize div 2) do
      FillMem32(v.c, @TPixelArray(PixelData)[k*PixelSize.Width+v.p.X-PointSize div 2], PointSize);
end;

procedure DrawPoints();
var
  i: Integer;
begin
  for i := 0 to VertUsed -1 do
    DrawPoint(Vertices[i]);
end;

procedure DrawLine2D(const v1, v2: TVertexData);
var
  v: TVertexData;
  i, l: Integer;
  f1, f2: Single;
begin
  if (v1.p.X < 0) or (v1.p.X >= PixelSize.Width) then
    Exit;
  if (v1.p.Y < 0) or (v1.p.Y >= PixelSize.Height) then
    Exit;
  if (v2.p.X < 0) or (v2.p.X >= PixelSize.Width) then
    Exit;
  if (v2.p.Y < 0) or (v2.p.Y >= PixelSize.Height) then
    Exit;
  l := Round(v1.p.Distance(v2.p));
  DrawPixel(v1);
  for i := 1 to l do begin
    f1 := i/l;
    f2 := 1 - f1;
    v.p.X := Round(v1.p.X*f1 + v2.p.X*f2);
    v.p.Y := Round(v1.p.Y*f1 + v2.p.Y*f2);
    v.r := Round(v1.r*f1 + v2.r*f2);
    v.g := Round(v1.g*f1 + v2.g*f2);
    v.b := Round(v1.b*f1 + v2.b*f2);
    v.a := Round(v1.a*f1 + v2.a*f2);
    DrawPixel(v);
  end;
end;

procedure DrawLine(var v1, v2: TVertexData);
var
  r1, r2: TVector3D;
begin
  matModelView.MulVec(v1.v, r1);
  if r1.Z >= 0 then
    Exit;
  matModelView.MulVec(v2.v, r2);
  if r2.Z >= 0 then
    Exit;
  v1.p.x := Round((0.5 - r1.X/r1.Z*HorizontalCorrection)*PixelSize.Width);
  v1.p.y := Round((0.5 - r1.Y/r1.Z*VerticalCorrection)*PixelSize.Height);
  v2.p.x := Round((0.5 - r2.X/r2.Z*HorizontalCorrection)*PixelSize.Width);
  v2.p.y := Round((0.5 - r2.Y/r2.Z*VerticalCorrection)*PixelSize.Height);
  DrawLine2D(v1, v2);
end;

procedure DrawLines();
var
  i: Integer;
begin
  for i := 0 to VertUsed div 2 - 1 do
    DrawLine(Vertices[2*i], Vertices[2*i+1]);
end;

procedure DrawTriangle2D(v1, v2, v3: TVertexData);
var
  mn, mx: TPoint;
  x, y: Integer;
  v: TVertexData;
  a, b, c: array[0..2] of Single;
  SqAr: array[0..2] of Integer;
  LightIntensity, TotalAreaRecip: Single;
//  vn: TVector3D;

  function Weigh(f1, f2, f3: Single): Single;
  begin
    Result := (f1*SqAr[2]+f2*SqAr[1]+f3*SqAr[0]) * TotalAreaRecip;
  end;

  function Clamp(f: Single): Single;
  begin
    if f < 0 then
      Result := 0
    else
      if f > 1 then
        Result := 1
      else
        Result := f;
  end;

begin
  mn.X := Max(0, Min(v1.p.X, Min(v2.p.X, v3.p.X)));
  mn.Y := Max(0, Min(v1.p.Y, Min(v2.p.Y, v3.p.Y)));
  mx.X := Min(BackBuffer.Width-1, Max(v1.p.X, Max(v2.p.X, v3.p.X)));
  mx.Y := Min(BackBuffer.Height, Max(v1.p.Y, Max(v2.p.Y, v3.p.Y)));
  a[0] := v1.p.Y - v2.p.Y;
  b[0] := v2.p.X - v1.p.X;
  c[0] := (v1.p.X - v2.p.X)*v1.p.Y + (v2.p.Y - v1.p.Y)*v1.p.X;
  a[1] := v1.p.Y - v3.p.Y;
  b[1] := v3.p.X - v1.p.X;
  c[1] := (v1.p.X - v3.p.X)*v1.p.Y + (v3.p.Y - v1.p.Y)*v1.p.X;
  a[2] := v3.p.Y - v2.p.Y;
  b[2] := v2.p.X - v3.p.X;
  c[2] := (v3.p.X - v2.p.X)*v3.p.Y + (v2.p.Y - v3.p.Y)*v3.p.X;
  V.n.W := 0;
  if Lighting then begin
    v.n.X := Mean([v1.n.X, v2.n.X, v3.n.X]);
    v.n.Y := Mean([v1.n.Y, v2.n.Y, v3.n.Y]);
    v.n.Z := Mean([v1.n.Z, v2.n.Z, v3.n.Z]);
//        matModelView.MulVec(v.n, vn);
    LightIntensity := Clamp(-v.n.DotProduct(Lights[GL_LIGHT0].SpotDirection));
  end else
    LightIntensity := 1;
  v.r := Round(v1.r*LightIntensity);
  v.g := Round(v1.g*LightIntensity);
  v.b := Round(v1.b*LightIntensity);
  v.a := Round(v1.a);
  for y := mn.Y to mx.Y do begin
    v.p.Y := y;
    for x := mn.X to mx.X do begin
      v.p.X := x;
      if a[0]*x+b[0]*y+c[0] < 0 then
        Continue;
      if a[1]*x+b[1]*y+c[1] > 0 then
        Continue;
      if a[2]*x+b[2]*y+c[2] > 0 then
        Continue;
      SqAr[0] := Abs(v1.p.X*(v2.p.Y-v.p.Y)+v2.p.X*(v.p.Y-v1.p.Y)+v.p.X*(v1.p.Y-v2.p.Y));
      SqAr[1] := Abs(v1.p.X*(v3.p.Y-v.p.Y)+v3.p.X*(v.p.Y-v1.p.Y)+v.p.X*(v1.p.Y-v3.p.Y));
      SqAr[2] := Abs(v3.p.X*(v2.p.Y-v.p.Y)+v2.p.X*(v.p.Y-v3.p.Y)+v.p.X*(v3.p.Y-v2.p.Y));
      TotalAreaRecip := 1/(SqAr[0] + SqAr[1] + SqAr[2]);
{      if Lighting then begin
        v.n.X := Weigh(v1.n.X, v2.n.X, v3.n.X);
        v.n.Y := Weigh(v1.n.Y, v2.n.Y, v3.n.Y);
        v.n.Z := Weigh(v1.n.Z, v2.n.Z, v3.n.Z);
//        matModelView.MulVec(v.n, vn);
        LightIntensity := Clamp(-v.n.DotProduct(Lights[GL_LIGHT0].SpotDirection));
      end else
        LightIntensity := 1;  }
{      v.r := Round(Weigh(v1.r, v2.r, v3.r)*LightIntensity);
      v.g := Round(Weigh(v1.g, v2.g, v3.g)*LightIntensity);
      v.b := Round(Weigh(v1.b, v2.b, v3.b)*LightIntensity);
      v.a := Round(Weigh(v1.a, v2.a, v3.a)*LightIntensity);  }
      v.v.Z := Weigh(v1.v.Z, v2.v.Z, v3.v.Z);
      DrawPixel(v);
    end;
  end;
end;

var
  DeferredTriangles: TTriangleData;
  DeferredCount: Integer;
procedure DeferTriangle2D(const v1, v2, v3: TVertexData);
begin
  if DeferredCount >= Length(DeferredTriangles) then
    SetLength(DeferredTriangles, Length(DeferredTriangles)+1);
  DeferredTriangles[DeferredCount][0] := v1;
  DeferredTriangles[DeferredCount][1] := v2;
  DeferredTriangles[DeferredCount][2] := v3;
  Inc(DeferredCount);
end;

procedure DrawTriangle(const sv1, sv2, sv3: TVertexData);
var
  v1, v2, v3: TVertexData;
  r1, r2, r3: TVector3D;
begin
  v1 := sv1;
  v2 := sv2;
  v3 := sv3;
  matModelView.MulVec(v1.v, r1);
  if r1.Z = 0 then
    Exit;
  matModelView.MulVec(v2.v, r2);
  if r2.Z = 0 then
    Exit;
  matModelView.MulVec(v3.v, r3);
  if r3.Z = 0 then
    Exit;
  with v1, r1 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  with v2, r2 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  with v3, r3 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  DrawTriangle2D(v1, v2, v3);
end;

procedure DrawTriangles();
var
  i: Integer;
begin
  for i := 0 to VertUsed div 3 - 1 do
    DrawTriangle(Vertices[3*i], Vertices[3*i+1], Vertices[3*i+2]);
end;

procedure DrawTriangleFan();
var
  i: Integer;
begin
  for i := 1 to VertUsed - 2 do
    DrawTriangle(Vertices[0], Vertices[i], Vertices[i+1]);
end;

procedure DrawQuad(const sv1, sv2, sv3, sv4: TVertexData);
var
  v1, v2, v3, v4: TVertexData;
  r1, r2, r3, r4: TVector3D;
begin
  v1 := sv1;
  v2 := sv2;
  v3 := sv3;
  v4 := sv4;
  matModelView.MulVec(v1.v, r1);
  if r1.Z = 0 then
    Exit;
  matModelView.MulVec(v2.v, r2);
  if r2.Z = 0 then
    Exit;
  matModelView.MulVec(v3.v, r3);
  if r3.Z = 0 then
    Exit;
  matModelView.MulVec(v4.v, r4);
  if r4.Z = 0 then
    Exit;
  with v1, r1 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  with v2, r2 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  with v3, r3 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  with v4, r4 do begin
    p.x := Round((0.5 - X/Z*HorizontalCorrection)*PixelSize.Width);
    p.y := Round((0.5 - Y/Z*VerticalCorrection)*PixelSize.Height);
  end;
  DeferTriangle2D(v1, v2, v3);
  DeferTriangle2D(v1, v3, v4);
end;

procedure DrawQuads();
var
  i: Integer;
begin
  for i := 0 to VertUsed div 4 - 1 do
    DrawQuad(Vertices[4*i], Vertices[4*i+1], Vertices[4*i+2], Vertices[4*i+3]);
  TGlThread.DrawTriangles(DeferredTriangles, DeferredCount);
  DeferredCount := 0;
end;

procedure DrawQuadStrip();
var
  i: Integer;
begin
  for i := 0 to VertUsed div 2 - 2 do
    DrawQuad(Vertices[2*i], Vertices[2*i+1], Vertices[2*i+3], Vertices[2*i+2]);
  TGlThread.DrawTriangles(DeferredTriangles, DeferredCount);
  DeferredCount := 0;
end;

procedure DrawPrimitives();
begin
  case CurrentMode of
  GL_POINTS: DrawPoints;
  GL_LINES:  DrawLines;
  GL_TRIANGLES:  DrawTriangles;
  GL_TRIANGLE_FAN:  DrawTriangleFan;
  GL_QUADS:  DrawQuads;
  GL_QUAD_STRIP:  DrawQuadStrip;
  else
    raise Exception.Create('Not implemented');
  end;
//  TGlThread.Wait;
  VertUsed := 0;
  //QueueUserWorkItem(@DrawPrimitives, nil, WT_EXECUTEDEFAULT);
end;

end.
