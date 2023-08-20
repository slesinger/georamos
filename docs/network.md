# API Specifications

## network_fetch_dirfile
Loads dir/file table in dir/file table format. It is (5+95)*256 in size. Dir/file table restrictions apply and must be enforced by server side.

Resource: /dirfile
Response: full dirfile table


## network_download
Retrieve file to store it in memory or georam. This can be used for data files as well as PRG files.

Resource: /get
Response:
  - file table entry
  - file data


## network_upload
Resource: /get/{filename16 type1}


## Create Directory

Resource: /ndir


/del