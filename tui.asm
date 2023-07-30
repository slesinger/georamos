#importonce
// http://petscii.krissz.hu

menu_screen_init:
	// set to 25 line extended color text mode and turn on the screen
	lda #$5B
	sta $D011
	// disable SHIFT-Commodore
	lda #$80
	sta $0291
	// set screen memory ($0400) and charset bitmap offset ($2000)
	// lda #$18
	// sta $D018
	// set border color
	lda #$0E
	sta $D020
	// set background color
	lda #$06
	sta $D021
	// set extended bg color 1
	lda #$0F
	sta $D022
	// set extended bg color 2
	lda #$01
	sta $D023
	// set extended bg color 3
	lda #$03
	sta $D024
    jsr menu_line_render
    jsr panel_header_left_render
    jsr panel_header_right_render
    jsr panel_vertical_leftl_render
    jsr panel_vertical_leftr_render
    jsr panel_vertical_rightl_render
    jsr panel_vertical_rightr_render
    jsr panel_footer_left_render
    jsr panel_footer_right_render
    jsr input_line_empty_render
    jsr actions_line_render
    jsr panel_content_left_render
    jsr panel_content_right_render
    rts

// Copies rectangle from source buffer to destination buffer
// render_source_meta: pointer source buffer structure metainformation:
//   width, height, 
//   sourceCharPtr, targetCharPtr, 
//   sourceColorPtr, targetColorPtr
// $f5-$f6 render_source_meta_ptr
// X: <destroyed>
// Y: <destroyed>
// A: <destroyed>
// return: -
render:
    cld
    ldy #$00
    lda ($f5),y  // width
    sta r_width + 1
    sta r_width2 + 1
    iny
    lda ($f5),y  // height
    sta r_height + 1
    iny
	lda ($f5),y  // chars from
	sta r_src_char + 1
    iny
	lda ($f5),y
	sta r_src_char + 2
    iny
	lda ($f5),y  // chars target $0400 + position
	sta r_trg_char + 1
    iny
	lda ($f5),y
	sta r_trg_char + 2
    iny
	lda ($f5),y  // color from
	sta r_src_color + 1
    iny
	lda ($f5),y
	sta r_src_color + 2
    iny
	lda ($f5),y  // color target $d800 + position
	sta r_trg_color + 1
    iny
	lda ($f5),y
	sta r_trg_color + 2

r_width:
    ldx #$28  // updated in runtime
r_height:
    ldy #$02  // updated in runtime

r_copy_loop_start:
r_src_char:
    lda $ffff  // copy character // updated in runtime
r_trg_char:
    sta $0400  // updated in runtime
    inc r_src_char + 1  //inc source pointer
    bne !+
    inc r_src_char + 2  // if over flow, increment hi nibble too
!:  inc r_trg_char + 1  //inc target pointer
    bne !+
    inc r_trg_char + 2  // if over flow, increment hi nibble too
!:
r_src_color:
    lda $ffff  // copy color // updated in runtime
r_trg_color:
    sta $d800  // updated in runtime
    inc r_src_color + 1  //inc source pointer
    bne !+
    inc r_src_color + 2  // if over flow, increment hi nibble too
!:  inc r_trg_color + 1  //inc target pointer
    bne !+
    inc r_trg_color + 2  // if over flow, increment hi nibble too
!:  dex  // move to next char on x
    bne r_copy_loop_start

    lda #40  // screen width
    clc
    sbc r_width + 1  // - width
    adc r_trg_char + 1
    sta r_trg_char + 1
    bcc !+
    inc r_trg_char + 2
!:  lda #40 // screen width
    sbc r_width + 1  // - width
    adc r_trg_color + 1
    sta r_trg_color + 1
    bcc !+
    inc r_trg_color + 2
!:  dey
    beq y_done
r_width2:
    ldx #$28  // updated in runtime
    jmp r_copy_loop_start
y_done:
    rts


menu_line_render:
    lda #<menu_line_meta
    sta $f5
    lda #>menu_line_meta
    sta $f6
    jsr render
    rts

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

input_line_empty_render:
    lda #<input_line_empty_meta
    sta $f5
    lda #>input_line_empty_meta
    sta $f6
    jsr render
    rts

input_line_upld_render:
    lda #<input_line_upld_meta
    sta $f5
    lda #>input_line_upld_meta
    sta $f6
    jsr render
    rts

actions_line_render:
    lda #<actions_line_meta
    sta $f5
    lda #>actions_line_meta
    sta $f6
    jsr render
    rts



menu_line_meta:
    .byte   40, 1  // width, height
    .word   menu_line_char_data  // sourceCharPtr
    .word   default_screen_memory  // targetCharPtr
    .word   menu_line_color_data  // sourceColorPtr
    .word   default_color_memory  // targetColorPtr
