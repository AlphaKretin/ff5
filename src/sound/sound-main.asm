; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: sound/sound-main.asm                                              |
; |                                                                         |
; | description: sound/music main source file                               |
; +-------------------------------------------------------------------------+

.p816

.include "macros.inc"
.include "hardware.inc"
.include "const.inc"

.include "sound/song_script.inc"
.include "sound/sample_brr.inc"

.export InitSound_ext, ExecSound_ext

; ------------------------------------------------------------------------------

; [ begin/end block of SPC data ]

_spc_block_seq .set 0

; each spc block is preceded by a 2-byte header containing the block size
.macro spc_block
        .word .ident(.sprintf("_spc_block_size_%d", _spc_block_seq))
        .ident(.sprintf("_spc_block_start_%d", _spc_block_seq)) := *
.endmac

.macro end_spc_block
        .local start
        start = .ident(.sprintf("_spc_block_start_%d", _spc_block_seq))
        .ident(.sprintf("_spc_block_size_%d", _spc_block_seq)) = * - start
        _spc_block_seq .set _spc_block_seq + 1
.endmac

; ------------------------------------------------------------------------------

; [ make adsr value ]

.macro make_adsr attack, decay, sustain, release
        .byte $80 | (attack & $0f) | ((decay & $07) << 4)
        .byte (release & $1f) | ((sustain & $07) << 5)
.endmac

; ------------------------------------------------------------------------------

.segment "sound_code"

; ---------------------------------------------------------------------------

.proc InitSound_ext

_0000:  jmp     InitSound
        nop

.endproc

; ---------------------------------------------------------------------------

.proc ExecSound_ext

_0004:  jmp     ExecSound
        nop

.endproc

; ---------------------------------------------------------------------------

_c40008:
        .addr   SPCCode
        .addr   SfxScript
        .addr   SfxBRR
        .addr   SfxLoopStart
        .addr   SfxADSR
        .addr   SfxFreqMult

_c40014:
        .word   $0200
        .word   $2c00
        .word   $4800
        .word   $1b00
        .word   $1a80
        .word   $1a00

_c40020:
        .addr   SongScriptPtrs
        .addr   SampleBRRPtrs
        .addr   SampleLoopStart
        .addr   SampleADSR
        .addr   SampleFreqMult
        .addr   SongSamples

; ---------------------------------------------------------------------------

; [ init spc ]

InitSound:
_002c:  phb
        phd
        php
        longa
        longi
        pha
        phx
        phy
        shorta
        lda     #$00
        pha
        plb
        ldx     #$1d00
        phx
        pld
        ldx     #$bbaa
        ldy     #$0800
@0047:  cpx     hAPUIO0
        beq     @007e
        dey
        bne     @0047
        ldy     $f8
        beq     @007e
        cpy     $48
        bne     @007e
        lda     #$f0
        cmp     $00
        bne     @007e       ; branch if full reset
        lda     #$08
        sta     hAPUIO1
        lda     #$00
        sta     hAPUIO0
        ldx     #$00f8
@006a:  sta     $1cff,x
        dex
        bne     @006a
        ldy     $f8
        sty     $48
        dec
        sta     $05
        lda     #$f0
        sta     $00
        jmp     _0161
@007e:  cpx     hAPUIO0
        bne     @007e
        ldx     #$0000
        lda     f:_c40014
        sta     hAPUIO2
        lda     f:_c40014+1
        sta     hAPUIO3
        lda     #$cc
        sta     hAPUIO1
        sta     hAPUIO0
@009c:  cmp     hAPUIO0
        bne     @009c
@00a1:  lda     #$00
        xba
        lda     f:_c40008,x
        sta     $14
        lda     f:_c40008+1,x
        sta     $15
        lda     #^*
        sta     $16
        ldy     #$0000
        lda     [$14],y
        clc
        adc     #$02
        sta     $10
        iny
        lda     [$14],y
        adc     #$00
        sta     $11
        iny
@00c6:  lda     [$14],y
        sta     hAPUIO1
        xba
        sta     hAPUIO0
@00cf:  cmp     hAPUIO0
        bne     @00cf    ; infinite loop?
        inc
        xba
        iny
        cpy     $10
        bne     @00c6
        xba
        inc3
        bne     @00e2
        inc
