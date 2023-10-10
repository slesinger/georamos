BasicUpstart2(growser_start)   // this can be enabled only to make develpment easier

*=$7000

    jmp growser_start

#import "shared.asm"
#import "net-utils.asm"

#import "docs/globals.asm"
#import "docs/userport-drv.asm"

growser_start:


    jsr parport.init
    // ldx #$06
    // uport_write_f(fromtext)
    // inc $d021  // upload done
    // uport_sread($0400, $0005)
    // inc $d021  // download done
    lda #$00
    sta $9e
    lda #$05
    sta $9f

    jsr parport.start_isr       // launch interrupt driven read

    // uport_read($0400, $0005)
!:  inc $0400
    jmp !-
    // jsr parport.stop_isr
    rts

fromtext: .text "MEDLICEK9"
.byte 0

// loopmenu:
//     jsr STD.GETIN
//     beq loopmenu
//     ldx #0
// !ne:
//     cmp cmd_vec,x
//     bne !+
//     inx
//     ldy cmd_vec,x
//     sty _s + 1
//     inx
//     ldy cmd_vec,x
//     sty _s+2
// _s: jsr $BEEF   // operand modified
//     jmp loopmenu
// !:
//     inx
//     inx
//     inx
//     pha
//     lda #$ff    // check if last cmd reached
//     cmp cmd_vec,x
//     beq !+
//     pla
//     jmp !ne-
// !:
//     pla  //unknown key pressed
//     jmp loopmenu


// cmd_vec:
//     cmdp('0', cmd0)
//     cmdp('1', cmd1)
//     cmdp('R', cmdreu)
//     cmdp('T', cmdterminal)
//     cmdp($ff, lastcmd)


// .macro cmdp(c, addr)
// {
//     .byte c
//     .word addr
// }

// cmd0:
// cmd1:
//     print(str.inputtext)
//     rstring(cmd_args)
//     jsr echo
//     rts

// cmd2:
//     print(str.inputnumber)
//     rnum(cmd_args)
//     jsr dump1
//     rts

// cmdreu:
//     inc $d020
//     rts

// cmdterminal:
//     print(str.inputtext)
//     uport_lread($0680)

// !:  jsr STD.GETIN
//     beq !-
//     cmp #$0d
//     beq !+
//     jsr STD.BSOUT
//     jmp !-
// !:
//     uport_stop()
//     show_screen(1, str.screen1)
//     rts

// lastcmd:
//     rts

// // numeric int args: max 16bit in little endian format
// // string args: '0' as terminator
// // commands must have exactly 4 chars
// cmd_tmp:    .byte $00
// cmd:        .byte $00           // poke the cmd nr. here
// cmd_start:
// cmd_init:   .text "INIT"        /* INIT<1|0> gfx on or off */
// cmd_sndstr: .text "ECHO"        /* ECHO<addr> */
// cmd_dump1:  .text "DUM1"        /* DUM1<len> */
// cmd_read:   .text "READ"        
// cmd_mandel: .text "MAND"        /* MAND<16bx8by> */
// cmd_dump2:  .text "DUM2"        /* DUM2<len> */
// cmd_irc:    .text "IRC_"        /* IRC_ */
// cmd_dump3:  .text "DUM3"        /* DUM3<len> - synchronous read*/
// cmd_arith:  .text "ARIT"        /* ARIT<fn-code byte><args> - uC math funcs */
// cmd_esppl:  .text "PLOT"        /* PLOT<plot# as one byte> */
// .align $100 // needed to support optimized write
// cmd_lit:    .fill 4, $00        // here the command is put
// cmd_args:   .fill 256, i        // poke the args here
// cmd_inv:    .text "INVALID COMMAND."
//             .byte $00

// prep_cmd:
//     tax     // cmd nr now in x
//     lda #0
//     clc
// !:  adc #4  // all commands have exactly 4 chars
//     dex
//     bne !-
//     tax
//     ldy #0
// !:
//     lda cmd_start,x
//     sta cmd_lit,y
//     inx
//     iny
//     cpy #4 
//     bne !-
//     rts

