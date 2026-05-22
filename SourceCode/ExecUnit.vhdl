library ieee;
use ieee.std_logic_1164.all;

entity ExecUnit is
    Generic (N : natural := 8);
    Port (
        A, B      : in  std_logic_vector(N-1 downto 0);
        FuncClass : in  std_logic_vector(1 downto 0);
        LogicFN   : in  std_logic_vector(1 downto 0);
        ShiftFN   : in  std_logic_vector(1 downto 0);
        AddnSub   : in  std_logic;
        ExtWord   : in  std_logic;
        Y         : out std_logic_vector(N-1 downto 0);
        Cout      : out std_logic;
        Ovfl      : out std_logic;
        Zero      : out std_logic;
        AltB      : out std_logic;
        AltBu     : out std_logic
    );
end entity ExecUnit;