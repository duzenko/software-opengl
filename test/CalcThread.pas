unit CalcThread;

interface

uses
  System.Classes;

type
  TCalcThread = class(TThread)
  protected
    procedure Execute; override;
  end;

implementation uses
  Forms, Data;

{ TCalcThread }

procedure TCalcThread.Execute;
begin
  NameThreadForDebugging('Calc');
  { Place thread code here }
  while not Application.Terminated do begin
    Sleep(1);
    Box.Move;
  end;
end;

end.
