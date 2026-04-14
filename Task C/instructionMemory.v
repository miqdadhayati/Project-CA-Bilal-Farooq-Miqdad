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
        // TASK C: ITERATIVE FIBONACCI SEQUENCE CALCULATOR
        // =============================================================
        //
        // Calculates Fibonacci numbers iteratively and displays each
        // on the LEDs (16-bit) and seven-segment display.
        //
        // Features demonstrated:
        //   - Iterative algorithm with register-based state
        //   - Subroutine call (DISPLAY_AND_DELAY) with MANDATORY STACK
        //     USAGE: saves ra and s0, uses callee-saved register s0
        //     to preserve data across nested call to DELAY
        //   - Nested subroutine call (DELAY called from DISPLAY_AND_DELAY)
        //   - LUI (Task B) for 16-bit overflow constant
        //   - BLT (Task B) for overflow comparison
        //   - BNE for delay loop
        //
        // Register Map:
        //   sp (x2)  = stack pointer, initialized to 0x1F0
        //   s0 (x8)  = fib_prev (previous Fibonacci number)
        //   s1 (x9)  = fib_curr (current Fibonacci number)
        //   s2 (x18) = LED/display address (0x200)
        //   s3 (x19) = temp: next Fibonacci number
        //   t0 (x5)  = temp: overflow threshold (65536)
        //   t1 (x6)  = delay outer counter (used only in DELAY)
        //   t2 (x7)  = delay inner counter (used only in DELAY)
        //   a0 (x10) = argument to DISPLAY_AND_DELAY
        //   ra (x1)  = return address
        //
        // LED Output Sequence:
        //   0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377,
        //   610, 987, 1597, 2584, 4181, 6765, 10946, 17711, 28657,
        //   46368, then resets to 0, 1, 1, 2, ... (loops forever)
        //
        // Each number displayed ~0.8 seconds. Full cycle ~20 seconds.
        // Press btnU to reset at any time.
        // =============================================================

        // --- INIT (rom[0]-rom[1]) ---
        rom[0]  = 32'h1F000113; // addi sp, x0, 0x1F0      | sp = 496 (stack top)
        rom[1]  = 32'h20000913; // addi s2, x0, 0x200      | s2 = 512 (LED address)

        // --- RESET_FIB (rom[2]-rom[7]) ---
        // Initialize fib_prev=0, fib_curr=1, display both
        rom[2]  = 32'h00000413; // addi s0, x0, 0          | s0 = fib_prev = 0
        rom[3]  = 32'h00100493; // addi s1, x0, 1          | s1 = fib_curr = 1
        rom[4]  = 32'h00040513; // addi a0, s0, 0          | a0 = 0 (display fib_prev)
        rom[5]  = 32'h030000EF; // jal  ra, +48            | call DISPLAY_AND_DELAY (rom[17])
        rom[6]  = 32'h00048513; // addi a0, s1, 0          | a0 = 1 (display fib_curr)
        rom[7]  = 32'h028000EF; // jal  ra, +40            | call DISPLAY_AND_DELAY (rom[17])

        // --- FIB_LOOP (rom[8]-rom[16]) ---
        // Compute next, check overflow, update, display, repeat
        rom[8]  = 32'h009409B3; // add  s3, s0, s1         | s3 = fib_prev + fib_curr
        rom[9]  = 32'h000102B7; // lui  t0, 0x00010        | t0 = 65536 (16-bit limit)
        rom[10] = 32'h0059C463; // blt  s3, t0, +8         | if s3 < 65536 -> CONTINUE (rom[12])
        rom[11] = 32'hFDDFF06F; // jal  x0, -36            | else -> RESET_FIB (rom[2])
        // CONTINUE:
        rom[12] = 32'h00048413; // addi s0, s1, 0          | fib_prev = fib_curr
        rom[13] = 32'h00098493; // addi s1, s3, 0          | fib_curr = next_fib
        rom[14] = 32'h00048513; // addi a0, s1, 0          | a0 = new fib_curr
        rom[15] = 32'h008000EF; // jal  ra, +8             | call DISPLAY_AND_DELAY (rom[17])
        rom[16] = 32'hFE1FF06F; // jal  x0, -32            | -> FIB_LOOP (rom[8])

        // =============================================================
        // DISPLAY_AND_DELAY SUBROUTINE (rom[17]-rom[26])
        // Argument: a0 = value to display
        // Stack frame: saves ra (for nested call) and s0 (callee-saved)
        // =============================================================
        rom[17] = 32'hFF810113; // addi sp, sp, -8         | allocate stack frame
        rom[18] = 32'h00112223; // sw   ra, 4(sp)          | save return address
        rom[19] = 32'h00812023; // sw   s0, 0(sp)          | save s0 (caller's fib_prev)
        rom[20] = 32'h00050413; // addi s0, a0, 0          | s0 = argument (preserved across call)
        rom[21] = 32'h00892023; // sw   s0, 0(s2)          | write s0 to LED display (mem[0x200])
        rom[22] = 32'h014000EF; // jal  ra, +20            | call DELAY (rom[27]) — clobbers ra
        rom[23] = 32'h00012403; // lw   s0, 0(sp)          | restore s0
        rom[24] = 32'h00412083; // lw   ra, 4(sp)          | restore return address
        rom[25] = 32'h00810113; // addi sp, sp, 8          | deallocate stack frame
        rom[26] = 32'h00008067; // jalr x0, ra, 0          | return to caller

        // =============================================================
        // DELAY SUBROUTINE (rom[27]-rom[33])
        // Busy-wait ~0.8 s at 10 MHz: 2000 * (2000*2 + 3) ≈ 8 M cycles
        // Uses only t1(x6), t2(x7). Leaf function — no stack needed.
        // =============================================================
        rom[27] = 32'h7D000313; // addi t1, x0, 2000       | outer loop count
        // DELAY_OUTER:
        rom[28] = 32'h7D000393; // addi t2, x0, 2000       | inner loop count
        // DELAY_INNER:
        rom[29] = 32'hFFF38393; // addi t2, t2, -1         | t2--
        rom[30] = 32'hFE039EE3; // bne  t2, x0, -4         | if t2!=0 -> DELAY_INNER
        rom[31] = 32'hFFF30313; // addi t1, t1, -1         | t1--
        rom[32] = 32'hFE0318E3; // bne  t1, x0, -16        | if t1!=0 -> DELAY_OUTER
        rom[33] = 32'h00008067; // jalr x0, ra, 0          | return
    end

    // Byte-addressed PC -> word index via address[7:2]
    assign instruction = rom[instAddress[7:2]];

endmodule
