#include "constants.h"

			.rtmodel cpu, "*"
			.extern _Zp

			.extern program_loadmap0
			.extern program_loadmap1

frame		.byte 0

			.public xoffset
xoffset		.byte 0

			.public program_state
program_state
			.byte 0

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
			lda program_state
			beq program_mainloop
			cmp #1
			bne pml2
			jsr program_loadmap0
			jmp program_mainloop
pml2:		cmp #2
			bne pml3
			jsr program_loadmap1
			jmp program_mainloop
pml3:		jmp program_mainloop

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
			.byte 0x00						; copy, no chain
			.word 160*200					; count
			.word ((BKGMEM>>0) & 0xffff)	; fill value
			.byte ((BKGMEM>>16) & 0x0f)		; src bank and flags
			.word 0x0000					; dst
			.byte ((GFXMEM>>16) & 0x0f)		; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			rts

; -----------------------------------------------------------------------------------------------


copyhgtcolsourceline:

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
			multheight8 19					; 20*8=160

			lda #0							; put basepage back to zeropage
			tab

			rts

 ; -----------------------------------------------------------------------------------------------

renderfinalheightline:

			jsr initializemultregs
			lda #8							; get ready to multiply by 8
			sta 0xd771

			clc
			ldy #0
rfhlloop:	lda COLORLINES+0,y				; get colour
			sta getfpixel+0
			lda HEIGHTLINES,y				; get height
			cmp #200
			bcs skipfdraw

			sta 0xd774						; multiply by 8
			clc
			lda 0xd779
			adc columnlo,y
			sta putfpixel+0
			lda 0xd77a
			adc columnhi,y
			sta putfpixel+1

			sec
			lda #200
			sbc HEIGHTLINES,y
			sta drawfheight

			sta 0xd707						; inline DMA
			;.byte 0x80, 0x00				; sourceMB
			;.byte 0x81, 0x00				; destMB
			;.byte 0x82, 0					; Source skip rate (256ths of bytes)
			;.byte 0x83, 1					; Source skip rate (whole bytes)
			;.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 8					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x03						; fill, no chain
drawfheight:.word 1							; count
getfpixel:	.word 0x00fe					; fill value
			.byte 0x00						; src bank and flags
putfpixel:	.word 0x0000					; dst
			.byte ((GFXMEM>>16) & 0x0f)		; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

skipfdraw:	iny
			cpy #160
			bne rfhlloop

			rts

 ; -----------------------------------------------------------------------------------------------

renderheightline:

			jsr initializemultregs
			lda #8							; get ready to multiply by 8
			sta 0xd771

			clc
			ldy #0
rhlloop:	lda COLORLINES+0,y				; get colour
			sta getpixel+0
			lda HEIGHTLINES,y				; get height
			sta 0xd774						; multiply by 8
			;clc
			lda 0xd779
			adc columnlo,y
			sta putpixel+0
			lda 0xd77a
			adc columnhi,y
			sta putpixel+1

			sta 0xd707						; inline DMA
			;.byte 0x80, 0x00				; sourceMB
			;.byte 0x81, 0x00				; destMB
			;.byte 0x82, 0					; Source skip rate (256ths of bytes)
			;.byte 0x83, 1					; Source skip rate (whole bytes)
			;.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 8					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x03						; fill, no chain
drawheight:	.word 8							; count
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

			;lda #0x0c
			;sta 0xd020

			jsr clearscreen

			dec frame

			ldx #0

renderloop:
			;lda #0xfe
			;sta 0xd020

			lda perspscalelo,x
			sta linescalelo1+1
			sta linescalelo2+1
			lda perspscalehi,x
			sta linescalehi1+1
			sta linescalehi2+1
			clc
			ldy frame
			;lda sine,y
			;lsr a
			;lsr a
			lda xoffset
			adc perspxoffs,x
			sta dmachlsrc1+0
			sta dmachlsrc2+0
			clc
			txa									; get current line
			adc frame							; add y offset based on frame number
			sta dmachlsrc1+1
			sta dmachlsrc2+1
			jsr copyhgtcolsourceline

			;lda #0xfd
			;sta 0xd020

			jsr initializemultregs
			lda perspbaseheight,x				; set base to this
			tay
			lda perspheight,x					; scale heightline by this
			sta 0xd770							; MULTINA
			jsr scaleheightline

			;lda #0xfb
			;sta 0xd020

			txa
			adc #0x0c
			;lda #0x04
			sta drawheight

			jsr renderheightline

			;lda #0xfe
			;sta 0xd020

			inx
			cpx #30-1
			bne renderloop

			jsr renderfinalheightline

			;lda #0
			;sta 0xd020

			rts

 ; -----------------------------------------------------------------------------------------------

			.align 256
			.public perspbaseheight
perspbaseheight:
			.space 64

			.public perspheight
perspheight:
			.space 64

			.public perspscalelo
perspscalelo:
			.space 64

			.public perspscalehi
perspscalehi:
			.space 64

			.public perspxoffs
perspxoffs
			.space 64

 ; -----------------------------------------------------------------------------------------------

			.align 256
			.public columnlo
columnlo:	.space 256
			.public columnhi
columnhi:	.space 256

; -----------------------------------------------------------------------------------------------

sine:
    .byte  128, 131, 134, 137, 140, 143, 146, 149, 152, 156, 159, 162, 165, 168, 171, 174
    .byte  176, 179, 182, 185, 188, 191, 193, 196, 199, 201, 204, 206, 209, 211, 213, 216
    .byte  218, 220, 222, 224, 226, 228, 230, 232, 234, 236, 237, 239, 240, 242, 243, 245
    .byte  246, 247, 248, 249, 250, 251, 252, 252, 253, 254, 254, 255, 255, 255, 255, 255
    .byte  255, 255, 255, 255, 255, 255, 254, 254, 253, 252, 252, 251, 250, 249, 248, 247
    .byte  246, 245, 243, 242, 240, 239, 237, 236, 234, 232, 230, 228, 226, 224, 222, 220
    .byte  218, 216, 213, 211, 209, 206, 204, 201, 199, 196, 193, 191, 188, 185, 182, 179
    .byte  176, 174, 171, 168, 165, 162, 159, 156, 152, 149, 146, 143, 140, 137, 134, 131
    .byte  128, 124, 121, 118, 115, 112, 109, 106, 103,  99,  96,  93,  90,  87,  84,  81
    .byte   79,  76,  73,  70,  67,  64,  62,  59,  56,  54,  51,  49,  46,  44,  42,  39
    .byte   37,  35,  33,  31,  29,  27,  25,  23,  21,  19,  18,  16,  15,  13,  12,  10
    .byte    9,   8,   7,   6,   5,   4,   3,   3,   2,   1,   1,   0,   0,   0,   0,   0
    .byte    0,   0,   0,   0,   0,   0,   1,   1,   2,   3,   3,   4,   5,   6,   7,   8
    .byte    9,  10,  12,  13,  15,  16,  18,  19,  21,  23,  25,  27,  29,  31,  33,  35
    .byte   37,  39,  42,  44,  46,  49,  51,  54,  56,  59,  62,  64,  67,  70,  73,  76
    .byte   79,  81,  84,  87,  90,  93,  96,  99, 103, 106, 109, 112, 115, 118, 121, 124
