# Layout and structures

## GeoRAM Layout
4MB GeoRAM contains 16384 blocks. That equals to ~25 floppy disks. Each block is 256 bytes long. Block that is paged (mounted) to IO1 memory space at $DE00 is called page.

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

Boot block (block 0) contains code that copies bootstrapping code to botstrap address $C800 (51200).

Bootstrapping code will control what block is paged into IO1 memory space. Bootstrap will page all other blocks that form GeoRAMOS and copies them to $C900

### Zero block schema

```
copy_bootstrap:  (=$00)
    copy bootstrap_code > $c800, until bootstrap_end is reached
    jump to $c800

bootstrap_code:
    page in block 1 -7
    copy to $c900 - $cf00
    jmp $cb20  (52000)
bootstrap_end:
```

# HDD layout
Sector 0    , block    0-26 : GeoRAMOS
Sector 0    , blocks  27-127: Dirctory structure (100 blocks)
Sector 0    , blocks 128-190: FAT sector pointer table (63 blocks)
Sector 0    , blocks 191    : unused
Sector 0    , blocks 192-254: FAT block pointer table (63 blocks)
Sector 0    , blocks 255    : unused
Sector 01-63                : data area

## Dir table
Total dir table size 100blocks*256bytes = 25600bytes

Record is fixed length (20bytes):
- 1B  size in blocks (block=256bytes, max 256)
- 16B filename, max 16chars, filled with blank spaces
- 1B  file type
- 1B  sector pointer to first "FAT sector pointer table"/"FAT block pointer table" record (values 1-63)
- 1B  block pointer to first "FAT sector pointer table"/"FAT block pointer table" record


#### File types
$00 scratched
$80 deleted    DEL
$81 sequential SEQ
$82 program    PRG
$83 user       USR
$84 relative   REL
$FF directory  DIR
> See 4.4. http://www.devili.iki.fi/pub/Commodore/docs/books/Inside_Commodore_DOS_OCR.pdf


## File Allocation Table

Maximum file size: 256 blocks (64KB)
Minimum blocks per file: 1 (256 bytes)
Maximum number of files: 63 - 1280(avg file size <16block is ok (<$1000)) 
Maximum fat records: 1280


#### FAT record
Position of FAT record in "FAT sector pointer table" and "FAT block pointer table" (same in both) reflects position of data block.
- 1B sector of next block or in case last record of the file $00 - organized as "FAT sector pointer table"
- 1B block of next block  or in case last record of the file number of bytes belonging from the block - organized as "FAT block pointer table"
If FAT record contains 0, corresponding data space is not allocated.


