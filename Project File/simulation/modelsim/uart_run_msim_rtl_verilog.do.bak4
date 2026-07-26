transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/USER/Desktop/FPGA {C:/Users/USER/Desktop/FPGA/uart_tx.v}
vlog -vlog01compat -work work +incdir+C:/Users/USER/Desktop/FPGA {C:/Users/USER/Desktop/FPGA/uart_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/USER/Desktop/FPGA {C:/Users/USER/Desktop/FPGA/uart_top.v}

vlog -vlog01compat -work work +incdir+C:/Users/USER/Desktop/FPGA {C:/Users/USER/Desktop/FPGA/tb_uart.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb_uart

add wave *
view structure
view signals
run -all
