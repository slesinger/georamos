# Growser

Growser is a thin client browser of georamos that displays screen updates coming over the network, like telnet and ncurses.

## Poll API response format

Block:
  $08 - block magic, escape character
  1B  - command
  xB  - data


## Commands (with parameters)

  $01 - STA value (address 2B, value 1B)

  $02 - ORA AND value (address 2B, ora value 1B, and value 1B)

  $10 - clear screen ()

  $11 - render rectangle (x, y, w, h, data)
  
  $12 - output text (null terminated petscii string)

  $13 - set cursor position (x, y)

$fe - hide growser
$ff - exit growser

