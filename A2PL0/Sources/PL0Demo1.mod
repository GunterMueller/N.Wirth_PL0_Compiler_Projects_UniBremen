module PL0Demo1;

const 
  N = 7; M = -300000;

var 
  x, y: integer;

  procedure Ausgabe;
  begin
    ! y;  ! x
  end Ausgabe;

  procedure Eingabe;
  begin
    ? x;  ? y;
    call Ausgabe
  end Eingabe;

begin
  ! N; ! M;
  call Eingabe;
  if x > 0 then begin
    if  y > 0 then begin
      ! x;  ! y
    end;
    if  y <= 0 then begin
      ! -x - y
    end 
  end;
  if x <= 0 then  ! -x - y
end PL0Demo1 .

----------------------------------------------

PL0.Compile  PL0Demo1.mod ~

RISCSystem.Decode ~

RISCSystem.Execute -2 10 ~    { Ausgabe: 7 -300000 10 -2 -8 }
RISCSystem.Execute  2 10  ~    { Ausgabe: 7 -300000 10 2 2 10 }




