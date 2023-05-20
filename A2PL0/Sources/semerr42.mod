module semerr42;

type a = array 4 of d;
type c = array 4 of b;
type b = array 2 of boolean;
type d = c;

var x : a;

begin
  ? x[2, 1];    (* fehlerhafter Typ *)
  ! x[2, 1, 3]    (* fehlerhafte Indizierung *)
end semerr42.


PL4.Compile  semerr42.mod ~
