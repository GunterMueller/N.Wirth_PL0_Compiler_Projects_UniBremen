module synterr41;

var m : array1;
    n : array0;    
    o = array1;            (* '=' anstelle von ':'   *)
    
const call = 33;

  procedure read          (* ';' fehlt      *)
  var i : integer;
  var x = array0;           (* '=' anstelle von ':'    *)
  begin
      i := 1;
      while i <= 7 do
             ?x[i];
             i := i + 1
      end;        
      m[2] := x
  end read;

type array1 = array 3 of array0;

  procedure writeReverse;
  var x : array0;
  var i : integer;
  begin
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ;; x := m[2];            ;;
     ;; i := 7;                 ;;
     ;; while i >= 1 do ;;
     ;;    !x[i];                 ;;
     ;;    i := i - 1            ;;
     ;; end                     ;;  
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  end writeReverse;

type array0 = array 7 of integer;

begin
   ! call;
   read;
   if ~ odd m[2, 1 then        (* ']' fehlt      *)
      writeReverse
   else
      ! m[2, ]              (* Indexausdruck fehlt    *)
   end
end synterr41.


PL4.Compile  synterr41.mod ~


