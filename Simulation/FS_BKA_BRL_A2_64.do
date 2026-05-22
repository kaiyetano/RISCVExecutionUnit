# Functional Simulation Script for ExecUnit BKA_BRL on Arria II (64-bit)

quit -sim

set TranscriptFile "FS_BKA_BRL_A2_64_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files..."
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit_BKA_BRL.vhdl
vcom -work work -2008 -explicit -stats=none ExecUnit_tb.vhd

echo "Starting functional simulation for BKA_BRL ExecUnit..."
vsim -t 1ps -voptargs="+acc" work.ExecUnit_tb_BKA_BRL

transcript off

do wave.do

transcript on

restart -f
echo "Running functional simulation..."
run -all

transcript off

transcript file ""

echo "Functional simulation complete. Results saved to $TranscriptFile"
