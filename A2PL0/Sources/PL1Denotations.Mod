MODULE PL1Denotations;  (* GF  9.12.04 *)

IMPORT 
  G := PL1Global,
  OT := PL1ObjectTable, O := PL1Objects, 
  CG := PL1CodeGenerator, N := PL1Nodes;

TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos;  
  
  Constant = O.Constant; 
  StringConstant = O.StringConstant;
  Variable = O.Variable;
  
  Item = CG.Item;  
  
  ExprNode = N.ExprNode; 

VAR
  SimplifyConstParts*: PROCEDURE( VAR exp: ExprNode );
  (* needed for optimizing index expressions *)

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
        ELSIF obj IS Variable THEN  
          type := obj(Variable).type
        ELSIF obj IS Constant THEN
          IF writeAccess THEN
            G.Error( "assignment not allowed", position )
          END;
          type := obj(Constant).type
        ELSIF obj IS StringConstant THEN
          IF writeAccess THEN
            G.Error( "assignment not allowed", position )
          END;
          type := obj(StringConstant).type
        ELSE
          G.Error( "assignment not allowed", position );
          type := O.integer
        END
      END Analyse;  
      
      

      PROCEDURE Synthesize*( ): Item;  
      BEGIN 
        G.TraceSynthesis( "denotation" );  
        IF obj IS Constant THEN
          RETURN CG.ConstantItem( obj(Constant) )
        ELSIF obj IS StringConstant THEN
          RETURN CG.StringConstItem( obj(StringConstant) )
        ELSE
          RETURN CG.VariableItem( obj )
        END;  
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  wa: BOOLEAN );  
      BEGIN 
        position := pos;  id := name;  writeAccess := wa
      END Init;  

  END DenotationNode;  


END PL1Denotations.