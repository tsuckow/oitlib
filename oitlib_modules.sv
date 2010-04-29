// ============================================================================
// Generates a multiplexer.
// COUNT:  The number of input vectors
// WIDTH:  The number of bits in each input vector
//
// select: A vector which selects between the given inputs
// in:     A vector containing each input
// out:    The multiplexed output
// Author: Keith Majhor
// Updated: Thomas Suckow
// ============================================================================
module oitMux #( parameter COUNT = 2, parameter WIDTH = 1 )
(
input      [oitBits( COUNT ) - 1:0] select,
input      [COUNT * WIDTH  - 1:0] in,
output reg [        WIDTH  - 1:0] out
);

`include "oitlib_functions.sv"

generate
	always @ ( select or in )
	for ( int i = 0; i < WIDTH; i += 1 )
	begin
		reg [COUNT - 1:0] tmp;
		for ( int s = 0; s < COUNT; s += 1 )
			tmp[s] = &
			{   in[i + s * WIDTH]
			,   select ^ ~s[oitBits( COUNT ) - 1:0]
			};

		out[i] = |tmp;
	end
endgenerate

endmodule

// ============================================================================
// Generates a decoder.
// COUNT:  The number of states to decode
// ACTIVE: Determines the active state
// Author: Keith Majhor
// Updated: Thomas Suckow
// ============================================================================
module oitDecoder #( parameter COUNT = 0, parameter ACTIVE = 1 )
(
input      [oitBits( COUNT ) - 1:0] in,
output reg [COUNT          - 1:0]   out
);

`include "oitlib_functions.sv"

generate
	always @ ( in )
	for ( int i = 0; i < COUNT; i += 1 )
		out[i] = ACTIVE
			?  &{ in ^ ~i[oitBits( COUNT ) - 1:0] }  // Active High
			: ~&{ in ^ ~i[oitBits( COUNT ) - 1:0] }; // Active Low
endgenerate

endmodule

// ============================================================================
// A Half Adder, calculates the sum of two bits.
// in:  A vector containing each of the input values
// out: A vector containing the sum and carry out bits
// Author: Keith Majhor
// Updated: Thomas Suckow
// ============================================================================
module oitHalfAdder
(
input  [1:0] in,
output [1:0] out
);
	assign out[0] = in[1] ^ in[0];
	assign out[1] = in[1] & in[0];
endmodule

// ============================================================================
// A Full Adder, calculates the sum of three bits.
// in:  A vector containing each of the input values
// out: A vector containing the sum and carry out bits
// Author: Keith Majhor
// Updated: Thomas Suckow
// ============================================================================
module oitFullAdder
(
input  [2:0] in,
output [1:0] out
);
	assign out[0] = in[2] ^ in[1] ^ in[0];
	assign out[1] = ( in[2] & in[1] )
	              | ( in[2] & in[0] )
	              | ( in[1] & in[0] );
endmodule

module debug #(parameter a=0,parameter b=0) (output x);

assign x = b;

endmodule

// ============================================================================
// Generates an adder.
// WIDTH_a: The width of the first input vector
// WIDTH_b: The width of the second input vector
//
// a:       A vector containing the two input vectors
// b:       A vector containing the two input vectors
// out:     A vector containing the sum of each input
//
// Author: Thomas Suckow
// ============================================================================
module oitAdder #( parameter WIDTH_a = 0, parameter WIDTH_b = 0 )
(
input  [WIDTH_a - 1:0]                a,
input  [WIDTH_b - 1:0]                b,
output [oitMax( WIDTH_a, WIDTH_b ):0] out
);

`include "oitlib_functions.sv"

parameter WIDTH_OUT = oitMax( WIDTH_a, WIDTH_b ) + 1;

wire [WIDTH_OUT - 2:0] carry;
genvar i;

generate

for (i=1; i < WIDTH_OUT - 1; i=i+1)
begin
  wire first, second;
  assign first  = (i<WIDTH_a)?a[i]:1'b0;
  assign second = (i<WIDTH_b)?b[i]:1'b0;
	oitFullAdder fa( { carry[i-1], first, second }, { carry[i], out[i] } );
end

endgenerate

oitHalfAdder fa0( { a[0], b[0] }, { carry[0], out[0] } );

assign out[ WIDTH_OUT - 1 ] = carry[ WIDTH_OUT - 2 ];

endmodule

// ============================================================================
// Generates a binary counter.
// COUNT: The number of counts
// ASYNC: Determines whether the reset is synchronous or asynchronous
//
// clock: A clock
// reset: Sets out to 0
// out:   The current count
// Author: Keith Majhor
// Updated: Thomas Suckow
// ============================================================================
module oitBinCounter #( parameter COUNT = 0, parameter ASYNC = 1 )
(
input                               clock,
input                               reset,
output reg [oitBits( COUNT ) - 1:0] out
);

`include "oitlib_functions.sv"

generate
	parameter POWER_OF_2 = ( COUNT == oitPow( 2, oitLog( 2, COUNT ) ) );
	parameter OUT_WIDTH  = oitBits( COUNT );
	parameter LAST       = COUNT - 1;

	wire [OUT_WIDTH - 1:0] inc;
	wire [OUT_WIDTH - 1:0] next;
	wire                   temp;

	oitAdder #( 1, OUT_WIDTH ) a1 ( 1'b1, out, inc );

	// Determine next output value
	if ( POWER_OF_2 && ASYNC )
		assign next = inc;
	else
	begin
		if ( POWER_OF_2 ) assign temp = reset;
		else if ( ASYNC ) assign temp =         &( out ^ ~LAST );
		else              assign temp = reset | &( out ^ ~LAST );

		oitMux #( 2, OUT_WIDTH )
		m1 (   temp
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
// Author: Keith Majhor
// Updated: Thomas Suckow
// ============================================================================
module oitLatch #( parameter WIDTH = 0, parameter ACTIVE = 1 )
(
input                    clock,
input                    enable,
input      [WIDTH - 1:0] in,
output reg [WIDTH - 1:0] out
);

generate
	wire [WIDTH - 1:0] tmp;
	oitMux #( 2, WIDTH ) lmux ( enable == ACTIVE, { in, out }, tmp );

    always @ ( posedge clock )
		out = tmp;
endgenerate

endmodule
/* Filetype tags for editors.
* vim: set filetype=verilog : 
*/
