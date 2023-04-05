/*
    Package contains state for uart_tx
    created by: Sam Deutrom
    date create: 01/04/23
    date last modified: 01/04/23
*/
package uart_tx_pkg;
    typedef enum logic [1:0] {
        IDEL,
        START,
        SEND,
        STOP
    } tx_states_e;
endpackage