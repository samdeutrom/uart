/*
    Module to transmit single word over UART
    created by: Sam Deutrom
    date create: 01/04/23
    date last modified: 01/04/23
*/

import uart_tx_pkg::*;

module uart_tx
    #(parameter	
        CLK_FREQ   = 100_000_000,
        BAUD_RATE  = 115200,
        DATA_WIDTH = 8
   )( 
        input  logic                    clk, rst_n,
        input  logic                    tx_ready_i, rx_ready_i,
	    input  logic  [DATA_WIDTH-1:0]  data_i,
	    output logic                    data_o
	);
	
	// State machine state defined in uart_tx_pkg.sv
	states_e state;
	states_e next;
	
	/*-------------------------------------------
	|			Baud Rate Generator				|				 
	-------------------------------------------*/
    localparam int BAUD_COUNTER_MAX = CLK_FREQ/BAUD_RATE; 
    localparam int BAUD_COUNTER_SZIE = $clog2(BAUD_COUNTER_MAX);
	
    logic [BAUD_COUNTER_SZIE-1:0] 	baud_counter;
    logic							baud_pulse;
	
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) 	baud_counter <= '0;
        else begin
            if (baud_pulse) 	baud_counter <= '0;
            else 			baud_counter <= baud_counter +'d1;
        end
    end
	
    assign baud_pulse = (baud_counter == BAUD_COUNTER_MAX-1); 
	
	/*-------------------------------------------
	|			Shifting Data Out 				|				 
	-------------------------------------------*/
    logic [DATA_WIDTH-1:0]    data_shift_buf;
    logic                     data_set; 
    logic                     data_shift;
	
    always_ff @(posedge clk or negedge rst_n) begin 
    if (!rst_n)    data_shift_buf <= '0;
        else begin
            if      (data_set)      data_shift_buf <= data_i;
            else if (data_shift)    data_shift_buf <= data_shift_buf >> 1'b1;
        end 
    end
	
    assign data_set = ((state == IDEL) && (next == START)); 
    assign data_shift = ((state == SEND) && baud_pulse);
	
	/*-------------------------------------------
	|			Counting Data Sent 				|				 
	-------------------------------------------*/
    localparam DATA_COUNTER_MAX  = DATA_WIDTH;
    localparam DATA_COUNTER_SIZE = $clog2(DATA_COUNTER_MAX);
	
    logic [DATA_COUNTER_SIZE-1:0]    data_counter;
    logic							 data_done;
	
    always_ff @(posedge clk or negedge rst_n) begin  
        if (!rst_n)   data_counter <= '0; 
        else begin 
            if         (next != state)  data_counter <= '0;    // State change
            else if    (baud_pulse)     data_counter <= data_counter + 1'd1;
            
        end 
    end
	
    assign data_done = (data_counter == DATA_COUNTER_MAX-1);
	
	/*-------------------------------------------
	|		tx_ready Rising Edge Detection		|				 
	-------------------------------------------*/
    logic [1:0]	tx_ready_rise_detect;
    logic 		tx_ready;

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    tx_ready_rise_detect <= '0; 
        else begin 
            if (baud_pulse)    tx_ready_rise_detect <= {tx_ready_rise_detect[0], tx_ready_i};
        end
    end
	
    assign tx_ready = tx_ready_rise_detect[0] && !tx_ready_rise_detect[1];
	
	/*-------------------------------------------
	|				State Machine				|				 
	-------------------------------------------*/
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    state <= IDEL;
        else           state <= next;
    end
	
	// Next state logic
    always_comb begin 
        case (state)
            IDEL    :    if (tx_ready && rx_ready_i)     next = START;
			             else                            next = IDEL;
            START   :    if (baud_pulse)                 next = SEND;
			             else                            next = START; 
            SEND    :    if (data_done && baud_pulse)    next = STOP;
			             else                            next = SEND;
            STOP    :	 if (baud_pulse)                 next = IDEL;
			             else                            next = STOP;
            default :                                    next = IDEL;
            endcase 
    end
	
    // Output logic
    localparam logic TX_IDEL 	= 1'b1;
    localparam logic TX_START 	= 1'b0; 
    localparam logic TX_STOP 	= 1'b1;
	
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n )    data_o <= '0;
        else begin
            case (next)
                IDEL  :    data_o <= TX_IDEL;
                START :    data_o <= TX_START;
                SEND  :    data_o <= data_shift_buf[0];
                STOP  :    data_o <= TX_STOP;
            endcase
        end	
    end

endmodule