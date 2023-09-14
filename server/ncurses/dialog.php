<?php

class Dialog extends Widget {

    function __construct($text, $x, $y, $width, $height) {
        parent::__construct($x, $y, $width, $height, $this);
        $this->text = $text;
        $this->x = $x;
        $this->y = $y;
        $this->width = $width;
        $this->height = $height;
    }

    function __destruct() {
    }

    function draw($screen) {
        parent::draw($screen);
        // draw frame using characters
        for ($x = 0; $x < $this->width; $x++) {
            $screen->move($this->x + $x, $this->y);
            $screen->printw('=');
            $screen->move($this->x + $x, $this->y + $this->height-1);
            $screen->printw('-');
        }
        for ($y = 0; $y < $this->height; $y++) {
            $screen->move($this->x, $this->y + $y);
            $screen->printw('|');
            $screen->move($this->x + $this->width-1, $this->y + $y);
            $screen->printw('|');
        }       
        $screen->move($this->x + 1, $this->y);
        $screen->printw($this->text);
     }

}

?>