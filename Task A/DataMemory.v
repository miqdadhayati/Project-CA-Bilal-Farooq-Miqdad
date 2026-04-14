`timescale 1ns / 1ps

module DataMemory(
    input  wire        clk,
    input  wire        MemWrite,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    // 128 words of 32-bit memory (covers byte addresses 0-508)
    // Word-addressed using address[8:2] (7 bits -> 128 locations)
    reg [31:0] mem [0:127];

    always @(posedge clk) begin
        if (MemWrite)
            mem[address[8:2]] <= write_data;
    end

    assign read_data = mem[address[8:2]];
endmodule
