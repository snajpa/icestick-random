module ws2811_sender
	#(
		parameter NUM_LEDS = 4,
		parameter SYSTEM_CLOCK = 50_000_000
	)(
	input	clk,
	input 	rst,

	input [NUM_LEDS*24 - 1:0]	datai,
	output reg	do,
	output reg 	sending
	);

	localparam integer NUM_BITS = NUM_LEDS*24;
   
	function integer log2;
		input integer                    value;
		begin
		 value = value-1;
		 for (log2=0; value>0; log2=log2+1)
		   value = value>>1;
		end
	endfunction

	localparam integer CYCLE_COUNT         = SYSTEM_CLOCK / 800000;
	localparam integer H0_CYCLE_COUNT      = 0.32 * CYCLE_COUNT;
	localparam integer H1_CYCLE_COUNT      = 0.64 * CYCLE_COUNT;
	localparam integer CLOCK_DIV_WIDTH     = log2(CYCLE_COUNT);
		       
	localparam integer RESET_COUNT         = 100 * CYCLE_COUNT;
	localparam integer RESET_COUNTER_WIDTH = log2(RESET_COUNT);

	reg [RESET_COUNTER_WIDTH-1:0]         reset_counter; 
	reg [CLOCK_DIV_WIDTH-1:0]             clock_div;           // Clock divider for a cycle

	localparam STATE_PRERESET = 3'd0;
	localparam STATE_RESET 	  = 3'd1;
	localparam STATE_PRESEND      = 3'd2;
	localparam STATE_SEND = 3'd3;
	localparam STATE_POST = 3'd4;
	localparam STATE_FINISHED = 3'd5;
	localparam STATE_LOADBUFFER = 3'd6;

	reg [3:0]	state;
	reg [log2(NUM_BITS):0] current_bit;

	reg [NUM_LEDS*24 - 1:0] buffer;
	
	always @ (posedge clk) begin

		if(rst) begin

			state <= STATE_PRERESET;
			sending <= 0;

		end
		else begin
			
			case (state)
				STATE_PRERESET: begin

					do <= 0;
					reset_counter <= 0;
					state <= STATE_RESET;
				end
				STATE_RESET: begin
					if ( reset_counter == RESET_COUNT-1) begin
						state <= STATE_LOADBUFFER;
					end		
					else begin
						reset_counter <= reset_counter + 1;
					end
				end
				STATE_LOADBUFFER: begin
					buffer <= datai;
					current_bit <= 0;
					state <= STATE_PRESEND;
				end
				STATE_PRESEND: begin
					clock_div <= 0;
					state <= STATE_SEND;
					do <= 1;	
					sending <= 1;
				end
				STATE_SEND: begin
					if(datai[current_bit] == 0 && clock_div >= H0_CYCLE_COUNT) begin
						do <= 0;
					end
					else if(datai[current_bit] == 1 && clock_div >= H1_CYCLE_COUNT) begin
						do <= 0;
					end
					if( clock_div == CYCLE_COUNT-1) begin
						state <= STATE_POST;
					end
					else begin
						clock_div <= clock_div + 1;
					end
				end
				STATE_POST: begin
					if ( current_bit != NUM_BITS-1 ) begin
						current_bit <= current_bit + 1;
						state <= STATE_PRESEND;
					end
					else begin
						state <= STATE_FINISHED;
					end
				end
				STATE_FINISHED: begin
					sending <= 0;
					current_bit <= 0;
					state <= STATE_LOADBUFFER;
				end
			endcase
		end


	end
endmodule

module top (
	clk,
	LED1
);
	input clk;
	output LED1;

	reg rst = 0;
	reg busy;
	reg [20*24-1:0] in = 'h000000;
	reg do;

ws2811_sender
#(
	.NUM_LEDS(20),
	.SYSTEM_CLOCK(12000000)
) sender (
	.clk(clk),
	.rst(rst),
	.datai(in),
	.do(do),
	.sending(busy)
);

always @ (posedge clk) begin
	LED1 <= do;
end
	
endmodule


