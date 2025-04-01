#include <stdint.h>
#include "macros.h"
#include "registers.h"
#include "constants.h"
#include "modplay.h"
#include "iffl.h"
#include "irqload.h"
#include "dma.h"
#include "dmajobs.h"
#include "program.h"

void program_loaddata()
{
	fl_init();
	fl_waiting();
	floppy_iffl_fast_load_init("DATA");
	floppy_iffl_fast_load(); // chars
	floppy_iffl_fast_load(); // pal
	floppy_iffl_fast_load(); // heightmap
	floppy_iffl_fast_load(); // song
}

void program_init()
{
	VIC2.BORDERCOL = 0x00;
	VIC2.SCREENCOL = 0x00;
	modplay_init();
	modplay_initmod(ATTICADDRESS, SAMPLEADRESS);
	modplay_enable();

	dma_runjob((__far char *)&dma_clearcolorram1);
	dma_runjob((__far char *)&dma_clearcolorram2);
	dma_runjob((__far char *)&dma_clearscreen1);
	dma_runjob((__far char *)&dma_clearscreen2);
	dma_runjob((__far char *)&dma_copypalette);

	uint16_t i = (GFXMEM / 64);
	for(uint16_t x=0; x<40; x++)
	{
		for(uint16_t y=0; y<25; y++)
		{
			poke(SCREEN+y*RRBSCREENWIDTH2+2*x+0, (i >> 0) & 0xff);
			poke(SCREEN+y*RRBSCREENWIDTH2+2*x+1, (i >> 8) & 0xff);
			i++;
		}
	}

	// fill column tables
	for(uint16_t y=0; y<32; y++)
	{
		for(uint16_t x=0; x<8; x++)
		{
			poke(&columnlo+y*8+x, ((y*25*64 + x) >> 0) & 0xff);
			poke(&columnhi+y*8+x, ((y*25*64 + x) >> 8) & 0xff);
		}
	}
}
