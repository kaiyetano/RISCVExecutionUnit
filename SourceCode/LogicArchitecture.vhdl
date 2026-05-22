library ieee;
use ieee.std_logic_1164.all;

architecture Log64 of LogicUnit is
begin
    process(A, B, LogicFN)
    begin
        case LogicFN is
            when "00" => Y <= B;
            when "01" => Y <= A xor B;
            when "10" => Y <= A or B;
            when "11" => Y <= A and B;
            when others => Y <= (others => '0');
        end case;
    end process;
end architecture;
