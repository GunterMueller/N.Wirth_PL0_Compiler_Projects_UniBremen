MODULE PL2Nodes;   (* g.f.  9.12.04 *)

IMPORT G := PL2Global, CG := PL2CodeGenerator, Objects := PL2Objects;

(** base types for all nodes in Syntax Tree *)
TYPE 
  Item = CG.Item;
  Type = Objects.Type;
  
  Node* = OBJECT 
    VAR
      position*: G.Textpos;   (* position in souce code *)
  END Node;  
  
  Property* = RECORD    (* property of blocks *)
    varspace*  : INTEGER;
    locProcs*  : BOOLEAN
  END;
  
  DeclNode* = OBJECT (Node)
    VAR
      next*: DeclNode;

      PROCEDURE Analyse*( VAR prop: Property );   (** abstract *)
      BEGIN  HALT( 99 )   (* force overwriting *)
      END Analyse;    

      PROCEDURE Synthesize*;   (** abstract *)
      BEGIN  HALT( 99 );   (* force overwriting *)
      END Synthesize;  

  END DeclNode;  

  ExprNode* = OBJECT (Node)
    VAR
      type*: Type;   (* expression type,  value supplied by Analysis *)
      next*: ExprNode;

      PROCEDURE Analyse*;   (** abstract *)
      BEGIN  HALT( 99 )   (* force overwriting *)
      END Analyse;
      
      PROCEDURE Synthesize*( ): Item;  (** abstract *)
      BEGIN  HALT( 99 );   (* force overwriting *)
      END Synthesize;  

  END ExprNode;  
  
    
  StmtNode* = OBJECT (Node)
    VAR
      next*: StmtNode;

      PROCEDURE Analyse*;   (** abstract *)
      BEGIN  HALT( 99 );   (* force overwriting *)
      END Analyse;  

      PROCEDURE Synthesize*;  (** abstract *)
      BEGIN  HALT( 99 );   (* force overwriting *)
      END Synthesize;  

  END StmtNode;  
      

      
END PL2Nodes.