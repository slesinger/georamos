#importonce
#import "shared.asm"


*=page01 "menu"
    jsr menu_screen_init  // all registers destroyed
    #if NETWORK
        jsr network_init
    #endif

// TODO to scan CONTROL, see https://skoolkid.github.io/sk6502/c64rom/asm/EA87.html
read_key:
    jsr GETIN           // non-blockin read key
    beq read_key
    cmp #$31            // 1
    beq help
    cmp #$32            // 2
    beq upload_from_memory
    cmp #$33            // 3
    beq dowload_to_memory
    cmp #$35            // 5
    beq copy_file
    cmp #$36            // 6
    beq move_file
    cmp #$37            // 7
    beq create_dir
    cmp #$38            // 8
    beq delete_file
    cmp #$39            // 9
    beq menu_drop
    cmp #$30            // 0
    beq exit_to_basic
    cmp #$52            // R  (with C=)  TODO C= is not recognized
    beq reload_panel
    cmp #$91            // up arrow
    beq arrow_up_handler
    cmp #$11            // down arrow
    beq arrow_down_handler
    cmp #$1d            // right arrow
    beq next_input_handler
    cmp #$9d            // left arrow
    beq next_input_handler
    cmp #$5f            // arrow left to escape  
    beq escape_handler
    cmp #$8d            // shift + return
    beq shiftreturn_handler
    cmp #$0d            // return, TODO change directory
    beq next_input_handler
    jmp read_key

help:
    inc $d021
    jmp read_key

upload_from_memory:
    jsr upload_from_memory_impl
    jmp read_key

dowload_to_memory:
    jsr dowload_to_memory_impl
    jmp read_key

copy_file:
    inc $d021
    jmp read_key

move_file:
    inc $d021
    jmp read_key

create_dir:
    jsr create_dir_impl
    jmp read_key

delete_file:
    inc $d021
    jsr firmware_upload  // !!!!!!!!!!!!!!!!!!!!!!!!! This is temporary
    jmp read_key

menu_drop:
    inc $d021
    jmp read_key

exit_to_basic:
    jmp exit_to_basic_impl

reload_panel:
    jsr reload_panel_impl
    jmp read_key

arrow_up_handler:
    jsr load_current_state_meta_vector
    jsr panel_cursor_up
    jmp read_key

arrow_down_handler:
    jsr load_current_state_meta_vector
    jsr panel_cursor_down
    jmp read_key

escape_handler:
    inc $d021
    jmp read_key

shiftreturn_handler:  // download and execute file
    jsr shiftreturn_handler_impl
    jmp read_key

next_input_handler:
    lda current_state
!:  cmp #state_left_panel
    bne !+
    jsr activate_right_panel_func
    jmp read_key
    // if state is right panel, then activate left panel
!:  cmp #state_right_panel
    bne !+
    jsr activate_left_panel_func
    jsr network_get_time  // good time to update the time
    jmp read_key

reload_panel_impl:
    jsr load_current_state_meta_vector
    jsr panel_backend_fetch
rpi_end:
    rts


shiftreturn_handler_impl:  // download to memory and execute file
    jsr load_current_state_meta_vector  // > $fb/$fc panel metadata
    jsr get_filetable_entry_of_file_under_cursor  // > $fb/$fc block/entry of filetable record, A: sector
    ldx $fb  // block
    jsr georam_set  // change to point to file table
    ldx $fc  // entry pointer
    lda pagemem, x  // get file flags
    and #%11000000  // isolate flags
    cmp #%01000000  // check if is directory
    beq shi_end     // skip directory
    pha
    jsr network_get
    pla
    cmp #%10000000  // check if is PRG
    bne shi_end     // skip non-PRG
    // execute file
    lda $c1
    cmp #$01
    bne !+
    lda $c2
    cmp #$08
    bne !+
    jmp run_basic
    rts  // there is no return to georamos from executed program
!:  jmp run_prg
shi_end:
    rts


// Upload memory to GEORAM as a file
// filename_ptr 16 chars will be read
// filesize_ptr
// X: <preserved>
// Y: <preserved>
// A: <preserved>
// return: -
upload_from_memory_impl:
    jsr input_line_upld_render
    lda #state_upld_from
    sta current_state
    jsr input_field_focus
    cmp #$00                    // escape pressed - no action
    bne !+
    jsr input_line_empty_render
    jsr activate_left_panel_func
    jmp ufmi_end
