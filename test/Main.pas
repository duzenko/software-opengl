unit Main;

interface uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  RenderThread, CalcThread;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  private
    FRender: TRenderThread;
    FCalc: TCalcThread;
    procedure WMUser(var msg: TMessage); message WM_USER;
  public
  end;

var
  Form1: TForm1;

implementation uses
  Data, Utils;

{$R *.dfm}

procedure TForm1.FormClick(Sender: TObject);
begin
//  FRender.Paint;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  i := ChoosePixelFormat(Canvas.Handle, @pfd);
  if i = 0 then
    RaiseLastOSError;
  SetPixelFormat(Canvas.Handle, i, @pfd);
  FRender := TRenderThread.Create();
  FRender.RectColor := 1;
  FCalc := TCalcThread.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FCalc.Free;
  FRender.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
  VK_ESCAPE:
    Close;
  end;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  FRender.ClearColor := X / ClientWidth;
  FRender.RectColor := Y / ClientHeight;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  FRender.Resized := true;
end;

procedure TForm1.WMUser(var msg: TMessage);
begin
  Caption := IntToStr(msg.LParam) + ' fps';
end;

end.
