unit Vector3DHelper;

interface uses
  Types;

type
  TMinMax = record x1, y1, x2, y2: Integer end;
  TVector3DHelper = record helper for TVector3D
    function DotProductNegative(const AVector3D: TVector3D): boolean;
    function DotProductsNonNegative(const V1, V2: TVector3D): boolean;
    procedure Add(const v: TVector3D);
    procedure AddMul2(const add, mul: TVector3D);
    function Subtract(const AVector3D: TVector3D): TVector3D;
    procedure CopyFrom(const AVector3D: TVector3D);
    function PixelIndex(LineWidth: DWORD): DWORD;
    function Project(): TVector3D;
    function ProjectAddMul2(const add, mul: TVector3D): TVector3D;
    function RoundMaxAbs2: Integer;
    procedure MinMax(const v1, v2, clip: TVector3D; out R: TMinMax);
  end;
  PVector3D = ^TVector3D;

  TMatrix3DHelper = record helper for TMatrix3D
    procedure MulVec(const v: TVector3D; out Result: TVector3D);
    procedure MulMat(const mat: TMatrix3D);
    procedure LoadTranslate(x, y, z: Single);
    procedure Translate(x, y, z: Single);
  end;

implementation uses
  Math;

{ TVector3D }

{ TVector3DHelper }

procedure TVector3DHelper.Add(const v: TVector3D);
asm
  movups xmm0, [self]
  movups xmm1, [v]
  addps xmm0, xmm1
  movups [self], xmm0
end;

procedure TVector3DHelper.AddMul2(const add, mul: TVector3D);
const
  Half: Single = 0.5;
asm
  movaps xmm0, [self]
  addps xmm0, [add]
  mulps xmm0, [mul]
  movss xmm1, Half
  shufps xmm1, xmm1, 0
  mulps xmm0, xmm1
  movaps [self], xmm0
end;

procedure TVector3DHelper.CopyFrom(const AVector3D: TVector3D);
asm
  movups xmm0, [AVector3D]
  movups [Self], xmm0
end;

function TVector3DHelper.DotProductNegative(const AVector3D: TVector3D): boolean;
asm
  movups xmm0, [self]
  movaps xmm1, [AVector3D]
  xorps xmm2, xmm2
  dpps xmm0, xmm1, $f1
  cmpltss xmm0, xmm2
  movmskps eax, xmm0
end;

function TVector3DHelper.DotProductsNonNegative(const V1, V2: TVector3D): boolean;
asm
  xorps xmm2, xmm2
  movaps xmm0, [self]

  movaps xmm1, [v1]
  dpps xmm1, xmm0, $f1
  cmpnltss xmm1, xmm2
  movmskps eax, xmm1

  movaps xmm1, [v2]
  dpps xmm1, xmm0, $f1
  cmpnltss xmm1, xmm2
  movmskps edx, xmm1
  and eax, edx
end;

procedure TVector3DHelper.MinMax(const v1, v2, clip: TVector3D; out R: TMinMax);
asm
  movq xmm0, [Self]
  movq xmm1, [v1]
  movq xmm2, [v2]
  mov eax, clip
  movq xmm3, [eax]
  xorps xmm4, xmm4
  movups xmm5, xmm0

  minps xmm5, xmm1
  maxps xmm0, xmm1
  minps xmm5, xmm2
  maxps xmm0, xmm2
  maxps xmm5, xmm4
  minps xmm0, xmm3
  minps xmm5, xmm3
  maxps xmm0, xmm4

  movlhps xmm5, xmm0
  cvtps2dq xmm5, xmm5
  mov eax, R
  movups [eax], xmm5
//  R.x1 := Round(Max(0, Min(v1.X, Min(v2.X, X))));
//  R.y1 := Round(Max(0, Min(v1.Y, Min(v2.Y, Y))));
//  R.x2 := Round(Min(clip.X, Max(v1.X, Max(v2.X, X))));
//  R.y2 := Round(Min(clip.Y, Max(v1.Y, Max(v2.Y, Y))));
end;

function TVector3DHelper.Project(): TVector3D;
asm
  movaps xmm0, [Self]
  movhps qword [Result+8], xmm0
  movups xmm1, xmm0
  shufps xmm1, xmm1, $EA
  divps xmm0, xmm1
  movlps [Result], xmm0
