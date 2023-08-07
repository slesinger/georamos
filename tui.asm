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

/*
Copies rectangle from source buffer to destination buffer
render_source_meta: pointer source buffer structure metainformation:
  width, height, 
  sourceCharPtr, targetCharPtr, 
  sourceColorPtr, targetColorPtr
$f5-$f6 render_source_meta_ptr
X: <destroyed>
Y: <destroyed>
A: <destroyed>
return: -
*/
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


/*
Change background color from bg2 to bg3 and show cursor
$f5, $f6: vector input field metadata
X: <untouched>
Y: <preserved>
A: <preserved>
return: -
*/
activate_input_field:
    pha
    tya
    pha

    ldy #16
    lda ($f5), y  // get lo nibble of char memory
    sta $f7
    iny
    lda ($f5), y  // get hi nibble of char memory
    sta $f8
    ldy #19
    lda ($f5), y  // get field length
    sta aif_len + 1
    ldy #$00
!:  lda ($f7),y
    eor #%11000000
    sta ($f7),y
    iny
aif_len:
    cpy #$ff  // updated real time
    bne !-

    ldy #18  // cursor position pointer
    lda ($f5), y  // get cursor position
    tay
    lda ($f7), y  // get char from char memory
    and #%00111111  // pure letters
    ora #%11000000  // cyan background
    sta ($f7), y  // indicate cursor position
    pla
    tay
    pla
    rts


/*
Change background color to bg2, remove cursor
$f5, $f6: vector input field metadata
X: <untouched>
Y: <preserved>
A: <preserved>
return: -
*/
deactivate_input_field:
    pha
    tya
    pha
    ldy #16
    lda ($f5), y  // get lo nibble of char memory
    sta $f7
    iny
    lda ($f5), y  // get hi nibble of char memory
    sta $f8
    ldy #19
    lda ($f5), y  // get field length
    sta dif_len + 1
    ldy #$00
!:  lda ($f7),y
    and #%00111111
    eor #%01000000
    sta ($f7),y
    iny
dif_len:
    cpy #$ff  // updated real time
    bne !-
    pla
    tay
    pla
    rts


/*
Enter activate input, GETIN loop, set cursor position, handle arrow keys, excape, enter for next field
current_state: indicates what input field to focus, see state .enum
X: <?>
Y: <?>
A: return
return: A: 0: escape, 1: enter
*/
focus_input_field:
    jsr load_current_input_field_vector
    jsr activate_input_field

    // set cursor  (by adding $80)
    // activate this
    // deactivate others
    // read keys and dispatch
input_read_key:
    jsr GETIN           // non-blockin read key
    beq input_read_key
    cmp #$1d            // right cursor
    beq input_arrow_right_handler
    cmp #$9d            // left cursor
    beq input_arrow_left_handler
    cmp #$14            // delete
    beq input_arrow_left_handler
    cmp #$5f            // arrow left to escape  
    beq input_escape_handler
    cmp #$0d            // enter to commit form
    beq input_enter_handler
    cmp #$8d            // shift + return as tab, next input
    beq next_upld_input_handler
    cmp #$20            // low boundary for accpeted keys
    bcc input_read_key  // if lower then jump
    cmp #$5f            // high boundary for accpted keys
    bcc input_letter_handler  // if within range then jump
    jmp input_read_key
input_arrow_left_handler:
    jsr cursor_move_left
    jmp input_read_key
input_arrow_right_handler:
    jsr cursor_move_right
    jmp input_read_key
input_letter_handler:
    jsr load_current_input_field_vector
    jsr input_letter_handler_impl
    jmp input_read_key
input_enter_handler:
    jsr input_line_empty_render
    jsr activate_left_panel_func
    lda #$01
    rts
input_escape_handler:
    lda #$00
    rts


next_upld_input_handler:
    jsr next_upld_input_handler_impl
    jmp input_read_key

next_upld_input_handler_impl:
    lda current_state
    // if state is upload from, then activate upload to
    cmp #state_upld_from
    bne !+
    jsr load_current_input_field_vector
    jsr deactivate_input_field
    lda #state_upld_to  // new input field
    sta current_state
    jsr load_current_input_field_vector
    jsr activate_input_field
    jmp nuihi_end
    // if state is upload to, then activate upload file
!:  cmp #state_upld_to
    bne !+
    jsr load_current_input_field_vector
    jsr deactivate_input_field
    lda #state_upld_file  // new input field
    sta current_state
    jsr load_current_input_field_vector
    jsr activate_input_field
    jmp nuihi_end
    // if state is upload file, then activate upload type
!:  cmp #state_upld_file
    bne !+
    jsr load_current_input_field_vector
    jsr deactivate_input_field
    lda #state_upld_type  // new input field
    sta current_state
    jsr load_current_input_field_vector
    jsr activate_input_field
    jmp nuihi_end
    // if state is upload type, then activate upload from
!:  cmp #state_upld_type
    bne !+
    jsr load_current_input_field_vector
    jsr deactivate_input_field
    lda #state_upld_from  // new input field
    sta current_state
    jsr load_current_input_field_vector
    jsr activate_input_field
    jmp nuihi_end
nuihi_end:
    rts


/*
Based on current state, resolve input field vector metadata and load to $f5/$f6
current_state: see state .enum
return: $f5, $f6: vector of input field metadata
*/
load_current_input_field_vector:
    pha
    lda current_state
    jsr load_state_input_field_vector
    pla
    rts

