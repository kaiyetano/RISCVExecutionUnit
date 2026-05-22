# Timing simulation script for CSA_BRL_C4_16 with FAST timing model
transcript on

# Ensure we use the global precompiled cycloneive library
if {[info exists env(CYCLONEIVE_LIB)]} {
    vmap cycloneive $env(CYCLONEIVE_LIB)
} else {
    echo "CYCLONEIVE_LIB not set; assuming cycloneive is already mapped"
}

# Compile the post-synthesis netlist (VHO file)
vcom -work work -2008 -explicit -stats=none modelsim/CSA_BRL_C4_16.vho

# Compile the testbench
vcom -work work -2008 -explicit -stats=none ExecUnit_tb_16.vhd

# Start simulation with FAST timing SDF annotation
vsim -t 1ps -voptargs="+acc" -L altera_mf -L cycloneive -sdftyp /DUT=modelsim/CSA_BRL_C4_16_min_1200mv_0c_vhd_fast.sdo work.ExecUnit_tb_timing

# Run the simulation
run -all

# Save transcript
transcript file TS_CSA_BRL_C4_16_FAST_transcript.txt
transcript off

