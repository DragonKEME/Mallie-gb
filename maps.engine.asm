include "hardware.inc"
; Maps relative function

/*
External access: 
;Ram: 
    - MallieCounterWalkAdvance: Static (1 byte)

;Function:
    - TilesetToVram

;Hardware:
    - Screen position: rSCY (FF42) and rSCX (FF43)
    - Background 0: _SCRN0 (memory 9800-9BFF)
*/

; screen lengh in mapel
DEF SCRN_SX_MAPEL = 10

; screen width y in mapel
DEF SCRN_SY_MAPEL = 9       

section "RamMaps", wram0
/*
Maps storage:
    - First Mapel show address: pointer on the first showed tileset (top left) in the Map array
        Each next mapel can be found with manipulation of this pointer

    - Offset Map: Offset on screen for the First show mapel. -> bit 7-4: y offset, bit 3-0: x offset
        /!\ everything before offset is draw with padding mapel

    - Padding Line: bollean (0 -> False, everything else -> true) 
        indicate the current line must be draw with padding mapel

    +-------------------+--------------------+
    |     Map Bank      |        Map...      
    +-------------------+--------------------+
       ...Address       |       Size X       | \
    +-------------------+--------------------+ |
    |     Size Y        |    Mapel Bank      | |
    +-------------------+--------------------+ | -> Map header
    |              Mapel Address             | |
    +-------------------+--------------------+ |
    |   Padding Mapel   |    offset map      | /
    +-------------------+--------------------+ \
    |        First Mapel show address        | |
    +-------------------+--------------------+ | -> position on map
    |     Current x     |     Current y      | /
    +-------------------+--------------------+  
    |   Padding Line    |  Mapel Array Size  |
    +-------------------+--------------------+
    |                Virtual                 | \
    +                                        + |
    :                 Flags                  : | -> size = SCRN_SX_MAPEL * SCRN_SY_MAPEL
    +                                        + |
    |                  Map                   | /
    +----------------------------------------+
    | Counter offset X  |  Counter offset Y  |
    +-------------------+--------------------+

*/
MapEngine_Ram_MapInfo:
    ; Map info
    MapEngine_Ram_Map_Bank: db
    MapEngine_Ram_Map_Address: dw
    
    ; Map header
    MapEngine_Ram_Map_SizeX: db
    MapEngine_Ram_Map_SizeY: db
    MapEngine_Ram_Mapel_Bank: db
    MapEngine_Ram_Mapel_Address: dw
    MapEngine_Ram_Padding_Mapel: db

    ; Location on map
    MapEngine_Ram_MapOffset: db
    MapEngine_Ram_FirstShowMapel_Address: dw
    MapEngine_Ram_Current_x: db
    MapEngine_Ram_Current_y: db
    MapEngine_Ram_Padding_Line: db


    ;Mapel header
    MapEngine_ram_Mapel_ArraySize: db

    ; Virtual flags map
    MapEngine_Ram_VirtualMapIndex: db
    MapEngine_Ram_VirtualFlagsMap: ds SCRN_SX_MAPEL*SCRN_SY_MAPEL

MapEngine_Function_variable:
    ; LoadScreenMap
    ; Counter Offset(X/Y): using to count n to 0 the X decalage during drawing Map
    MapEngine_Ram_CounterOffsetX: db
    MapEngine_Ram_CounterOffsetY: db


section "MapsEngine", rom0
/*
;Init: Save *map and *mapel in ram, load associated tileset, and load map in background
Must called in vblank or screen off
/!\ init position non verified
@params: [de] -> maps pointer
@params: a -> maps bank
@params: c -> init x position (top left mapel on screen)
@params: b -> init y position (top left mapel on screen)
@params: l -> offsets (bit 7-4: y offset, bit 3-0: x offset)
*/
MapEngine_init:
    push bc         ; Store init position (sp - 2)
    push hl         ; Store offset (sp - 4)

    ld hl, MapEngine_Ram_MapInfo
    ld [hli], a     ; MapEngine_Map_Bank = Map bank (param a)
    ld a, e
    ld [hli], a   
    ld a, d
    ld [hli], a     ; MapEngine_Map_Address = Map Address (param de)

    ; load map bank

    pop bc          ; Restore offset    (sp - 2)
    push hl         ; Store MapInfo     (sp - 4)
    ld hl, MapEngine_Ram_MapOffset
    ld [hl], c      ; keep offset in ram
    pop hl          ; Restore MapInfo   (sp - 2)
    

    ld a, 6     ; map header Size
    ld c, a
    xor a
    ld b, a      ; bc = header size
    call MemCopy ; Copy map header

    pop bc      ; restore init position (sp - 0)

    ld hl, MapEngine_Ram_Current_x
    ld a, c
    ld [hli], a
    ld [hl], b      ; [hl] -> MapEngine_Ram_Current_y = b

    ld h, d
    ld l, e     ; hl = de -> maps Array

    ld a, [MapEngine_Ram_Map_SizeX]
    ld e, a
    xor a
    ld d, a ; de = [MapEngine_Ram_Map_SizeX]

    ld a, b
    cp 0
    jp z, MapEngine_init_GoToPositionYLoop_end

