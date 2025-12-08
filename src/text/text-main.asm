
; +----------------------------------------------------------------------------+
; |                                                                            |
; |                              FINAL FANTASY V                               |
; |                                                                            |
; +----------------------------------------------------------------------------+
; | file: src/text/text-main.asm                                               |
; |                                                                            |
; | description: game text                                                     |
; +----------------------------------------------------------------------------+

.p816

.include "macros.inc"
.include "const.inc"

; ------------------------------------------------------------------------------

inc_lang "text/dlg_%s.inc"
inc_lang "text/map_title_%s.inc"
inc_lang "text/battle_dlg_%s.inc"
inc_lang "text/battle_msg_%s.inc"
inc_lang "text/item_desc_%s.inc"
inc_lang "text/job_desc_%s.inc"
inc_lang "text/ability_desc_%s.inc"
inc_lang "text/menu_text_%s.inc"

.export ItemName, JobName, MagicName, AttackName, MonsterName
.export MonsterSpecialName, StatusName, BattleCmdName
.export PassiveAbilityName, SpecialAbilityName

; ------------------------------------------------------------------------------

.segment "dlg_ptrs"

; In the RPGe translation, this pointer table is unchanged from the original,
; but since the Japanese dialogue is not loaded, there's no simple way to
; output the pointers to the Japanese dialogue. For now, this simply
; outputs 16-bit points to the English dialogue instead.

; c8/2220
.if !LANG_EN
DlgPtrs:
.endif
        ptr_tbl Dlg

; ------------------------------------------------------------------------------

.segment "dlg"

; ca/0000
.if !LANG_EN
Dlg:
.endif
        .incbin "dlg_jp.dat"

; Extra text in the RPGe translation (pretty sure these are all unused)
; ca/00ee: "Lenna: Do you really have to go?"
; ca/01ba: "Lenna"
; ca/eca2: "What is going on in here?"

; ------------------------------------------------------------------------------

.segment "monster_name"

; d0/5c00
.if LANG_EN
        .res 384 * 8, $ff
.else
MonsterName:
        .incbin "monster_name_jp.dat"
.endif

; ------------------------------------------------------------------------------

.segment "monster_special_name"

; d0/8700
.if !LANG_EN
MonsterSpecialName:
.endif
        .incbin "monster_special_name_jp.dat"

; ------------------------------------------------------------------------------

.segment "map_title"

; d0/7000
MapTitlePtrs:
        fixed_block $0200
        ptr_tbl MapTitle
        end_fixed_block

; d0/7200
.if !LANG_EN
MapTitle:
.endif
        fixed_block $0600
        .incbin "map_title_jp.dat"
        end_fixed_block

; ------------------------------------------------------------------------------

.segment "battle_dlg"

; d0/f000
BattleDlgPtrs:
        ptr_tbl BattleDlg

; d0/f1d4
.if !LANG_EN
BattleDlg:
        .incbin "battle_dlg_jp.dat"
.endif

; ------------------------------------------------------------------------------

.segment "item_name"

; d1/1380
.if LANG_EN
.export ItemNameShort := *
.else
ItemName:
.endif
        incbin_lang "item_name_%s.dat"

; ------------------------------------------------------------------------------

.segment "attack_name"

        fixed_block $0800

; d1/1c80
MagicName:
        incbin_lang "magic_name_%s.dat"

; d1/1e8a
AttackName:
        incbin_lang "attack_name_%s.dat"

        end_fixed_block

; ------------------------------------------------------------------------------

.segment "status_name"

; d1/28b6: status names (24 items, 8 bytes each)
StatusName:
        incbin_lang "src/text/status_name_%s.dat"

; ------------------------------------------------------------------------------

.export AttackMessageTbl

.segment "battle_msg"

; d1/3840
AttackMessageTbl:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$34,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$4d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$35,$00,$00,$36,$37,$38,$39,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$40,$3d,$00,$46,$00,$43,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$45,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$3a,$00,$00,$00,$3b,$3b,$3b,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$40,$41,$42,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$47,$48,$00,$00,$00,$00,$00,$34,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $49,$00,$00,$00,$4a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00

; d1/39a9
BattleMsgPtrs:
        ptr_tbl BattleMsg

; d1/3ba9
.if !LANG_EN
BattleMsg:
        .incbin "battle_msg_jp.dat"
.endif

; ------------------------------------------------------------------------------

.segment "item_desc"

; d1/4000
ItemDescPtrs:
        ptr_tbl ItemDesc

; d1/4100
ItemDesc:
        incbin_lang "item_desc_%s.dat"

