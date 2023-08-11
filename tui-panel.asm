#importonce

#import "shared.asm"
#import "utils.asm"
#import "tui.asm"
#import "block_0000.asm"
#import "block_0001.asm"
/*
activate
focus
render
refresh

panel_content
  - render (frontend)
  - scroll_up
  - scroll_down
  - select file
  - cursor up
  - cursor down

panel_backend
  - refresh (backend)

backend structure filedir entry
  - block pointing to dir/file table  (sector is always 0)
  - pointer to specific entry in the dir/file table
  - flags (bit0=is_selected)
*/


panel_header_left_render:
    lda #<default_screen_memory + 40  // start of second line
    sta panel_header_meta + 4   // targetCharPtr
    lda #<default_color_memory + 40
    sta panel_header_meta + 8   // targetColorPtr
    lda #<panel_header_meta
    sta $fb
    lda #>panel_header_meta
    sta $fc
    jsr render
    rts

panel_header_right_render:
    lda #<default_screen_memory + 40 + 20 // start of mid second line
    sta panel_header_meta + 4   // targetCharPtr
    lda #<default_color_memory + 40 + 20
    sta panel_header_meta + 8   // targetColorPtr
    lda #<panel_header_meta
    sta $fb
    lda #>panel_header_meta
    sta $fc
    jsr render
    rts

panel_vertical_leftl_render:
    lda #<default_screen_memory + 2 * 40  // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $fb
    lda #>panel_vertical_meta
    sta $fc
    jsr render
    rts

panel_vertical_leftr_render:
    lda #<default_screen_memory + 2 * 40 + 19 // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40 + 19
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $fb
    lda #>panel_vertical_meta
    sta $fc
    jsr render
    rts

panel_vertical_rightl_render:
    lda #<default_screen_memory + 2 * 40 + 20 // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40 + 20
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $fb
    lda #>panel_vertical_meta
    sta $fc
    jsr render
    rts

panel_vertical_rightr_render:
    lda #<default_screen_memory + 2 * 40 + 39 // start of third line
    sta panel_vertical_meta + 4   // targetCharPtr
    lda #<default_color_memory + 2 * 40 + 39
    sta panel_vertical_meta + 8   // targetColorPtr
    lda #<panel_vertical_meta
    sta $fb
    lda #>panel_vertical_meta
    sta $fc
    jsr render
    rts

panel_footer_left_render:
    lda #default_screen_memory_lo + $70  // start of 23line
    sta panel_header_meta + 4   // targetCharPtr
    lda #default_screen_memory_hi + $03  // start of 23line
    sta panel_header_meta + 5   // targetCharPtr

    lda #<default_color_memory_lo + $70
    sta panel_header_meta + 8   // targetColorPtr
    lda #>default_color_memory_hi + $03
    sta panel_header_meta + 9   // targetColorPtr

    lda #<panel_header_meta
    sta $fb
    lda #>panel_header_meta
    sta $fc
    jsr render
    rts

panel_footer_right_render:
    lda #default_screen_memory_lo + $70 + 20  // mid of 23line
    sta panel_header_meta + 4   // targetCharPtr
    lda #default_screen_memory_hi + $03  // start of 23line
    sta panel_header_meta + 5   // targetCharPtr

    lda #<default_color_memory_lo + $70 + 20
    sta panel_header_meta + 8   // targetColorPtr
    lda #>default_color_memory_hi + $03
    sta panel_header_meta + 9   // targetColorPtr

    lda #<panel_header_meta
    sta $fb
    lda #>panel_header_meta
    sta $fc
    jsr render
    rts

panel_content_left_render:
    lda #<panel_left_backend_meta
    sta $fb
    lda #>panel_left_backend_meta
    sta $fc
    lda #<panel_left_backend_data
    sta $f7
    lda #>panel_left_backend_data
    sta $f8
    jsr panel_backend_refresh
    jsr panel_content_render
    rts

panel_content_right_render:
    lda #<panel_right_backend_meta
    sta $fb
    lda #>panel_right_backend_meta
    sta $fc
    lda #<panel_right_backend_data
    sta $f7
    lda #>panel_right_backend_data
    sta $f8
    jsr panel_backend_refresh
    jsr panel_content_render
    rts

