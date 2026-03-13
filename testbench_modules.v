`timescale 1ns / 1ps

module tb_IAMS;

parameter MESSAGE_WIDTH = 4;
parameter PROBABILITY_WIDTH = 6;
parameter M = 2;
parameter N = 4;

// DUT signals
reg clk;
reg rst;
reg decode_enable;
reg load_input;
reg signed [MESSAGE_WIDTH-1:0] gamma_input;

wire [N-1:0] codeword;
wire calculated;


// Instantiate DUT
IAMS #(
    .MESSAGE_WIDTH(MESSAGE_WIDTH),
    .PROBABILITY_WIDTH(PROBABILITY_WIDTH),
    .M(M),
    .N(N)
) dut (
    .clk(clk),
    .rst(rst),
    .decode_enable(decode_enable),
    .load_input(load_input),
    .gamma_input(gamma_input),
    .codeword(codeword),
    .calculated(calculated)
);


// Clock generation
always #5 clk = ~clk;


// LLR test vector
reg signed [MESSAGE_WIDTH-1:0] llr_vector [0:N-1];

integer i;


// Initialize LLRs
initial begin
    llr_vector[0] =  3;
    llr_vector[1] = -2;
    llr_vector[2] =  1;
    llr_vector[3] = -3;
end


// Simulation control
initial begin

clk = 0;
rst = 1;
decode_enable = 0;
load_input = 0;
gamma_input = 0;


// Reset
#20;
rst = 0;


// Enable decoder
#10;
decode_enable = 1;


// Load LLR values sequentially
for(i = 0; i < N; i = i + 1)
begin
    @(posedge clk);
    load_input = 1;
    gamma_input = llr_vector[i];
end


// Stop loading
@(posedge clk);
load_input = 0;


// Wait for decoder to finish
wait(calculated == 1);


// Print result
$display("=================================");
$display("Decoded codeword = %b", codeword);
$display("=================================");


// End simulation
#50;
$finish;

end


// Monitor signals
initial begin
    $monitor("time=%0t load=%b gamma=%d calculated=%b codeword=%b",
              $time, load_input, gamma_input, calculated, codeword);
end


// Waveform dump
initial begin
    $dumpfile("iams_decoder.vcd");
    $dumpvars(0,tb_IAMS);
end


endmodule