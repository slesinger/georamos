
// BasicUpstart2(start)   // this can be enabled only to make develpment easier


*=$5000 "Hello World"

    jmp start  // must be at the very beginning of start address

#import "../../shared.asm"

start:
    // init
    lda #0
    sta $d020
    lda #0
    sta $d021

read_key:

    // do stuff
    inc $d020
    inc $d021

    // make sure it is possible to exit
    jsr GETIN           // non-blockin read key
    beq read_key
    // key pressed
    // clean up
    lda #14
    sta $d020
    lda #6
    sta $d021

    // exit
    rts

