#importonce

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


/* convert A from petscii fromat used in georam file to Extended 
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