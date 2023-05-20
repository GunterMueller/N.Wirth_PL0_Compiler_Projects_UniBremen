MODULE PL0Types;   (* gf   5.4.05  *)

IMPORT G := PL0Global,
    OT := PL0ObjectTable,  O := PL0Objects, 
    N := PL0Nodes,  D := PL0Denotations;
    
TYPE
  Node = N.Node;
  DenotationNode = D.DenotationNode;
  
  Type = O.Type;
  

  PROCEDURE GetType*( node: Node ): Type;  
  VAR obj: OT.Object;
  BEGIN 
    G.TraceAnalysis( OT.curlev, "GetType" );
    IF node IS DenotationNode THEN  
      obj := OT.FindDecl( node(DenotationNode).id );  
      IF obj = NIL THEN
        G.Error( "undeclared identifier", node.position );
        RETURN NIL
      ELSIF ~(obj IS Type) THEN
        G.Error( "is not a type", node.position );
        RETURN NIL
      ELSE
        RETURN obj(Type)
      END
    ELSE
      G.Error( "identifier expected", node.position );
      RETURN NIL
    END
  END GetType;
  
  
  

END PL0Types.