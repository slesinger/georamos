*=$1000


ldx #$00
lda my_text,x
sta $0500,x
inx


my_text:
.text "Hello World!"