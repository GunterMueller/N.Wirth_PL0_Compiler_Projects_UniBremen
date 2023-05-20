MODULE PL3Scanner;   (* g.f. 21.3.03  *)

IMPORT Streams, G := PL3Global, IT := PL3IdentifierTable;

TYPE 
  Symbol = G.Symbol;  (* Scanner symbol *)
  Identifier = G.Identifier;  (* identifier numbers *)
  
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
  LParen* = 26;  Odd* = 27;  Not* = 28;  Len* = 29; Number* = 30;  Character* = 31; String* = 32;  
  (* ---- start Statement ---- *)
  Ident* = 33;  Call* = 34;  If* = 35;  While* = 36;  For* = 37; Read* = 38;  Write* = 39;  Return* = 40;
  (* ---- end   Statement ---- *)
  Semicolon* = 41;  End* = 42;  Elsif* = 43;  Else* = 44;   
  (* ---- start declarations or statementpart ---- *)
  Begin* = 45;  Type* = 46;  Const* = 47;  Var* = 48;  Proc* = 49;  Module* =50; Eof* = 51;  
  
  MaxId* = IT.TableSize;

VAR
  value-: INTEGER;         (* identifier number (Ident) or constant value (Number, Char)  *)
  value2-: G.String;      (* string constant   *)
  pos-: G.Textpos;      (* current position in source text      *)
  
  input: Streams.Reader;  
  
CONST 
  LF = 0AX;  CR = 0DX;  HT = 09X;  EOF = 00X;  

VAR 
  ch: CHAR;  currPos, startpos: G.Textpos;  currLine: INTEGER;  

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

  PROCEDURE ScanString(  ): Symbol;  
  VAR startline, i: INTEGER;  tch: CHAR;  
    string: ARRAY 120 OF CHAR;
    str: G.String
  BEGIN 
    startline := currLine;  i := 0;  tch := ch;  nextCh;  
    REPEAT 
      IF ch = "\" THEN 
        nextCh;  
        IF ch = "n" THEN ch := LF
        ELSIF ch = "t" THEN ch := HT
        ELSIF (ch < ' ') OR (ch > '~') THEN 
          G.Error( "illegal character", currPos )
        END 
      END;  
      string[i] := ch;  INC( i );  nextCh
    UNTIL (ch = tch) OR (currLine # startline);  
    IF currLine = startline THEN  
      IF i = 1 THEN
        value := ORD( string[0] );  
        nextCh;
        RETURN Character
      END;
      NEW( str, i + 1 );  COPY( string, str^ );
      
      nextCh;  
    ELSE 
      G.Error( "string must terminate in same line", currPos );
      NEW( str, 2 );  str^ := ""
    END;
    value2 := str;
    RETURN String
  END ScanString;  

  PROCEDURE ScanIdentifier(  ): Symbol;  
  VAR k: INTEGER;  sym: Symbol;  id: Identifier;
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
  VAR i, j, d, k: INTEGER; 
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
        pos := currPos;  G.Error( "number istoo large", pos );  k := 0 
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
    CASE ch OF  (* " " <= ch < 177C *)
    EOF:  sym := Eof;  
    | "!":  sym := Write;  nextCh
    | "?":  sym := Read;  nextCh
    | '"', "'":   
        sym := ScanString(  )
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
    | "&":  sym := And;  nextCh
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
    
    IT.EnterKeyword( "array", Array );
    IT.EnterKeyword( "begin", Begin );  
  (*  IT.EnterKeyword( "call", Call );  *)
    IT.EnterKeyword( "const", Const );  
    IT.EnterKeyword( "do", Do ); 
    IT.EnterKeyword( "downto", Downto ); 
    IT.EnterKeyword( "else", Else );
    IT.EnterKeyword( "elsif", Elsif );
    IT.EnterKeyword( "end", End ); 
    IT.EnterKeyword( "for", For );
    IT.EnterKeyword( "if", If );  
    IT.EnterKeyword( "len", Len );
    IT.EnterKeyword( "module", Module );
    IT.EnterKeyword( "odd", Odd ); 
    IT.EnterKeyword( "of", Of );  
    IT.EnterKeyword( "or", Or );  
    IT.EnterKeyword( "procedure", Proc );
    IT.EnterKeyword( "return", Return );
    IT.EnterKeyword( "then", Then );  
    IT.EnterKeyword( "to", To );
    IT.EnterKeyword( "type", Type );  
    IT.EnterKeyword( "var", Var );
    IT.EnterKeyword( "while", While );  
  END Initialize;  

END PL3Scanner.