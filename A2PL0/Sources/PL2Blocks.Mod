MODULE PL2Blocks;   (* gf   9.12.04  *)

IMPORT 
  G := PL2Global,
  OT := PL2ObjectTable, O := PL2Objects, 
  CG := PL2CodeGenerator,
  N := PL2Nodes;

TYPE 
  Textpos = G.Textpos;  
  Node = N.Node;  StmtNode = N.StmtNode;  Property = N.Property;
  DeclNode = N.DeclNode;

  Procedure = O.Procedure;  

TYPE 
  BlockNode* = OBJECT (Node)
    VAR
      declarations: DeclNode;  
      statements: StmtNode;  
        
      owner*  : Procedure;  (* the procedure this block belongs to, nil:  root block *)
      prop: Property;
        
      PROCEDURE AnalyseDeclList( n: DeclNode );  
      BEGIN 
        WHILE n # NIL DO  
          n.Analyse( prop );  n := n.next
        END
      END AnalyseDeclList; 
      
        
      PROCEDURE Analyse*;  
      BEGIN 
        G.TraceAnalysis( OT.curlev, "Block" );  
        OT.EnterBlock();  
        
        AnalyseDeclList( declarations );
        
        statements.Analyse;
      
        OT.LeaveBlock();  
      END Analyse;  


      
      PROCEDURE Synthesize*;  
      VAR decl: DeclNode; 
      BEGIN 
        G.TraceSynthesis( "Block" );  
        CG.IncLevel;  
        
        IF prop.locProcs & ( CG.currLevel > 0) THEN
          CG.GetFPRegister
        END;
        
        decl := declarations;
        WHILE decl # NIL DO  
          decl.Synthesize;  decl := decl.next
        END;
        
        IF owner = NIL THEN  
          (* root block *)
          CG.varspace := prop.varspace;
          CG.Prologue( 0 );  
          statements.Synthesize;
          CG.Epilogue( 0 ) 
        ELSE  
          (* procedure block *)
          G.TraceSynthesis( "enter procedure" );
          IF owner.waddr < -1 THEN
            (* fix forward references to this procedure*)
            CG.FixLink( -owner.waddr )
          END;  
          owner.waddr := CG.pc;   (* assign entry address *)
          
          CG.Prologue( prop.varspace );  
          statements.Synthesize;
          G.TraceSynthesis( "leave procedure" );
          CG.Epilogue( 0 );  
        END;
        
        IF prop.locProcs & ( CG.currLevel > 0) THEN
          CG.ReturnFPRegister
        END;
        CG.DecLevel 
      END Synthesize;  

      PROCEDURE & Init*( pos: Textpos;  decl: DeclNode; stmt: StmtNode );  
      BEGIN 
        position := pos;  
        declarations := decl;  
        statements := stmt;  
        owner := NIL  
      END Init;  

  END BlockNode;  
  

END PL2Blocks.