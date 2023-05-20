module semerr51;

  procedure p1( x, y: t1 );
  begin
     p2;          (* zu wenig Parameter *)
     p2(y);        
     p2(x, y)        (* zu viel Parameter  *)
  end p1;

  procedure p2( x: t1 );
  begin
     p1(x, x);
     p1(x, x[2]);       (* falscher Parametertyp *)
     p1(x);        (* zu wenig Parameter *)
     p1(x, x, x);       (* zu viel Parameter  *)
     p3;
     p3(x);        (* zu viel Parameter  *)         
     p4(x)        (* p4 ist keine Prozedur *)
  end p2;

type t1 = array 4 of boolean;

  procedure p3; 
  begin 
  end p3;

var p4 : boolean;

begin
  p3
end semerr51.


PL5.Compile semerr51.mod ~
