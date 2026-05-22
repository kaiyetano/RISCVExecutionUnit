library ieee;
use ieee.std_logic_1164.all;

Entity ArithmeticUnit is 
    Generic (N : natural := 64);
    Port ( 
        A       : in  std_logic_vector(N-1 downto 0);
        B       : in  std_logic_vector(N-1 downto 0);
        AddnSub : in  std_logic;
        ExtWord : in  std_logic;
        S       : out std_logic_vector(N-1 downto 0);
        Cout    : out std_logic;
        Ovfl    : out std_logic;
        Zero    : out std_logic;
        AltBu   : out std_logic;
        AltB    : out std_logic
    );
End Entity ArithmeticUnit;
