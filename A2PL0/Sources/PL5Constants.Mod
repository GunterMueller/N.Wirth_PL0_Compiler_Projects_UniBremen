MODULE PL5Constants;   (* g.f.  9.12.04  *)

IMPORT 
  G := PL5Global,
  OT := PL5ObjectTable, Objects := PL5Objects, 
  CG := PL5CodeGenerator, N := PL5Nodes;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  ExprNode = N.ExprNode;  DeclNode = N.DeclNode;
  Item = CG.Item;
  
  Type = Objects.Type;
  Constant = Objects.Constant;
  StringConstant = Objects.StringConstant;

CONST 
  NoId = -1;  
  
TYPE
  ConstantNode* = OBJECT (ExprNode)
    VAR
    (*  type: O.Type;  (inherited) *)
      value-  : INTEGER;  
      obj    : Constant;
      
      PROCEDURE Analyse*;  
      BEGIN
        G.TraceAnalysis( OT.curlev, "const" );  
        NEW( obj, NoId, position, type, value );
      END Analyse; 
      
      PROCEDURE Synthesize*( ): Item;  
      BEGIN 
        G.TraceSynthesis( "const" );
        RETURN CG.ConstantItem( obj )
      END Synthesize; 
      
      PROCEDURE & Init*( p: Textpos;  t: Type;  v: INTEGER );  
      BEGIN  
        position := p;  type := t;  value := v
      END Init; 
      
  END ConstantNode;  
  
  
  StringConstNode* = OBJECT (ExprNode)
    VAR
    (*  type: O.Type;  (inherited) *)
      value-  : G.String;  
      obj    : StringConstant;
      
      PROCEDURE Analyse*;  
      BEGIN
        G.TraceAnalysis( OT.curlev, "const" );  
        NEW( obj, NoId, position, value )
      END Analyse; 
      
      PROCEDURE Synthesize*( ): Item;  
      BEGIN 
        G.TraceSynthesis( "const" );
        RETURN CG.StringConstItem( obj )
      END Synthesize; 
      
      PROCEDURE & Init*( p: Textpos;  t: Type;  v: G.String );  
      BEGIN  
        position := p;  type := t;  value := v
      END Init; 
      
  END StringConstNode;  

  

  ConstDeclNode* = OBJECT (DeclNode)
    VAR
      id: Identifier;
      exprNode: ExprNode;
  
      PROCEDURE Analyse*( VAR prop: N.Property; pass: INTEGER );  
      VAR obj: Constant;  sobj: StringConstant;
      BEGIN 
        G.TraceAnalysis( OT.curlev, "const. decl." );  
        IF exprNode IS ConstantNode THEN
          NEW( obj, id, position, exprNode(ConstantNode).type, exprNode(ConstantNode).value );
          OT.EnterObject( obj )
        ELSIF exprNode IS StringConstNode THEN
          NEW( sobj, id, position, exprNode(StringConstNode).value );
          OT.EnterObject( sobj )
        ELSE
          G.Error( "illegal constant", exprNode.position )
        END
      END Analyse;  
      
      PROCEDURE Synthesize*;
      (* nothing to do *)
      END Synthesize;

      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  val: ExprNode );  
      BEGIN  
        position := pos;  id := name;  exprNode := val; 
      END Init;  
      
  END ConstDeclNode;
  
  

END PL5Constants.