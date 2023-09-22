#importonce

#import "status.asm"


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
.byte W, 20, 0, $08
.byte $68, $74, $74, $70, $3A, $2F, $2F, $63, $36, $34, $2E, $64, $6f, $6d, $61, $2f
//    h    t    t    p    :    /    /    c    6    4    .    d    o    m    a    /
// .byte W, 28, 0, $08
// .byte $68, $74, $74, $70, $3A, $2F, $2F, $31, $39, $32, $2E, $31, $36, $38, $2E, $31, $2E, $32, $3A, $36, $34, $36, $34, $2F
// //    h    t    t    p    :    /    /    1    9    2    .    1    6    8    .    1    .    2    :    6    4    6    4    /
// .text "http://C64.DOMA/"
 

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
.break
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


/* Send byte to network
A: byte
return: -
*/
write_byte:
// pha  // for debug
    sta $dd01   // Bit 0..7: Userport Daten PB 0-7 schreiben
dowrite:
    lda $dd0d
    nop
    nop
    nop
    nop
    and #$10        // Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
    beq dowrite
// pla  // for debug
// jsr write_byte_debug  // for debug
    rts

// This is debug version of the above
write_byte_debug:
wbd:
    sta $5000  // default starting address of log
    lda #$01
    clc
    adc wbd +1
    sta wbd +1
    lda #$00
    adc wbd +2
    sta wbd +2
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



