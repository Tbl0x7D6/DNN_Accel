#include <stdio.h>

#include "lwip/sockets.h"
#include "netif/xadapter.h"
#include "lwipopts.h"
#include "xil_printf.h"
#include "FreeRTOS.h"
#include "task.h"

#include "app.h"

u16_t echo_port = 7;

void server()
{
    if (driver_init() != XST_SUCCESS) {
        printf("BRAM initialization failed!\n");
        vTaskDelete(NULL);
        return;
    }

	int sock;
	struct sockaddr_in address, cliaddr;

	if ((sock = lwip_socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		vTaskDelete(NULL);
		return;
	}

	address.sin_family = AF_INET;
	address.sin_port = htons(echo_port);
	address.sin_addr.s_addr = INADDR_ANY;

	if (lwip_bind(sock, (struct sockaddr *)&address, sizeof (address)) < 0) {
		lwip_close(sock);
		vTaskDelete(NULL);
		return;
	}

	printf("[server] Started on port %d\n", echo_port);

	while (1) {
        socklen_t len = sizeof(cliaddr);

        packet_t buf;
        u8_t output[OUTPUT_BUFFER_SIZE];

        int n = lwip_recvfrom(sock, &buf, sizeof(packet_t),
                            0, (struct sockaddr *) &cliaddr, &len);
        if (n < 0) {
            printf("[server] Error receiving data\n");
            break;
        }

        printf("[server] Received request of %d bytes\n", n);
        app(&buf, output);

        lwip_sendto(sock, (const char *) &(buf.inst), sizeof(buf.inst),
                    0, (const struct sockaddr *) &cliaddr, len);
    }

    lwip_close(sock);
    vTaskDelete(NULL);
    return;
}
