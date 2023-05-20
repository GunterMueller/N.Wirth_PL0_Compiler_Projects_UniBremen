module PL4TestArrays1;

const  N = 200;
  
var  sive: array N of boolean;

  procedure primes;
  var i, j, p, n: integer;  
  begin
    ! "compute small prime numbers:\n";
    InitSive;
    i := 1; n := 0;
    while i < N do
      if sive[i] then  
        p := 2*i + 1;  ! p; 
        n := n + 1;
        if n = 16 then
          ! "\n";  n := 0
        end;
        j := i + p; 
        while j < N do
          sive[j] := false;  j := j + p
        end;
      end;
      i := i + 1
    end
  end primes;
  
  procedure InitSive;
  var i: integer;
  begin
    i := 0;
    while i < N do
      sive[i] := true;  i := i + 1
    end
  end InitSive;

begin
  primes
end PL4TestArrays1.

------------------------------------------------

  PL4.Compile  PL4TestArrays1.mod 

  RISCSystem.Execute ~

  RISCSystem.Decode ~

  RISCSystem.SetBreakpoint  304  ~
  RISCSystem.Step  ~
  RISCSystem.Continue ~  
  
  RISCSystem.ShowMem 336 20 ~
