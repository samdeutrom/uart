/*
    Package contains state for uart_tx
    created by: Sam Deutrom
*/
package uart_rx_pkg;
    typedef enum logic [2:0] {
        IDEL,
        START,
        DATA,
        STOP,
        ERROR} rx_states_e;
endpackage