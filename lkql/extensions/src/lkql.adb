with Langkit_Support.Text; use Langkit_Support.Text;

package body LKQL is
   ---------------
   -- Node_Text --
   ---------------

   function Node_Text (Self : L.LKQL_Node'Class) return String is
   begin
      return Image (L.Text (Self));
   end Node_Text;
end LKQL;
