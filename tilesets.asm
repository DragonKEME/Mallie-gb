; Array and function managing tileset

/*
TabTiles: (3xN bytes)
    Contens a array of tilesset descriptor:

TilesetDescriptor: (3 bytes)
    - Bank number: Bank location
    - Tileset address: Address of the tileset

    1                                16
    +---------------+----------------+
    |  Bank Number  |   Tileset...
    +---------------+----------------+
       ...address   |
    +---------------+

*/

DEF TilesetDescriptor_Size = 3

TilesSets:

CastleBorderTilesetDescriptor:
    db 0                    ; bank number
    dw CastleBorderTileset  ; address

CastleBorderWeedTilesetDescriptor:
    db 0                    ; bank number
    dw CastleBorderWeedTileset