@00e2:  inx2
        cpx     #$000c
        beq     @0106
        xba
        lda     f:_c40014,x
        sta     hAPUIO2
        lda     f:_c40014+1,x
        sta     hAPUIO3
        xba
        sta     hAPUIO1
        sta     hAPUIO0
@00ff:  cmp     hAPUIO0
        bne     @00ff
        bra     @00a1
@0106:  ldy     #$0200
        sty     hAPUIO2
        xba
        lda     #$00
        sta     hAPUIO1
        xba
        sta     hAPUIO0
@0116:  cmp     hAPUIO0
        bne     @0116
        xba
        sta     hAPUIO0
        ldx     #$0100
@0122:  sta     $1cff,x
        dex
        bne     @0122
        lda     #$ff
        sta     $05
        longa
        lda     f:SfxBRR
        clc
        adc     #$4800
        sta     $f8
        sta     $48
        ldx     #$0800
@013d:  dex
        bne     @013d
        shorta
        lda     #$00
        sta     $fa
        lda     #$c4
        sta     $fb
        bra     _017d

; ---------------------------------------------------------------------------

; [ spc command ]

ExecSound:
_014c:  phb
        phd
        php
        longa
        longi
        pha
        phx
        phy
        shorta
        lda     #$00
        pha
        plb
        ldx     #$1d00
        phx
        pld
_0161:  shorta
        lda     $00
        stz     $00
        beq     _017d       ; no interrupt ($00)
        bmi     @0177
        cmp     #$01
        beq     _0188       ; play song ($01)
        cmp     #$03
        beq     _0188       ; suspend current song and play song ($03)
        cmp     #$70
        bcs     @017a       ; interrupts $70-$7F
@0177:  jmp     _0589       ; other interrupts
@017a:  jmp     _05c9

; ---------------------------------------------------------------------------

; [ common return code ]

_017d:  longa
        longi
        ply
        plx
        pla
        plp
        pld
        plb
        rtl

; ---------------------------------------------------------------------------

; [ play song ]

_0188:  shorta
        xba
        lda     $01
        cmp     $05
        bne     @01d4
        ldx     $02
        stx     $06
        txa
        and     #$0f
        sta     hAPUIO1
        lda     #$84
@019d:  cmp     hAPUIO0
        beq     @019d
        sta     hAPUIO0
@01a5:  cmp     hAPUIO0
        bne     @01a5
        lda     #$00
        sta     hAPUIO0
        xba
        txa
        and     #$f0
        sta     $02
        lda     $03
        and     #$0f
        ora     $02
        sta     hAPUIO1
        lda     #$81
@01c0:  cmp     hAPUIO0
        beq     @01c0
        sta     hAPUIO0
@01c8:  cmp     hAPUIO0
        bne     @01c8
        xba
        sta     hAPUIO0
        jmp     _017d
@01d4:  jsr     _05e0
        lda     $05
        bmi     @01e1
        sta     $09
        ldx     $06
        stx     $0a
@01e1:  lda     $01
        sta     hAPUIO1
        sta     $05
        ldx     $02
        stx     hAPUIO2
        stx     $06
        xba
@01f0:  cmp     hAPUIO0
        beq     @01f0
        sta     hAPUIO0
@01f8:  cmp     hAPUIO0
        bne     @01f8
        lda     #$02        ; transfer mode 2 (two bytes at a time)
        sta     hAPUIO1
        ldx     #$1c00
        stx     hAPUIO2
        sta     hAPUIO0
@020b:  cmp     hAPUIO0
        bne     @020b
        longa
        lda     $05
        and     #$00ff
        pha
        asl
        sta     $e8
        pla
        clc
        adc     $e8
        tax
        shorta
        lda     f:SongScriptPtrs,x
        sta     $14
        lda     f:SongScriptPtrs+1,x
        sta     $15
        lda     f:SongScriptPtrs+2,x
        sta     $16
        ldy     $14
        stz     $14
        stz     $15
        lda     [$14],y
        xba
        iny
        bne     @0242
        inc     $16
@0242:  lda     [$14],y
        pha
        iny
        bne     @024a
        inc     $16
@024a:  xba
        pha
        plx
        lda     #$05
        xba
