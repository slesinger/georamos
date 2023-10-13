from __future__ import annotations

import serial, time
import re, sys, asyncio
import codecs, cbmcodecs2
from rich.color import Color
from textual.driver import Driver
from threading import Event, Timer
from typing import TYPE_CHECKING
from textual.events import Key
from threading import Thread

if TYPE_CHECKING:
    from textual.app import App

BAUD_SPEED = 115200 #250000  250000 is not reliable, some bytes are missing
TO_C64_ESC = 0x9f # escape commands when sending screen difs to C64
TO_C64_HOME = 0x01  # set cursor to (0,0)

class C64Color():
    """
    c64  name  idx
    0 black   16
    1 white   231
    2 darkred 88
    3 cyan    51
    4 violet  213
    5 green   28
    6 darkblue 18
    7 yellow  226
    8 orange  214
    9 saddlebrown 94
    a red     196
    b darkslategray 23
    c gray    244
    d lightgreen 120
    e dodgerblue 33
    f lightgray 252
    """

    # TODO calculate from https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797?permalink_comment_id=3964000#256-colors
    colors = [
        (0,   0,   0),
        (255, 255, 255),
        (136, 0,   0),
        (170, 255, 238),
        (204, 68, 204),
        (0, 204, 85),
        (0, 0, 170),
        (238, 238, 119),
        (221, 136, 85),
        (102, 68, 0),
        (255, 119, 119),
        (51, 51, 51),
        (119, 119, 119),
        (170, 255, 102),
        (0, 136, 255),
        (187, 187, 187),
    ]

    @staticmethod
    def toC64(color: Color) -> int:
        c = color.get_truecolor()
        min_diff = 999
        min_idx = -1
        for i, c64rgb in enumerate(C64Color.colors):
            diff = abs(c64rgb[0] - c.red) + abs(c64rgb[1] - c.green) + abs(c64rgb[2] - c.blue)
            if diff < min_diff:
                min_diff = diff
                min_idx = i
        return min_idx


class C64Cursor():
    def __init__(self):
        self.x = 0
        self.y = 0
        self.textColor = 12
        self.bkgColor = 0

    def setPos(self, x: int, y: int) -> None:
        self.x = x
        self.y = y

    def nextPos(self) -> None:
        self.x += 1
        if self.x >= 40:
            self.x = 0
            self.y += 1
            if self.y >= 25:
                # TODO emit scroll event
                self.y -= 1 # TODO finalize

    def newLine(self) -> None:
        self.x = 40-1
        self.nextPos()

    def setTextColor(self, color: int) -> None:
        c = Color.from_ansi(color)
        self.textColor = C64Color.toC64(c)

    def setTextColorRGB(self, r: int, g: int, b: int) -> None:
        c = Color.from_rgb(r, g, b)
        self.textColor = C64Color.toC64(c)

    def setBkgColor(self, color: int) -> None:
        c = Color.from_ansi(color)
        self.bkgColor = C64Color.toC64(c)

    def setBkgColorFGB(self, r: int, g: int, b: int) -> None:
        c = Color.from_rgb(r, g, b)
        self.bkgColor = C64Color.toC64(c)


class C64():
    SCREEN_WIDTH = 40
    SCREEN_HEIGHT = 25
    DEFAULT_TEXT_COLOR = 33
    DEFAULT_BKG_COLOR = 18
    screen = []
    color = []
    screen_backbuffer = []

    def __init__(self):
        self.cursor = C64Cursor()
        self.clear()
        self.screen_backbuffer = [ [0x20]*self.SCREEN_HEIGHT for i in range(self.SCREEN_WIDTH)]
        self.ser = serial.Serial('/dev/ttyUSB0', BAUD_SPEED, timeout=0.02)
        self.dump_timer = Timer(1.0, self.dumpser)
        self.dump_timer.start()

    def clear(self):
        self.screen = [ [0x20]*self.SCREEN_HEIGHT for i in range(self.SCREEN_WIDTH)]
        self.color = [ [0x0e]*self.SCREEN_HEIGHT for i in range(self.SCREEN_WIDTH)]

    def dump(self):
        with open("dump.bin", "wb") as file:
            for sy in range(0, self.SCREEN_HEIGHT):
                for sx in range(0, self.SCREEN_WIDTH):
                    file.write(self.screen[sx][sy].to_bytes(1, 'big'))
            for sy in range(0, self.SCREEN_HEIGHT):
                for sx in range(0, self.SCREEN_WIDTH):
                    file.write(self.color[sx][sy].to_bytes(1, 'big'))
        print("Dump finished", file=sys.__stdout__)

    def dumpser(self):
        bResponse = []
        bResponse.append((TO_C64_ESC).to_bytes(1,'big'))
        # bResponse.append((TO_C64_HOME).to_bytes(1,'big'))
        for sy in range(0, self.SCREEN_HEIGHT):
            for sx in range(0, self.SCREEN_WIDTH):
                bResponse.append((self.screen[sx][sy]).to_bytes(1,'big'))
        self.ser.write(b"".join(bResponse))
        self.ser.flush()
        print("Dump Serial finished", file=sys.__stdout__)
        self.dump()
        self.dump_timer = Timer(5, self.dumpser)
        self.dump_timer.start()
# setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're busy receiving

    def executeAnsiCommand(self, params, cmd):
        p = params.split(';')
        match cmd:
            case 'H':
                self.cursor.setPos(int(p[1])-1, int(p[0])-1)
            case 'm':
                self._ansiM(p)
            case _:
                #self.log(f"No matching ANSI command {cmd}")
                pass

    def _ansiM(self, params: list[str]) -> None:
        p = [int(a) for a in params]
        idx = 0
        while idx < len(p):
            match p[idx]:
                case 38: # text color
                    if p[idx+1] == 2:
                        self.cursor.setTextColorRGB(p[idx+2], p[idx+3], p[idx+4])
                        idx += 5
                    elif p[idx+1] == 5:
                        self.cursor.setTextColor(p[idx+2])
                        idx += 3
                case 48: # background
                    if p[idx+1] == 2:
                        self.cursor.setTextColorRGB(p[idx+2], p[idx+3], p[idx+4])
                        idx += 5
                    elif p[idx+1] == 5:
                        self.cursor.setBkgColor(p[idx+2])
                        idx += 3
                case 1:  # bold
                    idx += 1
                case 2:  # dim
                    idx += 1
                case 3:  # italic
                    idx += 1
                case 0:
                        self.cursor.setTextColor(self.DEFAULT_TEXT_COLOR)
                        self.cursor.setBkgColor(self.DEFAULT_BKG_COLOR)
                        idx += 1
                case _:
                    print(f"Unknown color command {p[idx]}", file=sys.__stdout__)
                    return


    def put(self, b: int):
        if b == 0x0a:
            self.cursor.newLine()
            return
        self.screen[self.cursor.x][self.cursor.y] = b
        # print(f" ({self.cursor.x},{self.cursor.y}) b", file=sys.__stdout__)
        self.color[self.cursor.x][self.cursor.y] = self.cursor.textColor
        self.cursor.nextPos()

    def fromC64(self, b: int) -> tuple[str, str | None]:
        # https://sta.c64.org/cbm64petkey.html
        printables: dict[int, str] = {
            0x5c: '£', # POUND SIGN
            0x5e: '^', # CIRCUMFLEX ACCENT
        }
        # for list of available values see this link but there are more: from textual.keys import _get_key_aliases
        functional: dict[int, str] = {
            0x03: 'escape',   # STOP
            0x06: 'shift+tab',# CTRL + left arrow
            0x0d: 'enter',    # RETURN
            0x11: 'down',     # cursor down
            0x13: 'home',     # HOME
            0x14: 'delete',   # DELETE
            0x1d: 'right',    # cursor right
            0x5f: 'tab',      # left arrow
            0x83: 'shift+escape',# SHIFT + RUN/STOP
            0x85: 'f1',       # F1
            0x86: 'f3',       # F3
            0x87: 'f5',       # F5
            0x88: 'f7',       # F7
            0x89: 'f2',       # F2
            0x8a: 'f4',       # F4
            0x8b: 'f6',       # F6
            0x8c: 'f8',       # F8
            0x8d: 'shift+return', # SHIFT + F1
            0x91: 'up',       # cursor up
            0x93: 'end',      # SHIFT + CLR/HOME
            0x94: 'insert',   # SHIFT + INST/DEL
            0x9d: 'left',     # cursor left
        }
        #https://style64.org/petscii/
        gfx: dict[int, str] = {
            0x7b: '┼', # BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
            0xc0: '─', # BOX DRAWINGS LIGHT HORIZONTAL
            0xdc: '', # LEFT HALF BLOCK MEDIUM SHADE (CUS)
        }
        if ch := printables.get(b, None):
            return ch, ch
        if ch := functional.get(b, None):
            return ch, None
        if 0x20 <= b <= 0x40: # numbers and symbols
            return chr(b), chr(b)
        if 0x41 <= b <= 0x5d: # letters
            return chr(b).lower(), chr(b).lower()
        if 0xc1 <= b <= 0xda: # shift letters
            return chr(b-0x80), chr(b-0x80)
        
        print(f"Decode error of {hex(b)} which is chr {chr(b)}", file=sys.__stdout__)
        return '?', None






