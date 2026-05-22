LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY ExecUnit_tb IS
END ExecUnit_tb;

ARCHITECTURE Behaviour OF ExecUnit_tb IS
	CONSTANT TestVectorFile : string := "ExecUnit.tvs";
	CONSTANT PreStimTime    : time := 40 ns;
	CONSTANT PostStimTime   : time := 250 ns;
	CONSTANT StableTime     : time := 5 ns;
	
	-- Function to check if all bits in a vector are resolved (no X or Z)
	FUNCTION is_resolved(vec : std_logic_vector) RETURN boolean IS
	BEGIN
		FOR i IN vec'RANGE LOOP
			IF vec(i) /= '0' AND vec(i) /= '1' AND vec(i) /= 'L' AND vec(i) /= 'H' THEN
				RETURN false;
			END IF;
		END LOOP;
		RETURN true;
	END FUNCTION;
	
	SIGNAL in_A, in_B       : std_logic_vector(63 DOWNTO 0);
	SIGNAL in_FuncClass     : std_logic_vector(1 DOWNTO 0);
	SIGNAL in_LogicFN       : std_logic_vector(1 DOWNTO 0);
	SIGNAL in_ShiftFN       : std_logic_vector(1 DOWNTO 0);
	SIGNAL in_AddnSub       : std_logic;
	SIGNAL in_ExtWord       : std_logic;
	
	SIGNAL out_Y            : std_logic_vector(63 DOWNTO 0);
	SIGNAL out_Cout, out_Ovfl, out_Zero, out_AltB, out_AltBu : std_logic;
	
	SIGNAL exp_Y            : std_logic_vector(63 DOWNTO 0);
	SIGNAL exp_Cout, exp_Ovfl, exp_Zero, exp_AltB, exp_AltBu : std_logic;
	
	SIGNAL test_index       : integer := 0;
	SIGNAL StartTime        : time := 0 ns;
	SIGNAL EndTime          : time := 0 ns;
	SIGNAL tpd_Y            : time := 0 ns;
	SIGNAL tpd_Flags        : time := 0 ns;
	
	SIGNAL y_match          : std_logic;
	SIGNAL cout_match       : std_logic;
	SIGNAL ovfl_match       : std_logic;
	SIGNAL zero_match       : std_logic;
	SIGNAL altb_match       : std_logic;
	SIGNAL altbu_match      : std_logic;
	
	COMPONENT ExecUnit IS
		GENERIC (N : natural := 64);
		PORT (
			A, B      : IN  std_logic_vector(N-1 DOWNTO 0);
			FuncClass : IN  std_logic_vector(1 DOWNTO 0);
			LogicFN   : IN  std_logic_vector(1 DOWNTO 0);
			ShiftFN   : IN  std_logic_vector(1 DOWNTO 0);
			AddnSub   : IN  std_logic;
			ExtWord   : IN  std_logic;
			Y         : OUT std_logic_vector(N-1 DOWNTO 0);
			Cout      : OUT std_logic;
			Ovfl      : OUT std_logic;
			Zero      : OUT std_logic;
			AltB      : OUT std_logic;
			AltBu     : OUT std_logic
		);
	END COMPONENT;

