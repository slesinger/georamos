#define BOOTBLOCK_DEVELOPMENT  // it will be executed at $cf00,a000 instead of assembled to file
// or
// #define UPLOAD_FIRMWARE  // upload firmware to georamos (can be invoked from menu)



#import "shared.asm"

#if BOOTBLOCK_DEVELOPMENT
    BasicUpstart2(menu_jumper)
#endif

#if UPLOAD_FIRMWARE
    BasicUpstart2(firmware_upload_init)
    // Temporarily made by pressing 8 (like delete) in menu
#endif

#import "block_0000.asm"
#import "block_0001.asm"
#import "tui.asm"
#import "tui-input.asm"
#import "tui-panel.asm"
#import "fs.asm"
#import "utils.asm"
