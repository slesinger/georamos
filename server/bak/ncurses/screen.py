# https://invisible-island.net/ncurses/man/ncurses.3x.html
# https://github.com/gansm/finalcut#class-digramm
# https://github.com/gansm/finalcut/blob/main/doc/first-steps.md#first-steps-with-the-final-cut-widget-toolkit
# https://codedocs.xyz/gansm/finalcut/annotated.html
# https://github.com/irmen/cbmcodecs2

'''
Codes 192-223 as codes  96-127
Codes 224-254 as codes 160-190
Code  255     as code  126
Code   14 Big / small letters / chars
Code  142 Big / graphic letters / chars
'''

import cbmcodecs2

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

class Screen:
    cur_x = 0
    cur_y = 0
    cur_color = 0
    char = []
    color = []
    char_backbuffer = []
    
    def __init__(self):
        self.clear()
        self.char_backbuffer = [ [' ']*SCREEN_HEIGHT for i in range(SCREEN_WIDTH)]


    def clear(self):
        self.char = [ [' ']*SCREEN_HEIGHT for i in range(SCREEN_WIDTH)]
        self.color = [ [0x0e]*SCREEN_HEIGHT for i in range(SCREEN_WIDTH)]
    

    def move(self, x, y):
        self.cur_x = x
        self.cur_y = y
    
    def printw(self, str):
        for i in range(0, len(str)):
            self.addch(str[i])
        
    
    def addch(self, ch):
        cir = 0
        self.char[self.cur_x][self.cur_y] = ch
        self.color[self.cur_x][self.cur_y] = self.cur_color
        self.cur_x += 1
        if (self.cur_x >= SCREEN_WIDTH):
            self.cur_x = 0
            self.cur_y += 1
            if (self.cur_y >= SCREEN_HEIGHT):
                self.cur_y = 0
            
        
    
    # def color_set(color):
    #     cur_color = color
    # 
    def refresh(self):
        pass
        # ncurses_refresh()
    
    def getch(self):
        pass
        # return ncurses_getch()
    

    def diff_petscii(self):
        br = []
        # discover diff
        cmd_str = ""
        cmd_x_start = -1
        cmd_x_end = -1
        cmd_y = -1
        for y in range(0, SCREEN_HEIGHT-20):
            for x in range(0, SCREEN_WIDTH):
                if self.char[x][y] != self.char_backbuffer[x][y]:
                    if cmd_y == y and cmd_x_end + 1 == x:  # just add to current  string
                        cmd_x_end = x
                        cmd_str += self.char[x][y]
                    else:  # finalize difference string and start new one
                        # print old difference
                        if cmd_str != "":
                            br += [0x08, 0x13, cmd_x_start, cmd_y]  # move cursor
                            # print("x: cmd_x_start, y: cmd_y, ")
                            br += [0x08, 0x12]
                            br += cmd_str.encode("ascii",errors="replace")
                            br += [0x00]
                        
                        # start new difference
                        cmd_x_start = x
                        cmd_x_end = x
                        cmd_y = y
                        cmd_str = self.char[x][y]
        
                        # print old difference
                        if cmd_str != "":
                            br += [0x08, 0x13, cmd_x_start, cmd_y]  # move cursor
                            # print("x: cmd_x_start, y: cmd_y, ")
                            br += [0x08, 0x12]
                            br += cmd_str.encode("ascii",errors="replace")
                            br += [0x00]
        return bytes(br)
                        
        # copy to backbuffer
        self.char_backbuffer = self.char
    

    def print_full_ascii(self):
        for y in range(0, SCREEN_HEIGHT):
            print("|")
            for x in range(0, SCREEN_WIDTH):
                print(self.char[x][y])
            print("|\n")

