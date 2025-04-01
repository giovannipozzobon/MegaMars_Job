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

copyheightlineA:

			; copy from heightmap, line X
			sta dmachlsrc+1					

			sta 0xd707						; inline DMA
			.byte 0x80, 0x00				; sourceMB
			.byte 0x81, 0x00				; destMB
			.byte 0x82, 0					; Source skip rate (256ths of bytes)
			.byte 0x83, 1					; Source skip rate (whole bytes)
			.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 1					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x00						; copy
			.word 128						; count
dmachlsrc:	.word 0x0000					; src
			.byte (HEIGHTMAP>>16)			; src bank and flags
			.word HEIGHTLINES				; dst
			.byte 0x00						; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

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

			lda #0							; put basepage back to zeropage
			tab

			rts

 ; -----------------------------------------------------------------------------------------------

renderheightline:

			lda #0							; initialize MULTiply registers
			sta 0xd770
			sta 0xd771
			sta 0xd772
			sta 0xd773
			sta 0xd774
			sta 0xd775
			sta 0xd776
			sta 0xd777

			lda #8							; get ready to multiply by 8
			sta 0xd771

			ldy #0

rhlloop:
			lda HEIGHTLINES,y				; get height
			sta getpixel+0
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
			.word 4							; count
getpixel:	.word 0x00fe					; fill value
			.byte 0x00						; src bank and flags
putpixel:	.word 0x0000					; dst
			.byte ((GFXMEM>>16) & 0x0f)		; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			iny
			cpy #128
			bne rhlloop

			rts

 ; -----------------------------------------------------------------------------------------------

			.public program_testdmalines
program_testdmalines:

			lda #0
			sta 0xd020

			inc frame

			lda #0							; initialize MULTiply registers
			sta 0xd770
			sta 0xd771
			sta 0xd772
			sta 0xd773
			sta 0xd774
			sta 0xd775
			sta 0xd776
			sta 0xd777

;			lda #0
;			sta dmadst+0
;			sta dmadst+1

			ldx #0

renderloop:
			clc
			lda 0xd020
			adc #0x10
			sta 0xd020

			lda frame
			jsr copyheightlineA
			ldy #100						; set base to this
			lda #64							; scale heightline by this
			sta 0xd770						; MULTINA
			jsr scaleheightline

			jsr renderheightline

			inx
			cpx #1
			bne renderloop

			lda #0
			sta 0xd020

			rts

 ; -----------------------------------------------------------------------------------------------

			.align 256
			.public columnlo
columnlo:	.space 256
			.public columnhi
columnhi:	.space 256

; -----------------------------------------------------------------------------------------------
