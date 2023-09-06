<?php
const BASE_DIR = './netdisk/';
$fn = strtolower($_GET['f']);
$payload = strtolower($_GET['p']);
if (isset($payload)) {
    // Upload payload
    $fp = fopen(BASE_DIR . $fn, 'wb');
    fwrite($fp, $payload);
    fclose($fp);

    // send http result
    header('Content-Type: text/plain');

}
else {
    // Download file
    $filesize = filesize(BASE_DIR . $fn);
    $fp = fopen(BASE_DIR . $fn, 'rb');
    $binary = fread($fp, $filesize);
    fclose($fp);

    // send binary data as http result
    header('Content-Type: application/octet-stream');
    // header('Content-Length: ' . $filesize);
    print($binary);
    print(chr(0x00) . chr(0x00));  // this is a hack because wic64 firware wrongly detects length of payload
}
?>
