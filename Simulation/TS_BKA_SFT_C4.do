# Timing Simulation Script for ExecUnit BKA_SFT on Cyclone IV

quit -sim

set TranscriptFile "TS_BKA_SFT_C4_64_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files for timing simulation..."
vcom -work work -2008 -explicit -stats=none modelsim/BKA_SFT_C4_64.vho
vcom -work work -2008 -explicit -stats=none ExecUnit_tb.vhd

echo "Starting timing simulation for BKA_SFT ExecUnit..."
echo "Loading SDF timing information from modelsim/BKA_SFT_C4_64.sdo..."
vsim -t 1ps -voptargs="+acc" -sdftyp /DUT=modelsim/BKA_SFT_C4_64.sdo work.ExecUnit_tb_timing

transcript off

do wave.do

transcript on

restart -f
echo "Running timing simulation with SDF delays..."
run -all

transcript off

transcript file ""

echo "Timing simulation complete. Results saved to $TranscriptFile"
