<?php
const BASE_DIR = './netdisk/';
$fn = strtolower($_GET['f']);
// Read binary file
$filesize = filesize(BASE_DIR . $fn);
$fp = fopen(BASE_DIR . $fn, 'rb');
$binary = fread($fp, $filesize);
fclose($fp);

// send binary data as http result
header('Content-Type: application/octet-stream');
header('Content-Length: ' . $filesize);
echo $binary;
?>