!:  cmp #$01                    // return pressed - upload
    bne ufmi_end
    /// TODO validate from, to, file, type
    // get $FROM address
    ldx #state_upld_from        // convert "from" address to word
    jsr load_x_state_meta_vector
    jsr memaddrstr_to_word
    lda $f7
    sta write_file_srcPtr + 1  // set address for write_file will take data from memory
    lda $f8
    sta write_file_srcPtr + 2
    sta create_file_hi_original_address +1
    // get $TO address to calculate number of blocks to copy
    ldx #state_upld_to        // convert "to" address to word
    jsr load_x_state_meta_vector
    jsr memaddrstr_to_word
    lda $f7
    sta geo_copy_to_geo_last_block_bytes
    inc $f8
    lda $f8    // $f8 is hi nibble of $TO. Number of blocks to copy is $TO_hi - $FROM_hi
    sec
    sbc write_file_srcPtr + 2
    sta create_file_parent_size_blocks +1
    sta write_file_count_blocks  // count for write_file loop
    lda #$00  // root directory  TODO to figure out what directory the browser stands in
    sta create_file_parent_directory_id +1
    lda #$80 // PRG  TODO figure out correct type  $80 PRG or $c0 SEQ
    sta create_file_parent_file_flags +1
    // filename pointers
    lda #<input_field_upld_file
    sta create_file_parent_filename +1
    lda #>input_field_upld_file
    sta create_file_parent_filename +2
    jsr create_file  // > $fb/$fc sector/block of data to write
    jsr write_file
    jsr input_line_empty_render  // input line disappears to acknowledge done
ufmi_end:
    rts


dowload_to_memory_impl:
    jsr input_line_dnld_render
    jsr load_current_state_meta_vector  // > $fb/$fc panel metadata
    jsr get_filetable_entry_of_file_under_cursor  // > $fb/$fc block/entry of filetable record, A: sector
    ldx $fb  // block 0-255
    jsr georam_set  // change to point to file table
    lda $fc  // entry pointer
    clc
    adc #18  // skip  to original address (+18) and (+19) bytes of filetable record to point sector pointer to first FAT
    tax
    lda pagemem, x  // first sector of file
    sta dfmi_original_addr
    inx // now point to first FAT
    lda pagemem, x  // first sector of file
    sta dfmi_next_sector
    inx
    lda pagemem, x  // first block of file
    sta dfmi_next_block
    // display download dialog
// TODO make defailt value from dfmi_original_addr
    lda #state_dnld_to
    sta current_state
    jsr input_field_focus
    cmp #$00                    // escape pressed - no action
    bne !+
    jsr input_line_empty_render
    jsr activate_left_panel_func
    jmp dfmi_end
!:  cmp #$01                    // return pressed - download
    bne dfmi_end
    ldx #state_dnld_to          // convert "TO" address to word
    jsr load_x_state_meta_vector
    jsr memaddrstr_to_word
    lda $f7
    sta geo_copy_from_trgPtr + 1  // set address for write_file will take data from memory
    lda $f8
    sta geo_copy_from_trgPtr + 2

    // loop over FAT entries and copy data to memory
dfmi_loop:
    lda dfmi_next_sector
    sta dfmi_current_sector
    lda dfmi_next_block
    sta dfmi_current_block
    jsr resolve_next_sector_block // check if this is last block   //!!!!!!!!!!!!!!!!! TODO check this in advance in order to copy last block partially as needed
    lda dfmi_next_sector
    cmp #$00
    beq dfmi_last_block
    ldx dfmi_current_sector
    lda dfmi_current_block
    ldy #$01 // copy 1 block
    jsr geo_copy_from_geo  // download block to memory, this is the actual work
    // if not last block
    // inc geo_copy_from_trgPtr + 2   // increase target memory hi nibble
    jmp dfmi_loop  // repeat
    // if last block
dfmi_last_block:
    ldx dfmi_current_block
    lda dfmi_current_sector
    jsr georam_set  // change to point to file table
    lda geo_copy_from_trgPtr +1
    sta dfmi_trgPtr +1
    lda geo_copy_from_trgPtr +2
    sta dfmi_trgPtr +2
    lda dfmi_next_block  // contains number of bytes to copy within last block
    sta dfmi_last_block_bytes +1
    ldx #$FF  // copy remaining bytes in last block
!:  inx
    lda pagemem, x
dfmi_trgPtr:
    sta $ffff,x
dfmi_last_block_bytes:
    cpx #$ff
    bne !-
dfmi_end:
    jsr input_line_empty_render  // input line disappears to acknowledge done
    rts
dfmi_current_sector: .byte $00
dfmi_current_block: .byte $00
dfmi_original_addr: .byte $00
dfmi_next_sector: .byte $00
dfmi_next_block: .byte $00

