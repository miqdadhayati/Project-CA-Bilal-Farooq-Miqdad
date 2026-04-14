`timescale 1ns / 1ps

module clk_divider(
    input  wire clk_in,    // 100 MHz
    input  wire rst,
    output reg  clk_out    // 10 MHz
);
    // Divide by 10: toggle output every 5 input cycles
    // Period = 10 * 10ns = 100ns = 10 MHz
    reg [2:0] counter;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter == 3'd4) begin
                counter <= 3'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
