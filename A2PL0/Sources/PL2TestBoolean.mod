module PL2TestBoolean;

const Ok = "ok\n";  Error = "error\n";

var b: boolean;  a: integer;

begin
  a := 2;
  b := true & 2 < a;
  if b then  ! Error  else  ! Ok  end;
  
  b := a = 2 & false;
  if b then  ! Error  else  ! Ok  end;
  
  b := a = 2 & true;
  if ~b then  ! Error  else  ! Ok  end;
  
  if ~(a = 2 & (false or a < 7 & true)) then
    ! Error 
  else
    ! Ok 
  end;
  if (true & a=2 or false & a=2) & true then
    ! Ok
  else
    ! Error
  end;
  if (true & a=2 or false & a=2) & false then
    ! Error
  else
    ! Ok
  end;
  if true & a#2 or true & a=2 or false then
    ! Ok
  else
    ! Error
  end;
end PL2TestBoolean .


PL2.Compile  PL2TestBoolean.mod ~

RISCSystem.Execute  ~

RISCSystem.Decode ~

RISCSystem.SetBreakpoint 376 ~
RISCSystem.Step ~
RISCSystem.Continue ~





