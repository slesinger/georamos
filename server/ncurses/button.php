<?php

require_once('ncurses/widget.php');

class Button extends Widget {
    private $text;

    function __construct($text, $x, $y) {
        $this->text = $text;
        $this->x = $x;
        $this->y = $y;
    }

    function __destruct() {
    }

    function draw($screen) {
        $screen->move($this->x, $this->y);
        $screen->printw("[" . $this->text . "]");
    }
}

?>