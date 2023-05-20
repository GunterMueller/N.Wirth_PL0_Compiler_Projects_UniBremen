MODULE PL5ObjectTable;   (* g.f.  21.3.03   *)

(*  object table, created during progam analysis 
  latticed implementation
*)

IMPORT G := PL5Global, S := PL5Scanner;

CONST 
  MaxLev = G.MaxNestingLevel;  (* max. nesting level of procedures *)

TYPE 
  Object* = OBJECT 
    VAR
      id-      : G.Identifier;  (* object name (if any) *)
      pos-    : G.Textpos;  (* position in source text where the obj was declared *)
      level-    : INTEGER;  
      
      hidden    : Object;     (* covered obj.  with same name *)
      next    : Object;     (* next object in the same chain *)
      
      PROCEDURE & InitObj*( name: G.Identifier; p: G.Textpos );  
      BEGIN 
        id := name;  pos := p;  level := curlev
      END InitObj;  

  END Object;  
  

VAR 
  curlev-: INTEGER;  

  chains: ARRAY MaxLev OF Object;  
  table: ARRAY S.MaxId OF Object;  
    
  
  PROCEDURE EnterObject*( obj: Object );  
  VAR hidden: Object;  
  BEGIN 
    hidden := table[obj.id];  
    IF (hidden # NIL ) & (hidden.level = curlev) THEN  
      G.Error( "identifier declared twice", obj.pos )
    ELSE
      (* enter new Object  *)
      obj.level := curlev;  table[obj.id] := obj;  obj.hidden := hidden;  
      IF curlev >= 0 THEN  obj.next := chains[curlev];  chains[curlev] := obj  END  
    END;  
  END EnterObject;  

  PROCEDURE FindDecl*( id: G.Identifier ): Object;  
  BEGIN 
    RETURN table[id] 
  END FindDecl;  

  PROCEDURE EnterBlock-;  
  BEGIN 
    INC( curlev ) 
  END EnterBlock;  

  PROCEDURE LeaveBlock-;  
  VAR obj: Object;  
  BEGIN 
    obj := chains[curlev];  
    WHILE obj # NIL DO  table[obj.id] := obj.hidden;  obj := obj.next  END;  
    chains[curlev] := NIL;  DEC( curlev );  
  END LeaveBlock;  
  
  
  PROCEDURE Initialize-;
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO MaxLev - 1 DO  chains[i] := NIL  END;  
    FOR i := 0 TO S.MaxId - 1 DO  table[i] := NIL  END;  
    
    curlev := -1;  (* nesting level of predeclared types and constants *)
  END Initialize
  

END PL5ObjectTable.