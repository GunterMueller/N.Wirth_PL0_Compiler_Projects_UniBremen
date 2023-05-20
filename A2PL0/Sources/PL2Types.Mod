MODULE PL2Types;   (* gf   5.4.05  *)

IMPORT G := PL2Global,
    OT := PL2ObjectTable,  O := PL2Objects, 
    N := PL2Nodes,  D := PL2Denotations;
    
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
  
(* ----------- type checks which avoid cascaded failures -------------------*)

  PROCEDURE SameType*( t1, t2: Type ): BOOLEAN;  
  BEGIN 
    RETURN (t1 = t2) OR t1.okflag OR t2.okflag
  END SameType;  
  
  PROCEDURE Integer*( t: Type ): BOOLEAN;
  BEGIN
    RETURN (t = O.integer) OR t.okflag
  END Integer;
  
  PROCEDURE Boolean*( t: Type ): BOOLEAN;
  BEGIN
    RETURN (t = O.boolean) OR t.okflag
  END Boolean;  
  
  PROCEDURE Char*( t: Type ): BOOLEAN;
  BEGIN
    RETURN (t = O.character) OR t.okflag
  END Char;
  
  PROCEDURE String*( t: Type ): BOOLEAN;
  BEGIN
    RETURN (t = O.string) OR t.okflag
  END String;
  
(*-------------------------------------------------------------*)


END PL2Types.