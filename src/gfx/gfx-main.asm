
; +----------------------------------------------------------------------------+
; |                                                                            |
; |                              FINAL FANTASY V                               |
; |                                                                            |
; +----------------------------------------------------------------------------+
; | file: src/gfx/gfx-main.asm                                                 |
; |                                                                            |
; | description: graphics assets main assembly file                            |
; +----------------------------------------------------------------------------+

.include "const.inc"
.include "macros.inc"

; ------------------------------------------------------------------------------

.segment "window_gfx"

.export WindowPal, WindowGfx

; c0/d340
WindowPal:
        .incbin "window.pal"

; c0/d380
WindowGfx:
        incbin_lang "window_%s.4bpp"

; ------------------------------------------------------------------------------

.segment "map_overlay"

.export MapOverlayGfx

; c0/df00
MapOverlayGfx:
        .incbin "map_overlay.1bpp"

; ------------------------------------------------------------------------------

.segment "map_pal"

.export MapPal

; c3/bb00
MapPal:
.repeat 44, i
        .incbin .sprintf("map_pal/map_pal_%04x.pal", i)
.endrep

; ------------------------------------------------------------------------------

.segment "big_font_gfx"

.export BigFontGfx

; c3/eb00
BigFontGfx:
        incbin_lang "big_font_%s.1bpp"

; ------------------------------------------------------------------------------

.segment "timer_font_gfx"

.export TimerFontGfx

; cd/fe00
TimerFontGfx:
        .incbin "timer_font.4bpp"

; ------------------------------------------------------------------------------

.export MonsterPal

.segment "monster_pal"

; ce/d000
MonsterPal:
        .incbin "monster.pal"

; ------------------------------------------------------------------------------

.segment "minimap_gfx"

.export MinimapGfx

; cf/d800
MinimapGfx:
        .incbin "minimap.4bpp"

; ------------------------------------------------------------------------------

.export WorldTileAttr

.segment "world_tile_attr"

; cf/f9c0
WorldTileAttr:
        .incbin "world_tile_attr/bartz_world.dat"
        .incbin "world_tile_attr/galuf_world.dat"
        .incbin "world_tile_attr/underwater.dat"

; ------------------------------------------------------------------------------

.export WorldPal

.segment "world_pal"

; cf/fcc0
WorldPal:
        .incbin "world_pal/bartz_world.pal"
        .incbin "world_pal/galuf_world.pal"
        .incbin "world_pal/underwater.pal"

; ------------------------------------------------------------------------------

.export MonsterStencil

.segment "monster_stencil"

; not sure why ld65 needs "near" below. using .addr should force it to 16-bit.

; d0/d000
MonsterStencil:
        .addr   near MonsterStencilSmall
        .addr   near MonsterStencilLarge

; d0/d004
MonsterStencilSmall:
        .incbin "monster_stencil_small.dat"

; d0/d334
MonsterStencilLarge:
        .incbin "monster_stencil_large.dat"

; ------------------------------------------------------------------------------

.segment "the_end_gfx"

.export TheEndGfx

; d0/e4cb
TheEndGfx:
        .incbin "the_end.4bpp.lz"

; ------------------------------------------------------------------------------

.export AttackTiles1, AttackTiles2, AttackTiles3
.export AttackGfx1, AttackGfx2, AttackGfx3
.export AnimalsTiles, AnimalsGfx
.export WeaponTiles, WeaponGfx
.export WeaponHitTiles, WeaponHitGfx
.export AttackPal

.segment "attack_gfx1"

; d1/7fa0
AttackTiles1:
        .incbin "attack1.scr"

; d1/87a0
AttackTiles2:
        .incbin "attack2.scr"

; d1/8fa0
AttackTiles3:
        .incbin "attack3.scr"

; d1/97a0
WeaponTiles:
        .incbin "weapons.scr"

; d1/9ba0
WeaponHitTiles:
        .incbin "weapon_hit.scr"

; d1/a3a0
AttackPal:
        .repeat 128, i
        .incbin .sprintf("attack_pal/pal_%04x.pal", i)
        .endrep

; d1/aba0
AnimalsGfx:
        .incbin "animals.4bpp"

; d1/be00
AnimalsTiles:
        .incbin "animals.scr"

; d1/c000
WeaponGfx:
        .incbin "weapons.3bpp"

; d1/d800
WeaponHitGfx:
        .incbin "weapon_hit.3bpp"

; ------------------------------------------------------------------------------

.segment "small_font_gfx"

.export SmallFontGfx

; d1/f000
SmallFontGfx:
        incbin_lang "small_font_%s.2bpp"

; ------------------------------------------------------------------------------

.segment "battle_char_gfx"

.export BattleCharGfx
.export BattleCharGfx_0
.export BattleCharGfx_1
.export BattleCharGfx_2
.export BattleCharGfx_3
.export BattleCharGfx_4

; d2/0000
BattleCharGfx:
        .repeat 110, i
        .if (i .mod 22) = 0
        .ident(.sprintf("BattleCharGfx_%d", i / 22)) := *
        .endif
        .incbin .sprintf("battle_char_gfx/gfx_%04x.4bpp", i)
        .endrep

; ------------------------------------------------------------------------------

.export DeadCharGfx_0
.export DeadCharGfx_1
.export DeadCharGfx_2
.export DeadCharGfx_3
.export DeadCharGfx_4

; d4/9400
DeadCharGfx:
        .repeat 5, i
        .ident(.sprintf("DeadCharGfx_%d", i)) := *
        .incbin .sprintf("dead_char_gfx/gfx_%04x.4bpp", i)
        .endrep

; ------------------------------------------------------------------------------

.export MiscSpriteGfx1, MiscSpriteGfx2

; d4/97c0
MiscSpriteGfx1:
        incbin_lang "battle_sprites1_%s.3bpp"

; d4/9e50
MiscSpriteGfx2:
        .incbin "battle_sprites2.3bpp"

; ------------------------------------------------------------------------------

.export BattleCharPal
.export BattleCharPal_0
.export BattleCharPal_1
.export BattleCharPal_2
.export BattleCharPal_3
.export BattleCharPal_4

