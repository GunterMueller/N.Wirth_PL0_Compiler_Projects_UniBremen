MODULE PL3Blocks;   (* gf   9.12.04  *)

IMPORT 
  G := PL3Global,
  OT := PL3ObjectTable, O := PL3Objects, 
  CG := PL3CodeGenerator,
  N := PL3Nodes;

TYPE 
  Textpos = G.Textpos;  
  Node = N.Node;  StmtNode = N.StmtNode;  DeclNode = N.DeclNode;  
  Property =N.Property;

  Procedure = O.Procedure; 

TYPE 
  BlockNode* = OBJECT (Node)
    VAR
      constants: DeclNode;  
      variables: DeclNode;  
      procedures: DeclNode;  
      statements: StmtNode;  
        
      owner*  : Procedure;  (* the procedure this block belongs to, nil:  root block *)
      prop: Property;
        
      PROCEDURE AnalyseList( n: DeclNode; pass: INTEGER );  
      BEGIN 
        WHILE n # NIL DO  
          n.Analyse( prop, pass );  n := n.next
        END
      END AnalyseList; 
      
        
      PROCEDURE Analyse*;  
      BEGIN 
        OT.EnterBlock();  
        prop.varspace := 0;
        prop.locProcs := FALSE;
        
        G.TraceAnalysis( OT.curlev, "Block" );  
        
        AnalyseList( constants, 1 );
        AnalyseList( variables, 1 );
        
        AnalyseList( procedures, 1 ); (* collect names *)
        AnalyseList( procedures, 2 ); (* analyse bodies *)
        
        statements.Analyse;
        
        OT.LeaveBlock();  
      END Analyse;  

      
      PROCEDURE Synthesize*;  
      VAR proc: DeclNode;
      BEGIN 
        G.TraceSynthesis( "Block" );  
        CG.IncLevel;  
        
        IF prop.locProcs & ( CG.currLevel > 0) THEN
          CG.GetFPRegister  (* frame pointer for intermediate frame *)
        END;
        
        proc := procedures;
        WHILE proc # NIL DO  
          proc.Synthesize;  proc := proc.next
        END;
        
        IF owner = NIL THEN  
          (* root block *)
          G.TraceSynthesis( "begin root block" );
          CG.varspace := prop.varspace;
          CG.Prologue( 0 );  
          statements.Synthesize;
          G.TraceSynthesis( "leave root block" );
          CG.Epilogue( 0 ) 
        ELSE  
          (* procedure block *)
          G.TraceSynthesis( "begin procedure" );
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

      PROCEDURE & Init*( pos: Textpos;  con, var, proc: DeclNode; stmt: StmtNode );  
      BEGIN 
        position := pos;  
        constants := con;  
        variables := var;  
        procedures := proc;  
        statements := stmt;  
        owner := NIL;  (* not yet known *)
      END Init;  

  END BlockNode;  
  

END PL3Blocks.