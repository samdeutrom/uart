/*
    Module to transmit single word over UART
    created by: Sam Deutrom
    date create: 02/04/23
    date last modified: 02/04/23
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
    logic 		start_data_recieve;
    

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    data_i_fall_detect <= '0; 
        else           data_i_fall_detect <= {data_i_fall_detect[0], data_i};
    end
	
    assign start_data_recieve = ((state == IDEL) && 
                                 (!data_i_fall_detect[0] && data_i_fall_detect[1]));
                                 
    /*-------------------------------------------
	|			Baud Rate Generator				|				 
	-------------------------------------------*/
    localparam int BAUD_COUNTER_MAX = CLK_FREQ/BAUD_RATE; 
    localparam int HALF_BAUD_COUNTER_MAX = BAUD_COUNTER_MAX/2;
    localparam int HALF_BAUD_COUNTER_SZIE = $clog2(HALF_BAUD_COUNTER_MAX);
    
    logic [HALF_BAUD_COUNTER_SZIE-1:0] 	half_baud_counter;
    logic							    half_baud_pulse;
    logic                               counter_enabled;
    
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)     half_baud_counter <= '0;  
        else begin
            if (counter_enabled) begin
                if (half_baud_pulse)    half_baud_counter <= '0;
                else                    half_baud_counter <= half_baud_counter + 1'b1;
            end else    half_baud_counter <= '0;
        end
    end
    
    assign half_baud_pulse = (half_baud_counter == HALF_BAUD_COUNTER_MAX-1);
    assign counter_enabled = (state != IDEL);

    /*-------------------------------------------
	|           sample_pulse Pulse Generator          |				 
	-------------------------------------------*/
    logic [1:0] pulse_counter;
    logic [1:0] sample_pulse_reg;
    logic       sample_pulse;
    
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)     pulse_counter <= '0;   
        else begin
            if (counter_enabled) begin
                if (half_baud_pulse)    pulse_counter <= pulse_counter + 1'b1;
            end else    pulse_counter <= '0;
        end
    end
   

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    sample_pulse_reg <= '0;   
        else           sample_pulse_reg <= {sample_pulse_reg[0], pulse_counter[0]};
    end
    
    assign sample_pulse = (!sample_pulse_reg[1] && sample_pulse_reg[0]);
    
    /*-------------------------------------------
	|                Data Shifting              |				 
	-------------------------------------------*/
    localparam int DATA_COUNTER_MAX  = 10; // add stop bit and start bit 
    localparam int DATA_COUNTER_SIZE = $clog2(DATA_COUNTER_MAX);
    
    logic  [9:0]         data_o_reg;
    logic  [DATA_COUNTER_SIZE-1:0]  data_counter;
    logic                           sample;
    logic                           sampling_done;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)  data_counter <= '0;
        else begin
            if (data_counter == DATA_COUNTER_MAX)  data_counter <= '0;
            else if (sample_pulse)                   data_counter <= data_counter + 1'd1;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)  data_o_reg <= '0;
        else begin
            if (sample_pulse)  data_o_reg <= {data_i, data_o_reg[10-1:1]};
        end
    end
    
    assign sample = (sample_pulse && (state == RECEIVING)); 
    assign sampling_done = data_counter == DATA_COUNTER_MAX;
    
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
            IDEL    :    if (start_data_recieve)  next = START;
			             else                     next = IDEL;
            START   :    if (half_baud_pulse)     next = RECEIVING;
		 	             else                     next = START; 
            RECEIVING  :  if (sampling_done)      next = IDEL;
			             else                     next = RECEIVING; 
            endcase 
    end
	
      // Output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n )    data_o <= '0;
        else begin
            data_o <= 'Z;
            case (next)
                IDEL  :  if (data_valid)  data_o <= data_o_reg[8:1];
            endcase
        end	
    end
  


endmodule