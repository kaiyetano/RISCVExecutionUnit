library ieee;
use ieee.std_logic_1164.all;

architecture BKA_SFT of ExecUnit is
  signal arith_result : std_logic_vector(N-1 downto 0);
  signal logic_result : std_logic_vector(N-1 downto 0);
  signal shift_result : std_logic_vector(N-1 downto 0);
  signal arith_cout, arith_ovfl, arith_zero, arith_altb, arith_altbu : std_logic;
  signal Y_int : std_logic_vector(N-1 downto 0);

begin
  arith_unit : entity work.ArithmeticUnit(BrentKung)
    generic map (N => N)
    port map (
      A       => A,
      B       => B,
      AddnSub => AddnSub,
      ExtWord => ExtWord,
      S       => arith_result,
      Cout    => arith_cout,
      Ovfl    => arith_ovfl,
      Zero    => arith_zero,
      AltBu   => arith_altbu,
      AltB    => arith_altb
    );

  logic_unit : entity work.LogicUnit(Log64)
    generic map (N => N)
    port map (
      A       => A,
      B       => B,
      LogicFN => LogicFN,
      Y       => logic_result
    );

  shift_unit : entity work.ShiftUnit(Sft64)
    generic map (N => N)
    port map (
      A       => A,
      B       => B,
      ShiftFN => ShiftFN,
      ExtWord => ExtWord,
      Y       => shift_result
    );

  with FuncClass select
    Y_int <= arith_result when "00",
             logic_result when "01",
             shift_result when "10",
             (others => '0') when others;

  Y     <= Y_int;
  Cout  <= arith_cout when FuncClass = "00" else '0';
  Ovfl  <= arith_ovfl when FuncClass = "00" else '0';
  Zero  <= '1' when Y_int = (N-1 downto 0 => '0') else '0';
  AltB  <= arith_altb when FuncClass = "00" else '0';
  AltBu <= arith_altbu when FuncClass = "00" else '0';

end architecture;
