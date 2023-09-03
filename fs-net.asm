#importonce

#import "shared.asm"
#import "fs.asm"

// see interface in fs_download
fs_net_download:
    // make filename with extension
    ldx fs_download_dirfile_minor
    lda pagemem, x  // get file flags
    and #%11000000  // isolate flags
    pha  // save file type

    ldx fs_download_dirfile_minor
    inx
    inx
    ldy #$00
!:  lda pagemem,x
    sta command_get_filename, y
    inx
    iny    
    cpy #$10  // 16 chars filename
    bne !-
    // find of filename and append file type
!:  dey
    lda command_get_filename, y
    cmp #$20
    beq !-
    iny  // first empty space
    pla  // file type
    cmp #%10000000  // PRG
    bne fnd_seq
    lda #$2e  // .
    sta command_get_filename, y
    iny
    lda #$70  // p
    sta command_get_filename, y
    // iny
    lda #$72  // r
    sta command_get_filename+1, y
    // iny
    lda #$67  // g
    sta command_get_filename+2, y
    // iny
    jmp fnd_next
fnd_seq:
    cmp #%11000000  // SEQ
    bne fnd_unsupported_extension
    lda #$2e  // .
    sta command_get_filename, y
    iny
    lda #$73  // s
    sta command_get_filename, y
    iny
    lda #$65  // e
    sta command_get_filename+1, y
    iny
    lda #$71  // q
    sta command_get_filename+2, y
    iny

fnd_next:
    lda fs_download_memory_address+2
    cmp #$ff  // address not specified
    bne !+
    lda #$02  // use target address from file
    jmp !++
!:  lda fs_download_memory_address // use address specified by user
    sta $c3
    lda fs_download_memory_address+1
    sta $c4
    lda #$00
!:  sta $b9
    jsr network_get

    lda $c3
    sta fs_download_last_address
    lda $c4
    sta fs_download_last_address +1
    rts
fnd_unsupported_extension:
    lda #$06
    sta status_code
    sec
    jsr status_print
    rts
