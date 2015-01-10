unit simd;

interface

type
  TSimdVector = packed record
    x, y, z, w: Single;
  end;
  TSimdVectorInt = packed record
    x, y, z, w: Integer;
  end;
  PSimdVector = ^TSimdVector;

procedure AddVector(const v: TSimdVector);
procedure LoadVector(const v: TSimdVector);
procedure MulVector(const v: TSimdVector);
procedure DivVector(const v: TSimdVector);
procedure SaveVector(var v: TSimdVector);
//s procedure SaveVectorInt(var v: TPoint);

//function CheckInside(const v: TSimdVector): Boolean;
procedure MulScalar(f: Single);
procedure DivScalar(f: PSingle);

implementation

{ TCpuInstructions }

procedure AddVector(const v: TSimdVector);
asm
  addps xmm0, [v]
end;

function CheckInside(const v: TSimdVector): Boolean;
asm
  movhps xmm0, [v]
  movaps xmm1, xmm0
  shufps xmm1, xmm0, 01001111b
  shufps xmm0, xmm0, 10100100b
  cmpnleps xmm1, xmm0
  pmovmskb eax, xmm1
  inc eax
  shr eax, 16
end;

procedure DivScalar(f: PSingle);
asm
  movss xmm1, [f]
  shufps xmm1, xmm1, 0
  divps xmm0, xmm1
end;

procedure DivVector(const v: TSimdVector);
asm
  divps xmm0, [v]
end;

procedure LoadVector(const v: TSimdVector);
asm
  movups xmm0, [v]
end;

procedure MulScalar(f: Single);
asm
  movss xmm1, f
  shufps xmm1, xmm1, 0
  mulps xmm0, xmm1
end;

procedure MulVector(const v: TSimdVector);
asm
  mulps xmm0, [v]
end;

procedure SaveVector(var v: TSimdVector);
asm
  movups [v], xmm0
end;

//procedure SaveVectorInt(var v: TSimdVectorInt);
//asm
//  CVTTPS2DQ xmm1, xmm0
//  movups [v], xmm1
//end;

initialization

end.
