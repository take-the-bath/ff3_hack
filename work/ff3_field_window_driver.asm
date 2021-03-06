; encoding: utf-8
; ff3_field_window_driver.asm
;
; description:
;	replaces field::draw_window_box($3f:ed02) related codes.
;	this file implements 'driver'-like logics,
;	which drives underlying functions to show up windows on screen.
;	these logics are originally placed around $3f:eb2d - $3f:eefa.
;
; version:
;	0.2.0
;==================================================================================================
ff3_field_window_driver_begin:
;--------------------------------------------------------------------------------------------------
	.ifdef _OPTIMIZE_FIELD_WINDOW
	INIT_PATCH_EX field.window.driver, $3f, $eb2d, $eefa, $eb2d

;------------------------------------------------------------------------------------------------------
;;$3f:ecfa field::draw_in_place_window
;;	typically called when object's message is to be shown
;;callers:
;;	$3f:ec8d field::show_window (original implementation only)
;;	$3f:ec83 field::show_message_UNKNOWN
field.draw_inplace_window:
;; patch out external callers {
;;}
	DECLARE_WINDOW_VARIABLES
;.window_id = $96
	sta <.window_type
	lda #0
	sta <.a_button_down	;<$24
	sta <.b_button_down ;<$25
	;;originally fall through to $3f:ed02 field::draw_window_box
	FALL_THROUGH_TO field.draw_window_box

	;VERIFY_PC $ed02
;------------------------------------------------------------------------------------------------------
;;$3f:ed02 field::draw_window_box
;;	This logic plays key role in drawing window, both for menu windows and in-place windows.
;;	Usually window drawing is performed as follows:
;;	1)	Call this logic to fill in background with window parts
;;		and setup BG attributes if necessary (the in-palce window case).
;;		In cases of the menu window, BG attributes have alreday been setup in another logic
;;		and should not be changed.
;;	2)	Subsequently call other drawing logics which overwrites background with
;;		content (aka string) in the window, 2 consecutive window rows,
;;		which is equivalent to 1 text line, per 1 frame.
;;		These logics rely on window metrics variables, which is initially setup on this logic,
;;		and they don't change BG attributes anyway.
;;NOTEs:
;;	in the scope of this logic, it is safe to use the address range $0780-$07ff (inclusive) in a destructive way.
;;	The original code uses this area as temporary buffer for rendering purporses
;;	and discards its contents on exit.
;;	more specifically, address are utilized as follows:
;;		$0780-$07bf: used for PPU name table buffer,
;;		$07c0-$07cf: used for PPU attr table buffer,
;;		$07d0-$07ff: used for 3-tuple of array that in each entry defines
;;			(vram address(high&low), value to tranfer)
;;callers:
;;	1E:8EFD:20 02 ED  JSR field::draw_window_box	@ $3c:8ef5 ?; window_type = 0
;;	1E:8F0E:20 02 ED  JSR field::draw_window_box	@ $3c:8f04 ?; window_type = 1
;;	1E:8FD5:20 02 ED  JSR field::draw_window_box	@ $3c:8fd1 ?; window_type = 3
;;	1E:90B1:20 02 ED  JSR field::draw_window_box	@ $3c:90ad ?; window_type = 2
;;	1E:AAF4:4C 02 ED  JMP field::draw_window_box	@ $3d:aaf1 field::draw_menu_window_box
;;	(by falling through) @$3f:ecfa field::draw_in_place_window
field.draw_window_box:	;;$ed02
;; patch out external callers {
	FIX_ADDR_ON_CALLER $3c,$8efd+1
	FIX_ADDR_ON_CALLER $3c,$8f0e+1
	FIX_ADDR_ON_CALLER $3c,$8fd5+1
	FIX_ADDR_ON_CALLER $3c,$90b1+1
	FIX_ADDR_ON_CALLER $3d,$aaf4+1
;;}
;;[in]
.window_type = $96
	ldx <.window_type
	jsr field.get_window_region	;$ed61

field_x.draw_window_box_with_region:
	DECLARE_WINDOW_VARIABLES
