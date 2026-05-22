library ieee;
use ieee.std_logic_1164.all;

architecture BrentKung of ArithmeticUnit is

  function ceil_log2(n : positive) return natural is
    variable v : natural := 1;
    variable r : natural := 0;
  begin
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  function pow2(k : natural) return natural is
    variable v : natural := 1;
  begin
    for i in 1 to k loop
      v := v * 2;
    end loop;
    return v;
  end function;

  constant L : natural := ceil_log2(N);
  constant M : natural := pow2(L);

  type slv_vec is array (natural range <>) of std_logic_vector(M-1 downto 0);
  signal G : slv_vec(0 to L);
  signal P : slv_vec(0 to L);

  signal A_pad, B_pad, S_pad : std_logic_vector(M-1 downto 0);
  signal B_xor : std_logic_vector(N-1 downto 0);
  signal c : std_logic_vector(M downto 0);
  signal S_int : std_logic_vector(N-1 downto 0);
  signal Cout_int, Ovfl_int : std_logic;

begin
  B_xor <= B xor (N-1 downto 0 => AddnSub);

  A_pad(N-1 downto 0) <= A;
  B_pad(N-1 downto 0) <= B_xor;

  gen_pad_hi : if M > N generate
    A_pad(M-1 downto N) <= (others => '0');
    B_pad(M-1 downto N) <= (others => '0');
  end generate;

  G(0) <= A_pad and B_pad;
  P(0) <= A_pad xor B_pad;

  gen_fwd : for s in 0 to L-1 generate
    constant step : natural := pow2(s+1);
    constant half : natural := pow2(s);
  begin
    gen_fwd_bits : for i in 0 to M-1 generate
      signal at_end : std_logic;
      signal new_G, new_P : std_logic;
    begin
      at_end <= '1' when (i >= half) and ((i mod step) = step-1) else '0';
      
      gen_upper : if i >= half generate
        new_G <= G(s)(i) or (P(s)(i) and G(s)(i - half));
        new_P <= P(s)(i) and P(s)(i - half);
      end generate;
      
      gen_lower : if i < half generate
        new_G <= G(s)(i);
        new_P <= P(s)(i);
      end generate;
      
      G(s+1)(i) <= new_G when at_end = '1' else G(s)(i);
      P(s+1)(i) <= new_P when at_end = '1' else P(s)(i);
    end generate;
  end generate;

  c(0) <= AddnSub;

  gen_even_carries : for s in 0 to L-1 generate
    constant step : natural := pow2(s+2);
    constant half : natural := pow2(s+1);
    constant mmax : natural := (M - half) / step;
  begin
    gen_even_m : for m in 0 to mmax generate
      constant pos : natural := m*step + half;
    begin
      c(pos) <= G(s+1)(pos-1) or (P(s+1)(pos-1) and c(pos - half));
    end generate;
  end generate;

  gen_odd_carries : for k in 0 to (M/2)-1 generate
    c(2*k + 1) <= G(0)(2*k) or (P(0)(2*k) and c(2*k));
  end generate;

  S_pad <= P(0) xor c(M-1 downto 0);
  S_int <= S_pad(N-1 downto 0);
  
  -- For N/2-bit operations (ExtWord), compute flags from bit N/2-1
  Cout_int <= c(N/2) when ExtWord = '1' else c(N);
  Ovfl_int <= (c(N/2) xor c(N/2-1)) when ExtWord = '1' else (c(N) xor c(N-1));

  -- For ExtWord, sign-extend N/2-bit result to N bits
  S <= (N-1 downto N/2 => S_int(N/2-1)) & S_int(N/2-1 downto 0) when ExtWord = '1' else S_int;
  Cout <= Cout_int;
  Ovfl <= Ovfl_int;
  Zero <= '1' when (S_int(N/2-1 downto 0) = (N/2-1 downto 0 => '0')) and ExtWord = '1' else
          '1' when S_int = (N-1 downto 0 => '0') else '0';
  AltBu <= not Cout_int;
  AltB <= S_int(N/2-1) xor Ovfl_int when ExtWord = '1' else S_int(N-1) xor Ovfl_int;

end architecture;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

