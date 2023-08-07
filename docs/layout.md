# Layout and structures

## GeoRAM Layout
4MB GeoRAM contains 16384 blocks. That equals to ~25 floppy disks. Each block is 256 bytes long. Block that is paged (mounted) to IO1 memory space at $DE00 is called a page.

#### Block paging
```
    lda #$00
    sta $dfff  // 0-256 for 4MB Georam
    lda #$00
    sta $dffe  // 0-63
```

## Layout, files and address mapping

|sector|block|asm file|address|segments|purpose|
------------------------------------------------
|0|0|block_0000|c800|copy_bootstrap|copy first 256 bytes to c800, jmp to bootstrap_code, copy all other blocks|
|0|1|block_0001|c900|menu|TBD|


## Boot block

Boot block (block 0) contains code that copies bootstrapping code to botstrap address $C000.

Bootstrapping code will control what block is paged into IO1 memory space. Bootstrap will page all other blocks that form GeoRAMOS and copies them to $C100

### Zero block schema

```
copy_bootstrap:  (=$00)
    copy bootstrap_code > $c000, until bootstrap_end is reached
    jump to $c000

bootstrap_code:
    page in block 1 -7
    copy to $c100 - $cf00
    jmp $cb20  (52000)   // To be updated
bootstrap_end:
```

# HDD layout
Sector 0    , block    0-27 : GeoRAMOS (28 blocks)
Sector 0    , blocks  28-32 : Directory table (5 blocks)
Sector 0    , blocks  33-127: File table (100 blocks)              [$84000]
Sector 0    , blocks 128-190: FAT sector pointer table (63 blocks) [$200000]
Sector 0    , block  191    : unused
Sector 0    , blocks 192-254: FAT block pointer table (63 blocks)  [$300000]
Sector 0    , block  255    : unused
Sector 01-63                : data area

## Directory table / File table
Total dir table size 100blocks*256bytes = 25600bytes
Each block holds 12 entries (20bytes/entry * 12 = 240 < 256)
Maximum directories: 60

Record is fixed length (20bytes):
- 0B  directory id is implicit by its position, needed for linking as parent directory
- 1B  file flags / parent directory id
  - 6bits  parent directory id
  - 2bits  file flags
- 1B  size in blocks (block=256bytes, max 256)
- 16B filename, max 16chars, filled with blank spaces
- 1B  sector pointer to first "FAT sector pointer table"/"FAT block pointer table" record (values 1-63)
- 1B  block pointer to first "FAT sector pointer table"/"FAT block pointer table" record

First 5 blocks -> 60 entries is reserved for directories.
Very first record is root directory /.

#### File flags (highest 2 bits 64 and 128)
b00xxxxxxxx scratched / does not exist
b01xxxxxxxx directory  DIR
b10xxxxxxxx file PRG
b11xxxxxxxx file SEQ
> See 4.4. http://www.devili.iki.fi/pub/Commodore/docs/books/Inside_Commodore_DOS_OCR.pdf


## File Allocation Table

Maximum file size: 256 blocks (64KB)
Minimum blocks per file: 1 (256 bytes)
Maximum number of files: 63 - 1280(avg file size <16block is ok (<$1000)) 
Maximum fat records: 1280


#### FAT record
Position of FAT record in "FAT sector pointer table" and "FAT block pointer table" (same in both) reflects position of data block.
- 1B sector of next block or in case last record of the file it is $00 - organized as "FAT sector pointer table"
- 1B block of next block  or in case last record of the file number of bytes belonging from the block - organized as "FAT block pointer table"
If FAT block table record contains 0, corresponding data space is not allocated.


