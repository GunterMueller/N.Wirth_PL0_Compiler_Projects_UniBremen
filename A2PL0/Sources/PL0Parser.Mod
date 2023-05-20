MODULE PL0Parser;   (* g.f.  21.3.03  *)

IMPORT Streams,
  G := PL0Global, IT := PL0IdentifierTable, S := PL0Scanner, O := PL0Objects,
  N := PL0Nodes, 
  B := PL0Blocks, V := PL0Variables, 
  E := PL0Expressions, St := PL0Statements, 
  C := PL0Constants,  D := PL0Denotations,
  P := PL0Procedures;

CONST
  MissingIdent = "identifier expected"
  
TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos;  
  
  DeclNode = N.DeclNode;  
  ExprNode = N.ExprNode;  
  StmtNode = N.StmtNode;  
  
  ConstantNode = C.ConstantNode;
  
  BlockNode = B.BlockNode;
  
  DenotationNode = D.DenotationNode;
  VarDeclNode = V.VarDeclNode;
  MonadicExprNode = E.MonadicExprNode;
  DyadicExprNode = E.DyadicExprNode;
  
  ProcDeclNode = P.ProcDeclNode;

VAR 
  sym: S.Symbol;  (* current symbol *)
  idNum: Identifier;
  

  PROCEDURE trace( msg: ARRAY OF CHAR );  
  BEGIN 
    IF G.traceParser THEN 
      G.TraceParser( S.pos, sym, msg )
    END 
  END trace;  

  PROCEDURE GetSym;
  BEGIN  
    S.Get( sym);
    IF sym = S.Ident THEN  idNum := S.value  END
  END GetSym;

  
  
  PROCEDURE ErrorAndSkip( CONST msg: ARRAY OF CHAR;  fsym: INTEGER );  
  BEGIN 
    G.Error( msg, S.pos );  
    WHILE sym < fsym DO  GetSym  END;
    IF sym = S.Eof THEN  G.Error( "unexpected end of input", S.pos )  END 
  END ErrorAndSkip;  
  
  PROCEDURE Factor( ): ExprNode;  
  VAR   
    const: ConstantNode;  expr: ExprNode;  me: MonadicExprNode;
    Id: Identifier;  num: INTEGER;  pos: Textpos;
  BEGIN 
    trace( "Factor" );  
    CASE sym OF 
      S.Ident: 
        Id := idNum;  pos := S.pos;  GetSym;  
        expr := Denotation( Id, pos, FALSE )
    | S.Number: 
        num := INTEGER(S.value);  GetSym;
        NEW( const, S.pos, O.integer, num );  expr := const
    | S.LParen: 
        GetSym;  
        expr := Expression();  
        IF sym = S.RParen THEN  
          GetSym;
        ELSE  
          G.Error( "')' expected", S.pos ); expr := NIL  
        END 
    | S.Odd: 
        GetSym;  
        NEW( me, S.pos, S.Odd, Expression() );  expr := me
    ELSE 
      G.Error( "expression expected", S.pos );  
      expr := NIL
    END;  
    RETURN expr
  END Factor;  
  

  PROCEDURE Term( ): ExprNode;  
  VAR expr: ExprNode;  opr: INTEGER;  de: DyadicExprNode;
  BEGIN 
    trace( "Term" );  
    expr := Factor();  
    WHILE (sym = S.Times) OR (sym = S.Div) DO 
      opr := sym;  GetSym;  
      NEW( de, S.pos, opr, expr, Factor() );  expr := de;  
    END;  
    RETURN expr
  END Term;  
  

  PROCEDURE Expression( ): ExprNode;  
  VAR expr: ExprNode;  op: INTEGER;  me: MonadicExprNode;  de: DyadicExprNode;
  BEGIN 
    trace( "Expression" );  
    IF sym = S.Minus THEN  
      GetSym; 
      NEW( me, S.pos, S.Minus, Term() );  expr := me
    ELSIF sym = S.Plus THEN  
      GetSym;  
      expr := Term();  
    ELSE  
      expr := Term();  
    END;  
    WHILE (sym = S.Plus) OR (sym = S.Minus) DO 
      op := sym;  GetSym;  
      NEW( de, S.pos, op, expr, Term() );  expr := de
    END;  
    RETURN expr
  END Expression;  
  

  PROCEDURE Condition( ): ExprNode;  
  VAR expr: ExprNode;  op: INTEGER;  de: DyadicExprNode;
  BEGIN 
    trace( "Condition" );  
    expr := Expression();  
    IF (sym >= S.EQ) & (sym <= S.GE) THEN  
      op := sym;  GetSym;  
      NEW( de, S.pos, op, expr, Expression() );  RETURN de
    ELSE  
      RETURN expr
    END
  END Condition;  

  PROCEDURE Denotation( id: Identifier; pos: Textpos; writeAccess: BOOLEAN ): DenotationNode;  
  VAR acc: DenotationNode;  
  BEGIN 
    trace( "Denotation" );  
    NEW( acc, pos, id, writeAccess );  RETURN acc
  END Denotation;  
  

  PROCEDURE Assign( id: Identifier;  pos: Textpos ): StmtNode;  
  VAR target: DenotationNode;  stmt: St.AssignStmtNode;
  BEGIN 
    trace( "Assign" );  
    target := Denotation( id, pos, TRUE );  
    IF sym = S.Becomes THEN 
      GetSym;  
      NEW( stmt, pos, target, Expression() );  RETURN stmt
    ELSE 
      ErrorAndSkip( "':=' expected", S.Semicolon )
    END;  
    RETURN NIL 
  END Assign;  
  

  PROCEDURE Call( id: Identifier;  pos: Textpos ): StmtNode;  
  VAR stmt: St.CallStmtNode; 
  BEGIN 
    trace( "Call" );  
    NEW( stmt, pos, id );  RETURN stmt
  END Call;  
  

  PROCEDURE IfStmt( pos: Textpos ): StmtNode;  
  VAR cond: ExprNode; truep: StmtNode;  if: St.IfStmtNode; 
  BEGIN 
    trace( "IfStmt" );  
    GetSym;  
    cond := Condition();  
    IF sym = S.Then THEN  
      GetSym;  
      truep := Statement();  
      NEW( if, pos, cond, truep, NIL );  
      RETURN if
    ELSE 
      G.Error( "THEN expected", S.pos );
      RETURN NIL
    END;  
  END IfStmt;  
  

  PROCEDURE Statement( ): StmtNode;  
  VAR 
    pos, pos2: Textpos;  id: Identifier; 
    cond: ExprNode;
    stmt: StmtNode;    
    read: St.ReadStmtNode; write: St.WriteStmtNode; 
    while: St.WhileStmtNode;  
  BEGIN 
    trace( "Statement" );  
    CASE sym OF 
    | S.Ident: 
        pos := S.pos;  id := idNum;  GetSym;  
        stmt := Assign( id, pos )
    | S.Call:
        GetSym;  
        IF sym = S.Ident THEN
          pos := S.pos;  id := idNum;  GetSym; 
          stmt := Call( id, pos )
        ELSE
          ErrorAndSkip( MissingIdent, S.Semicolon )
        END;
    | S.Begin:
        GetSym;
        trace( "Begin" );
        stmt := StmtSequence();
        IF sym = S.End THEN
          GetSym;
        ELSE
          ErrorAndSkip( "END expected", S.End )
        END
    | S.If:   
        trace( "If" );
        stmt := IfStmt( S.pos )
    | S.While: 
        trace( "While" );  
        pos := S.pos;  GetSym;  
        cond := Condition();  
        IF sym = S.Do THEN  
          GetSym;  
          NEW( while, pos, cond, Statement() );  stmt := while;
          RETURN while
        ELSE  
          G.Error( "DO expected", S.pos );
          RETURN NIL
        END;
    | S.Read: 
        trace( "Read" );  
        pos := S.pos;  GetSym;  
        IF sym = S.Ident THEN  
          id := idNum;  pos2 := S.pos;  GetSym;  
          NEW( read, pos, Denotation( id, pos2, TRUE ) );  stmt := read 
        ELSE  
          ErrorAndSkip( MissingIdent, S.Semicolon )
        END 
    | S.Write: 
        trace( "Write" );  
        pos := S.pos;  GetSym;  
        NEW( write, pos, Expression() );
        stmt := write
    | S.End: 
        stmt := NIL 
    | S.Semicolon:  (* empty statement *)
        GetSym;  stmt := NIL
    ELSE  
      ErrorAndSkip( "wrong statement begin", S.Semicolon );  stmt := NIL
    END;  
    RETURN stmt
  END Statement;  

  PROCEDURE StmtSequence( ): StmtNode;  
  VAR first, last, new: StmtNode; list: St.StmtListNode
  BEGIN 
    trace( 'StmtSequence' );  
    first := NIL;  last := NIL;
    REPEAT  
      new := Statement();  
      IF new # NIL THEN 
        IF first = NIL THEN  first := new  ELSE  last.next := new   END;  
        last := new;
      END;
      IF sym = S.Semicolon THEN  GetSym  END
    UNTIL (sym < S.Ident) OR ((sym >= S.End) & (sym # S.Begin));
    NEW( list, first );
    RETURN list
  END StmtSequence;  

  PROCEDURE ConstDeclaration( ): DeclNode;  
  VAR 
    name: Identifier;  dpos: Textpos;  
    con: ConstantNode;  neg: BOOLEAN;
    cd: C.ConstDeclNode;  
  BEGIN 
    trace( "ConstDeclaration" );  
    IF sym = S.Ident THEN 
      name := idNum;  dpos := S.pos;  GetSym;  
      neg := FALSE;
      IF sym = S.EQ THEN 
        GetSym;  
        IF sym = S.Minus THEN
          neg := TRUE;  GetSym
        END;
        IF sym = S.Number THEN  
          IF neg THEN
            NEW( con, S.pos, O.integer, -S.value )
          ELSE
            NEW( con, S.pos, O.integer, S.value )
          END;
          NEW( cd, dpos, name, con );  
          GetSym
        ELSE  
          ErrorAndSkip( "number expected", S.Semicolon )
        END 
      ELSE  
        ErrorAndSkip("'=' expected", S.Semicolon )
      END 
    ELSE  
      ErrorAndSkip( MissingIdent, S.Semicolon )
    END;  
    RETURN cd;  
  END ConstDeclaration;  


  PROCEDURE VarDeclaration( ): DeclNode;  
  VAR 
    type: DenotationNode;  

    PROCEDURE variable( ): VarDeclNode;  
    VAR 
      head, tail: VarDeclNode; 
      vname, tname: Identifier;  
      vpos, tpos: Textpos; 
    BEGIN 
      head := NIL;  tail := NIL;  
      IF sym = S.Ident THEN 
        REPEAT
          vname := idNum;  vpos := S.pos;  GetSym;  
          IF sym = S.Colon THEN  
            GetSym;  
            IF sym = S.Ident THEN
              tname := idNum;  tpos := S.pos;  GetSym;  
              NEW( type, tpos, tname, TRUE );
              NEW( head, vpos, vname, type );  
            ELSE
              ErrorAndSkip( MissingIdent, S.Semicolon )
            END
          ELSIF sym = S.Comma THEN  
            GetSym;  
            tail := variable();  
            NEW( head, vpos, vname, type );  
            IF tail # NIL THEN  head.next := tail  END 
          ELSE  
            ErrorAndSkip( "':' or ',' expected", S.Semicolon )
          END 
        UNTIL sym # S.Ident
      ELSE  
        ErrorAndSkip( MissingIdent, S.Semicolon )
      END;  
      RETURN head
    END variable;  

  BEGIN 
    trace( "VarDeclaration" );  
    RETURN variable()
  END VarDeclaration;  

  

  PROCEDURE ProcDeclaration( procpos: Textpos ): DeclNode;  
  VAR 
    procname: Identifier;  
    proc: ProcDeclNode;  

  BEGIN 
    trace( "ProcDeclaration" );  
    procname := idNum;  GetSym;   
    IF sym = S.Semicolon THEN  
      GetSym  
    ELSE  
      ErrorAndSkip( "';' expected", S.Begin )
    END;
    NEW( proc, procpos, procname, Block( procname ) );
        IF sym = S.Semicolon THEN  
      GetSym  
    ELSE  
      ErrorAndSkip("';' expected", S.Begin )
    END;
    RETURN proc
  END ProcDeclaration;  
  

  PROCEDURE Block( blockId: Identifier ): BlockNode;  
  VAR 
    block: BlockNode;  
    declarations: DeclNode; 
    

    
    PROCEDURE Append( VAR list: DeclNode;  new: DeclNode );  
    VAR t: DeclNode;
    BEGIN 
      IF new # NIL THEN 
        IF list = NIL THEN  list := new
        ELSE
          t := list;
          WHILE t.next # NIL DO  t := t.next(DeclNode)  END;
          t.next := new
        END
      END; 
    END Append; 
    
      
    PROCEDURE Declarations;
    VAR procpos: G.Textpos;
    BEGIN 
      trace( "Declarations" );  

      IF sym = S.Const THEN
        GetSym;  
        REPEAT
          Append( declarations, ConstDeclaration() );  
          IF sym = S.Semicolon THEN  
            GetSym
          END;
        UNTIL sym # S.Ident;
      END;
      IF sym = S.Var THEN
        GetSym;  
        REPEAT
          Append( declarations, VarDeclaration() );  
          IF sym = S.Semicolon THEN  
            GetSym
          END;
        UNTIL sym # S.Ident
      END;
      IF sym = S.Proc THEN
        REPEAT
          procpos := S.pos;  GetSym;  
          IF sym = S.Ident THEN  
            Append( declarations, ProcDeclaration( procpos ) ) 
          ELSE  
            ErrorAndSkip( MissingIdent, S.Begin ) 
          END
        UNTIL sym # S.Proc
      END
    END Declarations;  

  BEGIN  (* Block *)
    trace( "Block" );  
    Declarations;  
    IF sym = S.Begin THEN  
      GetSym; 
      NEW( block, S.pos, declarations, StmtSequence( ) );
      IF sym = S.End THEN  
        GetSym;
        IF sym = S.Ident THEN  
          IF idNum # blockId THEN  
            G.Error( "identifier doesn't match procedure or module name", S.pos )
          END;
          GetSym
        ELSE    
          G.Error( MissingIdent, S.pos )
        END;
      ELSE  
        ErrorAndSkip( "';' or END expected", S.Begin )  
      END 
    ELSE  
      ErrorAndSkip( "CONST, TYPE, VAR, PROCEDURE or BEGIN expected", S.Begin )
    END;  
    RETURN block
  END Block;  
  
  
  PROCEDURE Parse*( input: Streams.Reader ): BlockNode;  
  VAR 
    rootBlock: BlockNode;  id: G.Identifier;
  BEGIN 
    S.Initialize( input );  
    O.Initialize; (* predeclared identifiers *)

    GetSym;  
    IF sym # S.Module THEN  
      G.Error( "MODULE expected", S.pos );  RETURN NIL  
    ELSE
      GetSym;
      IF sym = S.Ident THEN  
        id := idNum;  GetSym  
      ELSE  
        G.Error( MissingIdent, S.pos ) 
      END;
      IT.GetIdString( id, G.programName );
      IF sym # S.Semicolon THEN
        G.Error( "';' expected", S.pos )  
      ELSE  
        GetSym
      END;
      rootBlock := Block( id );  
      IF sym # S.Period THEN  G.Error( "'.' expected", S.pos )  END;  
      RETURN rootBlock
    END
  END Parse;  

END PL0Parser.