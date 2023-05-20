MODULE PL0Scanner;   (* g.f. 21.3.03  *)

IMPORT Streams, G := PL0Global, IT := PL0IdentifierTable;

TYPE 
  Symbol* = G.Symbol;  
  IdNumber = G.Identifier;
  Textpos = G.Textpos;

CONST 
  (** Symbols: *)
  Null* = 0;  Period* = 1;  
  (* ---- start right part of dyadic expression ---- *)
  Times* = 2;  Div* = 3;  Plus* = 4;  Minus* = 5;  
  EQ* = 6;  NE* = 7;  LT* = 8;  LE* = 9;  GT* = 10;  GE* = 11;  And* = 12;  Or* = 13;  
  (* ---- end of expression ---- *)
  Comma* = 14;  RBracket* = 15;  LBracket* = 16;  RParen* = 17;  
  Then* = 18;  Do* = 19;  To* = 20;  Downto* = 21;  Becomes* = 22;  
  Array* = 23;  Of* = 24;  Colon* = 25;
  (* ---- start formula ---- *)
  LParen* = 26;  Odd* = 27;  Not* = 28;  Number* = 29;  Character* = 30; String* = 31;  
  (* ---- start Statement ---- *)
  Ident* = 32;  Call* = 33;  If* = 34;  While* = 35;  For* = 36; Read* = 37;  Write* = 38;  
  (* ---- end   Statement ---- *)
  Semicolon* = 39;  End* = 40;  Elsif* = 41;  Else* = 42;   
  (* ---- start declarations or statementpart ---- *)
  Begin* = 43;  Type* = 44;  Const* = 45;  Var* = 46;  Proc* = 47;  Module* =48; Eof* = 49;  
  
  MaxId* = IT.TableSize;


VAR 
  value-: INTEGER;     (* identifier number (Ident), constant value (Number, Char)  *)
  pos-: Textpos;      (* current position in source text      *)
  
  input: Streams.Reader;  
  
CONST 
  LF = 0AX;  CR = 0DX;  EOF = 00X;  

VAR 
  ch: CHAR;  currPos, startpos: Textpos;  currLine: INTEGER;  

  PROCEDURE nextCh;  
  BEGIN 
    IF input.Available() > 0 THEN 
      input.Char( ch );  INC( currPos );  
      IF (ch < " ") OR (ch >= 7FX) THEN 
        (* ignore control chars *)
        IF (ch = LF) OR (ch = CR) THEN  INC( currLine )  END;  
        ch := ' '
      END 
    ELSE ch := EOF
    END 
  END nextCh;  


  PROCEDURE ScanIdentifier( ): Symbol;  
  VAR k: INTEGER;  sym: Symbol;  id: IdNumber;
    string: ARRAY 32 OF CHAR;
  BEGIN 
    k := 0;  
    REPEAT  
      string[k] := ch; INC( k ); nextCh  
    UNTIL (ch < "0") OR ("9" < ch) & (CAP( ch ) < "A") OR ("Z" < CAP( ch ));  
    string[k] := 0X;  
    IT.Enter( string, sym, id );  
    IF sym = Ident THEN  value := id  END;
    RETURN sym
  END ScanIdentifier;  
  

  PROCEDURE ScanNumber( ): Symbol;  
  VAR i, j, d: INTEGER;  k: INTEGER;
    dig: ARRAY 31 OF CHAR;  
  BEGIN 
    i := 0;  
    REPEAT 
      dig[i] := ch; INC( i ); nextCh  
    UNTIL (ch < "0") OR ("9" < ch) & (CAP( ch ) < "A") OR ("Z" < CAP( ch ));  
    j := 0;  k := 0;  
    REPEAT 
      d := ORD( dig[j] ) - ORD( '0' );  
      IF (d < 10) & ((MAX( INTEGER ) - d) DIV 10 >= k) THEN  
        k := 10*k + d 
      ELSE  
        pos := currPos;  G.Error( "number is too large", pos );  k := 0 
      END;  
      INC( j )
    UNTIL j = i;  
    value := k;
    RETURN Number
  END ScanNumber;  

  
  (**  returns next symbol and  updates 'id', 'num', 'strp' and 'pos'  *)
  PROCEDURE Get*( VAR sym: Symbol );  

    PROCEDURE Comment;  
    BEGIN 
      nextCh;  
      REPEAT 
        WHILE (ch # "*") & (ch # EOF) DO  nextCh  END;  
        nextCh
      UNTIL (ch = ")") OR (ch = EOF);  
      nextCh;
    END Comment;  

  BEGIN 
    WHILE ch <= ' ' DO nextCh END;  
    
    startpos := currPos;
    CASE ch OF  (* ' ' <= ch < 80X *)
    EOF:  sym := Eof;  
    | "!":  sym := Write;  nextCh
    | "?":  sym := Read;  nextCh
    | "#":  sym := NE;  nextCh
    | "(": 
        nextCh;  
        IF ch = "*" THEN  Comment;  Get( sym ) 
        ELSE  sym := LParen 
        END 
    | ")":  sym := RParen;  nextCh
    | "*":  sym := Times;  nextCh
    | "+":  sym := Plus;  nextCh
    | ",":  sym := Comma;  nextCh
    | "-":  sym := Minus;  nextCh
    | ".":  sym := Period;  nextCh
    | "/":  sym := Div;  nextCh
    | ";":  sym := Semicolon;  nextCh
    | "[":  sym := LBracket;  nextCh
    | "]":  sym := RBracket;  nextCh
    | ":":  nextCh;  
        IF ch = "=" THEN  sym := Becomes;  nextCh ELSE sym := Colon END 
    | "<":  nextCh;  
        IF ch = "=" THEN sym := LE;  nextCh ELSE sym := LT END 
    | "=":  sym := EQ;  nextCh
    | ">":  nextCh;  
        IF ch = "=" THEN sym := GE;  nextCh ELSE sym := GT END 
    | "~":  sym := Not;  nextCh
    | "0".."9": 
        sym := ScanNumber( );  
    | "A".."Z", "a".."z": 
        sym := ScanIdentifier( )
    ELSE 
        sym := Null;  nextCh
    END;  
    pos := startpos;  
  END Get;  
  
  

  PROCEDURE Initialize*( source: Streams.Reader );  
  BEGIN 
    input := source;
    IT.Initialize( Ident );
    
    currPos := -1;  currLine := 1;  nextCh;  
    
    IT.EnterKeyword( "begin", Begin );  
    IT.EnterKeyword( "call", Call );
    IT.EnterKeyword( "const", Const );  
    IT.EnterKeyword( "do", Do );
    IT.EnterKeyword( "end", End ); 
    IT.EnterKeyword( "if", If );  
    IT.EnterKeyword( "module", Module );
    IT.EnterKeyword( "procedure", Proc );
    IT.EnterKeyword( "then", Then );  
    IT.EnterKeyword( "var", Var );
    IT.EnterKeyword( "while", While );

  END Initialize;  

END PL0Scanner.