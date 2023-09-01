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
input_line static template
input_field
actions_line

#### Methods
render(x, y, width, height)
activate - render it as actively used
deactivate - render it normal
focus - set cursor to widget and jump tp local key dispatch loop
vanish(x, y, width, height)
scroll with new content line
cycle input
type
hotkey_handler
status_print(status_code, status_data1, status_data2) - also include new error message status_msg0 in tui.asm

