<?php
$key = strtolower($_GET['q']);
error_log("Key: " . $key);
header('Content-Type: application/octet-stream');
print(
    chr(0x08) . chr(0x11) . chr(0x05) . chr(0x03) . chr(0x03) . chr(0x02) .
    chr(0x41) . chr(0x42) . chr(0x43) . chr(0x44) . chr(0x45) . chr(0x46) .
    chr(0x08) . chr(0x00)
);
// zkus na konec ff, aby to kvitlo misto 00
?>