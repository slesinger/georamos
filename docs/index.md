# GeoRAMOS

The OS booting from GeoRAM

## Features
- Easy bootstrap
- HDD capabilities
- Quick tools access
- Background codelets execution

## Build

Before building georamos image, make sure that ```BOOTBLOCK_DEVELOPMENT``` in ```georam.asm``` is inactive.

Find ```georamos``` image in root folder. Its size must be 4194304 bytes.

## Usage
After poweroff, first, do bootstrap by ```SYS 57077```. ($DEF5)

Then, anytime, enter GeoRAMOS menu by ```SYS 53240``` ($cff8) ASPIRE FOR SYS 53000!!!!. If this does not work, bootstrap again by ```SYS 49397``` supposed $Cxxx is still there.

If all fails do:
```
POKE 49397,0
POKE 49398,0
SYS 57077
```

## Key bindings
1    Help
2    Upload memory area to GeoRAM file
3    Download GeoRAM file to memory
5    Copy file
6    Move file
7    Create a new directory
8    Delete file or directoru under cursor
9    Menu
0    Exit to Basic
Cursor up and down: Move cursor
SHIFT+RETURN: Skip to next panel or input
Aarrow left: escape from input
C=+g switch panel to georam
C=+8/9 switch panel to disk drive 8/9
C=+n switch panel to network drive
C=+r refresh directory from source (reload from network or drive)



### Vice positional mapping

The Backspace key is also INSert when you hold the Shift key.

PgUp is Restore.

ESC is RUN|STOP.

Tab key is Control.

The lower left Control key should be the C= key.

the ` key should give you a left-arrow.


# TODO
- bd00-bfff are free because sector 0 block 0-27 does not cover more. Move backend data area there and make sure initializes on bootstrap
- backend for disk
- backend for wic64
- key shortcuts pro spousteni menu ***
- cd
- design UI toolkit
- tool sd2iec launcher
- install fastloader
- load cartridge file
- translocate  https://github.com/jblang/supermon64/blob/master/README.md
- visual memory map 40*25=1000
### tried and failed quickly
- [ ] jump vector from zero page to easy menu start, e.g. sys 12,, ted SYS 56832
- .segmentdef block_fill [min=$0000, max=$3eff, fill] problem se zero page warningem, use .abs


*** keyabord CIA 1 $DC00
$DC0D irq
CIA1 IRG pin je napojeny na CPU IRG pin
$FFFE–$FFFF is the vector for handling both IRQ and BRK-instructions; it points to 65352/$FF48, nakonec 	JMP ($0314), By default the IRQ vector points to 59953/$EA31

Init       SEI                  ; set interrupt bit, make the CPU ignore irq requests
           LDA #%01111111       ; switch off interrupt signals from CIA-1
           STA $DC0D

           LDA $DC0D            ; acknowledge pending interrupts from CIA-1
           LDA $DD0D            ; acknowledge pending interrupts from CIA-2

?          LDA #210             ; set rasterline where interrupt shall occur
?          STA $D012
314/315 nebo NMI na 316/317?
           LDA #<Irq            ; set ISR
           STA $0314
           LDA #>Irq
           STA $0315

           CLI                  ; clear irq flag, allowing CPU to respond to interrupt requests
           RTS


/*
    lda #$00
    sta geo_copy_to_srcPtr + 1
    lda #$a0
    sta geo_copy_to_srcPtr + 2
    ldx #$01 //geo sector
    lda #$00 //geo block
    ldy #$04 //copy n pages
    jsr geo_copy_to
*/