;; ---
	.ifdef _FEATURE_DEFERRED_RENDERING
		jsr field_x.shrink_window_metrics
	;; notes:
	;;	initializing renderer here will interfere with `menu.erase_box_from_bottom`
	;;	and may result in glitches on screen or even worse, crashing the game.
	;;	it is necessary to tell the renderer to draw border in somewhere before rendering,
	;;	but doing it here is not reliable as it can't be assumed that
	;; 	rendering of a box and its contents is always tightly coupled.
	;;	there exists cases out-of-order execution of the following:
	;;		1. render a box
	;;		2. erase a box (possibly not the same as #1)
	;;		3. render contents in a box (possibly not the same as #1)
	;;	thus, it is deliberately chosen not to make the init here.
		jsr field_x.begin_ppu_update
		jsr field_x.end_ppu_update
		jmp field.restore_banks	;$ecf5
	.else	;;_FEATURE_DEFERRED_RENDERING
		lda <.window_top                    ; ED07 A5 39
		sta <.offset_y                      ; ED09 85 3B
		jsr field.calc_draw_width_and_init_window_tile_buffer; ED0B 20 70 F6
		jsr field.init_window_attr_buffer   ; ED0E 20 56 ED
		lda <.window_height                 ; ED11 A5 3D
		sec                                 ; ED13 38
		sbc #$02                            ; ED14 E9 02
		pha                                 ; ED16 48
		jsr field.get_window_top_tiles      ; ED17 20 F6 ED
		jsr field.draw_window_row           ; ED1A 20 C6 ED
		pla                                 ; ED1D 68
		sec                                 ; ED1E 38
		sbc #$02                            ; ED1F E9 02
		beq .render_bottom                  ; ED21 F0 18
		bcs .render_body                    ; ED23 B0 05
		dec <.offset_y                      ; ED25 C6 3B
		jmp .render_bottom                  ; ED27 4C 3B ED
	.render_body:
		pha                                 ; ED2A 48
		jsr field.get_window_middle_tiles   ; ED2B 20 1D EE
		jsr field.draw_window_row           ; ED2E 20 C6 ED
		pla                                 ; ED31 68
		sec                                 ; ED32 38
		sbc #$02                            ; ED33 E9 02
		beq .render_bottom                  ; ED35 F0 04
		bcs .render_body                    ; ED37 B0 F1
		dec <.offset_y                      ; ED39 C6 3B
	.render_bottom:
		jsr field.get_window_bottom_tiles   ; ED3B 20 3E EE
		jsr field.draw_window_row           ; ED3E 20 C6 ED
		inc <.window_left                   ; ED41 E6 38
		inc <.window_top                    ; ED43 E6 39
		lda <.window_width                  ; ED45 A5 3C
		sec                                 ; ED47 38
		sbc #$02                            ; ED48 E9 02
		sta <.window_width                  ; ED4A 85 3C
		lda <.window_height                 ; ED4C A5 3D
		sec                                 ; ED4E 38
		sbc #$02                            ; ED4F E9 02
		sta <.window_height                 ; ED51 85 3D
		jmp field.restore_banks             ; ED53 4C F5 EC
	.endif	;;_FEATURE_DEFERRED_RENDERING

	;VERIFY_PC $ed56
;--------------------------------------------------------------------------------------------------
	;INIT_PATCH $3f,$edc6,$ede1
	.ifndef _FEATURE_DEFERRED_RENDERING
field.draw_window_row:	;;$3f:edc6 field::draw_window_row
;;callers:
;;	$3f:ece5 field::draw_window_top
;;	$3f:ed02 field::draw_window_box (only the original implementation)
	DECLARE_WINDOW_VARIABLES
	lda <.window_width
	sta <.output_index
	jsr field.update_window_attr_buff	;$c98f
	jsr field_x.begin_ppu_update
	jsr field.upload_window_content		;$f6aa
	jsr field.set_bg_attr_for_window	;$c9a9
	;;fall through.
	.endif	;;_FEATURE_DEFERRED_RENDERING
;--------------------------------------------------------------------------------------------------
field_x.end_ppu_update:
	jsr field.sync_ppu_scroll	;$ede1
	jmp field.call_sound_driver	;$c750

field_x.begin_ppu_update:
	jsr waitNmiBySetHandler	;$ff00
	jmp ppud.do_sprite_dma
	;VERIFY_PC $ede1
;--------------------------------------------------------------------------------------------------
;;# $3f:eb2d field.scrolldown_item_window
;;
;;## args:
;;+	[in,out] ptr $1c: pointer to text
;;+	[in,out] ptr $3e: pointer to text
;;+	[in] u8 $93: bank number of the text
;;+	[in] u8 $a3: ?
;;+	[out] u8 $b4: ? (= 0x40(if aborted) or 0xC0(if scrolled))
;;+	[in,out] u16 ($79f0,$79f2): ?
;;+	[out] bool carry: 1: scroll aborted, 0: otherwise
;;## callers:
;;+	`1E:9255:20 2D EB  JSR field.scrolldown_item_window` @ 
field.scrolldown_item_window:	;;$3f:eb2d
;; fixups
	FIX_ADDR_ON_CALLER $3c,$9255+1	;;@ $3c:920d menu.window3.get_input_and_scroll
;; ---
;.text_bank = $93
.p_text = $1c
.p_text_end = $3e
	jsr field_x.switch_to_text_bank
	ldy #0
	lda [.p_text_end],y
	bne field.do_scrolldown_item_window
		lda #$40

	FALL_THROUGH_TO field.abort_item_window_scroll
;--------------------------------------------------------------------------------------------------
;;# $3f$eb3c field.abort_item_window_scroll
;;<details>
;;
;;## args:
;;+	[in] u8 $57: bank number to restore
;;+	[out] bool carry: always 1. (scroll aborted)
;;## callers:
;;+	`1F:EBA6:4C 3C EB  JMP field.abort_item_window_scroll` @ $3f$eb69 field.scrollup_item_window
;;## code:
field.abort_item_window_scroll:	;;$3f$eb3c
;; fixups
;; ---
	sta <$b4
	;sec	;;aborted scrolinng item window
field_x.restore_banks_with_carry_set:
	;php
	jsr field.restore_banks	;;note: here original implementation calls $ff03, not $ecf5
	;plp
	sec	;;aborted scrolinng item window
	rts

;--------------------------------------------------------------------------------------------------
;;# $3f$eb43 field.do_scrolldown_item_window
;;<details>
;;
;;## args:
;;+	[out] bool carry: always 0. (= scroll successful)
;;## callers:
;;+	`1F:EB36:D0 0B     BNE field.scrolldown_item_window` @ $3f$eb2d field.scrolldown_item_window
field.do_scrolldown_item_window:	;;$3f$eb43
	lda <$a3
	cmp #2
	bne .by_line
		;; ($79f0,$79f2) -= 8
		sec
		lda $79f0
		sbc #8
		sta $79f0
		bcs .low_byte_only
			dec $79f2
	.low_byte_only:
.by_line:
	jsr field.seek_text_to_next_line

field_x.reflect_item_window_scroll:
	lda #$c0
	sta <$b4
	FALL_THROUGH_TO field.reflect_window_scroll
;--------------------------------------------------------------------------------------------------
;;# $3f$eb61 field.reflect_window_scroll
;;
;;## args:
;;+	[in] u8 $57: bank number to restore
;;+	[out] bool carry: always 0. (= scroll successful)
;;## callers:
;;+	`1E:9F92:20 61 EB  JSR field.reflect_item_window_scro` @ $3c:9ec2 menu.items.main_loop
;;+	`1E:A889:4C 61 EB  JMP field.reflect_item_window_scro` @ $3d:a87a menu.draw_view_of_buffered_string
;;+	`1E:B436:20 61 EB  JSR field.reflect_item_window_scro`
;;+	`1E:B616:4C 61 EB  JMP field.reflect_item_window_scro`
;;+	`1E:B624:4C 61 EB  JMP field.reflect_item_window_scro`
;;+	`1E:BC0F:4C 61 EB  JMP field.reflect_item_window_scro`
;;+	`1F:EB9F:4C 61 EB  JMP field.reflect_item_window_scroll` @ $3f$eb69 field.scrollup_item_window
field_x.reflect_window_scroll_without_borders
	FIX_ADDR_ON_CALLER $3c,$9f92+1	;;@ $3c:9ec2 menu.items.main_loop
	.ifdef _FEATURE_DEFERRED_RENDERING
		;;note:
		;;	the item window could be rendered with border
		;;	and doing so does not impact the resulting contents.
		;;	however, borders takes extra 1f to render
		;;	and there are cases that borders cascaded
		;;	in different order than the original implementation would.
		;;	so here request to omit borders as a speed optimizaion.
		;;	this logic is called on both in menu mode and in floor (use item to object)
		jsr render_x.init_as_no_borders
	.endif
field.reflect_window_scroll:	;;$3f$eb61
;; fixups:
	;FIX_ADDR_ON_CALLER $3c,$9f92+1	;;@ $3c:9ec2 menu.items.main_loop
	FIX_ADDR_ON_CALLER $3d,$a889+1	;;@ $3d:a87a menu.draw_view_of_buffered_string
	FIX_ADDR_ON_CALLER $3d,$b436+1
	FIX_ADDR_ON_CALLER $3d,$b616+1
	FIX_ADDR_ON_CALLER $3d,$b624+1	;;shop, right after selected to sell item
	FIX_ADDR_ON_CALLER $3d,$bc0f+1
;; ---
	.ifdef _FEATURE_DEFERRED_RENDERING
		;; as name entry window is solely rendered with this function,
		;; it is required to default to be with border here, in order to render safely.
		jsr render_x.defer_window_text_with_border

	.else
		jsr field.draw_string_in_window	;$eec0
	.endif
	;clc	;successfully scrolled the item window
	;bcc field_x.restore_banks_with_status
	jmp field.restore_banks	;carry will be cleared by this routine

;--------------------------------------------------------------------------------------------------
;;# $3f$eb69 field.scrollup_item_window
;;
;;## args:
;;+	[in,out] ptr $1c: pointer to text
;;+	[in] u8 $93: bank number of the text
;;+	[in] u8 $a3: ?
;;+	[out] u8 $b4: ? (= 0xc0 if scrolled, or 0x80 if aborted)
;;+	[in,out] u16 ($79f0,$79f2): ?
;;+	[out] bool carry: 1: scroll aborted, 0: scroll successful
;;## callers:
;;+	`1E:9233:20 69 EB  JSR field.scrollup_item_window` @ ?
field.scrollup_item_window:	;;$3f$eb69
;; fixups:
	FIX_ADDR_ON_CALLER $3c,$9233+1	;;@ $3c:920d menu.window3.get_input_and_scroll
;; ---
.p_text = $1c
.p_text_end = $3e
;.text_bank = $93
;; ---
	jsr field_x.unseek_window_text
	jsr field_x.unseek_window_text
	jsr field_x.switch_to_text_bank
	ldy #1
	lda [.p_text],y
	beq .abort_scroll
		jsr field.unseek_text_to_line_beginning
		lda <$a3
		cmp #2
		bne field_x.reflect_item_window_scroll
			;; ($79f0,$79f2) += 8
			lda $79f0
			clc
			adc #8
			sta $79f0
			bcc field_x.reflect_item_window_scroll
				inc $79f2
				bcs field_x.reflect_item_window_scroll
.abort_scroll:	;$eba2
	lda #$80
	bne field.abort_item_window_scroll

	;VERIFY_PC $eba9
;--------------------------------------------------------------------------------------------------
	;INIT_PATCH $3f, $eba9, $ee9a
;;
;;# $3f:eba9 field::seek_text_to_next_line
;;<details>
;;
;;## args:
;;+	[in,out] ptr $1c: pointer to text to seek with
;;+	[out] ptr $3e: pointer to the text, pointing the beginning of next line
;;## callers:
;;+	`1F:EB5E:20 A9 EB  JSR field::seek_to_next_line`
;;+	$3f:ee65 field::stream_string_in_window
;;## code:
field_x.seek_text_to_next:
.p_text = $1c
	IS_PRINTABLE_CHAR
	bcs field.seek_text_to_next_line	;printable.
	;: skip operand value of the replacement char
		inc <.p_text
		bne field.seek_text_to_next_line
			inc <.p_text+1

	FALL_THROUGH_TO field.seek_text_to_next_line

field.seek_text_to_next_line:
;; fixup callers
	;FIX_ADDR_ON_CALLER $3f,$eb5e+1
;; ---
	ldy #0
field_x.find_next_eol:
.p_text = $1c
.p_out = $3e
;; ---
;.loop:
	lda [.p_text],y
	;; p_text++
	inc <.p_text
	bne .low_only
		inc <.p_text+1
.low_only:
	cmp #CHAR.EOL
	bne field_x.seek_text_to_next
.found:
	lda <.p_text
	sta <.p_out
	lda <.p_text+1
	sta <.p_out+1
	rts

;field_x.seek_window_text:
;; on exit, zero is always cleared
;; as either low byte of ptr or high byte has non-zero value after increment
;.p_text = $1c
;	inc <.p_text
;	bne .return
;		inc <.p_text+1
;.return
;	rts

;--------------------------------------------------------------------------------------------------
;;# $3f:ebd1 field::unseek_text_to_line_beginning
;;<details>
;;
;;## args:
;;+	[in,out] ptr $1c: pointer to text to seek with
;;+	[out] ptr $3e: pointer to the text, pointing the beginning of line
;;## callers:
;;+	`1F:EB81:20 D1 EB  JSR field.unseek_to_line_beginning`
;;## notes:
;;used to scroll back texts, in particular when a cursor moved up in item window.
;;
field.unseek_text_to_line_beginning:	;;$3f:ebd1
;; fixup callers:
	;FIX_ADDR_ON_CALLER $3f,$eb81+1
;; ---
;;note: in this logic this points to the byte immeditely preceding the current position
.p_text = $1c
.p_out = $3e
;; --- 
.loop:
		jsr field_x.unseek_window_text
		ldy #0
		lda [.p_text],y
		;; checking if the char at right before the pointer
		;; is a replacement code
		;jsr field_x.is_printable_char
		IS_PRINTABLE_CHAR
		bcs .printable_char	;printable.
			;; if it is, then seek back 2 chars to skip operand byte.
			;; this is bit tricky however it works.
			jsr field_x.unseek_window_text
			bne .loop	;always set
.printable_char:
		;; if the
		iny
		lda [.p_text],y
		lsr A
		bne .loop	;char is neither CHAR.NULL or CHAR.EOL
.found:
	;$3c <- ($1c + 2)
	lda #2
	clc
	adc <.p_text
	sta <.p_out
	ldy <.p_text+1
	bcc .return
		iny
.return:
	sty <.p_out+1
	rts

field_x.unseek_window_text:
.p_text = $1c
	lda <.p_text
	bne .low_byte_only
		dec <.p_text+1
.low_byte_only:
	dec <.p_text
	rts

	;VERIFY_PC $ec0c
	;INIT_PATCH $3f, $ec0c, $ee9a
;------------------------------------------------------------------------------------------------------
;;below 2 logics are moved for space optimization:
;;# $3f:ec0c field::show_sprites_on_lower_half_screen
;;# $3f:ec12 field::show_sprites_on_region7 (bug?)
;--------------------------------------------------------------------------------------------------
;$3f:ed61 field::get_window_region
;//[in]
;// u8 $37: skipAttrUpdate
;// u8 X: window_type (0...4)
;//		0: object's message?
;//		1: choose dialog (Yes/No) (can be checked at INN)
;//		2: use item to object
;//		3: Gil (can be checked at INN)
;//		4: floor name
	;INIT_PATCH $3f,$ed61,$edc6
;;$3f:ed61 field::get_window_region
;;callers:
;;	$3f:ed02 field::draw_window_box
;;NOTEs:
;; 1) to reflect changes in screen those made by 'field.hide_sprites_around_window',
;;	which is called within this function,
;;	caller must update sprite attr such as:
;;	lda #2
;;	sta $4014	;DMA
;; 2) this logic is very simlar to $3d:aabc field::get_menu_window_metrics.
;;	the difference is:
;;		A) this logic takes care of wrap-around unlike the other one, which does not.
;;		B) target window and the address of table where the corresponding metrics defined at
field.get_window_region:	;;$3f:ed61 field::get_window_metrics
;[in]
.viewport_left = $29	;in 16x16 unit
.viewport_top = $2f	;in 16x16 unit
.skip_attr_update = $37
;[out]
.left = $38	;in 8x8 unit
.top = $39	;in 8x8 unit
.width = $3c
.height = $3d
.offset_x = $97
.offset_y = $98
.internal_top = $b5
.internal_left = $b6
.internal_bottom = $b7
.internal_right = $b8

	lda <.skip_attr_update
	bne field_x.rts_1	;rts (original: bne $ed60)
	;; calculate left coordinates
	lda field.window_attr_table_x,x
	sta <.internal_left
	sta <.offset_x
	dec <.offset_x
	lda <.viewport_left	;assert(.object_x < 0x80)
	asl a
	adc <.internal_left
	and #$3f
	sta <.left
	;; calculate top coordinates
	lda field.window_attr_table_y,x
	;clc ;here always clear
	adc #2
	sta <.offset_y
	sta <.internal_top
	dec <.internal_top
	lda <.viewport_top
	asl a
	adc field.window_attr_table_y,x
	cmp #$1e
	bcc .no_wrap
	;sec ;here always set
	sbc #$1e
