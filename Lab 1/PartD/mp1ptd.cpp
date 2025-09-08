#include "xparameters.h"
#include "xuartps.h"
#include "xaxidma.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xdebug.h"

#define CAESAR_BASE	0x60000000
#define REG_SHIFT         0x00

#define MAX_STR_LEN       256
#define BUF_ALIGN         64

// statically aligned buffers (in DDR, via default linker script)
static uint8_t InBuf [MAX_STR_LEN + 4]  __attribute__((aligned(BUF_ALIGN)));
static uint8_t OutBuf[MAX_STR_LEN + 4]  __attribute__((aligned(BUF_ALIGN)));

// Simple BD memories for one-BD-per-direction rings (small lab pattern)
static uint8_t TxRingMem[256] __attribute__((aligned(64)));
static uint8_t RxRingMem[256] __attribute__((aligned(64)));

XAxiDma AxiDma;

volatile u32 TxDone;
volatile u32 RxDone;
volatile u32 Error;

static int uart_getline(char *dst, int maxn) {
  int n = 0;
  while (n < maxn - 1) {
    int c = XUartPs_RecvByte(STDIN_BASEADDRESS);
    if (c == '\r' || c == '\n') {
      // eat the paired \n if CR was seen first (or vice versa)
      // (non-blocking check is fine to skip here for simplicity)
      dst[n] = 0;
      return n;
    }
    dst[n++] = (char)c;
  }
  dst[n] = 0;
  return n;
}

static void uart_puts(const char *s) {
  while (*s) {
    XUartPs_SendByte(STDIN_BASEADDRESS, (uint8_t)*s++);
  }
}

// ---------- DMA SG ring bring-up (one BD each way) ----------
static int setup_dma_sg_single(XAxiDma *Dma) {
  int Status;
  XAxiDma_BdRing *TxRing = XAxiDma_GetTxRing(Dma);
  XAxiDma_BdRing *RxRing = XAxiDma_GetRxRing(Dma);

  // Create rings in our small static buffers
  Status = XAxiDma_BdRingCreate(TxRing, (UINTPTR)TxRingMem, (UINTPTR)TxRingMem,
                                XAXIDMA_BD_MINIMUM_ALIGNMENT, 1);
  if (Status != XST_SUCCESS) return XST_FAILURE;

  Status = XAxiDma_BdRingCreate(RxRing, (UINTPTR)RxRingMem, (UINTPTR)RxRingMem,
                                XAXIDMA_BD_MINIMUM_ALIGNMENT, 1);
  if (Status != XST_SUCCESS) return XST_FAILURE;

  // Interrupt coalescing: 1; we’ll poll
  XAxiDma_BdRingSetCoalesce(TxRing, 1, 1);
  XAxiDma_BdRingSetCoalesce(RxRing, 1, 1);

  // Start rings
  Status = XAxiDma_BdRingStart(TxRing);
  if (Status != XST_SUCCESS) return XST_FAILURE;

  Status = XAxiDma_BdRingStart(RxRing);
  if (Status != XST_SUCCESS) return XST_FAILURE;

  return XST_SUCCESS;
}


