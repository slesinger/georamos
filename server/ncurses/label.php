<?php

require_once('ncurses/widget.php');

class Label extends Widget {
    private $text;

    function __construct($text, $x, $y) {
        parent::__construct($x, $y, strlen($text), 1, $this);
        $this->text = $text;
        $this->x = $x;
        $this->y = $y;
    }

    function __destruct() {
    }

    function setText($text) {
        $this->text = $text;
    }


    function draw($screen) {
        $screen->move($this->x, $this->y);
        $screen->printw($this->text);
    }
}

?>