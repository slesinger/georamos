#importonce

// Only definitions here, no code that occupies memory

.const space = $20
.const W = $57

// Memory
.const page00 = $cf00
.const page00_lo = $00
.const page00_hi = $cf
.const page00_end = $cfff
.const page01 = $a000
.const page01_hi = $a0
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
.const SCNKEY = $FF9F
.const GETIN = $ffe4
.const CHROUT = $ffd2

state: .enum {
    state_left_panel, 
    state_right_panel, 
    state_upld_from, 
    state_upld_to, 
    state_upld_file, 
    state_upld_type,
    state_dnld_to,
    state_cdir_name
}

// sector numbers
backend_type: .enum {
    backend_type_georam = 0,  // dir/file table sector for georam
    backend_type_floppy8 = 63 + 0,  // sector 63 for non georam temp dir/file table, 64 for floppy drive 8
    backend_type_floppy9 = 63 + 64,  // sector 63 for non georam temp dir/file table, 64 for floppy drive 9
    backend_type_network = 63 + 128  // sector 63 for non georam temp dir/file table, 128 for network drive
}