.no_wrap:
	sta <.top
	
	;; calculate right coordinates
	lda field.window_attr_table_width,x
	sta <.width
	clc
	adc <.internal_left
	sta <.internal_right
	dec <.internal_right
	;; calculate bottom coordinates
	lda field.window_attr_table_height,x
	sta <.height
	clc
	adc <.internal_top
	;sec	;here always clear
	sbc #2	;effectively -3
	sta <.internal_bottom
	;; done calcs
	;; here X must have window_type (as an argument to the call below)
	FALL_THROUGH_TO field.hide_sprites_under_window
		;jmp field.hide_sprites_under_window	;$ec18
		;rts
		;VERIFY_PC $edb2

;--------------------------------------------------------------------------------------------------
;;# $3f:ec18 field::hide_sprites_under_window
;;<details>
;;
;;## args:
;;+	[in]	u8 X: window_type (0...4)
;;## callers:
;;+	$3f$ed61 field::get_window_region
;;## code:
field.hide_sprites_under_window:
	lda #0
	FALL_THROUGH_TO field.showhide_sprites_by_region
;--------------------------------------------------------------------------------------------------
;;# $3f:ec1a field::showhide_sprites_by_region
;;## args:
;;+	[in]	u8 A: show/hide.
;;	+	1: show
;;	+	0: hide
;;+	[in]	u8 X: region_type (0..6; with 0 to 4 being shared with window_type)
;;## callers:
;;+	$3f:ec0c field::show_sprites_on_lower_half_screen
;;+	$3f:ec12 field::show_sprites_on_region7 (with X set to 7)
;;+	$3f:ec18 field::showhide_sprites_by_window_region
;;## local variables:
;;+	u8 $80: region boundary in pixels, left, inclusive.
;;+	u8 $81: region boundary in pixels, right, exclusive.
;;+	u8 $82: region boundary in pixels, top, inclusive.
;;+	u8 $83: region boundary in pixels, bottom, exclusive.
;;+	u8 $84: show/hide flag
field.showhide_sprites_by_region:
;; --- fixups
;; all callers have got replaced their implementation within this file
;; --- 
;.region_left = $80	;in pixels
;.region_right = $81	;in pixels
;.region_top = $82	;in pixels
;.region_bottom = $83;in pixels
.is_to_show = $84
.sprite_buffer.x = $0203
.sprite_buffer.y = $0200
.sprite_buffer.attr = $0202
	sta <.is_to_show
	ldy #$40	;don't change player and cursor (stored at before $0240) anyways

	.for_each_sprites:
		;; if (x < left || right <= x) { continue; }
		lda .sprite_buffer.x, y
		sec
		sbc field.region_bounds.left, x
		cmp field.region_bounds.width, x
		bcs .next
			;; if (y < top || bottom <= y) { continue; }
			lda .sprite_buffer.y, y
			;;here carry is always clear
			sbc field.region_bounds.top, x	;;top is adjusted to account carry
			cmp field.region_bounds.height, x
			bcs .next
				lda .sprite_buffer.attr, y
				and #$df	;bit 5 <- 0: sprite in front of BG
				bit <.is_to_show
				bne .update
					ora #$20	;bit 5 <- 1: sprite behind BG
			.update:
				sta .sprite_buffer.attr, y
	.next:
		iny
		iny
		iny
		iny 
		bne .for_each_sprites
