#include <stdio.h>
#include "app.h"

void app(const packet_t *buf, void *output) {
    u8_t oper  = buf -> inst & 0x00FF;
    u8_t param = buf -> inst >> 8;
    printf("[app] Received operation: 0x%02X, parameter: %d\n", oper, param);

    if (oper & OPER_LOAD_INST) {
        printf("[app] Loading instructions into DNN accelerator...\n");

        int i, j;
        for (i = 0; i < param; i++) {
            u64_t inst = 0;
            for (j = 0; j < 8; j++) {
                inst |= ((u64_t)(buf -> data[i * 8 + j])) << (j * 8);
            }
            printf("[app] Instruction %d: 0x%016llX\n", i, inst);
            XBram_WriteReg(INST_Bram.Config.MemBaseAddress, i * 8, (u32_t)(inst & 0xFFFFFFFF));
            XBram_WriteReg(INST_Bram.Config.MemBaseAddress, i * 8 + 4, (u32_t)(inst >> 32));
        }

        printf("[app] %d instructions loaded.\n", param);

    } else if (oper & OPER_LOAD_WEIGHT) {
        printf("[app] Loading weights into DNN accelerator...\n");

        int i, j;
        for (i = 0; i < INPUT_BUFFER_SIZE; i += 4) {
            u32_t word = 0;
            u32_t addr = i + INPUT_BUFFER_SIZE * (u32_t)param;
            for (j = 0; j < 4; j++) {
                word |= ((u32_t)(buf -> data[i + j])) << (j * 8);
            }
            XBram_WriteReg(FILTER_Bram.Config.MemBaseAddress, addr, word);
        }

        printf("[app] Weights loaded into BRAM.\n");

    } else if (oper & OPER_IMAGE) {
        printf("[app] Processing image through DNN accelerator...\n");

        // TODO: only for test
        int i;
        for (i = 0; i < 4096; i++) {
            u32_t word = 0;
            if (i % 4 == 0) {
                word |= (u32_t)(buf -> data[i >> 2]);
            }
            XBram_WriteReg(IFM_Bram.Config.MemBaseAddress, i << 2, word);
        }

        printf("[app] Input feature map loaded into BRAM.\n");
        printf("[app] Starting CNN inference...\n");

        // Start DNN accelerator
        XGpioPs_WritePin(&Gpio, GPIO_START_PIN, 0x1);
        delay(10);

        // Pool until done
        while (XGpioPs_ReadPin(&Gpio, GPIO_DONE_PIN) == 0) {
            delay(100);
        }
        XGpioPs_WritePin(&Gpio, GPIO_START_PIN, 0x0);

        printf("[app] CNN inference completed.\n");

        // Read output
        // TODO: only for test
        for (i = 0; i < 4; i++) {
            u32_t word = XBram_ReadReg(IFM_Bram.Config.MemBaseAddress, i << 2);
            ((u32_t *)output)[i] = word;
            printf("[app] Output word %d: 0x%08X\n", i, word);
        }

    } else {
        printf("[app] Unknown operation code: 0x%02X\n", oper);
    }
}

int driver_init() {
    int status;

    status = bram_init();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = gpio_init();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}

int bram_init() {
    int Status;
    XBram_Config *ConfigPtr;

	ConfigPtr = XBram_LookupConfig(IFM_BRAM_DEVICE_ID);
    if (ConfigPtr == (XBram_Config *) NULL) {
		return XST_FAILURE;
	}
	Status = XBram_CfgInitialize(&IFM_Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
    if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
    InitializeECC(ConfigPtr, ConfigPtr->CtrlBaseAddress);

    ConfigPtr = XBram_LookupConfig(FILTER_BRAM_DEVICE_ID);
    if (ConfigPtr == (XBram_Config *) NULL) {
        return XST_FAILURE;
    }
    Status = XBram_CfgInitialize(&FILTER_Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    InitializeECC(ConfigPtr, ConfigPtr->CtrlBaseAddress);

    ConfigPtr = XBram_LookupConfig(INST_BRAM_DEVICE_ID);
    if (ConfigPtr == (XBram_Config *) NULL) {
        return XST_FAILURE;
    }
    Status = XBram_CfgInitialize(&INST_Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    InitializeECC(ConfigPtr, ConfigPtr->CtrlBaseAddress);

    return XST_SUCCESS;
}

void InitializeECC(XBram_Config *ConfigPtr, u32 EffectiveAddr)
{
	u32 Addr;
	volatile u32 Data;

	if (ConfigPtr->EccPresent &&
        ConfigPtr->EccOnOffRegister &&
        ConfigPtr->EccOnOffResetValue == 0 &&
        ConfigPtr->WriteAccess != 0) {
		for (Addr = ConfigPtr->MemBaseAddress;
                Addr < ConfigPtr->MemHighAddress; Addr+=4) {
			Data = XBram_In32(Addr);
			XBram_Out32(Addr, Data);
		}
		XBram_WriteReg(EffectiveAddr, XBRAM_ECC_ON_OFF_OFFSET, 1);
	}
}

int gpio_init() {
    int Status;
	XGpioPs_Config *ConfigPtr;

    ConfigPtr = XGpioPs_LookupConfig(GPIO_DEVICE_ID);
	Status = XGpioPs_CfgInitialize(&Gpio, ConfigPtr, ConfigPtr->BaseAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

    XGpioPs_SetDirectionPin(&Gpio, GPIO_START_PIN, 0x1);
    XGpioPs_SetOutputEnablePin(&Gpio, GPIO_START_PIN, 0x1);
	XGpioPs_WritePin(&Gpio, GPIO_START_PIN, 0x0);

    XGpioPs_SetDirectionPin(&Gpio, GPIO_DONE_PIN, 0x0);

    return XST_SUCCESS;
}

void delay(u32_t cycles) {
    volatile u32_t i;
    for (i = 0; i < cycles; i++);
}