class C64Driver(Driver):
    """A driver for Commodore 64 Growser"""

    def __init__(
        self,
        app: App,
        *,
        debug: bool = False,
        size: tuple[int, int] | None = None,
    ) -> None:
        """Initialize a driver.

        Args:
            app: The App instance.
            debug: Enable debug mode.
            size: Initial size of the terminal or `None` to detect.
        """
        size = 40, 25
        super().__init__(app, debug=debug, size=size)
        self._app = app
        self._debug = debug
        self._size = size
        self.stdout = sys.__stdout__
        self.exit_event = Event()
        self._loop = asyncio.get_running_loop()
        self.c64 = C64()
        # _ = asyncio.create_task(self.screen_diff_timer_callback())


    def run_input_thread(self) -> None:
        while not self.exit_event.is_set():
            serial_input = self.c64.ser.read(100)
            for i in serial_input:
                key, char = self.c64.fromC64(i)
                key_event = Key(key, char)
                self.process_event(key_event)


    # @asyncio.coroutine
    # async def screen_diff_timer_callback(self):
    #     while True:
    #         print(f"cau", file=sys.__stdout__)
    #         # await asyncio.sleep(1)
    #         self.c64.dumpser()
    #         time.sleep(2)
    #         print(f"screen sent", file=sys.__stdout__)


    def write(self, data: str) -> None:
        """Write data to the output device.

        Args:
            data: Raw data.
        """
        with open("ansi.bin", "w") as file:
            file.write(data)

        re_ansi = re.compile(r"(\x1b\[)((\d{1,5};)*\d{1,5})(.)")
        ANSI_ESC = 27

        enc = codecs.lookup("screencode_c64_lc")
        idx = 0
        len_data = len(data)
        while idx < len_data:
            b = data[idx]
            if ord(b) == ANSI_ESC:
                m = re_ansi.match(data[idx:])
                if m != None:
                    self.c64.executeAnsiCommand(m.group(2), m.group(4))
                    idx += m.end()
                    continue
            #print(enc.encode(b, errors='replace')[0], file=self.stdout)
            try:
                c64b = enc.encode(b, errors='strict')[0][0] # type: ignore
            except ValueError as e:
                match b:
                    case '\U0001f4c4':
                        c64b = 0x1c
                    case '📁':
                        c64b = 0x66
                    case '\u2014':
                        c64b = 0x40
                    case '\u2b58':
                        c64b = 0x8f
                    case _:
                        if ord(b) in [0x0a]: # convert to ?
                            c64b = ord(b)
                        else:
                            print('b')
                            print('ord(b)')
                            print(e, file=self.stdout)
                            c64b = 0x3f
            self.c64.put(c64b)
            idx += 1
        print("---", file=self.stdout)


    def flush(self) -> None:
        """Flush any buffered data."""
        print("flushuji now")
        # self.c64.dumpser()
        # self.c64.dump()


    def start_application_mode(self) -> None:
        """Start application mode."""
        print("startuji")
        self._key_thread = Thread(target=self.run_input_thread)
        self._key_thread.start()


    def disable_input(self) -> None:
        """Disable further input."""
        try:
            if not self.exit_event.is_set():
                self.exit_event.set()
                if self._key_thread is not None:
                    self._key_thread.join()
                self.exit_event.clear()
        except Exception as error:
            # TODO: log this
            pass


    def stop_application_mode(self) -> None:
        """Stop application mode, restore state."""
        print("zastavuji app")
        self.disable_input()


    def close(self) -> None:
        """Perform any final cleanup."""
        print("toto je close")
        # if self._writer_thread is not None:
        #     self._writer_thread.stop()

