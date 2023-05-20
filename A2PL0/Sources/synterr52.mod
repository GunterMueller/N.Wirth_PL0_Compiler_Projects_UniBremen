module syntaxerrors52;

  procedure p1( var a,b,c d: integer );  (* ein Komma fehlt*)
  begin
  end p1;

  procedure p2( var : integer );     (* Bezeichner fehlt  *)
  begin
  end p2;

  procedure p3( var a: integer; );   (* ';' zuviel    *)
  begin
  end p3;

  procedure p4( var a: ; b: c );     (* Typbezeichner fehlt  *)
  begin
  end p4;

  procedure p5( a,b,: T; b: c );     (*  Bezeichner fehlt  *)
  begin
  end p5;

begin 
end syntaxerrors52;        (* ';' statt '.'  *)


PL5.Compile synterr52.mod ~