@0250:  lda     [$14],y
        sta     hAPUIO2
        iny
        bne     @025a
        inc     $16
@025a:  lda     [$14],y
        sta     hAPUIO3
        iny
        bne     @0264
        inc     $16
@0264:  xba
        sta     hAPUIO0
@0268:  cmp     hAPUIO0
        bne     @0268
        inc
        bne     @0271
        inc
@0271:  xba
        dex2
        bpl     @0250
        longa
        ldx     #$0000
@027b:  stz     $88,x
        stz     $c8,x
        inx2
        cpx     #$0020
        bne     @027b
        lda     $04
        and     #$ff00
        lsr3
        tax
        clc
        adc     #$0020
        sta     $12
        lda     #$1da8
        sta     $14
        lda     #$1dc8
        sta     $16
@029f:  lda     f:SongSamples,x
        sta     ($14)
        inc     $14
        inc     $14
        ldy     #$0000
@02ac:  cmp     $1d28,y
        beq     @02c0
        iny2
        cpy     #$0020
        bne     @02ac
        sta     ($16)
        inc     $16
        inc     $16
        bra     @02c3
@02c0:  sta     $1d88,y
@02c3:  inx2
        cpx     $12
        bne     @029f
        lda     $c8
        jeq     @04ac
        stz     $17
        shorta
        ldx     #$0000
@02d7:  lda     $c8,x
        beq     @031c
        phx
        dec
        longa
        and     #$00ff
        pha
        asl
        sta     $e8
        pla
        clc
        adc     $e8
        tax
        shorta
        lda     f:SampleBRRPtrs,x
        sta     $14
        lda     f:SampleBRRPtrs+1,x
        sta     $15
        lda     f:SampleBRRPtrs+2,x
        sta     $16
        ldy     $14
        stz     $14
        stz     $15
        lda     [$14],y
        clc
        adc     $17
        sta     $17
        iny
        bne     @0311
        inc     $16
@0311:  lda     [$14],y
        adc     $18
        sta     $18
        plx
        inx2
        bra     @02d7
@031c:  ldx     #$0000
        longa
@0321:  lda     $28,x
        beq     @0329
        inx2
        bra     @0321
@0329:  lda     $48,x
        clc
        adc     $17
        bcs     @0338
        cmp     #$d200
        jcc     @03ea
@0338:  ldx     #$001e
@033b:  lda     $86,x
        bne     @0343
        dex2
        bne     @033b
@0343:  stx     $24
        ldx     #$0000
@0348:  lda     $88,x
        beq     @0353
        inx2
        cpx     #$0020
        bne     @0348
@0353:  cpx     $24
        bne     @0363
@0357:  stz     $28,x
        inx2
        cpx     #$0020
        bne     @0357
        jmp     @03ea
@0363:  shorta
        lda     #$07        ; transfer mode 7 (move chunk)
        sta     hAPUIO1
        stz     $10
        ldy     #$0000
        longa
@0371:  lda     $1d88,y
        beq     @037e
@0376:  iny2
        cpy     $24
        bne     @0371
        bra     @03e0
@037e:  tyx
        bra     @0385
@0381:  lda     $88,x
        bne     @038d
@0385:  inx2
        cpx     $24
        bne     @0381
        bra     @03e0
@038d:  stz     $28,x
        stz     $88,x
        sta     $1d28,y
        lda     $48,x
        sta     hAPUIO2
        shorta
        lda     $10
        sta     hAPUIO0
@03a0:  cmp     hAPUIO0
        bne     @03a0
        inc     $10
        longa
        lda     $1d48,y
        sta     hAPUIO2
        shorta
        lda     $10
        sta     hAPUIO0
@03b6:  cmp     hAPUIO0
        bne     @03b6
        inc     $10
        longa
        lda     $68,x
        sta     hAPUIO2
        sta     $1d68,y
        clc
        adc     $1d48,y
        sta     $1d4a,y
        shorta
        lda     $10
        sta     hAPUIO0
@03d5:  cmp     hAPUIO0
        bne     @03d5
        inc     $10
        longa
        bra     @0376
@03e0:  tyx
@03e1:  stz     $28,x
        inx2
        cpx     #$0020
        bne     @03e1
@03ea:  shorta
        lda     #$03        ; transfer mode 3 (three bytes at a time)
        sta     hAPUIO1
        ldx     #$0000
