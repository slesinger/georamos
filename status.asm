#importonce

#import "shared.asm"


/* Remove any text from status line (line 24)
input: -
return: -
*/
status_clear:
    pha
    tya
    pha
    ldy #$00
    lda #$20
!:  sta $0798, y
    iny
    cpy #$28
    bne !-
    ldy #$00
    lda status_color
!:  sta $db98, y
    iny
    cpy #$28
    bne !-
    pla
    tay
    pla
    rts


/* byte to decimal string
A: input byte
return:
    a: high character (left)
    x: low character (right)
*/
byte_to_hex_string:
    pha
    and #%00001111
    jsr int2petscii  // low
    tax
    pla
    lsr
    lsr
    lsr
    lsr
    jsr int2petscii  // high
    rts


/* Usefull when converting int $0-$f to hex encoded petsci char. 
A: int
return: 
  A: petscii character
*/
int2petscii:
    cmp #$0a
    bcc i2p_num  // branch if < $0a, then A is a number
    sec
    sbc #$09  // shift $0a-$f > $01-$06
    rts
i2p_num:
    clc
    adc #$30  // shift $00-$09 > $30-$39
    rts


/* Use line 24 for status messages
Template example: .text @"network error (<>,\$1e\$1f)"; .byte 0
input:
    status_code: this resolves to status template message if recognized
    status_data1 and 2: codes to be printed in place of template charctersstatus message.
    status_data1 template characters are < (high octet) and > (low octet)
    status_data2 template characters are arrow up (high octet) and arrow left (low octet)
return: -
*/
status_print:
    pha  // save everything
    txa
    pha
    tya
    pha
    bcc sp_info_color
    lda #$0a // error color
    jmp !+
sp_info_color:
    lda #$05 // info color
!:  sta status_color
    lda $fb
    sta ps_fb
    lda $fc
    sta ps_fc
    jsr status_clear
    // print status message
    ldy status_code
    lda status_msg_lo, y
    sta $fb
    lda status_msg_hi, y
    sta $fc
    lda #$98
    sta ps1 + 1  // init screen cursor position
    ldy #$00
ps2:lda ($fb), y
    cmp #$00  // end of string
    beq ps_msg_done
    cmp #$3c  // <
    bne !+
    lda status_data1
    jsr byte_to_hex_string
    jmp ps1
!:  cmp #$3e  // >
    bne !+
    lda status_data1
    jsr byte_to_hex_string
    txa
    jmp ps1
!:  cmp #$1e  // arrow up
    bne !+
    lda status_data2
    jsr byte_to_hex_string
    jmp ps1
!:  cmp #$1f  // arrow left
    bne ps1
    lda status_data2
    jsr byte_to_hex_string
    txa    
ps1:sta status_line
    inc ps1 + 1
    iny
    jmp ps2
ps_msg_done:
    lda ps_fb  // restore everything
    sta $fb
    lda ps_fc
    sta $fc
    lda #$0e // reset color
    sta status_color
    pla
    tay
    pla
    tax
    pla
    rts
status_code: .byte $ff
status_data1: .byte $ff
status_data2: .byte $ff
status_color: .byte $0e
ps_fb: .byte $ff
ps_fc: .byte $ff
status_msg_lo:
    .byte <status_msg00
    .byte <status_msg01
    .byte <status_msg02
    .byte <status_msg03
    .byte <status_msg04
    .byte <status_msg05
    .byte <status_msg06
    .byte <status_msg07
    .byte <status_msg08
status_msg_hi:
    .byte >status_msg00
    .byte >status_msg01
    .byte >status_msg02
    .byte >status_msg03
    .byte >status_msg04
    .byte >status_msg05
    .byte >status_msg06
    .byte >status_msg07
    .byte >status_msg08
status_msg00: .text "unknown message"; .byte 0
status_msg01: .text @"network error (<>,\$1e\$1f)"; .byte 0
status_msg02: .text @"uploaded size $\$1e\$1f<>"; .byte 0
status_msg03: .text @"georam full. last sector <>"; .byte 0
status_msg04: .text @"last address $\$1e\$1f<>"; .byte 0
status_msg05: .text "cancelled"; .byte 0
status_msg06: .text "error"; .byte 0
status_msg07: .text "ok"; .byte 0
status_msg08: .text "REUSE ME"; .byte 0


