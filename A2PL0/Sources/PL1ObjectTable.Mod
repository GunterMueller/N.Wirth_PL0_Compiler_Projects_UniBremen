MODULE PL1ObjectTable;   (* g.f.   21.3.03   *)


(**  Object Table;  created by analysis   *)

IMPORT G := PL1Global;

CONST 
  NoName = -1;  NoPos = -1;  

TYPE 
  Object* = OBJECT 
    VAR 
      id-    : G.Identifier;  (* object name (if any) *)
      pos-  : G.Textpos;  (* position in source text where the obj was declared *)
      level-  : INTEGER;  
        
      next  : Object;

      
    PROCEDURE & InitObj*( name: G.Identifier;  p: G.Textpos );
    BEGIN  
      id := name;  pos := p;  next :=NIL
    END InitObj;
      
  END Object; 
  

  Head = OBJECT (Object)
    VAR 
      lastObj  : Object;  
      down    : Head
  END  Head;
  
  
VAR 
  curlev-: INTEGER; 
  topScope: Head;  

  PROCEDURE EnterObject*( obj: Object );  
  VAR h: Object;  
  BEGIN 
    (* first check for multiple definition *)
    h := topScope.next;  
    WHILE h # NIL DO 
      IF (h.id = obj.id) & (obj.id # NoName) THEN  
        G.Error( "identifier declared twice", obj.pos );  RETURN  
      END;  
      h := h.next
    END;  
    (* now enter new Object  *)
    obj.level := curlev;  topScope.lastObj.next := obj;  topScope.lastObj := obj 
  END EnterObject;  

  PROCEDURE FindDecl*( name: G.Identifier ): Object;  
  VAR hd: Head;  obj: Object;  
  BEGIN 
    hd := topScope;  
    WHILE hd # NIL DO  obj := hd.next;  
      WHILE obj # NIL DO 
        IF obj.id = name THEN  RETURN obj  ELSE  obj := obj.next  END 
      END;  
      hd := hd.down
    END;  
    RETURN NIL 
  END FindDecl;  

  PROCEDURE EnterBlock*( );  
  VAR hd: Head;  
  BEGIN 
    INC( curlev );  
    NEW( hd, NoName, NoPos  );  
    hd.lastObj := hd;  hd.down := topScope;  topScope := hd;  
  END EnterBlock;  

  PROCEDURE LeaveBlock*( );  
  BEGIN 
    topScope := topScope.down;  DEC( curlev );  
  END LeaveBlock;  

  PROCEDURE Initialize*;  
  VAR hd: Head;  
  BEGIN 
    NEW( hd, NoName, NoPos );  
    hd.next := NIL;  hd.lastObj := hd;  hd.down := NIL;  topScope := hd;  
    curlev := -1; 
  END Initialize;  

END PL1ObjectTable.