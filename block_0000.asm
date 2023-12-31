#importonce
#import "shared.asm"


// This must be target execution address in spite it will be copied from page 0 to $cf00
*=page00 "copy_bootstrap" // good for entering GeoRAMOS menu by SYS 51200?
    jmp menu

.text "MEDLI"  // magic and more magic

copy_bootstrap:

// This code will be finally executed from $de00 (inspite assembled for $cf00). 
// Hence absolute jump with the code are allowed.

    // copy bootstrap from $de00 to $cf00
    lda #$00
    sta georam_sector
    sta georam_block
    jmp $de13
at_de12:
!:  lda pagemem,x
    sta bootstrap,x
    inx
    bne !-
    jmp bootstrap_code


/* set header position in georam
no inputs
return: -
*/
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

// Copy data from georam to target memory pointer
// geo_copy_from_trgPtr + 1: source address
// X: high byte of geo sector 0-63
// A: low byte of geo block 0-255
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
j2: cpy #$ff   // is fake, it will be replaced by real number of blocks
    bne geo_copy_from_trgPtr - 3
    rts


// This code is executed from $cf00 already after bootstrap is copied from $de00
// Absolute jump with the code are allowed.
bootstrap_code:
    // disable basic
    lda #$36
    sta $01
    // copy block1-4 from georam to $a000
    lda #$00
    sta geo_copy_from_trgPtr + 1
    lda #page01_hi
    sta geo_copy_from_trgPtr + 2
    ldx #$00 //geo sector
    lda #$01 //geo block
    ldy #$1a //copy n pages
    jsr geo_copy_from_geo
    jsr init
    jmp menu

// use jmp instead of jsr
exit_to_basic_impl:
    sei
    lda #$37
    sta $01             // Enable KERNAL and BASIC
    cli
    jsr RESTOR  // Initialize vector table $0314-$0333
    jsr SCINIT  // Initialize VIC++
    jsr IOINIT  // Initialize CIAs++
    rts

// This is needed to disable basic from non-basic area before using firmware upload finction that is within the basic area.
firmware_upload_init:
    lda #$36
    sta $01
    jsr firmware_upload
    rts

/* When a program is downloaded with start address $0801, basic rom needs to be enabled and basic program started.
Basic program must be loaded already.
*/
run_basic:
    sei
    lda #$37
    sta $01
    cli
    jsr $a659  // reset execute pointer and do CLR
    jmp $a7ae  // interpreter inner loop
    brk

/* Run a ML program with start address at $c1/$c2, basic rom needs to be enabled and basic program started.
ML program must be loaded already.
$c1/$c2 is the start address of the ML program.
*/
run_prg:
    sei
    lda #$37
    sta $01
    cli
    // jsr $a659  // reset execute pointer and do CLR
    lda $c1
    sta rp_jsr +1
    lda $c2
    sta rp_jsr +2
rp_jsr:
    jsr $ffff
    dec $01
    // jmp ($00c1)  // run non-basic program
    rts


// Global variables
geomem_sector: .byte $00  // 0-63
geomem_block: .byte $00  // 0-255
sector_ptr: .word $00   //used by fs
block_ptr: .word $00   //used by fs
default_server: // fill with spaces until here <
.text "192.168.1.2:8899                        "

.text "END0!"


*=$cff5 "Bootstrap vector 49397" // helper to bootstrap with SYS 57077  (SYS 49397)

    jmp $de08

menu_jumper:
*=$cff8 "Menu vector 49400" // helper to jump to menu with SYS 49400
    // disable basic
    lda #$36
    sta $01
    jmp menu

*=page00_end "boot end"
.byte $ff
