`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Modularized IAMS top file (all modules in one file)
// - find_min_secondmin  : unchanged from your original
// - IAMS_controller     : contains the original FSM and arrays (moved into a module)
// - IAMS                : top-level wrapper that instantiates IAMS_controller
//
// Functionality: kept identical to your posted code. Only structural re-organization.
//
// Created: converted from user's original single-module code to modular form.
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
    output [N-1:0] codeword,
    output calculated
);
    // Top-level simply instantiates the controller module (keeps the original ports)
    IAMS_controller #(
        .MESSAGE_WIDTH(MESSAGE_WIDTH),
        .PROBABILITY_WIDTH(PROBABILITY_WIDTH),
        .M(M),
        .N(N)
    ) u_iams_controller (
        .clk(clk),
        .rst(rst),
        .decode_enable(decode_enable),
        .load_input(load_input),
        .gamma_input(gamma_input),
        .codeword(codeword),
        .calculated(calculated)
    );
endmodule


//////////////////////////////////////////////////////////////////////////////////
// find_min_secondmin
// (kept the same as your original module, just copied unchanged)
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


//////////////////////////////////////////////////////////////////////////////////
// IAMS_controller
// - Contains the original arrays, FSM and logic from your posted IAMS module
// - Instantiates find_min_secondmin internally exactly as in your code
// - This module preserves all behavior; it is simply moved into its own module.
//////////////////////////////////////////////////////////////////////////////////
module IAMS_controller
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

    localparam D = 3;
    
    integer row, col, cycle_count;
    
    reg signed [MESSAGE_WIDTH-1:0] H [0:H_row-1][0:H_col-1];
    
    reg signed [MESSAGE_WIDTH-1:0] alpha [0:M-1][0:N-1];
    reg signed [MESSAGE_WIDTH-1:0] beta [0:N-1][0:M-1];
    
    reg signed [1:0] tau [0:M-1][0:N-1];
    reg signed [MESSAGE_WIDTH-1:0] lambda;
    
    reg signed [PROBABILITY_WIDTH-1:0] gamma [0:N-1];
    
    reg [N-1:0] codeword_intermediate;
    
    reg [3:0] state;
    
    integer i,j;
    integer iteration,l;
        
    wire min_finder_unit_enable;
    wire [MESSAGE_WIDTH-1:0] min_finder_unit_input;
    wire [MESSAGE_WIDTH-1:0] min_value1,min_value2,min_index1,min_index2;
    
    reg signed [1:0] negative_one;

    assign min_finder_unit_enable = (state==3);
    assign min_finder_unit_input  = beta[row][cycle_count];
    

    reg [N-1:0] row_mask [0:M-1];

    integer degree;
    integer delta;
    
    // instantiate min finder
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
     
     initial begin

        H[0][0] = 1;
        H[0][1] = 0;
        H[1][0] = 1;
        H[1][1] = 1;

        H[2][0] = 0;
        H[2][1] = 1;
        H[3][0] = 1;
        H[3][1] = 1;

        // Convert H → row_mask automatically (kept as in original)
        row_mask[0] = {1,0,1,1};
        row_mask[1] = {1,1,1,0};

    end
     
     reg signed [MESSAGE_WIDTH-1:0] vector_out [0:H_col];
     genvar e;
     generate
        for(e=0;e<H_col;e=e+1)
        begin : gen_vector_out
            // synchronous accumulation (kept behaviorally identical)
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
                        if(row_mask[row][col])
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

                                row <= l-1;
                                state <= state + 1;
                            
                        end
                    end
                2:
                    begin
                        if(row_mask[row][col])
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
                            
                                row <= l - 1;
                                state <= state + 1;
                            
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
                            if(row_mask[row][col])
                            begin
                                degree = column_degree(col);
                                delta  = min_value2 - min_value1;
                                if(row < 4 && degree >= D)
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
                                    if(col == min_index1)
                                    begin
                                        alpha[row][col] <= tau[row][col] * min_value2;
                                    end
                                    else if(col == min_index2)
                                    begin
                                        alpha[row][col] <= tau[row][col] * min_value1;
                                    end
                                    else if(delta == 0)
                                    begin
                                        if(min_value1 > 1)
                                            alpha[row][col] <= tau[row][col] * (min_value1 - 1);
                                        else
                                            alpha[row][col] <= 0;
                                        
                                    end
                                    else
                                    begin
                                        alpha[row][col] <= tau[row][col] * min_value1;
                                    end
                                end
                            end
                            if(col < N-1)
                            begin
                                col <= col + 1;
                            end
                            else
                            begin
                                col <= 0;
                               
                                    row <= l-1;
                                    state <= state + 1;
                                
                            end
                        end
                    end
                4:
                    begin
                        if(row_mask[row][col])
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
                            
                                if(l < layers)
                                begin
                                    l <= l + 1;
                                    state <= 1;
                                    row <= l;
                                end
                                else
                                begin
                                    state <= state + 1;
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
    

function integer column_degree;
input integer n;
integer k;
begin
    column_degree = 0;
    for(k=0;k<M;k=k+1)
        if(row_mask[k][n])
            column_degree = column_degree + 1;
end
endfunction

endmodule