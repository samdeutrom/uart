add wave -divider {uart_test}
add wave -noupdate -expand -group uart_test -radix hex \
{/uart_tx_tb/clk}\
{/uart_tx_tb/rst_n}\
add wave -divider {}

add wave -divider {uart_tx}\
{/uart_tx_tb/tx.baud_clk}\
{/uart_tx_tb/tx.next}\
{/uart_tx_tb/tx.state}\
{/uart_tx_tb/tx_send_i}\
{/uart_tx_tb/tx.tx_send_stretch}\
{/uart_tx_tb/tx_data_i}\
{/uart_tx_tb/tx.data_shift_buf}\
{/uart_tx_tb/tx_data_o}\
add wave -divider {}

# add wave -divider {uart_rx}\
# {/uart_tx_tb/tx_data_o}\
# {/uart_tx_tb/rx.half_baud_counter}\
# {/uart_tx_tb/rx.pulse_counter}\
# {/uart_tx_tb/rx.sample_pulse}\
# {/uart_tx_tb/rx.data_counter}\
# {/uart_tx_tb/rx.state}\
# {/uart_tx_tb/rx.next}\
# {/uart_tx_tb/rx.data_o_reg}\
# {/uart_tx_tb/rx_data_o}


# add wave -divider {}