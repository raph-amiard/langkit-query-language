with Ada.Containers; use Ada.Containers;

package body LKQL.Depth_Nodes is

   ----------
   -- Hash --
   ----------

   function Hash (Value : Depth_Node) return Ada.Containers.Hash_Type is
      Node_Hash : constant Hash_Type :=
        Hash_Rc (Value.Node);
      Depth_hash : constant Hash_Type := Hash_Type (Value.Depth);
   begin
      return Node_Hash xor Depth_hash;
   end Hash;

end LKQL.Depth_Nodes;