field_x.rts_1:
	rts
;--------------------------------------------------------------------------------------------------
;;# $3f:ec0c field::show_sprites_on_lower_half_screen
;;<details>
;;
;;## callers:
;;+	`1F:C9B6:20 0C EC  JSR field.show_sprites_on_region6`
field.show_sprites_on_lower_half_screen:
;; --- fixup address on callers
	FIX_ADDR_ON_CALLER $3e,$c9b6+1
;; ---
	ldx #6
	bne	field.show_sprites_by_region
;--------------------------------------------------------------------------------------------------
;;# $3f:ec12 field::show_sprites_on_region7 (bug?)
;;<details>
;;
;;## callers:
;;+	`1F:C9C1:20 12 EC  JSR field.show_sprites_on_region7`
field.show_sprites_on_region7:
;; --- fixup address on callers
	FIX_ADDR_ON_CALLER $3e,$c9c1+1
;; --- begin
	ldx #7	;;invalid region type. seems to be a bug.
field.show_sprites_by_region:
	lda #1
	bne	field.showhide_sprites_by_region
;------------------------------------------------------------------------------------------------------
field.region_bounds.left:	;$ec67 left (inclusive)
	DB $0A,$0A,$0A,$8A,$0A,$0A,$0A
;field.region_bounds.right:	;$ec6e right (excludive, out of the box)
	;DB $EF,$4F,$EF,$EF,$EF,$EF,$EF	