menu_line_char_data:  // 20 per ass line
	.byte	$8C, $C5, $C6, $D4, $E0, $86, $C9, $CC, $C5, $E0, $83, $CF, $CD, $CD, $C1, $CE, $C4, $E0, $8F, $D0, $D4, $C9, $CF, $CE, $D3, $E0, $92, $C9, $C7, $C8, $D4, $E0, $E0, $E0, $C6, $F1, $F6, $F1, $F2, $F8
menu_line_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

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

input_line_empty_meta:
    .byte   40, 1  // width, height
    .word   input_line_empty_char_data  // sourceCharPtr
    .byte   default_screen_memory_lo + $98, default_screen_memory_hi + $03  // targetCharPtr
    .word   input_line_empty_color_data  // sourceColorPtr
    .byte   default_color_memory_lo + $98, default_color_memory_hi + $03 // targetColorPtr
input_line_empty_char_data:
    .byte   $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
input_line_empty_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

input_line_upld_meta:
    .byte   40, 1  // width, height
    .word   input_line_upld_char_data  // sourceCharPtr
    .byte   default_screen_memory_lo + $98, default_screen_memory_hi + $03  // targetCharPtr
    .word   input_line_upld_color_data  // sourceColorPtr
    .byte   default_color_memory_lo + $98, default_color_memory_hi + $03 // targetColorPtr
input_line_upld_char_data:
	.byte	$15, $10, $0C, $04, $20, $24, $60, $60, $60, $60, $2D, $60, $60, $60, $60, $20, $0E, $01, $0D, $05, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $20, $50, $52, $47
input_line_upld_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

actions_line_meta:
    .byte   40, 1  // width, height
    .word   actions_line_char_data  // sourceCharPtr
    .byte   default_screen_memory_lo + $c0, default_screen_memory_hi + $03  // targetCharPtr
    .word   actions_line_color_data  // sourceColorPtr
    .byte   default_color_memory_lo + $c0, default_color_memory_hi + $03 // targetColorPtr
actions_line_char_data:
	.byte	$B1, $C8, $C5, $CC, $D0, $E0, $B2, $D5, $D0, $CC, $C4, $E0, $B3, $C4, $CE, $CC, $C4, $E0, $B5, $C3, $CF, $D0, $D9, $E0, $B6, $CD, $CF, $D6, $C5, $E0, $B7, $CE, $C4, $C9, $D2, $E0, $B8, $C4, $C5, $CC
actions_line_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E


// screen character data
*=$2800
	.byte	$8C, $C5, $C6, $D4, $E0, $86, $C9, $CC, $C5, $E0, $83, $CF, $CD, $CD, $C1, $CE, $C4, $E0, $8F, $D0, $D4, $C9, $CF, $CE, $D3, $E0, $92, $C9, $C7, $C8, $D4, $E0, $E0, $E0, $C6, $F1, $F6, $F1, $F2, $F8
	.byte	$2B, $13, $3A, $2F, $04, $05, $16, $14, $0F, $0F, $0C, $13, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2B, $2B, $07, $3A, $2F, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2B
	.byte	$21, $14, $01, $13, $0D, $20, $37, $2E, $31, $20, $20, $20, $20, $20, $20, $20, $20, $20, $10, $21, $21, $2E, $2E, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $04, $21
	.byte	$21, $06, $02, $36, $34, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $10, $21, $21, $01, $13, $05, $0C, $05, $03, $14, $05, $04, $20, $06, $09, $0C, $05, $20, $20, $20, $10, $21
	.byte	$21, $0D, $09, $03, $12, $0F, $0D, $0F, $0E, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $01, $0E, $0E, $14, $08, $05, $12, $20, $04, $05, $0D, $0F, $20, $20, $20, $20, $20, $10, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $C4, $C1, $D4, $C1, $E0, $C6, $C9, $CC, $C5, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $D3, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $86, $89, $8C, $85, $A0, $83, $95, $92, $93, $8F, $92, $A0, $A0, $A0, $A0, $A0, $A0, $90, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $19, $05, $14, $20, $01, $0E, $0F, $14, $08, $05, $12, $20, $04, $01, $14, $01, $20, $13, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $38, $3A, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $39, $3A, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $14, $0F, $0F, $0C, $13, $20, $0D, $05, $0E, $15, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $0D, $05, $0D, $0F, $12, $19, $20, $0D, $01, $10, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21, $21, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $21
	.byte	$2B, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2B, $2B, $02, $31, $32, $33, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $13, $33, $32, $37, $36, $38, $2B
	.byte	$15, $10, $0C, $04, $20, $24, $60, $60, $60, $60, $2D, $60, $60, $60, $60, $20, $0E, $01, $0D, $05, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $20, $50, $52, $47
	.byte	$B1, $C8, $C5, $CC, $D0, $E0, $B2, $D5, $D0, $CC, $C4, $E0, $B3, $C4, $CE, $CC, $C4, $E0, $B5, $C3, $CF, $D0, $D9, $E0, $B6, $CD, $CF, $D6, $C5, $E0, $B7, $CE, $C4, $C9, $D2, $E0, $B8, $C4, $C5, $CC

// screen color data
*=$2be8
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
