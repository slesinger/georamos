#importonce
#import "shared.asm"
// .import source "georam.sym"

// .filenamespace block_0001

#if !BOOTBLOCK_DEVELOPMENT
    .segment block_0001
#endif

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
    // if state is upload from, then activate upload to
    lda current_state
    cmp #state_upld_from
    beq toggle_upld_to
    // if state is upload to, then activate upload file
    cmp #state_upld_to
    beq toggle_upld_file
    // if state is upload file, then activate upload type
    cmp #state_upld_file
    beq toggle_upld_type
    // if state is upload type, then activate upload from
    cmp #state_upld_type
    beq toggle_upld_from
    // if state is left panel, then activate right panel
    cmp #state_left_panel
    beq toggle_right_panel
    // if state is right panel, then activate left panel
    cmp #state_right_panel
    beq toggle_left_panel
    jmp read_key


// Toggle background color from bg2 to bg3 or back
toggle_left_panel:
    jsr activate_right_panel_func
    jsr activate_left_panel_func
    jmp read_key

toggle_right_panel:
    jsr activate_left_panel_func
    jsr activate_right_panel_func
    jmp read_key

toggle_upld_from:
    jsr activate_upld_type_func
    jsr activate_upld_from_func
    jmp read_key

toggle_upld_to:
    jsr activate_upld_from_func
    jsr activate_upld_to_func
    jmp read_key

toggle_upld_file:
    jsr activate_upld_to_func
    jsr activate_upld_file_func
    jmp read_key

toggle_upld_type:
    jsr activate_upld_file_func
    jsr activate_upld_type_func
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
    jsr activate_upld_from_func
    jsr focus_input_field
    // lda #$00
    // sta geo_copy_to_srcPtr + 1
    // lda #$80
    // sta geo_copy_to_srcPtr + 2
    // ldx #$01 //geo sector
    // lda #$00 //geo block
    // ldy #$10 //copy $8000 - $8fff
    // jsr geo_copy_to_geo
    // inc $d020 // confirm done
    rts

dowload_to_memory_impl:
    lda #$00
    sta geo_copy_from_trgPtr + 1
    lda #$80
    sta geo_copy_from_trgPtr + 2
    ldx #$01 //geo sector
    lda #$00 //geo block
    ldy #$10 //copy n pages
    jsr geo_copy_from_geo
    inc $d020 // confirm done
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
    jsr activate_left_panel_func  // start with cursor in left panel
    rts


// Safely switch georam while preserving sector/block in geomem variables
// Y: sector
// X: block
// A: <untouched>
// return: -
georam_set:
    sty georam_sector
    sty geomem_sector
    stx georam_block
    stx geomem_block
    rts



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

