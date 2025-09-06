#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "sleep.h"

#define	XGPIO_LED_SW_BASEADDRESS	XPAR_XGPIO_0_BASEADDR

#define LED_CH  1
#define SW_CH   2

static XGpio Gpio;

static inline unsigned state_from_switches(unsigned sw) {
    switch (sw & 0x3) {
        case 0x0:   return 0b0001;
        case 0x1:   return 0b0011;
        case 0x2:   return 0b0111;
        default:    return 0b1111;
    }
}

static inline unsigned apply_mode(unsigned state, unsigned mode) {
    switch (mode & 0x3) {
        case 0x0:   return state;
        case 0x1:   return (state >> 2);
        case 0x2:   return ((state << 3) | (state >> 1)) & 0xF;
        default:    return (~state) & 0xF;
    }
}

int main(void) {
    int Status;
	Status = XGpio_Initialize(&Gpio, XGPIO_LED_SW_BASEADDRESS);
	if (Status != XST_SUCCESS) {
		xil_printf("Gpio Initialization Failed\r\n");
		return XST_FAILURE;
	}
    XGpio_SetDataDirection(&Gpio, LED_CH, 0x0);
    XGpio_SetDataDirection(&Gpio, SW_CH, 0x3);

    unsigned int mode = 0;
    while (1) {
        unsigned sw = XGpio_DiscreteRead(&Gpio, SW_CH);
        unsigned out = apply_mode(state_from_switches(sw), mode);
        XGpio_DiscreteWrite(&Gpio, LED_CH, out);
        mode++;
        sleep(1);
    }
}