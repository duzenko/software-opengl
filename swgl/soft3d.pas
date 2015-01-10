unit soft3d;

interface uses
  Types, Graphics, gl;

type
  TVertexData = record
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

procedure DrawPoints();
procedure DrawLines();
procedure DrawTriangles();
procedure DrawQuads();

type
  PMatrix3D = ^TMatrix3D;

var
  BackBuffer: TBitmap;
  PointSize: Integer = 1;
  PixelData: Pointer;
  matModelView, matProjection: TMatrix3D;
  CurrentColor: DWORD = $ffffffff;
  HorizontalCorrection, VerticalCorrection: Single;
  PixelSize: TSize;
  CurrentMode: GLenum;
  CurrentMatrix: PMatrix3D = @matProjection;

implementation uses
  Math, Utils, Vector3DHelper;

type
  TPixelArray = array of TColor;

var
  Vertices: array of TVertexData;
  VertUsed: Integer;

procedure AddVertex3f(const v: TVector3D);
begin
  if VertUsed = Length(Vertices) then begin
    SetLength(Vertices, Length(Vertices) + 1024);
  end;
  Vertices[VertUsed].c := CurrentColor;
  Vertices[VertUsed].v := v;
  Vertices[VertUsed].v.W := 1;
  Inc(VertUsed);
end;

procedure DrawPixel(const v: TVertexData);
begin
  TPixelArray(PixelData)[v.p.Y*PixelSize.Width+v.p.X] := v.c;
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
  VertUsed := 0;
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
  VertUsed := 0;
end;

procedure DrawTriangle2D(var v1, v2, v3: TVertexData);
var
  mn, mx: TPoint;
  x, y: Integer;
  v: TVertexData;
  a, b, c, SqAr: array[0..2] of Single;
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
  for y := mn.Y to mx.Y do begin
    v.p.Y := y;
    for x := mn.X to mx.X do begin
      v.p.X := x;
      if a[0]*x+b[0]*y+c[0] > 0 then
        Continue;
      if a[1]*x+b[1]*y+c[1] < 0 then
        Continue;
      if a[2]*x+b[2]*y+c[2] < 0 then
        Continue;
      SqAr[0] := Abs(v1.p.X*(v2.p.Y-v.p.Y)+v2.p.X*(v.p.Y-v1.p.Y)+v.p.X*(v1.p.Y-v2.p.Y));
      SqAr[1] := Abs(v1.p.X*(v3.p.Y-v.p.Y)+v3.p.X*(v.p.Y-v1.p.Y)+v.p.X*(v1.p.Y-v3.p.Y));
      SqAr[2] := Abs(v3.p.X*(v2.p.Y-v.p.Y)+v2.p.X*(v.p.Y-v3.p.Y)+v.p.X*(v3.p.Y-v2.p.Y));
      v.r := Round((v1.r*SqAr[2]+v2.r*SqAr[1]+v3.r*SqAr[0])/(SqAr[0]+SqAr[1]+SqAr[2]));
      v.g := Round((v1.g*SqAr[2]+v2.g*SqAr[1]+v3.g*SqAr[0])/(SqAr[0]+SqAr[1]+SqAr[2]));
      v.b := Round((v1.b*SqAr[2]+v2.b*SqAr[1]+v3.b*SqAr[0])/(SqAr[0]+SqAr[1]+SqAr[2]));
      v.a := Round((v1.a*SqAr[2]+v2.a*SqAr[1]+v3.a*SqAr[0])/(SqAr[0]+SqAr[1]+SqAr[2]));
      DrawPixel(v);
    end;
  end;
end;

procedure DrawTriangle(var v1, v2, v3: TVertexData);
var
  r1, r2, r3: TVector3D;
begin
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
  VertUsed := 0;
end;

procedure DrawQuad(var v1, v2, v3, v4: TVertexData);
var
  r1, r2, r3, r4: TVector3D;
begin
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
  DrawTriangle2D(v1, v2, v3);
  DrawTriangle2D(v1, v3, v4);
end;

procedure DrawQuads();
var
  i: Integer;
begin
  for i := 0 to VertUsed div 4 - 1 do
    DrawQuad(Vertices[4*i], Vertices[4*i+1], Vertices[4*i+2], Vertices[4*i+3]);
  VertUsed := 0;
end;

end.
