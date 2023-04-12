/*
    Module to transmit single word over UART
    created by: Sam Deutrom
*/

import uart_rx_pkg::*;

module uart_rx
    #(parameter	
        CLK_FREQ   = 100_000_000,
        BAUD_RATE  = 115200,
        DATA_WIDTH = 8
   )( 
        input  logic                    clk, rst_n,
	    input  logic                    data_i,
        output logic  [DATA_WIDTH-1:0]  data_o
	);
	
	// State machine state defined in uart_rx_pkg.sv
	rx_states_e state;
	rx_states_e next;
    
    /*-------------------------------------------
	|       data_i Falling Edge Detection       |				 
	-------------------------------------------*/
    logic [1:0]	data_i_fall_detect;
    logic 		start_data_receive;
    
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    data_i_fall_detect <= '0; 
        else           data_i_fall_detect <= {data_i_fall_detect[0], data_i};
    end
	
    assign start_data_receive = (!data_i_fall_detect[0] && data_i_fall_detect[1]);
                                 
     /*-------------------------------------------
    |           Baud Rate Generator             |				 
    -------------------------------------------*/
    localparam int BAUD_COUNTER_MAX = CLK_FREQ/BAUD_RATE; 
    localparam int HALF_BAUD_COUNTER_MAX = BAUD_COUNTER_MAX/2; 
    localparam int BAUD_COUNTER_SZIE = $clog2(BAUD_COUNTER_MAX);
	
    logic  [BAUD_COUNTER_SZIE-1:0]  baud_counter;
    logic                           baud_counter_enable;
    logic                           baud_counter_done;;
    logic                           baud_clk;
    logic                           baud_clk_0;
    
	// Increment baud_counter logic
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)  baud_counter <= '0;
        else begin
            if (baud_counter_done)         baud_counter <= '0;
            else if (baud_counter_enable)  baud_counter <= baud_counter + 1'd1;
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

    assign baud_counter_enable = (next == RECEIVING);
    assign baud_clk_0 = ((baud_counter <= HALF_BAUD_COUNTER_MAX-1) || (next == IDEL));
    assign baud_counter_done = (baud_counter == BAUD_COUNTER_MAX-1);

    
    /*-------------------------------------------
	|                Data Shifting              |				 
	-------------------------------------------*/
    
    localparam int RX_REGISTER_WIDTH = DATA_WIDTH + 2; // add stop bit and start bit
    localparam int DATA_COUNTER_MAX  = RX_REGISTER_WIDTH;  
    localparam int DATA_COUNTER_SIZE = $clog2(DATA_COUNTER_MAX);
    
    logic  [RX_REGISTER_WIDTH-1:0]  data_o_reg;
    logic  [DATA_COUNTER_SIZE-1:0]  data_counter;
    logic                           data_done;
    
    // increment data_counter 
    always_ff @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n)  data_counter <= '0;
        else begin 
            if (data_counter == DATA_COUNTER_MAX - 1)  data_counter <= 0;
            else                                       data_counter <= data_counter + 1'd1;
        end
    end
    
    always_ff @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n)  data_done <= '0;
        else begin 
            if (data_counter == DATA_COUNTER_MAX - 1)  data_done <= 1;
            else                                       data_done <= 0;
        end
    end
    
    always_ff @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n)  data_o_reg <= '0;
        else         data_o_reg <= {data_i, data_o_reg[RX_REGISTER_WIDTH-1:1]};
    end
     
    
    /*-------------------------------------------
	|                Validate Data              |				 
	-------------------------------------------*/
    logic data_valid;
    
    assign data_valid = ((data_o_reg[9]) && (!data_o_reg[0]) && (state == IDEL)); // Check start and stop bit
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
            IDEL       :  if (start_data_receive)  next = RECEIVING;
                          else                     next = IDEL;
            RECEIVING  :  if (data_done)           next = IDEL;
                          else                     next = RECEIVING;
            default    :                           next = IDEL;            
        endcase 
    end
	
      // Output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n )    data_o <= '0;
        else begin
            case (next)
                IDEL  : if (data_valid)  data_o <= data_o_reg[(RX_REGISTER_WIDTH-1)-1:1];
                RECEIVING : data_o <= data_o;
                default : data_o <= '0;
            endcase
        end	
    end
  


endmodule