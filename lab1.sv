// CSEE 4840 Lab 1: Run and Display Collatz Conjecture Iteration Counts
//
// Spring 2026
//
// By: Owen Cooper and Maximilian Comfere
// Uni: odc2106 and mkc2182

module lab1( input logic        CLOCK_50,  // 50 MHz Clock input
	     
	     input logic [3:0] 	KEY, // Pushbuttons; KEY[0] is rightmost

	     input logic [9:0] 	SW, // Switches; SW[0] is rightmost

	     // 7-segment LED displays; HEX0 is rightmost
	     output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

	     output logic [9:0] LEDR // LEDs above the switches; LED[0] on right
	     );
	logic                        clk, go, done;
	logic [31:0]                 start;
	logic [15:0]                 count;

	logic [11:0]                 n;
   
	assign clk = CLOCK_50;

/////////////

	logic k0, k1, k2, k3;
	logic [9:0] base_number;

	assign k0 = ~KEY[0];
	assign k1 = ~KEY[1];
	assign k2 = ~KEY[2];
	assign k3 = ~KEY[3];

	assign LEDR[9:0] = base_number;

	assign base_number = SW[9:0];

	logic [7:0] offset;

	logic [21:0] hold_ctrl;
	logic hold_tick;

	always_ff @(posedge clk) begin
		hold_ctrl <= hold_ctrl + 22'd1;
	end
	
	assign hold_tick = (hold_ctrl == 22'd0);

	always_ff @(posedge clk) begin
		// if k2 is pressed reset the difference
		if (k2) begin
			offset <= 8'd0;
		end else if (hold_tick) begin
			// if only key 0 then increment
			if (k0 && !k1) begin
				if (offset != 8'hFF) offset <= offset + 8'd1;
			// if only key 1 then decrement
			end else if (k1 && !k0) begin
				if (offset != 8'h00) offset <= offset - 8'd1;
			end
		end
	end
	// creates the signal for when k3 is pressed
	// but so it doesnt go repeatedly
	logic k3_prev;
	
	always_ff @(posedge clk) begin
		k3_prev <= k3;
	end
	
	assign go = k3 & ~k3_prev;

	// stores the iteration counts
	logic [31:0] range_start;
	
	always_ff @(posedge clk) begin
		if (go) range_start <= {22'd0, base_number} + {24'd0, offset};
	end

	logic [15:0] iters;

	range #(.RAM_WORDS(256), .RAM_ADDR_BITS(8)) u_range (
		.clk(clk),
		.go(go),
		.start(range_start),
		.done(done),
		.count(iters)
	);

	logic [11:0] display_number;
	assign display_number = {2'b00, base_number} + offset;
	
	// display bits ( hundreds, tens, ones)
	logic [3:0] n_h, n_t, n_o;
	logic [3:0] i_h, i_t, i_o;

	always_comb begin
		n_h = (display_number / 100) % 10;
		n_t = (display_number / 10) % 10;
		n_o = display_number % 10;	
		
        i_h = (iters / 100) % 10;
        i_t = (iters / 10) % 10; 
        i_o = iters % 10;
	end

	hex7seg H0(.a(i_o), .y(HEX0));
	hex7seg H1(.a(i_t), .y(HEX1));
	hex7seg H2(.a(i_h), .y(HEX2));

	hex7seg H3(.a(n_o), .y(HEX3));
	hex7seg H4(.a(n_t), .y(HEX4));
	hex7seg H5(.a(n_h), .y(HEX5)); 
 
endmodule

