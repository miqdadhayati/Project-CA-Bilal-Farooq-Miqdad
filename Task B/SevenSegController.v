`timescale 1ns / 1ps

module SevenSegController(
    input  wire        clk_100mhz,
    input  wire        rst,
    input  wire [4:0]  value,       // 0-16
    output reg  [6:0]  seg,         // active-low cathodes {g,f,e,d,c,b,a}
    output reg  [3:0]  an           // active-low anodes
);

    // --- BCD Conversion (0-16 -> tens + ones) ---
    wire [3:0] tens_val = (value >= 5'd10) ? 4'd1 : 4'd0;
    wire [3:0] ones_val = (value >= 5'd10) ? (value - 5'd10) : value[3:0];

    // --- Refresh Counter for Display Multiplexing ---
    // 100MHz / 2^17 ≈ 763 Hz refresh rate per digit
    reg [16:0] refresh_counter;
    wire [1:0] digit_sel = refresh_counter[16:15];

    always @(posedge clk_100mhz or posedge rst) begin
        if (rst)
            refresh_counter <= 17'd0;
        else
            refresh_counter <= refresh_counter + 1;
    end

    // --- Digit Selection ---
    // Leftmost 2 digits active (AN3=tens, AN2=ones); rightmost 2 blanked
    // (AN0/AN1 not working on this FPGA board)
    reg [3:0] current_digit;
    wire display_blank = 1'b0;

    always @(*) begin
        if (display_blank) begin
            an = 4'b1111;           // all digits off
            current_digit = 4'd0;
        end else begin
            case (digit_sel)
                2'b00: begin        // AN2 (second from left) = ones
                    an = 4'b1011;
                    current_digit = ones_val;
                end
                2'b01: begin        // AN3 (leftmost) = tens
                    an = 4'b0111;
                    current_digit = tens_val;
                end
                2'b10: begin        // AN0 = blanked (broken)
                    an = 4'b1111;
                    current_digit = 4'd0;
                end
                2'b11: begin        // AN1 = blanked (broken)
                    an = 4'b1111;
                    current_digit = 4'd0;
                end
                default: begin
                    an = 4'b1111;
                    current_digit = 4'd0;
                end
            endcase
        end
    end

    // --- Seven-Segment Decoder (active-low) ---
    // seg[6:0] = {g, f, e, d, c, b, a}
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1000000;   //  _
            4'd1: seg = 7'b1111001;   //   |
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; // blank
        endcase
    end

endmodule
