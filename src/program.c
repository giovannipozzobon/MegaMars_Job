#include <stdint.h>
#include "macros.h"
#include "registers.h"
#include "constants.h"
#include "keyboard.h"
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
	floppy_iffl_fast_load(); // colourmap
	floppy_iffl_fast_load(); // song
}

void program_init()
{
	VIC2.BORDERCOL = 0x00;
	VIC2.SCREENCOL = 0x00;

	VIC2.DEN = 0;

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

	uint16_t dz = 16;
	uint16_t z = 128;

	uint16_t numlines = 34;
	uint16_t scaleheight = 255; // no bigger than 255!
	uint16_t height = 200;
	uint16_t width = 255;
	uint16_t horizon = 0;
	uint16_t heightscale = 60; // no bigger than 64 otherwise it goes down again!

	uint8_t line = 0;
	while(line < numlines)
	{
		uint8_t index = numlines-line-1;

		uint16_t oneoverz = 65535/z;
		uint16_t basescale = (height * oneoverz)>>8;

		poke(0xc800+index, basescale);

		poke(&perspbaseheight+index, horizon+basescale);
		poke(&perspheight+index,     (heightscale*oneoverz)>>7);
		poke(&perspscalelo+index,    ((40+z>>2) >> 0) & 0xff);
		poke(&perspscalehi+index,    ((40+z>>2) >> 8) & 0xff);
		poke(&perspxoffs+index,		 2*numlines-line /*fovscale>>2*/);

		z += dz;
		dz += 0; // distance 'stretch' DON'T TOUCH, THIS IS RIGHT!!!

		line++;
	}

	VIC2.DEN = 1;
}

void program_update()
{
	if(keyboard_keypressed(KEYBOARD_CURSORRIGHT))
	{
		xoffset++;
	}
	else if(keyboard_keypressed(KEYBOARD_CURSORLEFT))
	{
		xoffset--;
	}
}