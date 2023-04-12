vlib work
vdel -all
vlib work

#Compile files
vlog -f files.tcl

set top_level work.uart_tb

vsim -t ns $top_level

onerror {resume}
delete wave *
wave zoom range 0us 1us
do wave.tcl
config wave -signalnamewidth 1
view wave -undock 

run -all
wave zoom full