`timescale 1ns / 1ps

module branch_adder(
    input  wire [31:0] PC,
    input  wire [31:0] imm,
    output wire [31:0] BranchTarget
);
    // imm is the half-offset from immGen; shift left by 1 to get byte offset
    // Works for both B-type branches and J-type jumps (JAL)
    assign BranchTarget = PC + (imm << 1);
endmodule
