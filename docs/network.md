# API Specifications

Each response contain first two bytes the target memory address.

## network_dirfile
Loads dir/file table in dir/file table format. It is (5+95)*256 in size. Dir/file table restrictions apply and must be enforced by server side.

Resource: /dirfile
Response: full dirfile table of current directory


## network_get
Retrieve file to store it in memory or georam. This can be used for data files as well as PRG files.

Resource: /get?f=<max16b filename>
Response:
  - file table entry
  - file data to memory
  - file data to georam To be implemented


## network_put
Resource: /get?f=<max16b filename>&p=<base16AP payoad>
Payload is sent to server in chunks of 256bytes


## Create Directory

Resource: /ndir


/del

# Notes

Monitor wic64 serial by
```
screen /dev/ttyUSB0 115200
```
Exit screen by ^a then :quit

mac addr: 30:...:d6:cc  WiC64-30:AE:A4:F7:D6:CC