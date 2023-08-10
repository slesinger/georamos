#importonce

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