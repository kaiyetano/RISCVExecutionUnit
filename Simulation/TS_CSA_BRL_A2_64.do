# Timing Simulation Script for CSA_BRL ExecUnit (Arria II, 64-bit)

quit -sim

set TranscriptFile "TS_CSA_BRL_A2_64_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files for timing simulation..."
vcom -work work -2008 -explicit -stats=none modelsim/CSA_BRL_A2_64.vho
vcom -work work -2008 -explicit -stats=none ExecUnit_tb.vhd

echo "Starting timing simulation for CSA_BRL ExecUnit..."
echo "Loading SDF timing information from modelsim/CSA_BRL_A2_64.sdo..."
vsim -t 1ps -voptargs="+acc" -sdftyp /DUT=modelsim/CSA_BRL_A2_64.sdo work.ExecUnit_tb_timing

transcript off

do wave.do

transcript on

restart -f
echo "Running timing simulation with SDF delays..."
run -all

transcript off

transcript file ""

echo "Timing simulation complete. Results saved to $TranscriptFile"
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0

# Add signals to wave window
add wave -divider "Testbench Signals"
add wave -label "Clock" /ExecUnit_tb/clk
add wave -divider "Inputs"
add wave -label "FuncClass" -radix binary /ExecUnit_tb/in_FuncClass
add wave -label "Op" -radix binary /ExecUnit_tb/in_Op
add wave -label "A" -radix hexadecimal /ExecUnit_tb/in_A
add wave -label "B" -radix hexadecimal /ExecUnit_tb/in_B
add wave -divider "Outputs"
add wave -label "Y" -radix hexadecimal /ExecUnit_tb/out_Y
add wave -label "Carry" /ExecUnit_tb/out_Carry
add wave -label "Negative" /ExecUnit_tb/out_Negative
add wave -label "oVerflow" /ExecUnit_tb/out_oVerflow
add wave -label "Zero" /ExecUnit_tb/out_Zero
add wave -divider "Expected Outputs"
add wave -label "Y_expected" -radix hexadecimal /ExecUnit_tb/out_Y_expected
add wave -label "Carry_expected" /ExecUnit_tb/out_Carry_expected
add wave -label "Negative_expected" /ExecUnit_tb/out_Negative_expected
add wave -label "oVerflow_expected" /ExecUnit_tb/out_oVerflow_expected
add wave -label "Zero_expected" /ExecUnit_tb/out_Zero_expected
transcript on

restart -f

echo "Running timing simulation with SDF delays..."
run -all

echo "Timing simulation complete. Results saved to TS_CSA_BRL_A2_64_transcript.txt"
