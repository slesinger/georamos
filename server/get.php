<?php
$fn = "./netdisk/hdnmirror";
// Read binary file
$filesize = filesize($fn);
$fp = fopen($fn, 'rb');
$binary = fread($fp, $filesize);
fclose($fp);

// send binary data as http result
header('Content-Type: application/octet-stream');
header('Content-Length: ' . $filesize);
echo $binary;
?>
