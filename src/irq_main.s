#include "constants.h"

			.rtmodel cpu, "*"

			.extern _Zp

			.extern modplay_play
			.extern program_rendervoxels
			.extern keyboard_update
			.extern program_update
			.extern program_state

 ; ------------------------------------------------------------------------------------

			.public clearscreen
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

			.public irq_main
irq_main:
			php
			pha
			phx
			phy
			phz

			lda #0xff
			sta 0xd020
			sta 0xd021

			lda program_state
			bne skipupdates

			jsr clearscreen
			jsr program_rendervoxels
			jsr keyboard_update

skipupdates:
			;lda #0xfe
			;sta 0xd020
			;sta 0xd021

			jsr program_update
			jsr modplay_play

			;lda #0x00
			;sta 0xd020
			;sta 0xd021

			;lda #0x32
			;sta 0xd012
			;lda #.byte0 irq_main
			;sta 0xfffe
			;lda #.byte1 irq_main
			;sta 0xffff

			plz
			ply
			plx
			pla
			plp
			asl 0xd019
			rti

; ------------------------------------------------------------------------------------
