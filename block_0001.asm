#importonce
#import "shared.asm"

// #if !BOOTBLOCK_DEVELOPMENT
    // .segment block_0001
// #endif

// *=$c350 "Menu vector 50000" // helper to jump to menu on nice decimal address
//     jmp $c100

*=page01 "menu"
    jsr menu_screen_init  // all registers destroyed

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
    cmp #$91            // up arrow
    beq arrow_up_handler
    cmp #$11            // down arrow
    beq arrow_down_handler
    cmp #$1d            // right arrow
    beq arrow_right_handler
    cmp #$9d            // left arrow
    beq arrow_left_handler
    cmp #$5f            // arrow left to escape  
    beq escape_handler
    cmp #$8d            // shift + return as tab, next input
    beq next_input_handler
    cmp #$0d            // shift + return as tab, next input PRECHODNE
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
    inc $d021
    jmp read_key

delete_file:
    inc $d021
    jmp read_key

menu_drop:
    inc $d021
    jmp read_key

exit_to_basic:
    jmp exit_to_basic_impl

arrow_up_handler:
    inc $d021
    jmp read_key

arrow_down_handler:
    inc $d021
    jmp read_key

arrow_right_handler:
    inc $d021
    jmp read_key

arrow_left_handler:
    inc $d021
    jmp read_key

escape_handler:
    inc $d021
    jmp read_key

next_input_handler:
    lda current_state
!:  cmp #state_left_panel
    bne !+
    jsr load_current_input_field_vector
    jsr deactivate_input_field
    lda #state_upld_to  // new input field
    sta current_state
    jsr focus_input_field
    // if state is right panel, then activate left panel
!:  cmp #state_right_panel
    bne !+
    jsr load_current_input_field_vector
    jsr deactivate_input_field
    lda #state_upld_to  // new input field
    sta current_state
    jsr focus_input_field
    jmp read_key


// use jmp instead of jsr
exit_to_basic_impl:
    sei
    lda #$37
    sta $01             // Enable KERNAL and BASIC
    cli
    jsr $ff8a           // RESTOR: Initialize vector table $0314-$0333
    jsr $ff81           // SCINIT: Initialize VIC++
    jsr $ff84           // IOINIT: Initialize CIAs++
    rts


// Upload memory to GEORAM as a file
// filename_ptr 16 chars will be read
// filesize_ptr
// memaddr_ptr
// X: <preserved>
// Y: <preserved>
// A: <preserved>
// return: -
upload_from_memory_impl:
    jsr input_line_upld_render
    lda #state_upld_from
    sta current_state
    jsr focus_input_field
    cmp #$00                    // escape pressed - no action
    bne !+
    jsr input_line_empty_render
    jsr activate_left_panel_func
    jmp ufmi_end
!:  cmp #$01                    // return pressed - upload
    bne ufmi_end
    
    /// TODO validate from, to, file, type
    jsr input_line_empty_render
    // get $FROM address
    lda #state_upld_from        // convert "from" address to word
    jsr load_state_input_field_vector
    jsr memaddrstr_to_word
    lda $f7
    sta write_file_srcPtr + 1  // set address for write_file will take data from memory
    lda $f8
    sta write_file_srcPtr + 2
    // get $TO address to calculate number of blocks to copy
    lda #state_upld_to        // convert "to" address to word
    jsr load_state_input_field_vector
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
    jsr create_file  // > $f5/$f6 sector/block of data to write
    jsr write_file
ufmi_end:
    rts
write_file_current_block: .byte $ff
write_file_count_blocks: .byte $ff

dowload_to_memory_impl:
    lda #state_upld_from
    jsr load_state_input_field_vector
    jsr memaddrstr_to_word
    lda $f7
    sta geo_copy_from_trgPtr + 1
    lda $f8
    sta geo_copy_from_trgPtr + 2

    lda #state_upld_to
    jsr load_state_input_field_vector
    jsr memaddrstr_to_word
    lda $f7  // lo nibble of $TO
    sta last_block_bytes
    lda $f8  // hi nibble of $TO
    sec
    sbc $f8  // $TO - $FROM = number of blocks to copy
    tay
    ldx #$01 //geo sector
    lda #$00 //geo block
    jsr geo_copy_from_geo
    inc $d020 // confirm done
    rts
last_block_bytes: .byte $00
/*
function converts memory address reprented as string to word.
$f5, $f6: vector of pointing to string
return: $f7 lo nibble, $f8 hi nibble
*/
memaddrstr_to_word:
    ldy #$00  // $X...
    lda ($f5), y
    cmp #$07
    bcc !+    // branch if < $07, then it is letter A=$01,..F=$06
    cld
    sec
    sbc #$30  // shift $30-$39 > $00-$09
    jmp !++
!:  adc #$09  // shift $01-$06 > $0a-$f
!:  asl
    asl
    asl
    asl
    sta $f8
    iny       // $.X..
    lda ($f5), y
    cmp #$07
    bcc !+    // branch if < $07, then it is letter A=$01,..F=$06
    cld
    sec
    sbc #$30  // shift $30-$39 > $00-$09
    jmp !++
!:  adc #$09  // shift $01-$06 > $0a-$f
!:  ora $f8
    sta $f8
    iny       // $..X.
    lda ($f5), y
    cmp #$07
    bcc !+    // branch if < $07, then it is letter A=$01,..F=$06
    cld
    sec
    sbc #$30  // shift $30-$39 > $00-$09
    jmp !++
!:  adc #$09  // shift $01-$06 > $0a-$f
!:  asl
    asl
    asl
    asl
    sta $f7
    iny       // $...X
    lda ($f5), y
    cmp #$07
    bcc !+    // branch if < $07, then it is letter A=$01,..F=$06
    cld
    sec
    sbc #$30  // shift $30-$39 > $00-$09
    jmp !++
!:  adc #$09  // shift $01-$06 > $0a-$f
!:  ora $f7
    sta $f7
    rts


menu_dev:      // called after running from vs code to skip download from GeoRAM
    jsr init
    jmp menu

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
$f5: sector 0-63
$f6: block 0-255
A,X,Y: <untouched>
return: -
*/
georam_set_f5f6:
    pha
    lda $f5
    sta geomem_sector
    sta georam_sector
    lda $f6
    sta geomem_block
    sta georam_block
    pla
    rts

/* upload firmware $c000-$cfff to georam sector 0 block 0
   copy this fresh compiled firmware from $c000 to $cfff to georamos image
   other content of the images stays intact
input: -
return: -
*/
firmware_upload:
    // check if georam is fresh empty (starts by $ff) then zero it fully
    lda $de00
    cmp #$ff
    bne fu_all_clear
	lda #<fu_memclean
	ldy #>fu_memclean
	jsr PRINT_NSTR
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
    // upload firmware
    lda #$00
    ldx #$00
    jsr georam_set  // start at sector 0, block 0
    lda #page00_lo
    sta geo_copy_to_srcPtr + 1
    lda #page00_hi
    sta geo_copy_to_srcPtr + 2
    ldx #$00  // sector 0
    lda #$00  // block 0
    ldy #$10  // 16 pages ~ c000-cfff
    jsr geo_copy_to_geo
	lda #<fw_upload_ok
	ldy #>fw_upload_ok
	jsr PRINT_NSTR
	rts
fu_memclean:
    .text "CLEANING GEORAM MEMORY "
    .byte $0d, $22, $00
fw_upload_ok:
    .byte $0d
    .text "FIRMWARE UPLOADED SUCCESSFULLY"
    .byte $22, $00


// State of the program
current_state: .byte $00
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

