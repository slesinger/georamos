#importonce

panel_header_left_render:
    lda #<default_screen_memory + 40  // start of second line
    sta panel_header_meta + 4   // targetCharPtr
    lda #<default_color_memory + 40
    sta panel_header_meta + 8   // targetColorPtr
    lda #<panel_header_meta
    sta $f5
    lda #>panel_header_meta
    sta $f6
    jsr render
    rts

panel_header_right_render:
    lda #<default_screen_memory + 40 + 20 // start of mid second line
    sta panel_header_meta + 4   // targetCharPtr
    lda #<default_color_memory + 40 + 20
    sta panel_header_meta + 8   // targetColorPtr
    lda #<panel_header_meta
    sta $f5
    lda #>panel_header_meta
    sta $f6
    jsr render
    rts

panel_vertical_leftl_render:
    lda #<default_screen_memory + 2 * 40  // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $f5
    lda #>panel_vertical_meta
    sta $f6
    jsr render
    rts

panel_vertical_leftr_render:
    lda #<default_screen_memory + 2 * 40 + 19 // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40 + 19
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $f5
    lda #>panel_vertical_meta
    sta $f6
    jsr render
    rts

panel_vertical_rightl_render:
    lda #<default_screen_memory + 2 * 40 + 20 // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40 + 20
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $f5
    lda #>panel_vertical_meta
    sta $f6
    jsr render
    rts

panel_vertical_rightr_render:
    lda #<default_screen_memory + 2 * 40 + 39 // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40 + 39
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $f5
    lda #>panel_vertical_meta
    sta $f6
    jsr render
    rts

panel_footer_left_render:
    lda #default_screen_memory_lo + $70  // start of 23line
    sta panel_header_meta + 4   // targetCharPtr
    lda #default_screen_memory_hi + $03  // start of 23line
    sta panel_header_meta + 5   // targetCharPtr

    lda #<default_color_memory_lo + $70
    sta panel_header_meta + 8   // targetColorPtr
    lda #>default_color_memory_hi + $03
    sta panel_header_meta + 9   // targetColorPtr

    lda #<panel_header_meta
    sta $f5
    lda #>panel_header_meta
    sta $f6
    jsr render
    rts

panel_footer_right_render:
    lda #default_screen_memory_lo + $70 + 20  // mid of 23line
    sta panel_header_meta + 4   // targetCharPtr
    lda #default_screen_memory_hi + $03  // start of 23line
    sta panel_header_meta + 5   // targetCharPtr

    lda #<default_color_memory_lo + $70 + 20
    sta panel_header_meta + 8   // targetColorPtr
    lda #>default_color_memory_hi + $03
    sta panel_header_meta + 9   // targetColorPtr

    lda #<panel_header_meta
    sta $f5
    lda #>panel_header_meta
    sta $f6
    jsr render
    rts

panel_content_left_render:
    rts

panel_content_right_render:
    rts

activate_left_panel_func:
    lda #state_left_panel
    sta current_state
    lda #$28  // outline left panel
    sta $f5
    lda #$d8
    sta $f6
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$01  // white
    jsr activate_panel_horizontal_border
    lda #$3c  // outline right panel
    sta $f5
    lda #$d8
    sta $f6
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$0e  // light blue
    jsr activate_panel_horizontal_border

    // jsr panel_content_left_render
    // TODO render cursor
    rts

activate_right_panel_func:
    lda #state_right_panel
    sta current_state
    lda #$28  // outline left panel
    sta $f5
    lda #$d8
    sta $f6
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$0e  // light blue
    jsr activate_panel_horizontal_border
    lda #$3c  // outline right panel
    sta $f5
    lda #$d8
    sta $f6
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$01  // white
    jsr activate_panel_horizontal_border
    // jsr panel_content_right_render
    // TODO render cursor
    rts

/*
Change background color from bg2 to bg3
$f5, $f6: vector of char memory
activate_panel_horizontal_border_len+1: length of input field
X: <untouched>
Y: <destroyed>
A: text color
return: -
*/
activate_panel_horizontal_border:
    ldy #$00
!:  sta ($f5),y
    iny
activate_panel_horizontal_border_len:
    // cpy #input_upld_from_len  // updated real time
    // bne !-
    rts



panel_header_meta:
    .byte   20, 1  // width, height
    .word   panel_header_char_data  // sourceCharPtr
    .word   default_screen_memory  // targetCharPtr
    .word   panel_header_color_data  // sourceColorPtr
    .word   default_color_memory  // targetColorPtr
panel_header_char_data:
	.byte	$2B, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2B
panel_header_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

panel_vertical_meta:
    .byte   1, 20  // width, height
    .word   panel_vertical_char_data  // sourceCharPtr
    .word   default_screen_memory  // targetCharPtr
    .word   panel_vertical_color_data  // sourceColorPtr
    .word   default_color_memory  // targetColorPtr
panel_vertical_char_data:
    .byte   $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21
panel_vertical_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

