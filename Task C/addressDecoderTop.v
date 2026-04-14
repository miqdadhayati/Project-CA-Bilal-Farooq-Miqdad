`timescale 1ns / 1ps

module addressDecoderTop(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] address,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] writeData,
    input  wire [15:0] switches,
    input  wire        reset_btn,
    output reg  [31:0] readData,
    output reg  [31:0] display_reg   // value written to display address
);

    // --- Address Decoding ---
    // Mathematically: 0x200 is 10_0000_0000 (bits 9:8 are 10)
    // 0x300 is 11_0000_0000 (bits 9:8 are 11)
    wire DataMemSelect  = (address[9] == 1'b0);     // 0-511:   Data Memory (0x00 - 0x1FF)
    wire DisplaySelect  = (address[9:8] == 2'b10);  // 512-767: Display output (0x200 - 0x2FF)
    wire InputSelect    = (address[9:8] == 2'b11);  // 768-1023: Switch/Button input (0x300 - 0x3FF)

    // --- Data Memory ---
    wire [31:0] memReadData;

    DataMemory dm(
        .clk       (clk),
        .MemWrite  (MemWrite & DataMemSelect),
        .address   (address),
        .write_data(writeData),
        .read_data (memReadData)
    );

    // --- Display Output Register (address 0x200) ---
    always @(posedge clk or posedge rst) begin
        if (rst)
            display_reg <= 32'd0;
        else if (MemWrite & DisplaySelect)
            display_reg <= writeData;
    end

    // --- Priority Encoder for Switches ---
    // Finds the HIGHEST set switch bit and returns index + 1
    // Returns 0 if no switches are set
    reg [31:0] switch_encoded;
    integer i;

    always @(*) begin
        switch_encoded = 32'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (switches[i])
                switch_encoded = i + 1;  // overwrites with higher indices
        end
    end

    // --- Read Data Multiplexer ---
    always @(*) begin
        if (DataMemSelect)
            readData = memReadData;
        else if (InputSelect) begin
            if (address[2])
                readData = {31'd0, reset_btn};    // addr 0x304: reset button
            else
                readData = switch_encoded;         // addr 0x300: switch value
        end
        else
            readData = 32'd0;
    end

endmodule
