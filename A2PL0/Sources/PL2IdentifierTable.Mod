MODULE PL2IdentifierTable;   (* g.f.  21.3.03  *)

IMPORT G := PL2Global, Strings;  

TYPE
  String = G.String;  Symbol = G.Symbol;  Identifier = G.Identifier;

CONST 
  TableSize* = 293;  (* size of identifier table,  
                should be a prime number if hashing is used !  *)

VAR   
  Ident: Symbol;  (* scanner symbol 'Ident' *)

  table: ARRAY TableSize OF RECORD 
      name: String;   
      sym: Symbol;  
  END;  
  
  PROCEDURE Hash( CONST name: ARRAY OF CHAR; len: INTEGER ): INTEGER;  
  BEGIN 
    RETURN (ORD( name[1] )*len + ORD( name[len-1] )) MOD TableSize
  END Hash;  


  PROCEDURE Enter*( CONST name: ARRAY OF CHAR;  VAR sym: Symbol; VAR id: Identifier );  
  VAR len, h, d: INTEGER;  str: String; 
  BEGIN 
    len := INTEGER( Strings.Length( name ) );
    h := Hash( name, len );  d := 1;  
    LOOP 
      IF table[h].name = NIL THEN  (* free position found *)
        NEW( str, len + 1 );  COPY( name, str^ );
        table[h].name := str;  
        table[h].sym := Ident;  EXIT 
      ELSIF name # table[h].name^ THEN  (* collision *)
        IF d >= TableSize THEN 
          G.FatalError( "hashtable overflow" );  
        END;  
        h := h + d;  d := d + 2;  
        IF h >= TableSize THEN  h := h - TableSize  END 
      ELSE 
        (* identifier is already stored *)
        EXIT 
      END;  
    END  (* loop *) ;  
    
    sym := table[h].sym;  id := INTEGER( h )
  END Enter;  

  PROCEDURE EnterKeyword*( CONST name: ARRAY OF CHAR;  sym: Symbol );  
  VAR id: Identifier; s: Symbol;  
  BEGIN 
    Enter( name, s, id );  table[id].sym := sym;  
  END EnterKeyword;  
  
  PROCEDURE GetIdString*( id: Identifier; VAR name: ARRAY OF CHAR );  
  BEGIN 
    IF (id < 0) OR (table[id].name = NIL) THEN
      COPY( "no name", name )
    ELSE
      COPY( table[id].name^, name )
    END;
  END GetIdString;  

  PROCEDURE Initialize-( IdentifierSymbol: Symbol );  
  VAR i: INTEGER;  
  BEGIN 
    Ident := IdentifierSymbol;
    FOR i := 0 TO TableSize - 1 DO  table[i].name := NIL  END;  
  END Initialize;  

END PL2IdentifierTable.