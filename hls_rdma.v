`timescale 1 ns / 1 ps

module hls_rdma (
    input wire ap_clk,
    input wire ap_rst_n,
    input wire ap_start,
    output wire ap_done,
    output wire ap_idle,
    output wire ap_ready,

    // AXI4-Stream 인터페이스 (출력)
    output wire [31:0] m_axi_rdata,
    output wire m_axi_rvalid,
    input wire m_axi_rready,

    // DRAM AXI 인터페이스
    output wire [31:0] m_axi_araddr,
    output wire m_axi_arvalid,
    input wire m_axi_arready
);

    // ✅ FIFO 추가: DRAM → FIFO → AXI Stream
    wire [31:0] fifo_out;
    wire fifo_empty, fifo_rd_en;

    fifo #(
        .DATA_WIDTH(32),
        .FIFO_DEPTH(16)
    ) fifo_rd (
        .clk(ap_clk),
        .reset_n(ap_rst_n),
        .wr_en(m_axi_arvalid && m_axi_arready),
        .din(m_axi_rdata),
        .full(),
        .rd_en(fifo_rd_en),
        .dout(fifo_out),
        .empty(fifo_empty)
    );

    // AXI Stream 인터페이스 연결
    assign m_axi_rvalid = ~fifo_empty;
    assign fifo_rd_en = m_axi_rready;
    assign m_axi_rdata = fifo_out;

    // RDMA 완료 신호
    assign ap_done = 1'b1;
    assign ap_idle = 1'b0;
    assign ap_ready = 1'b1;

endmodule
