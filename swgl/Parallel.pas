unit Parallel;

interface uses
  Windows, System.Classes, soft3d;

type
  TTriangleData = array of array[0..2] of TVertexData;
  TGlThread = class(TThread)
  private
  class var
    Count: Integer;
    Event: THandle;
  protected
    procedure Execute; override;
  public
    class procedure DrawTriangles(Triangles2D: TTriangleData; ACount: Integer);
    class procedure FillMem32(val: DWORD; mem: Pointer; Cnt: DWORD);
    class procedure Wait;
  end;

implementation uses
  SysUtils, Math, Utils, OpenGL;

type
  TFillMemData = packed record val: DWORD; mem: Pointer; Cnt: DWORD end;
  PFillMemData = ^TFillMemData;
//  TTriangleData = array[0..2] of TVertexData;
  PTriangleData = ^TTriangleData;

procedure FillMemInt(p: PFillMemData); stdcall;
begin
  FillMem128(p.val, p.mem, p.Cnt);
  Dispose(p);
  if InterlockedDecrement(TGlThread.Count) = 0 then
    SetEvent(TGlThread.Event);
end;

procedure DrawTriangle2DInt(p: PTriangleData); stdcall;
var
  I: Integer;
begin
//  Dispose(p);
  for I := 0 to High(p^) do
    DrawTriangle2D(p^[i][0], p^[i][1], p^[i][2]);
  Dispose(p);
  if InterlockedDecrement(TGlThread.Count) = 0 then
    SetEvent(TGlThread.Event);
end;

{ TGlThread }

class procedure TGlThread.DrawTriangles(Triangles2D: TTriangleData; ACount: Integer);
var
  p: PTriangleData;
//  thId: Cardinal;
begin
  New(p);
  SetLength(p^, ACount);
  Move(Triangles2D[0], p^[0], ACount*SizeOf(p^[0]));
  if Event = 0 then
    Event := CreateEvent(nil, true, true, 'TGlThread');
  if InterlockedIncrement(Count) = 1 then
    ResetEvent(Event);
  QueueUserWorkItem(@DrawTriangle2DInt, p, WT_EXECUTEDEFAULT);
//  BeginThread(nil, 0, @DrawTriangle2DInt, p, 0, thId);
end;

procedure TGlThread.Execute;
begin
  { Place thread code here }
end;

class procedure TGlThread.FillMem32(val: DWORD; mem: Pointer; Cnt: DWORD);
var
  p: PFillMemData;
begin
  if Event = 0 then
    Event := CreateEvent(nil, true, true, 'TGlThread');
  if InterlockedIncrement(Count) = 1 then
    ResetEvent(Event);
  New(p);
  p.val := val;
  p.mem := mem;
  p.Cnt := Cnt;
  QueueUserWorkItem(@FillMemInt, p, WT_EXECUTEDEFAULT);
end;

class procedure TGlThread.Wait;
begin
  WaitForSingleObject(Event, INFINITE);
end;

end.
