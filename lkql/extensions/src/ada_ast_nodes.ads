with LKQL.AST_Nodes; use LKQL.AST_Nodes;

with Libadalang.Analysis; use Libadalang.Analysis;
with Libadalang.Common;

with Langkit_Support.Text; use Langkit_Support.Text;

with Ada.Containers; use Ada.Containers;
with GNATCOLL.Utils; use GNATCOLL.Utils;

package Ada_AST_Nodes is

   subtype Node_Type_Id is Libadalang.Common.Node_Type_Id;

   type Ada_AST_Node is new AST_Node with record
      Node : Ada_Node;
   end record;

   type Ada_AST_Node_Access is access all Ada_AST_Node;

   overriding function "=" (Left, Right : Ada_AST_Node) return Boolean is
     (Left.Node = Right.Node);

   overriding function Hash (Node : Ada_AST_Node) return Hash_Type is
     (Hash (Node.Node));

   overriding function Text_Image (Node : Ada_AST_Node) return Text_Type is
      (To_Text (Node.Node.Image));

   overriding function Kind_Name (Node : Ada_AST_Node) return String is
     (Kind_Name (Node.Node));

   overriding function Is_Null_Node (Node : Ada_AST_Node) return Boolean is
     (Node.Node.Is_Null);

   overriding function Children_Count (Node : Ada_AST_Node) return Natural is
     (Node.Node.Children_Count);

   function Get_Node_Type_Id (Node : Ada_AST_Node) return Node_Type_Id;
   --  Return the ``Node_Type_Id`` of ``Node``

   overriding function Nth_Child
     (Node : Ada_AST_Node; N : Positive) return Ada_AST_Node
   is
     (Ada_AST_Node'(Node => Node.Node.Child (N)));

   overriding function Matches_Kind_Name
     (Node : Ada_AST_Node; Kind_Name : String) return Boolean;

   overriding function Is_Field_Name
     (Node : Ada_AST_Node; Name : Text_Type) return Boolean;

   overriding function Is_Property_Name
     (Node : Ada_AST_Node; Name : Text_Type) return Boolean;

   overriding function Access_Field
     (Node : Ada_AST_Node; Field : Text_Type) return Introspection_Value;

   overriding function Property_Arity
     (Node : Ada_AST_Node; Property_Name : Text_Type) return Natural;

   overriding function Default_Arg_Value (Node          : Ada_AST_Node;
                                          Property_Name : Text_Type;
                                          Arg_Position  : Positive)
                                          return Introspection_Value;

   function Evaluate_Property
     (Node          : Ada_AST_Node;
      Property_Name : Text_Type;
      Arguments     : Introspection_Value_Array)
      return Introspection_Value;

   function Make_Ada_AST_Node (Node : Ada_Node) return AST_Node_Rc
   is (Make_AST_Node_Rc (Ada_AST_Node'(Node => Node)));

   function Kind_Names return Unbounded_String_Array;
   --  List of all the node kinds' names

   function Kind (Name : String) return Node_Type_Id;
   --  Return the ``Node_Type_Id`` for a given ``Name``

end Ada_AST_Nodes;
