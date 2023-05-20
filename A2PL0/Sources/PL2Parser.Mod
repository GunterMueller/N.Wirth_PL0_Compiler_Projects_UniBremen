MODULE PL2Parser;   (* g.f.  21.3.03  *)

IMPORT Streams,
  G := PL2Global, IT := PL2IdentifierTable, S := PL2Scanner, O := PL2Objects,
  N := PL2Nodes, 
  B := PL2Blocks, V := PL2Variables, 
  E := PL2Expressions, St := PL2Statements, 
  C := PL2Constants,  D := PL2Denotations,
  P := PL2Procedures;

CONST
  MissingIdent = "identifier expected"
  
TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos;  
  
  DeclNode = N.DeclNode;  
  ExprNode = N.ExprNode;  
  StmtNode = N.StmtNode;  
  
  ConstantNode = C.ConstantNode;
  StringConstNode = C.StringConstNode;
  ConstDeclNode = C.ConstDeclNode;
  
  BlockNode = B.BlockNode;
  
  DenotationNode = D.DenotationNode;
  VarDeclNode = V.VarDeclNode;
  MonadicExprNode = E.MonadicExprNode;
  DyadicExprNode = E.DyadicExprNode;
  
  ProcDeclNode = P.ProcDeclNode;

VAR 
  sym: G.Symbol;  (* current symbol *)
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
  (*  trace( "Factor" );  *)
    CASE sym OF 
      S.Ident: 
        Id := idNum;  pos := S.pos;  GetSym;  
        expr := Denotation( Id, pos, FALSE )
    | S.Number: 
        num := INTEGER(S.value);  GetSym;
        NEW( const, S.pos, O.integer, num );  expr := const
    | S.LParen: 
        GetSym;  
        expr := Formula();  
        IF sym = S.RParen THEN  
          GetSym;
        ELSE  
          G.Error( "')' expected", S.pos ); expr := NIL  
        END
    | S.Odd: 
        GetSym;  
        NEW( me, S.pos, S.Odd, Formula() );  expr := me
    | S.Not: 
        GetSym;  
        NEW( me, S.pos, S.Not, Formula() );  expr := me
    ELSE 
      G.Error( "expression expected", S.pos );  
      expr := NIL
    END;  
    RETURN expr
  END Factor;  
  

  PROCEDURE Term( ): ExprNode;  
  VAR expr: ExprNode;  opr: INTEGER;  de: DyadicExprNode;
  BEGIN 
  (*  trace( "Term" );  *)
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
  (*  trace( "Expression" );  *)
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
  
  
  PROCEDURE Relation( ): ExprNode;  
  VAR expr: ExprNode;  op: INTEGER;  de: DyadicExprNode;
  BEGIN 
  (*  trace( "Relation" );  *)
    expr := Expression();  
    IF (sym >= S.EQ) & (sym <= S.GE) THEN  
      op := sym;  GetSym;  
      NEW( de, S.pos, op, expr, Expression() );  RETURN de
    ELSE  
      RETURN expr
    END
  END Relation;  
  

  PROCEDURE Conjunction( ): ExprNode;  
  VAR expr: ExprNode;  de: DyadicExprNode;
  BEGIN 
  (*  trace( 'Conjunction' );  *)
    expr := Relation();  
    WHILE sym = S.And DO  
      GetSym;  
      NEW( de, S.pos, S.And, expr, Relation() );  expr := de 
    END;  
    RETURN expr
  END Conjunction;  
  
  
  PROCEDURE Formula( ): ExprNode;  
  VAR expr: ExprNode;  de: DyadicExprNode;
  BEGIN 
  (*  trace( 'Formula' );  *)
    expr := Conjunction();  
    WHILE sym = S.Or DO  
      GetSym;  
      NEW( de, S.pos, S.Or, expr, Conjunction() );  expr := de  
    END;  
  (*  trace( "Formula ]" );  *)
    RETURN expr
  END Formula;  
  


  PROCEDURE Denotation( id: Identifier; pos: Textpos; writeAccess: BOOLEAN ): DenotationNode;  
  VAR acc: DenotationNode;  
  BEGIN 
  (*  trace( "Denotation" );  *)
    NEW( acc, pos, id, writeAccess );  RETURN acc
  END Denotation;  
  

  PROCEDURE Assign( id: Identifier;  pos: Textpos ): StmtNode;  
  VAR target: DenotationNode;  stmt: St.AssignStmtNode;
  BEGIN 
    trace( "Assign" );  
    target := Denotation( id, pos, TRUE );  
    IF sym = S.Becomes THEN 
      GetSym;  
      NEW( stmt, pos, target, Formula() );  RETURN stmt
    ELSE 
      ErrorAndSkip( "':=' expected", S.Semicolon )
    END;  
    trace( "Assign ]" ); 
    RETURN NIL 
  END Assign;  
  

  PROCEDURE Call( id: Identifier;  pos: Textpos ): StmtNode;  
  VAR stmt: St.CallStmtNode; 
  BEGIN 
    trace( "Call" );  
    NEW( stmt, pos, id );  RETURN stmt
  END Call;  
  

  PROCEDURE IfStmt( pos: Textpos ): StmtNode;  
  VAR 
    cond: ExprNode; truep, falsep: StmtNode;  If: St.IfStmtNode;  
  
    PROCEDURE ElsePart( ): StmtNode;  
    VAR 
      cond: ExprNode; truep, falsep: StmtNode;  If: St.IfStmtNode;
    BEGIN 
      trace( "ElsePart" );  
      IF sym = S.Elsif THEN  
        GetSym;  
        cond := Formula();  
        IF sym = S.Then THEN  
          GetSym;  
          truep := StmtSequence();  
          IF (sym = S.Elsif) OR (sym = S.Else) THEN  
            falsep := ElsePart()  
          ELSE  
            falsep := NIL  
          END;  
          NEW( If, pos, cond, truep, falsep );
          RETURN If
        ELSE 
          G.Error( "THEN expected", S.pos )
        END 
      ELSE  
        (* sym =  Else *)  GetSym;  RETURN StmtSequence()
      END;  
    END ElsePart;  
  
  BEGIN 
    trace( "If" );  
    GetSym;  
    If := NIL;  cond := Formula();  
    IF sym = S.Then THEN  
      GetSym;  
      truep := StmtSequence();  
      IF (sym = S.Elsif) OR (sym = S.Else) THEN  
        falsep := ElsePart()  
      ELSE  
        falsep := NIL  
      END;
      NEW( If, pos, cond, truep, falsep );  
      IF sym = S.End THEN  
        GetSym;  
      ELSE 
        G.Error( "ELSIF, ELSE or END expected", S.pos )
      END
    ELSE 
      G.Error( "THEN expected", S.pos )
    END;  
    trace( "if  ]" );
    RETURN If
  END IfStmt;    

  PROCEDURE Statement( ): StmtNode;  
  VAR 
    pos, pos2: Textpos;  id: Identifier; 
    cond: ExprNode;
    scon: StringConstNode;
    char: ConstantNode;
    stmt: StmtNode;    
    read: St.ReadStmtNode; write: St.WriteStmtNode; 
    while: St.WhileStmtNode;  
  BEGIN 
  (*  trace( "Statement" );  *)
    CASE sym OF 
    S.Ident: 
        pos := S.pos;  id := idNum;  GetSym;  
        IF (sym = S.LParen) OR (sym >= S.Semicolon) THEN
          stmt := Call( id, pos );  
        ELSE 
          stmt := Assign( id, pos );  
        END 
    | S.Begin:
        GetSym;
        stmt := StmtSequence();
        IF sym = S.End THEN
          GetSym;
        ELSE
          ErrorAndSkip( "END expected", S.End )
        END
    | S.If:   
        stmt := IfStmt( S.pos )
    | S.While: 
        trace( "While" );  
        pos := S.pos;  GetSym;  
        cond := Formula();  
        IF sym = S.Do THEN  
          GetSym;  
          NEW( while, pos, cond, StmtSequence() );  stmt := while;
          IF sym = S.End THEN 
            GetSym
          ELSE
            G.Error( "END expected", S.pos )
          END;
          trace( "While ]" );
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
        IF sym = S.String  THEN  
          NEW( scon,  S.pos,  O.string, S.value2 );  
          NEW( write, pos, scon );  GetSym
        ELSIF sym = S.Character THEN
          NEW( char, S.pos, O.character, S.value );
          NEW( write, pos, char );  GetSym
        ELSE 
           NEW( write, pos, Formula() )
        END ;  
        trace( "Write ]" );
        stmt := write
    | S.End, S.Elsif, S.Else: 
        stmt := NIL 
    | S.Semicolon:  (* empty statement *)
        GetSym;  stmt := NIL
    ELSE  
      ErrorAndSkip( "wrong statement begin", S.Semicolon );  stmt := NIL
    END;  
  (*  trace( "Statement ]" ); *)
    RETURN stmt
  END Statement;  

  PROCEDURE StmtSequence( ): StmtNode;  
  VAR first, last, new: StmtNode; list: St.StmtListNode
  BEGIN 
    trace( 'Sequence' );  
    first := NIL;  last := NIL;
    REPEAT  
      new := Statement();  
      IF new # NIL THEN 
        IF first = NIL THEN  first := new  ELSE  last.next := new   END;  
        last := new;
      END;
      IF sym = S.Semicolon THEN  GetSym  END
    UNTIL sym >= S.End;
    NEW( list, first );
    trace ( "Sequence ]" );
    RETURN list
  END StmtSequence;  

  
  
  PROCEDURE ConstDeclaration( ): DeclNode;  
  VAR 
    name: Identifier;  dpos: Textpos;  
    con: ConstantNode;  neg: BOOLEAN;
    scon: StringConstNode;
    cd: ConstDeclNode;  
  BEGIN 
    trace( "ConstDeclaration" );  
    IF sym = S.Ident THEN 
      name := idNum;  dpos := S.pos;  GetSym;  
      neg := FALSE;
      IF sym = S.EQ THEN 
        GetSym;  
        IF sym = S.Minus THEN
          neg := TRUE; GetSym
        END;
        IF sym = S.Number THEN  
          IF neg THEN
            NEW( con, S.pos, O.integer, -S.value )
          ELSE
            NEW( con, S.pos, O.integer, S.value )
          END;
          NEW( cd, dpos, name, con );  
          GetSym
        ELSIF sym = S.String THEN 
          NEW( scon, S.pos, O.string, S.value2 );
          NEW( cd, dpos, name, scon );  
          GetSym
        ELSE  
          ErrorAndSkip( "number or string expected", S.Semicolon )
        END 
      ELSE  
        ErrorAndSkip("'=' expected", S.Semicolon )
      END 
    ELSE  
      ErrorAndSkip( "identifier expected", S.Semicolon )
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
    trace( "Block ]" );
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

END PL2Parser.