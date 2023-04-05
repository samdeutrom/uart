/*
    Package contains state for uart_tx
    created by: Sam Deutrom
    date create: 02/04/23
    date last modified: 02/04/23
*/
package uart_rx_pkg;
    typedef enum logic [1:0] {
        IDEL,
        START,
        RECEIVING
    } rx_states_e;
endpackage