module PL5Test3;

type 
  A = array 6 of integer;

var 
  x, y: A;
  z: integer;
  
  procedure P( a: A; var b: A; x: integer );
  begin
    ! x;
    ! a[4];
    b[2] := a[4] + 4;
    a[2] := 0
  end P;
  
begin
  x[0] := 1;
  x[1] := 2;
  x[2] := 3;
  x[4] := 5;
  z := x[x[2]+1] + 3;
  ! z;
  P( x, y, z );
  P( x, y, x[x[2]+1] + 3 );
  ! y[2]
end PL5Test3.


PL5.Compile PL5Test3.mod

RISCSystem.Execute  ~    { exp. output: 8 8 5 8 5 9 }

RISCSystem.Decode ~
