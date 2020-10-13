with Ada.Directories; use Ada.Directories;
with Ada.Text_IO;    use Ada.Text_IO;

with Ada_AST_Nodes; use Ada_AST_Nodes;

with Langkit_Support.Diagnostics; use Langkit_Support.Diagnostics;
with Langkit_Support.Diagnostics.Output;
with Langkit_Support.Text; use Langkit_Support.Text;

with LKQL.Errors;        use LKQL.Errors;
with LKQL.Evaluation;    use LKQL.Evaluation;
with LKQL.Eval_Contexts; use LKQL.Eval_Contexts;
with LKQL.Primitives;    use LKQL.Primitives;

with Libadalang.Project_Provider;

with GNAT.OS_Lib;
with GNATCOLL.Projects;

package body LKQL.Run is
   package GPR     renames GNATCOLL.Projects;
   package LAL_GPR renames Libadalang.Project_Provider;

   procedure Evaluate
     (Context : Eval_Context; LKQL_Script : L.LKQL_Node);
   --  Evaluate the script in the given context and display the error
   --  messages, if any.

   --------------
   -- Evaluate --
   --------------

   procedure Evaluate
     (Context : Eval_Context; LKQL_Script : L.LKQL_Node)
   is
      Ignore : Primitive;
   begin
      Ignore := Check_And_Eval (Context, LKQL_Script);
   exception
      when Stop_Evaluation_Error =>
         pragma Assert (Is_Error (Context.Last_Error),
                        "Stop Evaluation Error raised without adding the " &
                        "error to the evaluation context");

         if not Context.Error_Recovery_Enabled then
            declare
               N : L.LKQL_Node renames Context.Last_Error.AST_Node;
               D : constant Diagnostic := Langkit_Support.Diagnostics.Create
                 (N.Sloc_Range,
                  To_Text (Context.Last_Error.Short_Message));
            begin
               Output.Print_Diagnostic
                 (D, N.Unit, Simple_Name (N.Unit.Get_Filename));
            end;
         end if;
   end Evaluate;

   -------------------------
   -- Run_Against_Project --
   -------------------------

   procedure Run_Against_Project (LKQL_Script      : String;
                                  Project_Path     : String;
                                  Recovery_Enabled : Boolean := False)
   is
      Provider      : Unit_Provider_Reference;
      Ada_Context   : Analysis_Context;
      Env           : GPR.Project_Environment_Access;
      Project       : constant GPR.Project_Tree_Access := new GPR.Project_Tree;
      Ignore        : Primitive;
      Source_Files  : File_Array_Access;
      Project_File  : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create (+Project_Path);
   begin
      GPR.Initialize (Env);
      Project.Load (Project_File, Env);
      Provider :=
        LAL_GPR.Create_Project_Unit_Provider (Project, Env => Env);
      Ada_Context := Create_Context (Unit_Provider => Provider);
      Source_Files := Project.Root_Project.Source_Files (Recursive => False);
      Run_On_Files (LKQL_Script, Ada_Context, Source_Files, Recovery_Enabled);
      Unchecked_Free (Source_Files);
   end Run_Against_Project;

   ------------------
   -- Run_On_Files --
   ------------------

   procedure Run_On_Files (LKQL_Script      : String;
                           Ada_Context      : Analysis_Context;
                           Files            : File_Array_Access;
                           Recovery_Enabled : Boolean := False)
   is
      Ada_Unit            : Analysis_Unit;
      Interpreter_Context : Eval_Context;
      LKQL_Unit           : constant L.Analysis_Unit :=
        Make_LKQL_Unit (LKQL_Script);

   begin
      for F of Files.all loop
         Ada_Unit := Make_Ada_Unit (Ada_Context, F.Display_Full_Name);
         Interpreter_Context :=
           Make_Eval_Context (Make_Ada_AST_Node (Ada_Unit.Root),
                              Make_Ada_AST_Node (No_Ada_Node),
                              Err_Recovery => Recovery_Enabled);
         Put_Line (F.Display_Base_Name);
         Evaluate (Interpreter_Context, LKQL_Unit.Root);
         Interpreter_Context.Free_Eval_Context;
      end loop;
   end Run_On_Files;

   --------------------
   -- Make_LKQL_Unit --
   --------------------

   function Make_LKQL_Unit (Script_Path : String) return L.Analysis_Unit is
      Context : constant L.Analysis_Context := L.Create_Context;
      Unit    : constant L.Analysis_Unit :=
        Context.Get_From_File (Script_Path);
   begin
      if Unit.Has_Diagnostics then
         for D of Unit.Diagnostics loop
            Put_Line (Unit.Format_GNU_Diagnostic (D));
         end loop;
         GNAT.OS_Lib.OS_Exit (1);
      end if;

      return Unit;
   end Make_LKQL_Unit;

   -------------------
   -- Make_Ada_Unit --
   -------------------

   function Make_Ada_Unit
     (Context : Analysis_Context; Path : String) return Analysis_Unit
   is
      Unit : constant Analysis_Unit :=
        Context.Get_From_File (Path);
   begin
      if Unit.Has_Diagnostics then
         for D of Unit.Diagnostics loop
            Put_Line (Unit.Format_GNU_Diagnostic (D));
         end loop;

         return No_Analysis_Unit;
      end if;

      return Unit;
   end Make_Ada_Unit;

end LKQL.Run;