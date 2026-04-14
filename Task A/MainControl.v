`timescale 1ns / 1ps

module MainControl(
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        ALUSrc,
    output reg        MemRead,
    output reg        MemWrite,
    output reg  [1:0] MemtoReg,   // 00=ALU, 01=Memory, 10=PC+4
    output reg        Branch,
    output reg        Jump,        // JAL
    output reg        JumpReg,     // JALR
    output reg  [1:0] ALUOp
);
    always @(*) begin
        // Safe defaults
        RegWrite = 1'b0;  ALUSrc   = 1'b0;
        MemRead  = 1'b0;  MemWrite = 1'b0;
        MemtoReg = 2'b00; Branch   = 1'b0;
        Jump     = 1'b0;  JumpReg  = 1'b0;
        ALUOp    = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type (ADD, SUB, SLL, SRL, AND, OR, XOR)
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
            end

            7'b0010011: begin // I-type ALU (ADDI)
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b11;
            end

            7'b0000011: begin // I-type Load (LW)
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 2'b01;
            end

            7'b0100011: begin // S-type Store (SW)
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
            end

            7'b1100011: begin // B-type Branch (BEQ, BNE)
                Branch   = 1'b1;
                ALUOp    = 2'b01;
            end

            7'b1101111: begin // J-type (JAL)
                RegWrite = 1'b1;
                Jump     = 1'b1;
                MemtoReg = 2'b10;  // write PC+4 to rd
            end

            7'b1100111: begin // I-type (JALR)
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;   // ALU computes rs1 + imm
                JumpReg  = 1'b1;
                MemtoReg = 2'b10;  // write PC+4 to rd
            end

            default: begin
                // All zeros (safe)
            end
        endcase
    end
endmodule
