/*
Tile Set Form:
    1                8                 16
    +----------------+-----------------+
    |  Bank Number   |      Tiles...
    +----------------+-----------------+
       ...Location 1 |      ...
    +----------------+------------  <- (n*5 + 1 bytes) 

TilesLocation:
    - Bank number (1 byte): Bank number of tile
    - Start Address (2 bytes): Address of the first tile
    - Size Memory (2 bytes): Size, in Bytes, of tiles

    1                8                 16
    +----------------+-----------------+
    |  Bank Number   |      Start...
    +----------------+-----------------+
       ...Address    |      Size...
    +----------------+-----------------+
       ...Memory     |
    +----------------+  (5 bytes)


*/


CastleBorderWeedTileset:
    db  3           ; Size

; Castle
    db  0                               ; Bank
    dw  CastleSprite                    ; Start Address
    dw  EndCastleSprite - CastleSprite  ; Size

; Border
    db  0   ; Bank
    dw  BorderSprite
    dw  EndBorderSprite - BorderSprite

; Weed
    db  0   ; Bank
    dw  WeedSprite
    dw  EndWeedSprite - WeedSprite
