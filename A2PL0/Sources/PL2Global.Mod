MODULE PL2Global;   (* GF   9.12.04  *)

IMPORT WMUtilities, Strings, Commands;  

CONST
  MaxNestingLevel* = 4;  (* procedure nesting *)
  
TYPE
  (* types needed in most modules *)
  Textpos* = INTEGER;    (* position in source text *)
  Symbol* = INTEGER;    (* symbol numbers *)
  Identifier* = INTEGER;  (* identifier number *)
  String* = POINTER TO ARRAY OF CHAR;
  
VAR 
  programName*: ARRAY 32 OF CHAR;
  traceParser*, traceAnalyser*, traceCode*: BOOLEAN;   (*  compiler options  *)
  
  context: Commands.Context;
  errors-: INTEGER;  
  

  (* -------------------- error messages --------------------------- *)
VAR 
  lastErrorPos: INTEGER;  
  pw-, aw-, cw-: WMUtilities.WindowWriter;
  

  
  PROCEDURE Error*( CONST msg: ARRAY OF CHAR;  p: INTEGER );  
  BEGIN 
    INC( errors );  
    IF ABS( p - lastErrorPos ) < 8 THEN  
      (* avoid multiple messages for a single position *) RETURN   
    END;  
    
    lastErrorPos := p;  
    context.out.Update;
    context.error.String( "pos " );  context.error.Int( p, 0 );  
    context.error.String( ":   " );  context.error.String( msg );  
    context.error.Ln;  context.error.Update
  END Error;  
  
  PROCEDURE FatalError*( CONST msg: ARRAY OF CHAR );
  BEGIN
    context.out.Update;
    context.error.String( msg );  context.error.Ln;  context.error.Update;
    HALT( 99 )
  END FatalError;


(* --------------------- Compiler tracing --------------------------- *)


  PROCEDURE TraceParser*( pos, sym: INTEGER;  CONST msg: ARRAY OF CHAR );  
  VAR title: ARRAY 64 OF CHAR;
  BEGIN 
    IF traceParser THEN 
      IF pw = NIL THEN
        title := "Parser trace: ";  Strings.Append( title, programName );
        NEW( pw, title, 400, 600, FALSE );
      END;
      pw.String( "pos = " );  pw.Int( pos, 0 ); 
      pw.String( ", sym = " ); pw.Int( sym, 0 );  
      pw.String( " :     " );  pw.String( msg );
      pw.Ln;
      pw.Update
    END 
  END TraceParser;  

  PROCEDURE TraceAnalysis*( level: INTEGER;  CONST msg: ARRAY OF CHAR );  
  VAR i: INTEGER;  title: ARRAY 64 OF CHAR;
  BEGIN 
    IF traceAnalyser THEN  
      IF aw = NIL THEN
        title := "Analyser trace: ";  Strings.Append( title, programName );
        NEW( aw, title, 400, 600, FALSE );
      END;
      FOR i := 1 TO level DO  aw.String( "        " )  END;  
      aw.String( msg );  aw.Ln;
      aw.Update
    END  
  END TraceAnalysis;  
  
  PROCEDURE TraceSynthesis*( CONST msg: ARRAY OF CHAR );
  VAR title: ARRAY 64 OF CHAR;
  BEGIN
    IF traceCode THEN
      IF cw = NIL THEN
        title := "Code generator trace: ";  Strings.Append( title, programName );
        NEW( cw, title, 400, 600, FALSE );
        cw.SetFontName( "Courier" );
      END;
      cw.String( msg );  cw.Ln;
      cw.Update
    END
  END TraceSynthesis;
  


(* ---------------------------------*)

  PROCEDURE Initialize-( c: Commands.Context );  
  BEGIN 
    context := c;
    errors := 0;  lastErrorPos := -10;  
    pw :=NIL; aw := NIL; cw := NIL
  END Initialize;  

END PL2Global.