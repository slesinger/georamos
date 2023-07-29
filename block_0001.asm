#importonce
#import "shared.asm"
// .import source "georam.sym"

// .filenamespace block_0001

#if !BOOTBLOCK_DEVELOPMENT
    .segment block_0001
#endif

*=$c900 "menu"
	lda #<message
	ldy #>message
	jsr $ab1e
!:  jsr $ffe4           // GETIN: Wait for keypress
    beq !-

    cmp #$5f            // left arrow escape - exit to basic
    beq exit_to_basic
    cmp #$55            // u
    beq upload_from_memory
    cmp #$44            // d
    beq dowload_to_memory
!:  inc $d021
    jmp !-
    

// use jmp instead of jsr
exit_to_basic:
    sei
    lda #$37
    sta $01             // Enable KERNAL and BASIC
    cli
    jsr $ff8a           // RESTOR: Initialize vector table $0314-$0333
    jsr $ff81           // SCINIT: Initialize VIC++
    jsr $ff84           // IOINIT: Initialize CIAs++
    rts

upload_from_memory:
    lda #$00
    sta geo_copy_to_srcPtr + 1
    lda #$80
    sta geo_copy_to_srcPtr + 2
    ldx #$01 //geo sector
    lda #$00 //geo block
    ldy #$10 //copy $8000 - $8fff
    jsr geo_copy_to
    inc $d020 // confirm done
    rts

dowload_to_memory:
    lda #$00
    sta geo_copy_from_trgPtr + 1
    lda #$80
    sta geo_copy_from_trgPtr + 2
    ldx #$01 //geo sector
    lda #$00 //geo block
    ldy #$10 //copy n pages
    jsr geo_copy_from
    inc $d020 // confirm done
    rts


message:
.text "LEFT ARROW: EXIT TO BASIC               "
.text "U: UPLOAD MEMORY TO GEORAM              "
.text "D: DOWNLOAD MEMORY FROM GEORAM          "
.byte $22

*=$c9ff "menu_end"
.byte $ff