field.region_bounds.width:
	DB $E5,$45,$E5,$65,$E5,$E5,$E5	;width
field.region_bounds.top:		;$ec75 top (inclusive)
	;DB $0A,$8A,$8A,$6A,$0A,$0A,$6A
	DB $09,$89,$89,$69,$09,$09,$69	;top - 1.(accounted for optimization)
;field.region_bounds.bottom:	;$ec7c bottom (exclusive)
	;DB $57,$D7,$D7,$87,$2A,$57,$D7	
field.region_bounds.height:
	DB $4d,$4d,$4d,$1d,$20,$4d,$6d	;height

	;VERIFY_PC $ec83
;------------------------------------------------------------------------------------------------------
	;.org $edb2
field.window_attr_table_x:	; = $edb2
	.db $02, $02, $02, $12, $02
field.window_attr_table_y:	; = $edb7
	.db $02, $12, $12, $0e, $02
field.window_attr_table_width:	; = $edbc
	.db $1c, $08, $1c, $0c, $1c
field.window_attr_table_height:	; = $edc1
	.db $0a, $0a, $0a, $04, $04

	;VERIFY_PC $edc6
;------------------------------------------------------------------------------------------------------
	;INIT_PATCH $3f,$ec83,$ee9a

;;$3f:ec83 field::show_message_UNKNOWN:
;; 1F:EC83:A9 00     LDA #$00
;; 1F:EC85:20 FA EC  JSR field::draw_inplace_window
;; 1F:EC88:4C 65 EE  JMP field::stream_string_in_window
field.show_off_message_window:
	lda #0
field_x.show_off_window:
	jsr field.draw_inplace_window		;$ecfa
	jmp field.stream_string_in_window	;$ee65
;------------------------------------------------------------------------------------------------------
;;$3f:ec8b field::show_message_window:
;;callers:
;;	1F:E237:20 8B EC  JSR field::show_message_window
;;
field.show_message_window:
;;patch out callers
	FIX_ADDR_ON_CALLER $3f,$e237+1
;;
	lda #0
	FALL_THROUGH_TO field.show_window
;------------------------------------------------------------------------------------------------------
;;$3f:ec8d field::show_window:
;;callers:
;;	 1F:E264:20 8D EC  JSR $EC8D
;;in:
;;	u8 A : window_type
field.show_window:
;;patch out external callers {
	FIX_ADDR_ON_CALLER $3f,$e264+1
;;}
.field.pad1_inputs = $20
	;jsr field.draw_inplace_window		;$ecfa
	;jsr field.stream_string_in_window	;$ee65
	jsr field_x.show_off_window
	jsr field.await_and_get_next_input	;$ecab
	lda <$7d
	;beq .leave	;$eca8
	bne .enter_input_loop
.leave:	;$eca8
		jmp $c9b6
.input_loop:	;$ec9e
	jsr field.get_next_input	
.enter_input_loop:	;$ec9a
	lda <.field.pad1_inputs
	bpl .input_loop
.on_a_button_down:	;$eca4
	lda #0
	sta <$7d
	beq .leave	;always met
