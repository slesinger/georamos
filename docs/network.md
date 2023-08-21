# API Specifications

## network_dirfile
Loads dir/file table in dir/file table format. It is (5+95)*256 in size. Dir/file table restrictions apply and must be enforced by server side.

Resource: /dirfile
Response: full dirfile table


## network_get
Retrieve file to store it in memory or georam. This can be used for data files as well as PRG files.

Resource: /get
Response:
  - file table entry
  - file data to memory
  - file data to georam To be implemented


## network_upload
Resource: /get/{filename16 type1}


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