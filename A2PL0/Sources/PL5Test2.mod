module PL5Test2;

  procedure Eingabe;
  begin
    ?x;  ?y; 
    Ausgabe( x,  y )
  end Eingabe;

var x, y: integer;

  procedure Ausgabe( x, y: integer );
  begin
    !x;  !y;
    y := 0;  x := 0
  end Ausgabe;

begin
  Eingabe;
  if  x > 0 & y > 0 or x > y then
    !x;  !y
  else
    ! -x - y;
  end 
end PL5Test2.

  PL5.Compile  PL5Test2.mod ~

  RISCSystem.Execute -2 10 ~    { Ausgabe: -2 10 -8 }
  RISCSystem.Execute  2 10 ~    { Ausgabe: 2 10 2 10 }
  RISCSystem.Execute  2 -10 ~  { Ausgabe: 2 -10 2 -10 }

  RISCSystem.Decode ~

  RISCSystem.SetBreakpoint  144  ~
  RISCSystem.Step  ~
  RISCSystem.Continue ~  
  
  RISCSystem.ShowMem 204 2 ~
