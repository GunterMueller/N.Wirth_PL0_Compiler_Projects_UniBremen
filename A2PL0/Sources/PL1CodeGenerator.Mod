MODULE PL1CodeGenerator;   (* gf  9.12.04  *)

IMPORT Files, Strings, 
  G := PL1Global, S := PL1Scanner, O := PL1Objects,
  RISC, D := RISCDecoder;

CONST   
  MaxCode = 1000;  MaxRel = 200;  MaxLev = G.MaxNestingLevel; 
  
  (* reserved registers *)
  FP = 29;  SP = 30;  LNK = 31;  (* r0 = allways zero,  r1 = function return *) 
   

TYPE 
  Object = O.Object;
  Type = O.Type;
  Variable = O.Variable;  
  Constant = O.Constant;  StringConstant = O.StringConstant;  
  Procedure = O.Procedure;
  
  Register = INTEGER;
  Link* = INTEGER;

  Item* = POINTER TO RECORD  (* item used for delayed code emission *)
    mode-, lev-  : INTEGER; 
    type*      : Type;  
    r        : Register;
    off*      : INTEGER;    (* immediate value, (offset or constant) *)
    false-, true-  : Link;  
  END;  
      
CONST 
  VarAddr = 1;  ConstAddr = 2;  Reg = 3;  Const* = 4;  Cond = 5;  (* Item mode *)
  
  Reserved = {0, 1, FP, SP, LNK}; (* r0 = 0, r1 = function return register *)
  

