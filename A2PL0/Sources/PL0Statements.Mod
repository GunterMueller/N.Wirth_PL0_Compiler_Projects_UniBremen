MODULE PL0Statements;   (* g.f.  9.12.04 *)

IMPORT 
  G := PL0Global, OT := PL0ObjectTable, O := PL0Objects, 
  CG := PL0CodeGenerator,
  N := PL0Nodes,  D := PL0Denotations, E := PL0Expressions;  

TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos;  
  
  Item = CG.Item;  Link = CG.Link;

  ExprNode = N.ExprNode;  StmtNode = N.StmtNode;  DenotationNode = D.DenotationNode;  

  Object = OT.Object; 
  Variable = O.Variable;  Procedure = O.Procedure; 

TYPE 
  AssignStmtNode* = OBJECT (StmtNode)
      VAR 
        target: DenotationNode;  
        source: ExprNode;  
        
        PROCEDURE Analyse;  
        VAR obj: Object;  
        BEGIN 
          TraceAnalysis( 'assign' );  
          target.Analyse;  
          E.SimplifyConstParts( source );
          source.Analyse;  
          obj := OT.FindDecl( target.id ); 
          IF obj # NIL THEN
            IF ~(obj IS Variable) THEN  
              G.Error( "is not a variable", position )  
            END;  
          END
        END Analyse;  

        PROCEDURE Synthesize;  
        VAR src, dest: Item;  
        BEGIN 
          G.TraceSynthesis( 'assign' );  
          src := source.Synthesize( );  
          dest := target.Synthesize( );  
          CG.Store( dest, src )  
        END Synthesize;  

        PROCEDURE & Init*( pos: Textpos;  targ: DenotationNode;  src: ExprNode );  
        BEGIN 
          position := pos;  target := targ;  source := src 
        END Init;  

      END AssignStmtNode;  
  
  CallStmtNode* = OBJECT (StmtNode)
    VAR 
      procId: Identifier;  
      proc: Procedure; 
       
      
  
      PROCEDURE Analyse;  
      VAR o: Object;  
      BEGIN 
        TraceAnalysis( 'procedure call' );  
        o := OT.FindDecl( procId );  
        IF o = NIL THEN  
          G.Error( "undeclared identifier", position )  
        ELSE  
          IF o IS Procedure THEN  
            proc := o( Procedure ); 
          ELSE  
            G.Error( "is not a procedure", position )  
          END  
        END  
      END Analyse;  

  
      PROCEDURE Synthesize;  
      BEGIN 
        G.TraceSynthesis( 'procedure call' ); 
        CG.Call( proc );  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  name: Identifier );  
      BEGIN 
        position := pos;  procId := name; 
      END Init;  

  END CallStmtNode;  
      
  StmtListNode* = OBJECT (StmtNode)
    VAR stmtList: StmtNode;
    
    PROCEDURE Analyse;
    VAR curr: StmtNode;
    BEGIN
      curr := stmtList;
      WHILE curr # NIL DO
        curr.Analyse;  curr := curr.next
      END
    END Analyse;
    
    PROCEDURE Synthesize;
    VAR curr: StmtNode;
    BEGIN
      curr := stmtList;
      WHILE curr # NIL DO
        curr.Synthesize;  curr := curr.next
      END
    END Synthesize;
    
    PROCEDURE &Init*( stmts: StmtNode );
    BEGIN
      stmtList := stmts
    END Init;
  
  END StmtListNode;
  
  IfStmtNode* = OBJECT (StmtNode)
    VAR 
      expr: ExprNode;  
      truePart: StmtNode;  
      falsePart: StmtNode;  (* PL0 has no ELSE ! *)
      
      PROCEDURE Analyse;  
      BEGIN 
        TraceAnalysis( 'if' );  
        expr.Analyse;  
        truePart.Analyse;  
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR x: Item;  
      BEGIN 
        G.TraceSynthesis( 'if' );  
        x := CG.ToCondition( expr.Synthesize( ) );  
        truePart.Synthesize;  
        CG.FixLink( x.false ) 
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  cond: ExprNode;  thenp, elsep: StmtNode );  
      BEGIN 
        position := pos;  expr := cond;  truePart := thenp;  falsePart := elsep 
      END Init;  

  END IfStmtNode;  
  
  
  WhileStmtNode* = OBJECT (StmtNode)
    VAR 
      expr: ExprNode;  
      statement: StmtNode;  
      
      PROCEDURE Analyse;  
      BEGIN 
        TraceAnalysis( 'while' );  
        expr.Analyse;  
        statement.Analyse
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR start: Link;  x: Item;  
      BEGIN 
        G.TraceSynthesis( 'while' );  
        start := CG.pc;  
        x := CG.ToCondition( expr.Synthesize( ) );  
        statement.Synthesize;  
        CG.JumpBackw( start );  
        CG.FixLink( x.false );  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  cond: ExprNode;  stmt: StmtNode );  
      BEGIN 
        position := pos;  expr := cond;  statement := stmt 
      END Init;  

  END WhileStmtNode;
  
  
  WriteStmtNode* = OBJECT (StmtNode)
    VAR 
      source: ExprNode;  
      
      PROCEDURE Analyse;  
      BEGIN 
        TraceAnalysis( 'write' );  
        source.Analyse;  
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR x: Item;  
      BEGIN 
        G.TraceSynthesis( 'write' );  
        x := source.Synthesize( );  
        CG.WriteInteger( x )
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  val: ExprNode );  
      BEGIN 
        position := pos;  source := val 
      END Init;  

  END WriteStmtNode;  
  
  ReadStmtNode* = OBJECT (StmtNode)
    VAR 
      target: DenotationNode;  
      
      PROCEDURE Analyse;  
      VAR obj: Object;  
      BEGIN 
        TraceAnalysis( 'read' );  
        IF target IS DenotationNode THEN  
          target.Analyse;  obj := OT.FindDecl( target.id );  
          IF (obj = NIL) OR ~(obj IS Variable) THEN  
            G.Error( "variable expected", position )  
          END;  
        ELSE  
          G.Error( "identifier expected", position ) 
        END  
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR 
        src, dest: Item;  
      BEGIN 
        G.TraceSynthesis( 'read' );  
        src := CG.ReadInteger( );  
        dest := target.Synthesize( );  
        CG.Store( dest, src ) 
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  targ: DenotationNode );  
      BEGIN 
        position := pos;  target := targ 
      END Init;  

  END ReadStmtNode;  
  
  
  PROCEDURE TraceAnalysis( mess: ARRAY OF CHAR );  
  BEGIN 
    G.TraceAnalysis( OT.curlev, mess );  
  END TraceAnalysis;  

END PL0Statements.