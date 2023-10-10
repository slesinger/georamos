<?php
// https://invisible-island.net/ncurses/man/ncurses.3x.html
// https://github.com/gansm/finalcut#class-digramm
// https://github.com/gansm/finalcut/blob/main/doc/first-steps.md#first-steps-with-the-final-cut-widget-toolkit
// https://codedocs.xyz/gansm/finalcut/annotated.html


const SCREEN_WIDTH = 40;
const SCREEN_HEIGHT = 25;

class Screen {
    private $cur_x = 0;
    private $cur_y = 0;
    private $cur_color = 0;
    private $char;
    private $color;
    private $char_backbuffer;
    
    function __construct() {
        $this->clear();
        $this->char_backbuffer = array2d(SCREEN_WIDTH, SCREEN_HEIGHT, $value = ' ');

    }
    function __destruct() {
    }

    function clear() {
        $this->char = array2d(SCREEN_WIDTH, SCREEN_HEIGHT, $value = ' ');
        $this->color = array2d(SCREEN_WIDTH, SCREEN_HEIGHT, $value = 0x0e);
    }

    function move($x, $y) {
        $this->cur_x = $x;
        $this->cur_y = $y;
    }
    function printw($str) {
        for ($i = 0; $i < strlen($str); $i++) {
            $this->addch($str[$i]);
        }
    }
    function addch($ch) {
        $cir = 0;
        $this->char[$this->cur_x][$this->cur_y] = $ch;
        $this->color[$this->cur_x][$this->cur_y] = $this->cur_color;
        $this->cur_x++;
        if ($this->cur_x >= SCREEN_WIDTH) {
            $this->cur_x = 0;
            $this->cur_y++;
            if ($this->cur_y >= SCREEN_HEIGHT) {
                $this->cur_y = 0;
            }
        }
    }
    // function color_set($color) {
    //     $cur_color = $color;
    // }
    function refresh() {
        // ncurses_refresh();
    }
    function getch() {
        // return ncurses_getch();
    }

    function print_diff_petscii() {
        // discover diff
        $cmd_str = "";
        $cmd_x_start = -1;
        $cmd_x_end = -1;
        $cmd_y = -1;
        for ($y = 0; $y < SCREEN_HEIGHT; $y++) {
            for ($x = 0; $x < SCREEN_WIDTH; $x++) {
                if ($this->char[$x][$y] != $this->char_backbuffer[$x][$y]) {
                    if ($cmd_y == $y && $cmd_x_end + 1 == $x) {  // just add to current  string
                        $cmd_x_end = $x;
                        $cmd_str .= $this->char[$x][$y];
                    } else {  // finalize difference string and start new one
                        // print old difference
                        if ($cmd_str != "") {
                            print(chr(0x08) . chr(0x13) . chr($cmd_x_start) . chr($cmd_y));  // move cursor
                            // print("x: $cmd_x_start, y: $cmd_y, ");
                            print(chr(0x08) . chr(0x12) . $cmd_str . chr(0x00));
                        }
                        // start new difference
                        $cmd_x_start = $x;
                        $cmd_x_end = $x;
                        $cmd_y = $y;
                        $cmd_str = $this->char[$x][$y];
                    }
                }
            }
        }
                        // print old difference
                        if ($cmd_str != "") {
                            print(chr(0x08) . chr(0x13) . chr($cmd_x_start) . chr($cmd_y));  // move cursor
                            // print("x: $cmd_x_start, y: $cmd_y, ");
                            print(chr(0x08) . chr(0x12) . $cmd_str . chr(0x00));
                        }
        
        // copy to backbuffer
        $this->char_backbuffer = $this->char;
    }

    function print_full_ascii() {
        for ($y = 0; $y < SCREEN_HEIGHT; $y++) {
            print("|");
            for ($x = 0; $x < SCREEN_WIDTH; $x++) {
                print($this->char[$x][$y]);
            }
            print("|\n");
        }
    }

}


function array2d($m, $n, $value = 0) {
    return array_fill(0, $m, array_fill(0, $n, $value));
  }
?>