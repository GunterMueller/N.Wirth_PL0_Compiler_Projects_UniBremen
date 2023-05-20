(*
 * Das Programm enthaelt fehlerhafte Typdefinitionen
 * mit vielen Folgefehlern.
 * Gut ist es, wenn nur fuer die gekennzeichneten Zeilen
 * Fehlermeldungen ausgegeben werden.
 *)
module semerr52;

var m : Array1;

type T0 = array 3 of array 2 of T2;

  procedure Read ( var k: Array0 );
  var i : integer;
  var x : Array0;
  begin
    i := 1;
    while i <= 7 do
      Input( x[i] );
      i := i + 1
    end;
    k := x;
    WriteReverse ( m );
  end Read;

type Array1 = array 3 of Array0;          (* zykl. Typdefinition *)
type T2 = array 2 of Input;              (* unzul. Elementtyp   *)

  procedure WriteReverse( m: Array1 );
  var x : Array0;
  var i : integer;
  begin
    x := m[2]; 
    if m[1, 1] > 0 then
      i := 7;       
      while i >= 1 do 
        ! x[i];     
        m[2, i] := 0;
        i := i - 1;
      end;
      m[1, 1] := m[1, 1] - 1;
      WriteReverse ( m );
    end
  end WriteReverse;

type Array0 = array 7 of Array;          (* zykl. Typdefinition *)

  procedure Input( var i: integer );
  begin
     ? i
  end Input;

type Array = array 7 of Array0;          (* zykl. Typdefinition *)

begin
  m[1, 1] := 2;
  Read ( m[2] );
  m[1, 1] := 1;
  WriteReverse ( m )
end semerr52.

PL5.Compile  semerr52.mod ~
