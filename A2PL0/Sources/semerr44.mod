module  semerr44;

var m : array1;
var n : arrayx;        (* arrayx ist nicht definiert*)

const call = 33;

  procedure Read;
  var i : integer;
  var x : array0;
  begin
      i := 1;
      while i <= 7 do
         ?x[i];
         i := i + 1
      end;
      m[2] := x
  end Read;

type array1 = array 3 of array0;

  procedure WriteReverse;
  var x : arrayO;
  var i : integer;
  begin
     ;;;;;;;;;;;;;;;;;;;;;
     ;; x := m[2];      ;;    (* verschiedene Typen  *)
     ;; i := 7;       ;;
     ;; while i >= 1 do ;;
     ;;    !x[i];       ;;
     ;;    i := i - 1   ;;
     ;; end       ;;
     ;;;;;;;;;;;;;;;;;;;;;
  end WriteReverse;

type array0 = array 7 of integer;
type arrayO = array 7 of integer;

begin
   ! call[3];        (* indizierte Konstante *)
   Read;
   if ~odd m[2, 1] then
      WriteReverse
   else
      ! m[2, 1]
   end
end semerr44.


PL4.Compile semerr44.mod ~
