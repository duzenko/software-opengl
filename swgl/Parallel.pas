unit Parallel;

interface uses
  Windows, System.Classes, soft3d;

type
  TTriangle2D = array[0..2] of TVertexData;
  TTriangles2D = array of TTriangle2D;
  TGlThread = class(TThread)
  private
  class var
    ThreadCount: Integer;
    Event: THandle;
  protected
    procedure Execute; override;
  public
    class procedure DrawTriangles(Triangles2D: TTriangles2D; ACount: Integer);
    class procedure FillMem32(val: DWORD; mem: Pointer; Cnt: DWORD);
    class procedure Wait;
  end;

implementation uses
  SysUtils, Math, Utils, OpenGL;

type
  TFillMemData = packed record val: DWORD; mem: Pointer; Cnt: DWORD end;
  PFillMemData = ^TFillMemData;
  TDrawTrianglesData = record
    ThreadNo, TriangleCount: Integer;
    Triangles: TTriangles2D;
  end;
  PDrawTrianglesData = ^TDrawTrianglesData;

procedure FillMemInt(p: PFillMemData); stdcall;
begin
  FillMem128(p.val, p.mem, p.Cnt);
  Dispose(p);
  if InterlockedDecrement(TGlThread.ThreadCount) = 0 then
    SetEvent(TGlThread.Event);
end;

procedure DrawTriangle2DInt(p: PDrawTrianglesData); stdcall;
var
  I: Integer;
begin
  for I := 0 to p.TriangleCount - 1 do
    if i mod CPUCount = p.ThreadNo then
      DrawTriangle2D(p.Triangles[i][0], p.Triangles[i][1], p.Triangles[i][2]);
  Dispose(p);
  if InterlockedDecrement(TGlThread.ThreadCount) = 0 then
    SetEvent(TGlThread.Event);
end;

{ TGlThread }

class procedure TGlThread.DrawTriangles(Triangles2D: TTriangles2D; ACount: Integer);
var
  p: PDrawTrianglesData;
  i: Integer;
begin
//  SetLength(p^, ACount);
//  Move(Triangles2D[0], p^[0], ACount*SizeOf(p^[0]));
  if Event = 0 then
    Event := CreateEvent(nil, true, true, 'TGlThread');
  ThreadCount := Min(ACount, CPUCount);
  ResetEvent(Event);
  for i := 0 to ThreadCount-1 do begin
    New(p);
    p.ThreadNo := i;
    p.TriangleCount := ACount;
    p.Triangles := Triangles2D;
    if not QueueUserWorkItem(@DrawTriangle2DInt, p, WT_EXECUTEDEFAULT) then
      RaiseLastOSError;
  end;
  Wait;
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
  if InterlockedIncrement(ThreadCount) = 1 then
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
  if ThreadCount <> 0 then
    raise Exception.Create('Error Message');
end;


end.
