module PL5Test5;

var m : Array1;

  procedure Read( var k: Array0 );
  var i : integer;
  var x : Array0;
  begin
    i := 0;
    while i < 7 do
      Input( x[i] );  i := i + 1
    end;
    k := x;
    WriteReverse( m );          (* das globale m *)
  end Read;

type Array1 = array 3 of Array0;

  procedure WriteReverse( m: Array1 );
  var x: Array0;
    i : integer;
  begin
    x := m[1];     
    if m[0, 0] > 0 then
      ! '\n';
      i := 6;  
      m[2] := m[1];
      while  i >= 0  do 
        ! x[i];   
        m[1, i] := -m[2, 6-i];
        i := i - 1   
      end;          
      m[0, 0] := m[0, 0] - 1;
      WriteReverse ( m )          (* das lokale m !! *)  
    end
  end WriteReverse;

type Array0 = array 7 of integer;

  procedure Input( var i: integer );
  begin
    ? i
  end Input;

begin
  ! 'PL5 Testprogramm 5\n';
  ? m[0, 0] ;
  Read( m[1] );
  m[0, 0] := 1;
  WriteReverse( m )            (* und wieder das globale m *)
end PL5Test5.



PL5.Compile  PL5Test5.mod ~

RISCSystem.Decode ~

RISCSystem.Execute  2   1 2 3 4 5 6 7~    Ausgabe :  
                                7 6 5 4 3 2 1
                                 -1 -2 -3 -4 -5 -6 -7
                                 7 6 5 4 3 2 1
                                 
RISCSystem.Execute  6   2 3 4 5 6 7 8~    Ausgabe :  
                                8 7 6 5 4 3 2
                                -2 -3 -4 -5 -6 -7 -8
                                8 7 6 5 4 3 2
                                -2 -3 -4 -5 -6 -7 -8
                                8 7 6 5 4 3 2
                                -2 -3 -4 -5 -6 -7 -8
                                8 7 6 5 4 3 2
