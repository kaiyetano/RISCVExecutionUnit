# Functional Simulation Script for BASELINE ExecUnit (Cyclone IV, 32-bit)

quit -sim

echo "Compiling source files..."
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit_BASELINE.vhdl
vcom -work work -2008 -explicit -stats=none ExecUnit_tb_32.vhd

echo "Loading functional simulation..."
vsim -t 1ps -voptargs="+acc" work.ExecUnit_tb_func

transcript off

do wave.do

transcript on

restart -f
echo "Running functional simulation..."
run -all

echo "Functional simulation complete. Results saved to FS_BASELINE_C4_32_transcript.txt"
