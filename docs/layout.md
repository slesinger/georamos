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

