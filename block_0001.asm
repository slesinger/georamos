#importonce
#import "shared.asm"


*=page01 "menu"
    jsr menu_screen_init  // all registers destroyed
    #if NETWORK
        jsr network_init
        jsr network_get_time
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
    cmp #$0d            // return
    beq return_handler
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
    jsr delete_file_impl
    jmp read_key

menu_drop:
    inc $d021
    jmp read_key

exit_to_basic:
    jmp exit_to_basic_impl

reload_panel:
    jsr reload_panel_impl
    ldx current_state
    jsr panel_content_render
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

return_handler:  // download and execute file
    jsr return_handler_impl
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
    jsr status_clear
    jmp read_key

reload_panel_impl:
    jsr load_current_state_meta_vector
    jsr panel_backend_fetch
rpi_end:
    rts


return_handler_impl:  // download to memory and execute file
    jsr load_current_state_meta_vector  // > $fb/$fc panel metadata
    jsr get_filetable_entry_of_file_under_cursor  // > $fb/$fc block/entry of filetable record, A: backend type
    sta fs_download_backend_type
    lda $fb  // block
    sta fs_download_dirfile_major
    lda $fc  // entry pointer
    sta fs_download_dirfile_minor
    lda #$ff  // user does not specify target address, so use one from dirfiletable
    sta fs_download_memory_address+1
    jsr fs_download
    bcc network_get_ok
    lda #$06 // error status
    sta status_code
    sec
    jsr status_print
    rts   // return on error, do nothing
network_get_ok:
    lda fs_download_last_address
    sta status_data1
    lda fs_download_last_address +1
    sta status_data2
    lda #$04 // ok status
    sta status_code
    clc
    jsr status_print
    lda fs_download_file_type
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
!:  
    jsr CLRSCR  // clear screen
    jsr run_prg
    jsr menu_screen_init
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
    jsr load_current_state_meta_vector  // > $fb/$fc panel metadata
    ldy #$06  // backend type
    lda ($fb),y 
    sta fs_upload_backend_type
    lda #state_upld_from
    sta current_state
    jsr input_field_focus
    cmp #$00                    // escape pressed - no action
    bne !+
    lda #$05  // cancelled
    sta status_code
    clc
    jsr status_print
    jsr activate_left_panel_func
    jmp ufmi_end
!:  cmp #$01                    // return pressed - upload
    bne ufmi_end  // assert other status
    /// TODO validate from, to, file, type
    // get $FROM address
    ldx #state_upld_from        // convert "from" address to word
    jsr load_x_state_meta_vector
    jsr memaddrstr_to_word
    lda $f7
    sta fs_upload_memory_from
    lda $f8
    sta fs_upload_memory_from + 1
    // get $TO address to calculate number of blocks to copy
    ldx #state_upld_to        // convert "to" address to word
    jsr load_x_state_meta_vector
    jsr memaddrstr_to_word
    lda $f7
    sta fs_upload_memory_to
    lda $f8
    sta fs_upload_memory_to +1
    lda #$00  // root directory  TODO to figure out what directory the browser stands in
    sta create_file_parent_directory_id +1
    ldx #state_upld_type   //  prg or seq type  TODO validate values
    jsr load_x_state_meta_vector
    jsr screen2filetype
    sta fs_upload_type
    // filename pointers
    lda #<input_field_upld_file
    sta fs_upload_filenamePtr
    lda #>input_field_upld_file
    sta fs_upload_filenamePtr +1
    jsr fs_upload
    bcc ufmi_ok
    lda #$06  // error status
    sta status_code
    sec
    jsr status_print
    rts
ufmi_ok:
    // print status message
    lda fs_upload_size_uploaded
    sta status_data1
    lda fs_upload_size_uploaded +1
    sta status_data2
    lda #$02
    sta status_code
    clc
    jsr status_print
    jsr reload_panel_impl
    ldx current_state
    jsr panel_content_render
ufmi_end:
    rts


dowload_to_memory_impl:
    jsr input_line_dnld_render
    jsr load_current_state_meta_vector  // > $fb/$fc panel metadata
    jsr get_filetable_entry_of_file_under_cursor  // > $fb/$fc block/entry of filetable record, A: sector
    sta fs_download_backend_type
    and #%00111111  // get just sector part of it
    ldx $fb  // block 0-255
    stx fs_download_dirfile_major
    jsr georam_set  // change to point to file table
    lda $fc  // entry pointer
    sta fs_download_dirfile_minor
    clc
    adc #18  // skip  to original address (+18) and (+19) bytes of filetable record to point sector pointer to first FAT
    tax
    lda pagemem, x  // first sector of file
    sta dfmi_original_addr  // needed for value prefill
    // display download dialog
    lda #state_dnld_to
    sta current_state
    lda dfmi_original_addr     // prefill original address
    ldx #$00
    jsr load_current_state_meta_vector
    jsr input_field_set_addr_value
    jsr input_field_focus
    cmp #$00                    // escape pressed - no action
    bne !+
    lda #$05
    sta status_code
    clc
    jsr status_print
    jsr activate_left_panel_func
    jmp dfmi_end
!:  cmp #$01                    // return pressed - download
    bne dtmi_error
    ldx #state_dnld_to          // convert "TO" address to word
    jsr load_x_state_meta_vector
    jsr memaddrstr_to_word
    lda $f7
    sta fs_download_memory_address  // set memory address to put data to
    lda $f8
    sta fs_download_memory_address + 1
    jsr fs_download
    bcs dtmi_error
    lda fs_download_last_address
    sta status_data1
    lda fs_download_last_address +1
    sta status_data2
    lda #$04 // ok status
    sta status_code
    clc
    jsr status_print
    rts
dtmi_error:
    lda #$06 // error status
    sta status_code
    sec
    jsr status_print
dfmi_end:
    rts
dfmi_original_addr: .byte $00


create_dir_impl:
    jsr input_line_cdir_render
    lda #state_cdir_name
    sta current_state
    jsr input_field_focus
    cmp #$00                    // escape pressed - no action
    bne !+
    jsr status_clear
    jsr activate_left_panel_func
    jmp cfmi_end
!:  cmp #$01                    // return pressed - download
    bne cfmi_end
cfmi_end:
    // sta status_data1
    // sta status_data2
    // lda #$0x
    // sta status_code
    // jsr status_print  // input line disappears to acknowledge done
    rts

delete_file_impl:
    jsr reload_panel_impl
    ldx current_state
    jsr panel_content_render
    rts

// Main GeoRAMOS initialization
// X: <preserved>
// Y: <untouched>
// A: <preserved>
// return: -
init:
    jsr fs_check
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

