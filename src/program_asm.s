		.rtmodel cpu, "*"
	
		.extern _Zp

 ; -----------------------------------------------------------------------------------------------

		.public program_mainloop
program_mainloop:
			lda 0xd020
			lda 0xd020
			lda 0xd020
			lda 0xd020
			jmp program_mainloop

 ; -----------------------------------------------------------------------------------------------

			.public program_testdmalines
program_testdmalines:

			lda #0
			sta dmasadr+0
			sta dmasadr+1

			lda #0
			sta dmadadr+0
			sta dmadadr+1

			ldx #0x00
dmaloop:	sta 0xd707						; inline DMA
			.byte 0x80, 0x00				; sourceMB
			.byte 0x81, 0x00				; destMB
			.byte 0x82, 0					; Source skip rate (256ths of bytes)
			.byte 0x83, 1					; Source skip rate (whole bytes)
			.byte 0x84, 0					; Destination skip rate (256ths of bytes)
			.byte 0x85, 8					; Destination skip rate (whole bytes) skip 8 bytes to get to next vertical pixel
			.byte 0x00						; end of job options
			.byte 0x00						; copy
			.word 128						; count
dmasadr:	.word 0x0000					; src
			.byte 0x02						; src bank and flags
dmadadr:	.word 0x0000					; dst
			.byte 0x01						; dst bank and flags
			.byte 0x00						; cmd hi
			.word 0x0000					; modulo, ignored

			clc
			lda dmasadr+0
			adc #0x08
			sta dmasadr+0
			lda dmasadr+1
			adc #0
			sta dmasadr+1
			
			clc
			lda dmadadr+0
			adc #01
			sta dmadadr+0

			inx
			cpx #0x08
			bne dmaloop

			rts
