MODULE PL4Denotations;  (* GF  9.12.04 *)

IMPORT G := PL4Global, 
    OT := PL4ObjectTable, Objects := PL4Objects, 
    CG := PL4CodeGenerator,
    Constants := PL4Constants,  Nodes := PL4Nodes;  

CONST 
  Const = CG.Const; 

VAR
  SimplifyConstParts*: PROCEDURE( VAR exp: ExprNode );
  (* needed for optimizing index expressions *)

TYPE 
  Identifier = G.Identifier;  Textpos = G.Textpos; 
   
  ExprNode      = Nodes.ExprNode;  
  
  ConstantNode  = Constants.ConstantNode;
  
  Type        = Objects.Type;  
  ArrayType      = Objects.ArrayType; 
  Constant      = Objects.Constant;  
  StringConstant  = Objects.StringConstant;
  Variable      = Objects.Variable;
  
  Item = CG.Item;  
    

  DenotationNode* = OBJECT (ExprNode)
    VAR
    (*  type: Type;    (inherited) 
      position: Textpos; (inherited) *)
      id-: Identifier;  
      
      writeAccess: BOOLEAN;
      indices: ExprNode;  (* list of index expressions *)
      obj: OT.Object;
      
      PROCEDURE AnalyseIndices;  
      VAR i: INTEGER;  var: Variable;  curType, elType: Type;  index: ExprNode;  
      BEGIN  
        G.TraceAnalysis( OT.curlev, "analyse indices" );  
        var := obj(Variable);  curType := var.type;  index := indices;
        WHILE index # NIL DO  
          IF curType IS ArrayType THEN  
            elType := curType(ArrayType).elType;  
            index.Analyse;  
            IF index.type = Objects.integer THEN  
              IF index IS ConstantNode THEN  
                i := index(ConstantNode).value;  
                IF (i < 0) OR (i >= curType(ArrayType).range) THEN  
                  G.Error( "value out of range", index.position )  
                END  
              END  
            ELSE  
              G.Error( "integer value expected", index.position ) 
            END  
          ELSE  
            G.Error( "indexing not allowed", index.position );  
            RETURN
          END;  
          curType := elType;  
          index := index.next
        END;
        type := curType
      END AnalyseIndices;  
      
      PROCEDURE SimplifyList( VAR expr: ExprNode );
      BEGIN
        SimplifyConstParts( expr );
        IF expr.next # NIL THEN
          SimplifyConstParts( expr.next )
        END;
      END SimplifyList;

      PROCEDURE Analyse*;  
      BEGIN  
        G.TraceAnalysis( OT.curlev, "denotation" );  
        obj := OT.FindDecl( id );  
        IF obj = NIL THEN  
          G.Error( "identifier unknown", position )  
        ELSE  
          IF obj IS Variable THEN  
            IF indices # NIL THEN  
              SimplifyList( indices )
            END;
            AnalyseIndices;
          ELSIF obj IS Constant THEN
            IF writeAccess THEN
              G.Error( "assignment not allowed", position )
            END;
            IF indices # NIL THEN
              G.Error( "indexing a constant is forbidden", position );
            END;
            type := obj(Constant).type
          ELSIF obj IS StringConstant THEN
            IF writeAccess THEN
              G.Error( "assignment not allowed", position )
            END;
            IF indices # NIL THEN
              G.Error( "indexing a constant is forbidden", position );
            END;
            type := obj(StringConstant).type
          ELSIF obj IS Type THEN
            G.Error( "denotes a type", position )
          ELSE
            (*procedure*)
            G.Error( "procedure not allowed here", position )                  
          END
        END  
      END Analyse;  
      
    (*--------------------------------------- code generation ------------------------------------------*)    

      PROCEDURE SelectElement( VAR x: Item );  
      VAR 
        artype: ArrayType; eltype: Type;  
        index: ExprNode;
        y: Item; 
      BEGIN  
        G.TraceSynthesis( "    select element" );  
        index := indices;
        WHILE index # NIL DO  
          artype := x.type(ArrayType);  eltype := artype.elType;  
          y := index.Synthesize( );  
          IF y.mode = Const THEN  
            INC( x.off, y.off*eltype.size )  
          ELSE  
            CG.Check( y, artype.range );  
            IF eltype.size # 1 THEN
              CG.Multi( y, eltype.size )
            END;  
            CG.IncrAddr( x, y )
          END;  
          x.type := eltype;  
          index := index.next
        END;  
      END SelectElement;  

      PROCEDURE Synthesize*( ): Item;  
      VAR x: Item;
      BEGIN 
        G.TraceSynthesis( "denotation" );
        IF obj IS Constant THEN
          x := CG.ConstantItem( obj(Constant) )
        ELSIF obj IS StringConstant THEN
          x := CG.StringConstItem( obj(StringConstant) )
        ELSE
          x := CG.VariableItem( obj );
          IF indices # NIL THEN  SelectElement( x )  END;
        END;  
        RETURN x
      END Synthesize; 
    
    (* --------------------------------------------------------------------------------------------------------------- *)

      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  wa: BOOLEAN;  ind: ExprNode );  
      BEGIN 
        position := pos;  id := name;  writeAccess := wa;  indices := ind
      END Init;  

  END DenotationNode;  


END PL4Denotations .