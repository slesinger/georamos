#importonce

#import "shared.asm"

/* Multiply mmba_a * mmba_b
return: A: result
*/
math_multiply_by_adding:
    lda mmba_a
    sta mmba_mod+1  // modify code, this way we can use an immediate adc-command
    lda #$00
    tay  // initialisation of result: accu is lowbyte, and y-register is highbyte
    ldx mmba_b
    inx
mmba_loop1:
    clc
mmba_loop2:
    dex
    beq mmba_end
mmba_mod:
    adc #$00  // becomes modified -> adc a
    bcc mmba_loop2
    iny
    bne mmba_loop1
mmba_end:
    sta mmba_result
    sty mmba_result+1
    rts
mmba_a: .byte $00
mmba_b: .byte $00
mmba_result: .byte $00, $00


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


/* convert A from petscii format used in georam file to Extended 
   Background Color format used in screen memory - first quater (blue bkg)
   See http://petscii.krissz.hu and load screens/menu.pe
A: petscii character
X, Y <untouched>
*/
petscii2screen0:
    and #%00111111  // blue background
    rts

screen02petscii:
    php
    cmp #$20
    bcc !+    // branch if < $20, then A is a letter
    plp
    rts
!:  cld
    clc
    adc #$40  // add $40 to convert to uppercase
    plp
    rts


/* Usefull when converting petscii encoded number as string. 
A: petscii character
X: <preserved>
Y: <preserved>
return: A: hex value
*/
petscii2int:
    pha
    and #%11110000
    cmp #%00110000  // is a number
    bne !+  // is a letter
    pla
    sec
    sbc #$30  // shift $30-$39 > $00-$09
    rts
!:  pla
    sec
    sbc #$37  // shift $41-$46 > $0a-$f
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


/* This routine is from WiC64
*/
charconvert:
    cmp #$20
    bne con0
    lda #$2e
con0:    
    cmp #$c0    
    bcs con2
    cmp #$40    
    bcs con1
    rts
con1:
    clc
    adc #$20
    rts
con2:
    sec
    sbc #$80
    rts


/* Print NULL terminated string to screen cursor position
A: lo nibble of string pointer
Y: hi nibble of string pointer
return: -
*/
PRINT_NSTR:
    sta $fb
    sty $fc
    ldy #$00
PRINT_NSTR_LOOP:
    lda ($fb),y
    cmp #$00  // NULL terminated string
    beq PRINT_NSTR_END
    jsr CHROUT  // print accumulator to cursor position
    iny
    bne PRINT_NSTR_LOOP
PRINT_NSTR_END:
    rts


/*
function converts memory address reprented as string to word.
$fb, $fc: vector of pointing to string
return: $f7 lo nibble, $f8 hi nibble
*/
memaddrstr_to_word:
    cld
    ldy #$00  // $X...
    lda ($fb), y
    jsr petscii2int
    asl
    asl
    asl
    asl
    sta $f8
    iny
    lda ($fb), y
    jsr petscii2int
    clc
    adc $f8
    sta $f8

    iny
    lda ($fb), y
    jsr petscii2int
    asl
    asl
    asl
    asl
    sta $f7
    iny
    lda ($fb), y
    jsr petscii2int
    clc
    adc $f7
    sta $f7
    rts


/* Resolve backend_type (see shared.asm) to single letter string that is used in panel header
A: backend_type
    backend_type_georam = 0,  // dir/file table sector for georam
    backend_type_floppy8 = 63 + 0,  // sector 63 for non georam temp dir/file table, 64 for floppy drive 8
    backend_type_floppy9 = 63 + 64,  // sector 63 for non georam temp dir/file table, 64 for floppy drive 9
    backend_type_network = 63 + 128  // sector 63 for non georam temp dir/file table, 128 for network drive

return:
    A: string
*/
backend_type2string:
    cmp #$00
    bne !+
    lda #7  // "G"
    rts
!:  and #%11000000
    cmp #$00
    bne !+
    lda #$38  // "8"
    rts
!:  cmp #$40
    bne !+
    lda #$39  // "9"
    rts
!:  cmp #$80
    bne !+
    lda #$0e  // "N"
    rts
!:  lda #$3f  // "?"
    rts

// Copy data from source memory pointer to georam
// geo_copy_to_srcPtr + 1: source address
// X: high byte of geo address 0-63
// A: low byte of geo address 0-255
// Y: number of pages to copy
geo_copy_to_geo:
    jsr geo_copy_common_init
    sty j1 + 1
    ldy #$00
geo_copy_to_srcPtr:
    lda $ffff,x  // $1000 is fake address, it will be replaced by real address
    sta pagemem,x
    inx
    bne geo_copy_to_srcPtr
    iny
    jsr georam_next
    inc geo_copy_to_srcPtr+2
j1: cpy #$ff   // is fake, it will be replaced by real number of blocks
    bne geo_copy_to_srcPtr 
    rts
geo_copy_to_geo_last_block_bytes: .byte $00

