`timescale 1ns / 1ps

module instructionMemory #(
    parameter OPERAND_LENGTH = 31
)(
    input  [OPERAND_LENGTH:0] instAddress,
    output [31:0] instruction
);
    // 34 instructions (rom[0] to rom[33])
    reg [31:0] rom [0:63];

    initial begin
        // ===== _start: Initialize registers =====
        rom[0]  = 32'h1F000113; // addi sp, zero, 0x1F0      | sp = 496
        rom[1]  = 32'h20000493; // addi s1, zero, 512        | s1 = display output addr
        rom[2]  = 32'h30000913; // addi s2, zero, 768        | s2 = switch input addr
        rom[3]  = 32'h30400993; // addi s3, zero, 772        | s3 = reset button addr

        // ===== INPUT_WAITING: Clear display, poll switches =====
        rom[4]  = 32'h0004A023; // sw   zero, 0(s1)          | clear display
        // POLL_SWITCHES
        rom[5]  = 32'h00092503; // lw   a0, 0(s2)            | read switch value
        rom[6]  = 32'hFE050EE3; // beq  a0, zero, -4         | if zero -> POLL (rom[5])
        rom[7]  = 32'h008000EF; // jal  ra, +8               | call COUNTDOWN_SUB (rom[9])
        rom[8]  = 32'hFF1FF06F; // jal  zero, -16            | j INPUT_WAITING (rom[4])

        // ===== COUNTDOWN_SUB: Countdown subroutine =====
        rom[9]  = 32'hFF810113; // addi sp, sp, -8           | push stack frame
        rom[10] = 32'h00112223; // sw   ra, 4(sp)            | save return address
        rom[11] = 32'h00812023; // sw   s0, 0(sp)            | save s0
        rom[12] = 32'h00050413; // addi s0, a0, 0            | s0 = counter = switch value

        // COUNTDOWN_LOOP
        rom[13] = 32'h02040263; // beq  s0, zero, +36        | if counter==0 -> DONE (rom[22])
        rom[14] = 32'h0009A283; // lw   t0, 0(s3)            | read reset button
        rom[15] = 32'h00029A63; // bne  t0, zero, +20        | if pressed -> RESET (rom[20])
        rom[16] = 32'h0084A023; // sw   s0, 0(s1)            | write counter to display
        rom[17] = 32'h030000EF; // jal  ra, +48              | call DELAY (rom[29])
        rom[18] = 32'hFFF40413; // addi s0, s0, -1           | counter--
        rom[19] = 32'hFE9FF06F; // jal  zero, -24            | j COUNTDOWN_LOOP (rom[13])

        // RESET_DETECTED
        rom[20] = 32'h0004A023; // sw   zero, 0(s1)          | clear display
        rom[21] = 32'h0040006F; // jal  zero, +4             | j COUNTDOWN_DONE (rom[22])

        // COUNTDOWN_DONE
        rom[22] = 32'h0004A023; // sw   zero, 0(s1)          | clear display
        rom[23] = 32'h00092283; // lw   t0, 0(s2)            | read switches
        rom[24] = 32'hFE029EE3; // bne  t0, zero, -4         | loop -> wait for switch release
        rom[25] = 32'h00412083; // lw   ra, 4(sp)            | restore return address
        rom[26] = 32'h00012403; // lw   s0, 0(sp)            | restore s0
        rom[27] = 32'h00810113; // addi sp, sp, 8            | pop stack frame
        rom[28] = 32'h00008067; // jalr zero, ra, 0          | ret

        // ===== DELAY: Busy-wait (~0.8s at 10 MHz) =====
        // 2000 * (2000*2 + ~3) = ~8,006,000 cycles = ~0.8s
        rom[29] = 32'h7D000313; // addi t1, zero, 2000       | outer loop count
        // DELAY_OUTER
        rom[30] = 32'h7D000393; // addi t2, zero, 2000       | inner loop count
        // DELAY_INNER
        rom[31] = 32'hFFF38393; // addi t2, t2, -1           | t2--
        rom[32] = 32'hFE039EE3; // bne  t2, zero, -4         | loop -> DELAY_INNER (rom[31])
        rom[33] = 32'hFFF30313; // addi t1, t1, -1           | t1--
        rom[34] = 32'hFE0318E3; // bne  t1, zero, -16        | loop -> DELAY_OUTER (rom[30])
        rom[35] = 32'h00008067; // jalr zero, ra, 0          | ret
    end

    // Byte-addressed PC -> word index via address[7:2]
    assign instruction = rom[instAddress[7:2]];

endmodule
