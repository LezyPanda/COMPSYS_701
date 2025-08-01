#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include <inttypes.h>

void display7(int address, int number)
{
	int hex = 0x0000000;
	if (number == 0)
		hex = 64;
	else if (number == 1)
		hex = 121;
	else if (number == 2)
		hex = 36;
	else if (number == 3)
		hex = 48;
	else if (number == 4)
		hex = 25;
	else if (number == 5)
		hex = 18;
	else if (number == 6)
		hex = 2;
	else if (number == 7)
		hex = 120;
	else if (number == 8)
		hex = 0;
	else if (number == 9)
		hex = 16;


	IOWR_ALTERA_AVALON_PIO_DATA(address, hex);
}

int main()
{
	uint32_t maxCorr = 0;
	IOWR_ALTERA_AVALON_PIO_DATA(HEX0_BASE, 15);
	IOWR_ALTERA_AVALON_PIO_DATA(HEX1_BASE, 15);
	IOWR_ALTERA_AVALON_PIO_DATA(HEX2_BASE, 15);
	IOWR_ALTERA_AVALON_PIO_DATA(HEX3_BASE, 15);
	IOWR_ALTERA_AVALON_PIO_DATA(HEX4_BASE, 15);
	IOWR_ALTERA_AVALON_PIO_DATA(HEX5_BASE, 15);
	while(1)
	{
		volatile uint32_t recvData = IORD_ALTERA_AVALON_PIO_DATA(TDMA_RECV_DATA_BASE);
		if ((((recvData >> 28) & 0xF) == 0b1000)) // Is Data Packet
		{
			uint16_t id = ((recvData >> 20) & 0xF);
			if (id == 0b0111) // From Peak Detecting
			{
				uint8_t peakDetected = (recvData >> 18) & 1; // 18
				if (peakDetected == 1) // A Peak is Detected
				{
					uint32_t corrCount = recvData & (0x3FFFF); // 17 downto 0

					if (corrCount > maxCorr)
					{
						display7(HEX0_BASE, corrCount % 10);
						display7(HEX1_BASE, corrCount / 10 % 10);
						display7(HEX2_BASE, corrCount / 100 % 10);
						maxCorr = corrCount;
					}

					// Corr Read
					IOWR_ALTERA_AVALON_PIO_DATA(TDMA_SEND_ADDR_BASE, 0b0100); // To Peak Detector
					IOWR_ALTERA_AVALON_PIO_DATA(TDMA_SEND_DATA_BASE, (0b1000 << 28) | (0b0110 << 20) | 0b11); // 1000 (31~28), 0110 (23~20), 11 (1~0)
				}
			}
		}
	}
	return 0;


}