; d4/a3c0
BattleCharPal:
        .repeat 110, i
        .if (i .mod 22) = 0
        .ident(.sprintf("BattleCharPal_%d", i / 22)) := *
        .endif
        .incbin .sprintf("battle_char_pal/pal_%04x.pal", i)
        .endrep

; ------------------------------------------------------------------------------

.export MonsterGfxProp

; d4/b180
MonsterGfxProp:
        .byte   $00,$00,$00,$00,$00
        .byte   $80,$44,$40,$02,$01
        .byte   $80,$74,$00,$03,$02
        .byte   $80,$a4,$00,$04,$03
        .byte   $80,$d4,$40,$05,$04
        .byte   $01,$04,$00,$06,$05
        .byte   $01,$4c,$00,$08,$06
        .byte   $00,$00,$00,$0a,$00
        .byte   $81,$a8,$00,$0c,$07
        .byte   $81,$ea,$40,$0d,$08
        .byte   $02,$1a,$00,$0e,$09
        .byte   $02,$66,$00,$10,$0a
        .byte   $02,$b2,$00,$12,$0b
        .byte   $03,$3e,$00,$14,$0c
        .byte   $03,$d6,$00,$16,$0d
        .byte   $04,$26,$00,$18,$0e
        .byte   $84,$a6,$00,$1a,$0f
        .byte   $05,$1b,$00,$1b,$10
        .byte   $05,$9b,$80,$1d,$00
        .byte   $86,$97,$00,$1f,$11
        .byte   $86,$d3,$00,$20,$12
        .byte   $07,$24,$00,$21,$13
        .byte   $07,$bc,$40,$23,$14
        .byte   $88,$10,$00,$25,$15
        .byte   $08,$40,$40,$26,$16
        .byte   $08,$94,$40,$28,$17
        .byte   $88,$dc,$00,$2a,$18
        .byte   $09,$12,$00,$2b,$19
        .byte   $89,$8e,$00,$2d,$1a
        .byte   $09,$c4,$00,$2e,$1b
        .byte   $0a,$24,$c0,$30,$01
        .byte   $0a,$b4,$40,$32,$1c
        .byte   $0b,$2c,$80,$34,$02
        .byte   $01,$4c,$00,$36,$06
        .byte   $0c,$20,$c0,$38,$03
        .byte   $8c,$fc,$00,$3a,$1d
        .byte   $8d,$32,$00,$3b,$1e
        .byte   $80,$44,$40,$3c,$01
        .byte   $0d,$98,$40,$3d,$1f
        .byte   $0e,$1c,$80,$3f,$04
        .byte   $0e,$c0,$00,$41,$20
        .byte   $07,$bc,$40,$43,$14
        .byte   $0f,$18,$80,$45,$05
        .byte   $81,$ea,$40,$47,$08
        .byte   $0f,$80,$00,$48,$21
        .byte   $89,$8e,$00,$4a,$1a
        .byte   $09,$c4,$00,$4b,$1b
        .byte   $8c,$fc,$00,$4d,$1d
        .byte   $0f,$d0,$c0,$4e,$06
        .byte   $10,$a0,$00,$50,$22
        .byte   $10,$f8,$00,$52,$23
        .byte   $11,$80,$00,$54,$24
        .byte   $12,$08,$00,$56,$25
        .byte   $12,$90,$80,$58,$07
        .byte   $93,$48,$00,$5a,$26
        .byte   $13,$93,$00,$5b,$27
        .byte   $13,$fb,$00,$5d,$28
        .byte   $14,$97,$00,$5f,$29
        .byte   $94,$f7,$00,$61,$2a
        .byte   $07,$24,$00,$62,$13
        .byte   $15,$2d,$00,$64,$2b
        .byte   $15,$65,$80,$66,$08
        .byte   $16,$09,$80,$68,$09
        .byte   $97,$11,$00,$6a,$2c
        .byte   $17,$4d,$00,$6b,$2d
        .byte   $17,$bd,$00,$6d,$2e
        .byte   $18,$4d,$00,$6f,$2f
        .byte   $98,$c9,$00,$71,$30
        .byte   $88,$dc,$00,$72,$18
        .byte   $19,$29,$40,$73,$31
        .byte   $19,$b9,$00,$75,$32
        .byte   $09,$12,$00,$77,$19
        .byte   $1a,$45,$80,$79,$0a
        .byte   $1a,$45,$80,$7b,$0a
        .byte   $9b,$19,$00,$7d,$33
        .byte   $1b,$58,$00,$7e,$34
        .byte   $1b,$d4,$80,$80,$0b
        .byte   $9c,$18,$00,$82,$35
        .byte   $17,$bd,$00,$83,$2e
        .byte   $1c,$54,$00,$85,$36
        .byte   $9b,$19,$00,$87,$33
        .byte   $1c,$b0,$40,$88,$37
        .byte   $02,$b2,$00,$8a,$0b
        .byte   $01,$4c,$00,$8c,$06
        .byte   $1c,$f0,$80,$8e,$0c
        .byte   $03,$d6,$00,$90,$0d
        .byte   $1e,$10,$00,$92,$38
        .byte   $1e,$c0,$80,$94,$0d
        .byte   $1f,$bc,$00,$96,$39
        .byte   $20,$04,$00,$98,$3a
        .byte   $03,$3e,$00,$9a,$0c
        .byte   $0a,$24,$c0,$9c,$01
        .byte   $80,$74,$00,$9e,$02
        .byte   $20,$4c,$00,$9f,$3b
        .byte   $81,$a8,$00,$a1,$07
        .byte   $09,$12,$00,$a2,$19
        .byte   $20,$88,$00,$a4,$3c
        .byte   $20,$e4,$00,$a6,$3d
        .byte   $21,$40,$00,$a8,$3e
        .byte   $80,$a4,$00,$aa,$03
        .byte   $21,$8c,$80,$ab,$0e
        .byte   $08,$94,$40,$ad,$17
        .byte   $1e,$c0,$80,$af,$0d
        .byte   $a2,$60,$80,$b1,$0f
        .byte   $0e,$c0,$00,$b2,$20
        .byte   $22,$c6,$00,$b4,$3f
        .byte   $13,$fb,$00,$b6,$28
        .byte   $23,$06,$40,$b8,$40
        .byte   $23,$a6,$00,$ba,$41
        .byte   $23,$ee,$00,$bc,$42
        .byte   $0f,$d0,$c0,$be,$06
        .byte   $a4,$66,$00,$c0,$43
        .byte   $8d,$32,$00,$c1,$1e
        .byte   $1b,$d4,$80,$c2,$0b
        .byte   $24,$90,$80,$c4,$10
        .byte   $a5,$2c,$00,$c6,$44
        .byte   $94,$f7,$00,$c7,$2a
        .byte   $1b,$58,$00,$c8,$34
        .byte   $0f,$80,$00,$ca,$21
        .byte   $0a,$24,$c0,$cc,$01
        .byte   $13,$93,$00,$ce,$27
        .byte   $8c,$fc,$00,$d0,$1d
        .byte   $a4,$66,$00,$d1,$43
        .byte   $09,$c4,$00,$d2,$1b
        .byte   $0d,$98,$40,$d4,$1f
        .byte   $25,$47,$00,$d6,$45
        .byte   $07,$24,$00,$d8,$13
        .byte   $05,$1b,$00,$da,$10
        .byte   $25,$bb,$80,$dc,$11
        .byte   $26,$6f,$c0,$de,$12
        .byte   $27,$4f,$80,$e0,$13
        .byte   $1a,$45,$80,$e2,$0a
        .byte   $a5,$2c,$00,$e4,$44
        .byte   $1b,$58,$00,$e5,$34
        .byte   $03,$d6,$00,$e7,$0d
        .byte   $81,$a8,$00,$e9,$07
        .byte   $1b,$d4,$80,$ea,$0b
        .byte   $0f,$d0,$c0,$ec,$06
        .byte   $21,$40,$00,$ee,$3e
        .byte   $1f,$bc,$00,$f0,$39
        .byte   $18,$4d,$00,$f2,$2f
        .byte   $28,$53,$00,$f4,$46
        .byte   $a8,$a3,$00,$f6,$47
        .byte   $84,$a6,$00,$f7,$0f
        .byte   $28,$e8,$80,$f8,$14
        .byte   $19,$b9,$00,$fa,$32
        .byte   $0a,$b4,$40,$fc,$1c
        .byte   $88,$dc,$00,$fe,$18
        .byte   $1e,$c0,$80,$ff,$0d
        .byte   $2a,$0c,$01,$01,$48
        .byte   $2a,$54,$81,$03,$15
        .byte   $88,$10,$01,$05,$15
        .byte   $9c,$18,$01,$06,$35
        .byte   $23,$06,$41,$07,$40
        .byte   $ac,$34,$01,$09,$49
        .byte   $0f,$80,$01,$0a,$21
        .byte   $2c,$5b,$41,$0c,$4a
        .byte   $20,$88,$01,$0e,$3c
        .byte   $2c,$ff,$01,$10,$4b
        .byte   $a5,$2c,$01,$12,$44
        .byte   $23,$ee,$01,$13,$42
        .byte   $21,$8c,$81,$15,$0e
        .byte   $25,$47,$01,$17,$45
        .byte   $98,$c9,$01,$19,$30
        .byte   $2d,$cb,$81,$1a,$16
        .byte   $14,$97,$01,$1c,$29
        .byte   $1e,$c0,$81,$1e,$0d
        .byte   $ac,$34,$01,$20,$49
        .byte   $84,$a6,$01,$21,$0f
        .byte   $ae,$7b,$41,$22,$4c
        .byte   $04,$26,$01,$23,$0e
        .byte   $15,$2d,$01,$25,$2b
        .byte   $17,$4d,$01,$27,$2d
        .byte   $2e,$b4,$81,$29,$17
        .byte   $2f,$44,$01,$2b,$4d
        .byte   $28,$53,$00,$f4,$46
        .byte   $2f,$b4,$81,$2d,$18
        .byte   $80,$d4,$41,$2f,$04
        .byte   $b0,$34,$01,$30,$4e
        .byte   $30,$73,$01,$31,$4f
        .byte   $86,$d3,$01,$33,$12
        .byte   $25,$bb,$81,$34,$11
        .byte   $2a,$0c,$01,$36,$48
        .byte   $27,$4f,$80,$e0,$13
        .byte   $1a,$45,$80,$7b,$0a
        .byte   $21,$8c,$80,$ab,$0e
        .byte   $93,$48,$01,$38,$26
        .byte   $2c,$5b,$41,$39,$4a
        .byte   $19,$29,$41,$3b,$31
        .byte   $20,$88,$01,$3d,$3c
        .byte   $20,$e4,$01,$3f,$3d
        .byte   $20,$4c,$01,$41,$3b
        .byte   $1e,$10,$01,$43,$38
        .byte   $30,$b3,$41,$45,$50
        .byte   $19,$b9,$01,$47,$32
        .byte   $31,$27,$01,$49,$51
        .byte   $94,$f7,$01,$4b,$2a
        .byte   $31,$9b,$01,$4c,$52
        .byte   $b2,$2b,$01,$4e,$53
        .byte   $32,$6a,$81,$4f,$19
        .byte   $33,$76,$01,$51,$54
        .byte   $1c,$f0,$81,$53,$0c
        .byte   $02,$1a,$01,$55,$09
        .byte   $33,$ce,$41,$57,$55
        .byte   $34,$82,$c1,$59,$1a
        .byte   $27,$4f,$81,$5b,$13
        .byte   $26,$6f,$c1,$5d,$12
        .byte   $16,$09,$81,$5f,$09
        .byte   $23,$a6,$01,$61,$41
        .byte   $35,$5e,$01,$63,$56
        .byte   $23,$ee,$01,$65,$42
        .byte   $b5,$ca,$01,$67,$57
        .byte   $b6,$15,$01,$68,$58
        .byte   $36,$18,$c1,$69,$1b
        .byte   $24,$90,$81,$6b,$10
        .byte   $2c,$ff,$01,$6d,$4b
        .byte   $37,$64,$81,$6f,$1c
        .byte   $b9,$10,$41,$71,$59
        .byte   $97,$11,$01,$72,$2c
        .byte   $08,$94,$41,$73,$17
        .byte   $0a,$b4,$41,$75,$1c
        .byte   $b9,$10,$41,$77,$59
        .byte   $a8,$a3,$01,$78,$47
        .byte   $30,$b3,$41,$79,$50
        .byte   $1f,$bc,$01,$7b,$39
        .byte   $0c,$20,$c1,$7d,$03
        .byte   $02,$b2,$00,$12,$0b
        .byte   $0a,$b4,$41,$7f,$1c
        .byte   $a2,$60,$80,$b1,$0f
        .byte   $a2,$60,$80,$b1,$0f
        .byte   $16,$09,$81,$81,$09
        .byte   $b9,$52,$81,$83,$1d
        .byte   $12,$90,$80,$58,$07
        .byte   $0e,$1c,$80,$3f,$04
        .byte   $08,$40,$40,$26,$16
        .byte   $0a,$24,$c0,$30,$01
        .byte   $09,$12,$00,$2b,$19
        .byte   $0e,$c0,$00,$41,$20
        .byte   $19,$29,$40,$73,$31
        .byte   $1e,$c0,$80,$af,$0d
        .byte   $16,$09,$80,$68,$09
        .byte   $07,$24,$00,$d8,$13
        .byte   $0f,$d0,$c0,$be,$06
        .byte   $98,$c9,$00,$71,$30
        .byte   $13,$fb,$00,$5d,$28
        .byte   $1c,$54,$00,$85,$36
        .byte   $0c,$20,$c1,$84,$03
        .byte   $b9,$85,$01,$86,$5a
        .byte   $0f,$80,$00,$ca,$21
        .byte   $0f,$80,$01,$0a,$21
        .byte   $0f,$80,$00,$48,$21
        .byte   $00,$00,$01,$87,$00
        .byte   $8d,$32,$01,$89,$1e
        .byte   $15,$65,$80,$66,$08
        .byte   $80,$74,$00,$03,$02
        .byte   $00,$00,$01,$8a,$00
        .byte   $3a,$03,$81,$8c,$1e
        .byte   $3a,$e3,$81,$8e,$1f
        .byte   $3b,$8f,$81,$90,$20
        .byte   $3c,$67,$81,$92,$21
        .byte   $3e,$37,$c1,$94,$22
        .byte   $3e,$37,$c1,$96,$22
        .byte   $3e,$eb,$81,$98,$23
        .byte   $3f,$cf,$81,$9a,$24
        .byte   $05,$9b,$80,$1d,$00
        .byte   $40,$5f,$81,$9c,$25
        .byte   $41,$57,$81,$9e,$26
        .byte   $42,$5f,$81,$a0,$27
        .byte   $89,$8e,$01,$a2,$1a
        .byte   $43,$63,$81,$a3,$28
        .byte   $44,$1b,$01,$a5,$5b
        .byte   $01,$4c,$00,$08,$06
        .byte   $8d,$32,$01,$a7,$1e
        .byte   $44,$1f,$01,$a8,$5c
        .byte   $44,$77,$01,$aa,$5d
        .byte   $44,$d3,$81,$ac,$29
        .byte   $47,$77,$81,$ae,$2a
        .byte   $48,$93,$c1,$b0,$2b
        .byte   $48,$93,$c1,$b0,$2b
        .byte   $48,$93,$c1,$b0,$2b
        .byte   $48,$93,$c1,$b0,$2b
        .byte   $48,$93,$c1,$b0,$2b
        .byte   $16,$09,$81,$b2,$09
        .byte   $2d,$cb,$81,$b4,$16
        .byte   $93,$48,$01,$b6,$26
        .byte   $49,$cb,$c1,$b7,$2c
        .byte   $4a,$a3,$81,$b9,$2d
        .byte   $b9,$10,$41,$bb,$59
        .byte   $08,$40,$41,$bc,$16
        .byte   $cb,$a3,$01,$be,$5e
        .byte   $05,$9b,$81,$bf,$00
        .byte   $4a,$a3,$81,$b9,$2d
        .byte   $21,$8c,$81,$c1,$0e
        .byte   $b9,$52,$81,$83,$1d
        .byte   $49,$cb,$c1,$c3,$2c
        .byte   $4b,$d3,$81,$c5,$2e
        .byte   $4c,$ef,$01,$c7,$5f
        .byte   $4c,$ef,$01,$c7,$5f
        .byte   $4c,$ef,$01,$c7,$5f
        .byte   $4c,$ef,$01,$c7,$5f
        .byte   $4c,$ef,$01,$c7,$5f
        .byte   $4a,$a3,$81,$b9,$2d
        .byte   $49,$cb,$c1,$c9,$2c
        .byte   $4d,$0f,$81,$cb,$2f
        .byte   $b5,$ca,$01,$67,$57
        .byte   $b5,$ca,$01,$67,$57
        .byte   $b5,$ca,$01,$67,$57
        .byte   $b5,$ca,$01,$67,$57
        .byte   $4e,$d7,$81,$cd,$30
        .byte   $4f,$e7,$c1,$cf,$31
        .byte   $37,$64,$81,$d1,$1c
        .byte   $2a,$54,$81,$d3,$15
        .byte   $17,$4d,$01,$d5,$2d
        .byte   $d1,$53,$01,$d7,$60
        .byte   $81,$a8,$00,$0c,$07
        .byte   $15,$65,$81,$d8,$08
        .byte   $4f,$e7,$c1,$cf,$31
        .byte   $4f,$e7,$c1,$cf,$31
        .byte   $4f,$e7,$c1,$cf,$31
        .byte   $4f,$e7,$c1,$cf,$31
        .byte   $51,$98,$81,$da,$32
        .byte   $b9,$85,$01,$dc,$5a
        .byte   $52,$a4,$01,$dd,$61
        .byte   $52,$a4,$01,$df,$61
        .byte   $52,$a4,$01,$e1,$61
        .byte   $53,$34,$81,$e3,$33
        .byte   $28,$e8,$81,$e5,$14
        .byte   $54,$60,$81,$e7,$34
        .byte   $55,$4c,$01,$e9,$62
        .byte   $55,$ec,$c1,$eb,$35
        .byte   $56,$b8,$81,$ed,$36
        .byte   $48,$93,$c1,$ef,$2b
        .byte   $58,$74,$81,$f1,$37
        .byte   $2a,$54,$81,$f3,$15
        .byte   $59,$78,$81,$f5,$38
        .byte   $5c,$4c,$81,$f7,$39
        .byte   $00,$00,$01,$f9,$00
        .byte   $33,$76,$01,$fb,$54
        .byte   $89,$8e,$01,$fd,$1a
        .byte   $8c,$fc,$01,$fe,$1d
        .byte   $3b,$8f,$81,$ff,$20
        .byte   $00,$00,$02,$01,$00
        .byte   $5e,$2c,$82,$03,$3a
        .byte   $5f,$44,$82,$05,$3b
        .byte   $60,$64,$82,$07,$3c
        .byte   $61,$b8,$c2,$09,$3d
        .byte   $3c,$67,$81,$92,$21
        .byte   $62,$74,$02,$0b,$63
        .byte   $62,$78,$02,$0d,$64
        .byte   $4a,$a3,$81,$b9,$2d
        .byte   $4e,$d7,$81,$cd,$30
        .byte   $d1,$53,$02,$0f,$60
        .byte   $0b,$2c,$82,$10,$02
        .byte   $18,$4d,$02,$12,$2f
        .byte   $34,$82,$c2,$14,$1a
        .byte   $49,$cb,$c1,$c3,$2c
        .byte   $05,$1b,$00,$da,$10
        .byte   $41,$57,$81,$9e,$26
        .byte   $1c,$f0,$80,$8e,$0c
        .byte   $47,$77,$81,$ae,$2a
        .byte   $05,$1b,$02,$16,$10
        .byte   $36,$18,$c2,$18,$1b
        .byte   $e2,$7c,$82,$1a,$3e
        .byte   $e2,$88,$02,$1b,$65
        .byte   $e2,$88,$02,$1b,$65
        .byte   $e2,$88,$02,$1b,$65
        .byte   $e2,$88,$02,$1b,$65
        .byte   $37,$64,$81,$6f,$1c
        .byte   $e2,$8b,$82,$1c,$3f
        .byte   $e2,$c1,$82,$1d,$40
        .byte   $00,$00,$00,$00,$00
        .byte   $b9,$52,$81,$83,$1d
        .byte   $0e,$1c,$80,$3f,$04
        .byte   $12,$90,$80,$58,$07
        .byte   $2d,$cb,$82,$1e,$16
        .byte   $a2,$60,$80,$b1,$0f
        .byte   $24,$90,$80,$c4,$10
        .byte   $62,$f1,$82,$20,$41
        .byte   $63,$89,$82,$22,$42
        .byte   $51,$98,$81,$da,$32
        .byte   $64,$55,$82,$24,$43
        .byte   $54,$60,$81,$e7,$34
        .byte   $56,$b8,$81,$ed,$36
        .byte   $e5,$51,$82,$26,$44