MapEngine_init_GoToPositionYLoop:
    add hl, de
    dec b
    jp nz, MapEngine_init_GoToPositionYLoop

MapEngine_init_GoToPositionYLoop_end:
    ;b = 0 at this point

    add hl, bc  ; b = 0 and c = x -> bc = x

    ld d, h
    ld e, l     ; de = hl -> First Showed Mapel

    ld hl, MapEngine_Ram_FirstShowMapel_Address
    ld a, e
    ld [hli], a
    ld [hl], d

    
    ; load mapel bank

    ld hl, MapEngine_Ram_Mapel_Address
    ld a, [hli]
    ld e, a
    ld d, [hl]      ; [de] -> Mapel

    ; load mapel bank

    ld hl, MapEngine_ram_Mapel_ArraySize
    ld a, [de]
    ld [hl], a  ; [MapEngine_ram_Mapel_ArraySize] = Mapel array size

; Load Tileset

    inc de      ; [de] -> tileset bank (mapel)
    ld a, [de]

    ; load tilset bank

    inc de      ; de -> tileset address (LSB)
    ld a, [de]  
    ld l, a
    inc de      ; de -> tileset address (MSB)
    ld a, [de]
    ld h, a     ; hl = tileset address

    call TilesetToVram
    call MapEngine_LoadScreenMap

    ret

/*
Load or reload map on screen
Must called in vblank or screen off
@param: All data must be load in Map_Info (see init)
*/
MapEngine_LoadScreenMap:

    ; load map bank

    ld hl, MapEngine_Ram_FirstShowMapel_Address
    ld a, [hli]
    ld e, a
    ld d, [hl]      ; de = MapEngine_Ram_FirstShowMapel_Address

    ; for refresh, put screen at (0,0)
    xor a
    ld [rSCX], a
    ld [rSCY], a

    ; init padding line
    ld [MapEngine_Ram_Padding_Line], a

    ; init index vmap
    ld [MapEngine_Ram_VirtualMapIndex], a

    xor a
    ld [MapEngine_Ram_CounterOffsetX], a ; reset X offset counter
    ld [MapEngine_Ram_CounterOffsetY], a ; reset Y offset counter


    ; load the offset counter
    ld a, [MapEngine_Ram_MapOffset]
    ld b, a 
    ; Y counter
    and %11110000
    jp z, MapEngine_LoadScreenMap_offsetY_end
    swap a
    ld [MapEngine_Ram_CounterOffsetY], a    ; store y offset
    ld de, MapEngine_Ram_Padding_Mapel      ; de = padding mapel
    ld [MapEngine_Ram_Padding_Line], a      ; padding line = true
    jp MapEngine_LoadScreenMap_offsetX_end  ; skip X offset
MapEngine_LoadScreenMap_offsetY_end:
         
    ; X counter
    ld a, b                                 ; a = MapEngine_Ram_MapOffset
    and %00001111
    jp z, MapEngine_LoadScreenMap_offsetX_end
    push de
    ld de, MapEngine_Ram_Padding_Mapel      ; load padding mappel
    ld [MapEngine_Ram_CounterOffsetX], a    ; -> store 3-0 bits offset (x offset)
MapEngine_LoadScreenMap_offsetX_end:

    ld hl, _SCRN0
    ld a, SCRN_SX_MAPEL       ; number mapel in one line
    ld b, a         ; b = SCRN_SX_MAPEL (10) -> x counter
    dec a
    ld c, a         ; c = SCRN_SX_MAPEL - 1 = SCRN_SY_MAPEL (9) -> y counter

    push bc     ; save counters

