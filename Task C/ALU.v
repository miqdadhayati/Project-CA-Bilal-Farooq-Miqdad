`timescale 1ns / 1ps

module ALU(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult,
    output wire        Zero,
    output wire        Less_Than
);
    assign Zero = (ALUResult == 32'd0);
    assign Less_Than = ($signed(A) < $signed(B));  // signed comparison for BLT

    always @(*) begin
        case (ALUControl)
            4'b0010: ALUResult = A + B;                                          // ADD
            4'b0110: ALUResult = A - B;                                          // SUB
            4'b0000: ALUResult = A & B;                                          // AND
            4'b0001: ALUResult = A | B;                                          // OR
            4'b0011: ALUResult = A ^ B;                                          // XOR
            4'b0100: ALUResult = A << B[4:0];                                    // SLL
            4'b0101: ALUResult = A >> B[4:0];                                    // SRL
            4'b0111: ALUResult = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;     // SLT
            default: ALUResult = 32'd0;
        endcase
    end
endmodule
