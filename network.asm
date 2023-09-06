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
    jsr network_get_time
    rts
// TODO make this configurable, see global variables
command_default_server:
.byte W, 27, 0, $08
.byte $68, $74, $74, $70, $3A, $2F, $2F, $31, $39, $32, $2E, $31, $36, $38, $2E, $31, $2E, $32, $2F, $67, $65, $6F, $2F
//    h    t    t    p    :    /    /    1    9    2    .    1    6    8    .    1    .    2    /    g    e    o    /   
// .text "http://C64.DOMA/GEO/"
 

/* get time from wic64 command$15 and display in upper right corner
return -
*/
network_get_time:
    lda #<command_get_time
    sta $fe
    lda #>command_get_time
    sta $ff
    jsr network_send_command
    jsr network_getanswer_init
    bcc ngt_ok
    rts
ngt_ok:
    lda #default_screen_memory_lo + 29
    sta $fe
    lda #default_screen_memory_hi
    sta $ff
    ldy #$00
!:  jsr read_byte  // print HH:MM
    ora #$c0
    sta ($fe),y
    iny
    cpy #$05
    bne !-
    jsr read_byte  // skip :SS
    jsr read_byte
    jsr read_byte
!:  jsr read_byte  // print HH:MM
    ora #$c0
    sta ($fe),y
    iny
    cpy #$0b
    bne !-
    ldy #$05
!:  jsr read_byte  // read remaining bytes from network
    dey
    bne !-
    rts
command_get_time:
.byte W, 4, 0, $15


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
lda #14
sta $d020  //complete
    rts
command_dirfile:
.byte W, 4+12, 0, $01
.byte  $21, $64, $69, $72, $66, $69, $6C, $65, $2E, $70, $68, $70
//     !    d    i    r    f    i    l    e    .    p    h    p
 

/* Download file from server.
Filename will be appended to command_get_filename (max 16+.+3 chars) and total length will be updated as length = 15 + filename length
Georam must be set to dir/file to respective table block
A: filename with extension size
return:
  $c1/$c2 start address where data were loaded
  $c3/$c4 end address
  In case of error return carry flag set and A=4
*/
network_get:
    clc
    adc #18  // length of command start
    sta command_get_size
    lda #$00
    sta command_get_size+1
    lda #<command_get
    sta $fe
    lda #>command_get
    sta $ff
    jsr network_send_command
    jsr network_getanswer
    rts
command_get:
.byte W
command_get_size:
.byte 4+11, 0
.byte $01  // load http
.byte $21, $67, $65, $74, $2E, $70, $68, $70, $3F, $66, $3D
//    !    g    e    t    .    p    h    p    ?    f    =
command_get_filename:
.fill 21, $20  // space for filename


/* Use http GET tu upload memory content on server as query parameter.
inputs:
  A: filename with extension size
  $c1/$c2 start address where payload data are in memory
  command_put_payload_size: payload size. 4+11bytes for command and (19) bytes for filename is added in this routine
return:
  $c3/$c4 payload size sent to server
*/
network_put:
    clc 
    adc #21  // filename length + length of command start
    adc command_put_payload_size
    sta command_get_size
    lda #$00
    adc command_put_payload_size +1
    bcs np_payload_oversize
    sta command_get_size+1
    //add payload size once more becayse payload get converted to base16
    lda command_get_size
    clc
    adc command_put_payload_size
    sta command_get_size
    lda command_get_size+1
    adc command_put_payload_size +1
    bcs np_payload_oversize
    sta command_get_size+1

    lda #<command_get
    sta $fe
    lda #>command_get
    sta $ff
    jsr network_send_command_with_payload
    rts
np_payload_oversize:
    lda #$08
    sta status_code
    sec
    jsr status_print
    clc
    rts
command_put_payload_size: .word $0000


/*  Execute command without need to fetch response
$fe/$ff command to send
return -
*/
network_send_command:
    jsr net_lead
    ldy #$01
    lda ($fe),y  // Länge des Kommandos holen
    sec
    sbc #$01
    sta nsc_exit+1  // Als Exit speichern
    
    ldy #$ff
nsc_next:
    iny
    lda ($fe),y
    jsr write_byte
nsc_exit:
    cpy #$ff  // fake, end of string
    bne nsc_next
    // payload upload may follow in parent routine
    rts


// common network init sequence
net_lead:
    lda $dd02
    ora #$04
    sta $dd02  // Datenrichtung Port A PA2 auf Ausgang
    lda #$ff   // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04   // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00
    rts


/* Send payload from memory to server. Call only after network_send_command.
input:
    $c1/$c2 vector to payload
    command_put_payload_size: payload size
return:
    $c3/$c4 payload size sent to server
*/
network_send_command_with_payload:
    jsr net_lead
    ldy #$ff
