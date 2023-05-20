module PL1GGT;
var 
  x, y: integer;
begin 
  ? x; ? y; 
  if x > 0 then 
    if y > 0 then
    begin
      ! "GGT(";  ! x;  ! ',';  ! y;
      while x # y do 
      begin 
        if x < y then y := y - x;
        if x > y then x := x - y
      end;
      ! " )  = ";  ! x
    end
end PL1GGT. 

PL1.Compile  PL1GGT.mod ~


RISCSystem.Execute  3 11 ~    { Ausgabe: GGT( 3, 11 ) = 1 }
RISCSystem.Execute  25 30  ~  { Ausgabe: GGT( 25, 30 ) = 5 }

RISCSystem.Decode ~
