`timescale 1ns/1ns

/*
Test bench for uart_tx.sv
*/

module uart_tx_tb(); 




// PARAMETERS 
localparam PERIOD = 10;

logic 		clk;
logic 		rst_n; 
// For tx
logic 		tx_send_i;
logic [7:0] tx_data_i;
logic 		tx_data_o; // rx_data_in
// For rx


// create clock signal
initial begin
	clk <= 0;
	forever #(PERIOD/2) clk = ~clk;
end 

// initial reset
task reset(); 
    begin 
        rst_n <= 1;
        @(posedge clk); rst_n = 0;
        #(PERIOD*5); rst_n = 1;
    end
endtask 


uart_tx tx (
				.clk(clk),
				.rst_n(rst_n),
				.tx_send_i(tx_send_i),
                .rx_ready_i(1'b1),
				.data_i(tx_data_i),
				.data_o(tx_data_o)
			); 
            

           

initial begin
    reset();
	tx_send_i = 0;
	tx_data_i = '0;
	#(PERIOD*10000);
	#(PERIOD*100);
	tx_data_i = 8'b01010101;
	#(PERIOD*10000);
	tx_send_i = 1;
	#(PERIOD*10);
	tx_send_i = 0;
	#(PERIOD*50000);
	
	$stop();

end









endmodule