activate_left_panel_func:
    lda #state_left_panel
    sta current_state
    lda #$28  // outline left panel
    sta $fb
    lda #$d8
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$01  // white
    jsr activate_panel_horizontal_border
    lda #$3c  // outline right panel
    sta $fb
    lda #$d8
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$0e  // light blue
    jsr activate_panel_horizontal_border
    jsr panel_content_left_render
    // TODO render cursor
    rts

activate_right_panel_func:
    lda #state_right_panel
    sta current_state
    lda #$28  // outline left panel
    sta $fb
    lda #$d8
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$0e  // light blue
    jsr activate_panel_horizontal_border
    lda #$3c  // outline right panel
    sta $fb
    lda #$d8
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$01  // white
    jsr activate_panel_horizontal_border
    jsr panel_content_right_render
    // TODO render cursor
    rts

/*
Change background color from bg2 to bg3
$fb/$fc: vector of char memory
activate_panel_horizontal_border_len+1: length of input field
X: <untouched>
Y: <destroyed>
A: text color
return: -
*/
activate_panel_horizontal_border:
    ldy #$00
!:  sta ($fb),y
    iny
activate_panel_horizontal_border_len:
    cpy #$ff  // updated real time
    bne !-
    rts




/*
panel_backend
  - refresh (backend)

backend structure filedir entry
  byte 0:
   bit 0-6: block pointing to dir/file table  (sector is always 0), values 28-127
   bit 7: is_selected flag
  byte 1: pointer to specific entry in the dir/file table
$fb/$fc: panel_backend_meta pointer
$f7/$f8: panel_backend_data pointer

return: -
*/
panel_backend_refresh:
    // init pointers to metadata
    cld
    lda $fb  // lo nibble metadata pointer
    sta pbr_curr_dir +1
    lda $f7  // lo nibble data pointer
    sta pbr_s1 +1
    sta pbr_s2 +1
    sta pbr_s3 +1

    lda $fc  // hi nibble metadata pointer
    sta pbr_curr_dir +2
    lda $f8  // hi nibble data pointer
    sta pbr_s1 +2
    sta pbr_s2 +2
    sta pbr_s3 +2
    // loop over sector 0 blocks 28-127
    ldx #28                     
    stx pbr_current_block
    //   set georam
    lda #$00  // sector 0
    jsr georam_set
    //   loop over entries
    ldx #$00  // index within panel_backend_data
pbr_loop_block:
    ldy #$00  // index entries witin block
pbr_loop_entry:
    lda $de00, y
    and #%11000000  // check flags
    cmp #$00        // 00: scratched entry
    beq pbr_next_entry
    lda $de00, y
    and #%00111111  // ignore flags, leave parent dir id
    //     if entry belongs to current dir
pbr_curr_dir:
    cmp $ffff
    bne pbr_next_entry
    //       put block and pointer to panel_backend_data
    lda pbr_current_block
pbr_s1:
    sta $ffff, x  // save block found
    inx
    tya
pbr_s2:
    sta $ffff, x  // save pointer to entry found
    inx
pbr_next_entry:
    tya
    clc
    clv
    adc #21  // entry length
    tay
    cpy #252  // was last entry?  12 entries per block * 21 bytes per entry = 252
    bne pbr_loop_entry
    jsr georam_next
    lda geomem_block
    sta pbr_current_block
    cmp #128  // this next block is outside of dir/file table
    bne pbr_loop_block
    // fill rest of panel_backend_data with $00
    lda #$00
pbr_s3:
    sta $ffff, x
    inx
    bne pbr_s3
    rts
pbr_current_block: .byte $00

