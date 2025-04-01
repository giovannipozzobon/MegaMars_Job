#include "constants.h"

			.rtmodel cpu, "*"
			.extern _Zp

frame		.byte 0

multheight:		.macro a
				lda zp:\a					; get height
				sta 0xd774					; put in MULTINB
				tya
				sbc 0xd779					; add base height
				sta zp:\a					; put height
				.endm

multheight8:	.macro a
				multheight \a*8+0
				multheight \a*8+1
				multheight \a*8+2
				multheight \a*8+3
				multheight \a*8+4
				multheight \a*8+5
				multheight \a*8+6
				multheight \a*8+7
				.endm

 ; -----------------------------------------------------------------------------------------------

		.public program_mainloop
program_mainloop:
			lda 0xd020
			lda 0xd020
			lda 0xd020
			lda 0xd020
			jmp program_mainloop

; -----------------------------------------------------------------------------------------------

clearscreen:

			sta 0xd707						; inline DMA
			.byte 0x80, 0x00				; sourceMB
			.byte 0x81, 0x00				; destMB
			.byte 0x82, 0					; Source skip rate (256ths of bytes)
			.byte 0x83, 1					; Source skip rate (whole bytes)
			.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 1					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x03						; fill, no chain
			.word 160*200					; count
			.word 0x00fe					; fill value
			.byte 0x00						; src bank and flags
			.word 0x0000					; dst
			.byte ((GFXMEM>>16) & 0x0f)		; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			rts

; -----------------------------------------------------------------------------------------------


copyhgtcolsourceline:

			; copy from heightmap/colormap, line X
			sta dmachlsrc1+1
			sta dmachlsrc2+1

			sta 0xd707						; inline DMA
			.byte 0x80, 0x00				; sourceMB
			.byte 0x81, 0x00				; destMB
linescalelo1:.byte 0x82, 0					; Source skip rate (256ths of bytes)
linescalehi1:.byte 0x83, 1					; Source skip rate (whole bytes)
			.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 1					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x00						; copy
			.word 160						; count
dmachlsrc1:	.word 0x0000					; src
			.byte (HEIGHTMAP>>16)			; src bank and flags
			.word HEIGHTLINES				; dst
			.byte 0x00						; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			sta 0xd707						; inline DMA
			.byte 0x80, 0x00				; sourceMB
			.byte 0x81, 0x00				; destMB
linescalelo2:.byte 0x82, 0					; Source skip rate (256ths of bytes)
linescalehi2:.byte 0x83, 1					; Source skip rate (whole bytes)
			.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 1					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x00						; copy
			.word 160						; count
dmachlsrc2:	.word 0x0000					; src
			.byte (COLORMAP>>16)			; src bank and flags
			.word COLORLINES				; dst
			.byte 0x00						; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			rts

; -----------------------------------------------------------------------------------------------

initializemultregs:

			lda #0							; initialize MULTiply registers
			sta 0xd770
			sta 0xd771
			sta 0xd772
			sta 0xd773
			sta 0xd774
			sta 0xd775
			sta 0xd776
			sta 0xd777
			rts

; -----------------------------------------------------------------------------------------------

scaleheightline:

			lda #.byte1 HEIGHTLINES			; set basepage to where the heightlines are
			tab

			sec
			multheight8 0
			multheight8 1
			multheight8 2
			multheight8 3
			multheight8 4
			multheight8 5
			multheight8 6
			multheight8 7
			multheight8 8
			multheight8 9
			multheight8 10
			multheight8 11
			multheight8 12
			multheight8 13
			multheight8 14
			multheight8 15
			multheight8 16
			multheight8 17
			multheight8 18
			multheight8 19

			lda #0							; put basepage back to zeropage
			tab

			rts

 ; -----------------------------------------------------------------------------------------------

renderheightline:

			jsr initializemultregs
			lda #8							; get ready to multiply by 8
			sta 0xd771

			inc getpixel+0

			ldy #0

rhlloop:
			lda COLORLINES+0,y				; get colour
			sta getpixel+0
			lda HEIGHTLINES,y				; get height
			sta 0xd774
			clc
			lda 0xd779
			adc columnlo,y
			sta putpixel+0
			lda 0xd77a
			adc columnhi,y
			sta putpixel+1

			sta 0xd707						; inline DMA
			.byte 0x80, 0x00				; sourceMB
			.byte 0x81, 0x00				; destMB
			.byte 0x82, 0					; Source skip rate (256ths of bytes)
			.byte 0x83, 1					; Source skip rate (whole bytes)
			.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 8					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x03						; fill, no chain
			.word 32						; count
getpixel:	.word 0x00fe					; fill value
			.byte 0x00						; src bank and flags
putpixel:	.word 0x0000					; dst
			.byte ((GFXMEM>>16) & 0x0f)		; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			iny
			cpy #160
			bne rhlloop

			rts

 ; -----------------------------------------------------------------------------------------------

			.public program_testdmalines
program_testdmalines:

			lda #0
			sta 0xd020

			jsr clearscreen

			dec frame

			ldx #0

renderloop:
			clc
			lda 0xd020
			adc #0x10
			sta 0xd020

			lda perspscalelo,x
			sta linescalelo1+1
			sta linescalelo2+1
			lda perspscalehi,x
			sta linescalelo1+2
			sta linescalelo2+2
			clc
			txa									; get current line
			adc frame							; add offset based on frame number
			jsr copyhgtcolsourceline

			jsr initializemultregs
			lda perspbaseheight,x				; set base to this
			tay
			lda perspheight,x					; scale heightline by this
			sta 0xd770							; MULTINA
			jsr scaleheightline

			jsr renderheightline

			inx
			cpx #20
			bne renderloop

			lda #0
			sta 0xd020

			rts

 ; -----------------------------------------------------------------------------------------------

			.align 256
			.public perspbaseheight
perspbaseheight:
			.space 32

			.public perspheight
perspheight:
			.space 32

			.public perspscalelo
perspscalelo:
			.space 32

			.public perspscalehi
perspscalehi:
			.space 32

 ; -----------------------------------------------------------------------------------------------

			.align 256
			.public columnlo
columnlo:	.space 256
			.public columnhi
columnhi:	.space 256

; -----------------------------------------------------------------------------------------------
