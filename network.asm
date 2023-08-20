// See license at the end of this file
#importonce

#import "shared.asm"
#import "utils.asm"


/*
Set base address.
See block000.asm global variable 'default_server'
return -
*/
network_init:
    lda #<command_default_server
    sta $fe
    lda #>command_default_server
    sta $ff
    jsr network_send_command
    rts
// TODO make this configurable, see global variables
command_default_server:
 .byte "W", 32, 0, $08
 .text "http://192.168.1.2/georamos/"


/* Fetch dir/file table (5+95 blocks and populate it to sector 63)
return -
*/
network_fetch_dirfile:
    lda #<command_fetch_dirfile
    sta $fe
    lda #>command_fetch_dirfile
    sta $ff
    jsr network_send_command
    jsr network_getanswer
    rts
command_fetch_dirfile:
 .byte "W", 32, 0, $01
 .text ":dirfile"


/* not used yet
*/
network_load_http:
// httpcommand: !text "W",$00,$00,$01
    lda #"W"
    jsr write_byte
    lda $b7
    clc
    adc #$04
    jsr write_byte  // size lo nibble 4 + filename length
    lda #$00
    jsr write_byte  // size hi nibble
    lda #$01
    jsr write_byte  // load HTTP command

    ldy #00         // send filename
send_filenameheader:
    lda ($BB),y
    jsr charconvert
    jsr write_byte
    iny
    cpy $B7
    bne send_filenameheader
    rts


/*  Execute command without need to fetch response
$fe/$ff command to send
return -
*/
network_send_command:
    lda $dd02
    ora #$04
    sta $dd02  // Datenrichtung Port A PA2 auf Ausgang
    lda #$ff   // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04   // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00

    ldy #$01
    lda ($fe),y  // Länge des Kommandos holen
    sec
    sbc #$01
    sta stringexit+1  // Als Exit speichern
    
    ldy #$ff
string_next:
    iny
    lda ($fe),y
    jsr write_byte
stringexit:
    cpy #$ff  // fake, end of string
    bne string_next
    rts


/* Read data from server after command has been issued. Target memory address comes from network (like PRG has it)
Modified: $fc/$fd
If $b9 == 00 then get target memory vector from $c3/$c4. This effectively overwrites original address recived from network
return: 
  $fa/$fb length of data
  $c1/$c2 start address where data were loaded
  #c3/$c4 end address ?
*/
network_getanswer:
    lda #$00  // Datenrichtung Port B Eingang
    sta $dd03
    lda $dd00
    and #251  // PA2 auf LOW = ESP im Sendemodus
    sta $dd00
    jsr read_byte  // Dummy Byte - um IRQ im ESP anzuschubsen
    jsr read_byte
    sta $fa  // lo nibble of length of data
    jsr read_byte
    sta $fb  // hi nibble
    
loaderrorcheck:
    lda $fa
    cmp #$00
    bne noloaderror
    lda $fb
    cmp #$02
    bne noloaderror
    jsr read_byte
    jsr CHROUT  // TODO output error to status line
    jsr read_byte
    jsr CHROUT
    lda #" "
    jsr CHROUT
    sec
    lda #$04
    rts
noloaderror:
setloadadress:    
    jsr read_byte
    sta $fc
    jsr read_byte
    sta $fd
    lda $b9  // Sekundäradresse holen
    cmp #$00
    bne nga_loadtoaddress
    lda $c3  // Kernal übergibt Ladeadresse über $c3/c4
    sta $c1
    sta $fc
    lda $c4
    sta $c2
    sta $fd
nga_loadtoaddress:
    lda $fc
    sta $c3
    sta $c1  // Load Adresse Start C1 bzw. Ende C3
    lda $fd
    sta $c4
    sta $c2 
    
startload:
    ldx $fb             // low byte 
xloop:    
    ldy #$00
goread:
    jsr read_byte
    sta ($fc),y
    iny
    bne ycont
    inc $fd
ycont:    
    dex
    bne goread
    dec $fa
    lda $fa
    cmp #$ff
    bne goread
    sty $c3
    lda $fd
    sta $c4

cleanup:      // ESP in Lesemodus schalten    
    lda #$ff  // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04      // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00
    lda #$00
    clc
    rts


/* Send byte to network
A: byte
return: -
*/
write_byte:
    sta $dd01   // Bit 0..7: Userport Daten PB 0-7 schreiben
dowrite:
    lda $dd0d
    nop
    nop
    nop
    nop
    and #$10        // Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
    beq dowrite
    rts


/* Receive byte from network
return: A byte
*/
read_byte:
rb_doread:
    lda $dd0d
    nop
    nop
    nop
    nop
    and #$10        // Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
    beq rb_doread
    lda $dd01 
    rts



// Some pieces of code in this file were taken from:
// https://www.georg-rottensteiner.de/de/c64.html
//
//          WiC64 Hardware & Software - Copyright (c) 2021
//               Thomas "GMP" Müller <gmp@wic64.de>
//             Sven Oliver "KiWi" Arke <kiwi@wic64.de>
//          Hardy "Lazy Jones" Ullendahl <lazyjones@wic64.de>
//             Henning "YPS" Harperath <yps@wic64.de>
//         All rights reserved.
