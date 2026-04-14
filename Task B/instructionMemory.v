`timescale 1ns / 1ps

module instructionMemory #(
    parameter OPERAND_LENGTH = 31
)(
    input  [OPERAND_LENGTH:0] instAddress,
    output [31:0] instruction
);
    reg [31:0] rom [0:63];

    initial begin
        // =============================================================
        // TASK B DEMONSTRATION PROGRAM
        // Tests LUI, SLTI, and BLT with visible LED/7-seg output.
        // Each test writes its result to display (addr 0x200), then
        // calls a ~0.8 s delay so the instructor can observe the output.
        //
        // NO SWITCHES NEEDED - fully self-running after reset (btnU).
        //
        // Expected display sequence on LEDs / 7-seg:
        //   Step 1: LEDs = 0101_0000_0000_0011, 7-seg = 03  (LUI+ADDI)
        //   Step 2: LEDs = 0000_0000_0000_0001, 7-seg = 01  (SLTI: 5<10 TRUE)
        //   Step 3: LEDs = 0000_0000_0000_0000, 7-seg = 00  (SLTI: 5<3 FALSE)
        //   Step 4: LEDs = 0000_0000_0000_0001, 7-seg = 01  (BLT 3<7 taken PASS)
        //   Step 5: LEDs = 0000_0000_0000_0010, 7-seg = 02  (BLT 7<3 not taken PASS)
        //   Then halts showing 02. Press btnU to reset and replay.
        //
        // Registers used: x1 (LUI result), x3 (SLTI operand),
        //   x4-x5 (SLTI results), x9 (display addr),
        //   x12-x13 (BLT operands), x10-x11 (BLT results).
        // Delay subroutine uses x6 (t1) and x7 (t2) only.
        // =============================================================

        // --- Setup ---
        rom[0]  = 32'h20000493; // addi x9, x0, 512       | x9 = 0x200 (display addr)

        // ===================== TEST 1: LUI ==========================
        // lui x1, 0x00005 -> x1 = 0x00005000
        // addi x1, x1, 3 -> x1 = 0x00005003
        // Store x1: LEDs show 0101_0000_0000_0011, 7-seg shows "03"
        // Upper LEDs (14,12) prove LUI loaded bits[15:12], lower LEDs
        // (1,0) prove ADDI contributed the lower portion.
        // =============================================================
        rom[1]  = 32'h000050B7; // lui  x1, 0x00005        | x1 = 0x5000
        rom[2]  = 32'h00308093; // addi x1, x1, 3          | x1 = 0x5003
        rom[3]  = 32'h0014A023; // sw   x1, 0(x9)          | display <- 0x5003
        rom[4]  = 32'h064000EF; // jal  ra, +100           | call DELAY (rom[29])

        // ===================== TEST 2: SLTI (TRUE) ==================
        // x3 = 5, slti x4, x3, 10 -> x4 = 1  (5 < 10 is TRUE)
        // Display shows 1.
        // =============================================================
        rom[5]  = 32'h00500193; // addi x3, x0, 5          | x3 = 5
        rom[6]  = 32'h00A1A213; // slti x4, x3, 10         | x4 = 1
        rom[7]  = 32'h0044A023; // sw   x4, 0(x9)          | display <- 1
        rom[8]  = 32'h054000EF; // jal  ra, +84            | call DELAY (rom[29])

        // ===================== TEST 3: SLTI (FALSE) =================
        // slti x5, x3, 3 -> x5 = 0  (5 < 3 is FALSE)
        // Display shows 0.
        // =============================================================
        rom[9]  = 32'h0031A293; // slti x5, x3, 3          | x5 = 0
        rom[10] = 32'h0054A023; // sw   x5, 0(x9)          | display <- 0
        rom[11] = 32'h048000EF; // jal  ra, +72            | call DELAY (rom[29])

        // ===================== TEST 4: BLT TAKEN ====================
        // x12 = 3, x13 = 7.  blt x12, x13 -> 3 < 7 TRUE -> branch
        // If branch taken correctly:  display = 1 (PASS)
        // If branch NOT taken (bug):  display = 0 (FAIL)
        // Uses x12/x13 instead of x7/x8 to avoid delay clobbering x7.
        // =============================================================
        rom[12] = 32'h00300613; // addi x12, x0, 3         | x12 = 3
        rom[13] = 32'h00700693; // addi x13, x0, 7         | x13 = 7
        rom[14] = 32'h00D64663; // blt  x12, x13, +12      | 3<7 -> TAKEN -> rom[17]
        rom[15] = 32'h00000513; // addi x10, x0, 0         | FAIL (skipped if BLT works)
        rom[16] = 32'h0080006F; // jal  x0, +8             | jump to rom[18]
        rom[17] = 32'h00100513; // addi x10, x0, 1         | PASS (BLT landed here)
        rom[18] = 32'h00A4A023; // sw   x10, 0(x9)         | display <- result
        rom[19] = 32'h028000EF; // jal  ra, +40            | call DELAY (rom[29])

        // ===================== TEST 5: BLT NOT TAKEN ================
        // blt x13, x12 -> 7 < 3 FALSE -> should NOT branch
        // If correctly not taken: display = 2 (PASS)
        // If wrongly taken (bug): display = 0 (FAIL)
        // =============================================================
        rom[20] = 32'h00C6C663; // blt  x13, x12, +12      | 7<3 -> NOT TAKEN
        rom[21] = 32'h00200593; // addi x11, x0, 2         | PASS (fell through correctly)
        rom[22] = 32'h0080006F; // jal  x0, +8             | jump to rom[24]
        rom[23] = 32'h00000593; // addi x11, x0, 0         | FAIL (BLT wrongly taken)
        rom[24] = 32'h00B4A023; // sw   x11, 0(x9)         | display <- result
        rom[25] = 32'h010000EF; // jal  ra, +16            | call DELAY (rom[29])

        // ===================== HALT =================================
        rom[26] = 32'h0000006F; // jal  x0, 0              | infinite loop (halt)
        rom[27] = 32'h00000013; // nop (padding)
        rom[28] = 32'h00000013; // nop (padding)

        // ===================== DELAY SUBROUTINE (rom[29]) ===========
        // ~0.8s at 10 MHz:  2000 * (2000*2 + ~3) = ~8,006,000 cycles
        // Uses only x6 (t1) and x7 (t2). Returns via ra.
        // =============================================================
        rom[29] = 32'h7D000313; // addi t1, x0, 2000       | outer loop count
        // DELAY_OUTER:
        rom[30] = 32'h7D000393; // addi t2, x0, 2000       | inner loop count
        // DELAY_INNER:
        rom[31] = 32'hFFF38393; // addi t2, t2, -1         | t2--
        rom[32] = 32'hFE039EE3; // bne  t2, x0, -4         | if t2!=0 -> DELAY_INNER
        rom[33] = 32'hFFF30313; // addi t1, t1, -1         | t1--
        rom[34] = 32'hFE0318E3; // bne  t1, x0, -16        | if t1!=0 -> DELAY_OUTER
        rom[35] = 32'h00008067; // jalr x0, ra, 0          | return
    end

    // Byte-addressed PC -> word index via address[7:2]
    assign instruction = rom[instAddress[7:2]];

endmodule
