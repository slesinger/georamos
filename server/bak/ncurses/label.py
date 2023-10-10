
# from server.ncurses. import widget

class Label():
    text = ''

    def __init__(self, text, x, y):
        # super(Widget, self).__init__(x, y, len(text), 1, self)
        self.text = text
        self.x = x
        self.y = y

    def setText(self, text):
        self.text = text


    def draw(self, screen):
        screen.move(self.x, self.y)
        screen.printw(self.text)
