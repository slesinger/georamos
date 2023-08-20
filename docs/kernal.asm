// 
// WiC64 Test Kernal for Loading directly .prg from
// http server
//
// : replaces "!" at start of LOAD "!xxx" command with
// the default server (http://www.wic64.de/prg/)
//
// Changes F-Keys for loading WiC64 NET Start prorgam
// via F1 and 
// PHP directory demo via F3
//
// F3/F7 = RUN:
// F2 = SYS49152
// F4 = SYS64738 (RESET)
// F6 = PRINT PEEK(
// F8 = NEW
//
// The whole code is very big crap ! it's only a
// tech demo and not a real kernal for normal use !
//
// Lots of segment errors when compiling - but works anyway
// 
// This part of WiC64 was written 2020-2021 by KiWi
//
// Compiler used: C64 Studio by Georg Rottensteiner
//
// https://www.georg-rottensteiner.de/de/c64.html
//
//          WiC64 Hardware & Software - Copyright (c) 2021
//
//               Thomas "GMP" Müller <gmp@wic64.de>
//             Sven Oliver "KiWi" Arke <kiwi@wic64.de>
//          Hardy "Lazy Jones" Ullendahl <lazyjones@wic64.de>
//             Henning "YPS" Harperath <yps@wic64.de>
//
//    
//         All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are
//met:
//
//1. Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
//
//2. Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the
//   distribution.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES// LOSS OF USE,
//DATA, OR PROFITS// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



// !to "wic64kernal.bin",plain

.const Pointerlow = $A4
.const Pointerhigh = $A5
.const KeyNumber = $A6


*=$e000
// !bin "kernal.bin"


* = $e479
.text "*** COMMODORE WIC64 BASIC V3 "

*=$e5e7                     // Keyboard abfrage patchen
    jsr FKeys
    
* = $ea69     // Tape Motor $C0 killen

      nop
      nop

* = $eebb

sendloadheader:

    lda #$ff  // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04      // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00
    jsr send_string   // http://irgendwas an den ESP Senden
    rts




load:
    lda #$00  // Datenrichtung Port B Eingang
    sta $dd03
    lda $dd00
    and #251      // PA2 auf LOW = ESP im Sendemodus
    sta $dd00
    
    jsr read_byte   //// Dummy Byte - um IRQ im ESP anzuschubsen


    jsr read_byte
    sta $fa
    jsr read_byte
    sta $fb         // Länge der Datenübertragung Byte 1 und 2
    
    
loaderrorcheck:
    lda $fa
    cmp #$00
    bne noloaderror
    lda $fb
    cmp #$02
    bne noloaderror

    jsr read_byte
    jsr $ffd2
    jsr read_byte
    jsr $ffd2
    lda #" "
    jsr $ffd2
    sec
    lda #$04
    rts

noloaderror:
    
    
setloadadress:    
    jsr read_byte
    sta $fc
    jsr read_byte
    sta $fd
    lda $b9                   // Sekundäradresse holen
    cmp #$00
    bne LoadtoOriginal
    
    lda $c3                   // Kernal übergibt Ladeadresse über $c3/c4
    sta $c1
    sta $fc
    lda $c4
    sta $c2
    sta $fd
    

LoadtoOriginal:
    lda $fc
    sta $c3
    sta $c1                   // Load Adresse Start C1 bzw. Ende C3

    lda $fd
    sta $c4
    sta $c2 
    
startload:
    ldx $fb             // low byte 
xloop:    
    ldy #$00
goread:
    jsr read_byte
    sta ($fc),y
    iny
    bne ycont
    inc $fd
ycont:    
    dex
    bne goread
    dec $fa
    lda $fa
    cmp #$ff
    bne goread
    
    sty $c3
    lda $fd
    sta $c4


cleanup:      // ESP in Lesemodus schalten    
    lda #$ff  // Datenrichtung Port B Ausgang
    sta $dd03
    lda $dd00
    ora #$04      // PA2 auf HIGH = ESP im Empfangsmodus
    sta $dd00
    lda #$00
    clc
    rts










save:
.const datastart = $c3
.const memend = $ae
.const lengh = $c1

    lda #$01
    sta datastart
    lda #$08
    sta datastart+1

    sec
    lda memend
    sbc datastart       // Pointer Memory End load save
    sbc #1
    sta lengh

    lda memend+1
    sbc datastart+1
    sta lengh+1



    ldy #00                 // Filenamen senden
 write_filename_header:
    lda ($BB),y
//    jsr write_byte          // Header senden
    iny
    cpy $B7
    bne write_filename_header



 ende:
    clc
    rts


LoadHTTP:
send_string:                // httpcommand: !text "W",$00,$00,$01
    lda #"W"
    jsr write_byte
    lda $b7
    clc
    adc #$04
    jsr write_byte
    lda #$00
    jsr write_byte
    lda #$01
    jsr write_byte

    ldy #00                 // Filenamen senden
send_filenameheader:
    lda ($BB),y
    jsr charconvert
    jsr write_byte
    iny
    cpy $B7
    bne send_filenameheader
    rts
    
    
write_byte:
    sta $dd01   // Bit 0..7: Userport Daten PB 0-7 schreiben
dowrite:
    lda $dd0d
    nop
    nop
    nop
    nop
    and #$10        // Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
    beq dowrite
    rts

read_byte:
   
doread:
    lda $dd0d
    nop
    nop
    nop
    nop
    and #$10        // Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
    beq doread
    
    lda $dd01 
    rts

charconvert:
    cmp #$20
    bne con0
    lda #$2e
con0:    
    cmp #$c0    
    bcs con2
    cmp #$40    
    bcs con1
    rts
con1:
    clc
    adc #$20
    rts
con2:
    sec
    sbc #$80
    rts

FKeys:
    jsr $e5b4               // Originale Keyboard Abfrage ausführen
    
CheckFKeys:
    cmp #$8d
    bcs NoFKey              // Größer als F8
    cmp #$85
    bcc NoFKey              // Kleiner als F1
    sec
    sbc #$84
    sta KeyNumber           // F1=1 / F8 = 8
    
    lda #<FTable            // Zeiger auf F-Tasten Tabelle setzen
    sta Pointerlow
    lda #>FTable
    sta Pointerhigh
Search:
     jsr IncPointer
     dec KeyNumber
     lda KeyNumber
     cmp #0                 // FX = Xte Null in F-Tasten Tabelle suchen (F1=erste Null - F8=8te Null)
     beq Found              // Richtige xte 0 gefunden - Jetzt den Text ausgeben
SearchNextKey:
     ldy #$00
     lda (Pointerlow),y
     cmp #$00
     beq Search
     jsr IncPointer
     jmp SearchNextKey

Found:
      ldy #$00
      lda (Pointerlow),y
      cmp #0                // Bei der Ausgabe auf 0 gestoßen
      beq NoFKey            // Ausgabe beenden
      cmp #$0d              // Auf ENTER gestoßen - Enter als letzte Taste dem Tastaturpuffer übermitteln
      beq NoFKey
      jsr $E716             // CHROUT - Ein Zeichen ausgeben
      jsr IncPointer
      jmp Found
    
NoFKey:
    rts

    
IncPointer:                 //Zeiger der F-Tasten Tabelle hoch zählen
     inc Pointerlow
     lda Pointerlow
     cmp #$00
     bne IncEnd
     inc Pointerhigh
IncEnd:
     rts
     
     
FTable:                     // Tastaturcodes von https://www.c64-wiki.de/wiki/C64-Tastaturtabelle
.byte 0
F1:
.text " "
.byte 147,"L",207,34,"!START.PRG",34,$0d
.byte 0
F3:
.text "RUN:"
.byte $0d, 0
F5:
.text " "
.byte 147,"L",207,34,"!DIR.PRG",34,$0d
.byte 0
F7:
.text "RUN:"
.byte $0d, 0
F2:
.text "SYS 49152"
.byte 0
F4:
.text "SYS 64738"
.byte $0d, 0
F6:
.text "PRINT PEEK ("
.byte 0
F8:
.text "NEW:"
.byte $0d, 0


* = $f541     // jsr $f817 Tape play key check removed

      ldy #$01
      lda $c3
      sta ($b2),y
      iny
      lda $c4
      sta ($b2),y
      jsr sendloadheader
      jmp $f56c

* = $f5a5     // jsr $f84a - load data from tape
      jsr load

* = $f664     // jsr $f838 Tape record key check removed

      jsr $F68F       // 'SAVING' (Name) ausgeben
      jsr save
      clc
      rts

*=$fd6c                     // Fast Reset Patch , no RAM Check

    jsr $fd02               // CBM80 Cartige eingesteckt ?
    beq cbm80

    ldx #$00
    ldy #$a0                // $a000 Ende des Speichers für Basic
    jmp exit
   
cbm80:
    ldx #$00
    ldy #$80                // $8000 Ende des Speichers für Basic
   
exit:
    jmp $fd8c
    


    