;------------------------------------------------------------------------------------------------------
;;$3f:ECAB field::await_and_get_new_input:
;;callers:
;;	 1F:EC93:20 AB EC  JSR field::await_and_get_new_input ($3f:ec8b field::show_message_window)
;;	 1F:ECBA:4C AB EC  JMP field::await_and_get_new_input (tail recursion)
;;	 1F:EE6A:20 AB EC  JSR field::await_and_get_new_input ($3f:ee65 field::stream_string_in_window)
field.await_and_get_next_input:
	jsr field_x.get_input_with_result	;on exit, A have the value from $20
	beq field.get_next_input_in_this_frame
	jsr field_x.advance_frame
	jmp field.await_and_get_next_input
;------------------------------------------------------------------------------------------------------
;;$3f:ECc4 field::get_next_input:
;;callers:
;;	1F:EC9E:20 C4 EC  JSR field::get_next_input
field.get_next_input:
;.field.pad1_inputs = $20	;bit7 <- A ...  -> bit0
;;$ecc4:
	jsr field_x.advance_frame
	;;fall through
field.get_next_input_in_this_frame:
.field.input_cache = $21
;;$ecbd:
	jsr field_x.get_input_with_result	;on exit, A have the value from $20
	beq field.get_next_input
;;$eccf
	sta <.field.input_cache
	bne field_x.switch_to_text_bank
;------------------------------------------------------------------------------------------------------
;;$3f:ecd8 field::advance_frame_with_sound
;;callers:
;;	 1F:EE74:20 D8 EC  JSR field::advance_frame_w_sound ($3f:ee65 field::stream_string_in_window)
field.advance_frame_and_set_bank:
	jsr field_x.advance_frame
	;;jmp field_x.switch_to_text_bank
	FALL_THROUGH_TO field_x.switch_to_text_bank
;------------------------------------------------------------------------------------------------------
field_x.switch_to_text_bank:
.content_string_bank = $93
	lda <.content_string_bank
	jmp call_switch_2banks

field_x.advance_frame:
	jsr waitNmiBySetHandler
field_x.advance_frame_no_wait:
	inc <field.frame_counter
	jmp field.call_sound_driver

field_x.get_input_with_result:
.field.pad1_inputs = $20	;bit7 <- A ...  -> bit0
	jsr field.get_input
	lda <.field.pad1_inputs
	rts

	;VERIFY_PC $ece5

;------------------------------------------------------------------------------------------------------
	;INIT_PATCH $3f,$ece5,$ecf5
;;$3f:ece5 field::draw_window_top:
;;NOTEs:
;;	called when executed actions the below in item window from menu
;;	1) exchange of position
;;	2) use of item
;;callers:
;;	 1E:AAA3:4C E5 EC  JMP field::draw_window_top
;;original code:
;1F:ECE5:A5 39     LDA window_top = #$0B
;1F:ECE7:85 3B     STA window_row_in_draw = #$0F
;1F:ECE9:20 70 F6  JSR field::calc_size_and_init_buff
;1F:ECEC:20 56 ED  JSR field::init_window_attr_buffer
;1F:ECEF:20 F6 ED  JSR field::get_window_top_tiles
;1F:ECF2:20 C6 ED  JSR field::draw_window_row
field.draw_window_top:
;; patch out callers external to current implementation {
	FIX_ADDR_ON_CALLER $3d,$aaa3+1
;;}
.window_top = $39
.window_row_in_drawing = $3b
	.ifdef _FEATURE_DEFERRED_RENDERING
		jsr field_x.shrink_window_metrics
		ldx #(render_x.NEED_TOP_BORDER|render_x.PENDING_INIT|render_x.RENDER_RUNNING|render_x.SKIP_CONTENTS)
		jsr render_x.setup_deferred_rendering
		;; contents of the item window will be redrawn after the border rendered.
		;; so it is ok to fill content area with empty background, though not looking good.
		;jsr field.draw_window_content
		jsr render_x.queue_top_border
		jsr render_x.finalize
		;; HACK ---> TODO: do it cleaner way
		lda #0
		sta render_x.q.init_flags
		;; <--- HACK
	.else	;;ifdef _FEATURE_DEFERRED_RENDERING
		lda <.window_top
		sta <.window_row_in_drawing
		jsr field.calc_draw_width_and_init_window_tile_buffer
		jsr field.init_window_attr_buffer
		jsr field.get_window_top_tiles
		jsr field.draw_window_row
	.endif	;;ifdef _FEATURE_DEFERRED_RENDERING
	;; fall through (into $ecf5: field.restore_banks)
	;jmp field.restore_banks	;$ecf5
	FALL_THROUGH_TO field.restore_banks

	;VERIFY_PC $ecf5
;------------------------------------------------------------------------------------------------------
;;$3f:ecf5 restoreBanksBy$57
;;callers:
;;	 1F:EB64:20 F5 EC  JSR field::restore_banks (in $3f:eb61 field::drawEncodedStringInWindowAndRestoreBanks)
;;	 1F:F49E:4C F5 EC  JMP field::restore_banks
;;	field::draw_window_top (by falling thourgh)
;;	field::draw_window_box
field.restore_banks:
;; patch out external callers {
	;FIX_ADDR_ON_CALLER $3f,$eb64+1
	FIX_ADDR_ON_CALLER $3f,$f49e+1
;;}
.program_bank = $57
	lda <.program_bank
	jmp call_switch_2banks
	;VERIFY_PC $ecfa
;------------------------------------------------------------------------------------------------------
;;$3f:ed56 field::fill_07c0_ff
;;callers:
;;	$3f:ece5 field::draw_window_top
;;	$3f:ed02 field::draw_window_box
field.init_window_attr_buffer:
.window_attr_buffer = $07c0
	ldx #$0f
	lda #$ff
.fill:
	sta .window_attr_buffer,x
	dex
	bpl .fill
	rts

	;VERIFY_PC $ed61