nscwp_nextchar:
    iny
    lda ($fe),y
    cpy #$04
    bcc !+  //  if y < 5 then skip
    cmp #$00
    beq nscwp_payload_upload
!:  jsr write_byte
    jmp nscwp_nextchar

nscwp_payload_upload:
    lda #$00  // reset sent out bytes counter
    sta $c3
    sta $c4
    lda #$26  // &p=  
    jsr write_byte
    lda #$70
    jsr write_byte
    lda #$3d
    jsr write_byte

    ldy #$00
    lda command_put_payload_size +1  // low nibble
    cmp #$00
    beq napts_last  // if only < $ff bytes left
    ldy #$00
!:  lda ($c1),y
    jsr write_byte_base16
    iny
    bne !-
    inc $c2  // move to next memory page
    inc $c4  // increase nytes sent size by $100
    dec command_put_payload_size +1  // hi nibble
    beq napts_last 
    jmp !-
napts_last:
!:  lda ($c1),y
    jsr write_byte_base16
    inc $c3  // increase nytes sent size by $01
    iny
    cpy command_put_payload_size
    bne !-
    clc
    rts


/* Common start of reading a response from server
return:
    carry set: error
    carry clear: ok
    $fa(lo)/$fb(hi) length of data
*/
network_getanswer_init:
    lda #$00  // Datenrichtung Port B Eingang
    sta $dd03
    lda $dd00
    and #251  // PA2 auf LOW = ESP im Sendemodus
    sta $dd00
    jsr read_byte  // Dummy Byte - um IRQ im ESP anzuschubsen
    jsr read_byte
    sta $fb  // hi nibble of length of data
    jsr read_byte
    sta $fa  // lo nibble

loaderrorcheck:
    lda $fb
    cmp #$00
    bne noloaderror
    lda $fa
    cmp #$02
    bne noloaderror
    jsr read_byte
    sta status_data1
    jsr read_byte
    sta status_data2
    lda #$01
    sta status_code
    sec
    jsr status_print
    sec  // indicate error
    lda #$04
    rts
noloaderror:
    clc  // success
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
  $c3/$c4 end address
*/
network_getanswer:
    jsr network_getanswer_init
    bcc ng_netinitok
    rts
ng_netinitok:
    // subtract 2 from length because it was read already as target memory address ($fa=lo,$fb=hi)
    lda $fa
    sec
    sbc #$02
    sta $fa
    lda $fb
    sbc #$00
    sta $fb

    jsr read_byte
    sta $fc  // target memory address
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
    lda #$19
    lda #$ff  // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04      // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00
    lda #$00
    clc
    rts

startload_to_mem:
    ldx #$00  // hi loop counter
    ldy #$00  // lo loop counter
!:  cpx $fb  // hi nibble of length of data
    beq stm_goread_lo
stm_goread_hi:  // copy full pages
    jsr read_byte
    sta ($fc),y  // $fc/$fd where to store data, essentially $de00
    iny
    bne stm_goread_hi
    inc $fd  // hi current address
    inx
    jmp !-
stm_goread_lo:  // copy last incomplete page
    dey
!:  
    iny
    cpy $fa  // lo nibble of length of data
    beq stm_done_last
    jsr read_byte
    sta ($fc),y  // $fc/$fd where to store data
    jmp !-
stm_done_last:
    tya
    clc
    adc $fc
    sta $c3
    lda $fd
    adc #$00
    sta $c4
    rts

startload_to_geo_seq:
    ldx #$00
    ldy #$00
!:  cpx $fb  // hi nibble of length of data
    beq stgs_goread_lo
stgs_goread_hi:  // copy full pages
    jsr read_byte
    sta ($fc),y  // $fc/$fd where to store data, essentially $de00
    iny
    bne stgs_goread_hi
    jsr georam_next
    inx
    jmp !-
stgs_goread_lo:  // copy last incomplete page
    dey
!:  
    iny
    cpy $fa  // lo nibble of length of data
    beq stgs_done_last
    jsr read_byte
    sta ($fc),y  // $fc/$fd where to store data, essentially $de00
    jmp !-
stgs_done_last:
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

/* Same as write byte. It will convert byte to base16 and send it to network.
Example: "A" $01 will be converted to two bytes "01" and then to "AB" and sent to network
A: byte
return: -
*/
write_byte_base16:
    pha
    lsr  // take high 4 bits only
    lsr
    lsr
    lsr
    clc
    adc #$41  // move to A to range $41-$50  (ascii A-P)
    jsr write_byte
    pla
    and #%00001111  // take low 4 bits only
    clc
    adc #$41  // move to A to range $41-$50  (ascii A-P)
    jsr write_byte
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
