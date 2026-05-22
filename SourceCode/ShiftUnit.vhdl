library ieee;
use ieee.std_logic_1164.all;

Entity ShiftUnit is 
    Generic (N : natural := 64);
    Port ( 
        A       : in  std_logic_vector(N-1 downto 0);
        B       : in  std_logic_vector(N-1 downto 0);
        ShiftFN : in  std_logic_vector(1 downto 0);
        ExtWord : in  std_logic;
        Y       : out std_logic_vector(N-1 downto 0)
    );
End Entity ShiftUnit;
