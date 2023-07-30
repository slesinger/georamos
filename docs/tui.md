# TUI - Toolkit UI

## Design

northon commander style


bottom line display options

#### Widgets
menu_line
menudrop
panel_header
panel_vertical
panel_footer
panel items[] from entries[](position)
input_line static template + inputs[]
actions_line

#### Methods
render(x, y, width, height)
vanish(x, y, width, height)
scroll with new content line
cycle input
type
hotkey_handler

	// draw screen
	lda #$00
	sta $fb
	sta $fd
	sta $f7

	lda #$28  // chars from $2800
	sta $fc

	lda #$04
	sta $fe

	lda #$e8  // color from $2be8
	sta $f9
	lda #$2b
	sta $fa

	lda #$d8  // VIC color buffer
	sta $f8

	ldx #$00
	ldy #$00
	lda ($fb),y  // char from
	sta ($fd),y  // char to
	lda ($f9),y  // color from
	sta ($f7),y  // color to
	iny
	bne *-9

	inc $fc
	inc $fe
	inc $fa
	inc $f8

	inx
	cpx #$04
	bne *-24

	// wait for keypress
	lda $c6
	beq *-2

	rts
