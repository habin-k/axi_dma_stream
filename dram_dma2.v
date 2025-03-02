`timescale 1ns / 1ps

module dram_axi_dma_stream #(
    parameter integer DATA_WIDTH = 32
)(
    input  wire                 clk,
    input  wire                 reset_n,

    // AXI4 Stream 인터페이스 (DRAM → FPGA)
    output wire [DATA_WIDTH-1:0] axi_stream_tdata,
    output wire                 axi_stream_tvalid,
    input  wire                 axi_stream_tready,

    // AXI4 Stream 인터페이스 (FPGA → DRAM)
    input  wire [DATA_WIDTH-1:0] axi_stream_tdata_in,
    input  wire                 axi_stream_tvalid_in,
    output wire                 axi_stream_tready_in,

    // DRAM AXI4 인터페이스 (Read 채널)
    output wire [31:0]          m_axi_araddr,
    output wire                 m_axi_arvalid,
    input  wire                 m_axi_arready,
    input  wire [DATA_WIDTH-1:0] m_axi_rdata,
    input  wire                 m_axi_rvalid,
    output wire                 m_axi_rready,
    
    // DRAM AXI4 인터페이스 (Write 채널)
    output wire [31:0]          m_axi_awaddr,
    output wire                 m_axi_awvalid,
    input  wire                 m_axi_awready,
    output wire [DATA_WIDTH-1:0] m_axi_wdata,
    output wire                 m_axi_wvalid,
    input  wire                 m_axi_wready,

    // 완료(done) 신호 (옵션)
    output wire                 rdma_done,
    output wire                 wdma_done
);

    // 내부 완료 신호 연결용 와이어
    wire rdma_done_internal;
    wire wdma_done_internal;

    // HLS 기반 RDMA 모듈 (DRAM → FPGA 데이터 전송)
    hls_rdma rdma_inst (
        .ap_clk           (clk),
        .ap_rst_n         (reset_n),
        .ap_start         (1'b1),    // 단순 테스트를 위해 항상 동작
        .m_axi_araddr     (m_axi_araddr),
        .m_axi_arvalid    (m_axi_arvalid),
        .m_axi_arready    (m_axi_arready),
        .m_axi_rdata      (m_axi_rdata),
        .m_axi_rvalid     (m_axi_rvalid),
        .m_axi_rready     (m_axi_rready),
        .axi_stream_tdata (axi_stream_tdata),
        .axi_stream_tvalid(axi_stream_tvalid),
        .axi_stream_tready(axi_stream_tready),
        .done             (rdma_done_internal)
    );

    // HLS 기반 WDMA 모듈 (FPGA → DRAM 데이터 전송)
    hls_wdma wdma_inst (
        .ap_clk           (clk),
        .ap_rst_n         (reset_n),
        .ap_start         (1'b1),    // 단순 테스트를 위해 항상 동작
        .m_axi_awaddr     (m_axi_awaddr),
        .m_axi_awvalid    (m_axi_awvalid),
        .m_axi_awready    (m_axi_awready),
        .m_axi_wdata      (m_axi_wdata),
        .m_axi_wvalid     (m_axi_wvalid),
        .m_axi_wready     (m_axi_wready),
        .axi_stream_tdata_in(axi_stream_tdata_in),
        .axi_stream_tvalid_in(axi_stream_tvalid_in),
        .axi_stream_tready_in(axi_stream_tready_in),
        .done             (wdma_done_internal)
    );

    // 완료 신호를 외부 출력으로 연결
    assign rdma_done = rdma_done_internal;
    assign wdma_done = wdma_done_internal;

endmodule