; ------------------------------------------------------------------------------

.export BattleBGProp, BattleBGPal
.export BattleBGAnim, BattleBGAnimPtrs
.export BattleBGPalAnim, BattleBGPalAnimPtrs
.export BattleBGFlip, BattleBGFlipPtrs
.export BattleBGTiles, BattleBGTilesPtrs

.segment "battle_bg"

; d4/ba21
BattleBGProp:
        .incbin "battle_bg_prop.dat"

; d4/bb31: battle bg palettes (84 items, 32 bytes each)
BattleBGPal:
        .repeat 84, i
        .incbin .sprintf("battle_bg_pal/pal_%04x.pal", i)
        .endrep

; ---------------------------------------------------------------------------

.scope BattleBGAnim
        Start := bank_start BattleBGAnim
        ARRAY_LENGTH = 8
.endscope

; d4/c5b1: pointers to battle bg animation data (+$D40000)
BattleBGAnimPtrs:
        ptr_tbl BattleBGAnim

; d4/c5c1: battle bg animation data (8 items, variable size)

; Battle BG tile animation works by copying tile graphics from secondary
; buffers to the VRAM buffer, then from the VRAM buffer to VRAM. The data below
; is a list of tiles to copy. Up to 16 tiles get copied from the secondary
; buffers to the VRAM buffer every frame. During NMI, 8 tiles get transferred
; to VRAM every frame, so it takes 8 frames to copy all 64 tiles to VRAM.
; When the FF terminator is encountered, it loops back to the start of the
; animation data list. Each animated tile in the animation data is stored as 2
; bytes in the format below. There are 128 battle bg tiles, but only the first
; 64 can be animated.

