import sys
sys.path.append('..') 
from console import Console
from screencodes import ScreenCodes
import subprocess, shlex
from threading  import Thread
from queue import Queue, Empty

def enqueue_output(out, queue):
    for line in iter(out.readline, b''):
        queue.put(line)
    out.close()


process = subprocess.Popen(
    shlex.split("bash"),
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE)
q = Queue()
t = Thread(target=enqueue_output, args=(process.stdout, q))
t.daemon = True # thread dies with the program
t.start()


class Terminal(Console):
    def __init__(self, console_id) -> None:
        super().__init__(console_id)
    pass

            # if context['mode'] == MODE_TERMINAL:
                # return terminal(c64key2pckey(scancodes))

    '''
    scancode: int, c64 keyboard scancodes.
    '''
    def putScanCode(self, scancode):
        scancode = self.mapKeys(scancode)
        print(f"Sending to terminal: {hex(scancode)}")
        process.stdin.write(scancode.to_bytes(1,'big'))  # is int
        process.stdin.flush()


    def execute(self):
        pass

    def getNewScreenCodes(self):
        lines = []
        try: 
            for _ in range(10):
                lines.append(self.ascii2screen(q.get(timeout=.1)))  #(q.get_nowait())
            return int(ScreenCodes.ESCAPE_SCR).to_bytes(1,'big') + \
                int(ScreenCodes.SCR_SET_CURSOR_POS).to_bytes(1,'big') + \
                b"".join(lines)
        except Empty:
            # print('no output from terminal')
            return b"".join(lines)

    '''
    TODO use when we receive list of scancodes. now mapkeys is used directly
    '''
    def c64key2pckey(self, c64bytes):
        pcbytes = bytearray()
        for c in c64bytes:
            pcbytes.append(self.mapKeys(c))
        return pcbytes

    def mapKeys(self, i):
        if i == 0x0d: return 0x0a
        if i >= 0x20 and i <= 0x40: return i
        if i >= 0x5B and i <= 0x5F: return i
        if i >= 0xc1 and i <= 0xda: return i - 0x80
        if i >= 0x41 and i <= 0x5a: return i + 0x20

    '''
    line: bytes, output fro terminal
    '''
    def ascii2screen(self, line):
        ret = bytearray(len(line))
        for idx, c in enumerate(line):  #c is int
            d = c
            if c in [0x40, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f]: d = c - 0x40  # @ [ libra ] arrowUp arrowLeft
            if c > 0x61 and c < 0x7b:                     d = c - 0x60
            ret[idx] = d
        return ret
