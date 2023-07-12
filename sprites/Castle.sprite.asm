; Total : 22 tiles

CastleSprite:

CastleFaceWall_Standard: ; (1 tile)
    dw `00000000
    dw `22220222
    dw `00000000
    dw `22222220
    dw `00000000
    dw `22202222
    dw `00000000
    dw `33333333

CastleFaceWall_LeftShadow: ; (1 tile)
    dw `10000000
    dw `22220222
    dw `11000000
    dw `22222220
    dw `11100000
    dw `22202222
    dw `11110000
    dw `33333333

CastleTop: ; (3 tile)
    CastleTop_LeftUpper:
        dw `33333333
        dw `30000000
        dw `30222222
        dw `30000000
        dw `30222022
        dw `01111111
        dw `01111111
        dw `33333333
    CastleTop_RightUpper:
        dw `33333333
        dw `00000003
        dw `02222203
        dw `00000003
        dw `22202203
        dw `11111111
        dw `11111111
        dw `33333333

    CastleTop_Lower:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `00000000
        dw `33333333
        dw `01000010
        dw `00100001
        dw `33333333

CastleBottom: ; (3 tile)
    CastleBottom_UpperLeft:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `33333333
        dw `30000000
        dw `30222222
        dw `30000000
        dw `30222022

    CastleBottom_UpperRight:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `33333333
        dw `00000003
        dw `02222203
        dw `00000003
        dw `22202203

    CastleBottom_Lower:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `00000000
        dw `33333333
        dw `10000000
        dw `10000000
        dw `33333333

CastleSideLeft: ; (3 tile)
    CastleSideLeft_UpperTop:
        dw `03331003
        dw `03030103
        dw `03030013
        dw `03030003
        dw `03030003
        dw `03030003
        dw `03031003
        dw `03030103

    CastleSideLeft_UpperBottom:
        dw `03030013
        dw `03030003
        dw `03030003
        dw `03030003
        dw `03031003
        dw `03030103
        dw `03330013
        dw `03220003

    CastleSideLeft_Lower:
        dw `03100003
        dw `03010003
        dw `03001003
        dw `03000103
        dw `03000013
        dw `03000003
        dw `03100003
        dw `03010003


CastleSideRight: ; (3 tile)
    CastleSideRight_UpperTop:
        dw `31003330
        dw `30103030
        dw `30013030
        dw `30003030
        dw `30003030
        dw `30003030
        dw `31003030
        dw `30103030

    CastleSideRight_UpperBottom:
        dw `30013030
        dw `30003030
        dw `30003030
        dw `30003030
        dw `31003030
        dw `30103030
        dw `30013330
        dw `30002220

    CastleSideRight_Lower:
        dw `30000130
        dw `30000030
        dw `31000030
        dw `30100030
        dw `30010030
        dw `30001030
        dw `30000130
        dw `30000030

CastleAngle: ; (6 tile)
    CastleAngle_topLeft:
        dw `00000000
        dw `00000000
        dw `03330000
        dw `03030000
        dw `03033333
        dw `03030000
        dw `03031000
        dw `03030103

    CastleAngle_topRight:
        dw `00000000
        dw `00000000
        dw `00003330
        dw `00003030
        dw `33333030
        dw `10003030
        dw `01003030
        dw `30103030

    CastleAngle_BottomLeft_Upper:
        dw `03330003
        dw `03030003
        dw `03030003
        dw `03031003
        dw `03030103
        dw `03030010
        dw `03030001
        dw `03033333

    CastleAngle_BottomLeft_Lower:
        dw `03000000
        dw `03220222
        dw `03000000
        dw `03222220
        dw `03000000
        dw `03202222
        dw `03000000
        dw `03333333

    CastleAngle_BottomRight_Upper:
        dw `30003330
        dw `30003030
        dw `31003030
        dw `30103030
        dw `30013030
        dw `10003030
        dw `10003030
        dw `33333030
    
    CastleAngle_BottomRight_Lower:
        dw `00000030
        dw `22220230
        dw `00000030
        dw `22222230
        dw `00000030
        dw `22202230
        dw `00000030
        dw `33333330

CastleDoorUpper: ; (2 tile) Lower is the angle_bottom_lower inverted, right (ec left) angle make left (ec right) door entry 
    CastleDoorUpper_left:
        dw `00000000
        dw `00003330
        dw `00003030
        dw `03333030
        dw `31003030
        dw `10103030
        dw `10013030
        dw `33333030

    CastleDoorUpper_Right:
        dw `00000000
        dw `03330000
        dw `03030000
        dw `03033330
        dw `03030103
        dw `03030010
        dw `03030001
        dw `03033333

; End
EndCastleSprite: