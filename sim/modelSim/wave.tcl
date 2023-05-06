add wave -divider {uart_test}
add wave -noupdate -expand -group uart_test -radix hex \
{/uart_tb/clk}\
{/uart_tb/rst_n}\
add wave -divider {}

add wave -divider {uart_tx}\
{/uart_tb/tx.baud_clk}\
{/uart_tb/tx.next}\
{/uart_tb/tx.state}\
{/uart_tb/tx_send_i}\
{/uart_tb/tx.tx_send_stretch}\
{/uart_tb/tx_data_i}\
{/uart_tb/tx.data_shift_buf}\
{/uart_tb/tx_data_o}\
add wave -divider {}

add wave -divider {uart_rx}\
{/uart_tb/rx.data_i}\
{/uart_tb/rx.baud_counter_enable}\
{/uart_tb/rx.baud_counter_done}\
{/uart_tb/rx.data_counter}\
{/uart_tb/rx.data_counter_done}\
{/uart_tb/rx.data_done}\
{/uart_tb/rx.next}\
{/uart_tb/rx.state}\
{/uart_tb/rx.rx_shift_reg}\
{/uart_tb/rx_data_o}\
add wave -divider {}
