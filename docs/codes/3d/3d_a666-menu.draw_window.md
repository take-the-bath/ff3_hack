﻿
# $3d:a666 menu.draw_window
> 指定のタイプのメニューウインドウを描画する。枠と中身の両方。

### args:
#### in:
+	u8 x : window_type
+   u8 a : text_id, specifies the text to be rendered in the window

### (pseudo)code:
```js
{
    push(A);
	menu.draw_window_box();   //$aaf1
    return menu.stream_window_contents({text_id: A = pop()});  //fall through into $a66b.
/*
1E:A666:48        PHA
1E:A667:20 F1 AA  JSR field.draw_menu_window_box
1E:A66A:68        PLA
*/
}
```

**fall through**

