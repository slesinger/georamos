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

After poweroff, first, do bootstrap by ```SYS 57080```.

Then, anytime, enter GeoRAMOS menu by ```SYS 49408```.

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



### Vice positional mapping

The Backspace key is also INSert when you hold the Shift key.

PgUp is Restore.

ESC is RUN|STOP.

Tab key is Control.

The lower left Control key should be the C= key.

the ` key should give you a left-arrow.


# TODO
- key shortcuts pro spousteni menu
- design UI toolkit
- ukladani souboru (root dir, jmeno MEDLIK)
  - existuje root dir zaznam? kdyz ne, inicializuj fs
- list dir
- cd
- menu pro zadavani mem addr pro upload / download
- tool sd2iec launcher
- install fastloader
- load cartridge file
- translocate
- visual memory map 40*25=1000
### tried and failed quickly
- [ ] jump vector from zero page to easy menu start, e.g. sys 12,, ted SYS 56832
- .segmentdef block_fill [min=$0000, max=$3eff, fill] problem se zero page warningem, use .abs


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