end;

function TVector3DHelper.ProjectAddMul2(const add, mul: TVector3D): TVector3D;
const
  Half: Single = 0.5;
asm
  movups xmm0, [Self]
//  movhps qword [Result+8], xmm0
  movups xmm1, xmm0
  movhlps xmm2, xmm0
  shufps xmm1, xmm1, $AA
  divps xmm0, xmm1
//  movlps [Result], xmm0

//  movaps xmm0, [self]
  movups xmm1, [add]
  addps xmm0, xmm1
  movups xmm1, [mul]
  mulps xmm0, xmm1
  movss xmm1, Half
  shufps xmm1, xmm1, 0
  mulps xmm0, xmm1
  movlhps xmm0, xmm2
  mov eax, Result
  movups [eax], xmm0
end;

function TVector3DHelper.PixelIndex(LineWidth: DWORD): DWORD;
asm
  movss xmm0, Self.x
  movss xmm1, Self.y
  cvtss2si eax, xmm1
  mul LineWidth
  cvtss2si edx, xmm0
  add eax, edx
//  Result := Round(x) + Round(y) * LineWidth;
end;

function TVector3DHelper.RoundMaxAbs2: Integer;
const
  absmask: array[0..3] of DWORD = ($80000000, $80000000, $80000000, $80000000);
asm
//  Result := Round(Max(Abs(x), Abs(Y)));
  movq xmm1, [self]
  movups xmm0, absmask
  andnps xmm0, xmm1
  pshufd xmm1, xmm0, $55
  maxps xmm0, xmm1
  cvtss2si eax, xmm0
end;

function TVector3DHelper.Subtract(const AVector3D: TVector3D): TVector3D;
asm
  movups xmm0, [self]
  movups xmm1, [AVector3D]
  subps xmm0, xmm1
  movups [Result], xmm0
end;

{ TMatrix3DHelper }

procedure TMatrix3DHelper.LoadTranslate(x, y, z: Single);
begin
  FillChar(Self, SizeOf(Self), 0);
  m11 := 1;
  m14 := x;
  m22 := 1;
  m24 := y;
  m33 := 1;
  m34 := z;
  m44 := 1;
end;

procedure TMatrix3DHelper.MulMat(const mat: TMatrix3D);
var
  tmp: TMatrix3D;
  y: Integer;
  x: Integer;
begin
  for y := 0 to 3 do
    for x := 0 to 3 do begin
      tmp.M[y].V[x] := M[y].V[0] * mat.M[x].V[0]
        + M[y].V[1] * mat.M[x].V[1]
        + M[y].V[2] * mat.M[x].V[2]
        + M[y].V[3] * mat.M[x].V[3];
    end;
  M := tmp.M;
end;

procedure TMatrix3DHelper.MulVec(const v: TVector3D; out Result: TVector3D);
asm
  movups xmm0, [v]
  movups xmm1, dqword [Self+00]
  movups xmm2, dqword [Self+16]
  movups xmm3, dqword [Self+32]
  movups xmm4, dqword [Self+48]
  dpps xmm1, xmm0, $f1
  dpps xmm2, xmm0, $f1
  dpps xmm3, xmm0, $f1
  dpps xmm4, xmm0, $f1
  movss [Result], xmm1
  movss [Result+4], xmm2
  movss [Result+8], xmm3
  movss [Result+12], xmm4
//    Result.V[i] := M[i].X * v.X + M[i].y * v.y + M[i].z * v.z + M[i].w * v.w;
end;

procedure TMatrix3DHelper.Translate(x, y, z: Single);
var
  i, j, k: Integer;
  tr, Result: TMatrix3D;
begin
  FillChar(tr, SizeOf(tr), 0);
  with tr do begin
    m11 := 1;
    m14 := x;
    m22 := 1;
    m24 := y;
    m33 := 1;
    m34 := z;
    m44 := 1;
  end;
  for i := 0 to 3 do
    for j := 0 to 3 do begin
      Result.M[i].V[j] := 0;
      for k := 0 to 3 do
        Result.M[i].V[j] := Result.M[i].V[j] + M[i].V[k]*tr.M[k].V[j];
    end;
  m := Result.M;
end;

end.
