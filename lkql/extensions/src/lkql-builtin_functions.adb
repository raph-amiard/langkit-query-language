------------------------------------------------------------------------------
--                                                                          --
--                                   LKQL                                   --
--                                                                          --
--                     Copyright (C) 2019-2021, AdaCore                     --
--                                                                          --
-- LKQL is free software;  you can redistribute it and/or modify  it        --
-- under terms of the GNU General Public License  as published by the Free  --
-- Software Foundation;  either version 3,  or (at your option)  any later  --
-- version.   This  software  is distributed in the hope that it  will  be  --
-- useful but  WITHOUT ANY WARRANTY;  without even the implied warranty of  --
-- MERCHANTABILITY  or  FITNESS  FOR  A PARTICULAR PURPOSE.                 --
--                                                                          --
-- As a special  exception  under  Section 7  of  GPL  version 3,  you are  --
-- granted additional  permissions described in the  GCC  Runtime  Library  --
-- Exception, version 3.1, as published by the Free Software Foundation.    --
--                                                                          --
-- You should have received a copy of the GNU General Public License and a  --
-- copy of the GCC Runtime Library Exception along with this program;  see  --
-- the files COPYING3 and COPYING.RUNTIME respectively.  If not, see        --
-- <http://www.gnu.org/licenses/>.                                          --
------------------------------------------------------------------------------

with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Wide_Wide_Text_IO; use Ada.Wide_Wide_Text_IO;

with Langkit_Support.Text; use Langkit_Support.Text;

with LKQL.AST_Nodes;

with Ada_AST_Nodes; use Ada_AST_Nodes;
with LKQL.Evaluation; use LKQL.Evaluation;

