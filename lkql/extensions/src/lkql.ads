with Liblkqllang.Analysis;
with Liblkqllang.Common;

package LKQL is
   package L renames Liblkqllang.Analysis;
   package LCO renames Liblkqllang.Common;

   function Node_Text (Self : L.LKQL_Node'Class) return String;
   --  Helper debug function. Return the text of a node as a string.
end LKQL;
