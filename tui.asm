#importonce
// http://petscii.krissz.hu

#import "tui.asm"
#import "tui-panel.asm"

menu_screen_init:
	// set to 25 line extended color text mode and turn on the screen
	lda #$5B
	sta $D011
	// disable SHIFT-Commodore
	lda #$80
	sta $0291
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
    jsr panel_vertical_leftl_render
    jsr panel_vertical_leftr_render
    jsr panel_vertical_rightl_render
    jsr panel_vertical_rightr_render
    jsr input_line_empty_render
    jsr actions_line_render
    ldx #state_left_panel
    jsr panel_content_render
    jsr panel_header_render
    jsr panel_footer_render
    ldx #state_right_panel
    jsr panel_content_render
    jsr panel_header_render
    jsr panel_footer_render
    jsr activate_left_panel_func
    rts

/*
Copies rectangle from source buffer to destination buffer
render_source_meta: pointer source buffer structure metainformation:
  width, height, 
  sourceCharPtr, targetCharPtr, 
  sourceColorPtr, targetColorPtr
$fb/$fc render_source_meta_ptr
X: <destroyed>
Y: <destroyed>
A: <destroyed>
return: -
*/
render:
    cld
    ldy #$00
    lda ($fb),y  // width
    sta r_width + 1
    sta r_width2 + 1
    iny
    lda ($fb),y  // height
    sta r_height + 1
    iny
	lda ($fb),y  // chars from
	sta r_src_char + 1
    iny
	lda ($fb),y
	sta r_src_char + 2
    iny
	lda ($fb),y  // chars target $0400 + position
	sta r_trg_char + 1
    iny
	lda ($fb),y
	sta r_trg_char + 2
    iny
	lda ($fb),y  // color from
	sta r_src_color + 1
    iny
	lda ($fb),y
	sta r_src_color + 2
    iny
	lda ($fb),y  // color target $d800 + position
	sta r_trg_color + 1
    iny
	lda ($fb),y
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
    sta $fb
    lda #>menu_line_meta
    sta $fc
    jsr render
    rts


input_line_empty_render:
    lda #<input_line_empty_meta
    sta $fb
    lda #>input_line_empty_meta
    sta $fc
    jsr render
    rts

input_line_upld_render:
    lda #<input_line_upld_meta
    sta $fb
    lda #>input_line_upld_meta
    sta $fc
    jsr render
    rts

input_line_dnld_render:
    lda #<input_line_dnld_meta
    sta $fb
    lda #>input_line_dnld_meta
    sta $fc
    jsr render
    rts

input_line_cdir_render:
    lda #<input_line_cdir_meta
    sta $fb
    lda #>input_line_cdir_meta
    sta $fc
    jsr render
    rts

actions_line_render:
    lda #<actions_line_meta
    sta $fb
    lda #>actions_line_meta
    sta $fc
    jsr render
    rts



/* Given the state in X (what input is active) load $fb/$fc pointer to meta data
input:
  X: state. Can be done as 'ldx current_state' before calling this routine
return:
  $fb/$fc pointer to meta data of current input
*/
load_x_state_meta_vector:
    pha
    lda state_meta_ptr_lo,x
    sta $fb
    lda state_meta_ptr_hi,x
    sta $fc
    pla
    rts

/* Given the current state (what input is active) load $fb/$fc pointer to meta data
return:
  $fb/$fc pointer to meta data of current input
*/
load_current_state_meta_vector:
    pha
    txa
    pha
    ldx current_state
    lda state_meta_ptr_lo,x
    sta $fb
    lda state_meta_ptr_hi,x
    sta $fc
    pla
    tax
    pla
    rts

//~~~~~~~~~~~ Metadata pointers ~~~~~~~~~~~~~~~
// current_state for playing role of an index
state_meta_ptr_lo:
.byte <panel_left_backend_meta  // 0
.byte <panel_right_backend_meta // 1
.byte <input_field_upld_from    // 2
.byte <input_field_upld_to      // 3
.byte <input_field_upld_file    // 4
.byte <input_field_upld_type    // 5
.byte <input_field_dnld_to      // 6
.byte <input_field_cdir_name    // 7

state_meta_ptr_hi:
.byte >panel_left_backend_meta
.byte >panel_right_backend_meta
.byte >input_field_upld_from
.byte >input_field_upld_to
.byte >input_field_upld_file
.byte >input_field_upld_type
.byte >input_field_dnld_to
.byte >input_field_cdir_name

//~~~~~~~~~~ Screens ~~~~~~~~~~~~~~~
menu_line_meta:
    .byte   40, 1  // width, height
    .word   menu_line_char_data  // sourceCharPtr
    .word   default_screen_memory  // targetCharPtr
    .word   menu_line_color_data  // sourceColorPtr
    .word   default_color_memory  // targetColorPtr
menu_line_char_data:  // 20 per ass line
	.byte	$8C, $C5, $C6, $D4, $E0, $86, $C9, $CC, $C5, $E0, $83, $CD, $C4, $E0, $8F, $D0, $D4, $C9, $CF, $CE, $D3, $E0, $92, $C9, $C7, $C8, $D4, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0
menu_line_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

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

input_line_dnld_meta:
    .byte   40, 1  // width, height
    .word   input_line_dnld_char_data  // sourceCharPtr
    .byte   default_screen_memory_lo + $98, default_screen_memory_hi + $03  // targetCharPtr
    .word   input_line_dnld_color_data  // sourceColorPtr
    .byte   default_color_memory_lo + $98, default_color_memory_hi + $03 // targetColorPtr
input_line_dnld_char_data:
	.byte	$04, $0f, $17, $0e, $0c, $0f, $01, $04, $20, $14, $0f, $20, $24, $60, $60, $60, $60, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
input_line_dnld_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

input_line_cdir_meta:
    .byte   40, 1  // width, height
    .word   input_line_cdir_char_data  // sourceCharPtr
    .byte   default_screen_memory_lo + $98, default_screen_memory_hi + $03  // targetCharPtr
    .word   input_line_cdir_color_data  // sourceColorPtr
    .byte   default_color_memory_lo + $98, default_color_memory_hi + $03 // targetColorPtr
input_line_cdir_char_data:
	.byte	$03, $12, $05, $01, $14, $05, $20, $0e, $05, $17, $20, $04, $09, $12, $05, $03, $14, $0f, $12, $19, $3a, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $20, $20, $20
input_line_cdir_color_data:
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


