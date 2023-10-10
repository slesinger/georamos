import sys
sys.path.append('..') 
from console import Console

class Empty(Console):
    def __init__(self, console_id):
        welcome = ("                                        " + \
            f"    **** COMMODORE 64 CONSOLE {console_id} ****    " + \
            "                                        " + \
            " 64K RAM SYSTEM  38911 TOTAL BYTES FREE " +\
            "                                        " + \
            "READY.")
        super().__init__(console_id)
        self.appendScreenCodes(welcome)

    def putScanCode(self, scancode):
        print(scancode)
        pass

    def execute(self):
        pass

