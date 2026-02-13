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
   
	assign clk = CLOCK_50;

/////////////

	logic k0 = 1'b0, k1 = 1'b0, k2, k3;
	logic k0_raw, k1_raw;
	logic [9:0] base_number;
	
	// changed these to raw keys for debouncing later
	assign k0_raw = ~KEY[0];
	assign k1_raw = ~KEY[1];
	assign k2 = ~KEY[2];
	assign k3 = ~KEY[3];
	// we used a buffer to debounce the key so the buffer delays
	// when the value begins incrementing
	//  update output only when buffer is all 0s or all 1
	logic [7:0] k0_buf = 8'd0, k1_buf = 8'd0;

	always_ff @(posedge clk) begin

		k0_buf <= {k0_buf[6:0], k0_raw};
		k1_buf <= {k1_buf[6:0], k1_raw};

		if (&k0_buf) k0 <= 1'b1;
		else if (~|k0_buf) k0 <= 1'b0;

		if (&k1_buf) k1 <= 1'b1;
		else if (~|k1_buf) k1 <= 1'b0;
	end

	assign LEDR[7:0] = base_number;

	assign base_number = SW[9:0];

	logic [7:0] offset = 8'd0;
	// buffer for key press delays and counter
	logic [21:0] hold_ctrl;
	logic hold_tick;
	logic k0_prev = 1'b0, k1_prev = 1'b0;
	logic [7:0] repeat_wait = 8'd0; 
	logic [7:0] repeat_start_ticks = 8'd2; // delay before repeating

	always_ff @(posedge clk) begin
		hold_ctrl <= hold_ctrl + 22'd1;
	end
	
	assign hold_tick = (hold_ctrl == 22'd0);
	// get the initial key press then delay after the buffer is full
	always_ff @(posedge clk) begin
		k0_prev <= k0;
		k1_prev <= k1;

		// if k2 is pressed reset the difference
		if (k2) begin
			offset <= 8'd0;
			repeat_wait <= repeat_start_ticks;

		// if only key 0 then increment
		end else if (k0 && !k1) begin
			// inc immediatley
			//
			if (!k0_prev) begin
				if (offset != 8'hFF) offset <= offset + 8'd1;
				repeat_wait <= repeat_start_ticks;

			//buffer delays the repeat incrementing
			end else if (hold_tick) begin
				if (repeat_wait != 8'd0) repeat_wait <= repeat_wait - 8'd1;
				else if (offset != 8'hFF) offset <= offset + 8'd1;
			end
			
		// if only key 1 then decrement
		end else if (k1 && !k0) begin

			// one press decrements immediately
			if (!k1_prev) begin

				if (offset != 8'h00) offset <= offset - 8'd1;
				repeat_wait <= repeat_start_ticks;

			// wait to start decrementing
			end else if (hold_tick) begin
				if (repeat_wait != 8'd0) repeat_wait <= repeat_wait - 8'd1;
				else if (offset != 8'h00) offset <= offset - 8'd1;
			end

		end else begin

			repeat_wait <= repeat_start_ticks;
		end
	end

	// creates the signal for when k3 is pressed
	// but so it doesnt go repeatedly
	logic k3_prev;
	
	always_ff @(posedge clk) begin
		k3_prev <= k3;
	end
	

	// number shown on HEX3-HEX5 which is the base n + the offset nubmer
	logic [31:0] range_start;

	assign go = k3 & ~k3_prev;
        assign range_start = {22'd0, base_number} + {24'd0, offset};
	// used a mux witht he go bit as the select bit so that
        // it starts at the base when go is 1 or base + offset wehn go is 0
        // before, we were start at the wrong position
	logic [31:0] range_start_mux;
	assign range_start_mux = go ? {22'd0, base_number} : {24'd0, offset};

	logic [15:0] iters;
	//logic [15:0] iters_display = 16'd0;
	//get the range from the range module
	range #(.RAM_WORDS(256), .RAM_ADDR_BITS(8)) u_range (
		.clk(clk),
		.go(go),
		.start(range_start_mux),
		.done(done),
		.count(iters)
	);

	//logic [11:0] display_number;
	// storage for the number to be displayed	
	logic [3:0] n_h, n_t, n_o;
	logic [3:0] i_h, i_t, i_o;
	// assigne these to the range adn iter numbers
	assign n_h = range_start[11:8];
	assign n_t = range_start[7:4];
	assign n_o = range_start[3:0];

	assign i_h = iters[11:8];
	assign i_t = iters[7:4];
	assign i_o = iters[3:0];
	// display them using hex7seg
	hex7seg H0(.a(i_o), .y(HEX0));
	hex7seg H1(.a(i_t), .y(HEX1));
	hex7seg H2(.a(i_h), .y(HEX2));

	hex7seg H3(.a(n_o), .y(HEX3));
	hex7seg H4(.a(n_t), .y(HEX4));
	hex7seg H5(.a(n_h), .y(HEX5)); 
	
	// these are from debugging
	// assign LEDR[9] = done;
	// assign LEDR[8] = go;
 
endmodule



