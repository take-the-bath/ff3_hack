﻿
# $3c:9fa5 menu.items.on_2nd_item_selected
> 「アイテム」メニューで2回目の選択を行ったときの処理。

### args:
+	yet to be investigated

### callers:
+	yet to be investigated

### local variables:
+	yet to be investigated

### notes:
write notes here

### (pseudo)code:
```js
{
/*
    ldx $7AF0   ; 9FA5 AE F0 7A
    lda $7A03,x ; 9FA8 BD 03 7A
    sta <$8F     ; 9FAB 85 8F
    lda $7A02,x ; 9FAD BD 02 7A
    cmp #$0F    ; 9FB0 C9 0F
    bne .L_9FDC   ; 9FB2 D0 28
    ldx <$8E     ; 9FB4 A6 8E
    cpx #$20    ; 9FB6 E0 20
    bcs .L_9FCD   ; 9FB8 B0 13
.L_9FBA:
;; dustbox
    lda $60C0,x ; 9FBA BD C0 60
    cmp #$F6    ; 9FBD C9 F6
    beq .L_9FCD   ; 9FBF F0 0C
    cmp #$F7    ; 9FC1 C9 F7
    beq .L_9FCD   ; 9FC3 F0 08
    cmp #$9A    ; 9FC5 C9 9A
    bcc .L_9FD2   ; 9FC7 90 09
    cmp #$A4    ; 9FC9 C9 A4
    bcs .L_9FD2   ; 9FCB B0 05
.L_9FCD:
    jsr menu.queue_SE_of_invalid_action ; 9FCD 20 29 D5
    sec             ; 9FD0 38
    rts             ; 9FD1 60
; ----------------------------------------------------------------------------
.L_9FD2:
;; dustbox / empty
    lda #$00    ; 9FD2 A9 00
    sta $60C0,x ; 9FD4 9D C0 60
    sta $60E0,x ; 9FD7 9D E0 60
    clc             ; 9FDA 18
    rts             ; 9FDB 60
; ----------------------------------------------------------------------------
.L_9FDC:
;; swap
    ldx <$8F        ; 9FDC A6 8F
    ldy <$8E        ; 9FDE A4 8E
    cpy #$20        ; 9FE0 C0 20
    bcs .L_9FBA     ; 9FE2 B0 D6
    cpy <$8F        ; 9FE4 C4 8F
    beq .L_A033     ; 9FE6 F0 4B
    lda $60C0,x     ; 9FE8 BD C0 60
    pha             ; 9FEB 48
    lda $60C0,y     ; 9FEC B9 C0 60
    sta $60C0,x     ; 9FEF 9D C0 60
    pla             ; 9FF2 68
    sta $60C0,y     ; 9FF3 99 C0 60
    lda $60E0,x     ; 9FF6 BD E0 60
    pha             ; 9FF9 48
    lda $60E0,y     ; 9FFA B9 E0 60
    sta $60E0,x     ; 9FFD 9D E0 60
.L_A000:
    pla             ; A000 68
    sta $60e0,y     ; A001 99 E0 60
    clc             ; A004 18
    rts             ; A005 60
; ----------------------------------------------------------------------------
.L_A006:
    lda <$2D        ; A006 A5 2D
    lsr a           ; A008 4A
    bcs .L_A03C     ; A009 B0 31
    jsr menu.items.consume_item   ; A00B 20 3C A3
    jmp .L_A525     ; A00E 4C 25 A5
; ----------------------------------------------------------------------------
.L_A011:
    pla             ; A011 68
    lda #$65        ; A012 A9 65
    jsr .L_A2F6     ; A014 20 F6 A2
    lda <$20        ; A017 A5 20
    and #$40        ; A019 29 40
    bne .L_A031     ; A01B D0 14
    jsr menu.items.consume_item   ; A01D 20 3C A3
    jsr field.queue_SE_of_healing   ; A020 20 8C 95
    jsr .L_9921     ; A023 20 21 99
    jmp .L_C0ED     ; A026 4C ED C0
; ----------------------------------------------------------------------------
.L_A029:
    lda #$5A        ; A029 A9 5A
.L_A02B:
    jsr .L_A2F6     ; A02B 20 F6 A2
    jsr menu.init_input_states      ; A02E 20 92 95
.L_A031:
    clc             ; A031 18
    rts             ; A032 60
; ----------------------------------------------------------------------------
.L_A033:
    ldx <$8E        ; A033 A6 8E
    stx <$63        ; A035 86 63
    lda $60E0,x     ; A037 BD E0 60
    bne .L_A044     ; A03A D0 08
.L_A03C:
    jsr menu.queue_SE_of_invalid_action ; A03C 20 29 D5
    sec             ; A03F 38
    rts             ; A040 60
; ----------------------------------------------------------------------------
.L_A041:
    jmp .L_A15F     ; A041 4C 5F A1
; ----------------------------------------------------------------------------
.L_A044:
    ldy $60C0,x ; A044 BC C0 60
    cpy #$A4    ; A047 C0 A4
    beq .L_A006   ; A049 F0 BB
    cpy #$A6    ; A04B C0 A6
    bcc .L_A029   ; A04D 90 DA
    cpy #$C8    ; A04F C0 C8
    bcs .L_A041   ; A051 B0 EE
    cpy #$B1    ; A053 C0 B1
    bcs .L_A029   ; A055 B0 D2
    cpy #$AB    ; A057 C0 AB
    beq .L_A05F   ; A059 F0 04
    cpy #$AD    ; A05B C0 AD
    bne .L_A069   ; A05D D0 0A
    lda <$53      ; A05F A5 53
    and #$20    ; A061 29 20
    beq .L_A073   ; A063 F0 0E
    lda #$77    ; A065 A9 77
    bne .L_A02B   ; A067 D0 C2
.L_A069:
    cpy #$B0    ; A069 C0 B0
    bne .L_A073   ; A06B D0 06
    bit <$53     ; A06D 24 53
    lda #$78    ; A06F A9 78
    bvs .L_A02B   ; A071 70 B8
.L_A073:
    tya             ; A073 98
    pha             ; A074 48
    sec             ; A075 38
    sbc #$A6    ; A076 E9 A6
    clc             ; A078 18
    adc #$5B    ; A079 69 5B
    pha             ; A07B 48
    ldx #$15    ; A07C A2 15
    jsr menu.draw_window_box        ; A07E 20 F1 AA
    pla             ; A081 68
    jsr menu.draw_window_content    ; A082 20 78 A6
    pla             ; A085 68
    pha             ; A086 48
    cmp #$B0    ; A087 C9 B0
    beq .L_A011   ; A089 F0 86
.L_A08B:
    jsr .L_A715   ; A08B 20 15 A7
    pla             ; A08E 68
    tay             ; A08F A8
    bcs .L_A031   ; A090 B0 9F
    jsr field.queue_SE_of_healing   ; A092 20 8C 95
    ldx <$7F     ; A095 A6 7F
    cpy #$A6    ; A097 C0 A6
    bne .L_A0B4   ; A099 D0 19
    lda $6102,x ; A09B BD 02 61
    cmp #$40    ; A09E C9 40
    bcs .L_A0B1   ; A0A0 B0 0F
    lda #$1E    ; A0A2 A9 1E
.L_A0A4:
    sta <$8D     ; A0A4 85 8D
    lda #$01    ; A0A6 A9 01
    sta <$8B     ; A0A8 85 8B
    lda #$03    ; A0AA A9 03
    sta <$8C     ; A0AC 85 8C
    jsr .L_A48A   ; A0AE 20 8A A4
.L_A0B1:
    jmp .L_A12B   ; A0B1 4C 2B A1
; ----------------------------------------------------------------------------
.L_A0B4:
    cpy #$A7    ; A0B4 C0 A7
    bne .L_A0C4   ; A0B6 D0 0C
    lda $6102,x ; A0B8 BD 02 61
    cmp #$40    ; A0BB C9 40
    bcs .L_A0B1   ; A0BD B0 F2
    lda #$78    ; A0BF A9 78
    jmp .L_A0A4   ; A0C1 4C A4 A0
; ----------------------------------------------------------------------------
.L_A0C4:
    cpy #$A8    ; A0C4 C0 A8
    bne .L_A0D8   ; A0C6 D0 10
    lda $6102,x ; A0C8 BD 02 61
    cmp #$40    ; A0CB C9 40
    bcs .L_A0B1   ; A0CD B0 E2
    jsr .L_A458   ; A0CF 20 58 A4
    jsr .L_A418   ; A0D2 20 18 A4
    jmp .L_A12B   ; A0D5 4C 2B A1
; ----------------------------------------------------------------------------
.L_A0D8:
    cpy #$A9        ; A0D8 C0 A9
    bne .L_A0F2     ; A0DA D0 16
    lda $6102,x     ; A0DC BD 02 61
    bpl .L_A13C     ; A0DF 10 5B
    eor #$80        ; A0E1 49 80
    sta $6102,x     ; A0E3 9D 02 61
    lda #$00        ; A0E6 A9 00
    sta <$82        ; A0E8 85 82
    lda #$01        ; A0EA A9 01
    jsr .L_A438     ; A0EC 20 38 A4
    jmp .L_A12B     ; A0EF 4C 2B A1
; ----------------------------------------------------------------------------
.L_A0F2:
    cpy #$AA        ; A0F2 C0 AA
    bne .L_A0FB     ; A0F4 D0 05
    lda #$40        ; A0F6 A9 40
    jmp .L_A144     ; A0F8 4C 44 A1
; ----------------------------------------------------------------------------
.L_A0FB:
    cpy #$AB        ; A0FB C0 AB
    bne .L_A104     ; A0FD D0 05
    lda #$20        ; A0FF A9 20
    jmp .L_A144     ; A101 4C 44 A1
; ----------------------------------------------------------------------------
.L_A104:
    cpy #$AC        ; A104 C0 AC
    bne .L_A10D     ; A106 D0 05
    lda #$10        ; A108 A9 10
    jmp .L_A144     ; A10A 4C 44 A1
; ----------------------------------------------------------------------------
.L_A10D:
    cpy #$AD        ; A10D C0 AD
    bne .L_A11D     ; A10F D0 0C
    lda #$08        ; A111 A9 08
    eor $6102,x     ; A113 5D 02 61
    sta $6102,x     ; A116 9D 02 61
    clc             ; A119 18
    jmp .L_A12B     ; A11A 4C 2B A1
; ----------------------------------------------------------------------------
.L_A11D:
    cpy #$AE        ; A11D C0 AE
    bne .L_A126     ; A11F D0 05
    lda #$04        ; A121 A9 04
    jmp .L_A144     ; A123 4C 44 A1
; ----------------------------------------------------------------------------
.L_A126:
    lda #$02        ; A126 A9 02
    jmp .L_A144     ; A128 4C 44 A1
; ----------------------------------------------------------------------------
.L_A12B:
    bcs .L_A13C     ; A12B B0 0F
    jsr menu.items.consume_item   ; A12D 20 3C A3
    jsr menu.party_summary.draw_content   ; A130 20 32 A3
    lda #$00        ; A133 A9 00
    sta <$A2        ; A135 85 A2
    sta $78F0       ; A137 8D F0 78
    clc             ; A13A 18
    rts             ; A13B 60
; ----------------------------------------------------------------------------
.L_A13C:
    tya             ; A13C 98
    pha             ; A13D 48
    jsr menu.queue_SE_of_invalid_action ; A13E 20 29 D5
    jmp .L_A08B     ; A141 4C 8B A0
; ----------------------------------------------------------------------------
.L_A144:
    sta <$80        ; A144 85 80
    and $6102,x     ; A146 3D 02 61
    bne .L_A14F     ; A149 D0 04
    sec             ; A14B 38
    jmp .L_A12B     ; A14C 4C 2B A1
; ----------------------------------------------------------------------------
.L_A14F:
    lda <$80        ; A14F A5 80
    eor #$FF        ; A151 49 FF
    and $6102,x     ; A153 3D 02 61
    sta $6102,x     ; A156 9D 02 61
    clc             ; A159 18
    jmp .L_A12B     ; A15A 4C 2B A1
*/
}
```