; ffdddddd vhssssss 2-byte per animated tile format
;   f: frame index (cycles at 7.5 hz)
;   d: destination tile index
;   v: vertical flip (used if v+h set, can't flip both simultaneously)
;   h: horizontal flip
;   s: source tile index

BattleBGAnim:

; castle interior
BattleBGAnim::_7:
        .byte   $29,$29
        .byte   $69,$2a
        .byte   $a9,$2b
        .byte   $e9,$2c
        .byte   $ff

; castle exdeath
BattleBGAnim::_6:
        .byte   $10,$10,$11,$11,$20,$20,$21,$21,$18,$18,$19,$19,$28,$28,$29,$29
        .byte   $50,$12,$51,$13,$60,$22,$61,$23,$58,$1a,$59,$1b,$68,$2a,$69,$2b
        .byte   $90,$14,$91,$15,$a0,$24,$a1,$25,$98,$1c,$99,$1d,$a8,$2c,$a9,$2d
        .byte   $d0,$16,$d1,$17,$e0,$26,$e1,$27,$d8,$1e,$d9,$1f,$e8,$2e,$e9,$2f
        .byte   $ff

; flying fortress
BattleBGAnim::_5:
        .byte   $30,$30,$31,$31,$32,$32,$33,$33
        .byte   $70,$34,$71,$35,$72,$36,$73,$37
        .byte   $b0,$38,$b1,$39,$b2,$3a,$b3,$3b
        .byte   $f0,$3c,$f1,$3d,$f2,$3e,$f3,$3f
        .byte   $ff

; beach
BattleBGAnim::_4:
        .byte   $00,$00,$01,$01
        .byte   $40,$02,$41,$03
        .byte   $80,$04,$81,$05
        .byte   $c0,$02,$c1,$03
        .byte   $ff

; unknown
BattleBGAnim::_3:
        .byte   $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07,$08,$08
        .byte   $49,$09,$4a,$0a,$4b,$0b,$4c,$0c,$4d,$0d,$4e,$0e,$61,$21,$62,$22
        .byte   $80,$10,$81,$11,$82,$12,$83,$13,$84,$14,$85,$15,$86,$16,$87,$17,$88,$18
        .byte   $c9,$19,$ca,$1a,$cb,$1b,$cc,$1c,$cd,$1d,$ce,$1e,$e1,$23,$e2,$24
        .byte   $ff

; none
BattleBGAnim::_0:
        .byte   $ff

; cave w/ water
BattleBGAnim::_1:
        .byte   $30,$30,$31,$31,$38,$38,$39,$39
        .byte   $70,$32,$71,$33,$78,$3a,$79,$3b
        .byte   $b0,$34,$b1,$35,$b8,$3c,$b9,$3d
        .byte   $f0,$36,$f1,$37,$f8,$3e,$f9,$3f
        .byte   $ff

; fire-powered ship
BattleBGAnim::_2:
        .byte   $0b,$0b,$10,$10,$14,$14,$18,$18,$19,$19
        .byte   $4b,$0c,$50,$11,$54,$15,$58,$1a,$59,$1b
        .byte   $8b,$0d,$90,$12,$94,$16,$98,$1c,$99,$1d
        .byte   $cb,$0e,$d0,$13,$d4,$17,$d8,$1e,$d9,$1f
        .byte   $ff

; ---------------------------------------------------------------------------

.scope BattleBGPalAnim
        Start := bank_start BattleBGPalAnim
        ARRAY_LENGTH = 3
.endscope

; d4/c6cd: pointers to battle bg palette animation data (+$D4000)
BattleBGPalAnimPtrs:
        ptr_tbl BattleBGPalAnim

; d4/c6d3: battle bg palette animation data (3 items, variable size)

; One 16-color palette gets loaded each frame. The MSB determines if it
; gets copied to the first or second battle bg palette in vram. The lower
; bits are the index of the battle bg palette to load from the ROM.

BattleBGPalAnim:

; the void
BattleBGPalAnim::_1:
        .byte   $24,$24,$24,$24,$24,$24,$24,$24
        .byte   $a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5
        .byte   $38,$38,$38,$38,$38,$38,$38,$38
        .byte   $b9,$b9,$b9,$b9,$b9,$b9,$b9,$b9
        .byte   $3a,$3a,$3a,$3a,$3a,$3a,$3a,$3a
        .byte   $bb,$bb,$bb,$bb,$bb,$bb,$bb,$bb
        .byte   $38,$38,$38,$38,$38,$38,$38,$38
        .byte   $b9,$b9,$b9,$b9,$b9,$b9,$b9,$b9
        .byte   $ff

; neo exdeath
BattleBGPalAnim::_2:
        .byte   $40,$40
        .byte   $41,$41
        .byte   $42,$42
        .byte   $43,$43
        .byte   $44,$44
        .byte   $45,$45
        .byte   $46,$46
        .byte   $ff

; flying fortress
BattleBGPalAnim::_0:
        .byte   $30,$b1,$b1
        .byte   $30,$b4,$b4
        .byte   $32,$b5,$b5
        .byte   $32,$b1,$b1
        .byte   $33,$b4,$b4
        .byte   $33,$b5,$b5
        .byte   $ff

; ---------------------------------------------------------------------------

.scope BattleBGFlip
        Start := bank_start BattleBGFlip
        ARRAY_LENGTH = 9
.endscope

; d4/c736: pointers to battle bg tile flip data (+$D40000)
BattleBGFlipPtrs:
        ptr_tbl BattleBGFlip

; d4/c748: battle bg tile flip data (9 items, variable size)
BattleBGFlip:

BattleBGFlip::_7: .incbin "battle_bg_flip/desert_holes.dat.bgf"
BattleBGFlip::_0: .incbin "battle_bg_flip/none.dat.bgf"
BattleBGFlip::_6: .incbin "battle_bg_flip/void.dat.bgf"
BattleBGFlip::_1: .incbin "battle_bg_flip/forest.dat.bgf"
BattleBGFlip::_2: .incbin "battle_bg_flip/moore_ext.dat.bgf"
BattleBGFlip::_3: .incbin "battle_bg_flip/mountain_ext.dat.bgf"
BattleBGFlip::_4: .incbin "battle_bg_flip/beach.dat.bgf"
BattleBGFlip::_5: .incbin "battle_bg_flip/grass.dat.bgf"
BattleBGFlip::_8: .incbin "battle_bg_flip/final_battle.dat.bgf"

; ------------------------------------------------------------------------------

.scope BattleBGTiles
        Start := bank_start BattleBGTiles
        ARRAY_LENGTH = 28
.endscope

; d4/c86d: pointers to battle bg tile layout (+$D40000)
BattleBGTilesPtrs:
        ptr_tbl BattleBGTiles

; d4/c8a5: battle bg tile layout (28 items, variable size)
BattleBGTiles:

BattleBGTiles::_27: .incbin "battle_bg_tiles/final_battle.scr.bgt"
BattleBGTiles::_26: .incbin "battle_bg_tiles/phoenix_tower.scr.bgt"
BattleBGTiles::_25: .incbin "battle_bg_tiles/ronka_ruins.scr.bgt"
BattleBGTiles::_23: .incbin "battle_bg_tiles/void.scr.bgt"
BattleBGTiles::_20: .incbin "battle_bg_tiles/flying_fortress.scr.bgt"
BattleBGTiles::_21: .incbin "battle_bg_tiles/moore_int.scr.bgt"
BattleBGTiles::_22: .incbin "battle_bg_tiles/castle_exdeath.scr.bgt"
BattleBGTiles::_19: .incbin "battle_bg_tiles/ship_ext.scr.bgt"
BattleBGTiles::_8: .incbin "battle_bg_tiles/swamp.scr.bgt"
BattleBGTiles::_9: .incbin "battle_bg_tiles/tower_int.scr.bgt"
BattleBGTiles::_10: .incbin "battle_bg_tiles/tower_ext.scr.bgt"
BattleBGTiles::_11: .incbin "battle_bg_tiles/shrine.scr.bgt"
BattleBGTiles::_12: .incbin "battle_bg_tiles/castle_int.scr.bgt"
BattleBGTiles::_13: .incbin "battle_bg_tiles/castle_ext.scr.bgt"
BattleBGTiles::_14: .incbin "battle_bg_tiles/library.scr.bgt"
BattleBGTiles::_15: .incbin "battle_bg_tiles/pyramid.scr.bgt"
BattleBGTiles::_0: .incbin "battle_bg_tiles/grass.scr.bgt"
BattleBGTiles::_1: .incbin "battle_bg_tiles/beach.scr.bgt"
BattleBGTiles::_2: .incbin "battle_bg_tiles/desert.scr.bgt"
BattleBGTiles::_24: .incbin "battle_bg_tiles/desert_holes.scr.bgt"
BattleBGTiles::_3: .incbin "battle_bg_tiles/forest.scr.bgt"
BattleBGTiles::_4: .incbin "battle_bg_tiles/moore_ext.scr.bgt"
BattleBGTiles::_5: .incbin "battle_bg_tiles/cave.scr.bgt"
BattleBGTiles::_6: .incbin "battle_bg_tiles/cave_water.scr.bgt"
BattleBGTiles::_7: .incbin "battle_bg_tiles/mountain_ext.scr.bgt"
BattleBGTiles::_16: .incbin "battle_bg_tiles/ship_int.scr.bgt"
BattleBGTiles::_17: .incbin "battle_bg_tiles/shipwreck_int.scr.bgt"
BattleBGTiles::_18: .incbin "battle_bg_tiles/fire_ship.scr.bgt"

; ------------------------------------------------------------------------------

.export MonsterGfx

.segment "monster_gfx"

; d5/0000
MonsterGfx:
        .incbin "monster_gfx.dat"

; ------------------------------------------------------------------------------

.export _d84157, BattleBGGfxPtrs

.segment "battle_bg_gfx"

_d84157:
        .faraddr $7fc000
        .faraddr $7fc600
        .faraddr $7fcc00
        .faraddr $7fd600
        .faraddr $7fc000
        .faraddr $7fc200
        .faraddr $7fc000
        .faraddr $7fd000
        .faraddr $7fc000
        .faraddr $7fcc00
        .faraddr $7fca00
        .faraddr $7fd200
        .faraddr $7fc000
        .faraddr $7fc000
        .faraddr $7fda00
        .faraddr $7fe000
        .faraddr $7fc000
        .faraddr $7fce00
        .faraddr $7fce00
        .faraddr $7fc000
        .faraddr $7fc000

.scope BattleBGGfx
        ARRAY_LENGTH = 21
.endscope

; d8/4196
BattleBGGfxPtrs:
        ptr_tbl_far BattleBGGfx

; d8/41d5: Tower, Shrine, Castle, Pyramid
BattleBGGfx::_6:
BattleBGGfx::_7:
        .incbin "battle_bg_gfx/gfx_0000.4bpp.lz"

; d8/5a3d: Swamp, Library, Forest of Moore Interior, Castle Exdeath, Ship Exterior
BattleBGGfx::_8:
BattleBGGfx::_9:
BattleBGGfx::_14:
BattleBGGfx::_15:
        .incbin "battle_bg_gfx/gfx_0001.4bpp.lz"

; d8/7878: Flying Fortress, Ronka Ruins
BattleBGGfx::_16:
BattleBGGfx::_18:
        .incbin "battle_bg_gfx/gfx_0002.4bpp.lz"

; d8/88b2: Forest, Desert, Beach, Cave
BattleBGGfx::_0:
BattleBGGfx::_1:
BattleBGGfx::_2:
BattleBGGfx::_3:
BattleBGGfx::_5:
        .incbin "battle_bg_gfx/gfx_0003.4bpp.lz"

; d8/a517: Ship Interior, Mountain, Fire-Powered Ship
BattleBGGfx::_4:
BattleBGGfx::_10:
BattleBGGfx::_11:
        .incbin "battle_bg_gfx/gfx_0004.4bpp.lz"

; d8/b959: Grass, The Void
BattleBGGfx::_13:
BattleBGGfx::_17:
        .incbin "battle_bg_gfx/gfx_0005.4bpp.lz"

; d8/cdd8: Final Battle
BattleBGGfx::_20:
        .incbin "battle_bg_gfx/gfx_0006.4bpp.lz"

; d8/d881: Phoenix Tower
BattleBGGfx::_19:
        .incbin "battle_bg_gfx/gfx_0007.4bpp.lz"

; d8/dc32: Neo Exdeath
BattleBGGfx::_12:
        .incbin "battle_bg_gfx/gfx_0008.4bpp.lz"

; ------------------------------------------------------------------------------

.export _d8de36, _d8de4e, _d8de5a, _d8de7a

; d8/de36
_d8de36:
        .byte   $00,$08,$00,$08
        .byte   $00,$08,$00,$08
        .byte   $10,$00,$08,$10
        .byte   $08,$00,$08,$00
        .byte   $08,$00,$10,$08
        .byte   $00,$10,$08,$00

; d8/de4e
_d8de4e:
        .byte   $00,$00
        .byte   $08,$08
        .byte   $10,$10
        .byte   $08,$08
        .byte   $08,$10
        .byte   $10,$10

; d8/de5a
_d8de5a:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $06,$00,$00,$00,$00,$00,$00,$06
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $06,$00,$00,$00,$00,$00,$00,$06

; d8/de7a
_d8de7a:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
        .byte   $00,$02,$00,$02,$00,$02,$00,$02,$03,$03,$03,$03,$03,$03,$03,$03
        .byte   $04,$02,$04,$02,$04,$02,$04,$02,$06,$05,$06,$05,$06,$05,$06,$05
        .byte   $00,$07,$00,$07,$00,$07,$00,$07,$08,$08,$08,$08,$08,$08,$08,$08
        .byte   $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$09,$0a,$09,$0a,$09,$0a,$09,$0a
        .byte   $05,$04,$06,$00,$01,$02,$03,$07,$07,$07,$07,$07,$07,$07,$07,$07
        .byte   $05,$05,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$06
        .byte   $08,$06,$08,$06,$08,$06,$08,$06,$16,$16,$16,$16,$16,$16,$16,$16
        .byte   $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
        .byte   $0c,$0e,$0c,$0e,$0c,$0e,$0c,$0e,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        .byte   $10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c
        .byte   $11,$0c,$11,$0c,$11,$0c,$11,$0c,$12,$12,$12,$12,$12,$12,$12,$12
        .byte   $13,$13,$13,$13,$13,$13,$13,$13,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
        .byte   $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$11,$11,$11,$11,$11,$11,$11,$11
        .byte   $11,$11,$11,$11,$11,$11,$11,$11,$10,$10,$10,$10,$10,$10,$10,$10
        .byte   $12,$10,$12,$10,$12,$10,$12,$10,$11,$11,$11,$11,$11,$11,$11,$11
        .byte   $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
        .byte   $0c,$0e,$0c,$0e,$0c,$0e,$0c,$0e,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        .byte   $10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c,$10,$0c
        .byte   $11,$0c,$11,$0c,$11,$0c,$11,$0c,$12,$12,$12,$12,$12,$12,$12,$12
        .byte   $13,$13,$13,$13,$13,$13,$13,$13,$14,$15,$14,$15,$14,$15,$14,$15
        .byte   $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$11,$11,$11,$11,$11,$11,$11,$11
        .byte   $11,$11,$11,$11,$11,$11,$11,$11,$10,$10,$10,$10,$10,$10,$10,$10
        .byte   $12,$10,$12,$10,$12,$10,$12,$10,$11,$11,$11,$11,$11,$11,$11,$11

; ------------------------------------------------------------------------------

.segment "attack_gfx2"

.export AttackGfx1, AttackGfx2, AttackGfx3

; d9/0000
AttackGfx1:
        .incbin "attack1.3bpp"

; d9/2ec8
AttackGfx2:
        .incbin "attack2.3bpp"

; d9/5760
AttackGfx3:
        .incbin "attack3.3bpp"


; ------------------------------------------------------------------------------

.segment "world_gfx"

.export WorldGfx

; db/8000
WorldGfx:
        .incbin "world_gfx/bartz_world.4bpp"
        .incbin "world_gfx/galuf_world.4bpp"
        .incbin "world_gfx/underwater.4bpp"

; ------------------------------------------------------------------------------

.segment "map_sprite_gfx"

.export MapSpriteGfx, VehicleGfx, WorldSpriteGfx

; da/0000
MapSpriteGfx:
        .incbin "map_sprite.4bpp"

; db/3a00
VehicleGfx:
        .incbin "vehicle.3bpp"

; db/4d80
WorldSpriteGfx:
        .incbin "world_sprite.4bpp"

; ------------------------------------------------------------------------------

.segment "kanji_gfx"

.export KanjiGfx

; db/d000
KanjiGfx:
        .incbin "kanji.1bpp"

; ------------------------------------------------------------------------------

.segment "map_gfx"

.export MapBG3Gfx, MapBG3GfxPtrs, MapGfx, MapGfxPtrs

.enum MapBG3Gfx
        ARRAY_LENGTH = 17
        Start = MapBG3Gfx
.endenum

; dc/0000
MapBG3GfxPtrs:
        ptr_tbl MapBG3Gfx
        end_ptr MapBG3Gfx

; dc/0024
MapBG3Gfx:

.repeat MapBG3Gfx::ARRAY_LENGTH, i
        array_item MapBG3Gfx, {i} := *
        .incbin .sprintf("map_bg3_gfx/map_bg3_gfx_%04x.2bpp", i)
.endrep
MapBG3Gfx::End:

; ------------------------------------------------------------------------------

.enum MapGfx
        ARRAY_LENGTH = 39
        Start = MapGfx
.endenum

; dc/2d84
MapGfxPtrs:
        ptr_tbl_dword MapGfx
        end_ptr_dword MapGfx

; dc/2e24
MapGfx:
.repeat MapGfx::ARRAY_LENGTH, i
        array_item MapGfx, {i} := *
        .incbin .sprintf("map_gfx/map_gfx_%04x.4bpp", i)
.endrep
MapGfx::End:

; ------------------------------------------------------------------------------

.segment "map_anim_gfx"

.export MapAnimGfx

; df/9b00
MapAnimGfx:
        .incbin "map_anim.4bpp"

; ------------------------------------------------------------------------------

.segment "map_sprite_pal"

.export MapSpritePal

; df/fc00
MapSpritePal:
.repeat 32, i
        .incbin .sprintf("map_sprite_pal/map_sprite_%04x.pal", i)
.endrep

.export MapSpritePal_8 := MapSpritePal + 8 * 32
.export VehiclePal := MapSpritePal + 26 * 32
.export MapSpritePal_bf05 := MapSpritePal + $224

; ------------------------------------------------------------------------------
