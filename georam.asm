#define BOOTBLOCK_DEVELOPMENT  // it will be executed at $c000 instead of assembled to file
// or
// #define UPLOAD_FIRMWARE  // upload firmware to georamos (can be invoked from menu)



#import "shared.asm"

// .filenamespace georam

// #if !BOOTBLOCK_DEVELOPMENT
//     .segment georamos [outBin="georamos"]     // future ram   ,  disk pointer    , georamos file
//         .segmentout [segments ="block_0000"]  // $c000 - $c0ff,  sector 0 block 0, $0000 - $00ff
//         .segmentout [segments ="block_fill"]  //              ,                  , $0100 - $3fff
//         .segmentout [segments ="block_0001"]  // $c200 - $c2ff,  sector 0 block 1, $4000 - $40ff
//         .segmentout [segments ="block_fill"]
//         .segmentout [segments ="block_rest"]
    // .segmentdef block_0000 [min=bootstrap, max=bootstrap + $ff, fill]         // $c000 - $c0ff
    // .segmentdef block_0001 [min=bootstrap + $100, max=bootstrap + $fff, fill] // $c100 - $c1ff
//     .segmentdef block_fill [min=$0000, max=$3eff, fill]                       // $0000 - $3eff
//     .segmentdef block_rest [min=$0000, max=$400000 - 2 * $4000 -1, fill]
// #endif 


#if BOOTBLOCK_DEVELOPMENT
    BasicUpstart2(menu_dev)
#endif

#if UPLOAD_FIRMWARE
    BasicUpstart2(firmware_upload)
#endif

#import "block_0000.asm"
#import "block_0001.asm"
#import "tui.asm"
#import "tui-input.asm"
#import "tui-panel.asm"
#import "fs.asm"


