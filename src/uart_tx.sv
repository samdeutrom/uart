/*
    Module to transmit single word over UART
    created by: Sam Deutrom
    date last modified: 05/04/23
*/

import uart_tx_pkg::*;

module uart_tx
    #(parameter	
        CLK_FREQ   = 100_000_000,
        BAUD_RATE  = 115200,
        DATA_WIDTH = 8)
        (
        input  logic                    clk, rst_n,
        input  logic                    tx_send_i,
        input  logic  [DATA_WIDTH-1:0]  data_i,
        output logic                    data_o);
	
	// State machine state defined in uart_tx_pkg.sv
	tx_states_e state;
	tx_states_e next;
	
    /*-------------------------------------------
    |           Baud Rate Generator             |				 
    -------------------------------------------*/
    localparam int BAUD_COUNTER_MAX = CLK_FREQ/BAUD_RATE; 
    localparam int HALF_BAUD_COUNTER_MAX = BAUD_COUNTER_MAX/2; 
    localparam int BAUD_COUNTER_SZIE = $clog2(BAUD_COUNTER_MAX);
	
    logic  [BAUD_COUNTER_SZIE-1:0]  baud_counter;
    logic                           baud_counter_done;;
    logic                           baud_clk;
    logic                           baud_clk_0;
    
	// Increment baud_counter logic
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)  baud_counter <= '0;
        else begin
            if (baud_counter_done) 	baud_counter <= '0;
            else 			        baud_counter <= baud_counter +'d1;
        end
    end
    
    // Generate baud_clk logic
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)  baud_clk <= '0;
        else begin
            if (baud_clk_0)  baud_clk <= '0;
            else 			 baud_clk <= '1;
        end
    end

    assign baud_clk_0 = (baud_counter <= HALF_BAUD_COUNTER_MAX-1);
    assign baud_counter_done = (baud_counter == BAUD_COUNTER_MAX-1);
    
    /*-------------------------------------------
    |         Sync tx_ready to baud_clk         |				 
    -------------------------------------------*/
    localparam int TX_STRETCH_COUNTER = BAUD_COUNTER_MAX+HALF_BAUD_COUNTER_MAX; //1.5 times new clk domain
    localparam int TX_STRETCH_SIZE = $clog2(TX_STRETCH_COUNTER);
    
    logic  [1:0]                  tx_send_buf;
    logic                         tx_send_rise;
    logic  [TX_STRETCH_SIZE-1:0]  tx_send_counter;
    logic                         tx_send_stretch;
    logic                         tx_send_counter_done; 
    
    // Detect posedge of tx_send_i logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)  tx_send_buf <= '0; 
        else         tx_send_buf <= {tx_send_buf[0], tx_send_i};
    end
    
    assign tx_send_rise = (tx_send_buf[1] && !tx_send_buf[0]); 
    
    // Increment tx_send_counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)  tx_send_counter <= '0; 
        else begin
            if      (tx_send_counter_done)  tx_send_counter <= '0; 
            else if (tx_send_stretch)       tx_send_counter <= tx_send_counter + 1'd1; 
        end
    end
    
    assign tx_send_counter_done = (tx_send_counter == TX_STRETCH_COUNTER-1);
    
    // set tx_send_stretch logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)  tx_send_stretch <= '0; 
        else begin 
            if      (tx_send_counter_done)  tx_send_stretch <= '0;
            else if (tx_send_rise)          tx_send_stretch <= '1;
        end
    end
    
    /*-------------------------------------------
    |            Shifting Data Out              |				 
    -------------------------------------------*/
    logic  [DATA_WIDTH-1:0]  data_shift_buf;
    logic                    data_set; 
    logic                    data_shift;
	
    // shift data in data_shift_buf logic
    always_ff @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n )  data_shift_buf <= '0;
        else begin
            if      (data_set)    data_shift_buf <= data_i;
            else if (data_shift)  data_shift_buf <= data_shift_buf >> 1'b1; 
        end
    end
	
    assign data_set = ((state == IDEL) && (next == START)); 
    assign data_shift = (state == SEND);
	
    /*-------------------------------------------
    |           Counting Data Sent              |				 
    -------------------------------------------*/
    localparam DATA_COUNTER_MAX  = DATA_WIDTH;
    localparam DATA_COUNTER_SIZE = $clog2(DATA_COUNTER_MAX);
	
    logic  [DATA_COUNTER_SIZE-1:0]  data_counter;
    logic							data_done;
    logic                           data_counter_enable;
    logic                           state_change;
	
    // Increment data_counter logic
    always_ff @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n)  data_counter <= '0;
        else begin
            if      (state_change || data_done)  data_counter <= '0;
            else if (data_counter_enable)        data_counter <= data_counter + 1'b1; 
        end
    end
    	
    assign data_done = (data_counter == DATA_COUNTER_MAX-1);
    assign data_counter_enable = (state == SEND);
    assign state_change = (state != next);
	
    /*-------------------------------------------
    |               State Machine               |				 
    -------------------------------------------*/
    always_ff @(posedge baud_clk or negedge rst_n) begin 
        if (!rst_n)  state <= IDEL;
        else         state <= next;
    end
	
	// Next state logic
    always_comb begin 
        case (state)
            IDEL    :  if (tx_send_stretch)  next = START;
			           else                  next = IDEL;
            START   :                        next = SEND;
            SEND    :  if (data_done)        next = STOP;
			           else                  next = SEND;
            STOP    :	                     next = IDEL;
            default :                        next = IDEL;
        endcase 
    end
	
    // Output logic
    localparam logic TX_IDEL   = 1'b1;
    localparam logic TX_START  = 1'b0; 
    localparam logic TX_STOP   = 1'b1;
	
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n )    data_o <= '0;
        else begin
            case (state)
                IDEL  : data_o <= TX_IDEL;
                START : data_o <= TX_START;
                SEND  : data_o <= data_shift_buf[0];
                STOP  : data_o <= TX_STOP;
            endcase
        end	
    end

endmodule