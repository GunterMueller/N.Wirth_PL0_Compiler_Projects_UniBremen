MODULE PL4Variables;   (* GF   9.12.04  *)

IMPORT G := PL4Global, 
    OT := PL4ObjectTable, O := PL4Objects, 
    Nodes := PL4Nodes, Types := PL4Types;

TYPE 
  Textpos = G.Textpos;  Identifier = G.Identifier;
  
  Node = Nodes.Node;  DeclNode = Nodes.DeclNode; Property = Nodes.Property;
  
TYPE 
  VarDeclNode* = OBJECT (DeclNode)
    VAR 
      name: Identifier;
      typeNode: Node;
      
  
      PROCEDURE Analyse*( VAR prop: Property; pass: INTEGER );
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
      (* nothing to do *)
      END Synthesize;
      
      
      PROCEDURE & Init*( pos: Textpos;  id: Identifier;  type: Node );  
      BEGIN  
        position := pos;  name := id;  typeNode := type
      END Init;
      
  END VarDeclNode;

          
END PL4Variables.