VAR 
  currLevel-: INTEGER;    (* current nesting level *)
  
  (* space needed for global variables, supplied by context analysis *)
  varspace*: INTEGER;  

  pc-, pcc, rel, entry: INTEGER;  
  
  code    : ARRAY MaxCode OF SIGNED32;    (* generated machine instructions *)
  constants  : ARRAY MaxCode OF SIGNED32;    (* strings and large integer constants *)
  reloc    : ARRAY MaxRel OF SIGNED32;      (* instructions which access global variables or constants *)

  FPregs  : ARRAY MaxLev OF Register;    (* registers pointing to intermediate frames *)
  
  usedRegs    : SET32;  (* registers in use *)
  usedFPregs  : SET32;  (* registers used as intermediate FPs *)

  
  PROCEDURE GetReg( ): Register;  
  VAR r: Register;  
  BEGIN  r := 2;
    REPEAT  
      IF ~(r IN usedRegs) THEN  
        INCL( usedRegs, r );  RETURN  r
      END;
      INC( r );
    UNTIL  r = FP;
    G.FatalError( "out of registers" )
  END GetReg;  
  
  PROCEDURE RetReg( r: Register );  
  BEGIN  
    IF ~((r IN Reserved) OR (r IN usedFPregs)) THEN  
      EXCL( usedRegs, r )  
    END
  END RetReg;
  
  PROCEDURE GetFPRegister-;
  VAR r: Register;
  BEGIN
    r := GetReg( );
    FPregs[currLevel] := r;  INCL( usedFPregs, r )
  END GetFPRegister;
  
  PROCEDURE ReturnFPRegister-;
  VAR r: Register;
  BEGIN
    r := FPregs[currLevel];
    EXCL( usedFPregs, r ); RetReg( r );
  END ReturnFPRegister;
  
  PROCEDURE IncLevel-;  
  BEGIN 
    INC( currLevel );  
  END IncLevel;  

  PROCEDURE DecLevel-;  
  BEGIN 
    DEC( currLevel );  
  END DecLevel;  
  
  
  PROCEDURE MarkReloc;
  (* register current instruction for relocation *)
  BEGIN
    reloc[rel] := pc;  INC( rel )
  END MarkReloc;

  PROCEDURE Put( op, a, b, c: INTEGER );  
  BEGIN  (*emit instruction*)
    IF op >= 32 THEN  DEC( op, 64 )  END;  
    code[pc] := ASH( ASH( ASH( op, 5 ) + a, 5 ) + b, 16 ) + (c MOD 10000H);  
    IF G.traceCode THEN
      D.DecodeInstruction( pc, code[pc], G.cw )
    END;
    INC( pc ) 
  END Put;  

  PROCEDURE PutOp( op: INTEGER;  x, y: Item );  
  VAR r: Register;  
  BEGIN 
    IF x.mode # Reg THEN  Load( x )  END;  
    IF x.r = 0 THEN  x.r := GetReg( );  r := 0  ELSE  r := x.r  END;  
    IF y.mode = Const THEN  
      Put( op + 16, r, x.r, y.off )  
    ELSE  
      IF y.mode # Reg THEN  Load( y )  END;  
      Put( op, x.r, r, y.r );  RetReg( y.r ) 
    END  
  END PutOp;  
  

  PROCEDURE AllocateString*( str: G.String ): INTEGER;  
  (* allocate string in constant area of code*)
  VAR 
    word, byte, start, j: INTEGER;  
    l, wl, i, k: SIZE;
  BEGIN 
    start := pcc;
    l := Strings.Length( str^ ) + 1;
    wl := (l + 3) DIV 4;
    FOR i := 0 TO wl - 1 DO
      word := 0;
      FOR j := 0 TO 3 DO
        k := 4*i + 3 - j;
        IF k < l THEN  byte := ORD( str[k] )  ELSE  byte := 0 END;
        word := word*100H + byte
      END;
      constants[pcc] := word;  INC( pcc )
    END;
    RETURN start*4
  END AllocateString;  
  
  
  PROCEDURE StringConstItem*( obj: StringConstant ): Item;
  VAR x: Item;
  BEGIN
    NEW( x );
    IF obj.addr = -1 THEN
      obj.addr := AllocateString( obj.value )
    END;
    x.mode := ConstAddr;  x.type := obj.type;  x.off := obj.addr;
    RETURN x
  END StringConstItem;
  
  
  PROCEDURE ConstantItem*( obj: Constant ): Item;
  VAR x: Item;
  BEGIN
    NEW( x );
    IF ABS( obj.value ) < 10000H THEN
      x.mode := Const;  x.type := obj.type;  x.off := obj.value;
    ELSE
      IF obj.addr = -1 THEN
        constants[pcc] := obj.value;  INC( pcc );
        obj.addr := 4*(pcc - 1)
      END;
      x.mode := ConstAddr;  x.type := obj.type;  x.off := obj.addr;
    END;
    RETURN x
  END ConstantItem;
  
  
  PROCEDURE VariableItem*( obj: Object ): Item;  
  VAR x: Item;
  BEGIN 
    NEW( x );
    WITH obj: Variable DO
      x.mode := VarAddr;  x.type := obj.type;  x.lev := obj.level;  
      x.off := obj.addr;  
      IF x.lev = 0 THEN  
        x.r := 0 
      ELSIF x.lev = currLevel THEN  
        x.r := FP 
      ELSE  
        x.r := FPregs[x.lev]
      END;
    END;
    RETURN x
  END VariableItem;  
  

  PROCEDURE Load*( VAR x: Item );  
  VAR r: Register;  
  BEGIN  
    IF x.mode = VarAddr THEN  
      IF x.lev = 0 THEN  MarkReloc  END;  
      r := GetReg( );  
      IF x.type.size = 1 THEN
        Put( RISC.Ldb, r, x.r, x.off )
      ELSE
        Put( RISC.Ldw, r, x.r, x.off )
      END;  
      RetReg( x.r );  x.r := r 
    ELSIF x.mode = ConstAddr THEN  
      MarkReloc; 
      x.r := GetReg( );  Put( RISC.Ldw, x.r, 0, x.off )
    ELSIF x.mode = Const THEN  
      IF x.off = 0 THEN  
        x.r := 0  
      ELSE  
        x.r := GetReg( );  Put( RISC.Addi, x.r, 0, x.off )  
      END  
    END;  
    x.mode := Reg 
  END Load;  


  PROCEDURE LoadAddr*( VAR x: Item );  
  VAR r: Register;  
  BEGIN  
    IF x.mode = VarAddr THEN  
      IF x.lev = 0 THEN  MarkReloc  END;  
      r := GetReg( );  
      Put( RISC.Addi, r, x.r, x.off );  RetReg( x.r );  x.r := r 
    ELSIF x.mode = ConstAddr THEN  
      MarkReloc; 
      x.r := GetReg( );  Put( RISC.Addi, x.r, 0, x.off )
    END;  
    x.mode := Reg 
  END LoadAddr;  
  

  PROCEDURE FixLink*( link: Link );
  VAR next: Link;  distance: INTEGER;
  BEGIN 
    WHILE link # 0 DO
      distance := (pc - link) MOD 10000H;
      next := code[link] MOD 10000H;  
      code[link] := code[link] DIV 10000H * 10000H + distance;
      link := next;
    END;
  END FixLink;
  

  PROCEDURE JumpBackw*( link: Link );  
  BEGIN 
    Put( RISC.Beq, 0, 0, link - pc ) 
  END JumpBackw;  

  PROCEDURE JumpForw*( ): Link;  
  BEGIN 
    Put( RISC.Beq, 0, 0, 0 );  
    RETURN pc - 1 
  END JumpForw;  


  PROCEDURE ToCondition*( x: Item ): Item;  
  BEGIN 
    IF x.mode # Cond THEN
      CASE x.mode OF 
      | VarAddr, ConstAddr:   
          Load( x );  
          Put( RISC.Beq, x.r, 0, 0 );  RetReg( x.r );   
      | Reg:
          Put( RISC.Beq, x.r, 0, 0 );  RetReg( x.r );   
      | Const: 
          IF x.off = 0 THEN  
            Put( RISC.Beq, 0, 0, 0 ) (* branch allways *)
          ELSE  
            Put( RISC.Bne, 0, 0, 0 ) (* branch never (NOP) *)
          END  
      END;  
      x.mode := Cond;  x.type := O.boolean;   x.false := pc - 1;  x.true := 0
    END;
    RETURN x
  END ToCondition;  
  

  PROCEDURE CondBranch*( op: INTEGER; VAR x: Item; y: Item );  
  BEGIN 
    IF x.mode # Reg THEN  Load( x )  END;  
    IF y.mode # Reg THEN  Load( y )  END;  
    CASE op OF 
    | S.EQ:  Put( RISC.Bne, x.r, y.r, 0 ) 
    | S.NE:  Put( RISC.Beq, x.r, y.r, 0 ) 
    | S.LT:   Put( RISC.Bge, x.r, y.r, 0 ) 
    | S.LE:  Put( RISC.Bgt, x.r, y.r, 0 ) 
    | S.GE:  Put( RISC.Blt, x.r, y.r, 0 ) 
    | S.GT:  Put( RISC.Ble, x.r, y.r, 0 ) 
    END;  
    RetReg( x.r );  RetReg( y.r );  
    x.mode := Cond;  x.type := O.boolean;  x.false := pc - 1;  x.true := 0;
  END CondBranch;  
  

  PROCEDURE Store*( x, y: Item );   (* x := y *)
  BEGIN 
    IF y.mode # Reg THEN  Load( y )  END;  
    IF x.lev = 0 THEN  MarkReloc  END;  
    IF x.type.size = 1 THEN
      Put( RISC.Stb, y.r, x.r, x.off ); 
    ELSE
      Put( RISC.Stw, y.r, x.r, x.off )
    END;  
    RetReg( x.r );  RetReg( y.r ) 
  END Store;  
  

  PROCEDURE Call*( obj: Procedure );  
  BEGIN 
    IF (currLevel > 0) & (obj.level >= currLevel) THEN
      (* save FP as intermediate FP *)
      Put( RISC.Addi, FPregs[currLevel], FP, 0 )
    END;
    IF obj.waddr >= 0 THEN  
      Put( RISC.Bsr, 0, 0, obj.waddr - pc ) 
    ELSE  
      (* create chain of forward references *)
      IF obj.waddr = -1 THEN  
        Put( RISC.Bsr, 0, 0, 0 )  
      ELSE  
        Put( RISC.Bsr, 0, 0, -obj.waddr )
      END;  
      obj.waddr := -(pc - 1) 
    END  
  END Call;  


  PROCEDURE Prologue*( varspace: INTEGER );  
  BEGIN 
    IF currLevel = 0 THEN  
      entry := pc;  
      Put( RISC.Addi, SP, 0, RISC.MemSize (*- vsize*) );
      Put( RISC.Push, 0, SP, 4 );   (* push Link *)
    ELSE  
      Put( RISC.Push, LNK, SP, 4 );    (* return address *)
      Put( RISC.Push, FP, SP, 4 );    (* dynamic link *)
      Put( RISC.Addi, FP, SP, 0 );  
      IF varspace > 0 THEN 
         Put( RISC.Subi, SP, SP, varspace ) (* loc. variables *)
      END  
    END  
  END Prologue;  

  PROCEDURE Epilogue*( parspace: INTEGER );  
  BEGIN 
    IF currLevel = 0 THEN  
      Put( RISC.Pop, LNK, SP, 4 );  
      Put( RISC.Ret, 0, 0, LNK )  
    ELSE  
      Put( RISC.Addi, SP, FP, 0 );    
      Put( RISC.Pop, FP, SP, 4 );  
      Put( RISC.Pop, LNK, SP, 4 + parspace );   (* dyn. link + parameter space *)
      Put( RISC.Ret, 0, 0, LNK ) 
    END  
  END Epilogue;  

  PROCEDURE Push*( x: Item;  size: INTEGER );  
  BEGIN 
    IF x.mode # Reg THEN  Load( x )  END;  
    Put( RISC.Push, x.r, SP, size );  RetReg( x.r ) 
  END Push;  

  PROCEDURE Check*( VAR x: Item;  y: INTEGER );   (* check if x.r is in the range 0..y, else abort *)
  BEGIN  
    IF x.mode # Reg THEN  Load( x )  END; 
    Put( RISC.Chki, x.r, 0, y );  
  END Check;  

  PROCEDURE Mult*( VAR x: Item; y: Item );   (* x := x * y *)
  BEGIN  PutOp( RISC.Mul, x, y );  
  END Mult;  
  
  PROCEDURE Multi*( VAR x: Item; y: INTEGER );   (* x := x * y *)
  BEGIN  
    IF x.mode # Reg THEN  Load( x )  END; 
    Put( RISC.Muli, x.r, x.r, y );  
  END Multi;  

  PROCEDURE Div*( VAR x: Item; y: Item );   (* x := x / y *)
  BEGIN  PutOp( RISC.Div, x, y );  
  END Div;  

  PROCEDURE Add*( VAR x: Item; y: Item );   (* x := x + y *)
  BEGIN  PutOp( RISC.Add, x, y );  
  END Add;  

  PROCEDURE Sub*( VAR x: Item; y: Item );   (* x := x - y *)
  BEGIN  PutOp( RISC.Sub, x, y );  
  END Sub;  

  PROCEDURE LAnd*( VAR x: Item; y: Item );   (* x := x & y *)
  BEGIN  PutOp( RISC.And, x, y );  
  END LAnd;  
  
  PROCEDURE LAndi*( VAR x: Item; y: INTEGER );   (* x := x & y *)
  BEGIN  
    IF x.mode # Reg THEN  Load( x )  END; 
    Put( RISC.Andi, x.r, x.r, y );  
  END LAndi;  

  PROCEDURE LOr*( VAR x: Item; y: Item );   (* x := x or y *)
  BEGIN  PutOp( RISC.Or, x, y );  
  END LOr;  
  
  
  
  PROCEDURE Negate*( VAR x: Item );   (* x :=  -x *)
  BEGIN 
    IF x.mode = Const THEN
      x.off := -x.off
    ELSE
      IF x.mode # Reg THEN  Load( x )  END;  
      Put( RISC.Sub, x.r, 0, x.r ) 
    END
  END Negate;  
  
  PROCEDURE Odd*( VAR x: Item );  (* x := ODD( x ) *)
  BEGIN
    IF x.mode = Const THEN  
      x.off := x.off MOD 2
    ELSE  
      LAndi( x, 1 )
    END;   
    x := ToCondition( x )
  END Odd;
  

  PROCEDURE ReadInteger*( ): Item;  
  VAR x: Item;
  BEGIN 
    NEW( x );
    x.r := GetReg( );
    Put( RISC.Sys, 3, x.r, 0 );
    x.mode := Reg;  x.type := O.integer;
    RETURN x
  END ReadInteger;  

  PROCEDURE WriteInteger*( x: Item );  
  BEGIN 
    IF x.mode # Reg THEN  Load( x )  END;  
    Put( RISC.Sys, 4, x.r, 0 );  RetReg( x.r ) 
  END WriteInteger;  
  
  PROCEDURE WriteCharacter*( x: Item );  
  BEGIN 
    IF x.mode # Reg THEN  Load( x )  END;  
    Put( RISC.Sys, 2, x.r, 0 );  RetReg( x.r ) 
  END WriteCharacter;  

  PROCEDURE WriteString*( x: Item );  
  VAR r: Register;  
  BEGIN 
    LoadAddr( x );  r := GetReg( );
    (* Loop *)
    Put( RISC.Ldb, r, x.r, 0 );
    Put( RISC.Beq, r, 0, +4 );
    Put( RISC.Sys, 2, r, 0 );
    Put( RISC.Addi, x.r, x.r, 1 );
    Put( RISC.Beq, 0, 0, -4 );

    RetReg( x.r );  RetReg( r );  
  END WriteString;  

  
  PROCEDURE Initialize-;  
  BEGIN 
    pc := 0;  pcc := 0;  rel := 0;  
    usedRegs := Reserved;
    currLevel := -1;  
  END Initialize;  


  
  (** fix references to constants and global variables and write codefile *)
  PROCEDURE WriteCodefile*;  
  VAR i, k, top, base: INTEGER;  
    f: Files.File;  w: Files.Writer;
    varwords: INTEGER; (* variable space in words *)
  BEGIN 
    varwords := varspace DIV 4;     
    (* clear global variable space *)
    FOR i := 0 TO varwords - 1 DO  code[pc + i] := 0  END;
    
    (* append constants to code *) 
    top := pc + varwords;
    FOR i := 0 TO pcc - 1 DO code[top + i] := constants[i]  END;
    
    (* relocate: fix references to global variables and constants *)
    base := top*4;
    FOR i := 0 TO rel - 1 DO
      k := reloc[i];  code[k] := (code[k] DIV 10000H*10000H) + (code[k] + base) MOD 10000H 
    END;  
  
    f := Files.New( "RISC.code" );  Files.OpenWriter( w, f, 0 );
    FOR i := 0 TO 31 DO  w.Char( G.programName[i] )  END;
    w.RawLInt( pc );  w.RawLInt( varwords + pcc ); w.RawLInt( entry );
    FOR i := 0 TO pc + varwords + pcc DO  w.RawLInt( code[i] )  END;
    w.Update;  Files.Register( f )
  END WriteCodefile;  


END PL1CodeGenerator.