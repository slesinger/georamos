#importonce

#import "shared.asm"
#import "fs.asm"

// see interface in fs_download
fs_net_download:
    ldx fs_download_dirfile_minor
    lda pagemem, x  // get file flags
    and #%11000000  // isolate flags
    sta fs_net_download_filetype
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
fs_net_download_filetype: .byte $00


// see interface in fs_upload
fs_net_upload:
    lda fs_upload_filenamePtr
    sta $fe
    lda fs_upload_filenamePtr+1
    sta $ff
    lda fs_upload_memory_from
    sta $f8
    lda fs_upload_memory_from+1
    sta $f9
    lda fs_upload_type
    jsr make_filename_with_extension
    pha  // save filename length

    // fs_upload_memory_to - fs_upload_memory_from => $c1/$c2 as payload size
    lda fs_upload_memory_to
    sec
    sbc fs_upload_memory_from
    sta command_put_payload_size
    lda fs_upload_memory_to+1
    sbc fs_upload_memory_from+1
    sta command_put_payload_size +1
    lda #$01
    clc
    adc command_put_payload_size  // add 1 because last byte is mean to be included
    sta command_put_payload_size
    lda #$00
    adc command_put_payload_size +1
    sta command_put_payload_size +1
    pla  // restore filename length
    jsr network_put
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
    iny
    lda #$72  // r
    sta command_get_filename, y
    iny
    lda #$67  // g
    sta command_get_filename, y
    iny

    lda fs_upload_memory_from  // append original address for prg
    jsr byte2base16ap
    sta command_get_filename, y
    iny
    txa
    sta command_get_filename, y
    iny
    lda fs_upload_memory_from +1
    jsr byte2base16ap
    sta command_get_filename, y
    iny
    txa
    sta command_get_filename, y
    // iny
    lda #$00  // null terminated
    sta command_get_filename+1, y
    tya
    clc
    rts
fnd_seq:
    cmp #%11000000  // SEQ
    bne mfwe_unsupported_extension
    lda #$2e  // .
    sta command_get_filename, y
    iny
    lda #$73  // s
    sta command_get_filename, y
    iny
    lda #$65  // e
    sta command_get_filename, y
    iny
    lda #$71  // q
    sta command_get_filename, y
    // iny
    lda #$00  // null terminated
    sta command_get_filename+1, y
    tya
    clc
    rts
mfwe_unsupported_extension:
    sec
    rts
