#importonce
#import "shared.asm"

#if !BOOTBLOCK_DEVELOPMENT
    .segment block_0001
#endif
*=$c900
!:    inc $d021
    jmp !-
.text "MEDLIK"
