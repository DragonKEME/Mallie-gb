; Array of map Element

/*
Map Element (mapel)
    Tiles no 1-4 (4 bytes): Number of the tile in Vram (see tilesetto know it)

    Flags associated of his mapel (1 byte): 0 -> not activated, 1 -> Activated
        - bit 0: Traversable
        - bit 1: Warp
        - bit (2-7): Unused

    +---------------------+---------------------+
    |     Tiles no 1      |     Tiles no 2      |
    +---------------------+---------------------+
    |     Tiles no 3      |     Tiles no 4      |
    +---------------------+---------------------+
    |       Flags         |
    +---------------------+ <- 5

    Tile disposition:
    +-------+-------+
    |       |       |
    |   1   |   2   |
    |       |       |
    +-------+-------+
    |       |       |
    |   3   |   4   |
    |       |       |
    +-------+-------+

*/

/*
MapelArrays (also named mapelset or mapels)

Header:
    Array Size (1 byte): Mapel Number 
    Tileset Bank (1 byte): Bank of the tileset 
    Tileset Address (2 byte): Address of the tilset used by this MapelArray
    Mapels (n*5 bytes): Mapel

    0                     8                     16
    +---------------------+---------------------+
    |     Array Size      |    Tileset bank     |
    +---------------------+---------------------+
    |              Tileset Address              |
    +---------------------+---------------------+
    |                                           |
    +                 Mapel[0]                  +
    |                                           |
    +                     +---------------------+
    |                     |     Mapel[1]...
    +---------------------+---------------------+ n*5 + 2 (header)

*/
castleBorderMapels:
; Header
    db  22       ; SIZE
    db  0       ; Tileset Bank
    dw  CastleBorderWeedTileset ; TilesetAddress

castleBorderMapels_Empty: ; 0
    db  1           ; tile 1
    db  0           ; tile 2
    db  0           ; tile 3
    db  1           ; tile 4
    db  %00000000   ; flag

castleBorderMapels_Border:
    castleBorderMapels_Border_TopLeft: ; 1
        db  0           ; tile 1
        db  0           ; tile 2
        db  29          ; tile 3
        db  25          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Border_TopRight: ; 2
        db  0           ; tile 1
        db  0           ; tile 2
        db  25          ; tile 3
        db  30          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Border_BottomLeft: ; 3
        db  31          ; tile 1
        db  26          ; tile 2
        db  0           ; tile 3
        db  0           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Border_BottomRight: ; 4
        db  26          ; tile 1
        db  32          ; tile 2
        db  0           ; tile 3
        db  0           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Border_Top: ; 5
        db  0           ; tile 1
        db  0           ; tile 2
        db  25          ; tile 3
        db  25          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Border_Bottom: ; 6
        db  26          ; tile 1
        db  26          ; tile 2
        db  0           ; tile 3
        db  0           ; tile 4
        db  %00000001   ; flag



castleBorderMapels_BorderCastle:
    castleBorderMapels_BorderCastle_TopLeft: ; 7
        db  27          ; tile 1
        db  17          ; tile 2
        db  27          ; tile 3
        db  12          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_BorderCastle_TopRight: ; 8
        db  18          ; tile 1
        db  28          ; tile 2
        db  15          ; tile 3
        db  28          ; tile 4
        db  %00000001   ; flag
    
    castleBorderMapels_BorderCastle_BottomLeft: ; 9
        db  27          ; tile 1
        db  19          ; tile 2
        db  27          ; tile 3
        db  20          ; tile 4
        db  %00000001   ; flag
    
    castleBorderMapels_BorderCastle_BottomRight: ; 10
        db  21          ; tile 1
        db  28          ; tile 2
        db  22          ; tile 3
        db  28          ; tile 4
        db  %00000001   ; flag
    
    castleBorderMapels_BorderCastle_Left_1: ; 11
        db  27          ; tile 1
        db  13          ; tile 2
        db  27          ; tile 3
        db  11          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_BorderCastle_Left_2: ; 12
        db  27          ; tile 1
        db  12          ; tile 2
        db  27          ; tile 3
        db  13          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_BorderCastle_Left_3: ; 13
        db  27          ; tile 1
        db  11          ; tile 2
        db  27          ; tile 3
        db  12          ; tile 4
        db  %00000001   ; flag
    castleBorderMapels_BorderCastle_Right_1: ; 14
        db  16          ; tile 1
        db  28          ; tile 2
        db  14          ; tile 3
        db  28          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_BorderCastle_Right_2: ; 15
        db  15          ; tile 1
        db  28          ; tile 2
        db  16          ; tile 3
        db  28          ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_BorderCastle_Right_3: ; 16
        db  14          ; tile 1
        db  28          ; tile 2
        db  15          ; tile 3
        db  28          ; tile 4
        db  %00000001   ; flag

castleBorderMapels_Castle:
    castleBorderMapels_Castle_Top_1: ; 17
        db  5           ; tile 1
        db  6           ; tile 2
        db  3           ; tile 3
        db  3           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Castle_Top_2: ; 18
        db  7           ; tile 1
        db  5           ; tile 2
        db  3           ; tile 3
        db  3           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Castle_Top_3: ; 19
        db  6           ; tile 1
        db  7           ; tile 2
        db  3           ; tile 3
        db  3           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Castle_Bottom_1: ; 20
        db  8           ; tile 1
        db  9           ; tile 2
        db  3           ; tile 3
        db  3           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Castle_Bottom_2: ; 21
        db  10          ; tile 1
        db  8           ; tile 2
        db  3           ; tile 3
        db  3           ; tile 4
        db  %00000001   ; flag

    castleBorderMapels_Castle_Bottom_3: ; 22
        db  9           ; tile 1
        db  10           ; tile 2
        db  3          ; tile 3
        db  3           ; tile 4
        db  %00000001   ; flag