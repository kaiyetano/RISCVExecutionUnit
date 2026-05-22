# Functional Simulation Script for BASELINE_C4_16
# Compile order: arithmetic, logic, shift, execunit, testbench

# Clean up previous compilation
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# Compile source files
vcom -2008 -work work "../SourceCode/ArithmeticUnit.vhdl"
vcom -2008 -work work "../SourceCode/ArithmeticArchitecture.vhdl"
vcom -2008 -work work "../SourceCode/LogicUnit.vhdl"
vcom -2008 -work work "../SourceCode/LogicArchitecture.vhdl"
vcom -2008 -work work "../SourceCode/ShiftUnit.vhdl"
vcom -2008 -work work "../SourceCode/ShiftArchitecture.vhdl"
vcom -2008 -work work "../SourceCode/ExecUnit.vhdl"
vcom -2008 -work work "../SourceCode/ExecUnit_Baseline.vhdl"
vcom -2008 -work work "ExecUnit_tb_16.vhd"

# Run simulation
vsim -voptargs="+acc" work.ExecUnit_tb(Behaviour)

# Set up waveform
add wave -divider "Inputs"
add wave -hexadecimal /ExecUnit_tb/in_A
add wave -hexadecimal /ExecUnit_tb/in_B
add wave /ExecUnit_tb/in_FuncClass
add wave /ExecUnit_tb/in_LogicFN
add wave /ExecUnit_tb/in_ShiftFN
add wave /ExecUnit_tb/in_AddnSub
add wave /ExecUnit_tb/in_ExtWord

add wave -divider "Outputs"
add wave -hexadecimal /ExecUnit_tb/out_Y
add wave /ExecUnit_tb/out_Cout
add wave /ExecUnit_tb/out_Ovfl
add wave /ExecUnit_tb/out_Zero
add wave /ExecUnit_tb/out_AltB
add wave /ExecUnit_tb/out_AltBu

add wave -divider "Expected Values"
add wave -hexadecimal /ExecUnit_tb/exp_Y
add wave /ExecUnit_tb/exp_Zero
add wave /ExecUnit_tb/exp_AltB
add wave /ExecUnit_tb/exp_AltBu

add wave -divider "Test Control"
add wave -decimal /ExecUnit_tb/test_index
add wave /ExecUnit_tb/tests_passed
add wave /ExecUnit_tb/tests_failed

add wave -divider "Timing Measurements"
add wave /ExecUnit_tb/tpd_Y
add wave /ExecUnit_tb/worst_tpd_Y
add wave -decimal /ExecUnit_tb/worst_test_Y

# Run until completion
run -all

# Save transcript
transcript file FS_BASELINE_C4_16_transcript.txt

# Keep simulation open
#quit -sim