;;for optimzation,
;;$3f$ed61 field.get_window_metrics is relocated to nearby $3f$ec1a field.showhide_sprites_by_region
;------------------------------------------------------------------------------------------------------
;$3f:ede1 field::sync_ppu_scroll
;{
;	if ($37 == 0) { //bne ede8
;		return $e571();
;	}
;$ede8:
;	$2000 = $ff;
;	$2005 = 0; $2005 = 0;
;	return;
;$edf6:
;}
	;INIT_PATCH $3f,$ede1,$edf6
;;$3f:ede1 field::sync_ppu_scroll
;;callers:
;;	$3f:edc6 field.draw_window_row
;;	$3f:f692 field.draw_window_content
field.sync_ppu_scroll:
.in_menu_mode = $37
.ppu_ctrl_cache = $ff
	lda <.in_menu_mode
	bne .set_ppu_ctrl
		jmp field.sync_ppu_scroll_with_player	;$e571
.set_ppu_ctrl:
	lda <.ppu_ctrl_cache
	sta $2000
	lda #00
	sta $2005
	sta $2005
	rts
	;VERIFY_PC $edf6
;------------------------------------------------------------------------------------------------------
	.ifndef _FEATURE_DEFERRED_RENDERING
	;INIT_PATCH $3f,$edf6,$ee65
;;$3f:edf6 field::getWindowTilesForTop
;;callers:
;;	$3f:ece5 field::draw_window_top
;;	$3f:ed02 field::draw_window_box
field.get_window_top_tiles:		
	lda #$00
	jsr field_x.get_window_tiles
	;lda #$07
	;;fall through
field_x.get_window_tiles:
.width = $3c
.eol = $3c
.window_tiles_buffer_upper_row = $0780
;.window_tiles_buffer_lower_row = $07a0
;;in: A := lower 1bits:  0: fill in upper row; 1: fill in lower row
;;	higher 7bits: offset into tile table
	pha
	lsr A
	tay
	ldx #0
	bcc .save_width
	ldx #$20
.save_width:
	lda <.width
	pha	;width
.left_tile:
	lda field_x.window_parts,y
	sta .window_tiles_buffer_upper_row,x
	txa
	clc
	adc <.width
	sta <.eol	;width + offset
	inx
.center_tiles:
		lda field_x.window_parts+1,y
		sta .window_tiles_buffer_upper_row,x
		inx
		cpx <.eol
		bcc .center_tiles
.right_tile:
	lda field_x.window_parts+2,y
	sta .window_tiles_buffer_upper_row-1,x
	pla	;original width
	sta <.width
	pla
	;here always carry is set
	;adc #$22	;effectively +23
	adc #$06
	rts

;;$3f:ee3e field::getWindowTilesForBottom
;;callers:
;;	$3f:ed02 field::draw_window_box
field.get_window_bottom_tiles:	;ed3b
	lda #$03<<1
	jsr field_x.get_window_tiles
	bne field_x.get_window_tiles
;;$3f:ee1d field::getWindowTilesForMiddle
;;callers:
;;	$3f:ed02 field::draw_window_box
field.get_window_middle_tiles:	;ee1d
	lda #$03<<1
	jsr field_x.get_window_tiles
	lda #$03<<1|1
	bne field_x.get_window_tiles

field_x.window_parts:
	db $f7, $f8, $f9
	db $fa, $ff, $fb
	db $fc, $fd, $fe
	.else	;.ifndef _FEATURE_DEFERRED_RENDERING

field_x.window_parts:
	db $f7, $f8, $f9
	db $fc, $fd, $fe

	.endif	;.ifndef _FEATURE_DEFERRED_RENDERING

	;VERIFY_PC $ee65
;------------------------------------------------------------------------------------------------------
	;INIT_PATCH $3f,$ee65,$ee9a
;;$3f:ee65 field::stream_string_in_window
;;callers:
;;	1E:9109:4C 65 EE  JMP $EE65 @ $3c:90ff	? 
;;	1E:A675:4C 65 EE  JMP $EE65	@ $3d:a66b field.draw_menu_window_content
;;	1F:EC88:4C 65 EE  JMP $EE65 @ $3f:ec83 field::show_off_message_window
;;	1F:EC90:20 65 EE  JSR $EE65 @ $3f:ec8b field::show_message_window
field.stream_string_in_window:
;; patch out callers external to this implementation {
	FIX_ADDR_ON_CALLER $3c,$9109+1
	FIX_ADDR_ON_CALLER $3d,$a675+1
;; }
.viewport_left = $29	;in 16x16 unit
.viewport_top = $2f	;in 16x16 unit
.in_menu_mode = $37
.window_left = $38	;in 8x8 unit
.window_top = $39	;in 8x8 unit
.window_width = $3c
.window_height = $3d
.offset_x = $97
.offset_y = $98
;; ---
	;; all of the callers are fine to render with borders (the default of 'load_and_draw_string').
	jsr field.load_and_draw_string	;$ee9a.
	;; on exit from above, carry has a boolean value.
	;; 1: more to draw, 0: completed drawing.
	bcc .do_return	
	.paging:
		jsr field.await_and_get_next_input
		lda <.window_height
		clc
		adc #1	;round up to next mod 2
		lsr A
	.streaming:
		sec
		sbc #1
		pha	;# of text lines available to draw
		lda #0
		sta <field.frame_counter
		.delay_loop:
			jsr field.advance_frame_and_set_bank	;$ecd8
			lda <field.frame_counter
			and #FIELD_WINDOW_SCROLL_FRAMES	;;originally 1
			bne .delay_loop
		jsr field.seek_text_to_next_line	;$eba9
		jsr field.draw_string_in_window		;$eec0
		;; on exit from above, carry has a boolean value.
		;; 1: more to draw, 0: completed drawing.
		pla	;# of text lines available to draw
		bne .streaming	;there is more space to fill in
		bcs .paging	;there is more text to draw
		;;content space is filled with reaching end of text 
.do_return:
	rts
	;VERIFY_PC $ee9a
	;INIT_PATCH $3f,$ee9a,$eec0
