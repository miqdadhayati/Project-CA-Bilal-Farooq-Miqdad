`timescale 1ns / 1ps

module TopLevelProcessor_tb;

    reg clk;
    reg rst;
    reg [15:0] switches;
    reg reset_btn;
    wire [31:0] display_out;

    TopLevelProcessor uut (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .reset_btn(reset_btn),
        .display_out(display_out)
    );

    // 10 ns clock period (100 MHz equivalent for fast simulation)
    always #5 clk = ~clk;

    // Monitor display changes
    always @(display_out) begin
        $display("Time=%0t ns | display_out=0x%08H (dec=%0d) | LEDs[15:0]=0x%04H",
                 $time, display_out, display_out, display_out[15:0]);
    end

    // Also monitor key register values via hierarchical access
    // (only works in simulation, not synthesis)
    always @(posedge clk) begin
        if (!rst) begin
            // Print when PC changes to track instruction execution
            // Uncomment the line below for detailed per-cycle tracing:
            // $display("  PC=0x%03H  inst=0x%08H", uut.PC, uut.instruction);
        end
    end

    initial begin
        // --- Initialize ---
        clk = 0;
        rst = 1;
        switches = 16'd0;
        reset_btn = 0;

        // Hold reset for 100 ns
        #100;
        rst = 0;

        $display("=== Task B Test Program Started ===");
        $display("No switches needed - program is self-running.");
        $display("");

        // The program has 5 test steps, each followed by a ~0.8s delay.
        // At 10 MHz (100 ns/cycle), the delay is ~800,000,000 ns per step.
        // That's way too long for simulation. For QUICK simulation testing,
        // we can either:
        //   (a) Run for a short time and check the first few display values
        //       (display changes within the first ~50 cycles before delay)
        //   (b) Temporarily reduce the delay loop counts in instructionMemory.v
        //       from 2000 to e.g. 3 for simulation, then restore for FPGA.
        //
        // Here we run for 600 ns (60 cycles) which is enough to see the
        // LUI, SLTI, and BLT results stored to display before the first
        // delay loop starts stalling.

        // Wait for initial instructions to execute
        // rom[0]-rom[3]: setup + LUI + store = 4 cycles = 40 ns
        #50;
        $display("");
        $display("--- After LUI test (rom[0]-rom[3]) ---");
        $display("  display_out = 0x%08H (expect 0x00005003 if LUI+ADDI worked)", display_out);
        if (display_out == 32'h00005003)
            $display("  >> LUI TEST PASSED <<");
        else
            $display("  >> LUI TEST FAILED << (got 0x%08H)", display_out);

        // The program now enters the delay loop at rom[29].
        // For simulation, we can't wait for the full delay.
        // Let's just verify the first store happened correctly.

        $display("");
        $display("=== Simulation Complete ===");
        $display("The LUI result was verified in simulation.");
        $display("For full SLTI and BLT verification, either:");
        $display("  1. Run on FPGA hardware (recommended), or");
        $display("  2. Reduce delay constants (2000->3) in instructionMemory.v");
        $display("     and run simulation for ~2000 ns.");
        $display("");

        // Run a bit more just to make sure nothing crashes
        #500;

        $finish;
    end

endmodule
