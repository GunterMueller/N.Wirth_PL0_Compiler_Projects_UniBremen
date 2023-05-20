module PL5Test1;

const N = 7;  M = -300000;

var x, y, z: integer;

  procedure Ausgabe;
  begin
    ! y;  ! x
  end Ausgabe;

  procedure Eingabe;
  begin
    ? x;  ? y;
    Ausgabe
  end Eingabe;

  procedure NestedProcs;
  var i1, i2, i3: integer;

    procedure P2;
    var i2, i3: integer;
    
      procedure P3;
      var i3: integer;
      begin
        i3 := 1;
        i1 := i1*i2 - (4 + i3 - 1);
        P2
      end P3;
      
    begin
      if i1 < 500 then
        i2 := i1 + 7;
        i3 := 25;
        P3;
        if i3 # 25 then
          ! "error\n"
        end 
      end 
    end P2;
    
  begin
    i1 := 12;
    P2;
    ! i1; 
  end NestedProcs;

begin
  ! N; ! M;
  Eingabe;
  if x > 0 then
    z := 0;
    if  y > 0 then
      ! x;  ! y
    else
      ! -x - y;
    end 
  else
    ! -x - y;
  end;
  NestedProcs
end PL5Test1 .


PL5.Compile PL5Test1.mod ~

RISCSystem.Execute -2 10 ~    { Ausgabe: 7 -300000 10 -2 -8 51740 }
RISCSystem.Execute  2 10  ~    { Ausgabe: 7 -300000 10 2 2 10 51740 }

RISCSystem.Decode ~