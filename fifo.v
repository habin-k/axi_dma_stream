`timescale 1ns / 1ps

module fifo #(
    parameter integer DATA_WIDTH = 32,
    parameter integer FIFO_DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  reset_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire                  full,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] dout,
    output wire                  empty
);

    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH:0]   wr_ptr = 0;
    reg [ADDR_WIDTH:0]   rd_ptr = 0;
    reg                  full_reg = 0;
    reg                  empty_reg = 1;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr <= 0;
            full_reg <= 0;
        end else if (wr_en && !full_reg) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
        end
        full_reg <= (wr_ptr - rd_ptr == FIFO_DEPTH);
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rd_ptr <= 0;
            empty_reg <= 1;
        end else if (rd_en && !empty_reg) begin
            rd_ptr <= rd_ptr + 1;
        end
        empty_reg <= (wr_ptr == rd_ptr);
    end
    
    assign dout = fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
    assign full = full_reg;
    assign empty = empty_reg;
    
endmodule