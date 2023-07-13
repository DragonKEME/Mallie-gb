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
    dw  CastleTiles                    ; Start Address
    dw  EndCastleTiles - CastleTiles  ; Size

; Border
    db  0   ; Bank
    dw  BorderTiles
    dw  EndBorderTiles - BorderTiles

; Weed
    db  0   ; Bank
    dw  WeedTiles
    dw  EndWeedTiles - WeedTiles