@03f4:  lda     $28,x
        beq     @03fc
        inx2
        bra     @03f4
@03fc:  stx     $24
        lda     $48,x
        sta     hAPUIO2
        lda     $49,x
        sta     hAPUIO3
        lda     #$00
        sta     hAPUIO0
@040d:  cmp     hAPUIO0
        bne     @040d
        inc
        sta     $10
        ldx     #$0000
@0418:  shorta
        lda     $c8,x
        jeq     @04ac
        ldy     $24
        sta     $1d28,y
        phx
        dec
        longa
        and     #$00ff
        pha
        asl
        sta     $e8
        pla
        clc
        adc     $e8
        tax
        shorta
        lda     f:SampleBRRPtrs,x
        sta     $14
        lda     f:SampleBRRPtrs+1,x
        sta     $15
        lda     f:SampleBRRPtrs+2,x
        sta     $16
        ldy     $14
        stz     $14
        stz     $15
        lda     [$14],y
        xba
        iny
        bne     @0458
        inc     $16
@0458:  lda     [$14],y
        iny
        bne     @045f
        inc     $16
@045f:  xba
        longa
        pha
        ldx     $24
        sta     $68,x
        clc
        adc     $48,x
        sta     $4a,x
        inx2
        stx     $24
        plx
        shorta
@0473:  lda     [$14],y     ; first byte
        sta     hAPUIO1
        iny
        bne     @047d
        inc     $16
@047d:  lda     [$14],y     ; second byte
        sta     hAPUIO2
        iny
        bne     @0487
        inc     $16
@0487:  lda     [$14],y     ; third byte
        sta     hAPUIO3
        iny
        bne     @0491
        inc     $16
@0491:  lda     $10
        sta     hAPUIO0
@0496:  cmp     hAPUIO0       ; wait for spc
        bne     @0496
        inc     $10
        bne     @04a1
        inc     $10
@04a1:  dex3
        bne     @0473
        plx
        inx2
        brl     @0418
@04ac:  longa
        lda     $a8
        jeq     @057c
        lda     #$1da8
        sta     $14
        lda     #$1e00
        sta     $16
        lda     #$1e40
        sta     $18
        lda     #$1ec0
        sta     $1a
@04c9:  lda     ($14)
        beq     @050a
        inc     $14
        inc     $14
        ldy     #$0000
@04d4:  cmp     $1d28,y
        beq     @04dd
        iny2
        bra     @04d4
@04dd:  dec
        asl
        tax
        lda     f:SampleFreqMult,x   ; sample loop pointers ???
        sta     ($16)
        inc     $16
        inc     $16
        lda     $1d48,y
        sta     ($18)
        inc     $18
        inc     $18
        clc
        adc     f:SampleLoopStart,x   ; sample pitch multipliers
        sta     ($18)
        inc     $18
        inc     $18
        lda     f:SampleADSR,x   ; sample adsr values
        sta     ($1a)
        inc     $1a
        inc     $1a
        bra     @04c9
@050a:  shorta
        lda     #$02
        sta     hAPUIO1
        ldx     #$1e00
        phx
        pld
        ldx     #$1a40
        stx     hAPUIO2
        lda     #$00
        ldx     #$fffe
        bra     @0528
@0523:  ldy     $00,x
        sty     hAPUIO2
@0528:  sta     hAPUIO0
@052b:  cmp     hAPUIO0
        bne     @052b
        inc
        inx2
        cpx     #$0040
        bne     @0523
        ldx     #$1b80
        stx     hAPUIO2
        lda     #$00
        ldx     #$fffe
        bra     @054a
@0545:  ldy     $40,x
        sty     hAPUIO2
@054a:  sta     hAPUIO0
@054d:  cmp     hAPUIO0
        bne     @054d
        inc
        inx2
        cpx     #$0080
        bne     @0545
        ldx     #$1ac0
        stx     hAPUIO2
        lda     #$00
        ldx     #$fffe
        bra     @056c
@0567:  ldy     $c0,x
        sty     hAPUIO2
@056c:  sta     hAPUIO0
@056f:  cmp     hAPUIO0
        bne     @056f
        inc
        inx2
        cpx     #$0040
        bne     @0567
