program Squares;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  RenderThread in 'RenderThread.pas',
  CalcThread in 'CalcThread.pas',
  Data in 'Data.pas',
  DGlut in 'DGlut.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
