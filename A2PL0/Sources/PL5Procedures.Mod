MODULE PL5Procedures;   (* gf  9.12.04  *)

IMPORT G := PL5Global,
    OT := PL5ObjectTable, Objects := PL5Objects,  
    Nodes := PL5Nodes,  
    Blocks := PL5Blocks, Types := PL5Types;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  Node = Nodes.Node;  Property = Nodes.Property;
  DeclNode = Nodes.DeclNode;
  
  BlockNode = Blocks.BlockNode;
  
  Type = Objects.Type;
  Procedure = Objects.Procedure;
  Parameter = Objects.Parameter;
  
  
  ParameterNode* = OBJECT (Node)
    VAR
      id-      : Identifier;  
      refpar-  : BOOLEAN;   (* TRUE: call by reference *)
      type-    : Node;
      next*    : ParameterNode;
    
      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  ref: BOOLEAN;  ptype: Node );  
      BEGIN  
        position := pos;  id := name;  refpar := ref;  type := ptype
      END Init;  
          
  END ParameterNode;
  
  
  ProcDeclNode* = OBJECT (DeclNode)
    VAR
      id      : Identifier;  
      params  : ParameterNode;  
      body    : BlockNode;  
      parspace  : INTEGER;
      
      PROCEDURE MakeParamObjects( cur: ParameterNode ): Parameter;
      VAR
        par: Parameter;  type: Type;  nextpar: Parameter;
        size: INTEGER; 
      BEGIN
        G.TraceAnalysis( OT.curlev, '       Parameter' );
        type := Types.GetType( cur.type );
        IF cur.refpar THEN  size := 4
        ELSE
          size := type.size;
          INC( size, (-size) MOD 4 ); (* round up to word bounadry *)
        END;  
        IF cur.next # NIL THEN  
          nextpar := MakeParamObjects( cur.next )  
        ELSE  
          nextpar := NIL  
        END;  
        NEW( par, cur.id, cur.position, type, parspace, cur.refpar, nextpar );  
        INC( parspace, size );
        RETURN par
      END MakeParamObjects;
    
      PROCEDURE AnalyseHead;  
      VAR proc: Procedure;  parList: Parameter;
      BEGIN  
        G.TraceAnalysis( OT.curlev, "Procedure head" );  
        parList := NIL;  parspace := 0;
        IF params # NIL THEN 
          parList := MakeParamObjects( params );
        END;
        NEW( proc, id, position, parList, parspace ); 
        OT.EnterObject( proc );  
        body.owner := proc
      END AnalyseHead;  
      
      PROCEDURE AnalyseBody;  
      BEGIN  
        G.TraceAnalysis( OT.curlev, "Procedure body" );  
        body.Analyse
      END AnalyseBody;
          
      PROCEDURE Analyse*( VAR prop: Property; pass: INTEGER );  
      BEGIN 
        prop.locProcs := TRUE;
        IF pass = 1 THEN  AnalyseHead  ELSE  AnalyseBody  END;
      END Analyse;  
      
      PROCEDURE Synthesize*;  
      BEGIN  
        G.TraceSynthesis( 'Procedure' );  
        body.Synthesize
      END Synthesize;  


      PROCEDURE & Init*( pos: Textpos;  name: Identifier;  par: ParameterNode; block: BlockNode );  
      BEGIN  
        position := pos;  id := name;  params := par;  body := block
      END Init; 
                
  END ProcDeclNode;
    
END PL5Procedures.