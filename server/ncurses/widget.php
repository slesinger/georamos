<?php

class Widget {
    protected $x;
    protected $y;
    private $width;
    private $height;
    private $parent;
    private $widgets = array();

    function __construct($x, $y, $width, $height, $parent) {
        $this->x = $x;
        $this->y = $y;
        $this->width = $width;
        $this->height = $height;

        // if ($parent != null) {
        //     $this->parent = $parent;
        //     $parent->add_child($this);
        // }
    }

    function __destruct() {
    }

    function add($widget) {
        array_push($this->widgets, $widget);
    }

    function setX($x) {
        $this->x = $x;
    }

    function setY($y) {
        $this->y = $y;
    }

    function draw($screen) {
        // clean area of the widget
        for ($y = 0; $y < $this->height; $y++) {
            $screen->move($this->x, $this->y + $y);
            $screen->printw(str_repeat(' ', $this->width));
        }
        // draw children
        foreach ($this->widgets as $widget) {
            $widget->draw($screen);
        }
    }
}

?>