BEGIN
	y_match    <= '1' WHEN (out_Y = exp_Y) ELSE '0';
	cout_match <= '1' WHEN (out_Cout = exp_Cout) ELSE '0';
	ovfl_match <= '1' WHEN (out_Ovfl = exp_Ovfl) ELSE '0';
	zero_match <= '1' WHEN (out_Zero = exp_Zero) ELSE '0';
	altb_match <= '1' WHEN (out_AltB = exp_AltB) ELSE '0';
	altbu_match <= '1' WHEN (out_AltBu = exp_AltBu) ELSE '0';
	
	DUT : ExecUnit
		GENERIC MAP (N => 64)
		PORT MAP (
			A         => in_A,
			B         => in_B,
			FuncClass => in_FuncClass,
			LogicFN   => in_LogicFN,
			ShiftFN   => in_ShiftFN,
			AddnSub   => in_AddnSub,
			ExtWord   => in_ExtWord,
			Y         => out_Y,
			Cout      => out_Cout,
			Ovfl      => out_Ovfl,
			Zero      => out_Zero,
			AltB      => out_AltB,
			AltBu     => out_AltBu
		);
	
	stimulus : PROCESS
		FILE test_file : text;
		VARIABLE file_line : line;
		VARIABLE file_status : file_open_status;
		
		VARIABLE v_A, v_B, v_Y_exp : std_logic_vector(63 DOWNTO 0);
		VARIABLE v_FuncClass, v_LogicFN, v_ShiftFN : std_logic_vector(1 DOWNTO 0);
		VARIABLE v_AddnSub, v_ExtWord : std_logic;
		VARIABLE v_Zero_exp, v_AltB_exp, v_AltBu_exp : std_logic;
		VARIABLE v_space    : character;
		VARIABLE test_num   : integer := 0;
		VARIABLE pass_cnt   : integer := 0;
		VARIABLE fail_cnt   : integer := 0;
		
		VARIABLE stim_time  : time;
		VARIABLE v_tpd_Y    : time;
		VARIABLE v_tpd_Flags : time;
		VARIABLE worst_tpd_Y : time := 0 ns;
		VARIABLE worst_tpd_Flags : time := 0 ns;
		VARIABLE worst_index_Y : integer := 0;
		VARIABLE worst_index_Flags : integer := 0;
		
	BEGIN
		file_open(file_status, test_file, TestVectorFile, read_mode);
		
		IF file_status /= open_ok THEN
			REPORT "ERROR: Cannot open test vector file: " & TestVectorFile 
				SEVERITY failure;
		END IF;
		
		REPORT "========================================";
		REPORT "ExecUnit Testbench";
		REPORT "Reading vectors from: " & TestVectorFile;
		REPORT "========================================";
		
		WHILE NOT endfile(test_file) LOOP
			readline(test_file, file_line);
			
			IF file_line'length > 0 THEN
				IF file_line(1) /= '#' THEN
					hread(file_line, v_A);
					read(file_line, v_space);
					hread(file_line, v_B);
					read(file_line, v_space);
					read(file_line, v_FuncClass);
					read(file_line, v_space);
					read(file_line, v_LogicFN);
					read(file_line, v_space);
					read(file_line, v_ShiftFN);
					read(file_line, v_space);
					read(file_line, v_AddnSub);
					read(file_line, v_space);
					read(file_line, v_ExtWord);
					read(file_line, v_space);
					hread(file_line, v_Y_exp);
					read(file_line, v_space);
					read(file_line, v_Zero_exp);
					read(file_line, v_space);
					read(file_line, v_AltB_exp);
					read(file_line, v_space);
					read(file_line, v_AltBu_exp);
					
					test_num := test_num + 1;
					test_index <= test_num;
					
					exp_Y <= v_Y_exp;
					exp_Zero <= v_Zero_exp;
					exp_AltB <= v_AltB_exp;
					exp_AltBu <= v_AltBu_exp;
					
					in_A <= (OTHERS => 'X');
					in_B <= (OTHERS => 'X');
					in_FuncClass <= (OTHERS => 'X');
					in_LogicFN <= (OTHERS => 'X');
					in_ShiftFN <= (OTHERS => 'X');
					in_AddnSub <= 'X';
					in_ExtWord <= 'X';
					WAIT FOR PreStimTime;
					
					in_A <= v_A;
					in_B <= v_B;
					in_FuncClass <= v_FuncClass;
					in_LogicFN <= v_LogicFN;
					in_ShiftFN <= v_ShiftFN;
					in_AddnSub <= v_AddnSub;
					in_ExtWord <= v_ExtWord;
					stim_time := now;
					StartTime <= now;
					
					WAIT UNTIL (out_Y'STABLE(StableTime) AND out_Cout'STABLE(StableTime) AND 
					            out_Ovfl'STABLE(StableTime) AND out_Zero'STABLE(StableTime) AND
					            out_AltB'STABLE(StableTime) AND out_AltBu'STABLE(StableTime) AND
					            (out_Zero = '0' OR out_Zero = '1' OR out_Zero = 'L' OR out_Zero = 'H') AND
					            is_resolved(out_Y)) FOR PostStimTime;
					
					v_tpd_Y := now - stim_time - StableTime;
					v_tpd_Flags := out_Cout'LAST_EVENT;
					
					EndTime <= now;
					tpd_Y <= v_tpd_Y;
					tpd_Flags <= v_tpd_Flags;
					
					IF v_tpd_Y > worst_tpd_Y THEN
						worst_tpd_Y := v_tpd_Y;
						worst_index_Y := test_num;
					END IF;
					
					IF (out_Y = v_Y_exp) AND (out_Zero = v_Zero_exp) AND (out_AltB = v_AltB_exp) AND (out_AltBu = v_AltBu_exp) THEN
						pass_cnt := pass_cnt + 1;
						REPORT "Test " & integer'image(test_num) & " PASSED | " &
						       "FuncClass=" & to_string(v_FuncClass) & " | tpd_Y=" & time'image(v_tpd_Y);
					ELSE
						fail_cnt := fail_cnt + 1;
						REPORT "Test " & integer'image(test_num) & " FAILED | " &
						       "A=" & to_hstring(v_A) & " B=" & to_hstring(v_B) &
						       " FuncClass=" & to_string(v_FuncClass) &
						       " | Expected: Y=" & to_hstring(v_Y_exp) & 
						       " Zero=" & std_logic'image(v_Zero_exp) & " AltB=" & std_logic'image(v_AltB_exp) &
						       " AltBu=" & std_logic'image(v_AltBu_exp) &
						       " | Got: Y=" & to_hstring(out_Y) & 
						       " Zero=" & std_logic'image(out_Zero) & " AltB=" & std_logic'image(out_AltB) &
						       " AltBu=" & std_logic'image(out_AltBu)
						       SEVERITY error;
					END IF;
					
				END IF;
			END IF;
		END LOOP;
		
		file_close(test_file);
		
		WAIT FOR 20 ns;
		
		REPORT "========================================";
		REPORT "ExecUnit Test Summary";
		REPORT "========================================";
		REPORT "Total Tests: " & integer'image(test_num);
		REPORT "Passed:      " & integer'image(pass_cnt);
		REPORT "Failed:      " & integer'image(fail_cnt);
		REPORT "========================================";
		REPORT "Worst-Case Propagation Delays:";
		REPORT "  Output Y (tpd_Y): " & time'image(worst_tpd_Y) & " at test index " & integer'image(worst_index_Y);
		REPORT "========================================";
		
		IF fail_cnt > 0 THEN
			REPORT "TESTBENCH FAILED" SEVERITY failure;
		ELSE
			REPORT "ALL TESTS PASSED";
		END IF;
		
		WAIT;
	END PROCESS stimulus;