/* Use panel_backend_meta as dataprovider backend and render panel's main content
$fb/$fc: panel_backend_meta pointer
$f7/$f8: panel_backend_data pointer
*/
panel_content_render:
.break
    cld
    // init pointers
    ldy #$03
    lda ($fb), y  // lo nibble metadata pointer
    sta pcr_s2 + 1  // screen position first line
    sta pcr_s3 + 1  // screen position first line
    sta pcr_s4 + 1  // screen position first line
    lda #$04
    sta pcr_s2 + 2  // screen position first line
    sta pcr_s3 + 2  // screen position first line
    sta pcr_s4 + 2  // screen position first line
    lda #$fe  // zero backend position (-2 'cause it adds 2 at first)
    sta gnbe_current_entry
    lda #$00
    sta pcr_current_line  // loop over lines 0-19
pcr_next_line:
    jsr get_next_backend_entry
    lda $de00, y  // file flags
    sta pcr_type +1
    iny
    iny
    // render entry
    ldx #$00
pcr_namecopy_loop:
    lda $de00, y  // dir/file table name
    jsr petscii2screen0
pcr_s2:
    sta $ffff, x  // screen memory
    iny
    inx
    cpx #16       // file name length
    bne pcr_namecopy_loop
    lda #$20
pcr_s3:
    sta $ffff, x  // space between filename and type
    inx
pcr_type:
    lda #$ff
    jsr file_flags2type
pcr_s4:
    sta $ffff, x  // file type
    // skip to next line in screen memory
    lda pcr_s2 + 1
    clc
    clv
    adc #40
    sta pcr_s2 + 1
    sta pcr_s3 + 1
    sta pcr_s4 + 1
    bcc pcr_inc_line
    inc pcr_s2 + 2
    inc pcr_s3 + 2
    inc pcr_s4 + 2
pcr_inc_line:
    inc pcr_current_line
    lda pcr_current_line
    cmp #20
    bne pcr_next_line
    rts
pcr_current_line: .byte $00
pcr_spacefill: .fill 16, $20

//return: y: pointer to entry in dir/file table in $de00
get_next_backend_entry:
    ldy gnbe_current_entry
    iny
    iny
    sty gnbe_current_entry
    lda ($f7), y  // block of dir/file table
    cmp #$00  // end of dir/file table?
    beq gnbe_end_of_dirfile_table
    tax
    lda #$00  // sector 0
    jsr georam_set
    iny
    lda ($f7), y  // pointer to entry in dir/file table
    tay
    rts
gnbe_end_of_dirfile_table:
    lda #$00
    ldx #$ff  // unused block filled with zeroes
    jsr georam_set
    ldy #231  // last entry at 21 bytes per entry = 231
    rts
gnbe_current_entry: .byte $00

// convert bit 6-7 in A of file flags to screen letter P, S, D, see layout.md
file_flags2type:
    and #%11000000
    cmp #%01000000
    bne !+
    lda #$04  // D
    rts
!: cmp #%10000000
    bne !+
    lda #$10  // P
    rts
!: cmp #%11000000
    bne !+
    lda #$13  // S
    rts
!:  lda #$20  // space
    rts


panel_header_meta:
    .byte   20, 1  // width, height
    .word   panel_header_char_data  // sourceCharPtr
    .word   default_screen_memory  // targetCharPtr
    .word   panel_header_color_data  // sourceColorPtr
    .word   default_color_memory  // targetColorPtr
panel_header_char_data:
	.byte	$2B, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2B
panel_header_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

panel_vertical_meta:
    .byte   1, 20  // width, height
    .word   panel_vertical_char_data  // sourceCharPtr
    .word   default_screen_memory  // targetCharPtr
    .word   panel_vertical_color_data  // sourceColorPtr
    .word   default_color_memory  // targetColorPtr
panel_vertical_char_data:
    .byte   $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21
panel_vertical_color_data:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E



panel_left_backend_meta:
    panel_left_current_dir: .byte $00  // root dir "/" id is $00
    panel_left_cursor_position: .byte $00
    panel_left_scroll_position: .byte $00
    panel_left_first_screen_line: .byte $51
panel_left_backend_data: .fill 2*128, $00

panel_right_backend_meta:
    panel_right_current_dir: .byte $00  // root dir "/" id is $00
    panel_right_cursor_position: .byte $00
    panel_right_scroll_position: .byte $00
    panel_right_first_screen_line: .byte $65
panel_right_backend_data: .fill 2*128, $00
