library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture Sft64 of ShiftUnit is
    
    function log2_ceil(n : positive) return natural is
        variable temp : positive := 1;
        variable result : natural := 0;
    begin
        while temp < n loop
            temp := temp * 2;
            result := result + 1;
        end loop;
        return result;
    end function;
    
    constant SHIFT_BITS_FULL : natural := log2_ceil(N);
    constant SHIFT_BITS_HALF : natural := log2_ceil(N/2);
    
begin
    process(A, B, ShiftFN, ExtWord)
        variable shift_amt : natural;
        variable data_half : std_logic_vector(N/2-1 downto 0);
        variable result_half : std_logic_vector(N/2-1 downto 0);
    begin
        if ExtWord = '1' then
            shift_amt := to_integer(unsigned(B(SHIFT_BITS_HALF-1 downto 0)));
            data_half := A(N/2-1 downto 0);
            case ShiftFN is
                when "01" => 
                    result_half := std_logic_vector(shift_left(unsigned(data_half), shift_amt));
                    Y <= (N-1 downto N/2 => result_half(N/2-1)) & result_half;
                when "10" => 
                    result_half := std_logic_vector(shift_right(unsigned(data_half), shift_amt));
                    Y <= (N-1 downto N/2 => result_half(N/2-1)) & result_half;
                when "11" => 
                    result_half := std_logic_vector(shift_right(signed(data_half), shift_amt));
                    Y <= (N-1 downto N/2 => result_half(N/2-1)) & result_half;
                when others => 
                    Y <= (N-1 downto N/2 => A(N/2-1)) & data_half;
            end case;
        else
            shift_amt := to_integer(unsigned(B(SHIFT_BITS_FULL-1 downto 0)));
            case ShiftFN is
                when "01" => Y <= std_logic_vector(shift_left(unsigned(A), shift_amt));
                when "10" => Y <= std_logic_vector(shift_right(unsigned(A), shift_amt));
                when "11" => Y <= std_logic_vector(shift_right(signed(A), shift_amt));
                when others => Y <= A;
            end case;
        end if;
    end process;
end architecture;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture Brl64 of ShiftUnit is
    
    function log2_ceil(n : positive) return natural is
        variable temp : positive := 1;
        variable result : natural := 0;
    begin
        while temp < n loop
            temp := temp * 2;
            result := result + 1;
        end loop;
        return result;
    end function;
    
    constant SHIFT_BITS_FULL : natural := log2_ceil(N);
    constant SHIFT_BITS_HALF : natural := log2_ceil(N/2);
begin
    process(A, B, ShiftFN, ExtWord)
        variable shift_amt : natural;
        variable data_half : std_logic_vector(N/2-1 downto 0);
        variable result_half : std_logic_vector(N/2-1 downto 0);
        variable result : std_logic_vector(N-1 downto 0);
        variable amount : natural;
    begin
        if ExtWord = '1' then
            shift_amt := to_integer(unsigned(B(SHIFT_BITS_HALF-1 downto 0)));
            data_half := A(N/2-1 downto 0);
            
            case ShiftFN is
                when "01" =>
                    result_half := std_logic_vector(shift_left(unsigned(data_half), shift_amt));
                    Y <= (N-1 downto N/2 => result_half(N/2-1)) & result_half;
                when "10" =>
                    result_half := std_logic_vector(shift_right(unsigned(data_half), shift_amt));
                    Y <= (N-1 downto N/2 => result_half(N/2-1)) & result_half;
                when "11" =>
                    result_half := std_logic_vector(shift_right(signed(data_half), shift_amt));
                    Y <= (N-1 downto N/2 => result_half(N/2-1)) & result_half;
                when others =>
                    Y <= (N-1 downto N/2 => A(N/2-1)) & data_half;
            end case;
        else
            result := A;
            amount := 1;

            for i in 0 to SHIFT_BITS_FULL-1 loop
                if B(i) = '1' then
                    case ShiftFN is
                        when "01" =>
                            result := result(N-1-amount downto 0) & (amount-1 downto 0 => '0');
                        when "10" =>
                            result := (amount-1 downto 0 => '0') & result(N-1 downto amount);
                        when "11" =>
                            result := (amount-1 downto 0 => result(N-1)) & result(N-1 downto amount);
                        when others =>
                            null;
                    end case;
                end if;
                amount := amount * 2;
            end loop;

            Y <= result;
        end if;
    end process;
end architecture;
