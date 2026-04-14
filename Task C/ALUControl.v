`timescale 1ns / 1ps

module ALUControl(
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire       funct7_bit5,   // instruction[30]
    output reg  [3:0] ALUControlOut
);
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControlOut = 4'b0010;  // Load/Store/JALR -> ADD
            2'b01: ALUControlOut = 4'b0110;  // Branch -> SUB (for comparison)
            2'b11: begin                     // I-type ALU
                case (funct3)
                    3'b000:  ALUControlOut = 4'b0010;  // ADDI -> ADD
                    3'b010:  ALUControlOut = 4'b0111;  // SLTI -> SLT
                    default: ALUControlOut = 4'b0010;
                endcase
            end
            2'b10: begin                     // R-type
                case (funct3)
                    3'b000:  ALUControlOut = funct7_bit5 ? 4'b0110 : 4'b0010;  // SUB / ADD
                    3'b001:  ALUControlOut = 4'b0100;  // SLL
                    3'b101:  ALUControlOut = 4'b0101;  // SRL
                    3'b100:  ALUControlOut = 4'b0011;  // XOR
                    3'b110:  ALUControlOut = 4'b0001;  // OR
                    3'b111:  ALUControlOut = 4'b0000;  // AND
                    default: ALUControlOut = 4'b0000;
                endcase
            end
            default: ALUControlOut = 4'b0000;
        endcase
    end
endmodule
