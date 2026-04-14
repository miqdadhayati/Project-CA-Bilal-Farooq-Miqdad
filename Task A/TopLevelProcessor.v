`timescale 1ns / 1ps

module TopLevelProcessor(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] switches,
    input  wire        reset_btn,
    output wire [31:0] display_out
);

    // =====================================================
    // WIRE DECLARATIONS
    // =====================================================

    // PC & Instruction
    wire [31:0] PC, PCNext, PCPlus4;
    wire [31:0] instruction;

    // Control Signals
    wire        Branch, MemRead, MemWrite, ALUSrc, RegWrite;
    wire        Jump, JumpReg;
    wire [1:0]  MemtoReg, ALUOp;
    wire [3:0]  ALU_Ctrl;

    // Register File & Immediate
    wire [31:0] imm, readData1, readData2, WriteData;

    // ALU
    wire [31:0] ALU_B, ALUResult;
    wire        Zero;

    // Memory
    wire [31:0] mem_read_data;
    wire [31:0] BranchTarget;

    // Display register from address decoder
    wire [31:0] display_reg;

    // =====================================================
    // BRANCH / JUMP DECISION LOGIC
    // =====================================================

    // Branch condition: BEQ (funct3[0]=0) branches when Zero=1
    //                   BNE (funct3[0]=1) branches when Zero=0
    // XOR gives: taken=1 when condition is met
    wire branch_taken = Branch & (instruction[12] ^ Zero);

    // JALR target: rs1 + imm with LSB cleared
    wire [31:0] JALR_target = {ALUResult[31:1], 1'b0};

    // PC selection priority: JALR > JAL/Branch > PC+4
    assign PCNext = JumpReg              ? JALR_target   :
                    (Jump | branch_taken) ? BranchTarget  :
                    PCPlus4;

    // =====================================================
    // DATAPATH INSTANTIATIONS
    // =====================================================

    // 1. Program Counter
    ProgramCounter u_PC (
        .clk    (clk),
        .rst    (rst),
        .PCNext (PCNext),
        .PC     (PC)
    );

    // 2. PC + 4
    pcAdder u_pcAdd (
        .PC      (PC),
        .PCPlus4 (PCPlus4)
    );

    // 3. Instruction Memory
    instructionMemory u_InstMem (
        .instAddress (PC),
        .instruction (instruction)
    );

    // 4. Main Control Unit
    MainControl u_MainCtrl (
        .opcode   (instruction[6:0]),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .Branch   (Branch),
        .Jump     (Jump),
        .JumpReg  (JumpReg),
        .ALUOp    (ALUOp)
    );

    // 5. Register File
    RegisterFile u_RegFile (
        .clk         (clk),
        .rst         (rst),
        .WriteEnable (RegWrite),
        .rs1         (instruction[19:15]),
        .rs2         (instruction[24:20]),
        .rd          (instruction[11:7]),
        .WriteData   (WriteData),
        .readData1   (readData1),
        .readData2   (readData2)
    );

    // 6. Immediate Generator
    immGen u_immGen (
        .instruction (instruction),
        .imm         (imm)
    );

    // 7. ALU Control
    ALUControl u_ALUCtrl (
        .ALUOp        (ALUOp),
        .funct3       (instruction[14:12]),
        .funct7_bit5  (instruction[30]),
        .ALUControlOut(ALU_Ctrl)
    );

    // 8. ALU Source MUX (Register vs Immediate)
    mmux2 u_ALUSrcMux (
        .in0 (readData2),
        .in1 (imm),
        .sel (ALUSrc),
        .out (ALU_B)
    );

    // 9. ALU
    ALU u_ALU (
        .A          (readData1),
        .B          (ALU_B),
        .ALUControl (ALU_Ctrl),
        .ALUResult  (ALUResult),
        .Zero       (Zero)
    );

    // 10. Branch / Jump Target Adder
    branch_adder u_brAdd (
        .PC           (PC),
        .imm          (imm),
        .BranchTarget (BranchTarget)
    );

    // 11. Address Decoder + Data Memory + Peripherals
    addressDecoderTop u_AddrDec (
        .clk         (clk),
        .rst         (rst),
        .address     (ALUResult),
        .MemRead     (MemRead),
        .MemWrite    (MemWrite),
        .writeData   (readData2),
        .switches    (switches),
        .reset_btn   (reset_btn),
        .readData    (mem_read_data),
        .display_reg (display_reg)
    );

    assign display_out = display_reg;

    // 12. Write-back MUX (3-to-1)
    // MemtoReg: 00 = ALU result, 01 = Memory read, 10 = PC+4
    assign WriteData = (MemtoReg == 2'b01) ? mem_read_data :
                       (MemtoReg == 2'b10) ? PCPlus4       :
                       ALUResult;

endmodule
