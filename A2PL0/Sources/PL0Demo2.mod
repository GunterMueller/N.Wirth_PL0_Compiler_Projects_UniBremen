module PL0Demo2;

  procedure NestedProcs;
  var i0, i1, i2, i3: integer;

    procedure P2;
    var i0, i2, i3: integer;
    
      procedure P3;
      var i3: integer;
      begin
        ! 3;
        i3 := i2;
        i1 := i1*i2 - i3;
        call P2
      end P3;
      
    begin
      ! 2; ! i1;
      if i1 < 500  then 
      begin
        i2 := i1 + 10;
        ! i2;
        call P3
      end
    end P2;
    
  begin
    i1 := 10;
    call P2;
    ! 1; ! i1
  end NestedProcs;

begin
  call NestedProcs
end PL0Demo2 .

---------------------------------------------

PL0.Compile  PL0Demo2.mod ~

RISCSystem.Execute ~    { Ausgabe:  2 10 20 3 2 180 190 3 2 34010 1 34010 }

RISCSystem.Decode ~


