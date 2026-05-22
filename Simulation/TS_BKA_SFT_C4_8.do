vlib work
vcom -2008 ExecUnit_tb_8.vhd
vcom -2008 BKA_SFT_C4_8.vho
vsim -t ps ExecUnit_tb -sdftyp /ExecUnit_tb/DUT=BKA_SFT_C4_8.sdo
run 20 us
quit
