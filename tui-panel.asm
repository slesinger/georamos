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


/*
X: ldx #state_left_panel or ldx #state_right_panel
*/
panel_content_render:
    jsr load_x_state_meta_vector
    jsr panel_backend_refresh
    jsr panel_content_render_impl
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

    lda #$70  // outline left panel
    sta $fb
    lda #$db
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$01  // white
    jsr activate_panel_horizontal_border

    lda #$84  // outline right panel
    sta $fb
    lda #$db
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$0e  // light blue
    jsr activate_panel_horizontal_border

    lda #2*40   /// line 3, column 1
    sta activate_vertical_color_column + 1
    lda #$01  // activate vertical lines
    jsr activate_vertical_color
    lda #2*40+19  // line 3, column 19
    sta activate_vertical_color_column + 1
    lda #$01  // white
    jsr activate_vertical_color
    lda #2*40+20  // line 3, column 20
    sta activate_vertical_color_column + 1
    lda #$0e  // light blue
    jsr activate_vertical_color
    lda #2*40+39  // line 3, column 39
    sta activate_vertical_color_column + 1
    lda #$0e  // light blue
    jsr activate_vertical_color
    ldx #state_left_panel
    jsr panel_content_render
    
    // jsr deactive_cursor
    ldx #state_left_panel
    jsr load_x_state_meta_vector
    lda #%11000000  // cyan
    sta render_cursor_color +1
    jsr render_cursor
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

    lda #$70  // outline left panel
    sta $fb
    lda #$db
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$0e  // light blue
    jsr activate_panel_horizontal_border

    lda #$84  // outline right panel
    sta $fb
    lda #$db
    sta $fc
    lda #20
    sta activate_panel_horizontal_border_len + 1
    lda #$01  // white
    jsr activate_panel_horizontal_border

    lda #2*40   /// line 3, column 1
    sta activate_vertical_color_column + 1
    lda #$0e  // activate vertical lines
    jsr activate_vertical_color
    lda #2*40+19  // line 3, column 19
    sta activate_vertical_color_column + 1
    lda #$0e  // white
    jsr activate_vertical_color
    lda #2*40+20  // line 3, column 20
    sta activate_vertical_color_column + 1
    lda #$01  // light blue
    jsr activate_vertical_color
    lda #2*40+39  // line 3, column 39
    sta activate_vertical_color_column + 1
    lda #$01  // light blue
    jsr activate_vertical_color
    ldx #state_right_panel
    jsr panel_content_render

    // jsr deactive_cursor
    ldx #state_right_panel
    jsr load_x_state_meta_vector
    lda #%11000000  // cyan
    sta render_cursor_color +1
    jsr render_cursor
    rts

/* Show cursor
$fb/$fc: vector of of panel_backend_meta structure
A: <preserved>
return: -
*/
render_cursor:
    pha
    // get cursor position from metadata
    ldy #$01  // cursor position
    lda ($fb), y
    // calculate position of cursor on screen > $f7/$f8
    sta mmba_a
    lda #40
    sta mmba_b
    jsr math_multiply_by_adding  // cursor position * 40 chars per line > mmba_result
    ldy #$03  // lo nibble of left top corner of panel content
    lda ($fb), y
    clc
    adc mmba_result
    sta $f7  // lo nibble pointer to screen memory
    lda #$04
    adc mmba_result+1  // carry is preserved from lo nibble adding
    sta $f8  // hi nibble pointer to screen memory
    // figure out color of cursor
    // render cursor
    ldy #$00
!:  lda ($f7), y
    and #%00111111  // remove background color
render_cursor_color:
    ora #$ff  //set background color
    sta ($f7), y
    iny
    cpy #18
    bne !-
    pla
    rts


