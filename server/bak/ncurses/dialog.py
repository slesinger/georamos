from ncurses.widget import Widget

class Dialog(Widget):

    def __init__(self, text, x, y, width, height):
        super().__init__(x, y, width, height, self)
        self.text = text
        self.x = x
        self.y = y
        self.width = width
        self.height = height


    def draw(self, screen):
        super().draw(screen)
        # draw frame using characters
        for x in range(0, self.width):
            screen.move(self.x + x, self.y)
            screen.printw('=')
            screen.move(self.x + x, self.y + self.height-1)
            screen.printw('-')
        
        for y in range(0, self.height):
            screen.move(self.x, self.y + y)
            screen.printw('|')
            screen.move(self.x + self.width-1, self.y + y)
            screen.printw('|')
            
        screen.move(self.x + 1, self.y)
        screen.printw(self.text)
