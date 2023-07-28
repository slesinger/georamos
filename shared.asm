#importonce

.var georam_sector = $dffe  // 0-63, always store to geomem_sector, because it is not possible read from this address
.var georam_block = $dfff  // 0-255, always store to geomem_block, because it is not possible read from this address
.const pagemem = $de00
.const bootstrap = $c800
.const menu = $c900