/* Update information about backend type and directory of the panel. // TODO This works for georam only
Note: $fd/$fe destroyed
Input:
    $fb/$fc: vector of of meta structure
return: -
*/
panel_header_render:
    lda $fb   // save $fb/$fc
    sta gfr_fb
    lda $fc
    sta gfr_fc

    jsr get_dirtable_entry_of_panel  // $fb/$fc pointing to dirtable entry now
    sta ghr_backend_type
    lda #$00 //sector
    ldx $fb  // block
    jsr georam_set  // change to point to file table
    lda $fc  // entry pointer
    clc
    adc #2 + 16 - 1  // move to end of filename
    tax

    lda gfr_fb  // restore $fb/$fc
    sta $fb
    lda gfr_fc
    sta $fc

    ldy #$07
    lda ($fb), y  // screen offset
    sta $fd  // lo nibble of screen to write to
    iny
    lda ($fb), y  // screen offset
    clc
    adc #default_screen_memory_hi  // point to screen memory to $04xx
    sta $fe  // hi nibble
    ldy #$00
    lda #$2B  // +
    sta ($fd), y
    iny

    lda ghr_backend_type
    jsr backend_type2string
    sta ($fd), y
    iny
    lda #$3a  // :
    sta ($fd), y
    ldy #19
    lda #$2B  // +
    sta ($fd), y

    dey
    lda #$20
    sta phr_cmp + 1
!:  lda pagemem, x  // read dir name, 16 chars
phr_cmp:
    cmp #$20
    bne phr_not_space
    lda #$2d  // -
phr_not_space2:
    sta ($fd), y  // copy dir name backwards
    dey
    dex
    cpy #2 // is at start of file name?
    bne !-
    rts
phr_not_space:
    pha
    lda #$ff  // disable comparison to space once some non space character is found going backwards over the filename
    sta phr_cmp + 1
    pla
    jmp phr_not_space2
ghr_backend_type: .byte $ff


/* Update information about size and start address of file under cursor. // TODO This works for georam only
Note: $fd/$fe destroyed
Input:
    $fb/$fc: vector of of meta structure
return: -
*/
panel_footer_render:
    lda $fb   // save $fb/$fc
    sta gfr_fb
    lda $fc
    sta gfr_fc
    jsr get_filetable_entry_of_file_under_cursor
    // get file size
    lda #$00 //sector
    ldx $fb  // block
    jsr georam_set  // change to point to file table
    ldx $fc  // entry pointer
    inx  // file size
    lda pagemem, x  // get file flags
    sta gfr_file_size
    lda $fc  // entry pointer
    clc
    adc #18  // move to original address hi nibble pointer
    tax
    lda pagemem, x
    sta gfr_start_address
    clc
    adc gfr_file_size
    sec
    sbc #1
    sta gfr_end_address  // TODO lo nibble of end address, loop over to the last FAT record is needed
    // render chars
    lda gfr_fb
    sta $fb
    lda gfr_fc
    sta $fc
    ldy #$07  
    lda ($fb), y  // screen offset
    clc
    adc #$48  // add offset to move to footer
    sta $fd  // lo nibble of screen to write to
    iny
    lda ($fb), y  // screen offset
    clc
    adc #default_screen_memory_hi + 3  // point to screen memory to $04xx, 3 to move to footer
    sta $fe  // hi nibble
    ldy #$00
    lda #$2B  // +
    sta ($fd), y
    iny
    // convert gfr_file_size to decimal string
    lda gfr_file_size
    jsr byte_to_hex_string
    sta ($fd), y
    iny
    txa
    sta ($fd), y
    iny
    lda #$2d  // fill middle with -
!:  sta ($fd), y
    iny
    cpy #8    // until
    bne !-
    lda #$1b  // [
    sta ($fd), y
    iny
    // print start address
    lda gfr_start_address
    jsr byte_to_hex_string
    sta ($fd), y
    iny
    txa
    sta ($fd), y
    iny
    lda #$2e  // .
    sta ($fd), y
    iny
    sta ($fd), y
    iny
    lda #$2d  //  -
    sta ($fd), y
    iny
    // print end address
    lda gfr_end_address
    jsr byte_to_hex_string
    sta ($fd), y
    iny
    txa
    sta ($fd), y
    iny
    lda #$2e  // .
    sta ($fd), y
    iny
    sta ($fd), y
    iny

    lda #$1d  // ]
    sta ($fd), y
    iny
    lda #$2B  // +
    sta ($fd), y
    rts
