BasicUpstart2(growser_start)   // this can be enabled only to make develpment easier

*=$7000

    jmp growser_start

#import "shared.asm"
#import "net-utils.asm"

growser_start:
    jsr network_init

    sei                  // set interrupt bit, make the CPU ignore interrupt requests
    lda #%01111111       // switch off interrupt signals from CIA-1
    sta $DC0D
    and $D011            // clear most significant bit of VIC's raster register
    sta $D011

    lda $DC0D            // acknowledge pending interrupts from CIA-1
    lda $DD0D            // acknowledge pending interrupts from CIA-2

    lda #$18             // set rasterline where interrupt shall occur
    sta $D012

    lda #<irq_routine            // set interrupt vectors, pointing to interrupt service routine below
    sta $0314
    lda #>irq_routine
    sta $0315

    lda #%00000001       // enable raster interrupt signals from VIC
    sta $D01A
    cli                  // clear interrupt flag, allowing the CPU to respond to interrupt requests


// .break  // break is good for developement here otherwise experimental wic64 in vice takse long to respond
key_loop:
    lda growser_polling_trigger_flag
    cmp #$00
    beq !+
    lda #$00
    sta growser_polling_trigger_flag
    lda #<command_growser_poll
    sta $fe
    lda #>command_growser_poll
    sta $ff
inc $0400
    jsr network_send_command
    jsr growser_handle_poll_response
    cmp #$ff  // exit growser
    bne !+
    rts
!:  jsr GETIN
    cmp #$00
    beq key_loop
    sta command_growser_poll_q
    jsr CHROUT
    jmp key_loop
growser_polling_trigger_flag: .byte 0

// =========


/* Polling is trigger by a flag from raster interrupt. 
If growser_polling_trigger_flag if non-zero, it gets called from keyboard loop.
*/
command_growser_poll:
// .byte W, 4+13, 0, $01
// .byte  $21, $70, $6f, $6c, $6c, $2E, $70, $68, $70, $3F, $71, $3D
// //     !    p    o    l    l    .    p    h    p    ?    q    =
.byte W, 4+9, 0, $01
.byte  $21, $70, $6f, $6c, $6c, $3F, $71, $3D
//     !    p    o    l    l    ?    q    =
command_growser_poll_q:
.byte $70


/*
Polling response can contain multiple blocks. Each block starts with a command code with leading $08.
return:
   exit?
*/
growser_handle_poll_response:
    jsr network_getanswer_init
    bcc ghpr_netinitok
    // TODO print error status
    rts
ghpr_netinitok:
ghpr_startloop:
    // dispatch incoming blocks
.break
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte
jsr read_byte

    jsr read_byte
    cmp #$08
    beq gdp_magic_ok
    brk  // data not ok, first byte of block must be $08 TODO write incoming data to status bar
gdp_magic_ok:
    jsr read_byte
    cmp #$00  // end dispatching, make another request
    bne !+
    rts
!:  cmp #$01
    bne !+
    jsr growser_sta_value
    jmp ghpr_endloop
!:  cmp #$02
    bne !+
    jsr growser_oraand_value
    jmp ghpr_endloop
!:  cmp #$10
    bne !+
    jsr growser_clear_screen
    jmp ghpr_endloop
!:  cmp #$11
    bne !+
    jsr growser_render_rectangle
    jmp ghpr_endloop
!:  cmp #$12
    bne !+
    jsr growser_output_text
    jmp ghpr_endloop
!:  cmp #$13
    bne !+
    jsr growser_set_cursor_postion
    jmp ghpr_endloop
!:  cmp #$ff
    bne !+
    rts
!:  brk  // unexpected command
ghpr_endloop:
    jmp ghpr_startloop


growser_sta_value:
    jsr read_byte
    sta gsv_sta +1
    jsr read_byte
    sta gsv_sta +2
    jsr read_byte
gsv_sta:
    sta $ffff
    rts


growser_oraand_value:
    jsr read_byte
    sta gov_lda +1
    sta gov_sta +1
    jsr read_byte
    sta gov_lda +2
    sta gov_sta +2
    jsr read_byte
    sta gov_ora +1
    jsr read_byte
    sta gov_and +1
gov_lda:
    lda $ffff
gov_ora:
    ora #$ff
gov_and:
    and #$ff
gov_sta:
    sta $ffff
    rts


growser_clear_screen:
    jsr $e544  // clear screen
    rts


growser_render_rectangle:
    jsr read_byte  // x
    tay
    sta trr_x
    jsr read_byte  // y
    tax
    sta trr_y
    clc
    jsr $fff0  // set cursor position
    jsr read_byte
    sta trr_width
    jsr read_byte
    sta trr_height
    lda #$00
    sta trr_current_y

grr_loop:
.break
    ldx trr_width
!:  dex
    jsr read_byte
    jsr CHROUT  // print accumulator to cursor position
    cpx #$00
    bne !-
    inc trr_current_y  // starting from 0
    inc trr_y
    lda trr_current_y
    cmp trr_height
    beq grr_end
    ldy trr_x
    ldx trr_y
    clc
    jsr $fff0  // set cursor position
    jmp grr_loop
grr_end:

    rts
trr_x: .byte 0
trr_y: .byte 0
trr_current_y: .byte 0
trr_width: .byte 0
trr_height: .byte 0

growser_output_text:
got_loop:
    jsr read_byte
    cmp #$00  // NULL terminated string
    beq got_end
    jsr CHROUT  // print accumulator to cursor position
    jmp got_loop
got_end:
    rts


growser_set_cursor_postion:
    jsr read_byte
    tay
    jsr read_byte
    tax
    clc
    jsr $fff0  // set cursor position
    rts

irq_routine:
    inc ir_frame_count
    lda ir_frame_count
    cmp #$fe
    bne ir_frame_count_skip
    lda #0  // 10 seems good value
    sta ir_frame_count
// nop
// jmp ir_frame_count_skip
    lda #$01
    sta growser_polling_trigger_flag
ir_frame_count_skip:
    asl $d019            // acknowledge the interrupt by clearing the VIC's interrupt flag
    jmp $ea31            // jump into KERNAL's standard interrupt service routine to handle keyboard scan, cursor display etc.
ir_frame_count: .byte 0
