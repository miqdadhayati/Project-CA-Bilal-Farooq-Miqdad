`timescale 1ns / 1ps

module RegisterFile(
    input  wire        clk,
    input  wire        rst,
    input  wire        WriteEnable,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] WriteData,
    output wire [31:0] readData1,
    output wire [31:0] readData2
);
    reg [31:0] registers [0:31];
    integer i;

    // Asynchronous read (x0 hardwired to 0)
    assign readData1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign readData2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    // Synchronous write (never write to x0)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else if (WriteEnable && rd != 5'd0) begin
            registers[rd] <= WriteData;
        end
    end
endmodule