gfr_fb: .byte $ff
gfr_fc: .byte $ff
gfr_file_size: .byte $ff  // in blocks
gfr_start_address: .byte $ff  // hi nibble only
gfr_end_address: .byte $ff  // hi nibble only until TODO is done

/* Move cursor down
$fb/$fc: vector of of panel_backend_meta structure
return: -
*/
panel_cursor_down:
    ldy #$01  // cursor position
    lda ($fb), y
    cmp #19  // last line
    bne !+
    rts
!:  ldy #%00000000  // blue
    sty render_cursor_color +1
    jsr render_cursor
    tay
    iny
    tya
    ldy #$01
    sta ($fb), y  // increase cursor position
    lda #%11000000  // cyan
    sta render_cursor_color +1
    jsr render_cursor
    jsr panel_footer_render
    rts

panel_cursor_up:
    ldy #$01  // cursor position
    lda ($fb), y
    cmp #$00  // last line
    bne !+
    rts
!:  ldy #%00000000  // blue
    sty render_cursor_color +1
    jsr render_cursor
    tay
    dey
    tya
    ldy #$01
    sta ($fb), y  // increase cursor position
    lda #%11000000  // cyan
    sta render_cursor_color +1
    jsr render_cursor
    jsr panel_footer_render
    rts


/* Highlight vertical lines in color ram
A: vertical sign ! text color
activate_verticals_color_column +1: column start
return: -
*/
activate_vertical_color:
    cld
    pha
    lda #$d8
    sta activate_vertical_color_column +2  // is always $d8xx
    pla
    ldx #$00
activate_vertical_color_column:
    sta $d850
    pha
    clc
    lda activate_vertical_color_column +1
    adc #40
    sta activate_vertical_color_column +1
    bcc !+
    inc activate_vertical_color_column +2
!:  pla
    inx
    cpx #$14
    bne activate_vertical_color_column
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


/* Fetch data from floppy or network and populate sector 63 dir/file table. 
This is called by C++r or when panel content type is changed
$fb/$fc: panel_backend_meta pointer
return: -
*/
panel_backend_fetch:
    ldy #$06  // backend type ptr
    lda ($fb), y  // backend type defines sector
    pha
    and #%00111111  // get just sector part of it
    ldx #28  // start of dir table
    jsr georam_set
    pla      // backend type defines sector
    and #%11000000  // get just backend type from it
    cmp #128  // network
    bne !+
    jsr network_dirfile
    rts
!:  jsr panel_backend_fetch_drive  // both 8 and 9
    rts

panel_backend_fetch_drive:
    // TODO to be implemented
    rts

/*
Update backend data pointers (128 entries) to point to dir/file table entries within current view (directory)
  - refresh (backend)

backend structure filedir entry
  byte 0:
   bit 0-6: block pointing to dir/file table  (sector is always 0), values 28-127
   bit 7: is_selected flag
  byte 1: pointer to specific entry in the dir/file table
$fb/$fc: panel_backend_meta pointer
return: -
*/
panel_backend_refresh:
    // init pointers to metadata
    cld
    lda $fb  // lo nibble metadata pointer
    sta pbr_curr_dir +1
    ldy #$04  // pointer from meta to data
    lda ($fb), y
    sta pbr_s1 +1
    sta pbr_s2 +1
    sta pbr_s3 +1

    lda $fc  // hi nibble metadata pointer
    sta pbr_curr_dir +2
    iny
    lda ($fb), y  // hi nibble data pointer
    sta pbr_s1 +2
    sta pbr_s2 +2
    sta pbr_s3 +2
    // loop over sector 0 blocks 28-127
    ldx #28                     
    stx pbr_current_block
    //   set georam
    iny  // backend type
    lda ($fb), y  // backend type defines sector
    and #%00111111  // get just sector part of it
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
*/
panel_content_render_impl:
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


