MODULE PL2Expressions;  

IMPORT
  G := PL2Global, S := PL2Scanner, O := PL2Objects, N := PL2Nodes, 
  D := PL2Denotations, T := PL2Types, C := PL2Constants, CG := PL2CodeGenerator,
  OT := PL2ObjectTable;
  

TYPE 
  Textpos = G.Textpos; Item = CG.Item;  
  
  Constant = O.Constant;
  
  ExprNode = N.ExprNode;   
  ConstantNode = C.ConstantNode;
  
  DenotationNode = D.DenotationNode;
  

TYPE
  MonadicExprNode* = OBJECT (ExprNode)
    VAR
      op: INTEGER;  
      arg: ExprNode;  
      
      PROCEDURE Analyse*;  
      BEGIN 
        arg.Analyse;  
        CASE op OF 
        | S.Odd: 
            IF ~T.Integer( arg.type ) THEN  
              G.Error( "integer operand expected", arg.position ) 
            END;  
            type := O.boolean 
        | S.Minus, S.Plus:
            IF ~T.Integer( arg.type ) THEN  
              G.Error( "integer operand expected", arg.position ) 
            END;  
            type := O.integer 
        | S.Not:  
            IF ~T.Boolean( arg.type ) THEN  
              G.Error( "boolean operand expected", arg.position )
            END;  
            type := O.boolean 
        END;
      END Analyse;  

      PROCEDURE Synthesize*( ): Item;  
      VAR x: Item; 
      BEGIN 
        x := arg.Synthesize( );
        CASE op OF 
        | S.Odd:  
            CG.Odd( x )
        | S.Minus:
            CG.Negate( x )
        | S.Plus:
            (* +x = x *)
        | S.Not:
            CG.Not( x );  
        END;
        RETURN x
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  oper: INTEGER;  argument: ExprNode );  
      BEGIN 
        position := pos;  op := oper;  arg := argument 
      END Init;  

  END MonadicExprNode;  
  

  DyadicExprNode* = OBJECT (ExprNode)
    VAR
      op: INTEGER;  
      left: ExprNode;  
      right: ExprNode;  
      
      PROCEDURE Analyse*;  
      BEGIN 
        left.Analyse;  right.Analyse;
        CASE op OF 
        | S.Plus, S.Minus, S.Times, S.Div: 
            IF ~T.Integer( left.type ) OR ~T.Integer( right.type ) THEN  
                G.Error( "integer operands expected", position ) 
            END;  
            type := O.integer;   
        | S.EQ, S.NE, S.LT, S.GE, S.GT, S.LE: 
            IF ~T.SameType( left.type, right.type ) THEN  
              G.Error( "type missmatch", position ) 
            END;  
            type := O.boolean 
        | S.And, S.Or: 
            IF ~T.Boolean( left.type ) OR ~T.Boolean( right.type ) THEN  
              G.Error( "boolean operands expected", position )  
            END;  
            type := O.boolean;  
        END 
      END Analyse;  
      

      PROCEDURE Synthesize*( ): Item;  
      VAR x: Item;  
      BEGIN 
        x := left.Synthesize( );   
        CASE op OF 
        | S.Plus:    
            CG.Add( x, right.Synthesize( ) ) 
        | S.Minus:  
            CG.Sub( x, right.Synthesize( ) ) 
        | S.Times:  
            CG.Mult( x, right.Synthesize( ) ) 
        | S.Div:
            CG.Div( x, right.Synthesize( ) )
        | S.EQ, S.NE, S.LT, S.GE, S.GT, S.LE:
            CG.CondBranch( op, x, right.Synthesize( ) ) 
        | S.And:
            CG.And1( x );
            CG.And2( x, right.Synthesize( ) )
        | S.Or: 
            CG.Or1( x );
            CG.Or2( x, right.Synthesize( ) )
        END;
        RETURN x
      END Synthesize;  
      

      PROCEDURE & Init*( pos: Textpos;  o: INTEGER;  l, r: ExprNode );  
      BEGIN 
        position := pos;  op := o;  left := l;  right := r 
      END Init;  

  END DyadicExprNode;  


(*==========================================================*)    


  PROCEDURE ConstValue( expr: ExprNode; VAR value: INTEGER ): BOOLEAN;
  VAR obj: OT.Object;
  BEGIN
    IF expr IS ConstantNode THEN 
      value := expr(ConstantNode).value;
      RETURN TRUE
    ELSIF expr IS DenotationNode THEN
      obj := OT.FindDecl( expr(DenotationNode).id );
      IF obj IS Constant THEN
        value := obj(Constant).value;
        RETURN TRUE
      END      
    END;
    RETURN FALSE
  END ConstValue;    
  
            
  PROCEDURE SimplifyConstParts*( VAR expr: ExprNode );
  (* small optimization, simplify constant parts in expressions *)
  VAR 
    de, lde: DyadicExprNode;  
    newNode: ConstantNode;
    tmp: ExprNode;
    op, lop: INTEGER;
    value, rval, lval: INTEGER;
  BEGIN
    IF expr IS DyadicExprNode THEN
      de := expr(DyadicExprNode);  op := de.op;
      SimplifyConstParts( de.left );  
      SimplifyConstParts( de.right );  
      IF (op IN {S.Plus, S.Times}) & ConstValue( de.left, value ) THEN
        tmp := de.left;  de.left := de.right;  de.right := tmp
      END;  
      IF (op IN {S.Times, S.Div, S.Plus, S.Minus}) & ConstValue( de.right, rval ) THEN
        IF ConstValue( de.left, lval ) THEN
          CASE op OF
          | S.Plus:    value := lval + rval
          | S.Minus:    value := lval - rval
          | S.Times:    value := lval * rval;
          | S.Div:    value := lval DIV rval;
          END;
          NEW( newNode, expr.position, O.integer, value );
          newNode.Analyse;
          newNode.next := expr.next;
          expr := newNode
        ELSIF de.left IS DyadicExprNode THEN
          lde := de.left(DyadicExprNode);
          IF ConstValue( lde.right, lval ) THEN
            lop := lde.op;
            CASE lop OF
            | S.Plus:  
                IF op = S.Plus THEN  value := lval + rval
                ELSIF op = S.Minus THEN  value := lval - rval
                ELSE op := -1
                END
            | S.Minus:
                IF op = S.Minus THEN  value := lval + rval
                ELSIF op = S.Plus THEN  value := lval - rval
                ELSE  op := -1
                END
            | S.Times:  
                IF op = S.Times THEN  value := lval * rval
                ELSE  op := -1
                END
            | S.Div:  
                IF op = S.Div THEN  value := lval * rval
                ELSE  op := -1
                END
            END;
            IF op > 0 THEN
              NEW( newNode, expr.position, O.integer, value );
              newNode.Analyse;
              lde.right := newNode;  lde.next := expr.next;
              expr := lde
            END
          END
        END
      END
    END;
  END SimplifyConstParts;
  
  
BEGIN
  D.SimplifyConstParts := SimplifyConstParts  
END PL2Expressions.