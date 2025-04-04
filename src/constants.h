#ifndef __CONSTANTS_H
#define __CONSTANTS_H

#define SCREEN					0xa000
#define RRBSCREENWIDTH			80
#define RRBSCREENWIDTH2			(2*RRBSCREENWIDTH)

#define PALETTE					0xc000

#define GFXMEM					0x10000
#define BKGMEM                  0x18000
#define HEIGHTMAP				0x20000
#define COLORMAP				0x30000

#define HEIGHTLINES				0x08000
#define COLORLINES				0x08100

#define COLOR_RAM				0xff80000
#define COLOR_RAM_OFFSET		0x0800
#define SAFE_COLOR_RAM			(COLOR_RAM + COLOR_RAM_OFFSET)
#define SAFE_COLOR_RAM_IN1MB	(SAFE_COLOR_RAM - $ff00000)	

#define MAPPEDCOLOURMEM			0x08000

#define SAMPLEADRESS			(0x40000)

#define ATTICADDRESS			0x08000000

#endif
