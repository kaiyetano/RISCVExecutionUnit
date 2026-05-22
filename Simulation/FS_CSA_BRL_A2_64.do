# Functional Simulation Script for CSA_BRL ExecUnit (Arria II, 64-bit)

quit -sim

echo "Compiling source files..."
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit_CSA_BRL.vhdl
vcom -work work -2008 -explicit -stats=none ExecUnit_tb.vhd

echo "Loading functional simulation..."
vsim -t 1ps -voptargs="+acc" work.ExecUnit_tb_CSA_BRL

transcript off

do wave.do

transcript on

restart -f
echo "Running functional simulation..."
run -all

echo "Functional simulation complete. Results saved to FS_CSA_BRL_A2_64_transcript.txt"

