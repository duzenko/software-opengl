unit wgl;

interface uses
  Windows;

function wglCreateContext(DC: HDC): HGLRC; stdcall;
function wglMakeCurrent(DC: HDC; p2: HGLRC): BOOL; stdcall;
function wglDeleteContext(p1: HGLRC): BOOL; stdcall;
function wglChoosePixelFormat(DC: HDC; p2: PPixelFormatDescriptor): Integer; stdcall;
function wglSwapBuffers(DC: HDC): BOOL; stdcall;

implementation uses
  SysUtils, Graphics, soft3d;

function wglCreateContext(DC: HDC): HGLRC;
begin
  BackBuffer := TBitmap.Create;
  BackBuffer.PixelFormat := pf32bit;
  Result := 1;
end;

function wglMakeCurrent(DC: HDC; p2: HGLRC): BOOL;
begin
  Result := true;
end;

function wglDeleteContext(p1: HGLRC): BOOL;
begin
  BackBuffer.Free;
  Result := true;
end;

function wglChoosePixelFormat(DC: HDC; p2: PPixelFormatDescriptor): Integer; stdcall;
begin
  Result := 1;
end;

function wglSwapBuffers(DC: HDC): BOOL; stdcall;
begin
  Result := true;
  if not BitBlt(DC, 0, 0, BackBuffer.Width, BackBuffer.Height, BackBuffer.Canvas.Handle, 0, 0, SRCCOPY) then
    RaiseLastOSError;
//  Result := Windows.SwapBuffers(DC);
end;

end.