MapEngine_LoadScreenMap_Loop:
    ; Draw mapel loop (bc must be push before)
    
    ld a, [de]
    ld c, a

    push de     ; Store map mapel index pointer
    push hl     ; Store tile position

    call MapEngine_DrawMapel

    ld hl, MapEngine_Ram_VirtualMapIndex
    inc [hl]    ; next index

    pop hl      ; Restore tile position
    pop de      ; restore map mapel index pointer
    
    pop bc      ; retore counter

    ; x--
    dec b
    jp z, MapEngine_LoadScreenMap_Loop_decY ; if x = 0 dec y

    push bc     ; resave it

    ; if paddind line == 1 (true) do nothing
    ld a, [MapEngine_Ram_Padding_Line]
    cp 0
    jp nz, MapEngine_LoadScreenMap_Loop_exceedMapX_end   ; if padding line == true skip test

    ; if x offset > 0 -> padding
    ld a, [MapEngine_Ram_CounterOffsetX]
    cp 0
    jp z, MapEngine_LoadScreenMap_Loop_exceedMapX_if
    dec a                                               ; counterX --
    ld [MapEngine_Ram_CounterOffsetX], a                ; store
    cp 0
    jp nz, MapEngine_LoadScreenMap_Loop_exceedMapX      ; counter > 0 -> padding
    pop bc
    pop de                                              ; restore de after padding
    push bc
    jp MapEngine_LoadScreenMap_Loop_exceedMapX_end
    
    
MapEngine_LoadScreenMap_Loop_exceedMapX_if:
    ; if (current + b < Max X -1)
    ld a, [MapEngine_Ram_Current_x]
    add a, SCRN_SX_MAPEL
    sub a, b
    ld b, a
    ld a, [MapEngine_Ram_Map_SizeX]
    dec a
    cp b
    jp nc, MapEngine_LoadScreenMap_Loop_exceedMapX_else

MapEngine_LoadScreenMap_Loop_exceedMapX:
    ; if exceed mapel = padding
    ld de, MapEngine_Ram_Padding_Mapel ; [de] -> padding mapel
    jp MapEngine_LoadScreenMap_Loop_exceedMapX_end

MapEngine_LoadScreenMap_Loop_exceedMapX_else:
    ; else inc de
    inc de

MapEngine_LoadScreenMap_Loop_exceedMapX_end:
    inc hl
    inc hl      ; next tile
    jp MapEngine_LoadScreenMap_Loop

MapEngine_LoadScreenMap_Loop_decY:

    dec c           ; y--
    jp z,  MapEngine_LoadScreenMap_Loop_end  ; x = 0, y = 0 it's end

    ld a, SCRN_SX_MAPEL        
    ld b, a         ; b = 10 -> x counter

    push bc

    ld a, [MapEngine_Ram_CounterOffsetY]
    cp 0
    jp z, MapEngine_LoadScreenMap_Loop_exceedMapY_if
    dec a                                               ; counterY --
    ld [MapEngine_Ram_CounterOffsetY], a                ; store
    cp 0
    jp nz, MapEngine_LoadScreenMap_Loop_exceedMapY      ; counter > 0 -> padding

MapEngine_LoadScreenMap_Loop_exceedMapY_if:  
    ; if (currentY + c < Max Y - 1)
    ld a, [MapEngine_Ram_Current_y]
    add a, SCRN_SY_MAPEL
    sub a, c
    ld c, a
    ld a, [MapEngine_Ram_Map_SizeY]
    dec a
    cp c
    jp nc, MapEngine_LoadScreenMap_Loop_exceedMapY_else

MapEngine_LoadScreenMap_Loop_exceedMapY:  
    ; if exceed mapel = padding line
    ld de, MapEngine_Ram_Padding_Mapel
    inc a                               ; a > 0
    ld [MapEngine_Ram_Padding_Line], a  ; padding line = true
    jp MapEngine_LoadScreenMap_Loop_exceedMapY_end

MapEngine_LoadScreenMap_Loop_exceedMapY_else:
    ;else go to next line and padding = false
    pop bc
    push bc     ; get counter

    push hl     ; store vram position

    ; de -> MapEngine_Ram_FirstShowMapel_Address + (deltaY - offset) * sizeX 
    ld a, [MapEngine_Ram_FirstShowMapel_Address]
    ld l, a
    ld a, [MapEngine_Ram_FirstShowMapel_Address + 1] 
    ld h, a     ; hl = MapEngine_Ram_FirstShowMapel_Address

    ld d, 0
    ld a, [MapEngine_Ram_Map_SizeX]
    ld e, a                     ; de = SizeX

    ; offset
    ld a, [MapEngine_Ram_MapOffset]
    and %11110000
    swap a
    ld b, a                   ; b -> offset
    ld a, SCRN_SY_MAPEL       ; a -> loop counter
    sub a, b                  ; a -> loop counter - offset
    cp c
    jp z, MapEngine_LoadScreenMap_Loop_exceedMapY_else_mulLoop_end

    MapEngine_LoadScreenMap_Loop_exceedMapY_else_mulLoop:
        add hl, de
        dec a
        cp c
        jp nz, MapEngine_LoadScreenMap_Loop_exceedMapY_else_mulLoop