/*
Load pointer $f5/$f6 to input field vector metadata indicated in A
A: state, see state .enum
return: $f5, $f6: vector of input field metadata
*/
load_state_input_field_vector:
    cmp #state_upld_from
    bne !+
    lda #<input_field_upld_from
    sta $f5
    lda #>input_field_upld_from
    sta $f6
    jmp load_current_input_field_vector_end
!:  cmp #state_upld_to
    bne !+
    lda #<input_field_upld_to
    sta $f5
    lda #>input_field_upld_to
    sta $f6
    jmp load_current_input_field_vector_end

!:  cmp #state_upld_file
    bne !+
    lda #<input_field_upld_file
    sta $f5
    lda #>input_field_upld_file
    sta $f6
    jmp load_current_input_field_vector_end
!:  cmp #state_upld_type
    bne !+
    lda #<input_field_upld_type
    sta $f5
    lda #>input_field_upld_type
    sta $f6
    jmp load_current_input_field_vector_end
!:
load_current_input_field_vector_end:
    rts

/*
Move cursor to right in current input field
current_state: see state .enum
return: -
*/
cursor_move_right:
    jsr load_current_input_field_vector
    // set pointer to char memory
    ldy #16
    lda ($f5), y  // get lo nibble of char memory
    sta cmr0 + 1
    sta cmr1 + 1
    sta cmr2 + 1
    sta cmr3 + 1
    iny
    lda ($f5), y  // get hi nibble of char memory
    sta cmr0 + 2
    sta cmr1 + 2
    sta cmr2 + 2
    sta cmr3 + 2
    ldy #18  // cursor position pointer
    lda ($f5), y  // get cursor position
    tax
    inx
    txa
    // check if cursor is at the end of input field
    ldy #19
    cmp ($f5), y  // compare cursor position to field length
    beq cmr_next_field  // if cursor position is equal the length then skip to next input field
    // if not at the end of input field then move cursor to right
    tay  // old cursor position
    dey
    // hide cursor
cmr0:lda $ffff, y
    and #%00111111  // pure letters
    ora #%10000000  // white background
cmr1:sta $ffff, y  // write input char to char memory
    // show cursor
    iny  // increment cursor position
cmr2:lda $ffff, y
    and #%00111111  // pure letters
    ora #%11000000  // white background
cmr3:sta $ffff, y  // write input char to char memory
    tya
    ldy #18  // cursor position pointer
    sta ($f5), y  // save new cursor position
    rts
cmr_next_field:
    jsr next_upld_input_handler_impl
    rts

/*
Move cursor to left in current input field
current_state: see state .enum
return: -
*/
cursor_move_left:
    jsr load_current_input_field_vector
    // set pointer to char memory
    ldy #16
    lda ($f5), y  // get lo nibble of char memory
    sta cml0 + 1
    sta cml1 + 1
    sta cml2 + 1
    sta cml3 + 1
    iny
    lda ($f5), y  // get hi nibble of char memory
    sta cml0 + 2
    sta cml1 + 2
    sta cml2 + 2
    sta cml3 + 2
    ldy #18  // cursor position pointer
    lda ($f5), y  // get cursor position
    cmp #$00  // compare cursor position to beginning of the field
    beq cmr_prev_field  // if cursor position is equal the length then skip to prev input field
    // hide cursor
    tay
cml0:lda $ffff, y
    and #%00111111  // pure letters
    ora #%10000000  // white background
cml1:sta $ffff, y  // write input char to char memory
    // show cursor
    dey  // increment cursor position
cml2:lda $ffff, y
    and #%00111111  // pure letters
    ora #%11000000  // white background
cml3:sta $ffff, y  // write input char to char memory
    tya
    ldy #18  // cursor position pointer
    sta ($f5), y  // save new cursor position
cmr_prev_field:  // jump to previous field is not implemented
    rts

/*
Write A to screen, to input field buffer, validate input, may skip to next input field
$f5, $f6: vector of input field metadata
A: input character from keypress
return: -
*/
input_letter_handler_impl:
    // prepare char memory pointer
    pha
    ldy #16
    lda ($f5), y  // get lo nibble of char memory
    sta !+ + 1
    iny
    lda ($f5), y  // get hi nibble of char memory
    sta !+ + 2
    ldy #18  // cursor position pointer
    lda ($f5), y  // get cursor position
    tay
    pla
    sta ($f5), y  // write input char to input field data as petscii
    ora #%10000000  // white background
!:  sta $ffff, y  // write input char to char memory
    jsr cursor_move_right
    rts



input_fields:
input_field_upld_from:  // metadata
    .fill 16, $20  // buffer for data with spaces         +0
    .word $079e  // pointer to char memory within $0400   +16
    .byte 00  // cursor position within field             +18
    .byte 4  // length of input field                     +19
    .word input_field_upld_to  // pointer to next input field metadata   +20
input_field_upld_to:  // metadata
    .fill 16, $20  // buffer for data with spaces
    .word $07a3  // pointer to char memory within $0400
    .byte 00  // cursor position within field
    .byte 4  // length of input field
    .word input_field_upld_file  // pointer to next input field metadata
input_field_upld_file:  // metadata
    .fill 16, $20  // buffer for data with spaces
    .word $07ac  // pointer to char memory within $0400
    .byte 00  // cursor position within field
    .byte 16  // length of input field
    .word input_field_upld_type  // pointer to next input field metadata
input_field_upld_type:  // metadata
    .fill 16, $20  // buffer for data with spaces
    .word $07bd  // pointer to char memory within $0400
    .byte 00  // cursor position within field
    .byte 3  // length of input field
    .word input_field_upld_from  // pointer to next input field metadata


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


//~~~~~~~~~~ Screens ~~~~~~~~~~~~~~~
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