architecture ConditionalSum of ArithmeticUnit is

  component ArithmeticUnit is
    generic (N : natural);
    port (
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
  end component;

  signal B_xor : std_logic_vector(N-1 downto 0);
  signal S_int : std_logic_vector(N-1 downto 0);
  signal Cout_int, Ovfl_int : std_logic;
  signal Cout_half, Ovfl_half : std_logic;
  signal carry_half : std_logic_vector(N/2 downto 0);

begin
  B_xor <= B xor (N-1 downto 0 => AddnSub);
  
  -- Compute N/2-bit carry/overflow for ExtWord operations
  carry_half(0) <= AddnSub;
  gen_carry_half : for i in 0 to N/2-1 generate
    carry_half(i+1) <= (A(i) and B_xor(i)) or (A(i) and carry_half(i)) or (B_xor(i) and carry_half(i));
  end generate;
  Cout_half <= carry_half(N/2);
  Ovfl_half <= carry_half(N/2) xor carry_half(N/2-1);

  gen_base : if N = 1 generate
    signal s0, c0 : std_logic;
  begin
    s0   <= A(0) xor B_xor(0) xor AddnSub;
    c0   <= (A(0) and B_xor(0)) or (A(0) and AddnSub) or (B_xor(0) and AddnSub);
    S_int(0) <= s0;
    Cout_int <= c0;
    Ovfl_int <= (A(0) xnor B_xor(0)) and (A(0) xor s0);
  end generate;

  gen_rec : if N > 1 generate
    constant L : natural := N/2;
    constant U : natural := N - L;
    signal S_lo       : std_logic_vector(L-1 downto 0);
    signal C_lo       : std_logic;
    signal S_hi0, S_hi1 : std_logic_vector(U-1 downto 0);
    signal C_hi0, C_hi1 : std_logic;
    signal S_hi_sel   : std_logic_vector(U-1 downto 0);
    signal Cout_sel, Ovfl_sel   : std_logic;
    
    -- Local ripple-carry computation for upper half with both carry assumptions
    signal carry0, carry1 : std_logic_vector(U downto 0);
    signal S_hi0_local, S_hi1_local : std_logic_vector(U-1 downto 0);
    signal Ovfl_hi0, Ovfl_hi1 : std_logic;
  begin
    u_low : ArithmeticUnit
      generic map (N => L)
      port map (
        A       => A(L-1 downto 0),
        B       => B(L-1 downto 0),
        AddnSub => AddnSub,
        ExtWord => '0',
        S       => S_lo,
        Cout    => C_lo,
        Ovfl    => open,
        Zero    => open,
        AltBu   => open,
        AltB    => open
      );

    -- Compute upper half with carry-in = 0
    carry0(0) <= '0';
    gen_hi0 : for i in 0 to U-1 generate
      S_hi0_local(i) <= A(L+i) xor B_xor(L+i) xor carry0(i);
      carry0(i+1) <= (A(L+i) and B_xor(L+i)) or (A(L+i) and carry0(i)) or (B_xor(L+i) and carry0(i));
    end generate;
    S_hi0 <= S_hi0_local;
    C_hi0 <= carry0(U);
    Ovfl_hi0 <= (A(N-1) xnor B_xor(N-1)) and (A(N-1) xor S_hi0_local(U-1));

    -- Compute upper half with carry-in = 1
    carry1(0) <= '1';
    gen_hi1 : for i in 0 to U-1 generate
      S_hi1_local(i) <= A(L+i) xor B_xor(L+i) xor carry1(i);
      carry1(i+1) <= (A(L+i) and B_xor(L+i)) or (A(L+i) and carry1(i)) or (B_xor(L+i) and carry1(i));
    end generate;
    S_hi1 <= S_hi1_local;
    C_hi1 <= carry1(U);
    Ovfl_hi1 <= (A(N-1) xnor B_xor(N-1)) and (A(N-1) xor S_hi1_local(U-1));

    with C_lo select
      S_hi_sel <= S_hi1 when '1',
                  S_hi0 when others;

    with C_lo select
      Cout_sel <= C_hi1 when '1',
                  C_hi0 when others;

    with C_lo select
      Ovfl_sel <= Ovfl_hi1 when '1',
                  Ovfl_hi0 when others;

    S_int <= S_hi_sel & S_lo;
    Cout_int <= Cout_sel;
    Ovfl_int <= Ovfl_sel;
  end generate;

  -- Output assignments
  S <= (N-1 downto N/2 => S_int(N/2-1)) & S_int(N/2-1 downto 0) when ExtWord = '1' else S_int;
  Cout <= Cout_half when ExtWord = '1' else Cout_int;
  Ovfl <= Ovfl_half when ExtWord = '1' else Ovfl_int;
  Zero <= '1' when (S_int(N/2-1 downto 0) = (N/2-1 downto 0 => '0')) and ExtWord = '1' else
          '1' when S_int = (N-1 downto 0 => '0') else '0';
  AltBu <= (not Cout_half) when ExtWord = '1' else (not Cout_int);
  AltB <= S_int(N/2-1) xor Ovfl_half when ExtWord = '1' else S_int(N-1) xor Ovfl_int;

end architecture;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

architecture Baseline of ArithmeticUnit is
  signal generate_carry, propagate_carry : std_logic_vector(N-1 downto 0);
  signal carry : std_logic_vector(N downto 0);
  signal B_xor : std_logic_vector(N-1 downto 0);
  signal S_int : std_logic_vector(N-1 downto 0);
  signal S_final : std_logic_vector(N-1 downto 0);
  signal Cout_int, Ovfl_int : std_logic;
  signal Cout_half, Ovfl_half : std_logic;

begin
  B_xor <= B xor (N-1 downto 0 => AddnSub);
  carry(0) <= AddnSub;
  
  gen_ripple : for i in 0 to N-1 generate
    generate_carry(i) <= A(i) and B_xor(i);
    propagate_carry(i) <= A(i) xor B_xor(i);
    carry(i+1) <= generate_carry(i) or (propagate_carry(i) and carry(i));
    S_int(i) <= A(i) xor B_xor(i) xor carry(i);
  end generate;
  
  -- For N/2-bit operations, get the carry and overflow from bit N/2-1
  Cout_half <= carry(N/2);
  Ovfl_half <= carry(N/2) xor carry(N/2-1);
  
  -- Select outputs based on ExtWord
  Cout_int <= Cout_half when ExtWord = '1' else carry(N);
  Ovfl_int <= Ovfl_half when ExtWord = '1' else (carry(N) xor carry(N-1));
  
  -- For ExtWord, sign-extend N/2-bit result to N bits
  S_final <= (N-1 downto N/2 => S_int(N/2-1)) & S_int(N/2-1 downto 0) when ExtWord = '1' else S_int;

  S <= S_final;
  Cout <= Cout_int;
  Ovfl <= Ovfl_int;
  Zero <= '1' when (S_int(N/2-1 downto 0) = (N/2-1 downto 0 => '0')) and ExtWord = '1' else
          '1' when S_int = (N-1 downto 0 => '0') else '0';
  AltBu <= not Cout_int;
  AltB <= S_int(N/2-1) xor Ovfl_int when ExtWord = '1' else S_int(N-1) xor Ovfl_int;

end architecture;