; At d1/4658 in the RPGe translation
; "of `Doom'!"

; ------------------------------------------------------------------------------

.segment "char_name"

; d1/5500
CharName:
        .incbin "char_name_jp.dat"

; ------------------------------------------------------------------------------

.segment "job_name"

; d1/5600
JobName:
        incbin_lang "job_name_%s.dat"

; ------------------------------------------------------------------------------

.segment "battle_cmd_name"

; d1/5800
.if LANG_EN
        .res 96 * 5, $ff
.else
BattleCmdName:
        .incbin "battle_cmd_name_jp.dat"
.endif

; ------------------------------------------------------------------------------

.segment "passive_ability_name"

; d1/6200
.if !LANG_EN
PassiveAbilityName:
.endif
        incbin_lang "passive_ability_name_%s.dat"

; ------------------------------------------------------------------------------

.segment "special_ability_name"

; d1/6700
.if LANG_EN
        .res 105 * 9
.else
SpecialAbilityName:
        .incbin "special_ability_name_jp.dat"
.endif

; ------------------------------------------------------------------------------

.segment "job_ability_desc"

; d1/7140: pointers to job descriptions (+$D10000)
JobDescPtrs:
        ptr_tbl JobDesc

; d1/716c: pointers to ability descriptions (+$D10000)
AbilityDescPtrs:
        ptr_tbl AbilityDesc

; d1/724a: job descriptions (22 items, variable size)
JobDesc:
        incbin_lang "job_desc_%s.dat"

; d1/7337: ability descriptions (111 items, variable size)
AbilityDesc:
        incbin_lang "ability_desc_%s.dat"

; ------------------------------------------------------------------------------

.if LANG_EN

.segment "monster_name_en"

; e0/0050
MonsterName:
        .incbin "monster_name_en.dat"

.segment "battle_cmd_name_en"

.export BattleCmdNameOffsets

; e0/0f70: 5-byte pointers to battle command names
BattleCmdNameOffsets:
.repeat 96, i
        .dword i*7
        .byte 0
.endrep

; e0/1150
BattleCmdName:
        .incbin "battle_cmd_name_en.dat"

.segment "dlg_en_ptrs"

; e0/13f0
DlgPtrs:
        ptr_tbl_far Dlg

.segment "dlg_en"

; e1/0000
Dlg:
        .incbin "dlg_en.dat"

.segment "special_ability_name_en"

; e7/0900
SpecialAbilityName:
        .incbin "special_ability_name_en.dat"

.segment "attack_name_short_en"

.export AttackNameShort

; e7/0900
AttackNameShort:
        .incbin "attack_name_short_en.dat"

.export AttackNameLong

.segment "attack_name_long_en"

; e7/1780
AttackNameLong:
        .incbin "attack_name_long_en.dat"

.segment "battle_msg_en"

; e7/2760
BattleMsg:
        .incbin "battle_msg_en.dat"

.segment "menu_text_en"

; e7/2f00
MenuText:
        .incbin "menu_text_en.dat"

.segment "key_item_name_en"

.export KeyItemName, _e736a0

; e7/3500
KeyItemName:
        .incbin "key_item_name_en.dat"

; e7/36a0
_e736a0:
        .word   $6388,$63a4,$6408,$6424,$6488,$64a4,$6508,$6524
        .word   $6588,$65a4,$6608,$6624,$6688,$66a4,$6708,$6724
        .word   $6788,$67a4,$6808,$6824,$6888,$68a4,$68a4,$68a4
        .word   $68a4,$68a4,$68a4,$68a4,$68a4,$68a4,$68a4,$68a4
        .word   $68a4,$68a4,$68a4,$68a4,$68a4,$68a4,$68a4,$68a4
        .word   $68a4

.segment "monster_special_name_en"

; e7/3700
MonsterSpecialName:
        .incbin "monster_special_name_en.dat"

.segment "battle_dlg_en"

; e7/3b00
BattleDlg:
        .incbin "battle_dlg_en.dat"

.segment "item_desc_en"

; unused item descriptions (likely from early in translation development)

inc_lang "text/item_desc_old_%s.inc"

; e7/5100
        ptr_tbl ItemDescOld

; e7/5200
ItemDescOld:
        .incbin "item_desc_old_en.dat"

.segment "map_title_en"

; e7/7000
MapTitle:
        .incbin "map_title_en.dat"

.segment "item_name_en"

; e7/5860
ItemName:
        .incbin "item_name_long_en.dat"

.segment "passive_ability_name_en"

; e7/7060
PassiveAbilityName:
        .incbin "passive_ability_name_long_en.dat"

.endif
