module PL5Test4;

var m : Array1;

const call = 7;

  procedure Read( var m: Array0 );
  var i : integer;
    x : Array0;
  begin
    i := 0;
    while i <= 6 do
      Input( x[i] );
      i := i + 1
    end;
    m := x;
  end Read;

type 
  Array1 = array 3 of Array0;

  procedure WriteReverse;
  var x : Array0;
    i : integer;
  begin
    x := m[1]; 
    i := 6;
    while i >= 0 do
      ! x[i]; 
      i := i - 1
    end;
  end WriteReverse;

type 
  Array0 = array 7 of integer;

  procedure Input( var i: integer );
  begin
     ?i
  end Input;


begin
  ! 'PL5 Testprogramm 4\n'; 
  ! call; (* 'call' ist kein Prozeduraufruf mehr *)
  Read( m[1] );

  if ~( ~~ odd m[1,0] ) then
    WriteReverse
  else
    ! m[1,0]
  end
end PL5Test4.

PL5.Compile PL5Test4.mod ~

RISCSystem.Execute 2 3 4 5 6 7 8   ~    { Ausgabe: 7 8 7 6 5 4 3 2 }
RISCSystem.Execute 1 2 3 4 5 6 7   ~    { Ausgabe: 7 1 }

RISCSystem.Decode ~