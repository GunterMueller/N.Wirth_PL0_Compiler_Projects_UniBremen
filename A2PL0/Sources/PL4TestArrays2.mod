module PL4TestArrays2;

  procedure Primes;
  var
    sive: array N of boolean;
    i, j, p, n: integer;  
  
    procedure InitSive;
    var i: integer;
    begin
      i := 0;
      while i < N do
        sive[i] := true;  i := i + 1
      end
    end InitSive;
    
  begin
    ! "small prime numbers [3 ..";  ! 2*N;  ! "]:\n";
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
        end
      end;
      i := i + 1
    end
  end Primes;

const N = 500;

begin
  Primes
end PL4TestArrays2.

----------------------------------------------

PL4.Compile  PL4TestArrays2.mod 

RISCSystem.Execute ~

RISCSystem.Decode ~
