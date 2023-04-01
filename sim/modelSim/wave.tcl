add wave -divider {uart_tx_test}
add wave -noupdate -expand -group uart_tx_test -radix hex \
{/uart_tx_tb/clk}\
{/uart_tx_tb/reset}\
{/uart_tx_tb/MUT.baud_pulse}\
{/uart_tx_tb/MUT.next}\
{/uart_tx_tb/MUT.state}\
{/uart_tx_tb/MUT.data_counter}\
{/uart_tx_tb/MUT.data_done}\
{/uart_tx_tb/data_o}
