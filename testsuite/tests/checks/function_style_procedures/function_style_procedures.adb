package body Function_Style_Procedures is

   procedure P (R : out Integer) is
   begin
      R := 0;
   end P;

   procedure P_Limited (R : out Lim) is
   begin
      null;
   end P_Limited;

   procedure P2 (R : out Integer; R2: in out Integer) is
   begin
      R := R2;
      R2 := 0;
   end P2;

end Function_Style_Procedures;
