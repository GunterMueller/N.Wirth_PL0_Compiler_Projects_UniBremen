MODULE PL0Objects;   (* g.f.  21.3.03  *)

IMPORT G := PL0Global, IT := PL0IdentifierTable, OT := PL0ObjectTable;

TYPE 
  Object* = OT.Object;  
  Identifier = G.Identifier;  Textpos = G.Textpos;

CONST
  NoId = -1;  NoPos = -1;  NoAddr = -1;
  
TYPE
  Type* = OBJECT (Object) 
    VAR  
      size*: INTEGER;
      okflag*: BOOLEAN;  (* TRUE if an error has been reported *)
      
      PROCEDURE & Init*( id: Identifier; pos: Textpos; bytes: INTEGER );
      BEGIN
        InitObj( id, pos );
        size := bytes;  okflag := FALSE
      END Init;
      
  END Type;  
  
  
  Variable* = OBJECT (Object)
    VAR  
      type-    : Type;  
      addr-    : INTEGER;
      
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
      
      PROCEDURE &Init*( id: Identifier; pos: Textpos;  t:Type;  val: INTEGER );
      BEGIN
        InitObj( id, pos );
        type := t;  value := val;  addr := NoAddr
      END Init;
      
  END Constant;  
  
  
  StringConstant* = OBJECT (Object)
    VAR  
      type-  : Type;
      value-  : G.String;
      addr*  : INTEGER;    (* >= 0 if consstant has been allocated in RAM *)
      
      PROCEDURE &Init*( id: Identifier; pos: Textpos;  val: G.String );
      BEGIN
        InitObj( id, pos );
        type := string;  value := val;  addr := NoAddr
      END Init;
      
  END StringConstant; 
  
  
  
  Procedure* = OBJECT (Object)
    VAR
      waddr*: INTEGER;     (* word address of procedure entry *)
    (*  params-: Parameter;  
      parspace-: INTEGER;   (* stack space for parameters *)    *)
      
      PROCEDURE &InitProc*( id: Identifier; pos: Textpos(*; par: Parameter; space: INTEGER*) );
      BEGIN
        InitObj( id, pos );
      (*  params := par;  parspace := space;   *)
        waddr := NoAddr
      END InitProc;
      
  END Procedure;  
  
VAR 
  integer*, boolean*, character*, string*: Type;   (* predefined types *)
  
  
  PROCEDURE Initialize*;
  VAR 
    sym: G.Symbol;  id: Identifier; 
  BEGIN
    OT.Initialize;
    
    (* create predefined types and constants *)
    IT.Enter( "integer", sym, id );
    NEW( integer, id, NoPos, 4);  
    OT.EnterObject( integer );  

    NEW( boolean, NoId, NoPos, 1 ); 
    NEW( character, NoId, NoPos, 1 );  
    NEW( string, NoId, NoPos, 0 ); 
  END Initialize;
  

END PL0Objects.