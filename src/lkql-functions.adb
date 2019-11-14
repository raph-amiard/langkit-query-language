with GNATCOLL.Traces; use GNATCOLL.Traces;

with LKQL.Evaluation;     use LKQL.Evaluation;
with LKQL.Error_Handling; use LKQL.Error_Handling;

with Langkit_Support.Text; use Langkit_Support.Text;

with Ada.Strings.Wide_Wide_Unbounded; use Ada.Strings.Wide_Wide_Unbounded;
with Ada.Strings.Wide_Wide_Unbounded.Wide_Wide_Text_IO;
use Ada.Strings.Wide_Wide_Unbounded.Wide_Wide_Text_IO;

package body LKQL.Functions is

   -------------------
   -- Eval_Fun_Call --
   -------------------

   function Eval_Fun_Call
     (Ctx : Eval_Context; Call : L.Fun_Call) return Primitive
   is
   begin
      return Ret : Primitive do
         if Eval_Trace.Active then
            GNATCOLL.Traces.Trace
              (Eval_Trace,
               "Evaluating call " & Call.Short_Image & ", " & Call.Debug_Text);

            Eval_Trace.Increase_Indent;
         end if;

         Ret :=
           (if Call.P_Is_Builtin_Call
            then Eval_Builtin_Call (Ctx, Call)
            else Eval_User_Fun_Call (Ctx, Call, Call.P_Called_Function));

         if Eval_Trace.Active then
            Eval_Trace.Decrease_Indent;
            GNATCOLL.Traces.Trace
              (Eval_Trace,
               "Result : " & Image (To_Text (To_Unbounded_Text (Ret))));
         end if;
      end return;
   end Eval_Fun_Call;

   ------------------------
   -- Eval_User_Fun_Call --
   ------------------------

   function Eval_User_Fun_Call (Ctx  : Eval_Context;
                                Call : L.Fun_Call;
                                Def  : L.Fun_Decl) return Primitive
   is
      Args_Bindings : constant Environment_Map :=
        Eval_Arguments (Ctx, Call.P_Resolved_Arguments);
      Fun_Ctx       : constant Eval_Context :=
        (if Ctx.Is_Root_Context then Ctx else Ctx.Parent_Context);
      use String_Value_Maps;
   begin
      if Eval_Trace.Active then
         Eval_Trace.Decrease_Indent;
         for El in Args_Bindings.Iterate loop
            Eval_Trace.Trace
              ("Arg """ & Image (To_Text (Key (El))) & """ = "
               & Image (To_Text (To_Unbounded_Text (Element (El)))));
         end loop;
         Eval_Trace.Increase_Indent;
      end if;
      return Eval
        (Fun_Ctx, Def.F_Body_Expr, Local_Bindings => Args_Bindings);
   end Eval_User_Fun_Call;

   --------------------
   -- Eval_Arguments --
   --------------------

   function Eval_Arguments (Ctx       : Eval_Context;
                            Arguments : L.Named_Arg_Array)
                            return Environment_Map
   is
      Args_Bindings : Environment_Map;
   begin
      for Arg of Arguments loop
         declare
            Arg_Name  : constant Unbounded_Text_Type :=
              To_Unbounded_Text (Arg.P_Name.Text);
            Arg_Value : constant Primitive := Eval (Ctx, Arg.F_Expr);
         begin
            Args_Bindings.Insert (Arg_Name, Arg_Value);
         end;
      end loop;

      return Args_Bindings;
   end Eval_Arguments;

   -----------------------
   -- Eval_Builtin_Call --
   -----------------------

   function Eval_Builtin_Call
     (Ctx : Eval_Context; Call : L.Fun_Call) return Primitive
   is
   begin
      if Call.P_Arity /= 1 then
         Raise_Invalid_Arity (Ctx, 1, Call.F_Arguments);
      end if;

      if Call.F_Name.Text = "print" then
         return Eval_Print (Ctx, Call.F_Arguments.List_Child (1).F_Expr);
      elsif Call.F_Name.Text = "debug" then
         return Eval_Debug (Ctx, Call.F_Arguments.List_Child (1).F_Expr);
      end if;

      Raise_Unknown_Symbol (Ctx, Call.F_Name);
   end Eval_Builtin_Call;

   ----------------
   -- Eval_Print --
   ----------------

   function Eval_Print (Ctx : Eval_Context; Expr : L.Expr) return Primitive is
   begin
      Display (Eval (Ctx, Expr));
      return Make_Unit_Primitive;
   end Eval_Print;

   ----------------
   -- Eval_Debug --
   ----------------

   function Eval_Debug (Ctx : Eval_Context; Node : L.Expr) return Primitive is
      Code  : constant Text_Type := Node.Text;
      Value : constant Primitive := Eval (Ctx, Node);
      Message : constant Unbounded_Text_Type :=
        Code & " = " & To_Unbounded_Text (Value);
   begin
      Put_Line (Message);
      return Value;
   end Eval_Debug;

end LKQL.Functions;
