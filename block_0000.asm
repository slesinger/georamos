#importonce
#import "shared.asm"

// #if !BOOTBLOCK_DEVELOPMENT
    // .segment block_0000
// #endif

// This must be target execution address in spite it will be copied from page 0 to $c000
*=page00 "copy_bootstrap" // good for entering GeoRAMOS menu by SYS 51200?
    jmp menu

.text "MEDLIK"  // magic and more magic

copy_bootstrap:

// This code will be finally executed from $de00 (inspite assembled for $c000). 
// Hence absolute jump with the code are allowed.

    ldx #$00
!:  lda pagemem,x
    sta bootstrap,x
    inx
    bne !-
    jmp bootstrap_code

geomem_sector: .byte $00  // 0-63
geomem_block: .byte $00  // 0-255
// .watch geomem_block

// set header position in georam
// no inputs
georam_next:
    pha  // save a
    inc geomem_block
    beq inc_georam_sector
    lda geomem_block
    sta georam_block
    pla
    rts
inc_georam_sector:
    lda geomem_block
    sta georam_block
    inc geomem_sector
    lda geomem_sector
    sta georam_sector
    pla // restore a
    rts

geo_copy_common_init:
    stx georam_sector
    stx geomem_sector
    sta georam_block
    sta geomem_block
    ldx #$00
    rts

// Copy data from source memory pointer to georam
// geo_copy_to_srcPtr + 1: source address
// X: high byte of geo address 0-63
// A: low byte of geo address 0-255
// Y: number of pages to copy
geo_copy_to_geo:
    jsr geo_copy_common_init
    sty j1+1d
    ldy #$00
geo_copy_to_srcPtr:
    lda $0400,x  // $1000 is fake address, it will be replaced by real address
    sta pagemem,x
    inx
    bne geo_copy_to_srcPtr
    iny
    jsr georam_next
    inc geo_copy_to_srcPtr+2
j1: cpy #$1   // is fake, it will be replaced by real number of blocks
    bne geo_copy_to_srcPtr 
    rts
geo_copy_to_geo_last_block_bytes: .byte $00

// Copy data from georam to target memory pointer
// geo_copy_from_trgPtr + 1: source address
// X: high byte of geo address 0-63
// A: low byte of geo address 0-255
// Y: number of blocks to copy
geo_copy_from_geo:
    jsr geo_copy_common_init
    sty j2+1
    ldy #$00
    lda pagemem,x
geo_copy_from_trgPtr:
    sta $0400,x  // $1000 is fake address, it will be replaced by real address
    inx
    bne geo_copy_from_trgPtr - 3
    iny
    jsr georam_next
    inc geo_copy_from_trgPtr+2
j2: cpy #$1   // is fake, it will be replaced by real number of blocks
    bne geo_copy_from_trgPtr - 3
    rts


// This code is executed from $c000 already after bootstrap is copied from $de00
// Absolute jump with the code are allowed.
bootstrap_code:
    // copy block1-4 from georam to $c100
    lda #$00
    sta geo_copy_from_trgPtr + 1
    lda #page01_hi
    sta geo_copy_from_trgPtr + 2
    ldx #$00 //geo sector
    lda #$01 //geo block
    ldy #$0e //copy n pages
    jsr geo_copy_from_geo
    jsr init
    jmp menu

.text "END0!"

memaddr_ptr: .word $0000
sector_ptr: .word $0000
block_ptr: .word $0000

*=$c0f8 "Menu vector 49400" // helper to bootstrap with SYS 49400
    jmp $de09

*=page00_end "boot end"
.byte $ff
