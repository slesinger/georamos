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
.byte W, 27, 0, $08
.byte $68, $74, $74, $70, $3A, $2F, $2F, $31, $39, $32, $2E, $31, $36, $38, $2E, $31, $2E, $32, $2F, $67, $65, $6F, $2F
//    h    t    t    p    :    /    /    1    9    2    .    1    6    8    .    1    .    2    /    g    e    o    /   
// .text "http://C64.DOMA/GEO/"
 
/* Fetch dir/file table (5+95 blocks and populate it to sector 63)
return -
*/
network_dirfile:
    lda #<command_dirfile
    sta $fe
    lda #>command_dirfile
    sta $ff
    jsr network_send_command
    lda #$01  // write to georam sequentially
    sta $b9 
    lda #63  // sector
    ldx #28  // start with dir table at block 5
    jsr georam_set
    jsr network_getanswer
    rts
command_dirfile:
.byte W, 4+12, 0, $01
.byte  $21, $64, $69, $72, $66, $69, $6C, $65, $2E, $70, $68, $70
//     !    d    i    r    f    i    l    e    .    p    h    p
 

/* Download file from server.
Filename will be appended to command_get_filename (max 16+.+3 chars) and total length will be updated as length = 15 + filename length
Georam must be set to dir/file to respective table block
A: file type
X: pointer to file table entry
*/
network_get:
    pha
    // copy file name to command
    inx  // x point to file name
    inx
    ldy #$00
!:  lda pagemem,x
    sta command_get_filename, y
    inx
    iny    
    cpy #$10  // 16 chars filename
    bne !-
    // find of filename and append file type
!:  dey
    lda command_get_filename, y
    cmp #$20
    beq !-
    iny  // first empty space
    pla  // file type
    cmp #%10000000  // PRG
    bne ng_seq
    lda #$2e  // .
    sta command_get_filename, y
    iny
    lda #$70  // p
    sta command_get_filename, y
    // iny
    lda #$72  // r
    sta command_get_filename+1, y
    // iny
    lda #$67  // g
    sta command_get_filename+2, y
    // iny
    jmp ng_next
ng_seq:
    cmp #%11000000  // SEQ
    bne ng_end
    lda #$2e  // .
    sta command_get_filename, y
    iny
    lda #$73  // s
    sta command_get_filename, y
    iny
    lda #$65  // e
    sta command_get_filename+1, y
    iny
    lda #$71  // q
    sta command_get_filename+2, y
    iny
ng_next:
    tya
    clc
    adc #18  // length of command start
    sta command_get_size
    lda #<command_get
    sta $fe
    lda #>command_get
    sta $ff
    jsr network_send_command
    lda #$02  // use target address from file
    sta $b9
    jsr network_getanswer
ng_end:
    rts
command_get:
.byte W
command_get_size:
.byte 4+11, 0
.byte $01  // load http
.byte $21, $67, $65, $74, $2E, $70, $68, $70, $3F, $66, $3D
//    !    g    e    t    .    p    h    p    ?    f    =
command_get_filename:
.fill 20, $20  // space for filename

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
If $b9 == 0 then get target memory vector from $c3/$c4 (like kernal).
If $b9 == 1 target sequential write to georam. Make sure georam page is set correctly.
If $b9 >= 2 then use address received as first two bytes of fileit to point to georam $de00
TODO Use 02 to write to georam as a new file
If $b9 > 02 then get target memory vector from network
return: 
  $fa/$fb length of data
  $c1/$c2 start address where data were loaded
  #c3/$c4 end address
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
    lda #space
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
    bne nga_loadtogeoram
    lda $c3  // $b9 == 0 then take target address from $c3/c4 as kernal does it
    sta $c1
    sta $fc
    lda $c4
    sta $c2
    sta $fd
    jsr startload_to_mem
    jmp load_finished
nga_loadtogeoram:
    cmp #$01
    bne nga_loadtoaddress
    lda #$00  // $b9 == 1 then set address to georam sequential, used in dirfile, georam assumed to be set to correct block
    sta $fc
    lda #$de
    sta $fd
    jsr startload_to_geo_seq
    jmp load_finished
nga_loadtoaddress:
    lda $fc  // $b9 >= 2 then take address from network
    sta $c3
    sta $c1  // Load adress start C1 bzw. Ende C3
    lda $fd
    sta $c4
    sta $c2
    jsr startload_to_mem
    jmp load_finished

load_finished:
cleanup:      // ESP in Lesemodus schalten    
    lda #$ff  // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04      // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00
    lda #$00
    clc
    rts

startload_to_mem:
    ldx $fb  // lo??
    ldy #$00
stm_goread:
    jsr read_byte
    sta ($fc),y  // lo current address
    iny
    bne stm_ycont
    inc $fd  // hi current address
stm_ycont:    
    dex
    bne stm_goread
    dec $fa
    lda $fa
    cmp #$ff
    bne stm_goread
    sty $c3  // lo nibble end address
    lda $fd
    sta $c4  // hi niblle end address
    rts

startload_to_geo_seq:
    ldy #$00
stgs_goread:
    jsr read_byte
    sta ($fc),y  // lo current address
    iny
    bne stgs_ycont
    jsr georam_next
stgs_ycont:    
    bne stgs_goread
    dec $fa
    lda $fa
    cmp #$ff
    bne stgs_goread
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
