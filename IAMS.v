`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2026 10:40:09 AM
// Design Name: 
// Module Name: IAMS
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


module IAMS
#(
    parameter MESSAGE_WIDTH = 4,
    parameter PROBABILITY_WIDTH = 6,
    parameter M = 2,
    parameter N = 4
)(
    input clk,
    input rst,
    input decode_enable,
    input load_input,
    input [MESSAGE_WIDTH-1:0] gamma_input,
    output reg [N-1:0] codeword,
    output reg calculated
    );
    
    localparam max_iter = 10;
    localparam layers = 4;
    localparam H_row = 4;
    localparam H_col = 2;
    
    integer row, col, cycle_count;
    
    reg signed [MESSAGE_WIDTH-1:0] H [0:H_row][0:H_col];
    
    reg signed [MESSAGE_WIDTH-1:0] alpha [0:M-1][0:N-1];
    reg signed [MESSAGE_WIDTH-1:0] beta [0:N-1][0:M-1];
    
    reg signed [1:0] tau [0:M-1][0:N-1];
    reg signed [MESSAGE_WIDTH-1:0] lambda;
    
    reg signed [PROBABILITY_WIDTH-1:0] gamma [0:N-1];
    
    reg [N-1:0] codeword_intermediate;
    
    reg [3:0] state;
    
    integer i,j;
    integer iteration,l;
    
    wire condition1,condition2,condition3,condition4,condition5,condition6,condition7;
    
    wire min_finder_unit_enable;
    wire [MESSAGE_WIDTH-1:0] min_finder_unit_input;
    wire [MESSAGE_WIDTH-1:0] min_value1,min_value2,min_index1,min_index2;
    
    reg signed [1:0] negative_one;
    
    find_min_secondmin
    #(
        .DATA_WIDTH(MESSAGE_WIDTH),
        .SIZE(N)
     ) min_finder_unit(
        .clk(clk),
        .rst(rst),
        .enable(min_finder_unit_enable),
        .index(cycle_count),
        .value(min_finder_unit_input),
        .min_value1(min_value1),
        .min_value2(min_value2),
        .min_index1(min_index1),
        .min_index2(min_index2)        
     );
     
     
     reg signed [MESSAGE_WIDTH-1:0] vector_out [0:H_col];
     genvar e;
     generate
        for(e=0;e<H_col;e=e+1)
        begin
            always @(posedge clk)
            begin
                if(rst || state == 0)
                begin
                    vector_out[e] <= 0;
                end
                else if(state == 6)
                begin
                    vector_out[e] <= vector_out[e] + H[cycle_count][e] * codeword_intermediate[cycle_count];
                end
            end
        end
     endgenerate
     
     reg all_zeroes;
    
    always @(posedge clk)
    begin
        if(rst)
        begin
            for(i=0;i<M;i=i+1)
            begin
                for(j=0;j<N;j=j+1)
                begin
                    alpha[i][j] <= 0;
                end
            end
            row <= 0;
            col <= 0;
            cycle_count <= 0;
            state <= 0;
            negative_one <= -1;
            lambda <= 1;
            iteration <= 1;
            l <= 1;
            calculated <= 0;
            all_zeroes <= 1;
        end
        else
        begin
            case (state)
                0:
                    begin
                        if(load_input)
                        begin
                            gamma[cycle_count] <= gamma_input;
                            if(cycle_count < N-1)
                            begin
                                cycle_count <= cycle_count + 1;
                            end
                            else
                            begin
                                cycle_count <= 0;
                                state <= state + 1;
                            end
                        end
                    end
                1:
                    begin
                        if(condition1)
                        begin
                            beta[row][col] <= gamma[row] - alpha[col][row];
                        end
                        tau[col][row] <= 1;
                        if(col < M-1)
                        begin
                            col <= col + 1;
                        end
                        else
                        begin
                            col <= 0;
                            if(row < N-1)
                            begin
                                row <= row + 1;
                            end
                            else
                            begin
                                row <= 0;
                                state <= state + 1;
                            end
                        end
                    end
                2:
                    begin
                        if(condition2)
                        begin
                            if(beta[col][row] < 0)
                            begin
                                tau[row][col] <= tau[row][col] * negative_one;
                            end
                            else if(beta[col][row] == 0)
                            begin
                                tau[row][col] <= tau[row][col] * 0;
                            end
                        end
                        if(col < N-1)
                        begin
                            col <= col + 1;
                        end
                        else
                        begin
                            col <= 0;
                            if(row < M-1)
                            begin
                                row <= row + 1;
                            end
                            else
                            begin
                                row <= 0;
                                state <= state + 1;
                            end
                        end
                    end
                3:
                    begin
                        if(cycle_count < M-1) // wait for min & second min values & indices
                        begin
                            cycle_count <= cycle_count + 1;
                        end
                        else
                        begin
                            cycle_count <= 0;
                            if(condition3)
                            begin
                                if(min_value1 > lambda)
                                begin
                                    alpha[row][col] <= tau[row][col] * (min_value1 - lambda);
                                end
                                else
                                begin
                                    alpha[row][col] <= 0;
                                end
                            end
                            else
                            begin
//                                alpha[row][col] <= tau[row][col] * ;
                            end
                            if(col < N-1)
                            begin
                                col <= col + 1;
                            end
                            else
                            begin
                                col <= 0;
                                if(row < M-1)
                                begin
                                    row <= row + 1;
                                end
                                else
                                begin
                                    row <= 0;
                                    state <= state + 1;
                                end
                            end
                        end
                    end
                4:
                    begin
                        if(condition4)
                        begin
                            gamma[row] <= beta[row][col] + alpha[col][row];
                        end
                        if(col < M-1)
                        begin
                            col <= col + 1;
                        end
                        else
                        begin
                            col <= 0;
                            if(row < N-1)
                            begin
                                row <= row + 1;
                            end
                            else
                            begin
                                row <= 0;
                                if(l < layers)
                                begin
                                    l <= l + 1;
                                    state <= 1;
                                end
                                else
                                begin
                                    state <= state + 1;
                                end
                            end
                        end
                    end
                5:
                    begin
                        if(gamma[cycle_count] >= 0)
                        begin
                            codeword_intermediate[cycle_count] <= 0;
                        end
                        else 
                        begin
                            codeword_intermediate[cycle_count] <= 1;
                        end
                        if(cycle_count < N-1)
                        begin
                            cycle_count <= cycle_count + 1;
                        end
                        else
                        begin
                            cycle_count <= 0;
                            state <= state + 1;
                        end
                    end
                6:
                    begin
                        if(cycle_count < N-1)
                        begin
                            cycle_count <= cycle_count + 1;
                        end
                        else
                        begin
                            cycle_count <= 0;
                            state <= state + 1;
                            all_zeroes <= 1;
                        end
                    end
                7:
                    begin
                        if(cycle_count < H_col)
                        begin
                            cycle_count <= cycle_count + 1;
                            if(vector_out[cycle_count] != 0)
                            begin
                                all_zeroes <= 0;
                            end
                        end
                        else
                        begin
                            cycle_count <= 0;
                            state <= state + 1;
                        end                    
                    end
                8:
                    begin
                        if(all_zeroes)
                        begin
                            state <= state + 1;
                        end
                        else 
                        begin
                            if(iteration < max_iter)
                            begin
                                iteration <= iteration + 1;
                                l <= 0;
                                state <= 1;
                            end
                            else
                            begin
                                state <= state + 1;
                            end                        
                        end
                    end
                9:
                    begin
                        codeword[cycle_count] <= codeword_intermediate[cycle_count];
                        if(cycle_count < N-1)
                        begin
                            cycle_count <= cycle_count + 1;
                        end
                        else
                        begin
                            cycle_count <= 0;
                            state <= state + 1;
                            calculated <= 1;
                        end                       
                    end
                 10:
                    begin
                    
                    end
            endcase
        end
    end
    
endmodule
