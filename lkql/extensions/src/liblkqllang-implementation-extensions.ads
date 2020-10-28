package Liblkqllang.Implementation.Extensions is

   function LKQL_Node_P_Prelude_Unit
     (Node : Bare_LKQL_Node) return Internal_Unit;

   function LKQL_Node_P_Interp_Init_From_Project
     (Node : Bare_LKQL_Node; Project_File : Character_Type_Array_Access)
      return Boolean;

 function LKQL_Node_P_Interp_Eval (Node : Bare_LKQL_Node) return Symbol_Type;

end Liblkqllang.Implementation.Extensions;

