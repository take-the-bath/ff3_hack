; ff3_experimental.asm
;
;	experimental code
;
;	to invoke,push [select] button in command-window
;	code must reurn to 'returnAddress'
;======================================================================================================
ff3_experimental_begin:
EXPERIMENT_IMPL = 4
;3 = measure draw8linewindow performance
;4 = SE test
;------------------------------------------------------------------------------------------------------
	.bank	$68acf >> 13
	.org	($8000 + ($68acf & $7fff)) + ($02 * 2)
	commandWindowInputHandlers_02:
		.dw commandWindow_OnSelect	;original: $8abe
;-----------------------------------------------------------------------------------------------------
	.bank	BANK(ff3_experimental_begin)
	.org	ff3_experimental_begin
commandWindow_OnSelect:
;------------------------------------------------------------------------------------------------------
	.IF EXPERIMENT_IMPL = 1
	;tests draw window
	experiment_00:
	.width = $14
	.startOffset = $08
	.endOffset = .startOffset + (.width + 1)
	.border = %00000011
		jsr initTileArrayStorage
		
		;ldx #.width
		;jsr initString
		
		ldx #$ff
	.loadstr:
		inx
		lda .text,x
		sta stringCache+1,x
		bne .loadstr
		
		lda #.width
		sta <$18
		jsr strToTileArray
		
		lda #.startOffset
		sta <$18
		lda #.endOffset
		sta <$19
		lda #.border
		sta <$1a
		jsr draw8LineWindow
		
	.hit_a_button:
		jsr getPad1Input
		lda <inputBits
		lsr a
		bcc .hit_a_button
			
		jmp returnAddress
	.text:
		.db $2f,$7c,$92,$b6,$af,$8c,$ff,$cc,$b8,$f6,$51,$cc,$ff,$01,$cd,$c2,$56,$d9,$f6,$36,$ff,$9d,$90,$a3,$9e,$9b,$00
	.ENDIF	;EXPERIMENT_IMPL
	.IF EXPERIMENT_IMPL = 2
	;forces select command0a
	experiment_01:
		jsr setYtoOffset2E
		dey
		dey
		lda [pPlayer],y	; index and flags (+2c)
		and #$e7
		sta [pPlayer],y
		iny
		iny
		lda #$0a		;
		sta [pPlayer],y	;action id (+2e)
		ldx <iPlayer
		sta selectedAction,x
		iny
		lda #$ff
		sta [pPlayer],y	;target (+2f)
		iny
		lda #$c0	;enemy|all
		sta [pPlayer],y	;target flag (+30)
		inc <iPlayer
		;jmp returnAddress
	.ENDIF	;EXPERIMENT_IMPL
	.IF EXPERIMENT_IMPL = 3
nmi_counter16 = $0106
.dest = $0108
		;lda #40
		;sta .dest	;'rti'
		ldx #nmi_handler_hook_end - nmi_handler_hook
		dex
	.copy_handler_code:
			lda nmi_handler_hook,x
			sta .dest,x
			dex
		bpl .copy_handler_code	
		;init counter
		inx
		stx nmi_counter16
		stx nmi_counter16+1
		;replace handle ptr
		jsr waitNmi
		lda #LOW(.dest)
		sta pNmiHandler
		lda #HIGH(.dest)
		sta pNmiHandler + 1
		;ready
		jsr testStr
		jmp returnAddress
	nmi_handler_hook:
		pha
		clc
		lda nmi_counter16
		adc #1
		sta nmi_counter16
		lda nmi_counter16+1
		adc #0
		sta nmi_counter16+1
		pla
		jmp $fb57	;default nmi
	nmi_handler_hook_end:
	
	testStr:
	;	loadTileArrayForItemWindowColumn();//$35:b48b
	;	draw8LineWindow(left:$18 = #0, right:$19 = #1f, behavior:$1a = #3); //$34:8b38
		.IF 0
			jsr loadTileArrayForItemWindowColumn
		.ENDIF	
		.IF 1	;check how many nmi is required to draw8linewindow
			lda #$0
			sta <$18
			lda #$1f
			sta <$19
			lda #3
			sta <$1a
			jsr draw8LineWindow
			lda nmi_counter16
			sta <$18
			lda nmi_counter16+1
			sta <$19
		.ENDIF
		.IF 0	;check speed of ram read
			lda #0
			tay
			tax
			lda nmi_counter16
			adc #5
			
		.count:
			inx
			bne .next
			iny
		.next:	
			cmp nmi_counter16
			bne .count
			stx <$18
			sty <$19
		.ENDIF
		.IF 0	;check speed of vram read
			lda #0
			tax
			sta <$19
			lda nmi_counter16
			adc #1
			tay
		.count:
			lda $2007	;read vram
			inx
			bne .next
			inc <$19
		.next:	
			cpy nmi_counter16
			bne .count
			stx <$18
		.ENDIF		
		ldx #8
		jsr initString
		jsr itoa_16
		ldx #5
	.copy_countstr:
		lda <$1a,x
		sta $7ad7+1,x
		dex
		bpl .copy_countstr

		jsr initTileArrayStorage
		lda #8
		sta <$18
		jsr strToTileArray
		lda #3
		jsr draw1LineWindow	;draw1RowWindow(a = #3); //$34:8d1b();
.wait_a:
			jsr getPad1Input
			and #1
			beq .wait_a
		rts
	.ENDIF	;EXPERIMENT_IMPL = 3
	.IF EXPERIMENT_IMPL = 4
		lda #0	
		pha
		
	.show_current_id:	
		ldx #8
		jsr initString
		jsr initTileArrayStorage
		pla
		pha
		jsr itoa_8
		ldx #2
	.copy_number:	
			lda $1a,x
			sta stringCache+4,x
			dex
			bpl .copy_number
		lda #8
		sta <$18
		jsr strToTileArray
		lda #3
		jsr draw1LineWindow	
	.input_handler:
			jsr getPad1Input
			;lda <inputBits
			lsr a
			bcs .OnA
			lsr a
			bcs .OnB
			lsr a
			lsr a
			lsr a
			bcs .OnUp
			lsr a
			bcs .OnDown
			lsr a
			bcs .OnLeft
			lsr a
			bcc .input_handler
		.OnRight:
			pla
			clc
			adc #10
			pha
			jmp .show_current_id
		.OnUp:
			pla
			clc
			adc #1
			pha
			jmp .show_current_id
		.OnLeft:
			pla
			sec
			sbc #10
			pha
			jmp .show_current_id
		.OnDown:
			pla
			sec
			sbc #1
			pha
			jmp .show_current_id
		.OnA:
			pla
			sta <soundEffectId
			inc <playSoundEffect
			pha	
			lda #0
			.wait_play_end:
				cmp <playSoundEffect
				bne .wait_play_end
			jmp .input_handler
		.OnB:
			pla
			jmp returnAddress
	.ENDIF
endExperiment:
	pla	;ret addr
	jmp getCommandInput_next	
returnAddress = endExperiment