module synterr51;

var 
  m: array1;
     n: array1;

  procedure Read( var m: array0 );
  var i:  integer;
    x: array0;
  begin
      i := 1;
      while i <= 7 do
         Input( x[i] );
         i := i + 1
      end;
      m := x
  end Read;

type array1 = array 3 of array0;

  procedure WriteReverse;
  var x : array0;
    i : integer;
  begin
     x = m[2];            (* = statt := *)
     i := 7;
     while i >= 1 do
        ! x[i];
        i := i - 1
     end            
  end WriteReverse;

type array0 = array 7 of boolean;

  procedure Input( var i: integer );
  begin
     ? i
  end Input;
  
  procedure Output( i: integer );
  begin
     ! i
  end Output;

begin
   Read( m[2] );
   if ~odd m[2, 1] then
      WriteReverse
   else
      Output( m[2, 1 )             (* fehlende Indexklammer *)
   end
end synterr51.    


PL5.Compile  synterr51.mod ~
