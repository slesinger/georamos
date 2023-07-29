#define BOOTBLOCK_DEVELOPMENT  // it will be executed at $c800 instead of assembled to file



#import "shared.asm"

// .filenamespace georam

#if !BOOTBLOCK_DEVELOPMENT
    .segment georamos [outBin="georamos"]
        .segmentout [segments ="block_0000"]
        .segmentout [segments ="block_fill"]
        .segmentout [segments ="block_0001"]
        .segmentout [segments ="block_fill"]
        .segmentout [segments ="block_rest"]

    .segmentdef block_0000 [min=bootstrap, max=bootstrap + $ff, fill]
    .segmentdef block_0001 [min=bootstrap + $100, max=bootstrap + $1ff, fill]
    .segmentdef block_fill [min=$0000, max=$3eff, fill]
    .segmentdef block_rest [min=$0000, max=$400000 - 2 * $4000 -1, fill]
#endif 


#if BOOTBLOCK_DEVELOPMENT
    BasicUpstart2(menu_dev)
#endif

#import "block_0000.asm"
#import "block_0001.asm"
#import "tui.asm"


