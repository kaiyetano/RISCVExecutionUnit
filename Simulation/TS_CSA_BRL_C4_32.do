# Timing Simulation Script for ExecUnit CSA_BRL on Cyclone IV (32-bit)

quit -sim

set TranscriptFile "TS_CSA_BRL_C4_32_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files for timing simulation..."
vcom -work work -2008 -explicit -stats=none modelsim/CSA_BRL_C4_32.vho
vcom -work work -2008 -explicit -stats=none ExecUnit_tb_32.vhd

echo "Starting timing simulation for CSA_BRL ExecUnit (32-bit)..."
echo "Loading SDF timing information from modelsim/CSA_BRL_C4_32.sdo..."
vsim -t 1ps -voptargs="+acc" -sdftyp /DUT=modelsim/CSA_BRL_C4_32.sdo work.ExecUnit_tb_timing

transcript off

do wave.do

transcript on

restart -f
echo "Running timing simulation with SDF delays..."
run -all

transcript off

transcript file ""

echo "Timing simulation complete. Results saved to $TranscriptFile"
