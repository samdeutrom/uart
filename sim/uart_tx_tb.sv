`timescale 1ns/1ns

/*
Test bench for uart_tx.sv
*/

module uart_tx_tb(); 




// PARAMETERS 
localparam PERIOD = 10;

logic 		clk;
logic 		reset; 
logic 		tx_ready_i;
logic 		rx_ready_i;
logic [7:0] data_i;
logic 		data_o;


// create clock signal
initial begin
	clk <= 0;
	forever #(PERIOD/2) clk = ~clk;
end 

// initial reset
initial begin 
	reset <= 1;
	@(posedge clk); reset = 0;
	#(PERIOD*5); reset = 1; 
end


uart_tx MUT (
				.clk(clk),
				.rst_n(reset),
				.tx_ready_i(tx_ready_i),
				.rx_ready_i(rx_ready_i),
				.data_i(data_i),
				.data_o(data_o)
			);


initial begin

	tx_ready_i = 0;
	rx_ready_i = 0;
	data_i = '0;
	
	#(PERIOD*10000);
	rx_ready_i = 1;
	#(PERIOD*100);
	data_i = 8'b01010101;
	#(PERIOD*10000);
	tx_ready_i = 1;
	#(PERIOD*1000);
	tx_ready_i = 0;
	#(PERIOD*100000);
	
	$stop();

end









endmodule