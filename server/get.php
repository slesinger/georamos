<?php

function base16AP2bytes($b16) {
    $bytes = array();
    for ($i = 0; $i < strlen($b16); $i += 2) {
        $a = ord($b16[$i]) - 97;
        $b = ord($b16[$i+1]) - 97;
        $bytes[] = ($a << 4) | $b;
    }
    return $bytes;
}

const BASE_DIR = './netdisk/';
$fn = strtolower($_GET['f']);
if (str_contains(substr(substr($fn, -8), 0, 4), '.prg')) {
    $origAddr = substr($fn, -4);
    $fn = substr($fn, 0, -4);
}

if (isset($_GET['p'])) {
    $payload = strtolower($_GET['p']);
    // Upload payload
    $fp = fopen(BASE_DIR . $fn, 'wb');
    if (isset($origAddr)) {
        fwrite($fp, pack('C*', ...base16AP2bytes($origAddr)));
    }
    fwrite($fp, pack('C*', ...base16AP2bytes($payload)));
    fclose($fp);
    header('Content-Type: text/plain');
}
else if (isset($_GET['a'])) {
    $append_payload = strtolower($_GET['a']);
    // Append payload
    $fp = fopen(BASE_DIR . $fn, 'ab');
    fwrite($fp, pack('C*', ...base16AP2bytes($append_payload)));
    fclose($fp);
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
