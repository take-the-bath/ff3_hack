﻿


# $3c:91d9 menu.window2.get_input_and_update_cursor
> メニューの2つ目のウインドウ($7900で管理)用にパッド入力を取得し、必要に応じてカーソル位置の情報を更新する。描画はしない。

### args:
+	in u8 A: offset delta for up/down key
+	in,out u8 $79f0: byte offset of selected item (each menu item consists of 4-byte structure)
+	in u8 $79f1: byte offset of the end of menu-item in the view

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
    sta <$06     ; 91D9 85 06
    jsr menu.get_input_and_queue_SE ; 91DB 20 75 91
    and #$0F    ; 91DE 29 0F
    beq .L_91FC   ; 91E0 F0 1A
    cmp #$04    ; 91E2 C9 04
    bcs .L_91EA   ; 91E4 B0 04
    ldx #$04    ; 91E6 A2 04
    stx <$06     ; 91E8 86 06
.L_91EA:
    and #$05    ; 91EA 29 05
    bne .L_91FD   ; 91EC D0 0F
    lda $79F0   ; 91EE AD F0 79
    sec             ; 91F1 38
    sbc <$06     ; 91F2 E5 06
    bcs .L_91F9   ; 91F4 B0 03
    adc $79F1   ; 91F6 6D F1 79
.L_91F9:
    sta $79F0   ; 91F9 8D F0 79
.L_91FC:
    rts             ; 91FC 60
; ----------------------------------------------------------------------------
.L_91FD:
    lda $79F0   ; 91FD AD F0 79
    clc         ; 9200 18
    adc <$06 ; 9201 65 06
    cmp $79F1   ; 9203 CD F1 79
    bcc .L_91F9   ; 9206 90 F1
    sbc $79F1   ; 9208 ED F1 79
    bcs .L_91F9   ; 920B B0 EC  ;;always satified.
*/
$920d:
}
```


