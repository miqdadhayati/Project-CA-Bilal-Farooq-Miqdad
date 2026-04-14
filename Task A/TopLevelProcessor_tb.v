//`timescale 1ns / 1ps

//module TopLevelProcessor_tb;

//    reg clk;
//    reg rst;
//    reg [15:0] switches;
//    reg reset_btn;
//    wire [31:0] display_out;

//    TopLevelProcessor uut (
//        .clk(clk),
//        .rst(rst),
//        .switches(switches),
//        .reset_btn(reset_btn),
//        .display_out(display_out)
//    );

//    always #5 clk = ~clk;
//    initial begin 
//        // Initialize Inputs
//        clk = 0;
//        rst = 1;
//        switches = 0;
//        reset_btn = 0;

//        // Wait 100 ns for global reset to finish
//        #100;
//        rst = 0;

//        // The processor starts in INPUT_WAITING state
//        // Let it run for a few cycles
//        #100;

//        // Trigger switch 3 (should result in countdown from 4)
//        switches[3] = 1'b1;
        
//        // Let it read the switch and enter COUNTDOWN_SUB
//        #100;

//        // Clear switch so it doesn't get read again immediately after finishing
//        switches[3] = 1'b0;

//        // Monitor display_out
//        $display("Time: %0t ns, Display: %0d", $time, display_out);
        
//        // Since delay loop takes ~8,000,000 cycles, simulating it entirely
//        // in Vivado would take a very long time. For simulation testing,
//        // it would be practical to shorten the delay in instruction memory,
//        // but since we are using the actual ROM values, we will just run
//        // for a bit or rely on FPGA testing.
        
//        // We will run for a few loops to see the first instructions execute.
//        #1000;
//        $display("Time: %0t ns, Display: %0d", $time, display_out);

//        $finish;


//    end

//endmodule
`timescale 1ns / 1ps
module tb_TopLevel;
    reg clk;
    reg rst;
    reg [15:0] switches;
    reg reset_btn;
    wire [31:0] display_out;

    // Instantiate your top module (check your exact port names!)
    TopLevelFPGA uut (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .reset_btn(reset_btn),
        .display_out(display_out)
    );

    // Generate a 10ns Clock (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Start safely
        clk = 0;
        rst = 1; // Hold processor in reset
        switches = 16'h0008; 
        reset_btn = 0;
        
        #100; // Wait 100ns for system to stabilize
        
        rst = 0; // Release reset, processor starts!
        
        // Let it run for 10,000ns to see initial execution
        #10000; 
        
        $stop; // $stop pauses Vivado safely without closing it
    end
endmodule