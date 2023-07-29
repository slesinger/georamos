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

### Vice positional mapping

The Backspace key is also INSert when you hold the Shift key.

PgUp is Restore.

ESC is RUN|STOP.

Tab key is Control.

The lower left Control key should be the C= key.

the ` key should give you a left-arrow.


# TODO
- key shortcuts pro spousteni menu
- file system design
- list dir
- cd
- menu pro zadavani mem addr pro upload / download
- tool sd2iec launcher
- install fastloader
- load cartridge file
- translocate
- visual memory map
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