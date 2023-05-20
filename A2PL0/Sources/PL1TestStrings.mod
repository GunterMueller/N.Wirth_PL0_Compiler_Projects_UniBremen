module PL1TestStrings;

const
  Line = "================================\n";

begin
  ! "\nTestprogramm 1\n";
  ! Line;  
  ! '012345678912\n';
  ! 'dies ist ein langer\nmehrzeiliger String\t\t\"--\"\nmit \\n, \\t und \\".\n';
  ! 356;  !'\n';
  ! 384000;  !'\n';
  ! Line
end PL1TestStrings.


PL1.Compile PL1TestStrings.mod ~

RISCSystem.Execute  ~

RISCSystem.Decode ~






