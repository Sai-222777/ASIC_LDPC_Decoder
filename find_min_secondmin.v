`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2026 05:49:00 PM
// Design Name: 
// Module Name: find_min_secondmin
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module find_min_secondmin
#(
    parameter DATA_WIDTH = 6,
    parameter SIZE = 8
)(
    input clk,
    input rst,
    input enable,
    input [DATA_WIDTH-1:0] index,
    input signed [DATA_WIDTH-1:0] value,
    output reg [DATA_WIDTH-1:0] min_value1,
    output reg [DATA_WIDTH-1:0] min_value2,
    output reg [DATA_WIDTH-1:0] min_index1,
    output reg [DATA_WIDTH-1:0] min_index2
);

    wire signed [DATA_WIDTH-1:0] abs_value;
    assign abs_value = value[DATA_WIDTH-1] ? -value : value;


    always @(posedge clk)
    begin
        if(rst)
        begin
            min_index1 <= {DATA_WIDTH{1'b0}};
            min_index2 <= {DATA_WIDTH{1'b0}};
            min_value1 <= {1'b0,{DATA_WIDTH-1{1'b1}}};
            min_value2 <= {1'b0,{DATA_WIDTH-1{1'b1}}};
        end
        else if(enable)
        begin
            if(index < SIZE)
            begin
                if(abs_value <= min_value1)
                begin
                    min_value2 <= min_value1;
                    min_index2 <= min_index1;
                    
                    min_value1 <= abs_value;
                    min_index1 <= index;
                end
                else if(abs_value < min_value2)
                begin
                    min_value2 <= abs_value;
                    min_index2 <= index;
                end
            end
        end
    end

endmodule
