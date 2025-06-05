/*
 * my_binary_leds_V2.c
 *
 *  COMPSYS 701 - March 2024
 *      Author: Morteza
 */

#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

// Header files added for using high resolution timer
#include "altera_avalon_timer_regs.h"
#include "sys/alt_timestamp.h"


int main()
{
	while(1){
		
	}
}


void display(int address, int number)
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


