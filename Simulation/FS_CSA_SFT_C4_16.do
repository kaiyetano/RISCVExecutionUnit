# Functional Simulation Script for CSA_SFT ExecUnit (16-bit)

quit -sim

set TranscriptFile "FS_CSA_SFT_C4_16_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files for functional simulation..."

vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ArithmeticArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/LogicArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftUnit.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ShiftArchitecture.vhdl
vcom -work work -2008 -explicit -stats=none ../SourceCode/ExecUnit_CSA_SFT.vhdl
vcom -work work -2008 -explicit -stats=none ExecUnit_tb_16.vhd

echo "Starting functional simulation for CSA_SFT ExecUnit..."
vsim -voptargs="+acc" work.ExecUnit_tb(Behaviour)

transcript off

do wave.do

transcript on

restart -f
echo "Running functional simulation..."
run -all

transcript off

transcript file ""

echo "Functional simulation complete. Results saved to $TranscriptFile"
