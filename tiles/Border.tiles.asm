; Total : 8 tiles

BorderTiles:

BorderTop: ; (1 tile)
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `03300330
    dw `32233233
    dw `10101010
    dw `01010101

BorderBottom: ; (1 tile)
    dw `10101010
    dw `01010101
    dw `33333333
    dw `11211212
    dw `22113131
    dw `32332323
    dw `33303330
    dw `00000000

BorderLeft: ; (1 tile)
    dw `03213010
    dw `03123100
    dw `03313010
    dw `00313100
    dw `03223010
    dw `03213100
    dw `03123010
    dw `00313100

BorderRight: ; (1 tile)
    dw `00131230
    dw `01032130
    dw `00131330
    dw `01031300
    dw `00132230
    dw `01031230
    dw `00132130
    dw `01031300

BorderAngle: ; (4 tile)
    BorderAngle_topLeft:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `00000000
        dw `00033330
        dw `00322323
        dw `00313010
        dw `03223101
    
    BorderAngle_topRight:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `00000000
        dw `03333000
        dw `32322300
        dw `10131300
        dw `01032230

    BorderAngle_bottomLeft:
        dw `03213010
        dw `03123101
        dw `03213333
        dw `03121212
        dw `03323131
        dw `00332323
        dw `00003330
        dw `00000000

    BorderAngle_bottomRight:
        dw `10131230
        dw `01032130
        dw `33331230
        dw `11212330
        dw `22122300
        dw `32333300
        dw `33300000
        dw `00000000


; End
EndBorderTiles: