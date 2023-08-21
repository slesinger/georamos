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

Emulation of WiC64 is not available in stock VICE 3.6. Compile VICE 3.7 but before enable USERPORT_EXPERIMENTAL_DEVICES in userport/userport.h.
```
./configure --enable-gtk3ui --disable-pdf-docs
```

## Usage
After poweroff, first, do bootstrap by ```SYS 57077```. ($def5)

Then, anytime, enter GeoRAMOS menu by ```SYS 53240``` ($cff8). This jumps to already bootstrapped Georamos.

You can also bootstrap again by```SYS 53000``` ($cf08) supposed $CFxx is still there.

If all fails do:
```
POKE 49397,0
POKE 49398,0
SYS 57077
```

If this does not work then georam image is broken.

Start emulation by
``````
/usr/local/bin/x64sc -userportdevice 22 -autostartprgmode 1 -autostart /home/honza/projects/c64/projects/georam/georam.prg -moncommands /home/honza/projects/c64/projects/georam/georam.vs
```

## Key bindings
1    Help
2    Upload memory area to GeoRAM file
3    Download GeoRAM file to memory
5    Copy file     ??? can i do it without temp mempry???  remove this?
6    Move file     ??? can i do it without temp mempry???  remove this?
7    Create a new directory
8    Delete file or directoru under cursor
9    Menu
0    Exit to Basic
Cursor up and down: Move cursor
Left | Right: Change to next panel or input   !!!!!
RETURN: cd into dir | start PRG
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
- download prefill origin address
- network upload
- cd to directories
- scrollable panel
- backend for disk
- disk directory
- bookmarks to directories
- panel header info (backend type, current dir)
- panel footer inf (size, start address)
- status bar to display status/errors, memory location file is downloaded, loaded from disk
- copy network to georam
- copy georam to network
- file view
- key shortcuts pro spousteni menu ***, ****
- design UI toolkit
- replace network.asm jsr CHROUT for correct output to status line
- set default server config in options
- tool sd2iec launcher
- install fastloader
- load cartridge file
- translocate  https://github.com/jblang/supermon64/blob/master/README.md
- visual memory map 40*25=1000
- display free space in georam
### tried and failed quickly
- [ ] jump vector from zero page to easy menu start, e.g. sys 12,, ted SYS 56832


*** keyabord CIA 1 $DC00
$DC0D irq
CIA1 IRG pin je napojeny na CPU IRQ pin
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

**** patch kernal
Disable kernal at E000 and copy its content into E000 ram. Patch it like wic64 does. You can load the kernal from net.
