MODULE PL4Types;   (* gf   5.4.05  *)

IMPORT G := PL4Global,
    OT := PL4ObjectTable, O := PL4Objects,
    N := PL4Nodes, C := PL4Constants, D := PL4Denotations;  

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;  

  Node = N.Node;  DeclNode = N.DeclNode; Property = N.Property;
  DenotationNode = D.DenotationNode;  
  ConstantNode = C.ConstantNode;  

  Object = OT.Object;  

  Type = O.Type;    
  ArrayType = O.ArrayType;
  Constant = O.Constant;
  

CONST 
  NoId = -1;  NoPos = -1;


TYPE 
  ArrayTypeNode* = OBJECT (Node)
    VAR
      range: Node;  
      elType: Node;
      
      PROCEDURE & Init*( pos: Textpos;  size: Node;  typ: Node );  
      BEGIN  
        ASSERT( pos # 0 );
        position := pos;  range := size;  elType := typ
      END Init;  
      
  END ArrayTypeNode;
  
  
  Alias = OBJECT (Type)
    VAR
      id: Identifier;  
      type: Type
  END  Alias; 
  
  (* this type gets inserted to avoid subsequent error messages *)
  OkType = OBJECT (Type)  
  END OkType;

  
  

  
  TypeDeclNode* = OBJECT (DeclNode)
    VAR
      name  : Identifier;  
      type  : Node;  
      
      PROCEDURE pass1;  
      VAR obj: Object;  alias: Alias;  
      BEGIN 
        trace( "TypeDecl pass 1" );  
        IF type IS DenotationNode THEN          (* TYPE a = b  *)
          trace( "       alias" );  
          NEW( alias, name, position, 0 );  
          alias.id := type(DenotationNode).id;  alias.type := NIL;  
          OT.EnterObject( alias );  
        ELSIF type IS ArrayTypeNode THEN        (* TYPE a = ARRAY ... *)
          trace( "       anonymous array" );  
          obj := MakeArrayType( type(ArrayTypeNode), name, 1 );  
        END;  
      END pass1;
      
      PROCEDURE pass2;  
      VAR obj: Object; 
      BEGIN
        trace( "TypeDecl pass 2" );
        obj := OT.FindDecl( name );  
        IF obj = NIL THEN  (* name clash *)
        ELSIF obj IS Alias THEN  
          IF obj(Alias).type = NIL THEN  FinishType( obj )  END          
        ELSIF obj IS ArrayType THEN  
          IF obj( ArrayType ).size = 0 THEN  FinishType( obj )  END;
        END;  
      END pass2;  
        
      PROCEDURE Analyse*( VAR prop: Property; pass: INTEGER );  
      BEGIN
        CASE pass OF
        | 1: pass1
        | 2: pass2
        ELSE
        END
      END Analyse;  
      
      
      PROCEDURE Synthesize*;
      BEGIN
        (* nothing to do *)
      END Synthesize;
      

      PROCEDURE & Init*( pos: Textpos;  id: Identifier;  t: Node );  
      BEGIN 
        position := pos;  name := id;  type := t
      END Init;  

  END TypeDeclNode;  
  
  
  

  PROCEDURE GetType*( node: Node ): Type;  
  BEGIN 
    RETURN FindOrMakeType( node, (*pass*)2 )
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

  
  PROCEDURE FindOrMakeType( node: Node; pass: INTEGER ): Type;  
  VAR 
    type: Type; 
  BEGIN 
    trace( "FindOrMakeType" );  
    IF node IS DenotationNode THEN  
      trace( "       type access" );
      type := FindType( node(DenotationNode).id, node.position, pass )
    ELSIF node IS ArrayTypeNode THEN  
      type := MakeArrayType( node(ArrayTypeNode), NoId, pass );
      IF pass > 1 THEN  FinishType( type )  END
    END;  
    ASSERT( (pass = 1) OR (type # NIL) );
    RETURN type;  
  END FindOrMakeType;  
  
  
  PROCEDURE FindType( id: Identifier;  pos: Textpos; pass: INTEGER ): Type;  
  VAR 
    obj: Object; 
  BEGIN 
    trace( "       FindType" );
    obj := OT.FindDecl( id );  
    IF (obj = NIL) OR ~(obj IS Type) THEN
      IF pass = 1 THEN 
        RETURN NIL
      ELSE
        G.Error( "is not a type", pos );
        RETURN okType
      END;
    ELSE
      IF pass > 1 THEN
        RETURN RealType( obj )
      ELSE
        RETURN obj(Type)
      END;
    END;
  END FindType;  
  
  
  PROCEDURE MakeArrayType( node: ArrayTypeNode;  id: Identifier; pass: INTEGER ): Type;  
  VAR arrType: ArrayType;  elType: Type;  obj: Object;  
    range: INTEGER;  eltypeId: Identifier;
  BEGIN 
    trace( "       MakeArrayType" );  
    ASSERT( node.position # 0 );
    IF node.range IS ConstantNode THEN  
      range := node.range(ConstantNode).value
    ELSE  
      obj := OT.FindDecl( node.range(DenotationNode).id );  
      IF (obj = NIL) OR ~(obj IS Constant) OR (obj(Constant).type # O.integer) THEN
        G.Error( "integer constant expected", node.range.position );  
        range := 1
      ELSE
        range := obj(Constant).value
      END  
    END;  
    IF node.elType IS ArrayTypeNode THEN
      elType := MakeArrayType( node.elType(ArrayTypeNode), NoId, pass )
    ELSE
      elType := FindOrMakeType( node.elType, (*pass*)1 )
    END;
    IF elType # NIL THEN  
      NEW( arrType, id, node.position, range, elType, NoId ); 
    ELSE
      eltypeId := node.elType(D.DenotationNode).id;
      NEW( arrType, id, node.position, range, NIL, eltypeId );
    END;
    IF id # NoId THEN  OT.EnterObject( arrType )  END;  
    RETURN arrType 
  END MakeArrayType;  
  
  
  PROCEDURE RealType( obj: Object ): Type;
  VAR 
    alias: Alias;   type: Type;
  BEGIN
    trace( "       RealType" );
    WHILE obj IS Alias DO  
      alias := obj(Alias);
      IF alias.type = NIL THEN  
        type := FindType( alias.id, alias.pos, 2 );
        IF type = NIL THEN
          RETURN alias
        ELSE
          obj := type
        END
      ELSE
        obj := alias.type
      END            
    END;
    RETURN obj(Type)
  END RealType;
  
  
  PROCEDURE FinishType( obj: Object );  
  VAR 
    array: ArrayType;  elemType: Type;
  BEGIN 
    ASSERT( obj # NIL );
    IF obj IS Alias THEN  
      trace( "        fix alias" );
      obj := RealType( obj );
      FinishType( obj )
    ELSIF obj IS ArrayType THEN  
      trace( "       finish array type" );
      array := obj(ArrayType);  
      IF array.size > 0 THEN  
        (* allready finished *)
      ELSIF array.size = 0 THEN 
        array.size := -1;   (* mark *)
        IF array.elType = NIL THEN  
          elemType := FindType( array.elTypeId, array.pos, 2 );
          IF elemType.size < 0 THEN
            G.Error( "cyclic type definition", obj.pos );
            array.okflag := TRUE
          ELSE 
            FinishType( elemType );  
            array.size := array.range*elemType.size;
          END;
          array.elType := elemType
        ELSE
          IF array.elType.size < 0 THEN
            G.Error( "cyclic type definition", obj.pos );
            array.okflag := TRUE
          ELSE
            array.size := array.range*array.elType.size
          END
        END
      END;  
    END;  
  END FinishType;  
  

  PROCEDURE trace( CONST mess: ARRAY OF CHAR );
  BEGIN
    G.TraceAnalysis( OT.curlev, mess )
  END trace; 


VAR 
  okType: OkType;
    
BEGIN
  NEW( okType, NoId, NoPos, 1 ); okType.okflag := TRUE
END PL4Types.