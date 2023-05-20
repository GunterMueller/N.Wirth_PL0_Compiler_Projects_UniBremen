MODULE RISCDecoder; (* GF *)

IMPORT RISC, Streams;


VAR
  mnemo: ARRAY 56 OF ARRAY 5 OF CHAR;   (* assembler mnemos *)


  PROCEDURE DecodeInstruction*( waddr, instr: INTEGER; out: Streams.Writer );  
  VAR op, a, b, c: INTEGER;  

    PROCEDURE Reg( r: INTEGER );  
    BEGIN 
      CASE r OF 
      | 0:    out.Char( '0' )       
      | 1..28:   
          out.String( 'r' );  out.Int( r, 1 ) 
      | 29:  out.String( 'fp' ) 
      | 30:  out.String( 'sp' ) 
      | 31:  out.String( 'lnk' ) 
      ELSE out.Int( r, 2 ) 
      END  
    END Reg;  

  BEGIN 
    
    out.Int( waddr*4, 4 );  out.Char( ':' );  out.Char( 9X );  
    out.Hex( instr, -8 );  out.Char( 9X );  out.Char( 9X );
    
    op := instr DIV 4000000H MOD 40H;  
    out.String( mnemo[op] );  out.Char( 9X );  
    
    a := instr DIV 200000H MOD 20H;
    b := instr DIV 10000H MOD 20H;
    c := instr MOD 10000H;  
    IF c >= 8000H THEN  DEC( c, 10000H )  END;  (* sign extension *)
    
    IF op < RISC.Bsr THEN  Reg( a )  END;
    IF (op >= RISC.Addi) & (op <= RISC.Chki) THEN
      out.Char( ',' );  Reg( b );  out.Char( ',' );  out.Int( c, 0 )
    ELSIF (op >= RISC.Ldw) & (op <= RISC.Push) THEN
      out.Char( ',' );    
      IF b # 0 THEN  
        out.Int( c, 0 );  out.Char( '(' );  Reg( b );  out.Char( ')' )  
      ELSE
        out.Char( '#' ); out.Int( c, 0 )
      END
    ELSIF op = RISC.Bsr THEN  
      out.Char( "#" ); out.Int( (waddr + c)*4, 0 )
    ELSIF op = RISC.Jsr THEN  out.Int( instr MOD 4000000H, 0 )
    ELSIF op = RISC.Ret THEN  Reg( c )
    ELSIF op = RISC.Sys THEN
      out.Int( a, 0 ); out.Char( ',' );  Reg( b )
    ELSIF (op >= RISC.Beq) & (op <= RISC.Bgt) THEN
      out.Char( ',' );  Reg( b );  out.Char( ',' );  
      out.Char( "#" );  out.Int( (waddr + c)*4, 0 )
    ELSE
      out.Char( ',' );  Reg( b );  out.Char( ',' );  Reg( c )
    END;
    out.Ln;  out.Update
  END DecodeInstruction;  


BEGIN 
  mnemo[RISC.Add] := "add ";    mnemo[RISC.Sub] := "sub ";  
  mnemo[RISC.Mul] := "mul ";    mnemo[RISC.Div] := "div ";  
  mnemo[RISC.Mod] := "mod ";    mnemo[RISC.Cmp] := "cmp ";  
  mnemo[RISC.Or] := "or  ";    mnemo[RISC.And] := "and ";  
  mnemo[RISC.Bic] := "bic ";    mnemo[RISC.Xor] := "xor ";  
  mnemo[RISC.LSh] := "lsh ";    mnemo[RISC.ASh] := "ash ";  
  mnemo[RISC.Chk] := "chk ";    mnemo[RISC.Addi] := "addi";  
  mnemo[RISC.Subi] := "subi";    mnemo[RISC.Muli] := "muli";  
  mnemo[RISC.Divi]  := "divi";  mnemo[RISC.Modi] := "modi";  
  mnemo[RISC.Cmpi] := "cmpi";  mnemo[RISC.Ori] := "ori ";  
  mnemo[RISC.Andi] := "andi";    mnemo[RISC.Bici] := "bici";  
  mnemo[RISC.Xori] := "xori";    mnemo[RISC.LShi] := "shli";  
  mnemo[RISC.AShi]  := "shai";  mnemo[RISC.Chki] := "chki";  
  mnemo[RISC.Ldw] := "ldw ";    mnemo[RISC.Ldb] := "ldb ";  
  mnemo[RISC.Pop] := "pop ";    mnemo[RISC.Stw] := "stw ";  
  mnemo[RISC.Stb] := "stb ";    mnemo[RISC.Push] := "psh ";  
  mnemo[RISC.Beq] := "beq ";    mnemo[RISC.Bne] := "bne ";  
  mnemo[RISC.Blt] := "blt ";    mnemo[RISC.Bge] := "bge ";  
  mnemo[RISC.Ble] := "ble ";    mnemo[RISC.Bgt] := "bgt ";  
  mnemo[RISC.Bsr] := "bsr ";    mnemo[RISC.Jsr] := "jsr ";  
  mnemo[RISC.Ret]  := "ret ";  mnemo[RISC.Sys] := "sys "
END RISCDecoder.
