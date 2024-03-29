INCLUDE "hardware.inc"

;================================================= Definition ==================================================

; Perso Size in Vram
; Total Size
DEF persoVramSize = 384
; Size of a perso direction in Vram
DEF persoDirectionVramSize = 128 
; Size perso in Tile in Vram
DEF persoIndexVramSize = 24
; Size of a perso direction in Tile in Vram
DEF persoIndexDirectionVramSize = 8
; ================================================ Interrupt =================================================

section "Vblank", ROM0[$40]
call Vblank
reti

SECTION "Header", ROM0[$100]
    nop
	jp startSection

	ds $150 - @, 0 

section "Memory", wram0 ; ======================== RAM =========================================================

/*Personage object State Memory -> POSM (7 bytes):

- Position (2 bytes): Screen position of the top left pixel
    - XPosition (1 byte): Screen position X
    - YPosition (1 byte): Screen position Y

- Direction (1 bytes): Direction of the personnage, value posible:
    0 -> Face,
    1 -> Right,
    2 -> Back,
    3 -> Left, (special State, same Right sprite)

- WalkState (1 bytes): Status of walk
    0 -> Static,
    1 -> Mov1,
    2 -> Mov2,
    3 -> Static2 (Special static indicate next mov is 2)

- Vram index (1 bytes): index of personage tiles in vram (1st perso: 0, 2nd: 1, 3th: 2...)

- OAM Index: Position in the OAM of the start of personage, if is not showed set $FF

- OAM Attribute Pointer (2 bytes): Pointer of the OAM attribut list

    0               8                  16
    +---------------+------------------+
    |  X position   |   Y position     |
    +---------------+------------------+
    |  Direction    |   WalkState      |
    +---------------+------------------+
    |  Vram index   |   OAM Index      |
    +---------------+------------------+
    |       Attribute Pointer          |
    +---------------+------------------+


*/
DEF POMS_Size = 8
DEF MAX_POSM_IN_OAM = 10

; POSM array to draw (2 * 10 POSM)
; This array get by Vblank and draw every Posm found in it.
; Set pointer 0 at end of array
POSM_DrawingArray: ds 2*MAX_POSM_IN_OAM

; POSM of Mallie
POSM_Mallie: ds POMS_Size

; Mallie Walk advance
MallieCounterWalkAdvance: db
DEF MALLIE_MAX_COUNTER_ADVANCE = 16 ; 16 / pixel per advance

