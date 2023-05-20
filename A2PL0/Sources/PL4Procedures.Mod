MODULE PL4Procedures;   (* gf  9.12.04  *)

IMPORT G := PL4Global, 
    OT := PL4ObjectTable, O := PL4Objects,  
    N := PL4Nodes, B := PL4Blocks;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  
  ProcDeclNode* = OBJECT (N.DeclNode)
        VAR
          id: Identifier;  
          body: B.BlockNode;  
            
          
          PROCEDURE Analyse*( VAR prop: N.Property; pass: INTEGER );  
          VAR proc: O.Procedure;
          BEGIN             
            G.TraceAnalysis( OT.curlev, "Procedure" );  
            IF pass = 1 THEN
              prop.locProcs := TRUE;
              NEW( proc, id, position ); 
              OT.EnterObject( proc );
              body.owner := proc;
            ELSE
              body.Analyse
            END;
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
    
END PL4Procedures.