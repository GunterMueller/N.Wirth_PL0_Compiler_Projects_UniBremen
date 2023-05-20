MODULE PL3;   (* g.f.  21.3.03  *)


IMPORT Streams, Commands, Files,
  G := PL3Global, Parser := PL3Parser,
  Blocks := PL3Blocks, CG := PL3CodeGenerator; 

  
  PROCEDURE Error( c: Commands.Context; CONST msg: ARRAY OF CHAR );
  BEGIN
    c.out.Update;
    c.error.String( msg );  c.error.Ln;  
    c.error.Update
  END Error;



  PROCEDURE OpenSource( c: Commands.Context ): Streams.Reader;  
  (* open file and handle flags *)
  VAR 
    filename: ARRAY 32 OF CHAR;
    f: Files.File; r: Files.Reader;
  BEGIN 
    G.traceParser := FALSE;  
    G.traceAnalyser := FALSE;
    G.traceCode := FALSE;  
    REPEAT
      IF c.arg.GetString( filename ) THEN
        IF filename[0] = '-' THEN
          CASE filename[1] OF
          |'p':  G.traceParser := TRUE
          |'a':  G.traceAnalyser := TRUE
          |'c':  G.traceCode := TRUE
          ELSE
          END
        END
      ELSE
        Error( c, "filename missing" );  RETURN NIL
      END
    UNTIL filename[0] # '-';
    c.out.String( "PL3.Compile " );   c.out.String( filename);  c.out.Ln;
    f := Files.Old( filename );
    IF f # NIL THEN
      Files.OpenReader( r, f, 0 ); 
      RETURN r
    ELSE
      Error( c, "file not found" )
    END;
    RETURN NIL
  END OpenSource;  


  PROCEDURE Compile*( c: Commands.Context );  
  VAR 
    source: Streams.Reader;
    tree: Blocks.BlockNode;
  BEGIN 
    G.Initialize( c );
    source := OpenSource( c );
    IF source # NIL THEN        
      c.out.String( "--- Syntax Analysis" );  c.out.Ln; c.out.Update;
      tree := Parser.Parse( source );  
      IF G.errors = 0 THEN  
        c.out.String( "--- Semantic Analysis" );   c.out.Ln;  c.out.Update;
        tree.Analyse;
        IF G.errors = 0 THEN  
          c.out.String( "--- Code Generation" );   c.out.Ln;  c.out.Update;
          CG.Initialize;
          tree.Synthesize;
          IF G.errors = 0 THEN  
            CG.WriteCodefile 
          END
        END 
      END 
    END;  
  END Compile;  
  
END PL3.