;------------------------------------------------------------------------------------------------------
;;# $3f:ee9a field::load_and_draw_string
;;### args:
;;
;;#### in:
;;+	u8 $92: string_id
;;+	ptr $94: offset to string ptr table
;;
;;#### out:
;;+	bool carry: more_to_draw	//flagged cases could be tested at サロニアの図書館(オーエンのほん1)
;;+	ptr $3e: offset to the string, assuming the bank it to be loaded is at 1st page (starting at $8000)
;;+	u8 $93: bank number which the string would be loaded from
;;
;;### callers:
;;+	`1F:C036:20 9A EE  JSR field::load_and_draw_string` @ opening title
;;+	`1F:EE65:20 9A EE  JSR field::load_and_draw_string` @ $3f:ee65 field::stream_string_in_window
;;+	`3c:9116  jmp $EE9A `   @ some menu content
;;+	`3d:a682  jmp $EE9A `	@ $3d:a678 menu.draw_window_content
field_x.load_and_draw_string_without_border:
	FIX_ADDR_ON_CALLER $3e, $c036+1
	.ifdef _FEATURE_DEFERRED_RENDERING
		;; opening title roll should be rendered without border.
		;; however, this call is made after a call into 'menu.get_window_content_metrics'.
		;; as of patch version 0.8.2, that function does equivalent initialization.
		;; so we no longer need do it again here.
		;jsr render_x.init_as_no_borders
	.endif	;;_FEATURE_DEFERRED_RENDERING
field.load_and_draw_string:	;;$ee9a
;; fixups.
	FIX_ADDR_ON_CALLER $3c, $9116+1		;;menu content
	FIX_ADDR_ON_CALLER $3d, $a682+1		;;menu content. called when shop offerings is about to open.
	;FIX_ADDR_ON_CALLER $3e, $c036+1
;; ---
.p_text = $3e
.text_id = $92
.text_bank = $93
.p_text_table = $94	;;stores offset from $30000(18:8000) to the text 
;; ---
	lda <.text_id
	ldx <.p_text_table+1
	ldy <.p_text_table
	;; unlike the original implementation, the below function destructs $80,81.
	;; as these are generic temporary variable, this should be fine.
	jsr textd_x.load_text_ptr
	;; here A = text_bank.
	sta <.text_bank
	;FALL_THROUGH_TO field.draw_string_in_window
	FALL_THROUGH_TO render_x.defer_window_text_with_border
;------------------------------------------------------------------------------------------------------
render_x.defer_window_text_with_border:
	.ifdef _FEATURE_DEFERRED_RENDERING
	;; request deferred rendering with borders.
	;ldx #(render_x.PENDING_INIT|render_x.RENDER_RUNNING|render_x.NEED_TOP_BORDER|render_x.NEED_BOTTOM_BORDER)
.flags1 = render_x.PENDING_INIT|render_x.RENDER_RUNNING
.init_flags = .flags1 | render_x.NEED_TOP_BORDER|render_x.NEED_BOTTOM_BORDER|render_x.NEED_ATTRIBUTES
	ldx #(.init_flags)
	jsr render_x.setup_deferred_rendering
	.endif	;_FEATURE_DEFERRED_RENDERING
;------------------------------------------------------------------------------------------------------
	;INIT_PATCH $3f,$eec0,$eefa
;;# $3f:eec0 field.draw_string_in_window
;;
;;
;;### args:
;;+	[in] ptr $3e : string offset
;;+	[in] u8 $93 : string bank
;;+	[out] bool carry: more_to_draw
;;
;;### callers:
;;+	`1F:EB61:20 C0 EE  JSR field::draw_string_in_window` @ $3f:eb61 field.reflect_window_scroll
;;+	`1F:EE80:20 C0 EE  JSR field::draw_string_in_window` @ $3f:ee65 field::stream_string_in_window
;;+	`1F:EEBE:85 93     STA field.window_text_bank = #$18` (fall through)@ $3f:ee9a field::load_and_draw_string
field.draw_string_in_window:	;;$eec0
;; fixups.
	;; every caller is implemented within this file.
;; ---
.output_index = $90
.text_bank = $93
.p_text = $3e
.p_text_line = $1c
.menu_item_continue_building = $1e
.lines_drawn = $1f
;; ---
.program_bank = $57
;; --- window related
.in_menu_mode = $37
.window_left = $38
.window_top = $39
.offset_x = $3a
.offset_y = $3b
.window_width = $3c
.window_height = $3d
;; ---
	lda <.text_bank
	jsr call_switch_2banks	;$FF03
	lda <.p_text
	sta <.p_text_line
	lda <.p_text+1
	sta <.p_text_line+1
	lda <.window_left	;$38
	sta <.offset_x		;$3A
	lda <.window_top	;$39
	sta <.offset_y		;$3B
	jsr field.calc_draw_width_and_init_window_tile_buffer	;$f670
	lda #$00
	sta <.output_index	;$90
	sta <.lines_drawn	;$1F
	sta <.menu_item_continue_building	;$1e
	jsr textd.draw_in_box	;$eefa
	bcc .completed
;$eef3
.more_to_draw:
	jmp field_x.restore_banks_with_carry_set
	;lda <.program_bank	; $57
	;jsr call_switch_2banks	;$FF03
	;sec
	;rts
.completed:
	.ifdef _FEATURE_DEFERRED_RENDERING
		jsr render_x.fill_to_bottom
	.else
		jsr field.draw_window_content	;$f692
	.endif
	;lda <.program_bank	; $57
	;jsr call_switch_2banks	;$FF03
	jmp field.restore_banks	;carry will be implictly cleared
;$eef1
;field_x.clc_return:
	;FIX_OFFSET_ON_CALLER $3f,$eefe+1
;	clc
;	rts
;--------------------------------------------------------------------------------------------------	
	;VERIFY_PC $eefa
	VERIFY_PC_TO_PATCH_END field.window.driver
field.window.driver.BULK_PATCH_FREE_BEGIN:

	.endif	;_OPTIMIZE_FIELD_WINDOW

;======================================================================================================
	;RESTORE_PC ff3_field_window_driver_begin