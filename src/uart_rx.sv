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
    
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    data_i_fall_detect <= 2'b00; 
        else           data_i_fall_detect <= {data_i_fall_detect[0], data_i};
    end
	
    /*-------------------------------------------
    |           Baud Rate Generator             |				 
    -------------------------------------------*/
    localparam int BAUD_COUNTER_MAX = CLK_FREQ/BAUD_RATE; 
    localparam int HALF_BAUD_COUNTER_MAX = BAUD_COUNTER_MAX/2; 
    localparam int BAUD_COUNTER_SZIE = $clog2(BAUD_COUNTER_MAX);
	
    logic  [BAUD_COUNTER_SZIE-1:0]  baud_counter;
    
    // Flags
    logic   baud_counter_done;;
    logic   state_change; 
    
    // Flags Logic
    assign state_change = (state != next);
    assign baud_counter_done = (baud_counter == (BAUD_COUNTER_MAX-1));
    
	// Increment baud_counter logic
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)                 baud_counter <= {BAUD_COUNTER_SZIE{1'b0}};
        else begin
            if (baud_counter_done || state_change)  baud_counter <= {BAUD_COUNTER_SZIE{1'b0}};
            else                                    baud_counter <= baud_counter + 1'd1;
        end
    end
    
    /*-------------------------------------------
    |                Data Counting              |				 
    -------------------------------------------*/
    localparam int DATA_COUNTER_MAX  = DATA_WIDTH+1; // Need to be able to count up to the data width  
    localparam int DATA_COUNTER_SIZE = $clog2(DATA_COUNTER_MAX);
    
    logic  [DATA_COUNTER_SIZE-1:0]  data_counter;
    
    //Flags
    logic                           data_done;
    // Flags Logic
    assign data_done = (data_counter == DATA_COUNTER_MAX-1); 
  
    // increment data_counter 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)  data_counter <= {DATA_COUNTER_SIZE{1'b0}};
        else begin 
            if      (data_done || state_change)     data_counter <= {DATA_COUNTER_SIZE{1'b0}};
            else if (baud_counter_done)                     data_counter <= data_counter + 1'b1;
        end
    end

    /*-------------------------------------------
	|				State Machine				|				 
	-------------------------------------------*/  
    localparam int RX_REGISTER_WIDTH = DATA_WIDTH;
    
    logic  [RX_REGISTER_WIDTH-1:0]  rx_shift_reg;
   
    // flags
    logic 	start_data_receive;
    logic   start_done;
    logic   start_error;
    logic   stop_done;
    logic   stop_error;
    // flag logic
    assign start_data_receive = (data_i_fall_detect[1] && !data_i_fall_detect[0]);
    assign  start_done = ((baud_counter == HALF_BAUD_COUNTER_MAX-1) && !data_i);
    assign  start_error = ((baud_counter == HALF_BAUD_COUNTER_MAX-1) && data_i);
    
    assign  stop_done = ((baud_counter == BAUD_COUNTER_MAX-1) && data_i);
    assign  stop_error = ((baud_counter == BAUD_COUNTER_MAX-1) && !data_i);
    
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n)    state <= IDEL;
        else           state <= next;
    end
    
	// Next state logic
    always_comb begin 
        case (state)
            IDEL        :   if      (start_data_receive)    next = START;
                            else                            next = IDEL;
            START       :   if      (start_done)            next = DATA;
                            else if (start_error)           next = ERROR;
                            else                            next = START;
            DATA        :   if      (data_done)             next = STOP;
                            else                            next = DATA;
            STOP        :   if      (stop_done)             next = IDEL;
                            else if (stop_error)            next = ERROR;
                            else                            next = IDEL;
            default     :                                   next = ERROR;            
        endcase 
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if  (!rst_n)    rx_shift_reg <= {DATA_WIDTH{1'b0}};
        else begin
            rx_shift_reg <= rx_shift_reg;
            case (next)
            DATA        :   if (baud_counter_done)  rx_shift_reg <= {data_i, rx_shift_reg[(DATA_WIDTH-1):1]}; // shift LSB out
                            
            ERROR       :   rx_shift_reg <= {DATA_WIDTH{1'b1}};
            endcase
        end   
    end    
    
    assign data_o = (state == IDEL) ? rx_shift_reg : {DATA_WIDTH{1'b0}};  

endmodule