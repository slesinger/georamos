#importonce

#import "shared.asm"
#import "fs.asm"


// see interface in fs_download
fs_georam_download:
    lda fs_download_memory_address
    sta geo_copy_from_trgPtr +1
    lda fs_download_memory_address +1
    sta geo_copy_from_trgPtr +2

    lda fs_download_backend_type
    and #%00111111  // get just sector part of it
    ldx fs_download_dirfile_major  // block 0-255
    jsr georam_set  // change to point to file table
    lda fs_download_dirfile_minor  // entry pointer
    clc
    adc #18  // skip  to original address (+18) and (+19) bytes of filetable record to point sector pointer to first FAT
    tax
    lda pagemem, x  // first sector of file
    sta dfmi_original_addr
    inx // now point to first FAT
    lda pagemem, x  // first sector of file
    sta fgd_next_sector
    inx
    lda pagemem, x  // first block of file
    sta fgd_next_block

fgd_loop:
    lda fgd_next_sector
    sta fgd_current_sector
    lda fgd_next_block
    sta fgd_current_block
    jsr resolve_next_sector_block // check if this is last block
    lda fgd_next_sector
    cmp #$00
    beq fgd_last_block
    ldx fgd_current_sector
    lda fgd_current_block
    ldy #$01 // copy 1 block
    jsr geo_copy_from_geo  // download block to memory, this is the actual work
    // if not last block
    // inc geo_copy_from_trgPtr + 2   // increase target memory hi nibble
    jmp fgd_loop  // repeat
    // if last block
fgd_last_block:
    ldx fgd_current_block
    lda fgd_current_sector
    jsr georam_set  // change to point to file table
    lda geo_copy_from_trgPtr +1
    sta fgs_download_trgPtr +1
    lda geo_copy_from_trgPtr +2
    sta fgs_download_trgPtr +2
    lda fgd_next_block  // contains number of bytes to copy within last block
    sta dfmi_last_block_bytes +1
    ldx #$FF  // copy remaining bytes in last block
!:  inx
    lda pagemem, x
fgs_download_trgPtr:
    sta $ffff,x
dfmi_last_block_bytes:
    cpx #$ff
    bne !-
    txa                         // calculate last byte address
    adc fgs_download_trgPtr +1
    sta fs_download_last_address
    lda fgs_download_trgPtr +2
    sta fs_download_last_address +1
    rts
fgd_current_sector: .byte $00
fgd_current_block: .byte $00
fgd_next_sector: .byte $00
fgd_next_block: .byte $00


/* Populate fgd_next_sector and fgd_next_block with next FAT record
input: fgd_current_sector, fgd_current_block
return: fgd_next_sector, fgd_next_block
*/
resolve_next_sector_block:
    lda fgd_current_sector
    ora #%10000000  // +128
    tax  // block 128-190: FAT sector pointer table (63 blocks)
    dex
    lda #$00  // sector 0
    jsr georam_set  // change to point to file table
    ldy fgd_current_block
    lda pagemem, y  // get next sector
    sta fgd_next_sector
    lda fgd_current_sector
    ora #%11000000  // +192
    tax  // block 192-254: FAT block pointer table (63 blocks)
    dex
    lda #$00  // sector 0
    jsr georam_set  // change to point to file table
    ldy fgd_current_block
    lda pagemem, y  // get next sector
    sta fgd_next_block
    rts


