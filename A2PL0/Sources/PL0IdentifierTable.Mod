MODULE PL0IdentifierTable;   (* g.f.   21.3.03  *)
  
IMPORT  G := PL0Global, Strings;

TYPE
  Symbol = G.Symbol;  Identifier = G.Identifier; String = G.String; 

CONST  TableSize* = 293;  (* size of identifier table,  
                should be a prime number if hashing is used !  *)

VAR  
  Ident: Symbol;   (* scanner symbol 'Ident' *)
  
  table: ARRAY TableSize OF RECORD 
      name: String;   
      sym: Symbol;   (* associated symbol *)
  END;  
  kwBorder, lastId: INTEGER;  


  PROCEDURE Diff( CONST s1, s2: ARRAY OF CHAR ): INTEGER;  
  VAR i: INTEGER;  tch: CHAR;
  BEGIN 
    i := 0;  tch := s1[0];
    WHILE (tch = s2[i]) & (tch # 0X) DO  INC( i );  tch := s1[i]  END;
    RETURN ORD( tch ) - ORD( s2[i] );
  END Diff;  


  PROCEDURE Enter*( CONST name: ARRAY OF CHAR;  VAR sym: Symbol; VAR id: Identifier );  
  VAR len: SIZE; d, i, lo, hi, m: INTEGER; 
  BEGIN 
    (* check if name is a keyword *)
    lo := 0;  hi := kwBorder;  
    REPEAT 
      m := (lo + hi) DIV 2;  d := Diff( name, table[m].name^ );  
      IF d = 0 THEN  
        (* 'name' is a key word *)  sym := table[m].sym;  RETURN   
      END;
      IF d <= 0 THEN  hi := m - 1  ELSE  lo := m + 1  END 
    UNTIL lo > hi;  
    
    (* name is not a keyword, check if it is already in table *)
    sym := Ident;  
    FOR i := kwBorder + 1 TO lastId DO 
      IF name = table[i].name^ THEN  id := i;  RETURN  END 
    END;  
    
    (* name is new, append it to table *)
    IF lastId > (TableSize - 2) THEN  
      G.FatalError( "identifier table overflow") 
    END;  
    INC( lastId );  
    len := Strings.Length( name );
    NEW( table[lastId].name, len + 1 );  COPY( name, table[lastId].name^ );
    table[lastId].sym := Ident;  
    id := lastId
  END Enter;  


  (* keywords must be entered in alphabetical order (binary serach) *)
  PROCEDURE EnterKeyword*( CONST name: ARRAY OF CHAR;  sym: Symbol );  
  VAR len: SIZE;  
  BEGIN 
    len := Strings.Length( name );
    INC( kwBorder );
    NEW( table[kwBorder].name, len + 1 );  COPY( name, table[kwBorder].name^ );
    table[kwBorder].sym := sym;
    lastId := kwBorder;
  END EnterKeyword;  
  
  
  PROCEDURE GetIdString*( id: Identifier; VAR name: ARRAY OF CHAR );  
  BEGIN 
    IF (id < 0) OR (table[id].name = NIL) THEN
      COPY( "no name", name )
    ELSE
      COPY( table[id].name^, name )
    END;
  END GetIdString;  
  
  
  PROCEDURE Initialize*( identifierSymbol: Symbol );  
  VAR i: INTEGER;
  BEGIN 
    Ident := identifierSymbol;
    kwBorder := -1;  lastId := -1;  
    FOR i := 0 TO TableSize - 1 DO  table[i].name := NIL  END;  
  END Initialize;  

END PL0IdentifierTable.