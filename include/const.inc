; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: const.inc                                                         |
; |                                                                         |
; | description: assembler constants                                        |
; +-------------------------------------------------------------------------+

.list off
.ifndef CONST_INC
CONST_INC = 1

; ---------------------------------------------------------------------------

; define a config constant if it's not already defined
.macro def_config _const, _value
        .ifndef _const
        _const = _value
        .endif
.endmacro

        def_config LANG_EN, 0
        def_config BUGFIX_DECOMP, 0

; define language suffix
.if LANG_EN
        .define LANG_SUFFIX "en"
.else
        .define LANG_SUFFIX "jp"
.endif

; ---------------------------------------------------------------------------

; bit masks

BIT_0               = %00000001
BIT_1               = %00000010
BIT_2               = %00000100
BIT_3               = %00001000
BIT_4               = %00010000
BIT_5               = %00100000
BIT_6               = %01000000
BIT_7               = %10000000

; ---------------------------------------------------------------------------

.endif

.enum ATTACK
        FIRE            = $00
        BATTLE          = $80
        SPECIAL         = $81
        GOBLIN_PUNCH    = $93
.endenum

.list on
