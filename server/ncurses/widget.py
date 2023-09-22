class Widget:
    x = 0
    y = 0
    width = 0
    height = 0
    # parent
    widgets = []

    def __init__(self, x, y, width, height, parent):
        self.x = x
        self.y = y
        self.width = width
        self.height = height

        # if parent != None:
        #     self.parent = parent
        #     parent.add(self)

    def add(self, widget):
        self.widgets.append(widget)

    def setX(self, x):
        self.x = x

    def setY(self, y):
        self.y = y

    def draw(self, screen):
        # clean area of the widget
        for y in range(0, self.height):
            screen.move(self.x, self.y + y)
            screen.printw(' ' * self.width)

        # draw children
        for widget in self.widgets:
            widget.draw(screen)
