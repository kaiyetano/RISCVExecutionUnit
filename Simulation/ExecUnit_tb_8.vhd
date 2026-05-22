LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY ExecUnit_tb IS
END ExecUnit_tb;

ARCHITECTURE Behaviour OF ExecUnit_tb IS
	CONSTANT TestVectorFile : string := "ExecUnit_8.tvs";
	CONSTANT PreStimTime    : time := 10 ns;
	CONSTANT PostStimTime   : time := 1000 ns;
	CONSTANT StableTime     : time := 15 ns;
	
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
	
	SIGNAL in_A, in_B       : std_logic_vector(7 DOWNTO 0);
	SIGNAL in_FuncClass     : std_logic_vector(1 DOWNTO 0);
	SIGNAL in_LogicFN       : std_logic_vector(1 DOWNTO 0);
	SIGNAL in_ShiftFN       : std_logic_vector(1 DOWNTO 0);
	SIGNAL in_AddnSub       : std_logic;
	SIGNAL in_ExtWord       : std_logic;
	
	SIGNAL out_Y            : std_logic_vector(7 DOWNTO 0);
	SIGNAL out_Cout, out_Ovfl, out_Zero, out_AltB, out_AltBu : std_logic;
	
	SIGNAL exp_Y            : std_logic_vector(7 DOWNTO 0);
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
	
	TYPE test_record IS RECORD
		tpd_Y : time;
		tpd_Cout : time;
		tpd_Ovfl : time;
		tpd_Zero : time;
		tpd_AltB : time;
		tpd_AltBu : time;
	END RECORD;
	
	TYPE test_array IS ARRAY(natural RANGE <>) OF test_record;
	SIGNAL delays : test_array(0 TO 1023);
	
	SIGNAL worst_tpd_Y : time := 0 ns;
	SIGNAL worst_test_Y : integer := 0;
	SIGNAL worst_tpd_Cout : time := 0 ns;
	SIGNAL worst_test_Cout : integer := 0;
	SIGNAL worst_tpd_Ovfl : time := 0 ns;
	SIGNAL worst_test_Ovfl : integer := 0;
	SIGNAL worst_tpd_Zero : time := 0 ns;
	SIGNAL worst_test_Zero : integer := 0;
	SIGNAL worst_tpd_AltB : time := 0 ns;
	SIGNAL worst_test_AltB : integer := 0;
	SIGNAL worst_tpd_AltBu : time := 0 ns;
	SIGNAL worst_test_AltBu : integer := 0;
	
	SIGNAL tests_passed : integer := 0;
	SIGNAL tests_failed : integer := 0;
	SIGNAL total_tests  : integer := 0;
	
	COMPONENT ExecUnit IS
		GENERIC (N : natural := 8);
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
	-- Device Under Test
	DUT: ExecUnit
		GENERIC MAP (N => 8)
		PORT MAP (
			A => in_A,
			B => in_B,
			FuncClass => in_FuncClass,
			LogicFN => in_LogicFN,
			ShiftFN => in_ShiftFN,
			AddnSub => in_AddnSub,
			ExtWord => in_ExtWord,
			Y => out_Y,
			Cout => out_Cout,
			Ovfl => out_Ovfl,
			Zero => out_Zero,
			AltB => out_AltB,
			AltBu => out_AltBu
		);
	
	-- Test Stimulus Process
	PROCESS
		FILE test_file : text OPEN read_mode IS TestVectorFile;
		VARIABLE file_line : line;
		VARIABLE char : character;
		VARIABLE good_read : boolean;
		
		VARIABLE v_A, v_B, v_Y : std_logic_vector(7 DOWNTO 0);
		VARIABLE v_Y_str : string(1 to 32);
		VARIABLE skip_vector : boolean := false;
		VARIABLE j : integer := 1;
		VARIABLE firstc : character := ' ';
		VARIABLE v_FuncClass, v_LogicFN, v_ShiftFN : std_logic_vector(1 DOWNTO 0);
		VARIABLE v_AddnSub, v_ExtWord : std_logic;
		VARIABLE v_Cout, v_Ovfl, v_Zero, v_AltB, v_AltBu : std_logic;
		
		VARIABLE space : character;
	BEGIN
		REPORT "========================================";
		REPORT "ExecUnit Testbench";
		REPORT "Reading vectors from: " & TestVectorFile;
		REPORT "========================================";
		
		test_index <= 0;
		tests_passed <= 0;
		tests_failed <= 0;
		total_tests <= 0;
		
		in_A <= (OTHERS => '0');
		in_B <= (OTHERS => '0');
		in_FuncClass <= (OTHERS => '0');
		in_LogicFN <= (OTHERS => '0');
		in_ShiftFN <= (OTHERS => '0');
		in_AddnSub <= '0';
		in_ExtWord <= '0';
		
		WAIT FOR PreStimTime;
		
		WHILE NOT endfile(test_file) LOOP
			readline(test_file, file_line);
			
			IF file_line'length = 0 THEN
				NEXT;
			END IF;
			
			read(file_line, char, good_read);
			IF NOT good_read OR char = '#' THEN
				NEXT;
			END IF;
			
			file_line := new string'(char & file_line.all);
			
			hread(file_line, v_A, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			hread(file_line, v_B, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_FuncClass, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_LogicFN, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_ShiftFN, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_AddnSub, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_ExtWord, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			hread(file_line, v_Y, good_read);
			IF NOT good_read THEN
				-- If hex read failed, attempt to read token as string (allow 'x' marker)
				read(file_line, v_Y_str, good_read);
				IF NOT good_read THEN
					NEXT;
				END IF;
				-- detect 'x' or 'X' marker indicating skip-of-stability for this vector
				IF v_Y_str'LOW <= v_Y_str'HIGH THEN
					-- find first non-space character in the token
					j := v_Y_str'LOW;
					firstc := ' ';
					FOR jj IN v_Y_str'LOW TO v_Y_str'HIGH LOOP
						IF v_Y_str(jj) /= ' ' THEN
							j := jj;
							firstc := v_Y_str(jj);
							EXIT;
						END IF;
					END LOOP;
					IF firstc = 'X' THEN
						-- mark v_Y as don't-care (all 'X')
						v_Y := (OTHERS => 'X');
						-- consume remaining token (space already at next read)
					ELSE
						-- fallback: try to hread again (if token was padded)
						hread(file_line, v_Y, good_read);
						IF NOT good_read THEN
							NEXT;
						END IF;
					END IF;
				END IF;
				END IF;
				read(file_line, space);
			
			read(file_line, v_Zero, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_AltB, good_read);
			IF NOT good_read THEN NEXT; END IF;
			read(file_line, space);
			
			read(file_line, v_AltBu, good_read);
			IF NOT good_read THEN NEXT; END IF;
			
			test_index <= test_index + 1;
			total_tests <= total_tests + 1;
			
			exp_Y <= v_Y;
			exp_Zero <= v_Zero;
			exp_AltB <= v_AltB;
			exp_AltBu <= v_AltBu;
			
			in_A <= v_A;
			in_B <= v_B;
			in_FuncClass <= v_FuncClass;
			in_LogicFN <= v_LogicFN;
			in_ShiftFN <= v_ShiftFN;
			in_AddnSub <= v_AddnSub;
			in_ExtWord <= v_ExtWord;
			
			WAIT FOR 0 ns;
			StartTime <= NOW;
			-- detect if this vector used the 'x' marker (v_Y filled with 'X') and skip long stability wait
			skip_vector := false;
			FOR i IN v_Y'RANGE LOOP
				IF v_Y(i) = 'X' THEN
					skip_vector := true;
					EXIT;
				END IF;
			END LOOP;
			IF skip_vector THEN
				-- don't wait for full resolution; short wait to allow delta updates, then record no tpd contribution
				WAIT FOR StableTime;
				tpd_Y <= 0 ns;
			ELSE
				WAIT UNTIL (out_Y'stable(StableTime) AND out_Zero'stable(StableTime) AND out_AltB'stable(StableTime) AND out_AltBu'stable(StableTime) AND is_resolved(out_Y)) FOR PostStimTime;
				tpd_Y <= NOW - StartTime - StableTime;
			END IF;
			
			delays(test_index).tpd_Y <= tpd_Y;
			
			IF tpd_Y > worst_tpd_Y THEN
				worst_tpd_Y <= tpd_Y;
				worst_test_Y <= test_index;
			END IF;
			
			IF (skip_vector AND out_Zero = exp_Zero AND out_AltB = exp_AltB AND out_AltBu = exp_AltBu) OR (NOT skip_vector AND out_Y = exp_Y AND out_Zero = exp_Zero AND out_AltB = exp_AltB AND out_AltBu = exp_AltBu) THEN
				REPORT "Test " & integer'image(test_index) & " PASSED | FuncClass=" & to_string(in_FuncClass) & " | tpd_Y=" & time'image(tpd_Y);
				tests_passed <= tests_passed + 1;
			ELSE
				REPORT "Test " & integer'image(test_index) & " FAILED | Expected: Y=" & to_hstring(exp_Y) & " Zero=" & std_logic'image(exp_Zero) & " AltB=" & std_logic'image(exp_AltB) & " AltBu=" & std_logic'image(exp_AltBu) & " | Got: Y=" & to_hstring(out_Y) & " Zero=" & std_logic'image(out_Zero) & " AltB=" & std_logic'image(out_AltB) & " AltBu=" & std_logic'image(out_AltBu) SEVERITY error;
				tests_failed <= tests_failed + 1;
			END IF;
			
			WAIT FOR PreStimTime;
		END LOOP;
		
		WAIT FOR 20 ns;
		
		REPORT "========================================";
		REPORT "ExecUnit Test Summary";
		REPORT "========================================";
		REPORT "Total Tests: " & integer'image(total_tests);
		REPORT "Passed:      " & integer'image(tests_passed);
		REPORT "Failed:      " & integer'image(tests_failed);
		REPORT "========================================";
		REPORT "Worst-Case Propagation Delays:";
		REPORT "  Output Y (tpd_Y): " & time'image(worst_tpd_Y) & " at test index " & integer'image(worst_test_Y);
		REPORT "========================================";
		
		IF tests_failed = 0 THEN
			REPORT "ALL TESTS PASSED";
		ELSE
			REPORT "SOME TESTS FAILED" SEVERITY error;
		END IF;
		
		WAIT;
	END PROCESS;
	
END Behaviour;

-- Timing Simulation Configuration
CONFIGURATION ExecUnit_tb_timing OF ExecUnit_tb IS
	FOR Behaviour
	END FOR;
END ExecUnit_tb_timing;
