`timescale 1ns / 1ps

module mmux2(
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire        sel,
    output wire [31:0] out
);
    // sel=0 -> in0, sel=1 -> in1
    assign out = sel ? in1 : in0;
endmodule
