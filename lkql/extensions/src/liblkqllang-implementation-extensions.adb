with Liblkqllang.Prelude;
with Libadalang.Helpers; use Libadalang.Helpers;
with Libadalang.Analysis; use Libadalang.Analysis;

with Langkit_Support.Text; use Langkit_Support.Text;
with Langkit_Support.Symbols; use Langkit_Support.Symbols;
with GNATCOLL.Projects; use GNATCOLL.Projects;
with LKQL.Eval_Contexts; use LKQL.Eval_Contexts;

with Ada_AST_Nodes; use Ada_AST_Nodes;
with LKQL.Evaluation; use LKQL.Evaluation;
with LKQL.Primitives; use LKQL.Primitives;
with Liblkqllang.Public_Converters;
with Ada.Text_IO; use Ada.Text_IO;

package body Liblkqllang.Implementation.Extensions is

   --  TODO: for the moment the state is global, we need to store it in the
   --  LKQL context.
   Ctx      : Libadalang.Analysis.Analysis_Context;
   Files    : String_Vectors.Vector;
   LKQL_Ctx : Eval_Context;
   Init     : Boolean := False;

   -----------
   -- Units --
   -----------

   function Units return Unit_Vectors.Vector is
      Ret : Unit_Vectors.Vector;
   begin
      for F of Files loop
         Ret.Append_One (Ctx.Get_From_File (To_String (F)));
      end loop;
      return Ret;
   end Units;

   ------------------------------
   -- LKQL_Node_P_Prelude_Unit --
   ------------------------------

   function LKQL_Node_P_Prelude_Unit
     (Node : Bare_LKQL_Node) return Internal_Unit
   is
     (Liblkqllang.Prelude.Prelude_Unit);

   ------------------------------------------
   -- LKQL_Node_P_Interp_Init_From_Project --
   ------------------------------------------

   function LKQL_Node_P_Interp_Init_From_Project
     (Node         : Bare_LKQL_Node;
      Project_File : Character_Type_Array_Access) return Boolean
   is
      Project : Project_Tree_Access;
      Env     : Project_Environment_Access;

      UFP     : Unit_Provider_Reference;
   begin
      if Init then
         return False;
      end if;

      Libadalang.Helpers.Load_Project
        (Image (Project_File.Items), Project => Project, Env => Env);

      List_Sources_From_Project (Project.all, False, Files);

      UFP := Project_To_Provider (Project);
      Ctx := Create_Context (Charset => "utf-8", Unit_Provider => UFP);

      --  TODO: That's a really strange thing today, the LKQL context contains
      --  only one unit ... We need to fix that.
      LKQL_Ctx := Make_Eval_Context
        (Make_Ada_AST_Node (Units.Element (1).Root),
         Make_Ada_AST_Node (No_Ada_Node));

      Init := True;
      return True;
   end LKQL_Node_P_Interp_Init_From_Project;

   -----------------------------
   -- LKQL_Node_P_Interp_Eval --
   -----------------------------

   function LKQL_Node_P_Interp_Eval (Node : Bare_LKQL_Node) return Symbol_Type
   is
   begin
      return Get_Symbol
        (Node.Unit.Context.Symbols,
         Find
           (Node.Unit.Context.Symbols,
            To_Text
              (To_Unbounded_Text
                   (Check_And_Eval
                        (LKQL_Ctx, Public_Converters.Wrap_Node (Node))))));
   end LKQL_Node_P_Interp_Eval;

end Liblkqllang.Implementation.Extensions;
