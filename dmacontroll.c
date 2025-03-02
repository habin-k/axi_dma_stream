#include <stdio.h>
#include "xaxidma.h"
#include "xparameters.h"

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID
#define DRAM_BASE_ADDR 0x10000000  // DRAM 시작 주소

XAxiDma AxiDma;

int main() {
    XAxiDma_Config *CfgPtr;
    int Status;
    u32 *DramPtr = (u32 *)DRAM_BASE_ADDR;
    u32 StreamData[16];

    printf("Initializing DMA...\n");

    // DMA 초기화
    CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!CfgPtr) {
        printf("DMA Configuration Lookup Failed\n");
        return XST_FAILURE;
    }

    Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
    if (Status != XST_SUCCESS) {
        printf("DMA Initialization Failed\n");
        return XST_FAILURE;
    }

    printf("DMA Initialized Successfully!\n");

    // DRAM 데이터 초기화
    printf("Writing data to DRAM...\n");
    for (int i = 0; i < 16; i++) {
        DramPtr[i] = i + 100;
        printf("DRAM[%d] = %d\n", i, DramPtr[i]);
    }

    // DMA를 사용하여 DRAM 데이터를 AXI Stream으로 전송
    printf("Starting MM2S DMA Transfer (DRAM to AXI Stream)...\n");
    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)DramPtr, 64, XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        printf("MM2S DMA Transfer Failed\n");
        return XST_FAILURE;
    }

    // AXI Stream에서 받은 데이터 확인
    for (int i = 0; i < 16; i++) {
        StreamData[i] = DramPtr[i];  // 실제 환경에서는 AXI Stream 데이터 버퍼에서 읽어야 함
        printf("AXI Stream Data[%d] = %d\n", i, StreamData[i]);
    }

    // DMA를 사용하여 AXI Stream 데이터를 DRAM으로 저장
    printf("Starting S2MM DMA Transfer (AXI Stream to DRAM)...\n");
    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)StreamData, 64, XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        printf("S2MM DMA Transfer Failed\n");
        return XST_FAILURE;
    }

    printf("DMA Stream Transfer Completed Successfully!\n");

    return XST_SUCCESS;
}
