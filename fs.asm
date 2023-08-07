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
    lda #$00
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

/* Create file in directory
 X: <?>
 Y: <?>
 A: <?>
create_file_parent_directory_id +1: 0-59
create_file_parent_file_flags +1: $80 PRG, $c0 SEQ
create_file_parent_size_blocks +1: 1-256
create_file_parent_filename +1, +2: ptr to filename, 16chars max, filled with spaces
 return: $f5/$f6 - sector/block pointer to first FAT record
 */
 create_file:
    jsr find_free_fat_entry
    lda $f5
    sta cf_fat_sector_ptr + 1
    lda $f6
    sta cf_fat_block_ptr + 1
    jsr find_first_free_file_entry  // this will also leave $de00 set to point to georam correctly to write file meta entry
    ldy #$00
create_file_parent_directory_id:
    lda #$ff
    and #%00111111  // TODO return error if parent directory id is > 59
create_file_parent_file_flags:
    ora #$ff
    sta ($f5), y  // parent directory id
    iny
create_file_parent_size_blocks:
    lda #$ff
    sta ($f5), y  // size in blocks
    iny
    ldx #$00
create_file_parent_filename:
!:  lda $ffff, x
    sta ($f5), y
    iny
    inx
    cpx #$10
    bne !-
cf_fat_sector_ptr:
    lda #$ff  // sector
    tax
    sta ($f5), y
    iny
cf_fat_block_ptr:
    lda #$ff  // block
    sta ($f5), y
    stx $f5
    sta $f6
    rts

/*
$f5/$f6 - sector/block pointer where to write out data
write_file_srcPtr +1, +2: ptr to data to write
*/
write_file:
    lda #$00
    sta write_file_current_block
wf_block:
    jsr georam_set_f5f6  // switch sector/block to write out data, infered by create_file or find_free_fat_entry
    ldx #$00
write_file_srcPtr:
    lda $ffff,x  // $1000 is fake address, it will be replaced by real address
    sta pagemem,x
    inx
    bne write_file_srcPtr  // copy one full page

    inc write_file_current_block
    lda write_file_current_block
    cmp write_file_count_blocks
    beq wf_last_block  // write next block
    inc write_file_srcPtr +2  // increase memory page to read from
    jsr save_next_to_pointer_table  // save next block pointer to FAT pointer table, 
                                    // return $f5/$f6 as new free sector/block
    jmp wf_block
wf_last_block:
    lda geo_copy_to_geo_last_block_bytes
    sta $f6
    jsr save_eof_to_pointer_table  // sector=0 indicates last block, bloc=remaining bytes
    inc $d020 // confirm done
    rts
write_file_current_block: .byte $ff
write_file_count_blocks: .byte $ff


/* Find first free file entry in directory
return: $f5/$f6 - pointer to file record with $dexx
*/
find_first_free_file_entry:
    // start at sector 0 block 33
    lda #$00
    ldx #33
    jsr georam_set
    // read first file entry
!:  ldx #$00
!:  lda $de00 +18, x  // +18 is offest to sector pointer within file entry
    cmp #$00  // check if file entry is free by checking sector pointer == 0
    beq ffffie_found
    txa
    sec
    adc #20  // skip 20 bytes which is file entry size
    tax
    cpx #240  // 12entries by 20bytes
    bne !-
    jsr georam_next
    lda #128  // first block after file entry table
    cmp geomem_block  // check if out of file entry table
    bne !--
    // no more space to allocate a new file
    lda #$ff
    sta $f5
    sta $f6
    rts
ffffie_found:
    lda geomem_block
    sec
    sbc #33
    stx $f5   // position for file entry relative to $de00
    lda #$de  // position to IO1 page, georam block is set already
    sta $f6   
    rts


/* Find first free FAT entry
return: $f5/$f6 - sector/block to free FAT record, it will destroy $de00 georam position
  $f5/$f6 will be set to $ffff if disk is full
*/
find_free_fat_entry:
    // start at sector 0 block 192
    lda #$00
    ldx #192
    jsr georam_set
    // read first FAT entry