MapEngine_LoadScreenMap_Loop_exceedMapY_else_mulLoop_end:

    ld d, h
    ld e, l     ; de = hl

    pop hl              ; restore vram position

    ; padding == false
    xor a
    ld [MapEngine_Ram_Padding_Line], a  ; padding line = false

    ; load the offset counter
    ld a, [MapEngine_Ram_MapOffset]
    ld b, a 
    ; X counter
    and %00001111
    jp z, MapEngine_LoadScreenMap_Loop_exceedMapY_else_offsetX_end
    pop bc
    push de
    push bc
    ld de, MapEngine_Ram_Padding_Mapel      ; load padding mappel
    ld [MapEngine_Ram_CounterOffsetX], a    ; -> store 3-0 bits offset (x offset)
MapEngine_LoadScreenMap_Loop_exceedMapY_else_offsetX_end:


MapEngine_LoadScreenMap_Loop_exceedMapY_end:
    ; hl -> next background line
    ld bc, SCRN_VX_B    ; bc = backgroudX
    add hl, bc
    add hl, bc          ; hl = hl + 2*BackgroundX + SCRN_X_B - 2
    
    ; hl = hl - SCRN_X_B + 2
    ld a, l
    sub SCRN_X_B - 2
    jp nc, MapEngine_LoadScreenMap_Loop_exceedMapY_end_noCarry
    dec h
MapEngine_LoadScreenMap_Loop_exceedMapY_end_noCarry:
    ld l, a     ; hl = hl + 2*BackgroundX

    ld a, h
    cp $9b           ; check if hl not exceed screen 0
    jp c, MapEngine_LoadScreenMap_Loop
    ld h, $98        ; With 32 add we cannot write more that 8bit, and just continue at the start of screen
    jp MapEngine_LoadScreenMap_Loop
    

MapEngine_LoadScreenMap_Loop_end:
    ret


/*
 Draw one mapel 
 @param: c mapel index
 @param: [hl] -> first background tile
 @param: [MapEngine_Ram_VirtualMapIndex] -> Vmap index
*/
MapEngine_DrawMapel:
    push hl         ; store first background tile

    ;Load Mapel Address
    ld hl, MapEngine_Ram_Mapel_Address
    ld a, [hli]
    ld e, a
    ld d, [hl]      ; [de] -> Mapel address
    ld h, d
    ld l, e         ; hl = de -> Mapel Address

    ; find mapel with index (potentielle fonction)
    inc hl          ; [hl] -> tilset bank
    inc hl          ; [hl] -> tilset LSB
    inc hl          ; [hl] -> tilset MSB
    inc hl          ; [hl] -> Mapel[0]

    xor a
    ld b, a         ; bc = mapel index

    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc      ; mapel index * mapel size (5)
    ; end find mapel with index

    ld d, h
    ld e, l         ; de = hl -> Mapel[c]

    pop hl          ; restore first background tile

    ; copy first tile
    ld a, [de]
    ld [hli], a
    inc de
    ; copy 2nd tile
    ld a, [de]
    ld [hld], a
    inc de

    ld a, SCRN_VX_B  ; Size x background in bytes
    ld c, a          ; bc = SCRN_VX_B

    add hl, bc       ; [hl] -> next line

    ld a, h
    cp $9b           ; check if hl not exceed screen 0
    jp c, MapEngine_DrawMapel_notexceed

    ld h, $98        ; With 32 add we cannot write more that 8bit, and just continue at the start of screen

MapEngine_DrawMapel_notexceed:

    ; copy 3rd tile
    ld a, [de]
    ld [hli], a
    inc de
    ; copy 4th tile
    ld a, [de]
    ld [hl], a
    inc de

    ; load vmap flag
    ld hl, MapEngine_Ram_VirtualFlagsMap
    ld a, [MapEngine_Ram_VirtualMapIndex]
    ld c, a
    xor a
    ld b, a     ; bc = [MapEngine_Ram_VirtualMapIndex]
    add hl, bc  ; hl = hl + vmap index
    ld a, [de]  
    ld [hl], a  ; VirtualFlagsMap[n] = flag

    
    ret