END Behaviour;

CONFIGURATION ExecUnit_tb_func OF ExecUnit_tb IS
	FOR Behaviour
		FOR DUT : ExecUnit
			USE ENTITY work.ExecUnit(Baseline);
		END FOR;
	END FOR;
END CONFIGURATION ExecUnit_tb_func;

CONFIGURATION ExecUnit_tb_BKA_BRL OF ExecUnit_tb IS
	FOR Behaviour
		FOR DUT : ExecUnit
			USE ENTITY work.ExecUnit(BKA_BRL);
		END FOR;
	END FOR;
END CONFIGURATION ExecUnit_tb_BKA_BRL;

CONFIGURATION ExecUnit_tb_BKA_SFT OF ExecUnit_tb IS
	FOR Behaviour
		FOR DUT : ExecUnit
			USE ENTITY work.ExecUnit(BKA_SFT);
		END FOR;
	END FOR;
END CONFIGURATION ExecUnit_tb_BKA_SFT;

CONFIGURATION ExecUnit_tb_CSA_BRL OF ExecUnit_tb IS
	FOR Behaviour
		FOR DUT : ExecUnit
			USE ENTITY work.ExecUnit(CSA_BRL);
		END FOR;
	END FOR;
END CONFIGURATION ExecUnit_tb_CSA_BRL;

CONFIGURATION ExecUnit_tb_CSA_SFT OF ExecUnit_tb IS
	FOR Behaviour
		FOR DUT : ExecUnit
			USE ENTITY work.ExecUnit(CSA_SFT);
		END FOR;
	END FOR;
END CONFIGURATION ExecUnit_tb_CSA_SFT;

CONFIGURATION ExecUnit_tb_timing OF ExecUnit_tb IS
	FOR Behaviour
		FOR DUT : ExecUnit
			USE ENTITY work.ExecUnit;
		END FOR;
	END FOR;
END CONFIGURATION ExecUnit_tb_timing;
