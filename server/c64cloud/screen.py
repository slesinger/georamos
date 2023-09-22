from apps.empty import Empty
from apps.terminal import Terminal
from screencodes import ScreenCodes
from enum import IntEnum
import os

class OperationMode(IntEnum):
    SCREEN = 0  # render screen widgets
    TERMINAL = 1

'''
Responsible for switchin screens C= 1-9 and 0
Holds overall context
'''
class Screen():

    cmd_numbers = [ScreenCodes.CMD_1, ScreenCodes.CMD_2,ScreenCodes.CMD_3,
        ScreenCodes.CMD_4,ScreenCodes.CMD_5,ScreenCodes.CMD_6,
        ScreenCodes.CMD_7,ScreenCodes.CMD_8,ScreenCodes.CMD_9]

    active_console = 1
    op_mode = OperationMode.SCREEN
    consoles = []
    download_data = None

    def __init__(self) -> None:
        self.consoles = [
            Commodore(1),
            Empty(2), 
            Terminal(3),
            Empty(4),
            Empty(5),
            Empty(6),
            Empty(7),
            Empty(8),
            Empty(9),
        ]

    def dispatchScanCodes(self, scancodes):
        for sc in scancodes:
            # catch special codes that should be handle by screen
            if sc == 0x5f: #C=<-
                self.startMenu()
                continue
            if sc == 0xac: #C=d
                self.download()
                continue
            if sc == 0xb8: #C=u
                self.upload()
                continue
            if sc in self.cmd_numbers: #1-9,0 switch consoles
                self.switchTo(self.cmd_numbers.index(sc))
                continue

            #else send key to cloud application running in a console
            self.consoles[self.active_console].putScanCode(sc)
            self.consoles[self.active_console].execute()  #TODO Replace by threading


    '''
    Return screen updates as screencodes bytes, or download bytes
    '''
    def getNewScreenCodes(self):
        if self.download_data:
            return ScreenCodes.SCR_DOWNLOAD_TO_MEMORY.to_bytes(1,'big') + self.download_data  #PRG contains memory address already
        else:
            return self.consoles[self.active_console].getNewScreenCodes()


    def switchTo(self, consoleId):
        self.active_console = consoleId
        self.consoles[self.active_console].sendWholeScreen()

    def startMenu(self):
        pass

    def download(self):
        HOME = '../home'
        filename = 'PRG'
        full_fn = os.path.join(HOME, filename)
        with open(full_fn, mode="rb") as binary_file:
            self.download_data = binary_file.read()
            print(f"Ready for download {len(self.download_data)} from {full_fn}")

        # zazalohuj obrazovku
        # renderuj input pro file name na teto urovni
        # cekej na vstup
        # spust dowload
        pass


    def upload(self):
        pass

class Commodore():
    def __init__(self, console_id):
        pass

    def putScanCode(self, scancode):
        pass

    def getNewScreenCodes(self):
        return b""

    def sendWholeScreen(self):
        self.screencodes_queue = []
    
    def execute(self):
        pass