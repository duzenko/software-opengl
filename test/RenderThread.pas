unit RenderThread;

interface uses
  Windows, Messages, SysUtils, System.Classes, Forms,
  OpenGL;

type
  TRenderThread = class(TThread)
  private
    RC: HGLRC;
    FDC: HDC;
    procedure CreateRC;
    procedure DestroyRC;
    procedure Resize;
    procedure Render;
  protected
    procedure Execute; override;
  public
    Resized: Boolean;
    ClearColor, RectColor: Single;
    procedure SwapBuffersSync();
  end;

const
  pfd: TPixelFormatDescriptor = (
    nSize: sizeOf(pfd);
    nVersion: 1;
    dwFlags: PFD_DRAW_TO_WINDOW {$IFNDEF SSOFT} + PFD_SUPPORT_OPENGL + PFD_DOUBLEBUFFER {$ENDIF}
  );

implementation uses
  Data, Utils;

procedure CheckGlError;
var
  e: GLenum;
begin
  e := glGetError;
  if e <> 0 then
    raise Exception.Create(string(gluErrorString(e)));
end;

{ TRenderThread }

procedure TRenderThread.Render;
begin
  glPointSize(20); // размер точки

  glBegin(GL_POINTS);
  glColor3f(1, 0, 0);
  glVertex3f(-2, 5, 1);
  glEnd;

glBegin(GL_LINES); //рисуем линию
glColor3f(1,0,0); {раскрасим первую вершину}  glVertex3f(-1,0,1); //позиция первой вершины
glColor3f(0,1,0); {раскрасим вторую вершину}   glVertex3f(-4,5,1); //позиция второй вершины
glEnd;

glBegin(GL_TRIANGLES); //рисуем треугольник
glColor3f(1,0,0);  glVertex3f(0,5,1); //первая вершина
glColor3f(0,1,0);  glVertex3f(1,4,1); //вторая вершина
glColor3f(0,1,0);  glVertex3f(-1,4,1); //третья вершина
glEnd;

glBegin(GL_QUADS); //рисуем квадрат
glColor3f(1,0,0);  glVertex3i(-1,1,0); //первая вершина
glColor3f(0,1,0);  glVertex3f(1,1,-0); //вторая вершина
glColor3f(0,1,1);  glVertex3f(1,-1,-0); //третья вершина
glColor3f(0,0,1);  glVertex3f(-1,-1,0); //четвёртая вершина
glEnd;

end;

procedure TRenderThread.Resize;
begin
  with Application.MainForm do begin
    glViewport(0, 0, ClientWidth, ClientHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    glFrustum ( -ClientWidth/ClientHeight , ClientWidth/ClientHeight , -1 , 1 , 1 , 100.0 ); //Область видимости
//    gluOrtho2D(-ClientWidth/ClientHeight, ClientWidth/ClientHeight, -1, 1);
  end;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity; //Сбрасываем текущую матрицу
  gluLookAt(5,5,5, 0,0,0, 0,0,1);
  //gluLookAt(0,-2,0, 0,0,0, 0,0,1); //позиция наблюдателя
  CheckGlError;
  Resized := false;
end;

procedure TRenderThread.CreateRC;
begin
  while Application.MainForm = nil do
    Sleep(1);
  FDC := GetDC(Application.MainForm.Handle);
  RC := wglCreateContext(FDC);
  if RC = 0 then
    RaiseLastOSError;
  wglMakeCurrent(FDC, RC);
end;

procedure TRenderThread.DestroyRC;
begin
  wglDeleteContext(RC);
  ReleaseDC(Application.MainForm.Handle, FDC);
end;

procedure TRenderThread.Execute;
begin
  NameThreadForDebugging('GL Renderer');
  { Place thread code here }
  CreateRC;
  while not Resized do
    Sleep(1);
  while not Application.Terminated do begin
    Sleep(1);

    if Resized then
      Resize;

    glClearColor(0, 0, ClearColor, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    Render;
    glFlush;
    CheckGlError;

    if not SwapBuffers(FDC) then
      RaiseLastOSError;
    PostMessage(Application.MainForm.Handle, WM_USER, 0, 0);
  end;
  DestroyRC;
end;

procedure TRenderThread.SwapBuffersSync;
begin
  if not SwapBuffers(FDC) then
    RaiseLastOSError;
end;

end.
