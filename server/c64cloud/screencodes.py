from enum import IntEnum

class ScreenCodes(IntEnum):
    SPACE = 0x20

    CMD_1 = 0x81
    CMD_2 = 0x95
    CMD_3 = 0x96
    CMD_4 = 0x97
    CMD_5 = 0x98
    CMD_6 = 0x99
    CMD_7 = 0x9a
    CMD_8 = 0x9b
    CMD_9 = 0x29

    ESCAPE_SCR = 0xC0  # Escape character for control commands
    SCR_SET_CURSOR_POS = 0x01      # follows by cursorx, cursory
    SCR_SET_CURSOR_CONSOLE = 0x02
    SCR_DOWNLOAD_TO_MEMORY = 0x03  # follows by low, hi nibble of absolute memory address to store. This is normally part of PRG already!!