; Mallie counter vblank whitout move
MallieCounterVblankVoid: db
; Mallie number of VBlanc void (define mallie's speed)
DEF MALLIE_VBLANK_VOID_MAX = 1

; OAM Stack
; Number of OAM object used
NumberOAMObject: db

; Function Variable =======
_DrawPersonnageObjectOAM_RAM_POSMDirection: db

_TilesetToVram_RAM_TilesetNumberElement: db

; Update Keys
wNewKeys: db
wCurKeys: db

    
section "mainProgramm", ROM0 ; =================== Start program ===============================================
startSection:
    di  ; turn off interruption
    ; Turn off audio circuit
    xor a
    ld [rNR52], a

    call WaitVblank
    
    ; Turn off lcd
    xor a
    ld [rLCDC], a

    ; Copy mallie's sprite in VRAM
    ld de, MallieSprites
    ld hl, _VRAM8800
    ld bc, EndMallieSprites - MallieSprites
    call MemCopy

    ; init background with map
    ld de, StartCastleMap       ; map address
    xor a                       ; map bank
    ld c, a                    ; x first mapel
    ld b, a                     ; y first mapel
    ld l, a                   ; offset (no offset)
    call MapEngine_init

    ; Clear OAM
    xor a
    ld hl, _OAMRAM
    ld b, 160
StartClearOAM:
    ld [hl], a
    inc l
    dec b
    jp nz, StartClearOAM

    ;Initialise Mallie POSM
    ld hl, POSM_Mallie
    ld a, $50
    ld [hli], a     ; X-Position
    ld [hli], a     ; Y-Position
    xor a
    ld [hli], a     ; Initial Direction (Face)
    ld [hli], a     ; Initial WalkState (Static)
    ld [hli], a     ; Vram index (Mallie always 0)
    ld [hli], a     ; OAM index (Mallie always 0)

    ld de, MallieOAMAttribute
    ld a, d
    ld [hli], a     ; 1st byte attribute pointer
    ld [hl], e      ; 2nd byte attribute pointer

    xor a
    ld [MallieCounterWalkAdvance], a ; Reset walk counter to 0
    ld [MallieCounterVblankVoid], a   ; Reset Vblank void mallie

    ld hl, POSM_DrawingArray    ; Get POSM array
    ld de, POSM_Mallie

    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a     ; [hl] -> POSM_DrawingArray[0] = *POSM_Mallie

    xor a
    ld [hli], a
    ld [hli], a     ; [hl] -> POSM_DrawingArray[0] = NULL


    ld hl, POSM_Mallie
    call DrawPersonnageObjectOAM
    
    ld a, 4
    ld [NumberOAMObject], a


    ; Color Palette
    ld a, %11100100
    ld [rBGP], a     ; BackGround palette

    ld a, %11100100
    ld [rOBP0], a    ; OBJ0 palette

    ld a, %11100000
    ld [rOBP1], a    ; OBJ1 palette


    ld a, LCDCF_ON| LCDCF_BG8000 | LCDCF_OBJON | LCDCF_BGON ; %10010011
    ld [rLCDC], a

    xor a
    ld  [rIF], a    ; reset interupt flag

    ld a, IEF_VBLANK
	ld [rIE], a     ; Set Vblank call
	
	ei


mainLoop: ;================================= Main loop ===========================
    ; Mallie walk
    ld a, [MallieCounterVblankVoid]
    cp 0
    jp nz, _MainLoop_no_update_sprite

    ld a, [MallieCounterWalkAdvance]
    cp 0
    call z, UpdateKeys

    ld a, [wCurKeys]
    ld hl, POSM_Mallie

    ld d, a     ; d = a (wCurKeys)

    inc hl  ; [hl] -> POSM_Mallie y
    inc hl  ; [hl] -> POSM Direction

_MainLoop_CheckLeft:
    and PADF_LEFT
    jp z, _MainLoop_CheckRight

_MainLoop_Left:
    ; Decrement screen x 
    ld a,[rSCX]
    dec a
    ld [rSCX], a
    ;Mallie POSM is fix just screen move

    ld [hl], 3  ; POSM left direction
    jp _MainLoop_DefWalkstate

_MainLoop_CheckRight:
    ld a, d
    and PADF_RIGHT
    jp z, _MainLoop_CheckUp

_MainLoop_Right:
    ; Increment screen x
    ld a,[rSCX]
    inc a
    ld [rSCX], a
    ;Mallie POSM is fix just screen move

    ld [hl], 1  ; POSM right direction
    jp _MainLoop_DefWalkstate

_MainLoop_CheckUp:
    ld a, d
    and PADF_UP
    jp z, _MainLoop_CheckDown

_MainLoop_Up:
    ; Decrement screen y
    ld a,[rSCY]
    dec a
    ld [rSCY], a
    ;Mallie POSM is fix just screen move

    ld [hl], 2  ; POSM back direction
    jp _MainLoop_DefWalkstate

_MainLoop_CheckDown:
    ld a, d
    and PADF_DOWN
    jp z, _MainLoop_no_mallie_movement_input

_MainLoop_Down:
    ; Increment screen y
    ld a,[rSCY]
    inc a
    ld [rSCY], a
    ;Mallie POSM is fix just screen move

    ld [hl], 0  ; POSM face direction

_MainLoop_DefWalkstate:

    ; Begin Definition of Walkstate
    inc hl      ; [hl] -> POSM Walkstate

    ; if (mallieCounterWalkAdvance (CWA) == 0)
    ld a, [MallieCounterWalkAdvance]
    ld c, a     ; keep counter in c
    cp 0
    jp nz, _MainLoop_DefWalkstate_CheckCWA_4
    
        ; if (Walkstate != 2)
        ld a, [hl]
        cp 2
        jp z, _MainLoop_DefWalkstate_CWA_0_WalkstateElse
            ld [hl], 3      ; if walkstate is not already on M2 (Movement 2) walkstate and button keep pressed after new read: put this special static walkstate indicate the next walkstate is M2
            jp _MainLoop_DefWalkstate_Finally   ; finally goto inc CWA

        _MainLoop_DefWalkstate_CWA_0_WalkstateElse:
            ld [hl], 0     ; else walk already on M2 walkstate put in static walkstate, indicate the next walkstate is M1
            jp _MainLoop_DefWalkstate_Finally   ; finally goto inc CWA


_MainLoop_DefWalkstate_CheckCWA_4:
    ; else if (CWA == 8)
    cp 8
    jp nz, _MainLoop_DefWalkstate_Finally
        ; if (walkstate == 3)
        ld a, [hl]
        cp 3
        jp nz, _MainLoop_DefWalkstate_CWA_4_WalkstateElse
            ld [hl], 2      ; if Walkstate is in special static put M2 
            jp _MainLoop_DefWalkstate_Finally

        _MainLoop_DefWalkstate_CWA_4_WalkstateElse:
            ld [hl], 1      ; else put M1

_MainLoop_DefWalkstate_Finally:
    inc c
    ld a, c
    cp MALLIE_MAX_COUNTER_ADVANCE
    jp nz, _MainLoop_NoReset_MallieCounterAdvance
        xor a
_MainLoop_NoReset_MallieCounterAdvance:
    ld [MallieCounterWalkAdvance], a    ; inc Mallie counter

_MainLoop_no_update_sprite:             ; inc Vblank void in each case (sauf no input)
    ld a, [MallieCounterVblankVoid]
    inc a
    cp MALLIE_VBLANK_VOID_MAX
    jp nz, _MainLoop_NoReset_MallieVblankVoid
        xor a
_MainLoop_NoReset_MallieVblankVoid:
    ld [MallieCounterVblankVoid], a
    jp _MainLoop_end_mallie_movement    

_MainLoop_no_mallie_movement_input:
    ; here [hl] -> POSM direction
    inc hl  ; [hl] -> POSM walkstate
    ld [hl], 0      ; no walking reset static

_MainLoop_end_mallie_movement:
    

    halt
    jp mainLoop


Vblank:  ;======================================== Vblank interupt ===========================================
    ; store each register
    push af
    push bc
    push de
    push hl

    ld hl, POSM_DrawingArray

    ld a, [hli]
    ld e, a         ; LSB 1er POSM
    ld a, [hli]
    ld d, a         ; MSB 2nd POSM

    ; POSM_DrawingArray[0] = NULL no POSM to show
    or e
    jp z, _Vblank_POSMDRAW_end

    ld c, 0
    

_Vblank_POSMDRAW:
    push bc     ; keep counter protect
    push hl     ; Store POSM array
    ld h, d
    ld l, e    ; HL = DE (POSM address)

    call DrawPersonnageObjectOAM
    
    pop hl      ; restore POSM array
    pop bc      ; restore counter

    ld a, [hli]
    ld e, a         ; LSB POSM
    ld a, [hli]
    ld d, a         ; MSB POSM

    ; POSM_DrawingArray[n] = NULL -> no more POSM to draw
    or e
    jp z, _Vblank_POSMDRAW_end

    ; check don't up to MAX POSM capable OAM
    ld a, c
    cp MAX_POSM_IN_OAM
    jp nz, _Vblank_POSMDRAW

_Vblank_POSMDRAW_end:

    ; restore register
    pop hl
    pop de
    pop bc
    pop af
    ret


section "function", rom0 ;======================== Function ====================================================
; Wait the vblank when Vblank Interrupt disabled
; (Line Y > 144)
WaitVblank:
    ld a, [rLY]
    cp SCRN_Y
    jp c, WaitVblank
    ret 

; Copy memory block (1 byte block)
; @param [hl] pointer to target memory
; @param [de] pointer to source memory
; @param [bc] memory size
MemCopy:
    ld  a, [de]
    ld  [hli], a
    inc de
    dec bc
    ld  a, b
    or  c
    jp  nz, MemCopy
    ret 

; Clone one bytes on a plage of memory
; @param: [hl] pointer to target memory
; @param: d source byte
; @param: bc memory clone size
MemClone:
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jp nz, MemClone
    ret


; Make Sprite OAM following Personnage Object
; @param: [hl] pointer of POSM
DrawPersonnageObjectOAM:
    push hl     ; Store POSM pointer
    inc hl
    inc hl      ; [hl] -> direction
    ld b, [hl]  ; b = direction
    inc hl
    inc hl      ; [hl] -> Vram index
    ld c, [hl]  ; c = Vram index

    ld d, 128   ; Sprite perso start
    ld a, b
    ld [_DrawPersonnageObjectOAM_RAM_POSMDirection], a ; Store position in RAM for future usage

    ; While (Vram Index > 0) { d += persoSize; c--}
    xor a
    cp c
    jp z, _DrawPersonnageObjectOAM_EndVramIndex

_DrawPersonnageObjectOAM_VramIndex:
    ld a, d
    add persoIndexVramSize
    ld d, a
    dec c
    jp nz, _DrawPersonnageObjectOAM_VramIndex

_DrawPersonnageObjectOAM_EndVramIndex:

    ; While (Direction > 0) { d += persoDirectionSize; b--}
    xor a
    cp b
    jp z, _DrawPersonnageObjectOAM_EndVramDirection
    ; if (c > 2) { c = 1 }
    ld a, 2
    cp b
    jp nc, _DrawPersonnageObjectOAM_VramDirection
    ; Right
    ld b, 1
    inc d       ; increment 1 cause we start on the second tile of head (reverse oblige)

_DrawPersonnageObjectOAM_VramDirection:
    ld a, d
    add persoIndexDirectionVramSize
    ld d, a
    dec b
    jp nz, _DrawPersonnageObjectOAM_VramDirection
    
_DrawPersonnageObjectOAM_EndVramDirection:

    inc hl      ; [hl] -> OAM index
    ld e, [hl]  ; e = OAM index

    ld a, e
    inc e       ; check OAM Ram != FF
    jp c, _DrawPersonnageObjectOAM_newOAMPosition

    call FindOAMObject
    jp _DrawPersonnageObjectOAM_EndNewOAMPosition


_DrawPersonnageObjectOAM_newOAMPosition: ; After some reflection maybe not do that here Main must manage entity (can use $FF in OAM index to doesn't show Sprite?)
    ld a, [NumberOAMObject]
    call FindOAMObject      ; new OAM position
    ld e, a                 ; e = new OAM position

    ld a, h ; Verif Error
    or l
    jp z, _DrawPersonnageObjectOAM_end ; Error ocured in precedent function

    ld a, e
    add 4
    ld [NumberOAMObject], a ;Increment number object
_DrawPersonnageObjectOAM_EndNewOAMPosition:

    pop bc      ; get POSM pointer
    push bc     ; store him
    push hl     ; Store OAM RAM
    ld h, b
    ld l, c     ; hl = bc (POSM)

    ld a, [hli] 
    ld b, a     ; b = Xposition
    ld a, [hli]
    ld c, a     ; c = Yposition
    inc hl      ; [hl] -> Walkstate
    ld e, [hl]  ; e = WalkState

    pop hl      ; restore OAM ram

    ; Start initialise OAM
    ; first Tile
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld [hl], d
    inc l
    inc l

    ; if (position == 3 ) { d-- } else { d++ }
    ld a, [_DrawPersonnageObjectOAM_RAM_POSMDirection]
    cp 3
    jp z, _DrawPersonnageObjectOAM_DecD1
    inc d
    jp _DrawPersonnageObjectOAM_DecD1_End
_DrawPersonnageObjectOAM_DecD1: 
    dec d
_DrawPersonnageObjectOAM_DecD1_End:
    
    ld a, b
    add 8       ; X decalage 2nd tile
    ld b, a     

    ; 2nd tile 
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld [hl], d
    inc l
    inc l

    ; check is up 3
    ld a, e
    cp 3
    jp nz, _DrawPersonnageObjectOAM_AddWalkstate
    ld e, 0

_DrawPersonnageObjectOAM_AddWalkstate:

    ld a, d
    inc a       ; 1st Static Tile
    add e
    add e       ; Add 2 Walkstate
    ld d, a

    ; if (position == 3 ) { d++ }
    ld a, [_DrawPersonnageObjectOAM_RAM_POSMDirection]
    cp 3
    jp nz, _DrawPersonnageObjectOAM_IncD_End
    inc d
    inc d       ; Inc two time to compense previous dec and go to last tile
_DrawPersonnageObjectOAM_IncD_End:

    ld a, b
    sub 8       ; X decalage 3rd tile
    ld b, a
    ld a, c
    add 8       ; Y decalage 3rd and 4th tile
    ld c, a

    ; 3rd tile 
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld [hl], d
    inc l
    inc l
    
    ; if (position == 3 ) { d-- } else { d++ }
    ld a, [_DrawPersonnageObjectOAM_RAM_POSMDirection]
    cp 3
    jp z, _DrawPersonnageObjectOAM_DecD2
    inc d
    jp _DrawPersonnageObjectOAM_DecD2_End
_DrawPersonnageObjectOAM_DecD2: 
    dec d
_DrawPersonnageObjectOAM_DecD2_End:
    
    ld a, b
    add 8       ; X decalage 4th tile
    ld b, a     

    ; 4th tile 
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld [hl], d
    inc l   ; Stop hl in attribute of 4th Object (use after)

    pop de  ; X position
    inc de  ; Y position
    inc de  ; Direction
    inc de  ; WalkState
    inc de  ; Vram Index
    inc de  ; OAM Index
    inc de  ; [de] -> Attribute Pointer
    push hl ; Store OAM state
    ld h, d
    ld l, e     ; de = hl (Attribute Pointer)
    ld a, [hli]
    ld d, a
    ld e, [hl]  ; [de]-> Attribute Memory
    ld h, d
    ld l, e     ; hl = de (Attribute Memory)

    ld a, [_DrawPersonnageObjectOAM_RAM_POSMDirection]
    ld c, a
    xor a
    ld b, a     ; bc = RAM_POSMDirection en 16 bits
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc  ; [hl] -> OAM Attribute good direction

    ld  d, h
    ld  e, l    ; de = hl
    
    ; Start copy OAM Attribute, from actual position (4th Tile) to top (1th tile)
    inc de
    inc de
    inc de  ; Last Attribute 
    
    pop hl  ; Get OAM state
    ld a, 4
    ld c, a ; c = 3, n for loop
    ld b, a ; b = 4, to sub hl
_DrawPersonnageObjectOAM_AttributeLoop:
    ld a, [de]
    ld [hl], a      ; Copy Attribute

    ld a, l
    sub b   
    ld l, a ; hl = hl - 4,  precedent sprite attribute

    dec de

    dec c
    jp nz, _DrawPersonnageObjectOAM_AttributeLoop

_DrawPersonnageObjectOAM_end: ; End 
    ret

; Find OAM object pointer whit OAM index
; @param: a OAM index
; @return: hl OAM index
; @returnError: hl = $0000
FindOAMObject:
    ld hl, _OAMRAM
    ld c, a

    cp 39
    jp nc, _FindOAMObject_ReturnError ; Invalid Index
    cp 0
    jp z, _FindOAMObject_endfind
_FindOAMObject_find:
    ld a, l
    add 4
    ld l, a
    dec c
    jp nz, _FindOAMObject_find

_FindOAMObject_endfind:
    ret
_FindOAMObject_ReturnError:
    xor a
    ld l, a
    ld h, a
    ret

; Set tileset in vram with tileset number
; @params: [hl] -> tileset address
TilesetToVram:
    
    ld a, [hli] ; Number element of tileset
    ld [_TilesetToVram_RAM_TilesetNumberElement], a

    cp 0
    jp z, _TilesetToVram_LoopTileset_end

    push hl
    ld hl, _VRAM8000
    push hl
    add sp, +2  ; [sp] ->-> Tileset
    
    pop hl      ; [hl] -> Tileset,


_TilesetToVram_LoopTileset:

    ld a, [hli] ; Bank number


    ld e, [hl]  ; LSB tiles Start Address
    inc hl
    ld d, [hl]  ; MSB tiles Start Address (DE = tile Start Address)
    inc hl

    ld c, [hl]  ; LSB Memory tiles Size (Bytes)
    inc hl
    ld b, [hl]  ; MSB Memory tiles Size
    inc hl

    ; TODO: CHECK AND SET BANK NUMBER 

    push hl
    add sp, -2  ; [sp] ->-> Vram
    pop hl      ; [hl] -> Vram

    call MemCopy

    push hl     ; hl -> actual Vram, [sp] ->-> Vram
    add sp, +2
    pop hl

    ld a, [_TilesetToVram_RAM_TilesetNumberElement]
    dec a
    jp z, _TilesetToVram_LoopTileset_end
    ld [_TilesetToVram_RAM_TilesetNumberElement], a
    jp _TilesetToVram_LoopTileset

_TilesetToVram_LoopTileset_end:
_TilesetToVram_End:
    ret


; Fonctiun read Keys input, from gbdev tutorial
; https://gbdev.io/gb-asm-tutorial/part2/input.html
; @return: wNewKeys (RAM) New pressed Keys
; @return: wCurKeys (RAM) Current pressed key
UpdateKeys:
    ; Poll half the controller
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; B7-4 = 1; B3-0 = unpressed buttons
  
    ; Poll the other half
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; A3-0 = unpressed directions; A7-4 = 1
    xor a, b ; A = pressed buttons + directions
    ld b, a ; B = pressed buttons + directions
  
    ; And release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a
  
    ; Combine with previous wCurKeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b ; A = keys that changed state
    and a, b ; A = keys that changed to pressed
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret
  
  .onenibble
    ldh [rP1], a ; switch the key matrix
    call .knownret ; burn 10 cycles calling a known ret
    ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
    ldh a, [rP1]
    ldh a, [rP1] ; this read counts
    or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
  .knownret
    ret
  
; Engine
section "engine", rom0
    include "maps.engine.asm"

; Object
section "Mallie", rom0
    include "objects/mallie.sprite.asm"
    include "objects/mallie.attribute.asm"


; Tiles
section "weedTiles", rom0
    include "tiles/weed.tiles.asm"

section "castleTiles", rom0
    include "tiles/Castle.tiles.asm"

section "unicolorTile", rom0
    include "tiles/unicolor.tiles.asm"

section "borderTiles", rom0
    include "tiles/Border.tiles.asm"


; Tilesets
section "tileset.CastleBorder", rom0
    include "tilesets/CastleBorder.tileset.asm"

section "tilset.CastleBorderWeed", rom0
    include "tilesets/CastleBorderWeed.tileset.asm"


; Mapels
section "mapels.StartCastle", rom0
    include "mapels/castleBorder.mapels.asm"

; Maps
section "maps.StartCastle", rom0
    include "maps/StartCastle/startCastle.maps.asm"