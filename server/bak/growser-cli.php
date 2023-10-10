<?php

require_once('ncurses/application.php');
require_once('ncurses/label.php');
require_once('ncurses/dialog.php');
require_once('ncurses/button.php');

$app = new Application();
$movingLabel = new Label("Hello world!", 2, 1);
$app->add($movingLabel);
$dialog1 = new Dialog("Dialog", 10, 10, 21, 11);
$app->add($dialog1);
$dialog1->add(new Button("OK", 2, 2));
$dialog1->add(new Button("Cancel", 8, 2));
$app->draw();
$app->getScreen()->print_full_ascii();

while (true) {
    $ch = readline();
    $movingLabel->setText($ch);
    $movingLabel->setX(rand(0, 20));
    $movingLabel->setY(rand(0, 10));
    $app->draw();
    $app->getScreen()->print_full_ascii();
    $app->getScreen()->print_diff_petscii();
}

?>
