library ieee;
use ieee.std_logic_1164.all;

Entity LogicUnit is 
    Generic (N : natural := 64);
    Port ( 
        A       : in  std_logic_vector(N-1 downto 0);
        B       : in  std_logic_vector(N-1 downto 0);
        LogicFN : in  std_logic_vector(1 downto 0);
        Y       : out std_logic_vector(N-1 downto 0)
    );
End Entity LogicUnit;
