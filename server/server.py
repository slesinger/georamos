from rich.syntax import Syntax
from textual.app import App, ComposeResult
from textual.containers import Horizontal
from textual.reactive import var
from textual.widgets import Button, DirectoryTree, Header, Footer, Static, TextArea
from drivers.c64driver import C64Driver

import sys

"""
border jen solid
c64  name  idx
0 black   16
1 white   231
2 darkred 88
3 cyan    51
4 violet  213
5 green   28
6 darkblue 18
7 yellow  226
8 orange  214
9 saddlebrown 94
a red     196
b darkslategray 23
c gray    244
d lightgreen 120
e dodgerblue 33
f lightgray 252
"""

TEXT = """\
def hello(na:e)X
    print("hellX

def goodbye(namX
    print("goodX
"""


class ColorApp(App):
    CSS_PATH = "server.tcss"

    BINDINGS = [
        ("f", "toggle_files", "Toggle Files"),
        ("q", "quit", "Quit"),
    ]

    show_tree = var(True)

    def watch_show_tree(self, show_tree: bool) -> None:
        """Called when show_tree is modified."""
        self.query_one(DirectoryTree).set_class(show_tree, "-show-tree")

    def compose(self) -> ComposeResult:
        yield Header(show_clock=False)
        yield Horizontal(
            DirectoryTree("./netdisk", id="dirtree"),  #https://github.com/juftin/textual-universal-directorytree
            TextArea(TEXT, id="code", language="python"),
            classes="column",
        )
        yield Footer()

    def on_mount(self) -> None:
        self.title = "Growser"
        self.sub_title = "Files"
        self.query_one(DirectoryTree).show_root = False
        self.query_one(DirectoryTree).guide_depth = 2

    def on_directory_tree_file_selected(self, event: DirectoryTree.FileSelected) -> None:
        """Called when the user click a file in the directory tree."""
        event.stop()
        code_view = self.query_one("#code", TextArea)
        try:
            syntax = Syntax.from_path(
                str(event.path),
                line_numbers=True,
                word_wrap=False,
                indent_guides=True,
                theme="github-dark",
            )
        except Exception as e:
            code_view.load_text(str(e))
            self.sub_title = "ERROR"
        else:
            code_view.load_text(str(syntax))
            #self.query_one("#code-view").scroll_home(animate=False)
            self.sub_title = str(event.path)

    def on_key(self, event) -> None:
        print(f"event {event}", file=sys.__stdout__)
        # sys.exit(0)

    def action_toggle_files(self) -> None:
        """Called in response to key binding."""
        self.show_tree = not self.show_tree


if __name__ == "__main__":
    app = ColorApp(driver_class=C64Driver)
    app.run()
