MODULE PL0Denotations;  (* GF  9.12.04 *)

IMPORT 
  G := PL0Global,
  OT := PL0ObjectTable, O := PL0Objects, 
  CG := PL0CodeGenerator, N := PL0Nodes;

TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos;  
  
  Constant = O.Constant; Variable = O.Variable;
  
  Item = CG.Item;  
  
  ExprNode = N.ExprNode; 

VAR
  SimplifyConstParts*: PROCEDURE( VAR exp: ExprNode );
  (* needed for optimizing index expressions (PL4, ...)  *)

TYPE
  DenotationNode* = OBJECT (ExprNode)
    VAR
    (*  type: Type  (inherited) *)
      id-: Identifier;  
      writeAccess: BOOLEAN;
      obj: OT.Object;
      

      PROCEDURE Analyse*;  
      BEGIN  
        G.TraceAnalysis( OT.curlev, "denotation" );  
        obj := OT.FindDecl( id );  
        IF obj = NIL THEN  
          G.Error( "identifier unknown", position )  
        ELSE  
          IF obj IS Variable THEN  
            type := obj(Variable).type
          ELSIF ~ writeAccess THEN
            IF obj IS Constant THEN
              type := obj(Constant).type
            END
          ELSE
            G.Error( "assignment not allowed", position );
            type := O.integer
          END
        END  
      END Analyse;  
      
      

      PROCEDURE Synthesize*( ): Item;  
      BEGIN 
        G.TraceSynthesis( "denotation" );  
        IF obj IS Constant THEN
          RETURN CG.ConstantItem( obj(Constant) )
        ELSE
          RETURN CG.VariableItem( obj )
        END;  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  wa: BOOLEAN );  
      BEGIN 
        position := pos;  id := name;  writeAccess := wa
      END Init;  

  END DenotationNode;  


END PL0Denotations.