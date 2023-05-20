MODULE PL5Parameters;   (* gf   9.12.04  *)

IMPORT S := PL1Scanner, N := PL5Nodes;

TYPE 
  Textpos = S.Textpos;  IdNumber = S.IdNumber;
  Node = N.Node;
  
TYPE 
  ParameterNode* = OBJECT (Node)
    VAR
      id-: IdNumber;  
      refpar-: BOOLEAN;   (* TRUE: call by reference *)
      ptype-: Node;
    
      PROCEDURE & Init*( pos: Textpos;  name: IdNumber;  ref: BOOLEAN;  type: Node );  
      BEGIN  
        position := pos;  id := name;  refpar := ref;  ptype := type
      END Init;  
          
  END ParameterNode;

    
END PL5Parameters.