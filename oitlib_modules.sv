
/*
// ============================================================================
// Generates a multiplexer.
// COUNT:  The number of input vectors
// WIDTH:  The number of bits in each input vector
//
// select: A vector which selects between the given inputs
// in:     A vector containing each input
// out:    The multiplexed output
// ============================================================================
module kMux #( parameter COUNT = 2, parameter WIDTH = 1 )
(	input      [kBits( COUNT ) - 1:0] select
,   input      [COUNT * WIDTH  - 1:0] in
,   output reg [        WIDTH  - 1:0] out
);
generate
	always @ ( select or in )
	for ( int i = 0; i < WIDTH; i += 1 )
	begin
		reg [COUNT - 1:0] tmp;
		for ( int s = 0; s < COUNT; s += 1 )
			tmp[s] = &
			{   in[i + s * WIDTH]
			,   select ^ ~s[kBits( COUNT ) - 1:0]
			};

		out[i] = |tmp;
	end
endgenerate
endmodule

// ============================================================================
// Generates a decoder.
// COUNT:  The number of states to decode
// ACTIVE: Determines the active state
// ============================================================================
module kDecoder #( parameter COUNT = 0, parameter ACTIVE = 1 )
(   input  [kBits( COUNT ) - 1:0] in,
    output reg [COUNT          - 1:0] out
);
generate
	always @ ( in )
	for ( int i = 0; i < COUNT; i += 1 )
		out[i] = ACTIVE
			?  &{ in ^ ~i[kBits( COUNT ) - 1:0] }  // Active High
			: ~&{ in ^ ~i[kBits( COUNT ) - 1:0] }; // Active Low
endgenerate
endmodule

// ============================================================================
// A Half Adder, calculates the sum of two bits.
// in:  A vector containing each of the input values
// out: A vector containing the sum and carry out bits
// ============================================================================
module kHalfAdder
(   input  [1:0] in
,   output [1:0] out
);
	assign out[0] = in[1] ^ in[0];
	assign out[1] = in[1] & in[0];
endmodule

// ============================================================================
// A Full Adder, calculates the sum of three bits.
// in:  A vector containing each of the input values
// out: A vector containing the sum and carry out bits
// ============================================================================
module kFullAdder
(   input  [2:0] in
,   output [1:0] out
);
	assign out[0] = in[2] ^ in[1] ^ in[0];
	assign out[1] = ( in[2] & in[1] )
	              | ( in[2] & in[0] )
	              | ( in[1] & in[0] );
endmodule

// ============================================================================
// Generates an adder.
// WIDTH_1: The width of the first input vector
// WIDTH_0: The width of the second input vector
//
// in:      A vector containing the two input vectors
// out:     A vector containing the sum of each input
//
// NOTE( Keith ):
//     The output vector's width is 1 larger than the max of the two inputs.
// ============================================================================
module kAdder #( parameter WIDTH_1 = 0, parameter WIDTH_0 = 0 )
(   input  [WIDTH_1 + WIDTH_0    - 1:0] in,
    output [kMax( WIDTH_1, WIDTH_0 ):0] out
);
generate
	parameter WIDTH_OUT = kMax( WIDTH_1, WIDTH_0 ) + 1;

	wire                 temp;
	wire [WIDTH_1 - 1:0] in_1;
	wire [WIDTH_0 - 1:0] in_0;
	assign { in_1, in_0 } = in;

	if ( WIDTH_0 == 1 && WIDTH_1 == 1 )
		kHalfAdder( in, out );
	else if ( WIDTH_1 > WIDTH_0 )
	begin
		kAdder #( WIDTH_1 - 1, WIDTH_0 )
		(   { in_1[WIDTH_1 - 2:0], in_0 }
		,   { temp, out[WIDTH_OUT - 3:0] }
		);
		kHalfAdder
		(   { in_1[WIDTH_1 - 1], temp }
		,   out[WIDTH_OUT - 1:WIDTH_OUT - 2]
		);
	end
	else if ( WIDTH_1 < WIDTH_0 )
	begin
		kAdder #( WIDTH_1, WIDTH_0 - 1 )
		(   { in_1, in_0[WIDTH_0 - 2:0] }
		,   { temp, out[WIDTH_OUT - 3:0] }
		);
		kHalfAdder
		(   { in_0[WIDTH_0 - 1], temp }
		,   out[WIDTH_OUT - 1:WIDTH_OUT - 2]
		);
	end
	else
	begin
		kAdder #( WIDTH_1 - 1, WIDTH_0 - 1 )
		(   { in_1[WIDTH_1 - 2:0], in_0[WIDTH_0 - 2:0] }
		,   { temp, out[WIDTH_OUT - 3:0] }
		);
		kFullAdder
		(   { in_1[WIDTH_1 - 1], in_0[WIDTH_0 - 1], temp }
		,   out[WIDTH_OUT - 1:WIDTH_OUT - 2]
		);
	end
endgenerate
endmodule

// ============================================================================
// Generates a 7-segment display decoder.
// ACTIVE: Determines the active state. This should be 1 for common-cathode
//         displays and 0 for common-anode displays.
//
// in:     A vector containing binary coded hexidecimal digit
// out:    The decoded output for the display, bits set to ACTIVE are on
// ============================================================================
module k7SegDecoder #( parameter ACTIVE = 1 )
(   input      [3:0] in
,   output reg [7:0] out
);
generate
	always @ ( in )
	case ( in )
		4'h0:    out = { 8{ |ACTIVE } } ^ 8'b11000000;
		4'h1:    out = { 8{ |ACTIVE } } ^ 8'b11111001;
		4'h2:    out = { 8{ |ACTIVE } } ^ 8'b10100100;
		4'h3:    out = { 8{ |ACTIVE } } ^ 8'b10110000;
		4'h4:    out = { 8{ |ACTIVE } } ^ 8'b10011001;
		4'h5:    out = { 8{ |ACTIVE } } ^ 8'b10010010;
		4'h6:    out = { 8{ |ACTIVE } } ^ 8'b10000010;
		4'h7:    out = { 8{ |ACTIVE } } ^ 8'b11111000;
		4'h8:    out = { 8{ |ACTIVE } } ^ 8'b10000000;
		4'h9:    out = { 8{ |ACTIVE } } ^ 8'b10010000;
		4'hA:    out = { 8{ |ACTIVE } } ^ 8'b10001000;
		4'hB:    out = { 8{ |ACTIVE } } ^ 8'b10000011;
		4'hC:    out = { 8{ |ACTIVE } } ^ 8'b11000110;
		4'hD:    out = { 8{ |ACTIVE } } ^ 8'b10100001;
		4'hE:    out = { 8{ |ACTIVE } } ^ 8'b10000110;
		4'hF:    out = { 8{ |ACTIVE } } ^ 8'b10001110;
		default: out = 8'bxxxxxxxx;
	endcase
endgenerate
endmodule

// ============================================================================
// Generates a binary counter.
// COUNT: The number of counts
// ASYNC: Determines whether the reset is synchronous or asynchronous
//
// clock: A clock
// reset: Sets out to 0
// out:   The current count
// ============================================================================
module kBinCounter #( parameter COUNT = 0, parameter ASYNC = 1 )
(   input                             clock
,   input                             reset
,   output reg [kBits( COUNT ) - 1:0] out
);
generate
	parameter POWER_OF_2 = ( COUNT == kPow( 2, kLog( 2, COUNT ) ) );
	parameter OUT_WIDTH  = kBits( COUNT );
	parameter LAST       = COUNT - 1;

	wire [OUT_WIDTH - 1:0] inc;
	wire [OUT_WIDTH - 1:0] next;
	wire                   temp;

	kAdder #( 1, OUT_WIDTH )a1( { 1'b1, out }, inc );

	// Determine next output value
	if ( POWER_OF_2 && ASYNC )
		assign next = inc;
	else
	begin
		if ( POWER_OF_2 ) assign temp = reset;
		else if ( ASYNC ) assign temp =         &( out ^ ~LAST );
		else              assign temp = reset | &( out ^ ~LAST );

		kMux #( 2, OUT_WIDTH )
		m1(   temp
		,   { { OUT_WIDTH{ 1'b0 } }, inc }
		,   next
		);
	end

	// Build Flip Flops
	if ( ASYNC )
		always @ ( posedge clock or posedge reset )
		out = reset ? 0 : next;
	else
		always @ ( posedge clock )
		out = next;
endgenerate
endmodule

// ============================================================================
// Generates a latch.
// WIDTH:  The number of bits to latch
//
// clock:  A clock
// enable: Latches the input
// in:     The input
// out:    The output
// ============================================================================
module kLatch #( parameter WIDTH = 0, parameter ACTIVE = 1 )
(   input                    clock
,   input                    enable
,   input      [WIDTH - 1:0] in
,   output reg [WIDTH - 1:0] out
);
generate
	wire [WIDTH - 1:0] tmp;
	kMux #( 2, WIDTH )( enable == ACTIVE, { in, out }, tmp );

    always @ ( posedge clock )
		out = tmp;
endgenerate
endmodule
*/