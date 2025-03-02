# axi_dma_stream

- tb is the testbench (needs to be fixed)

흐름: RDMA는 DRAM에서 데이터를 읽어 AXI-stream을 통해 FPGA로 전달, WDMA는 AXI 스트림으로 입력된 데이터를 DRAM으로 기록

데이터가 DRAM으로 기록되도록 하기 위해 넣어야 하는 데이터는 axi_stream_tdata_in 포트
DRAM에서 읽은 데이터는 axi_stream_tdata 포트로 출력될 수 있고, 이 데이터를 외부 인터페이스(예: 디스플레이, 프로세서 등)로 전달할 수 있음

* 연산 결과가 동시다발적으로 나올 때는 각자 fifo를 두어야하나?
* 내부에서 순차적으로 출력되도록 만든다음 하나의 stream으로 나오게 하면 
