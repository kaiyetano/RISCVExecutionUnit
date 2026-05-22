# Timing Simulation Script for ExecUnit Baseline on Arria II (64-bit)

quit -sim

set TranscriptFile "TS_BASELINE_A2_64_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files for timing simulation..."
vcom -work work -2008 -explicit -stats=none modelsim/BASELINE_A2_64.vho
vcom -work work -2008 -explicit -stats=none ExecUnit_tb.vhd

echo "Starting timing simulation for Baseline ExecUnit..."
echo "Loading SDF timing information from modelsim/BASELINE_A2_64.sdo..."
vsim -t 1ps -voptargs="+acc" -sdftyp /DUT=modelsim/BASELINE_A2_64.sdo work.ExecUnit_tb_timing

transcript off

do wave.do

transcript on

restart -f
echo "Running timing simulation with SDF delays..."
run -all

transcript off

transcript file ""

echo "Timing simulation complete. Results saved to $TranscriptFile"
