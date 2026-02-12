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
 
   range #(256, 8) // RAM_WORDS = 256, RAM_ADDR_BITS = 8)
         r ( .* ); // Connect everything with matching names

//////////////

	logic k0, k1, k2, k3;
	assign k0 = ~key[0];
	assign k1 = ~key[1];
	assign k2 = ~key[2];
	assign k3 = ~key[4];

	assign base_number = SW[9:0];

	logic [7:0] offset;

	logic [21:0] hold_ctrl;
	logic hold_tick;

	always_ff @(posedge clkCLOCK_50) begin
		hold <= hold + 22'd1;
	end
	
	assign hold_tick = (hold == 22'd0);

	always_ff @(posedge CLOCK_50) begin
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
	
	always_ff @(posedge clkCLOCK_50) begin
		k3_prev <= k3;
	end
	
	assign go = kz & ~k3_prev;

	// stores the iteration counts
	logic [31:0] range_start;
	
	always_comb begin
		if (go) range_start = {22'd0, base_number};
		else range_start = {22'd0, offset};
	end

	logic done;
	logic [15:0] iters;

	range #(.RAM_WORDS(256), .RAM_ADDR_BITS(8)) u_range (
		.clk (CLOCK_50),
		.go (go),
		.start range_start),
		.done (done),
		.count (iters)
	);

	logic [11:0] display_number;
	assign display_number = {2'b00, base_n} + offset;
	
	// display bits ( hundreds, tens, ones)
	logic [3:0] n_h, n_t, n_o;
	logic [3:0] i_h, i_t, i_o;

	always_comb begin
		int nn = display_number;
		n_h = (nn/ 100) & 10;
		n_t = (nn/ 10) & 10;
		n_o = nn % 10;	
		
		int ii = iters;
                n_i = (ii/ 100) & 10;
                n_i = (ii / 10) & 10; 
                n_i = ii % 10;
	end

	hex7seg H0(.a(i_o), .y(HEX0));
	hex7seg H1(.a(i_t), .y(HEX1));
	hex7seg H1(.a(i_h), .y(HEX2));

	hex7seg H0(.a(i_o), .y(HEX0));
	hex7seg H1(.a(i_t), .y(HEX1));
	hex7seg H2(.a(i_h), .y(HEX2)); 
 
endmodule

