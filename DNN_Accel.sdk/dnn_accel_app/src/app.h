#ifndef _APP_H_
#define _APP_H_

#include "arch/cc.h"
#include "xparameters.h"
#include "xbram.h"
#include "xgpiops.h"

#define IFM_BRAM_DEVICE_ID       XPAR_BRAM_0_DEVICE_ID
#define FILTER_BRAM_DEVICE_ID    XPAR_BRAM_1_DEVICE_ID
#define INST_BRAM_DEVICE_ID      XPAR_BRAM_2_DEVICE_ID

#define GPIO_DEVICE_ID  	     XPAR_XGPIOPS_0_DEVICE_ID

// EMIO
#define GPIO_START_PIN           54
#define GPIO_DONE_PIN            55

#define INPUT_BUFFER_SIZE        1024
#define OUTPUT_BUFFER_SIZE       16

#define OPER_LOAD_WEIGHT         0x01
#define OPER_LOAD_INST           0x02
#define OPER_IMAGE               0x04

XBram IFM_Bram;
XBram FILTER_Bram;
XBram INST_Bram;

XGpioPs Gpio;

typedef struct {
    u16_t inst;
    u8_t data[INPUT_BUFFER_SIZE];
} packet_t;

int driver_init();
int bram_init();
int gpio_init();
void delay(u32_t cycles);
void app(const packet_t *buf, void *output);
void InitializeECC(XBram_Config *ConfigPtr, u32 EffectiveAddr);

#endif
