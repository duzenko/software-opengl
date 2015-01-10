unit Data;

interface

type
  TBox = record
  private
  public
    w, h, a, x, y: Single;
    Speed: record
      x, y: Single;
    end;

    function l: Single;
    function r: Single;
    function t: Single;
    function b: Single;

    procedure Move;
  end;

  TPoint = record
    x, y: Single;
  end;
  PPoint = ^TPoint;

  TPointsRelative = record
    p1, p2: Integer;
    f1, f2: Single;
    function Approx: TPoint;
  end;

  TWay = record
    Points: array[0..3] of TPoint;
    procedure FindRelative(f: Single; out Relative: TPointsRelative);
  end;

const
  r = 0.85;
var
  Box: TBox = (
    w: 0.2; h: 0.1; Speed: (x: 0.002; y: 0.001)
  );
  Way: TWay  = (
    Points: ((x: -r; y: -r), (x: +r; y: -r), (x: +r; y: +r), (x: -r; y: +r))
  );
var
  rel: TPointsRelative;

implementation

{ TBox }

function TBox.t: Single;
begin
  Result := -h/2;
end;

function TBox.b: Single;
begin
  Result := h/2;
end;

function TBox.l: Single;
begin
  Result := -w/2;
end;

function TBox.r: Single;
begin
  Result := w/2;
end;

procedure TBox.Move;
begin
  a := a + 0.1;
  while a >= 360 do
    a := a - 360;
  Way.FindRelative(a/360, rel);
  with rel.Approx do begin
    Self.x := x;
    Self.y := y;
  end;
{  l := l + Speed.x;
  t := t + Speed.y;
  if r >= 1 then
    Speed.x := -Abs(Speed.x);
  if l <= -1 then
    Speed.x := Abs(Speed.x);
  if b >= 1 then
    Speed.y := -Abs(Speed.y);
  if t <= -1 then
    Speed.y := Abs(Speed.y);  }
end;

function TPointsRelative.Approx;
begin
  Result.x := Way.Points[p1].x * f2 + Way.Points[p2].x * f1;
  Result.y := Way.Points[p1].y * f2 + Way.Points[p2].y * f1;
end;

procedure TWay.FindRelative;
var
  i: Integer;
  rl: Single;
begin
  rl := 1/Length(Points);
  for I := 0 to High(Points) do begin
    if f <= rl then begin
      Relative.p1 := i;
      if i < High(Points) then
        Relative.p2 := i+1
      else
        Relative.p2 := 0;
      Relative.f1 := f/rl;
      Relative.f2 := 1 - Relative.f1;
      Break;
    end;
    f := f - rl;
  end;
end;


end.
