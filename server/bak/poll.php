<?php
require_once('ncurses/application.php');
require_once('ncurses/label.php');
require_once('ncurses/dialog.php');
require_once('ncurses/button.php');


$key = strtolower($_GET['q']);
error_log("Key: " . $key);
header('Content-Type: application/octet-stream');

$app = new Application();
$movingLabel = new Label("HELLO WORLD!", 2, 1);
$app->add($movingLabel);
$dialog1 = new Dialog("DIALOG", 10, 10, 21, 11);
$app->add($dialog1);
$dialog1->add(new Button("OK", 2, 2));
$dialog1->add(new Button("CANCEL", 8, 2));

$movingLabel->setText($key);
$movingLabel->setX(rand(0, 20));
$movingLabel->setY(rand(0, 10));
$app->draw();
$app->getScreen()->print_diff_petscii();
print(chr(0x08) . chr(0x00));

// print(
//     chr(0x08) . chr(0x11) . chr(0x05) . chr(0x03) . chr(0x03) . chr(0x02) .
//     chr(0x41) . chr(0x42) . chr(0x43) . chr(0x44) . chr(0x45) . chr(0x46) .
//     chr(0x08) . chr(0x00)
// );
// zkus na konec ff, aby to kvitlo misto 00
?>
