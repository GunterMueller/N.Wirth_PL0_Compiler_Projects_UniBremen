MODULE PL5Objects;   (* g.f.  21.3.03  *)

IMPORT G := PL5Global, IT := PL5IdentifierTable, OT := PL5ObjectTable;

TYPE 
  Object* = OT.Object;  
  Identifier = G.Identifier;  Textpos = G.Textpos;

CONST
  NoId = -1;  NoPos = -1;  NoAddr = -1;
  
TYPE
  Type* = OBJECT (Object) 
    VAR  
      size*    : INTEGER;
      okflag*  : BOOLEAN;  (* TRUE if an error has been reported *)
      
      PROCEDURE & InitType*( id: Identifier; pos: Textpos; bytes: INTEGER );
      BEGIN
        InitObj( id, pos );
        size := bytes;  okflag := FALSE
      END InitType;
      
  END Type;
  
  ArrayType* = OBJECT (Type)
    VAR
      range-  : INTEGER;  
      elType*  : Type;  
      elTypeId-  : Identifier;
      
      PROCEDURE &InitArrayType*( id: Identifier;  pos: Textpos; 
                        r: INTEGER;  et: Type;  etid: Identifier );
      VAR size: INTEGER;
      BEGIN
        IF et = NIL THEN  size := 0  ELSE  size := r*et.size  END;
        InitType( id, pos, size );
        range := r;  elType := et;  elTypeId := etid
      END InitArrayType;
      
  END ArrayType;  
  
  
  Variable* = OBJECT (Object)
    VAR  
      type-  : Type;  
      addr-  : INTEGER;
      
      PROCEDURE &InitVar*(  id: Identifier; pos: Textpos;  t:Type;  a: INTEGER );
      BEGIN
        InitObj( id, pos );
        type := t;  addr := a
      END InitVar;
      
  END Variable;  
  
  
  Constant* = OBJECT (Object)
    VAR  
      type-  : Type;
      value-  : INTEGER;  (* constant value (integer or character) *)
      addr*  : INTEGER;    (* >= 0 if consstant has been allocated in RAM *)
      
      PROCEDURE &InitConst*( id: Identifier; pos: Textpos;  t:Type;  val: INTEGER );
      BEGIN
        InitObj( id, pos );
        type := t;  value := val;  addr := NoAddr
      END InitConst;
      
  END Constant;  
  
  StringConstant* = OBJECT (Object)
    VAR  
      type-  : Type;
      value-  : G.String;
      addr*  : INTEGER;    (* >= 0 if consstant has been allocated in RAM *)
      
      PROCEDURE &InitStringConst*( id: Identifier; pos: Textpos;  val: G.String );
      BEGIN
        InitObj( id, pos );
        type := string;  value := val;  addr := NoAddr
      END InitStringConst;
      
  END StringConstant;  
  
  
  Procedure* = OBJECT (Object)
    VAR
      waddr*    : INTEGER;     (* word address of procedure entry *)
      params-    : Parameter;  
      parspace-  : INTEGER;   (* stack space for parameters *)
      
      PROCEDURE &InitProc*( id: Identifier; pos: Textpos; par: Parameter; space: INTEGER );
      BEGIN
        InitObj( id, pos );
        params := par;  parspace := space; 
        waddr := NoAddr
      END InitProc;
      
  END Procedure;  
  
  
  Parameter* = OBJECT (Variable)
    VAR
      refpar-  : BOOLEAN;
      next-    : Parameter;
      
      PROCEDURE &InitPar*( id: Identifier; pos: Textpos; 
                    type: Type; addr: INTEGER;  ref: BOOLEAN; nextp: Parameter );
      BEGIN
        InitVar( id, pos, type, addr );
        refpar := ref;  next := nextp
      END InitPar;
      
  END Parameter;  

VAR 
  integer*, boolean*, character*, string*: Type;   (* predeclared types *)
  
  
  PROCEDURE Initialize*;
  VAR 
    sym: G.Symbol;  id: Identifier; con: Constant;
  BEGIN
    OT.Initialize;
    
    (* create predeclared types and constants *)
    IT.Enter( "integer", sym, id );
    NEW( integer, id, NoPos, 4);  
    OT.EnterObject( integer );  

    IT.Enter( "boolean", sym, id );
    NEW( boolean, id, NoPos, 1 ); 
    OT.EnterObject( boolean );  
    
    IT.Enter( "char", sym, id );
    NEW( character, id, NoPos, 1 );  
    OT.EnterObject( character );  

    IT.Enter( "false", sym, id );  
    NEW( con, id, NoPos, boolean, 0 );  
    OT.EnterObject( con );  

    IT.Enter( "true", sym, id );  
    NEW( con, id, NoPos, boolean, 1 );  
    OT.EnterObject( con );  
  
    NEW( string, NoId, NoPos, 0 ); 
  END Initialize;
  

END PL5Objects.