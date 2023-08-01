#importonce

// Check if GEORAM is present TODO
// Check if root directory is present and initialize fs if not
// X: <preserved>
// Y: <untouched>
// A: <preserved>
// return: -
check_fs:
    pha
    txa
    pha
    jsr get_first_dir_entry
    // check DIR flag
    ldx dir_entry_ptr_within_block
    lda $de00, x
    and #$c0  // get 2 highest bits 
    cmp #$40  // check if dir flag is set
    beq !+
    jsr format_fs
    jmp fs_ok
!:  lda $de02, x  // first char of filename
    cmp #$2f  // check if it's a slash
    beq fs_ok
    jsr format_fs
fs_ok:
    pla
    tax
    pla
    rts

// X: <preserved>
// Y: <preserved>
// A: <preserved>
// return: dir_entry_ptr_within_block as low byte, hi byte is #$de
get_first_dir_entry:
    pha
    txa
    pha
    tya
    pha
    // switch geo to sector 0 block 27
    ldy #$00
    ldx #27
    jsr georam_set
    // set dir entry idx to 0
    ldx #$00
    jsr read_dir_entry_within_block
    pla
    tay
    pla
    tax
    pla
    rts

// TBI
get_next_dir_entry:
    rts

// X: index of entry within block (value 0-12)
// Y: <untouched>
// A: <preserved>
// return: dir_entry_ptr_within_block as low byte, hi byte is #$de
read_dir_entry_within_block:
    // multiply index X by 20. shift left 4 times and 
    pha
    txa
    asl
    asl
    asl
    asl
    sta dir_entry_ptr_within_block
    txa
    asl
    asl
    cld
    adc dir_entry_ptr_within_block
    pla
    rts
dir_entry_ptr_within_block: .byte $00


// Assumes geo is set to sector 0 block 27
// Creates root dir entry
// Y: <untouched>
// X: <untouched>
// A: <preserved>
// return: -
format_fs:
    pha
    lda #$40  // dir flag, parent dir = 0
    sta $de00
    lda #$00
    sta $de01  // size
    lda #$2f
    sta $de02  // filename
    lda #$20   // space
    sta $de03
    sta $de04
    sta $de05
    sta $de06
    sta $de07
    sta $de08
    sta $de09
    sta $de0a
    sta $de0b
    sta $de0c
    sta $de0d
    sta $de0e
    sta $de0f
    sta $de10
    sta $de11
    lda #$01  // sector
    sta $de12
    lda #$00  // block
    sta $de13
    // TODO fill rest of block with 0
    pla
    rts
