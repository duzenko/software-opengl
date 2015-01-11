unit RenderThread;

interface uses
  Windows, Messages, SysUtils, System.Classes, Forms,
  OpenGL, DGLUT;

type
  TRenderThread = class(TThread)
  private
    RC: HGLRC;
    FDC: HDC;
    procedure CreateRC;
    procedure DestroyRC;
    procedure Resize;
    procedure Render;
    procedure UpdateFps;
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
begin        //exit;
  glpushMatrix; //Запомнили
  glTranslatef(-5,0,0); //Сместили
  glutSolidCube(1);      //Рисуем куб
  glPopmatrix;  //Восстановили

  glpushMatrix; //Запомнили
  glTranslatef(5,0,0); //Сместили
  glutSolidSphere(2,20,20);  //Рисуем сферу
  glPopmatrix; //Восстановили

  glpushMatrix; //Запомнили
  glTranslatef(0,5,0); //Сместили
  glutSolidTorus(1, 2, 20, 20);//Рисуем тор
  glPopmatrix; //Восстановили
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
  glEnable(GL_DEPTH_TEST); // включаем проверку разрешения фигур (впереди стоящая закрывает фигуру за ней)
//  glDepthFunc(GL_LEQUAL); //тип проверки
  glEnable(GL_LIGHTING); //включаем освещение
  glEnable(GL_LIGHT0); //включаем источник света №0
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
//    Sleep(1);

    if Resized then
      Resize;

    glClearColor(0, 0, ClearColor, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    Render;
    glFlush;
    CheckGlError;

    if not SwapBuffers(FDC) then
      RaiseLastOSError;
    UpdateFps;
  end;
  DestroyRC;
end;

procedure TRenderThread.SwapBuffersSync;
begin
  if not SwapBuffers(FDC) then
    RaiseLastOSError;
end;

procedure TRenderThread.UpdateFps;
const {$J+}
  Frames: Integer = 0;
  LastUpdate: Double = 0;
begin
  if LastUpdate = 0 then
    LastUpdate := PreciseTime;
  Inc(Frames);
  if LastUpdate + 1 <= PreciseTime then begin
    PostMessage(Application.MainForm.Handle, WM_USER, 0, Frames);
    LastUpdate := PreciseTime;
    Frames := 0;
  end;
end;

end.
