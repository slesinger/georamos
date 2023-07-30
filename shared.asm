#importonce

// Memory
.const default_screen_memory = $0400
.const default_screen_memory_lo = $00
.const default_screen_memory_hi = $04
.const default_color_memory = $d800
.const default_color_memory_lo = $00
.const default_color_memory_hi = $d8
.const pagemem = $de00
.const bootstrap = $c800
.const menu = $c900
.var georam_sector = $dffe  // 0-63, always store to geomem_sector, because it is not possible read from this address
.var georam_block = $dfff  // 0-255, always store to geomem_block, because it is not possible read from this address

.const input_upld_from_lo = $9e
.const input_upld_from_hi = $07
.const input_upld_from_len = $04
.const input_upld_to_lo = $a3
.const input_upld_to_hi = $07
.const input_upld_file_lo = $ac
.const input_upld_file_hi = $07
.const input_upld_file_len = $10
.const input_upld_type_lo = $bd
.const input_upld_type_hi = $07
.const input_upld_type_len = $03

// Kernal
.const SCNKEY = $FF9F
.const GETIN = $ffe4

state: .enum {
    state_left_panel, 
    state_right_panel, 
    state_upld_from, 
    state_upld_to, 
    state_upld_file, 
    state_upld_type
}
