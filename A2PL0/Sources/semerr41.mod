module semerr42;

type Ta = array 4 of Tb;
type Tb = array 2 of integer;

var x : Ta;

begin
  ? x[2, 0];
  ? x[2];    (* Typfehler *)
  ! "abcd";
  ! x[2]    (* Typfehler *) 
end semerr42.

PL4.Compile  semerr41.mod ~