// echo:
//     lda #$1
//     jsr prep_cmd
//     ldx #0
//     stx parport.len + 1
//     ldx #4
// !l: lda cmd_lit,x
//     beq !+
//     inx
//     jmp !l-
// !:  inx             // send also the '0' char
//     stx parport.len
//     stx cmd_tmp
//     poke16_(parport.buffer, cmd_lit)
//     jsr parport.write_buffer
//     ldx cmd_tmp
//     dex             // 4 chars command + '0'
//     dex
//     dex
//     dex
//     dex
//     lda #$0
//     sta gl.dest_mem,x      // terminate string
//     stx cmd_args
//     ldx #0
//     stx cmd_args + 1
//     jsr do_rcv
//     rts
// dump1:
//     lda #$02
//     jsr prep_cmd
//     ldx #6
//     uport_write_f(cmd_lit)
// do_rcv:
//     uport_read(gl.dest_mem, cmd_args)
//     rts




// .namespace str {
// inputtext:
//     .text "TEXT:"
//     .byte $00

// inputnumber:
//     .text "#TO READ:"
//     .byte $00

// screen1:
//     .text "0) COMMAND NIC"
//     .byte $0d
//     .text "1) ECHO TEXT"
//     .byte $0d
//     .text "2) DUMP DATA ESP->C64"
//     .byte $0d
//     .byte $00
// }



























    // switch server to growser mode (serial in/out)
    lda #<command_switch_growser
    sta $fe
    lda #>command_switch_growser
    sta $ff
    jsr network_send_command


    jsr g_dir_read
gloop:
    inc $0402

    // read key
    jsr GETIN
    cmp #$00
    beq g_nokey
    // send key
    inc $0403
    jsr net_lead  // send outbound
    jsr write_byte
    inc $0404
    jsr g_dir_read  // set inbound as default

g_nokey:
    // read userport
    inc $0405
    jsr read_byte
    inc $0407
    beq g_noinbyte
    // dispatch
    sta $0400
g_noinbyte:
    jmp gloop


g_dir_read:
    lda #$00  // Datenrichtung Port B Eingang
    sta $dd03
    lda $dd00
    and #%11111011  // #251 PA2 auf LOW = ESP im Sendemodus
    sta $dd00
    rts





    sei                  // set interrupt bit, make the CPU ignore interrupt requests
    lda #%01111111       // switch off interrupt signals from CIA-1
    sta $DC0D
    and $D011            // clear most significant bit of VIC's raster register
    sta $D011

    lda $DC0D            // acknowledge pending interrupts from CIA-1
    lda $DD0D            // acknowledge pending interrupts from CIA-2

    lda #$18             // set rasterline where interrupt shall occur
    sta $D012

    lda #<irq_routine    // set interrupt vectors, pointing to interrupt service routine below
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
    beq !+  // skip reading userport
    lda #$00
    sta growser_polling_trigger_flag
    jsr growser_read_userport_and_handle_poll_response
    cmp #$ff  // exit growser
    bne !+
    jmp growser_exit
!:  jsr GETIN
    cmp #$00
    beq key_loop
    jsr CHROUT
    jmp key_loop
growser_polling_trigger_flag: .byte 0  // if 1, read from userport

command_switch_growser:
.byte W, $04, $00, $30

growser_exit:
    lda #<command_switch_growser
    sta $fe
    lda #>command_switch_growser
    sta $ff
    jsr network_send_command
    rts
command_exit_growser:
.byte W, $04, $00, $31



/*
Polling response can contain multiple blocks. Each block starts with a command code with leading $08.
return:
   exit?
*/
growser_read_userport_and_handle_poll_response:
    // jsr network_getanswer_init
    // bcc ghpr_netinitok
    // TODO print error status
    // rts
    lda #$00  // Datenrichtung Port B Eingang
    sta $dd03
    lda $dd00
    and #251  // PA2 auf LOW = ESP im Sendemodus
    sta $dd00
// ghpr_netinitok:
ghpr_startloop:
    // dispatch incoming blocks
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
    jsr growser_set_cursor_position
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


growser_set_cursor_position:
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
