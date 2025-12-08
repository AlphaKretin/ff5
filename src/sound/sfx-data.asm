
; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: sound/sfx-data.asm                                                |
; |                                                                         |
; | description: sound effects data                                         |
; +-------------------------------------------------------------------------+

; c4/1e3f
SfxBRR:
        .incbin "sfx_brr.dat"

; ---------------------------------------------------------------------------

; c4/1f4f
SfxLoopStart:
        spc_block
        .word $4800,$4800
        .word $4824,$4824
        .word $4848,$4848
        .word $486c,$4887
        .word $48ab,$48c6
        .word $48d8,$48d8
        .word $48ea,$48ea
        .word $48fc,$48fc
        end_spc_block

; c4/1f71
SfxADSR:
        spc_block
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        make_adsr 15,7,7,0
        end_spc_block

; c4/1f83
SfxFreqMult:
        spc_block
        .byte $e0,$a0
        .byte $e0,$a0
        .byte $e0,$a0
        .byte $e0,$a0
        .byte $00,$00
        .byte $e0,$a0
        .byte $e0,$a0
        .byte $e0,$a0
        end_spc_block

; ---------------------------------------------------------------------------

; c4/1f95
SfxScript:
        .incbin "sfx_script.dat"

; ---------------------------------------------------------------------------