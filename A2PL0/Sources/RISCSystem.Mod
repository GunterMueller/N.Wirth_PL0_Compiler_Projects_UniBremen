MODULE RISCSystem;  (* GF *)

IMPORT RISC, D :=RISCDecoder,
  Commands, Strings, Files, WMUtilities;  

CONST
  CodeFileName = "RISC.code";

VAR 
  context: Commands.Context;  
  
  programName: ARRAY 32 OF CHAR;
  started: BOOLEAN;  
  entryAddress: INTEGER;
  
  
  PROCEDURE Error( CONST str: ARRAY OF CHAR );
  VAR c: Commands.Context;
  BEGIN
    c := Commands.GetContext();
    c.out.Update;
    c.error.String( str );  c.error.Ln;  
    c.error.Update
  END Error;


  (** decode compiled program  *)
  PROCEDURE Decode*( c: Commands.Context );
  VAR i, instr: INTEGER;  
    title, programName: ARRAY 64 OF CHAR;
    win: WMUtilities.WindowWriter;
    codesize, constsize, entry: INTEGER;
    f: Files.File; r: Files.Reader;
  BEGIN 
    context := c;
    f := Files.Old( CodeFileName );
    IF f = NIL THEN
      Error( "Code file notfound" )
    ELSE
      Files.OpenReader( r, f, 0 );
      FOR i := 0 TO 31 DO  r.Char( programName[i] )  END;
      r.RawLInt( codesize );  r.RawLInt( constsize );  r.RawLInt( entry );
      title := "Code: ";  Strings.Append( title, programName );
      NEW( win, title, 400, 600, FALSE );
      win.SetFontName( "Courier" );
      win.String( "entry:" );  win.Int( entry*4, 6 );  win.Ln;  win.Ln; 
      FOR i := 0 TO codesize - 1 DO
        r.RawLInt( instr );
        D.DecodeInstruction( i, instr, win );
        IF instr DIV 4000000H MOD 40H = RISC.Ret THEN  win.Ln  END;  
      END;  
      FOR i := 0 TO constsize - 1 DO
        r.RawLInt( instr );
        IF i MOD 4 = 0 THEN  
          win.Ln;  win.Int( 4*i + 4*codesize, 4 ); win.Char(':' );   win.Char( 9X )  
        END;  
        win.Hex( instr, -8 );  win.Char( ' ' )
      END;  
      win.Ln;  win.Update  
    END
  END Decode;  
  
  
  (* Load generated code into RISC memory*)
  PROCEDURE Load(): BOOLEAN;
  VAR 
    i: INTEGER;  
    codesize, constsize, entry: INTEGER;
    f: Files.File; r: Files.Reader;
  BEGIN 
    started := FALSE;
    f := Files.Old( CodeFileName );
    IF f = NIL THEN
      Error( "Code file not found" );
      RETURN FALSE
    ELSE
      Files.OpenReader( r, f, 0 );
      FOR i := 0 TO 31 DO  r.Char( programName[i] )  END;
      r.RawLInt( codesize );  r.RawLInt( constsize );  r.RawLInt( entry );
      FOR i := 0 TO codesize + constsize - 1 DO
        r.RawLInt( RISC.mem[i] );  
      END;  
      entryAddress := 4*entry;
      RETURN TRUE
    END
  END Load;  
  
  
  PROCEDURE Execute*( c: Commands.Context );
  BEGIN
    context := c;
    IF Load() THEN
      c.out.String( "Executing " ); c.out.String( programName );  c.out.Ln;  c.out.Update;
      RISC.PC := entryAddress DIV 4;
      started := TRUE;
      Exec( FALSE )
    END
  END Execute;
  
  
  PROCEDURE SystemCall( op, reg: INTEGER );
  (*
    op = 1: read a character, return it in reg
    op = 2: write the character value of reg
    op = 3: read an integer, return it in reg
    op = 4: write the integer value of reg
  *)
  CONST LF = 0AX;  
  VAR ch: CHAR; 
  BEGIN
    CASE op OF
    | 1:
      context.arg.Char( ch );
      IF ch > 0X THEN  RISC.R[reg] := ORD( ch )
      ELSE  Error( "input end reached")
      END
    | 2:  
      ch := CHR( RISC.R[reg] );
      IF ch = LF THEN
        context.out.Ln
      ELSE
        context.out.Char( ch )
      END
    | 3:  
      IF ~context.arg.GetInteger( RISC.R[reg], FALSE ) THEN
        Error( "not a number" )
      END
    | 4:  
      context.out.Char( ' ' );
      context.out.Int( RISC.R[reg], 0 )
    END;
    context.out.Update
  END SystemCall;
    
  
  PROCEDURE Exec( singlestep: BOOLEAN );  
  BEGIN 
    IF started THEN  
      RISC.exec( singlestep );
      context.out.Ln;
      CASE RISC.PSR OF
      | RISC.Terminated:
        context.out.String( "Execution teminated"); context.out.Ln;
        context.out.Update;
        started := FALSE
      | RISC.Stopped:
        context.out.String( "Program stopped at "); context.out.Int( RISC.PC*4, 0 );
        context.out.Ln;
        State;
      | RISC.Trapped:
        context.out.String( "Program trapped"); context.out.Ln;
        State;
        context.out.Update
      END
    ELSE  
      Error( "Execution has not been started" )
    END 
  END Exec;  
  
  
  
  (*----------------------------- debug tools  ----------------------------------*)
  
  
  PROCEDURE SetBreakpoint*( c: Commands.Context );  (* addr *)
  VAR addr: INTEGER;
  BEGIN  
    IF c.arg.GetInteger( addr, FALSE ) THEN 
      RISC.breakpoint := addr DIV 4;  
      c.out.String( "Breakpoint set to " );  c.out.Int( addr, 8 );  c.out.Ln; 
    ELSE  
      Error( "Program argument is not an interger value" )
    END 
  END SetBreakpoint;  
  
  
  PROCEDURE Step*;  (* execute a single instruction *)
  BEGIN  
    Exec( TRUE )
  END Step;  
  
  PROCEDURE Continue*;  
  BEGIN 
    Exec( FALSE );
  END Continue;  
  
  PROCEDURE Break*;  (* interrupt execution of possible endless loop*)
  BEGIN
    RISC.interrupt := TRUE
  END Break;


  PROCEDURE ShowMem*( c: Commands.Context );    (* addr  words*)
  VAR start, end, i: INTEGER;  
  BEGIN  
    IF c.arg.GetInteger( i, FALSE ) THEN
      start := i DIV 4;  
      IF c.arg.GetInteger( i, FALSE ) THEN  
        end := start + i;  i := start;  
        WHILE (i < end) & (i < RISC.MemSize DIV 4) DO 
          IF (i - start) MOD 4 = 0 THEN  
            c.out.Ln;  c.out.Int( i*4, 5 );  c.out.Char( ':' )  
          END;  
          c.out.String( '  ' ); c.out.Hex( RISC.mem[i], -8 );
          INC( i )
        END;  
        c.out.Ln
      END
    END 
  END ShowMem;
  
  
  PROCEDURE State;
  VAR i: INTEGER;
  BEGIN 
    IF started THEN  
      context.out.String( "PC = " );  context.out.Int( RISC.PC*4, 1 );  
        
      context.out.String( ",  FP = " );  context.out.Int( RISC.R[29], 1 );  
      context.out.String( ",  SP = " );  context.out.Int( RISC.R[30], 1 );
      context.out.String( ", LNK = " );  context.out.Int( RISC.R[31], 1 );
      context.out.Ln;
      context.out.String( "R1 .. R28:" ); context.out.Ln;
      FOR i := 1 TO 28 DO
        context.out.Hex( RISC.R[i], -8 );  context.out.Char( ' ' );
        IF i MOD 8 = 0 THEN context.out.Ln END
      END;
      context.out.Ln
    ELSE  
      Error( "Execution has not been started" )
    END
  END State;  
  

BEGIN 
  RISC.syscall := SystemCall;
  RISC.breakpoint := -1;  
  started := FALSE
END RISCSystem.