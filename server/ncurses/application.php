<?php

require_once('ncurses/screen.php');


class Application {
    private static $screen;
    private static $widgets = array();

    function __construct() {
        $this->screen = new Screen();
    }

    static function add($widget) {
        array_push($this->widgets, $widget);
    }

    function draw() {
        $this->screen->clear();
        foreach ($this->widgets as $widget) {
            $widget->draw($this->screen);
        }
    }

    function getScreen() {
        return $this->screen;
    }

}

?>
