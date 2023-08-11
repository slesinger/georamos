#importonce

// Only definitions here, no code that occupies memory

// Memory
.const page00 = $c000
.const page00_lo = $00
.const page00_hi = $c0
.const page00_end = $c0ff
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
.const PRINT_NSTR = $ab1e
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

