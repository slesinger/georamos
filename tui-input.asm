#importonce

#import "tui.asm"

/*
Change background color from bg2 to bg3 and show cursor
$fb/$fc: vector input field metadata
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
    lda ($fb), y  // get lo nibble of char memory
    sta $f7
    iny
    lda ($fb), y  // get hi nibble of char memory
    sta $f8
    ldy #19
    lda ($fb), y  // get field length
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
    lda ($fb), y  // get cursor position
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
$fb/$fc: vector input field metadata
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
    lda ($fb), y  // get lo nibble of char memory
    sta $f7
    iny
    lda ($fb), y  // get hi nibble of char memory
    sta $f8
    ldy #19
    lda ($fb), y  // get field length
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
Based on current state, resolve input field vector metadata and load to $fb/$fc
current_state: see state .enum
return: $fb/$fc: vector of input field metadata
*/
load_current_input_field_vector:
    pha
    lda current_state
    jsr load_state_input_field_vector
    pla
    rts

/*
Load pointer $fb/$fc to input field vector metadata indicated in A
A: state, see state .enum
return: $fb/$fc: vector of input field metadata
*/
load_state_input_field_vector:
    cmp #state_upld_from
    bne !+
    lda #<input_field_upld_from
    sta $fb
    lda #>input_field_upld_from
    sta $fc
    jmp load_current_input_field_vector_end
!:  cmp #state_upld_to
    bne !+
    lda #<input_field_upld_to
    sta $fb
    lda #>input_field_upld_to
    sta $fc
    jmp load_current_input_field_vector_end

!:  cmp #state_upld_file
    bne !+
    lda #<input_field_upld_file
    sta $fb
    lda #>input_field_upld_file
    sta $fc
    jmp load_current_input_field_vector_end
!:  cmp #state_upld_type
    bne !+
    lda #<input_field_upld_type
    sta $fb
    lda #>input_field_upld_type
    sta $fc
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
    lda ($fb), y  // get lo nibble of char memory
    sta cmr0 + 1
    sta cmr1 + 1
    sta cmr2 + 1
    sta cmr3 + 1
    iny
    lda ($fb), y  // get hi nibble of char memory
    sta cmr0 + 2
    sta cmr1 + 2
    sta cmr2 + 2
    sta cmr3 + 2
    ldy #18  // cursor position pointer
    lda ($fb), y  // get cursor position
    tax
    inx
    txa
    // check if cursor is at the end of input field
    ldy #19
    cmp ($fb), y  // compare cursor position to field length
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
    sta ($fb), y  // save new cursor position
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
    lda ($fb), y  // get lo nibble of char memory
    sta cml0 + 1
    sta cml1 + 1
    sta cml2 + 1
    sta cml3 + 1
    iny
    lda ($fb), y  // get hi nibble of char memory
    sta cml0 + 2
    sta cml1 + 2
    sta cml2 + 2
    sta cml3 + 2
    ldy #18  // cursor position pointer
    lda ($fb), y  // get cursor position
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
    sta ($fb), y  // save new cursor position
cmr_prev_field:  // jump to previous field is not implemented
    rts

/*
Write A to screen, to input field buffer, validate input, may skip to next input field
$fb/$fc: vector of input field metadata
A: input character from keypress
return: -
*/
input_letter_handler_impl:
    // prepare screen memory pointer
    pha
    ldy #16
    lda ($fb), y  // get lo nibble of screen memory
    sta !+ +1
    iny
    lda ($fb), y  // get hi nibble of screen memory
    sta !+ +2
    ldy #18  // cursor position pointer
    lda ($fb), y  // get cursor position
    tay
    pla
    sta ($fb), y  // write input char to input field data as key scancode
    ora #%10000000  // white background
!:  sta $ffff, y  // write input char to screen memory
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

