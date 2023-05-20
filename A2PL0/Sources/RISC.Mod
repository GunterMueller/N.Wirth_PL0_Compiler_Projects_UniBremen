MODULE RISC;   (* Copyright (c) N. Wirth, 1994-96  *)

CONST 
  MemSize* = 8192; 
  
  (* opcodes: *)
  Add* = 0;  Sub* = 1;  Mul* = 2;  Div* = 3;  Mod* = 4;  
  Cmp* = 5;  Or* = 8;  And* = 9;  Bic* = 10;  Xor* = 11;  
  LSh* = 12;  ASh* = 13;  Chk* = 14; 
  
  Addi* = 16;  Subi* = 17;  Muli* = 18;  Divi* = 19;  Modi* = 20;
  Cmpi* = 21;  Ori* = 24;  Andi* = 25;  Bici* = 26;  Xori* = 27;  
  LShi* = 28;  AShi* = 29;  Chki* = 30;  
  
  Ldw* = 32;  Ldb* = 33;  Pop* = 34;  Stw* = 36;  Stb* = 37;  Push* = 38;  
  
  Beq* = 40;  Bne* = 41;  Blt* = 42;  Bge* = 43;  Ble* = 44;  Bgt* = 45;  
  
  Bsr* = 46;  Jsr* = 48;  Ret* = 49;  Sys* = 50;
  
  
  (* cpu states*)
  Running* = 0;  Stopped* = 1;  Trapped* = 2;  Terminated* = 3;  
    
VAR 
  PSR- : SIGNED32;    (* processor status *)
  PC*: INTEGER;        (* program counter *)
  R*: ARRAY 32 OF SIGNED32;    (* r0 = 0, r30 = SP, r31 = link *)
  
  mem*: ARRAY MemSize DIV 4 OF SIGNED32;  
  
  syscall*: PROCEDURE( op, reg: INTEGER );
  
  breakpoint*: INTEGER; 
  interrupt*: BOOLEAN;
  
  
CONST
  NoBreak = -1;

  PROCEDURE exec*( singlestep: BOOLEAN );  
  VAR  
    IR: SIGNED32; 
    opcode, a, b, c, addr, next: INTEGER; 
    h: SET32;
  BEGIN 
    PSR := Running;  interrupt := FALSE;
    LOOP 
      IF interrupt OR (PC = breakpoint) THEN  
        breakpoint := NoBreak;  PSR := Stopped;  RETURN 
      END;  
      R[0] := 0;  next := PC + 1;  IR := mem[PC];  
      opcode := IR DIV 4000000H MOD 40H;  
      a := IR DIV 200000H MOD 20H; 
      b := IR DIV 10000H MOD 20H;  
      c := IR MOD 10000H;  
      IF (opcode < Addi) OR (opcode = Ret) THEN  c := R[c MOD 20H]; 
      ELSIF c >= 8000H THEN  DEC( c, 10000H ) (*sign extension*)
      END;  
      CASE opcode OF 
      Add, Addi: 
          R[a] := R[b] + c
      | Sub, Subi, Cmp, Cmpi: 
          R[a] := R[b] - c
      | Mul, Muli: 
          R[a] := R[b]*c
      | Div, Divi: 
          R[a] := R[b] DIV c
      | Mod, Modi: 
          R[a] := R[b] MOD c
      | Or, Ori: 
          R[a] := SIGNED32( SET32( R[b] ) + SET32( c ) )
      | And, Andi: 
          R[a] := SIGNED32( SET32( R[b] ) * SET32( c ) )
      | Bic, Bici: 
          R[a] := SIGNED32( SET32( R[b] ) - SET32( c ) )
      | Xor, Xori: 
          R[a] := SIGNED32( SET32( R[b] ) / SET32( c ) )
      | LSh, LShi: 
          R[a] := LSH( R[b], c )
      | ASh, AShi: 
          R[a] := ASH( R[b], c )
      | Chk, Chki: 
          IF (R[a] < 0) OR (R[a] >= c) THEN 
            PSR := Trapped;  RETURN
          END 
      | Ldw: 
          R[a] := mem[(R[b] + c) DIV 4]
      | Ldb: 
          addr := R[b] + c;
          R[a] := LSH( mem[addr DIV 4], -(addr MOD 4*8) ) MOD 100H;
      | Pop: 
          R[a] := mem[(R[b]) DIV 4];  INC( R[b], c )
      | Stw: 
          mem[(R[b] + c) DIV 4] := R[a]
      | Stb:
          addr := R[b] + c;
          h := SET32( mem[addr DIV 4] );
          CASE (R[b] + c) MOD 4 OF
          | 0: h := (h * SET32( 0FFFFFF00H )) + SET32( R[a] MOD 100H )
          | 1: h := (h * SET32( 0FFFF00FFH )) + SET32( R[a] MOD 100H * 100H )
          | 2: h := (h * SET32( 0FF00FFFFH )) + SET32( R[a] MOD 100H * 10000H)
          | 3: h := (h * SET32( 000FFFFFFH )) + SET32( R[a] MOD 100H * 1000000H)
          END;
          mem[addr DIV 4] := SIGNED32( h )
      | Push: 
          DEC( R[b], c );  mem[(R[b]) DIV 4] := R[a]
      | Beq: 
          IF R[a]  =  R[b] THEN  next := PC + c  END 
      | Bne: 
          IF R[a]  #  R[b] THEN  next := PC + c  END 
      | Blt: 
          IF R[a]  <  R[b] THEN  next := PC + c  END 
      | Bge: 
          IF R[a] >= R[b] THEN  next := PC + c  END 
      | Ble: 
          IF R[a] <= R[b] THEN  next := PC + c  END 
      | Bgt: 
          IF R[a]  >  R[b] THEN  next := PC + c  END 
      | Bsr: 
          next := PC + c;  R[31] := (PC + 1)*4
      | Jsr: 
          next := IR MOD 4000000H;  R[31] := (PC + 1)*4
      | Ret: 
          next := c DIV 4;  
          IF next = 0 THEN  
            breakpoint := NoBreak;  PSR := Terminated;  RETURN  
          END 
      | Sys:
          syscall( a, b );
      ELSE 
        (* illegal instruction *) PSR := Trapped;  RETURN
      END;  
      IF (next < 0) OR (next >= (MemSize DIV 4)) THEN
        PSR := Trapped;  RETURN
      END;
      PC := next;  
      IF singlestep THEN  
        PSR := Stopped;  RETURN  
      END
    END;  
  END exec;  

BEGIN
  breakpoint := NoBreak
END RISC.