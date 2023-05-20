MODULE PL2Variables;   (* GF   9.12.04  *)

IMPORT G := PL2Global, 
    OT := PL2ObjectTable, O := PL2Objects, 
    Nodes := PL2Nodes, Types := PL2Types;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  
  Node = Nodes.Node;  DeclNode = Nodes.DeclNode; Property = Nodes.Property;
  
TYPE 
  VarDeclNode* = OBJECT (DeclNode)
    VAR 
      name: Identifier;
      typeNode: Node;
      
  
      PROCEDURE Analyse*( VAR prop: Property );
      VAR 
        varObj: O.Variable;  type: O.Type;  size: INTEGER;
      BEGIN 
        type := Types.GetType( typeNode );
        size := type.size;
        INC( size, (-size) MOD 4 );  (* word alignment ! *)
        INC( prop.varspace, size );  
        NEW( varObj, name, position, type, -prop.varspace );
        OT.EnterObject( varObj );
      END Analyse; 
      
      PROCEDURE Synthesize;
      BEGIN
        (* nothing to do *)
      END Synthesize;
      
      
      PROCEDURE & Init*( pos: Textpos;  id: Identifier;  type: Node );  
      BEGIN  
        position := pos;  name := id;  typeNode := type
      END Init;
      
  END VarDeclNode;

          
END PL2Variables.