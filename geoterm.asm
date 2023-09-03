
*=$7000

geoterm_polling:
    lda #<command_default_server
    sta $fe
    lda #>command_default_server
    sta $ff
    jsr network_send_command
    jsr geoterm_handle_poll_response
    cmp #$ff  // exit geoterm
    bne geoterm_polling
    rts

command_geoterminal_poll:
.byte W, 4+12, 0, $01
.byte  $21, $70, $6f, $6c, $6c, $2E, $70, $68, $70
//     !    p    o    l    l    .    p    h    p

/*
Polling response can contain multiple blocks. Each block starts with a command code with leading $08.
Block:
  $08 - block magic, escape character
  1B  - command
  xB  - data
Commands:
  $01 - STA value
  $02 - ORA AND value
  $10 - clear screen
  $11 - render rectangle
  $fe - hide geoterm
  $ff - exit geoterm
return:
   exit?
*/
geoterm_handle_poll_response:
    jsr network_getanswer_init
    bcc ghpr_netinitok
    // TODO print error status
    rts
ghpr_netinitok:
    jsr geoterm_dispatch_poll

geoterm_dispath_poll:
    jsr read_byte
    cmp $08
    beq gdp_magic_ok
    brk  // data not ok, first byte of block must be $08 TODO write incoming data to status bar
gdp_magic_ok:
    jsr read_byte
    cmp #$01
    bne !+
    jsr geoterm_sta_value
!:  cmp #$02
    bne !+
    jsr geoterm_oraand_value
!:  cmp #$10
    bne !+
    jsr geoterm_clear_screen
!:  cmp #$11
    bne !+
    jsr geoterm_render_rectangle
!:  cmp #$ff
    bne !+
    rts
!:  brk  // unexpected command


geoterm_sta_value:
    rts

geoterm_oraaand_value:
    rts

geoterm_clear_screen:
    rts



