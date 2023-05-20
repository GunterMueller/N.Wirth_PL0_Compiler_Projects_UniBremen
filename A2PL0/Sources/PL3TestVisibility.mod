module PL3TestVisibility;

  procedure P1;
  begin
    Eingabe;
    if x > 0 & y > 0 then
      ! x;  ! y
    else
      ! -x - y;
    end
  end P1;
  
  procedure Eingabe;
  begin
    ? x;  ? y;
    Ausgabe
  end Eingabe;

  procedure Ausgabe;
  begin
    ! N; ! M; ! y;  ! x
  end Ausgabe;
  
var 
  x, y: integer;  

const 
  N = 7; M = -300000;    

begin
  P1
end PL3TestVisibility .


PL3.Compile  PL3TestVisibility.mod ~

RISCSystem.Execute -2 10 ~    { Ausgabe: 7 -300000 10 -2 -8 }
RISCSystem.Execute  2 10  ~    { Ausgabe: 7 -300000 10 2 2 10 }

RISCSystem.Decode ~


