`timescale 1 ns / 1 ps

module hls_wdma (
    input wire ap_clk,
    input wire ap_rst_n,
    input wire ap_start,
    output wire ap_done,
    output wire ap_idle,
    output wire ap_ready,

    // AXI4-Stream 인터페이스 (입력)
    input wire [31:0] m_axi_wdata,
    input wire m_axi_wvalid,
    output wire m_axi_wready,

    // DRAM AXI 인터페이스
    output wire [31:0] m_axi_awaddr,
    output wire m_axi_awvalid,
    input wire m_axi_awready
);

    // ✅ FIFO 추가: AXI Stream → FIFO → DRAM
    wire [31:0] fifo_out;
    wire fifo_full, fifo_wr_en;

    fifo #(
        .DATA_WIDTH(32),
        .FIFO_DEPTH(16)
    ) fifo_wr (
        .clk(ap_clk),
        .reset_n(ap_rst_n),
        .wr_en(fifo_wr_en),
        .din(m_axi_wdata),
        .full(fifo_full),
        .rd_en(m_axi_awready),
        .dout(fifo_out),
        .empty()
    );

    // AXI Stream 인터페이스 연결
    assign m_axi_wready = ~fifo_full;
    assign fifo_wr_en = m_axi_wvalid;
    assign m_axi_awvalid = ~fifo_full;
    assign m_axi_awaddr = fifo_out;

    // WDMA 완료 신호
    assign ap_done = 1'b1;
    assign ap_idle = 1'b0;
    assign ap_ready = 1'b1;

endmodule
