`timescale 1ns / 1ps

module TopLevelFPGA(
    input  wire        clk_100mhz,  // 100 MHz board oscillator
    input  wire        btnU,        // hard processor reset
    input  wire        btnC,        // software-readable reset button
    input  wire [15:0] sw,          // 16 switches
    output wire [6:0]  seg,         // 7-segment cathodes (active-low)
    output wire [3:0]  an,          // 7-segment anodes (active-low)
    output wire        dp,          // decimal point (active-low, unused)
    output wire [15:0] led          // LEDs (mirror display value)
);

    // =====================================================
    // Clock Divider: 100 MHz -> 10 MHz
    // =====================================================
    wire proc_clk;

    clk_divider u_clkdiv (
        .clk_in  (clk_100mhz),
        .rst     (btnU),
        .clk_out (proc_clk)
    );

    // =====================================================
    // Button Synchronizer (btnC -> processor clock domain)
    // =====================================================
    reg [1:0] btnC_sync;
    always @(posedge proc_clk or posedge btnU) begin
        if (btnU)
            btnC_sync <= 2'b00;
        else
            btnC_sync <= {btnC_sync[0], btnC};
    end
    wire reset_btn_clean = btnC_sync[1];

    // =====================================================
    // Switch Synchronizer (sw -> processor clock domain)
    // =====================================================
    reg [15:0] sw_sync1, sw_sync2;
    always @(posedge proc_clk or posedge btnU) begin
        if (btnU) begin
            sw_sync1 <= 16'd0;
            sw_sync2 <= 16'd0;
        end else begin
            sw_sync1 <= sw;
            sw_sync2 <= sw_sync1;
        end
    end

    // =====================================================
    // RISC-V Processor
    // =====================================================
    wire [31:0] display_out;

    TopLevelProcessor u_proc (
        .clk       (proc_clk),
        .rst       (btnU),
        .switches  (sw_sync2),
        .reset_btn (reset_btn_clean),
        .display_out(display_out)
    );

    // =====================================================
    // Seven-Segment Display
    // =====================================================
    SevenSegController u_7seg (
        .clk_100mhz (clk_100mhz),
        .rst         (btnU),
        .value       (display_out[4:0]),  // 0-16 fits in 5 bits
        .seg         (seg),
        .an          (an)
    );

    // =====================================================
    // LED Output (mirrors display value for debugging)
    // =====================================================
    assign led = display_out[15:0];

    // Decimal point off (active-low)
    assign dp = 1'b1;

endmodule
