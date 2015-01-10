unit Utils;

interface uses
  Windows, Types;

type
  TVec3D = array[0..2] of Double;
//  TVec4F = array[0..3] of Single;
  //TMat16 = array[0..15] of Single;

function PreciseTime: Double;
procedure FillMem32(val: DWORD; mem: Pointer; Cnt: DWORD);
procedure FillMem128(val: DWORD; mem: Pointer; Cnt: DWORD);
procedure ZeroMem(mem: pointer; Cnt: DWORD);
procedure NormalizeVector(var v: TVec3D);
procedure ComputeNormalOfPlane ( var vec1, vec2, out: TVec3D);
//procedure glhTranslatef2(var matrix: TMatrix3D; x, y, z: Single);
procedure MulMatVec(const Self: TMatrix3D; const v, Result: TVector3D);
//procedure MulMat(var m1, m2: TMatrix3D);
procedure MatTranslate(var m: TMatrix3D; x, y, z: Single);

implementation

procedure MulMatVec(const Self: TMatrix3D; const v, Result: TVector3D);
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

procedure MatTranslate(var m: TMatrix3D; x, y, z: Single);
var
  i, j, k: Integer;
  Self, Result: TMatrix3D;
begin
  FillChar(Self, SizeOf(Self), 0);
  with Self do begin
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
        Result.M[i].V[j] := Result.M[i].V[j] + m.M[i].V[k]*Self.M[k].V[j];
    end;
  m := Result;
end;

procedure NormalizeVector(var v: TVec3D);
var
  r: Single;
begin
  r := Sqr(v[0]) + Sqr(v[1]) + Sqr(v[2]);
  if r = 0 then
    Exit;
  r := 1/sqrt(r);
  v[0] := v[0] * r;
  v[1] := v[1] * r;
  v[2] := v[2] * r;
end;


procedure ComputeNormalOfPlane ( var vec1, vec2, out: TVec3D);
begin
    out[0] := vec1[1] * vec2[2] - vec1[2] * vec2[1];
    out[1] := vec1[2] * vec2[0] - vec1[0] * vec2[2];
    out[2] := vec1[0] * vec2[1] - vec1[1] * vec2[0];
end;


var
  pf: Int64;

function PreciseTime: Double;
var
  pc: Int64;
begin
  QueryPerformanceCounter(pc);
  Result := pc / pf;
end;

procedure FillMem32(val: DWORD; mem: Pointer; Cnt: DWORD);
asm
  XCHG    EDI, mem
  REP     STOSD
  XCHG    EDI, mem
end;

procedure FillMem128(val: DWORD; mem: Pointer; Cnt: DWORD);
asm
  movd xmm0, val
  shufps xmm0, xmm0, 0
  movaps xmm1, xmm0
@loopStart:
  movntps dqword ptr [mem], xmm0
  add mem, 16
  dec cnt
  jg @loopStart
@loopEnd:
end;

function ZeroMem16(mem: pointer; Cnt: DWORD): Pointer;
const
  zero: array[0..3] of dword  = ($0, $0, $0, $0);
asm
  movups xmm0, zero
@loopStart:
  movntps dqword ptr [mem],xmm0
  add mem, 16
  dec cnt
  jne @loopStart
@loopEnd:
end;

procedure ZeroMem(mem: pointer; Cnt: DWORD);
var
  rest: pointer;
begin
  rest := ZeroMem16(mem, Cnt div 4);
  FillMem32($ff00, rest, Cnt - Cnt div 4 * 4);
end;

initialization
  QueryPerformanceFrequency(pf);

end.
