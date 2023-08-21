<?php
const BASE_DIR = './netdisk/';
const MAX_ENTRIES_PER_BLOCK = 12;
const MAX_BLOCKS_FOR_DIRS = 5;  // see layout.md dir table
const MAX_BLOCKS_FOR_FILES = 95;  // see layout.md file table
const FILEDIR_ENTRY_LENGTH = 21;
const BLOCK_LENGTH = 256;
$file_types = array(
    "DIR" => 64,
    "PRG" => 128,
    "SEQ" => 192,
);

$myDirectory = opendir(BASE_DIR);
while($entryName = readdir($myDirectory)) {
    $dirArray[] = $entryName;
}
closedir($myDirectory);

sort($dirArray);

$parent_directory_id = 0;

header('Content-Type: application/octet-stream');
print(chr(0) . chr(0));  // each download must prepend target memory address. here it is faked to $0000

$current_entry_idx = 0;
$current_block_idx = 0;
// loop over directories
for($index=0; $index < count($dirArray); $index++) {
    $entry = $dirArray[$index];
    if (substr($entry, 0, 1) != ".") { // don't list hidden files
        $base = strtoupper(substr($entry, 0, 16));
        if (is_dir(BASE_DIR . $entry)) {  // Only dir
            $file_flags = $parent_directory_id + 64;  // 64 is flag indicating directory
            $file_size = ceil(filesize(BASE_DIR . $entry) / 256);  // TODO fetch number of files in subdirectory
            $file_name = str_pad($base, 16, " ");
            $file_original_address = 0;
            $file_sector_pointer = 0;
            $file_block_pointer = 0;
            $out_line = chr($file_flags) . chr($file_size) . $file_name . chr($file_original_address) . chr($file_sector_pointer) . chr($file_block_pointer);
            print($out_line);
            $current_entry_idx++;
            if ($current_entry_idx == MAX_ENTRIES_PER_BLOCK) {
                $current_entry_idx = 0;
                $out_line = str_repeat(chr(0), 4); // filler till end of block
                print($out_line);
                $current_block_idx++;
                if ($current_block_idx == MAX_BLOCKS_FOR_DIRS) {
                    break; // no more directories can fit in the dir table
                }
            }
        }
    }
}

// fill rest of current block
$missing_entries = MAX_ENTRIES_PER_BLOCK - $current_entry_idx;
print(str_repeat(chr(0x00), $missing_entries * FILEDIR_ENTRY_LENGTH + 4));

// fill rest of directory table blocks until block 5
$missing_dirblocks = MAX_BLOCKS_FOR_DIRS - $current_block_idx;
print(str_repeat(chr(0x00), ($missing_dirblocks - 1) * BLOCK_LENGTH));

// loop over files
$current_block_idx = 0;
$current_entry_idx = 0;
for($index=0; $index < count($dirArray); $index++) {
    $entry = $dirArray[$index];
    if (substr($entry, 0, 1) != ".") { // don't list hidden files
        $ext  = strtoupper(substr(strrchr($entry, '.'), 1));
        $base = strtoupper(substr(substr($entry, 0, strlen($entry) - strlen(strrchr($entry, '.'))), 0, 16));
        if ($ext == "PRG" || $ext == "SEQ") {  // Only .prg amd .seq files
            $file_type_bits = $file_types[$ext];
            $file_flags = $parent_directory_id + $file_type_bits;
            $file_size = ceil(filesize(BASE_DIR . $entry) / 256);
            $file_name = str_pad($base, 16, " ");
            $file_original_address = 0;
            $file_sector_pointer = 0;
            $file_block_pointer = 0;
            $out_line = chr($file_flags) . chr($file_size) . $file_name . chr($file_original_address) . chr($file_sector_pointer) . chr($file_block_pointer);
            print($out_line);
            $current_entry_idx++;
            if ($current_entry_idx == MAX_ENTRIES_PER_BLOCK) {
                $current_entry_idx = 0;
                $out_line = str_repeat(chr(0), 4); // filler till end of block
                print($out_line);
                $current_block_idx++;
                if ($current_block_idx == MAX_BLOCKS_FOR_FILES) {
                    break; // no more files can fit in the dir table
                }
            }
        }
    }
}

// fill rest of current block
$missing_entries = MAX_ENTRIES_PER_BLOCK - $current_entry_idx;
print(str_repeat(chr(0), $missing_entries * FILEDIR_ENTRY_LENGTH + 4));

?>
