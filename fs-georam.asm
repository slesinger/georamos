#importonce

#import "shared.asm"
#import "fs.asm"


// see interface in fs_download
fs_georam_download:
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

    lda fs_download_memory_address +1  // check if address specified
    cmp #$ff
    beq fgd_no_address
    lda fs_download_memory_address  // address is specified
    sta geo_copy_from_trgPtr +1
    sta $c1
    lda fs_download_memory_address +1
    sta geo_copy_from_trgPtr +2
    sta $c2
    jmp fgd_address_done
fgd_no_address:
    lda dfmi_original_addr  // only hi nibble
    sta geo_copy_from_trgPtr +2
    sta $c2
    cmp #$08
    bne !+
    lda #$01
    sta $c1
!:  lda #$00
    sta geo_copy_from_trgPtr +1
fgd_address_done:

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
    adc #$00
    sta fs_download_last_address +1
    clc
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


fs_georam_upload:
    lda fs_upload_memory_from
    sta write_file_srcPtr + 1  // set address for write_file will take data from memory
    lda fs_upload_memory_from +1
    sta write_file_srcPtr + 2
    sta create_file_hi_original_address +1

    lda fs_upload_memory_to
    sta geo_copy_to_geo_last_block_bytes
    inc fs_upload_memory_to +1
    lda fs_upload_memory_to +1    // hi nibble of $TO. Number of blocks to copy is $TO_hi - $FROM_hi
    sec
    sbc write_file_srcPtr + 2
    sta create_file_parent_size_blocks +1
    sta write_file_count_blocks  // count for write_file loop

    lda fs_upload_directory_id
    sta create_file_parent_directory_id +1

    lda fs_upload_filenamePtr
    sta create_file_parent_filename +1
    lda fs_upload_filenamePtr +1
    sta create_file_parent_filename +2

    lda fs_upload_type
    sta create_file_parent_file_flags +1

    jsr create_file  // > $fb/$fc sector/block of data to write
    jsr write_file
    clc
    rts
