module PL2GGT;
var 
  x, y: integer;
begin 
  ? x; ? y; 
  if x > 0 & y > 0 then
    ! "GGT(";  ! x;  ! ',';  ! y;
    while x # y do 
      if x < y then  y := y - x  end;
      if x > y then  x := x - y  end
    end;
    ! " )  = ";  ! x
  end
end PL2GGT. 

PL2.Compile   PL2GGT.mod ~

RISCSystem.Execute  3 11 ~    { Ausgabe: GGT( 3, 11 ) = 1 }
RISCSystem.Execute  125 30  ~  { Ausgabe: GGT( 125, 30 ) = 5 }

RISCSystem.Decode ~
