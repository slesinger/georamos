from abc import ABC, abstractmethod
from screencodes import ScreenCodes
from colorcodes import ColorCodes


'''
A particular console of the parent screen switching class
'''

class Console(ABC):
    SCREEN_WIDTH = 40
    SCREEN_HEIGHT = 25

    def __init__(self, console_id) -> None:
        self.screen_buffer = [ScreenCodes.SPACE.to_bytes(1,'big')] * (self.SCREEN_WIDTH*self.SCREEN_HEIGHT)
        self.color_buffer = bytearray([ColorCodes.BLUE] * (self.SCREEN_WIDTH*self.SCREEN_HEIGHT))
        self.cursor = {'x':0, 'y':0}
        self.keycodes_queue = []
        self.screencodes_queue = []  #list of bytes, holds changes that is to be send to C64
        self.console_id = console_id
        pass


    @abstractmethod
    def putScanCode(self, scancode):
        pass

    @abstractmethod
    def execute(self):
        pass

    '''
    data: list of bytes or string
    Ensure screen scrolling and cursor controls, too.
    '''
    def appendScreenCodes(self, data):
        if isinstance(data, str):
            for c in data:
                self.putchar(ord(c).to_bytes(1,'big'))  # TODO ord zamenit za screencode konverzni funkci, o radek niz taky
            self.screencodes_queue.extend([ord(x).to_bytes(1,'big') for x in data])
        elif isinstance(data, list):  # list of bytes
            print("NOT IMPLEMENTED")   # TODO


    def getNewScreenCodes(self):
        codes = self.screencodes_queue
        self.screencodes_queue = []
        print(type(codes), len(codes), "x" if len(codes) == 0 else type(codes[0]), len(self.screencodes_queue))
        return b"".join(codes)


    def sendWholeScreen(self):
        self.screencodes_queue = []
        self.screencodes_queue.append(ScreenCodes.ESCAPE_SCR.to_bytes(1,'big'))
        self.screencodes_queue.append(int(ScreenCodes.SCR_SET_CURSOR_POS).to_bytes(1,'big'))
        self.screencodes_queue.append(int(0).to_bytes(1,'big'))
        self.screencodes_queue.append(int(0).to_bytes(1,'big'))
        self.screencodes_queue.extend(self.screen_buffer)


    '''
    Writes screecodes integer to cursor position and moves cursor next
    '''
    def putchar(self, screenCode):
        cx = self.cursor['x']
        cy = self.cursor['y']
        buff_pos = self.SCREEN_WIDTH * cy + cx
        self.screen_buffer[buff_pos] = screenCode
        cx += 1
        if cx == self.SCREEN_WIDTH:
            cx = 0
            cy += 1
            if cy == self.SCREEN_HEIGHT:
                self.scrollUp(1)
                cy -= 1
        self.cursor['x'] = cx
        self.cursor['y'] = cy

    def scrollUp(self, num_lines):
        self.screen_buffer = self.screen_buffer[num_lines*self.SCREEN_WIDTH:] + bytearray([ScreenCodes.SPACE]*(self.SCREEN_WIDTH))

