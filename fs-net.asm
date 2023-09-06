#importonce

#import "shared.asm"
#import "fs.asm"

// see interface in fs_download
fs_net_download:
    ldx fs_download_dirfile_minor
    lda pagemem, x  // get file flags
    and #%11000000  // isolate flags
    cmp #%01000000  // check if is directory
    bne !+          // skip directory
    rts
!:  pha
    inx
    inx
    txa
    sta $fe
    lda #$de
    sta $ff
    pla
    jsr make_filename_with_extension
    bcs fnd_unsupported_extension
    pha  // save filename length
    lda fs_download_memory_address+1
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
    pla
    jsr network_get

    lda $c3
    sta fs_upload_size_uploaded
    lda $c4
    sta fs_upload_size_uploaded +1
    rts
fnd_unsupported_extension:
    lda #$06
    sta status_code
    sec
    jsr status_print
    rts


// see interface in fs_upload
fs_net_upload:
    lda fs_upload_filenamePtr
    sta $fe
    lda fs_upload_filenamePtr+1
    sta $ff
    lda fs_upload_type
    jsr make_filename_with_extension
    pha  // save filename length

    lda fs_upload_memory_from
    sta $c1
    lda fs_upload_memory_from+1
    sta $c2
    // fs_upload_memory_to - fs_upload_memory_from => $c1/$c2 as payload size
    lda fs_upload_memory_to
    sec
    sbc fs_upload_memory_from
    sta command_put_payload_size
    lda fs_upload_memory_to+1
    sbc fs_upload_memory_from+1
    sta command_put_payload_size +1

    pla  // restore filename length
    jsr network_put
    lda $c3
    sta fs_upload_size_uploaded
    lda $c4
    sta fs_upload_size_uploaded+1
    rts


/* When filename.ext parameter is needed for send_command this function takes
   filename and file type from file table entry and copies the to command_get_filename
   Final filename is null terminated.
inputs:
    A: file type
    $fe/$ff - vector of filename
return:
    A: length of filename with extension
*/
make_filename_with_extension:
!:  pha  // save file type
    ldy #$00
!:  lda ($fe),y
    sta command_get_filename, y
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
    lda #$00  // null terminated
    sta command_get_filename+3, y
    tya
    rts
fnd_seq:
    cmp #%11000000  // SEQ
    bne mfwe_unsupported_extension
    lda #$2e  // .
    sta command_get_filename, y
    iny
    lda #$73  // s
    sta command_get_filename, y
    // iny
    lda #$65  // e
    sta command_get_filename+1, y
    // iny
    lda #$71  // q
    sta command_get_filename+2, y
    // iny
    lda #$00  // null terminated
    sta command_get_filename+3, y
    tya
    rts
mfwe_unsupported_extension:
    sec
    rts
