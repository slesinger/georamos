from ncurses.label import Label
from ncurses.screen import Screen
from ncurses.dialog import Dialog
from ncurses.button import Button


class Application:
    widgets = []

    def __init__(self):
        self.screen = Screen()
        pass

        movingLabel = Label("HELLO WORLD!", 2, 1)
        self.add(movingLabel)
        dialog1 = Dialog("DIALOG", 10, 10, 21, 11)
        self.add(dialog1)
        dialog1.add(Button("OK", 2, 2))
        dialog1.add(Button("CANCEL", 8, 2))
        movingLabel.setText('MEDLIK')
        self.draw()


    def add(self, widget):
        self.widgets.append(widget)
    

    def draw(self):
        self.screen.clear()
        for widget in self.widgets:
            widget.draw(self.screen)
        
