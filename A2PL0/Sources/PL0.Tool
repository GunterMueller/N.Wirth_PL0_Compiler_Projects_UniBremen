Documentation and Tasks:

   PL0.RISC.System.Text
  PL0.PL6.Syntax.Text
  Aufgaben.Text
  
==========================================================

Target System:

Compiler.Compile
  RISC.Mod    (* processor *)
  RISCDecoder.Mod
  RISCSystem.Mod
  ~

Commands:
  RISCSystem.Execute  ...  ... ...  ~
  RISCSystem.Decode ~
  
Debug Commands:
  RISCSystem.SetBreakpoint  addr  ~
  RISCSystem.Step  ~
  RISCSystem.Continue ~  
  RISCSystem.Break ~
  RISCSystem.ShowMem  addr len ~


==========================================================
PL0 (initial compiler)

Compiler.Compile  
  PL0Global.Mod
  PL0IdentifierTable.Mod  PL0Scanner.Mod  
  PL0ObjectTable.Mod    PL0Objects.Mod
  
  PL0CodeGenerator.Mod
  
  (* syntax tree:  *)
  PL0Nodes.Mod
  PL0Constants.Mod    PL0Denotations.Mod
  PL0Types.Mod      PL0Variables.Mod
  PL0Blocks.Mod      PL0Procedures.Mod
  PL0Expressions.Mod  PL0Statements.Mod
  
  PL0Parser.Mod
  PL0.Mod  
  ~  
Demo programs:
  
  PL0Demo1.mod  PL0Demo2.mod  PL0GGT.mod
  
  
==========================================================
Sample Solutions:
  
PL1 (identifier hashing, string constants, additional symbols/keywords)

Compiler.Compile  
  PL1Global.Mod
  PL1IdentifierTable.Mod  PL1Scanner.Mod  
  PL1ObjectTable.Mod    PL1Objects.Mod
  
  PL1CodeGenerator.Mod
  
  PL1Nodes.Mod
  PL1Constants.Mod    PL1Denotations.Mod
  PL1Types.Mod      PL1Variables.Mod
  PL1Blocks.Mod      PL1Procedures.Mod
  PL1Expressions.Mod  PL1Statements.Mod
  
  PL1Parser.Mod
  PL1.Mod  
  ~  
Test  programs:
  synterr11.mod
  
  PL1TestStrings.mod  PL1GGT.mod


PL2 (different syntax,  type boolean,  boolean expressions) 

Compiler.Compile  
  PL2Global.Mod
  PL2IdentifierTable.Mod  PL2Scanner.Mod  
  PL2ObjectTable.Mod    PL2Objects.Mod
  
  PL2CodeGenerator.Mod
  
  PL2Nodes.Mod
  PL2Constants.Mod    PL2Denotations.Mod
  PL2Types.Mod      PL2Variables.Mod
  PL2Blocks.Mod      PL2Procedures.Mod
  PL2Expressions.Mod  PL2Statements.Mod
  
  PL2Parser.Mod
  PL2.Mod  
  ~  
Test  programs:
  
  PL2TestBoolean.mod   PL2GGT.mod
  
  

PL3 (latticed object table, linear visibility -> block scope visibility)

Compiler.Compile  
  PL3Global.Mod
  PL3IdentifierTable.Mod  PL3Scanner.Mod  
  PL3ObjectTable.Mod    PL3Objects.Mod
  
  PL3CodeGenerator.Mod
  
  PL3Nodes.Mod
  PL3Constants.Mod    PL3Denotations.Mod
  PL3Types.Mod      PL3Variables.Mod
  PL3Blocks.Mod      PL3Procedures.Mod
  PL3Expressions.Mod  PL3Statements.Mod  
  
  PL3Parser.Mod
  PL3.Mod  
  ~  
Test  programs:

  PL3TestVisibility.mod  
  
  

PL4 (type declarations, array types) 

Compiler.Compile  
  PL4Global.Mod
  PL4IdentifierTable.Mod  PL4Scanner.Mod  
  PL4ObjectTable.Mod    PL4Objects.Mod
  
  PL4CodeGenerator.Mod
  
  PL4Nodes.Mod
  PL4Constants.Mod    PL4Denotations.Mod
  PL4Types.Mod      PL4Variables.Mod
  PL4Blocks.Mod      PL4Procedures.Mod
  PL4Expressions.Mod  PL4Statements.Mod
  
  PL4Parser.Mod
  PL4.Mod  
  ~  

Test  programs:
  synterr41.mod

  semerr41.mod  semerr42.mod  semerr43.mod  semerr44.mod
  
  PL4TestArrays1.mod  PL4TestArrays2.mod 
  
  
  
PL5 (procedures with  prameters)

Compiler.Compile  
  PL5Global.Mod
  PL5IdentifierTable.Mod  PL5Scanner.Mod  
  PL5ObjectTable.Mod    PL5Objects.Mod
  
  PL5CodeGenerator.Mod
  
  PL5Nodes.Mod
  PL5Constants.Mod    PL5Denotations.Mod
  PL5Types.Mod      PL5Variables.Mod
  PL5Blocks.Mod      PL5Procedures.Mod
  PL5Expressions.Mod  PL5Statements.Mod
  
  PL5Parser.Mod
  PL5.Mod  
  ~          
  
Test programs:
  synterr51.mod  synterr52.mod  

  semerr51.mod  semerr52.mod

  PL5Test1.mod  PL5Test2.mod  PL5Test3.mod
  PL5Test4.mod  PL5Test5.mod 
    