/* Populate dfmi_next_sector and dfmi_next_block with next FAT record
input: dfmi_current_sector, dfmi_current_block
return: dfmi_next_sector, dfmi_next_block
*/
resolve_next_sector_block:
    lda dfmi_current_sector
    ora #%10000000  // +128
    tax  // block 128-190: FAT sector pointer table (63 blocks)
    dex
    lda #$00  // sector 0
    jsr georam_set  // change to point to file table
    ldy dfmi_current_block
    lda pagemem, y  // get next sector
    sta dfmi_next_sector
    lda dfmi_current_sector
    ora #%11000000  // +192
    tax  // block 192-254: FAT block pointer table (63 blocks)
    dex
    lda #$00  // sector 0
    jsr georam_set  // change to point to file table
    ldy dfmi_current_block
    lda pagemem, y  // get next sector
    sta dfmi_next_block
    rts


create_dir_impl:
    jsr input_line_cdir_render
    lda #state_cdir_name
    sta current_state
    jsr input_field_focus
    cmp #$00                    // escape pressed - no action
    bne !+
    jsr input_line_empty_render
    jsr activate_left_panel_func
    jmp cfmi_end
!:  cmp #$01                    // return pressed - download
    bne cfmi_end
cfmi_end:
    // jsr input_line_empty_render  // input line disappears to acknowledge done
    rts


// Main GeoRAMOS initialization
// X: <preserved>
// Y: <untouched>
// A: <preserved>
// return: -
init:
    jsr check_fs
    rts


/* Safely switch georam while preserving sector/block in geomem variables
A: sector 0-63
X: block 0-255
Y: <untouched>
return: -
*/
georam_set:
    sta geomem_sector
    sta georam_sector
    stx geomem_block
    stx georam_block
    rts

/* Safely switch georam while preserving sector/block in geomem variables
$fb: sector 0-63
$fc: block 0-255
A,X,Y: <untouched>
return: -
*/
georam_set_fbfc:
    pha
    lda $fb
    sta geomem_sector
    sta georam_sector
    lda $fc
    sta geomem_block
    sta georam_block
    pla
    rts

/* upload firmware $a000-$bfff to georam sector 0 block 0
   copy this fresh compiled firmware from ram to georamos image
   other content of the images stays intact
input: -
return: -
*/
firmware_upload:
    // check if georam is fresh empty (starts by $ff) then zero it fully
    lda $de00
    cmp #$ff
    bne fu_all_clear
    // fill whole georam with $00
	lda #<fu_memclean
	ldy #>fu_memclean
	jsr PRINT_NSTR  // .const PRINT_NSTR = $ab1e

    lda #$00
    ldx #$00
    jsr georam_set  // start at sector 0, block 0
fu_st:
    lda #$00
    ldx #$00
!:  sta $de00, x
    inx
    bne !-
    jsr georam_next
    lda #$00
    cmp geomem_block
    bne !+
    lda #$2e  // dot
    jsr CHROUT
!:  lda #64
    cmp geomem_sector
    bne fu_st
    lda #$00
    cmp geomem_block
    bne fu_st

fu_all_clear:
    // upload block0
    lda #page00_lo
    sta geo_copy_to_srcPtr + 1
    lda #page00_hi
    sta geo_copy_to_srcPtr + 2
    ldx #$00  // sector 0
    lda #$00  // block 0
    ldy #$01  // 1 page at $cf00
    jsr geo_copy_to_geo
    // upload rest of firmware
    lda #page00_lo
    sta geo_copy_to_srcPtr + 1
    lda #page01_hi
    sta geo_copy_to_srcPtr + 2
    ldx #$00  // sector 0
    lda #$01  // block 0
    ldy #26  // 26 pages ~ a000-baff
    jsr geo_copy_to_geo
	lda #<fw_upload_ok
	ldy #>fw_upload_ok
	jsr PRINT_NSTR
!:  jmp !-  // why it does not exit to basic with rts?
    rts
fu_memclean:
    .text "CLEANING GEORAM MEMORY "
    .byte $0d, $00
fw_upload_ok:
    .byte $0d
    .text "FIRMWARE UPLOADED SUCCESSFULLY"
    .byte $00


// State of the program
current_state: .byte $00  // see shared.asm state
left_panel_cursor_pos: .byte $00
right_panel_cursor_pos: .byte $00
current_dir_id: .byte $00
filename_ptr: .word $0000  //16 chars will be read
filesize_ptr: .word $0000


message:
.text "LEFT ARROW: EXIT TO BASIC               "
.text "U: UPLOAD MEMORY TO GEORAM              "
.text "D: DOWNLOAD MEMORY FROM GEORAM          "
.byte $22