int main(void) {
	int Status;

  	xil_printf("\r\n=== Caesar Accelerator config start ===\r\n");

	// Init DMA
	XAxiDma_Config *Cfg = XAxiDma_LookupConfig(XPAR_XAXIDMA_0_BASEADDR);
	if (!Cfg) {
		xil_printf("ERROR: XAxiDma_LookupConfig failed\r\n");
		return -1;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, Cfg);
	if (Status != XST_SUCCESS) {
		xil_printf("ERROR: XAxiDma_CfgInitialize failed (%d)\r\n", Status);
		return -2;
	}

	if (!XAxiDma_HasSg(&AxiDma)) {
		xil_printf("ERROR: DMA not in SG mode (enable SG in IP config)\r\n");
		return -3;
	}

	Status = setup_dma_sg_single(&AxiDma);
	if (Status != XST_SUCCESS) {
		xil_printf("ERROR: setup_dma_sg_single failed\r\n");
		return -4;
	}

    while (1) {
		// i) Read shift (signed 32-bit)
		xil_printf("\r\nEnter 32-bit signed shift (e.g., 3 or -3): \r\n");
		char line[64];
		int ln = uart_getline(line, sizeof(line));
		if (ln <= 0) continue;
		int shift = (int)strtol(line, NULL, 0);

		int32_t k_mod = shift % 26;         // C keeps sign of dividend
		if (k_mod < 0) k_mod += 26;
		// Write to accelerator AXI-Lite register (low 8 bits are used in HW)
		Xil_Out32(CAESAR_BASE + REG_SHIFT, (int32_t)k_mod);

		// ii) Read input string (≤256 chars)
		xil_printf("\r\nEnter text (max %d chars), then Enter:\r\n", MAX_STR_LEN);
		char text[MAX_STR_LEN + 1];
		int n = uart_getline(text, sizeof(text));
		if (n < 0) n = 0;
		if (n > MAX_STR_LEN) n = MAX_STR_LEN;

		// Prepare input buffer; pad to 4 bytes for clean AXIS word beats
		int pad = (4 - (n & 3)) & 3;
		int in_bytes = n + pad;
		memset(InBuf, 0, sizeof(InBuf));
		memcpy(InBuf, text, n);

		// Cache maintenance (if DCache enabled)
		Xil_DCacheFlushRange((UINTPTR)InBuf, in_bytes);
		Xil_DCacheInvalidateRange((UINTPTR)OutBuf, in_bytes);

		// ii) Create DMA descriptors and run the accelerator on that string
		XAxiDma_BdRing *RxRing = XAxiDma_GetRxRing(&AxiDma);
		XAxiDma_BdRing *TxRing = XAxiDma_GetTxRing(&AxiDma);
		XAxiDma_Bd *RxBd, *TxBd;

		// --- S2MM (device->mem) BD for output ---
		Status = XAxiDma_BdRingAlloc(RxRing, 1, &RxBd);
		if (Status != XST_SUCCESS) {
		xil_printf("ERROR: Rx BdRingAlloc\r\n");
		continue;
		}
		XAxiDma_BdClear(RxBd);
		XAxiDma_BdSetBufAddr(RxBd, (UINTPTR)OutBuf);
		XAxiDma_BdSetLength(RxBd, in_bytes, RxRing->MaxTransferLen);
		XAxiDma_BdSetCtrl(RxBd, 0);
		Status = XAxiDma_BdRingToHw(RxRing, 1, RxBd);
		if (Status != XST_SUCCESS) {
		xil_printf("ERROR: Rx BdRingToHw\r\n");
		XAxiDma_BdRingFree(RxRing, 1, RxBd);
		continue;
		}

		// --- MM2S (mem->device) BD for input ---
		Status = XAxiDma_BdRingAlloc(TxRing, 1, &TxBd);
		if (Status != XST_SUCCESS) {
		xil_printf("ERROR: Tx BdRingAlloc\r\n");
		// Attempt to cancel the RX we queued:
		// (In a lab setting, a board reset is often easier if this fails)
		continue;
		}
		XAxiDma_BdClear(TxBd);
		XAxiDma_BdSetBufAddr(TxBd, (UINTPTR)InBuf);
		XAxiDma_BdSetLength(TxBd, in_bytes, TxRing->MaxTransferLen);
		// Single packet: SOF+EOF => TLAST asserted at end of stream
		XAxiDma_BdSetCtrl(TxBd, XAXIDMA_BD_CTRL_TXSOF_MASK | XAXIDMA_BD_CTRL_TXEOF_MASK);
		Status = XAxiDma_BdRingToHw(TxRing, 1, TxBd);
		if (Status != XST_SUCCESS) {
		xil_printf("ERROR: Tx BdRingToHw\r\n");
		XAxiDma_BdRingFree(TxRing, 1, TxBd);
		continue;
		}

		// --- iii) Poll for completion on both rings ---
		// TX (MM2S)
		while (XAxiDma_BdRingFromHw(TxRing, 1, &TxBd) == 0) { /* spin */ }
		XAxiDma_BdRingFree(TxRing, 1, TxBd);

		// RX (S2MM)
		while (XAxiDma_BdRingFromHw(RxRing, 1, &RxBd) == 0) { /* spin */ }
		// optional: check RxBd status bits here
		XAxiDma_BdRingFree(RxRing, 1, RxBd);

		// Invalidate cache for received region
		Xil_DCacheInvalidateRange((UINTPTR)OutBuf, in_bytes);

		// iv) Print shifted string back (original length, without pad)
		OutBuf[n] = 0;
		uart_puts("Shifted: ");
		uart_puts((char*)OutBuf);
		uart_puts("\r\n");
    }
}