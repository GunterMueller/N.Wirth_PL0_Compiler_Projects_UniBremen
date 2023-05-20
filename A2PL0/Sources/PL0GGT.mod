module PL0GGT;
var 
  x, y: integer;
begin 
  ? x; ? y; 
  if x > 0 then 
    if y > 0 then
    begin
      ! x; ! y;
      while x # y do 
      begin 
        if x < y then y := y - x
        if x > y then x := x - y
      end;
      ! x
    end;
end PL0GGT. 


--------------------------------------------

PL0.Compile  PL0GGT.mod ~
PL0.Compile  -p PL0GGT.mod ~    (* trace parser *)
PL0.Compile  -a PL0GGT.mod ~    (* trace analysis *)
PL0.Compile  -c PL0GGT.mod ~    (* trace code generation *)

RISCSystem.Execute 3 11 ~    { Ausgabe: 3 11 1 }
RISCSystem.Execute 25 30  ~  { Ausgabe: 25 30 5 }

RISCSystem.Decode ~