!:  ldx #$00
!:  lda $de00, x
    cmp #$00  // check if FAT record is free
    beq ffffe_found
    inx
    cpx #$00
    bne !-
    jsr georam_next
    lda #255  // first block after FAT block table
    cmp geomem_block
    bne !--
    // disk full
    lda #$ff
    sta $f5
    sta $f6
    rts
ffffe_found:
    lda geomem_block
    sec
    sbc #191
    sta $f5   // sector = current block - 192 + 1, see HDD Layout FAT block pointer table (63 blocks)
    stx $f6   // block = current position within the block
    rts

/* Store sector/block pointer of next allocated block to FAT sector pointer table and FAT block pointer table
This routine must be called immediately after writing data to HDD block. 
Input implicit: Current sector is known from geomem_sector/geomem_block.
Next free block is determined in this routine
return -
*/
save_next_to_pointer_table:
    // save sector/block of last written data
    lda geomem_sector
    sta sntpt_olddata_sector
    lda geomem_block
    sta sntpt_olddata_block

    // set temp "next" block value to FF to prevent finding it as free again
    lda sntpt_olddata_sector
    clc
    clv
    adc #191  // sector 1 translates to block 192
    tax  // block
    lda #$00  // sector
    jsr georam_set
    lda #$ff  // "next free block" pointer temporarily
    ldx sntpt_olddata_block  // position within block of FAT sector pointer table indicates current block
    sta $de00, x       // store there the next sector pointer

    jsr find_free_fat_entry   // find next free block, returns $f5/$f6 sector/block

    // switch to sector FAT pointer table (sector 0, blocks 128-190)
    lda sntpt_olddata_sector
    clc
    clv
    adc #127  // sector 1 translates to block 128
    tax  // block
    lda #$00  // sector
    jsr georam_set
    lda $f5  // next free sector pointer
    ldx sntpt_olddata_block  // position within block of FAT sector pointer table indicates current block
    sta $de00, x       // store there the next sector pointer

    // switch to block FAT pointer table (sector 0, blocks 192-254)
    lda sntpt_olddata_sector
    clc
    clv
    adc #191  // sector 1 translates to block 192
    tax  // block
    lda #$00  // sector
    jsr georam_set
    lda $f6  // next free block pointer
    ldx sntpt_olddata_block  // position within block of FAT sector pointer table indicates current block
    sta $de00, x       // store there the next sector pointer
    rts
sntpt_olddata_sector: .byte $ff
sntpt_olddata_block: .byte $ff

/* Store sector/block to FAT sector pointer table and FAT block pointer table.
It is not really secotr/block. Instead, sector=0 to indicate EndOfFile. Block=number of bytes 
from the last block belonging to the file.
Current sector is know from geomem_sector/geomem_block
$f5/$f6 0 for end of file (is hardcoded) / lo nibble from the $TO input
return -
*/
save_eof_to_pointer_table:
    // save sector/block of last written data
    lda geomem_sector
    sta sntpt_olddata_sector
    lda geomem_block
    sta sntpt_olddata_block

    // switch to sector FAT pointer table (sector 0, blocks 128-190)
    lda sntpt_olddata_sector
    clc
    clv
    adc #127  // sector 1 translates to block 128
    tax  // block
    lda #$00  // sector
    jsr georam_set
    lda $f5  // next free sector pointer
    ldx sntpt_olddata_block  // position within block of FAT sector pointer table indicates current block
    sta $de00, x       // store there the next sector pointer

    // switch to block FAT pointer table (sector 0, blocks 192-254)
    lda sntpt_olddata_sector
    clc
    clv
    adc #191  // sector 1 translates to block 192
    tax  // block
    lda #$00  // sector
    jsr georam_set
    lda $f6  // next free block pointer
    ldx sntpt_olddata_block  // position within block of FAT sector pointer table indicates current block
    sta $de00, x       // store there the next sector pointer
    rts