package body LKQL.Builtin_Functions is
   function Create
     (Name      : Text_Type;
      Params    : Builtin_Function_Profile;
      Fn_Access : Native_Function_Access;
      Doc       : Text_Type) return Builtin_Function;
   --  Create a builtin function given a name, a description of its
   --  parameters and an access to the native code that implements it.

   function Param
     (Name          : Text_Type;
      Expected_Kind : Base_Primitive_Kind := No_Kind)
      return Builtin_Param_Description;
   --  Create a builtin parameter description given its name and its expected
   --  kind. The expected kind can be "No_Kind" if no particular kind is
   --  expected. This parameter will not have a default value.

   function Param
     (Name          : Text_Type;
      Expected_Kind : Base_Primitive_Kind;
      Default_Value : Primitive)
      return Builtin_Param_Description;
   --  Create a builtin parameter description given its name, expected
   --  kind and default value. The expected kind can be "No_Kind" if no
   --  particular kind is expected.

   ------------
   -- Create --
   ------------

   function Create
     (Name      : Text_Type;
      Params    : Builtin_Function_Profile;
      Fn_Access : Native_Function_Access;
      Doc       : Text_Type) return Builtin_Function
   is
   begin
      return new Builtin_Function_Description'
        (N         => Params'Length,
         Name      => To_Unbounded_Text (Name),
         Params    => Params,
         Fn_Access => Fn_Access,
         Doc       => To_Unbounded_Text (Doc));
   end Create;

   -----------
   -- Param --
   -----------

   function Param
     (Name          : Text_Type;
      Expected_Kind : Base_Primitive_Kind := No_Kind)
      return Builtin_Param_Description
   is
   begin
      return Builtin_Param_Description'
        (Name          => To_Unbounded_Text (Name),
         Expected_Kind => Expected_Kind,
         Default_Value => Primitive_Options.None);
   end Param;

   -----------
   -- Param --
   -----------

   function Param
     (Name          : Text_Type;
      Expected_Kind : Base_Primitive_Kind;
      Default_Value : Primitive)
      return Builtin_Param_Description
   is
   begin
      return Builtin_Param_Description'
        (Name          => To_Unbounded_Text (Name),
         Expected_Kind => Expected_Kind,
         Default_Value => Primitive_Options.To_Option (Default_Value));
   end Param;

   ----------------
   -- Eval_Print --
   ----------------

   function Eval_Print
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
   begin
      Display (Args (1), Bool_Val (Args (2)));
      return Make_Unit_Primitive;
   end Eval_Print;

   ------------------
   -- Eval_To_List --
   ------------------

   function Eval_To_List
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
   begin
      return To_List (Args (1).Get.Iter_Val.all);
   end Eval_To_List;

   ---------------
   -- Eval_Dump --
   ---------------

   function Eval_Dump
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
   begin
      Ada_AST_Node (Args (1).Get.Node_Val.Unchecked_Get.all).Node.Print;
      return Make_Unit_Primitive;
   end Eval_Dump;

   ----------------
   -- Eval_Image --
   ----------------

   function Eval_Image
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
   begin
      return To_Primitive (To_Unbounded_Text (Args (1)));
   end Eval_Image;

   -------------------------
   -- Eval_Children_Count --
   -------------------------

   function Eval_Children_Count
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
      Node : constant AST_Nodes.AST_Node'Class :=
         Node_Val (Args (1)).Unchecked_Get.all;
   begin
      return To_Primitive
        (if Node.Is_Null_Node then 0 else Node.Children_Count);
   end Eval_Children_Count;

   ---------------
   -- Eval_Text --
   ---------------

   function Eval_Text
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
      Node : constant AST_Nodes.AST_Node'Class :=
         Node_Val (Args (1)).Unchecked_Get.all;
   begin
      return To_Primitive (if Node.Is_Null_Node then "" else Node.Text);
   end Eval_Text;

   -----------------
   -- Starts_With --
   -----------------

   function Eval_Starts_With
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
      use Ada.Strings.Wide_Wide_Unbounded;

      Str    : constant Unbounded_Text_Type := Str_Val (Args (1));
      Prefix : constant Unbounded_Text_Type := Str_Val (Args (2));
      Len    : constant Natural := Length (Prefix);
   begin
      return To_Primitive
         (Length (Str) >= Len
          and then Unbounded_Slice (Str, 1, Len) = Prefix);
   end Eval_Starts_With;

   ---------------
   -- Ends_With --
   ---------------

   function Eval_Ends_With
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      pragma Unreferenced (Ctx);
      use Ada.Strings.Wide_Wide_Unbounded;

      Str    : constant Unbounded_Text_Type := Str_Val (Args (1));
      Suffix : constant Unbounded_Text_Type := Str_Val (Args (2));

      Str_Len    : constant Natural := Length (Str);
      Suffix_Len : constant Natural := Length (Suffix);
   begin
      return To_Primitive
         (Str_Len >= Suffix_Len
          and then Unbounded_Slice
            (Str, Str_Len - Suffix_Len + 1, Str_Len) = Suffix);
   end Eval_Ends_With;

   --------------
   -- Eval_Doc --
   --------------

   function Eval_Doc
     (Ctx : Eval_Context; Args : Primitive_Array) return Primitive
   is
      Obj : constant Primitive := Args (1);
   begin
      Put_Line
        (case Kind (Obj) is
         when Kind_Builtin_Function =>
           To_Text (Obj.Unchecked_Get.Builtin_Fn.Doc),
         when Kind_Function         =>
           To_Text (Str_Val (Eval (Ctx, Obj.Unchecked_Get.Fun_Node.P_Doc))),
         when Kind_Selector         =>
           To_Text (Str_Val (Eval (Ctx, Obj.Unchecked_Get.Sel_Node.F_Doc))),
         when others                => "");
      return Make_Unit_Primitive;
   end Eval_Doc;

   -----------------------
   -- Builtin_Functions --
   -----------------------

   Builtin_Functions : constant Builtin_Function_Array :=
     (Create
        ("print",
         (Param ("val"),
          Param ("new_line", Kind_Bool, To_Primitive (True))),
         Eval_Print'Access,
         "Built-in print function. Prints whatever is passed as an argument"),

      Create
        ("img",
         (1 => Param ("val")),
         Eval_Image'Access,
         "Return a string representation of an object"),

      Create
        ("dump",
         (1 => Param ("node", Kind_Node)),
         Eval_Dump'Access,
         "Given an ast node, return a structured dump of the subtree"),

      Create
        ("text",
         (1 => Param ("node", Kind_Node)),
         Eval_Text'Access,
         "Given an ast node, return its text"),

      Create
        ("to_list",
         (1 => Param ("it", Kind_Iterator)),
         Eval_To_List'Access,
         "Transform an iterator into a list"),

      Create
        ("children_count",
         (1 => Param ("node", Kind_Node)),
         Eval_Children_Count'Access,
         "Given a node, return the count of its children"),

      --  String builtins

      Create
        ("starts_with",
         (Param ("str", Kind_Str), Param ("prefix", Kind_Str)),
         Eval_Starts_With'Access,
         "Given a string, returns whether it starts with the given prefix"),

      Create
        ("ends_with",
         (Param ("str", Kind_Str), Param ("suffix", Kind_Str)),
         Eval_Ends_With'Access,
         "Given a string, returns whether it ends with the given prefix"),

      Create
        ("doc",
         (1 => Param ("obj")),
         Eval_Doc'Access,
         "Given any object, return the documentation associated with it")

      );

   ------------------
   -- All_Builtins --
   ------------------

   function All_Builtins return Builtin_Function_Array is
     (Builtin_Functions);

end LKQL.Builtin_Functions;
