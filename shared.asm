#importonce

// Only definitions here, no code that occupies memory

.const space = $20
.const W = $57

// Memory
.const debug = $ce00
.const page00 = $cf00
.const page00_lo = $00
.const page00_hi = $cf
.const page00_end = $cfff
.const page01 = $8000  // change this to relocate the menu
.const page01_hi = $80 // change this to relocate the menu
.const default_screen_memory = $0400
.const default_screen_memory_lo = $00
.const default_screen_memory_hi = $04
.const default_color_memory = $d800
.const default_color_memory_lo = $00
.const default_color_memory_hi = $d8
.const pagemem = $de00
.const bootstrap = page00
.const menu = page01
.var georam_sector = $dffe  // 0-63, always store to geomem_sector, because it is not possible read from this address
.var georam_block = $dfff  // 0-255, always store to geomem_block, because it is not possible read from this address

// Kernal
.const CLRSCR = $E544  // just clear wscreen with spaces
.const SCINIT = $FF81  // Initialize VIC++
.const IOINIT = $FF84  // Initialize CIAs++
.const RESTOR = $FF8A  // Initialize vector table $0314-$0333
.const SCNKEY = $FF9F
.const CHROUT = $FFD2
.const GETIN  = $FFE4

// for meta data pointer, see state_meta_ptr_lo and state_meta_ptr_hi in tui.asm
state: .enum {
    state_left_panel  = 0, 
    state_right_panel = 1, 
    state_upld_from   = 2, 
    state_upld_to     = 3, 
    state_upld_file   = 4,  
    state_upld_type   = 5,
    state_dnld_to     = 6,
    state_cdir_name   = 7
    // state_left_panel_header = 8,
    // state_right_panel_header = 9,
    // state_left_panel_footer = 10,
    // state_right_panel_footer = 11
}

// sector numbers
backend_type: .enum {
    backend_type_georam = 0,  // dir/file table sector for georam
    backend_type_floppy8 = 63 + 0,  // sector 63 for non georam temp dir/file table, 64 for floppy drive 8
    backend_type_floppy9 = 63 + 64,  // sector 63 for non georam temp dir/file table, 64 for floppy drive 9
    backend_type_network = 63 + 128  // sector 63 for non georam temp dir/file table, 128 for network drive
}


