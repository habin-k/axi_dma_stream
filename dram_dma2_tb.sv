`timescale 1ns / 1ps

module dram_dma2_tb;

    reg clk;
    reg reset_n;
    
    // AXI Stream 인터페이스 (DRAM → FPGA)
    wire [31:0] axi_stream_tdata;
    wire        axi_stream_tvalid;
    reg         axi_stream_tready;
    
    // AXI Stream 인터페이스 (FPGA → DRAM)
    reg  [31:0] axi_stream_tdata_in;
    reg         axi_stream_tvalid_in;
    wire        axi_stream_tready_in;
    
    // DRAM AXI 인터페이스 (Read 채널)
    wire [31:0] m_axi_araddr;
    wire        m_axi_arvalid;
    reg         m_axi_arready;
    reg  [31:0] m_axi_rdata_reg;
    reg         m_axi_rvalid_reg;
    wire [31:0] m_axi_rdata;
    wire        m_axi_rvalid;
    reg         m_axi_rready;
    
    // DRAM AXI 인터페이스 (Write 채널)
    wire [31:0] m_axi_awaddr;
    wire        m_axi_awvalid;
    reg         m_axi_awready;
    wire [31:0] m_axi_wdata;
    wire        m_axi_wvalid;
    reg         m_axi_wready;
    
    // 완료(done) 신호
    wire rdma_done;
    wire wdma_done;
    
    // AXI Read data 드라이버: 내부 레지스터와 연결
    assign m_axi_rdata  = m_axi_rdata_reg;
    assign m_axi_rvalid = m_axi_rvalid_reg;
    
    // DUT 인스턴스화
    dram_axi_dma_stream uut (
        .clk                (clk),
        .reset_n            (reset_n),
        .axi_stream_tdata   (axi_stream_tdata),
        .axi_stream_tvalid  (axi_stream_tvalid),
        .axi_stream_tready  (axi_stream_tready),
        .axi_stream_tdata_in(axi_stream_tdata_in),
        .axi_stream_tvalid_in(axi_stream_tvalid_in),
        .axi_stream_tready_in(axi_stream_tready_in),
        .m_axi_araddr       (m_axi_araddr),
        .m_axi_arvalid      (m_axi_arvalid),
        .m_axi_arready      (m_axi_arready),
        .m_axi_rdata        (m_axi_rdata),
        .m_axi_rvalid       (m_axi_rvalid),
        .m_axi_rready       (m_axi_rready),
        .m_axi_awaddr       (m_axi_awaddr),
        .m_axi_awvalid      (m_axi_awvalid),
        .m_axi_awready      (m_axi_awready),
        .m_axi_wdata        (m_axi_wdata),
        .m_axi_wvalid       (m_axi_wvalid),
        .m_axi_wready       (m_axi_wready),
        .rdma_done          (rdma_done),
        .wdma_done          (wdma_done)
    );
    
    // 클럭 생성: 10ns 주기 (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 리셋 생성: 초기 20ns 동안 Low 후 High
    initial begin
        reset_n = 0;
        #20;
        reset_n = 1;
    end
    
    // 기본 AXI 채널 신호 초기화
    initial begin
        axi_stream_tready = 1;  // 항상 ready
        m_axi_arready   = 1;    // 항상 read address 수락
        m_axi_awready   = 1;    // 항상 write address 수락
        m_axi_rready    = 1;    // 항상 read data 수락
        m_axi_wready    = 1;    // 항상 write data 수락
    end
    
    // FPGA → DRAM 스트림 데이터 자극 (WDMA 입력)
    initial begin
        axi_stream_tdata_in  = 32'd0;
        axi_stream_tvalid_in = 0;
        // 리셋 후 잠시 대기
        @(posedge reset_n);
        // 10회의 데이터 전송 시도
        repeat (10) begin
            @(posedge clk);
            axi_stream_tdata_in  <= axi_stream_tdata_in + 1;
            axi_stream_tvalid_in <= 1;
            @(posedge clk);
            axi_stream_tvalid_in <= 0;
            // 거래 간 1 사이클 대기
            @(posedge clk);
        end
    end
    
    // AXI Read Response 시뮬레이션 (간단한 카운터 데이터 제공)
    reg [31:0] read_counter;
    initial begin
        read_counter      = 0;
        m_axi_rdata_reg   = 0;
        m_axi_rvalid_reg  = 0;
    end
    
    always @(posedge clk) begin
        if (!reset_n) begin
            read_counter     <= 0;
            m_axi_rdata_reg  <= 0;
            m_axi_rvalid_reg <= 0;
        end else begin
            if (m_axi_arvalid && m_axi_arready) begin
                // read 주소 핸드쉐이크 발생 시, 다음 사이클에 데이터를 제공
                m_axi_rdata_reg  <= read_counter;
                m_axi_rvalid_reg <= 1;
                read_counter     <= read_counter + 1;
            end else if (m_axi_rready && m_axi_rvalid_reg) begin
                // 데이터가 수락되면 rvalid를 낮춤
                m_axi_rvalid_reg <= 0;
            end
        end
    end
    
    // Write Transaction 모니터링
    always @(posedge clk) begin
        if (m_axi_awvalid && m_axi_awready)
            $display("Time %t: Write Address Transaction - Address: %h", $time, m_axi_awaddr);
        if (m_axi_wvalid && m_axi_wready)
            $display("Time %t: Write Data Transaction - Data: %h", $time, m_axi_wdata);
    end
    
    // Read Transaction 모니터링
    always @(posedge clk) begin
        if (m_axi_arvalid && m_axi_arready)
            $display("Time %t: Read Address Transaction - Address: %h", $time, m_axi_araddr);
    end
    
    // RDMA/WDMA 완료 신호 모니터링
    always @(posedge clk) begin
        if (rdma_done)
            $display("Time %t: RDMA done signal asserted.", $time);
        if (wdma_done)
            $display("Time %t: WDMA done signal asserted.", $time);
    end
    
    // 시뮬레이션 종료
    initial begin
        #1000;
        $finish;
    end

endmodule
