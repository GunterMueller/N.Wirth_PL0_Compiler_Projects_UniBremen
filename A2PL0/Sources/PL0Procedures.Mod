MODULE PL0Procedures;   (* gf  9.12.04  *)

IMPORT G := PL0Global, 
    OT := PL0ObjectTable, O := PL0Objects,  
    N := PL0Nodes, B := PL0Blocks;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  
  ProcDeclNode* = OBJECT (N.DeclNode)
        VAR
          id: Identifier;  
          body: B.BlockNode;  
            
          
          PROCEDURE Analyse*( VAR prop: N.Property );  
          VAR proc: O.Procedure;
          BEGIN             
            G.TraceAnalysis( OT.curlev, "Procedure" );  
            prop.locProcs := TRUE;
            NEW( proc, id, position ); 
            OT.EnterObject( proc );
            body.owner := proc;
            body.Analyse;
          END Analyse;  
          
          PROCEDURE Synthesize*;  
          BEGIN  
            G.TraceSynthesis( 'Procedure' );  
            body.Synthesize
          END Synthesize;  


          PROCEDURE & Init*( pos: Textpos;  name: Identifier;  block: B.BlockNode );  
          BEGIN  
            position := pos;  id := name;  body := block
          END Init; 
                    
      END ProcDeclNode;
    
END PL0Procedures.