MODULE PL5Statements;   (* g.f.  9.12.04 *)

IMPORT G := PL5Global,
    OT := PL5ObjectTable, O := PL5Objects, 
    CG := PL5CodeGenerator,
    N := PL5Nodes, D := PL5Denotations, T := PL5Types, E := PL5Expressions;  

TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos;  
  
  Item = CG.Item;  Link = CG.Link;

  ExprNode = N.ExprNode;  StmtNode = N.StmtNode;  DenotationNode = D.DenotationNode;  

  Object = OT.Object;  ArrayType = O.ArrayType;  
  Variable = O.Variable;  Procedure = O.Procedure;  Parameter = O.Parameter;  

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
            ELSIF ~T.SameType( target.type, source.type ) THEN  
              G.Error( "type missmatch", position )
            END  
          END 
        END Analyse;  

        PROCEDURE Synthesize;  
        VAR src, dest: Item;  
        BEGIN 
          G.TraceSynthesis( 'assign' );  
          src := source.Synthesize( );  
          dest := target.Synthesize( );  
          IF dest.type.size IN {1, 4} THEN  
            CG.Store( dest, src )  
          ELSE  
            CG.Copy( dest, src )  
          END  
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
      actpar: ExprNode;  (* list of actual parameters *)
       
      
      PROCEDURE CheckActuals;  
      VAR po: Object;  fp: Parameter;  ap, last: ExprNode;  
      BEGIN 
        TraceAnalysis( 'check parameters' );  
        fp := proc.params;  ap := actpar;  last := NIL;
        WHILE fp # NIL DO  
          IF ap = NIL THEN  
            G.Error( "parameter missing", position );  RETURN 
          END;  
          IF fp.refpar THEN  
            (* call by reference *)
            IF ~(ap IS DenotationNode) THEN  
              G.Error( "variable expected", ap.position );  RETURN   
            END;  
            WITH ap: DenotationNode DO 
              ap.Analyse;  
              po := OT.FindDecl( ap.id );  
              IF ~(po IS Variable) THEN
                G.Error( "variable expected", ap.position )
              END;  
              IF ~T.SameType( ap.type, fp.type ) THEN  
                G.Error( "wrong parameter type", ap.position )
              END  
            END  
          ELSE  
            (* call by value *)
            ap.Analyse;  
            IF ~T.SameType( ap.type, fp.type ) THEN
              G.Error( "wrong parameter type", ap.position )
            END;  
            E.SimplifyConstParts( ap )
          END;  
          IF last = NIL THEN  actpar := ap  ELSE  last.next := ap  END;
          last := ap;
          
          fp := fp.next;  
          IF ap.next # NIL THEN  ap := ap.next( ExprNode )  ELSE  ap := NIL   END;
        END;  
        IF ap # NIL THEN  G.Error( "too many parameters", position )  END  
      END CheckActuals;  

      PROCEDURE Analyse;  
      VAR o: Object;  
      BEGIN 
        TraceAnalysis( 'procedure call' );  
        o := OT.FindDecl( procId );  
        IF o = NIL THEN  
          G.Error( "undeclared identifier", position )  
        ELSE  
          IF o IS Procedure THEN  
            proc := o( Procedure );  CheckActuals  
          ELSE  
            G.Error( "is not a procedure", position )  
          END  
        END  
      END Analyse;  

      PROCEDURE PushActuals;  
      (* push actual parameters onto stack *)
      VAR fp: Parameter;  p: ExprNode;  x: Item;  size: INTEGER;  
      BEGIN 
        fp := proc.params;  p := actpar;  
        WHILE p # NIL DO  
          G.TraceSynthesis( 'push parameter' );
          x := p.Synthesize( );  
          IF fp.refpar THEN  
            CG.LoadAddr( x );  size := 4
          ELSE  (* call by value *)
            IF fp.type IS ArrayType THEN  
              CG.LoadAddr( x );
              size := fp.type.size  
            ELSE  
              size := 4  
            END  
          END;  
          CG.Push( x, size );  fp := fp.next;  
          IF p.next # NIL THEN  p := p.next( ExprNode )  ELSE  p := NIL   END  
        END;  
      END PushActuals;  

      PROCEDURE Synthesize;  
      BEGIN 
        G.TraceSynthesis( 'procedure call' ); 
        PushActuals;   
        CG.Call( proc );  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  nam: Identifier;  par: ExprNode );  
      BEGIN 
        position := pos;  procId := nam;  actpar := par 
      END Init;  

  END CallStmtNode;  
      
      
  StmtListNode* = OBJECT (StmtNode)
    VAR 
      stmtList: StmtNode;
    
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
        stmtList := stmts;
        next := NIL
      END Init;
  
  END StmtListNode;
  
  
  IfStmtNode* = OBJECT (StmtNode)
    VAR 
      expr: ExprNode;  
      truePart: StmtNode;  
      falsePart: StmtNode;  
      
      PROCEDURE Analyse;  
      BEGIN 
        TraceAnalysis( 'if' );  
        expr.Analyse;  
        IF expr.type # O.boolean THEN  
          G.Error( "boolean expected", position )  
        END;  
        truePart.Analyse;  
        IF falsePart # NIL THEN  falsePart.Analyse  END
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR l: Link;  x: Item;
      BEGIN 
        G.TraceSynthesis( 'if' );  
        x := CG.ToCondition( expr.Synthesize( ) ); 
        CG.FixLink( x.true );
        truePart.Synthesize;  
        IF falsePart # NIL THEN  
          l := CG.JumpForw( );  
          CG.FixLink( x.false );  
          falsePart.Synthesize;  
          CG.FixLink( l )  
        ELSE  
          CG.FixLink( x.false ) 
        END  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  cond: ExprNode;  thenp, elsep: StmtNode );  
      BEGIN 
        position := pos;  expr := cond;  truePart := thenp;  falsePart := elsep 
      END Init;  

  END IfStmtNode;  
  
  
  WhileStmtNode* = OBJECT (StmtNode)
    VAR 
      expr: ExprNode;  
      stmts: StmtNode;  
      
      PROCEDURE Analyse;  
      BEGIN 
        TraceAnalysis( 'while' );  
        expr.Analyse;  
        IF ~T.Boolean( expr.type ) THEN
          G.Error( "boolean value expected", position )
        END;  
        stmts.Analyse
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR start: Link;  x: Item;
      BEGIN 
        G.TraceSynthesis( 'while' );  
        start := CG.pc;  
        x := CG.ToCondition( expr.Synthesize( ) ); 
        CG.FixLink( x.true );
        stmts.Synthesize;  
        CG.JumpBackw( start );  
        CG.FixLink( x.false );  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  cond: ExprNode;  stmt: StmtNode );  
      BEGIN 
        position := pos;  expr := cond;  stmts := stmt 
      END Init;  

  END WhileStmtNode;
  
  
  WriteStmtNode* = OBJECT (StmtNode)
    VAR 
      source: ExprNode;  
      
      PROCEDURE Analyse;  
      BEGIN 
        TraceAnalysis( 'write' );  
        source.Analyse;  
        IF T.Integer( source.type ) THEN
          E.SimplifyConstParts( source )
        ELSIF ~T.String( source.type ) & ~T.Char( source.type ) THEN  
          G.Error( "illegal type of operand", source.position )
        END;  
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR x: Item;  
      BEGIN 
        G.TraceSynthesis( 'write' );  
        x := source.Synthesize( );  
        IF x.type = O.string THEN  
          CG.WriteString( x )  
        ELSIF x.type = O.character THEN
          CG.WriteCharacter( x )  
        ELSE
          CG.WriteInteger( x )
        END;
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
        target.Analyse;  obj := OT.FindDecl( target.id );  
        IF ~(obj IS Variable) THEN
          G.Error( "variable expected", position )
        ELSIF ~T.Integer( target.type ) THEN  
          G.Error( "integer operand expected", position )  
        END  
      END Analyse;  

      PROCEDURE Synthesize;  
      VAR 
        src, dest: Item;  
      BEGIN 
        G.TraceSynthesis( 'read' );  
        src := CG.ReadInteger( );  dest := target.Synthesize( );  
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

END PL5Statements.