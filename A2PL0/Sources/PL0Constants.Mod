MODULE PL0Constants;   (* g.f.  9.12.04  *)

IMPORT 
  G := PL0Global, 
  OT := PL0ObjectTable, O := PL0Objects, 
  CG := PL0CodeGenerator, N := PL0Nodes;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  ExprNode = N.ExprNode;  DeclNode = N.DeclNode;  Property = N.Property;
  
  Constant = O.Constant;
  
  Item = CG.Item;

  
  
  ConstantNode* = OBJECT (ExprNode)
    VAR
    (*  type  : Type;  (inherited) *)
      value-  : INTEGER;  
      obj    : Constant;
      
      PROCEDURE Analyse*;  
      CONST NoId = -1;
      BEGIN
        G.TraceAnalysis( OT.curlev, "const" );  
        NEW( obj, NoId, position, type, value )
      END Analyse; 
      
      
      PROCEDURE Synthesize*( ): Item;  
      BEGIN 
        G.TraceSynthesis( "const" );
        RETURN CG.ConstantItem( obj )
      END Synthesize; 
      
      
      PROCEDURE & Init*( p: Textpos;  t: O.Type;  v: INTEGER );  
      BEGIN  
        position := p;  type := t;  value := v
      END Init; 
      
  END ConstantNode;  
  
  

  ConstDeclNode* = OBJECT (DeclNode)
    VAR
      id: Identifier;
      con: ExprNode;
  
      PROCEDURE Analyse*( VAR prop: Property );  
      VAR obj: Constant;  
      BEGIN 
        G.TraceAnalysis( OT.curlev, "const" );  
        IF con IS ConstantNode THEN
          NEW( obj, id, position,  con(ConstantNode).type, con(ConstantNode).value);
          OT.EnterObject( obj )
        ELSE
          G.Error( "illegal constant", con.position )
        END
      END Analyse;  
      
      PROCEDURE Synthesize*;
      (* nothing to do *)
      END Synthesize;

      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  val: ExprNode );  
      BEGIN  
        position := pos;  id := name;  con := val; 
      END Init;  
      
  END ConstDeclNode;

  
END PL0Constants.