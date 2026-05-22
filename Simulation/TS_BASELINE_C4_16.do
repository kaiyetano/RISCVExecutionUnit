# Timing Simulation Script for BASELINE ExecUnit (Cyclone IV, 16-bit)

quit -sim

set TranscriptFile "TS_BASELINE_C4_16_transcript.txt"

transcript file $TranscriptFile
transcript on

echo "Compiling source files for timing simulation..."

# Ensure we use the global precompiled cycloneive library
if {[info exists env(CYCLONEIVE_LIB)]} {
    vmap cycloneive $env(CYCLONEIVE_LIB)
} else {
    echo "CYCLONEIVE_LIB not set; assuming cycloneive is already mapped"
}

vcom -work work -2008 -explicit -stats=none modelsim/BASELINE_C4_16.vho
vcom -work work -2008 -explicit -stats=none ExecUnit_tb_16.vhd

echo "Starting timing simulation for BASELINE ExecUnit..."
echo "Loading SDF timing information from modelsim/BASELINE_C4_16.sdo..."
vsim -t 1ps -voptargs="+acc" -L altera_mf -L cycloneive -sdftyp /DUT=modelsim/BASELINE_C4_16.sdo work.ExecUnit_tb_timing

transcript off

do wave.do

transcript on

restart -f
echo "Running timing simulation with SDF delays..."
run -all

transcript off

transcript file ""

echo "Timing simulation complete. Results saved to $TranscriptFile"

