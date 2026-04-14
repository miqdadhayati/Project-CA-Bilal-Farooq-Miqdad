`timescale 1ns / 1ps

module immGen(
    input  wire [31:0] instruction,
    output reg  [31:0] imm
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-Type: ALU Immediate (ADDI), Load (LW), JALR
            7'b0010011, 7'b0000011, 7'b1100111:
                imm = {{20{instruction[31]}}, instruction[31:20]};

            // S-Type: Store (SW)
            7'b0100011:
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-Type: Branch (BEQ, BNE)
            // Extracts half-offset (bits[12:1]); branch_adder shifts <<1
            7'b1100011:
                imm = {{20{instruction[31]}}, instruction[31], instruction[7],
                       instruction[30:25], instruction[11:8]};

            // J-Type: JAL
            // Extracts half-offset (bits[20:1]); branch_adder shifts <<1
            7'b1101111:
                imm = {{12{instruction[31]}}, instruction[31], instruction[19:12],
                       instruction[20], instruction[30:21]};

            default:
                imm = 32'd0;
        endcase
    end
endmodule