/*
Backend type agnostic get next entry routine
  $fb/$fc  backend meta data pointer
return: 
  y: pointer to entry in dir/file table in $f9/$fa (e.g. $de00)
*/
get_next_backend_entry:
    ldy #$04  // pointer from meta to data
    lda ($fb), y
    sta $f7
    iny
    lda ($fb), y
    sta $f8
    iny
    lda ($fb), y  // backend type
    and #%00111111  // get just sector part of it
    sta gnbe_sector +1
    ldy gnbe_current_entry
    iny
    iny
    sty gnbe_current_entry
    lda ($f7), y  // block of dir/file table
    cmp #$00  // end of dir/file table?
    beq gnbe_end_of_dirfile_table
    tax
gnbe_sector:
    lda #$00  // sector 0 for georam. 63 for others
    jsr georam_set
    iny
    lda ($f7), y  // pointer to entry in dir/file table
    tay
    rts
gnbe_end_of_dirfile_table:
    lda #$00  // sector 0 - universal empty space
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


/* Get dirtable entry of active panel
input: $fb/$fc: vector of panel metadata
return:
  $fb/$fc: vector pointing to dirtable entry: sector=0, block=$fb, pointer to entry=$fc
  A: sector of dirtable entry (0 for georam, 63 for network....)
*/
get_dirtable_entry_of_panel:
    ldy #$00
    lda ($fb), y  // current dir id  0-59

    ldy #$06  // backend type
    lda ($fb),y 
    sta gdeop_backend_type
    lda #28
    sta $fb  // TODO this is hardccoded first block of dir table
    lda #$00
    sta $fc  // TODO this is hardccoded first entry in dir table
    lda gdeop_backend_type
    rts
gdeop_backend_type: .byte $ff


/* Get filetable entry of file under cursor of active panel
input: $fb/$fc: vector of panel metadata
return:
  $fb/$fc: vector pointing to filetable entry: sector=0, block=$fb, pointer to entry=$fc
  A: sector of filetable entry (0 for georam, 63 for network....)
*/
get_filetable_entry_of_file_under_cursor:
    ldy #$06  // backend type
    lda ($fb),y 
    sta gfeofuc_backend_type
    ldy #$01  // cursor position info
    lda ($fb), y  // a = cursor position within panel
    tax  // save cursor position
    // TODO calculate cursor position within data backend (which is scrollable), now I assume curpos in panel == selected file in backend
    // hang $fb/$fc vector to point to backend data
    ldy #$04  // ptr to backend data
    lda ($fb),y
    pha  // save backend data lo nibble
    iny
    lda ($fb),y
    sta $fc  // hi nibble ptr to backend data
    pla
    sta $fb  // lo nibble ptr to backend data
!:  // pointing to backend data
    txa
    asl  // backend data is 2 bytes per entry
    tay
    lda ($fb), y  // sector=0, block=a=x
    tax
    iny
    lda ($fb), y  // a=pointer to entry in dir/file table
    stx $fb
    sta $fc
    lda gfeofuc_backend_type
    and #%00111111  // get just sector part of it
    rts
gfeofuc_backend_type: .byte $00





panel_vertical_meta:
    .byte 1, 20  // width, height
    .word panel_vertical_char_data  // sourceCharPtr
    .word default_screen_memory  // targetCharPtr
    .word panel_vertical_color_data  // sourceColorPtr
    .word default_color_memory  // targetColorPtr
panel_vertical_char_data:
    .byte $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21, $21
panel_vertical_color_data:
	.byte $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E


// for panel backend data see, georam.asm
panel_left_backend_meta:
    panel_left_current_dir: .byte $00  // root dir "/" id is $00
    panel_left_cursor_position: .byte $00  // +1
    panel_left_scroll_position: .byte $00  // +2
    panel_left_first_screen_line: .byte $51  // +3
    panel_left_backend_ptr: .word panel_left_backend_data  // +4  // 128 pointers to actual entries
    panel_left_backend_type: .byte backend_type_network    // +6 see shared.asm
    .word $0028  // top left corner offset of panel border // +7

panel_right_backend_meta:
    panel_right_current_dir: .byte $00  // root dir "/" id is $00
    panel_right_cursor_position: .byte $00
    panel_right_scroll_position: .byte $00
    panel_right_first_screen_line: .byte $65
    panel_right_backend_ptr: .word panel_right_backend_data
    panel_right_backend_type: .byte backend_type_georam
    .word $003c  // top left corner offset of panel border

