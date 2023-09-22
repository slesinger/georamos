from ncurses.widget import Widget

class Button(Widget):

    def __init__(self, text, x, y):
        self.x = x
        self.y = y
        self.text = text

    def draw(self, screen):
        screen.move(self.x, self.y)
        screen.printw("[" + self.text + "]")
