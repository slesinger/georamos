# File System and Backends

File system is a common interface to talk to various backends.

### Backend file systems

- georam disk
- network "bucket"
- floppy disk
- iec2sd

# Interface

## format file system
[x] georam   [ ] net  [x] floppy


## get dirfile table entry pointer
to be used in dowload_to_memory_impl

## get content of current dir
Use directory of current panel
Populate file/dir table in memory (for floppy do not use 0801)

## upload
from memory to backend
- start addr
- end addr
- file name
- type (prg, seq)


## download
From backend to memory

**Inputs**
- backend type
- dirfile table entry pointer
- to specified memory address by user. If $ffff then use original address from dirfile table or prg

(How seq files are handled differently? No original address in first two bytes.)

**Return**
- address of last byte of memory after download


## execute
download to original address and jmp to first address or run a basic script

## rename file

## delete file

## get file details

## change to directory

## create directory

## rename directory

## delete directory

# Currently available
resolve_next_sector_block
fs_format
get_first_dir_entry
get_next_dir_entry
create_file (empty file, unclosed)
write_file
find_first_free_file_entry
find_free_fat_entry
save_next_to_pointer_table
save_eof_to_pointer_table