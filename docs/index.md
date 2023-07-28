# GeoRAMOS

The OS booting from GeoRAM

## Features
- Easy bootstrap
- HDD capabilities
- Quick tools access
- Background codelets execution

## Usage

After poweroff, first, do bootstrap by ```SYS 57000``` ($DEA8) or ```SYS $DEAD```.

Then, anytime, enter GeoRAMOS menu by ```SYS 51200```.

Everything else is intuitive.

# TODO
- zkopirovat z geo vsechny bloky do c800
- zakladni menu
- prvni tool bude sd2iec launcher
- [ ] jump vector from zero page to easy menu start, e.g. sys 12,, ted SYS 56832


/*
    // switch first page of Georam
    lda #$00
    sta $dfff  // 16K block 0-256 for 4MB Georam
    lda #$00
    sta $dffe  // page 0-63

    lda #$d0
    sta $de00

    // print "medlik!"
    lda #<georam
    ldy #>georam
    jsr $ab1e


    jmp -3


    lda #$00
    sta geo_copy_to_srcPtr + 1
    lda #$a0
    sta geo_copy_to_srcPtr + 2
    ldx #$01 //geo sector
    lda #$00 //geo block
    ldy #$04 //copy n pages
    jsr geo_copy_to


*=$de00
georam:

*=$c000 "Data"
message:
// .encoding "screencode_mixed"  //petscii_upper, petscii_mixed, ascii
.encoding "screencode_upper"
    .text "MEDLIK!"
    .byte $00

*/