@057c:  shorta
        lda     #$00
        sta     hAPUIO1
        sta     hAPUIO0
        jmp     _017d

; ---------------------------------------------------------------------------

; [ other interrupts ]

_0589:  shorta
        xba
        lda     $03
        sta     hAPUIO3
        lda     $02
        sta     hAPUIO2
        lda     $01
        sta     hAPUIO1
        xba
@059c:  cmp     hAPUIO0
        beq     @059c
        sta     hAPUIO0
        cmp     #$f0        ; branch if not a "stop music" interrupt
        bcc     @05bc
        cmp     #$f2
        bcs     @05bc
        xba
        lda     $05
        bmi     @05b7       ; branch if no previous song
        sta     $09
        ldx     $06
        stx     $0a
@05b7:  lda     #$ff
        sta     $05
        xba
@05bc:  cmp     hAPUIO0
        bne     @05bc
        lda     #$00        ; no interrupt
        sta     hAPUIO0
        jmp     _017d

; ---------------------------------------------------------------------------

; [ interrupts $70-$7F ]

_05c9:  longa
        and     #$000f
        asl2
        tax
        lda     f:_c40601+2,x
        sta     $02
        lda     f:_c40601,x
        sta     $00
        jmp     _0161

; ---------------------------------------------------------------------------

; [ check if song needs to be suspended ]

_05e0:  php
        shorta
        xba
        cmp     #$03
        beq     @05fe
        ldx     #$0000
@05eb:  lda     f:_c40641,x   ; songs to suspend the previous song
        bmi     @05fc
        cmp     $01
        beq     @05f8
        inx
        bra     @05eb
@05f8:  lda     #$03
        bra     @05fe
@05fc:  lda     #$01
@05fe:  xba
        plp
        rts

; ---------------------------------------------------------------------------

; [ interrupts $70-$7F ]

_c40601:
        .byte   $01,$0e,$08,$0f   ; $70: play song $0e (victory fanfare)
        .byte   $01,$2b,$08,$0f   ; $71: play song $2b (the battle)
        .byte   $01,$01,$08,$0f   ; $72: play song $01 (the fierce battle)
        .byte   $01,$09,$08,$0f   ; $73: play song $09 (the last battle)
        .byte   $01,$22,$08,$0f   ; $74: play song $22 (gilgamesh)
        .byte   $01,$0a,$08,$0f   ; $75: play song $0a (requiem)
        .byte   $01,$2d,$08,$0f   ; $76: play song $2d (the evil lord, exdeath)
        .byte   $01,$40,$08,$0f   ; $77: play song $40 (the decisive battle)
        .byte   $01,$07,$08,$0f   ; $78: play song $07 (critter tripper fritter!)
        .byte   $01,$3e,$08,$0f   ; $79: play song $3e (a meteor is falling)
        .byte   $01,$00,$08,$0f   ; $7a: play song $00 (ahead on our way)
        .byte   $01,$00,$08,$0f   ; $7b: play song $00
        .byte   $01,$00,$08,$0f   ; $7c: play song $00
        .byte   $01,$00,$08,$0f   ; $7d: play song $00
        .byte   $01,$00,$08,$0f   ; $7e: play song $00
        .byte   $80,$10,$00,$00   ; $7f: fade out sound

; ---------------------------------------------------------------------------

; [ songs to suspend the previous song ]

_c40641:
        .byte   SONG::THE_BATTLE
        .byte   SONG::GOOD_NIGHT
        .byte   SONG::IM_A_DANCER
        .byte   SONG::PIANO_LESSON_1
        .byte   SONG::PIANO_LESSON_2
        .byte   SONG::PIANO_LESSON_3
        .byte   SONG::PIANO_LESSON_4
        .byte   SONG::PIANO_LESSON_5
        .byte   SONG::PIANO_LESSON_6
        .byte   SONG::PIANO_LESSON_7
        .byte   SONG::PIANO_LESSON_8
        .byte   $ff                     ; end of list terminator

; ---------------------------------------------------------------------------

; c4/064d
SPCCode:
        ; spc_block
        .incbin "ff5_spc.dat"
        ; end_spc_block

; ---------------------------------------------------------------------------

.include "sfx-data.asm"
.include "song-data.asm"

; ---------------------------------------------------------------------------
