; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: cutscene/cutscene-main.asm                                        |
; |                                                                         |
; | description: code for decompression and loading cinematics              |
; +-------------------------------------------------------------------------+

.p816

.include "macros.inc"
.include "hardware.inc"
.include "const.inc"

.export ShowCutscene_ext, Decomp_ext

.import ExecSound_ext
.import RNGTbl, SmallFontGfx

; ---------------------------------------------------------------------------

.segment "cutscene_code"

; ---------------------------------------------------------------------------

; [ show cutscene ]

ShowCutscene_ext:
        bra     ShowCutscene

; ---------------------------------------------------------------------------

; [ decompress ]

Decomp_ext:
        php
        phb
        phd
        jsr     InitDecomp
        jsr     Decomp
        pld
        plb
        plp
        rtl

; ---------------------------------------------------------------------------

; [ show cutscene ]

; A: cutscene id

; c3/000f
ShowCutscene:
        .a8
        .i16
        pha
        jsr     InitDecomp
        sei
        lda     #$80
        sta     hINIDISP
        lda     #$00
        sta     hNMITIMEN
        lda     $c7
        sta     hHDMAEN
        lda     #^CutsceneProg
        sta     $d2
        ldx     #near CutsceneProg
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$8000                  ; 7f/8000
        stx     $d3
        jsr     Decomp
        pla
        jml     _7f8000

; ---------------------------------------------------------------------------

; [ init decompression ]

; c3/003d
InitDecomp:
        .a8
        .i16
        lda     #0
        pha
        plb
        longa
        lda     #$0420                  ; direct page is at $0420
        tcd
        shorta
        ldx     #0
        stx     $c7
        lda     #$ff
        sta     $c6
        rts

; ---------------------------------------------------------------------------

; [ decompress ]

; ++$04f0/$d0: source
; ++$04f3/$d3: destination

; c3/0053
Decomp:
@0053:  .a8
        .i16
        phb
        lda     #$7f
        pha
        plb
        lda     #$7f
        sta     $c9
        longa
        lda     #$07ff                  ; buffer mask
        sta     $de
        lda     $d0
        cmp     #$ffff
        bne     @008a
        shorta
        lda     [$d0]
        longa
        and     $c6
        sta     $ca
        inc     $d0
        shorta
        inc     $d2
        lda     [$d0]
        longa
        and     $c6
        xba
        ora     $ca
        dec
        sta     $ca
        inc     $d0
        bra     @00a3
@008a:  lda     [$d0]                   ; data length
        dec
        sta     $ca
        inc     $d0
        bne     @0099
        shorta
        inc     $d2
        longa
@0099:  inc     $d0
        bne     @00a3
        shorta
        inc     $d2
        longa
@00a3:  ldx     #$07de
        stx     $cc                     ; set buffer pointer
        ldx     $c7
        txa
        tay
@00ac:  sta     $f7ff,x                 ; clear buffer
        inx2
        cpx     $cc
        bne     @00ac
        stz     $ce
@00b7:  lsr     $ce
        lda     $ce
        and     #$0080
        bne     @00d6                   ; branch if still working on a chunk
        shorta
        lda     [$d0]                   ; header byte
        longa
        inc     $d0
        bne     @00d0
        shorta
        inc     $d2
        longa
@00d0:  and     $c6
        ora     $c8
        sta     $ce                     ; header byte
@00d6:  lda     $ce
        and     #1
        beq     @010b                   ; branch if compressed
        shorta
        lda     [$d0]                   ; data byte
        longa
        inc     $d0
        bne     @00ed
        shorta
        inc     $d2
        longa
@00ed:  shorta
        sta     [$d3],y                 ; copy to destination
        longa
        cpy     $ca
        bne     @00fd
@00f7:  lda     $c7                     ; end of data
        shorta
        plb
        rts
@00fd:  iny
        ldx     $cc
        sta     $f7ff,x                 ; copy to buffer
        txa
        inc
        and     $de                     ; buffer mask
        sta     $cc
        bra     @00b7
@010b:  shorta
        lda     [$d0]                   ; first byte
        xba
        longa
        inc     $d0
        bne     @011a
        shorta
        inc     $d2
@011a:  shorta
        lda     [$d0]                   ; second byte
        sta     $da
        lsr5
        xba
        longa
        sta     $d8
        lda     $da
        and     #$001f
        inc3
        sta     $da                     ; string length
        stz     $dc                     ; clear byte counter
        inc     $d0
        bne     @0140
        shorta
        inc     $d2
        longa
@0140:  lda     $dc                     ; byte counter
        cmp     $da
        beq     @016d                   ; branch when counter reaches the string length
        lda     $d8
        clc
        adc     $dc
        and     $de                     ; buffer mask
        tax
        shorta
        lda     $f7ff,x
        sta     [$d3],y                 ; copy to destination
        longa
        cpy     $ca
        beq     @00f7
        iny
        ldx     $cc

; *** bug ***
; the accumulator is 16-bit here so this overwrites the next byte in the buffer
; with whatever was in the upper 8 bits of the accumulator. This will corrupt
; the output if the lzss buffer offset is exactly $0800 bytes behind the
; destination offset.

.if BUGFIX_DECOMP
        shorta
        sta     $f7ff,x                 ; copy to buffer
        longa
.else
        sta     $f7ff,x                 ; copy to buffer
.endif
        inc     $cc
        lda     $cc
        and     $de
        sta     $cc
        inc     $dc
        bra     @0140
@016d:  brl     @00b7

; ------------------------------------------------------------------------------

.segment "cutscene_data"

; c3/0200
_c30200:
        .incbin "unknown_c30200.dat.cmp"

; c3/02b3
_c302b3:
        .incbin "unknown_c302b3.dat.cmp"

; c3/0368
_c30368:
        .incbin "unknown_c30368.dat.cmp"

; c3/05f9
_c305f9:
        .incbin "unknown_c305f9.dat.cmp"

; c3/05fd
_c305fd:
        .incbin "unknown_c305fd.dat.cmp"

; c3/0663
_c30663:
        .incbin "unknown_c30663.dat.cmp"

; c3/067c
_c3067c:
        .incbin "unknown_c3067c.dat.cmp"

; c3/06f5
_c306f5:
        .incbin "unknown_c306f5.dat.cmp"

; c3/09d2
_c309d2:
        .incbin "unknown_c309d2.dat.cmp"

; c3/0d89
_c30d89:
        .incbin "unknown_c30d89.dat.cmp"

; c3/0da3
_c30da3:
        .incbin "unknown_c30da3.dat.cmp"

; c3/0e1b
_c30e1b:
        .incbin "unknown_c30e1b.dat.cmp"

; c3/0e70
_c30e70:
        .incbin "unknown_c30e70.dat.cmp"

; c3/0f4a
_c30f4a:
        .incbin "unknown_c30f4a.dat.cmp"

; c3/0f70
_c30f70:
        .incbin "unknown_c30f70.dat.cmp"

; c3/1177
_c31177:
        .incbin "unknown_c31177.dat.cmp"

; c3/1243
_c31243:
        .incbin "unknown_c31243.dat.cmp"

; c3/1c65
_c31c65:
        .incbin "unknown_c31c65.dat.cmp"

; c3/1c69
_c31c69:
        .incbin "unknown_c31c69.dat.cmp"

; c3/1d25
_c31d25:
        .incbin "unknown_c31d25.dat.cmp"

; c3/1d48
_c31d48:
        .incbin "unknown_c31d48.dat.cmp"

; c3/1dfe
_c31dfe:
        .incbin "unknown_c31dfe.dat.cmp"

; c3/1e83
_c31e83:
        .incbin "unknown_c31e83.dat.cmp"

; c3/2d22
_c32d22:
        .incbin "unknown_c32d22.dat.cmp"

; c3/331f
_c3331f:
        .incbin "unknown_c3331f.dat.cmp"

; c3/3342
_c33342:
        .incbin "unknown_c33342.dat.cmp"

; c3/33f6
_c333f6:
        .incbin "unknown_c333f6.dat.cmp"

; c3/362b
_c3362b:
        .incbin "unknown_c3362b.dat.cmp"

; c3/383c
_c3383c:
        .incbin "unknown_c3383c.dat.cmp"

; c3/3909
_c33909:
        .incbin "unknown_c33909.dat.cmp"

; c3/4452
_c34452:
        .incbin "unknown_c34452.dat.cmp"

; c3/4469
_c34469:
        .incbin "unknown_c34469.dat.lz"

; c3/4df8
_c34df8:
        .incbin "unknown_c34df8.dat.cmp"

; c3/4e34
_c34e34:
        .incbin "unknown_c34e34.dat.lz"

; c3/50d4
_c350d4:
        .incbin "unknown_c350d4.dat.lz"

; c3/51ef
_c351ef:
        .incbin "unknown_c351ef.dat.lz"

; c3/5b1e
_c35b1e:
        .incbin "unknown_c35b1e.dat.cmp"

; c3/66d8
_c366d8:
        .incbin "unknown_c366d8.dat.cmp"

; c3/72e7
_c372e7:
        .incbin "unknown_c372e7.dat.cmp"

; c3/7445
_c37445:
        .incbin "unknown_c37445.dat.cmp"

; c3/750d
_c3750d:
        .incbin "unknown_c3750d.dat.cmp"

; c3/759a
_c3759a:
        .incbin "unknown_c3759a.dat.cmp"

; c3/765c
_c3765c:
        .incbin "unknown_c3765c.dat.cmp"

; c3/77ae
_c377ae:
        .incbin "unknown_c377ae.dat.cmp"

; c3/7891
_c37891:
        .incbin "unknown_c37891.dat.cmp"

; c3/7a07
_c37a07:
        .incbin "unknown_c37a07.dat.cmp"

; c3/7a69
_c37a69:
        .incbin "unknown_c37a69.dat.cmp"

; c3/7b92
_c37b92:
        .incbin "unknown_c37b92.dat.cmp"

; ------------------------------------------------------------------------------

.segment "cutscene_code_lz"

; c3/7e4d
CutsceneProg:

; lz-compressed cutscene code will be inserted here during the 2nd linker pass

; ------------------------------------------------------------------------------

.segment "cutscene_wram"

        fixed_block $4500

; ------------------------------------------------------------------------------

_7f8000:
        pha
        jsr     _7f95d9
        pla
        sta     $0420
        longa
        and     #$000f
        asl
        tax
        shorta
        phk
        plb
        jsr     (near _7f801a,x)
        jsr     _7f95ec
        rtl

; cutscene jump table
_7f801a:
        .addr _7f8c78,_7f804b,_7f8516,_7f8784,_7f8516,_7f867d,_7f8516,_7f8aa2
        .addr _7f8c09,_7f8b80,_7f8888,_7f8963,_7f804a,_7f804a,_7f804a,_7f804a

; ------------------------------------------------------------------------------

_7f803a:
@803a:  sei
        lda     #$80
        sta     hINIDISP
        lda     #$00
        sta     hNMITIMEN
        lda     $c7
        sta     hHDMAEN

_7f804a:
        rts

; ------------------------------------------------------------------------------

; [ cutscene $01: title/credits ]

_7f804b:
@804b:  jsr     _7f94a5
        jsr     _7f9465
        jsr     _7faff3
        jsr     _7f963a
        jsr     _7fa963
        jsr     _7f983b
        jsr     _7fb21d
        jsr     _7fb5a9
        jsr     _7f970e
        jsr     _7fc209
        ldx     #$0200
        stx     $30
        ldx     #$0180
        stx     $32
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$02
        sta     $72
        ldx     #$0300
        stx     $66
        ldx     #$0010
        stx     $62
        ldx     #$00ae
        stx     $60
        ldx     #$0020
        stx     $64
        jsr     _7fa570
        ldx     #$8000
        stx     $58
        ldx     #$8000
        stx     $5c
        ldx     #$8000
        stx     $5e
        lda     #$01
        sta     $4e
        stz     $45
        ldx     #$0001
        stx     $1d00
        ldx     #$0018
        stx     $1d02
        jsl     ExecSound_ext
        lda     #$10
        sta     $7ff101
        longa
        lda     #$e000
        sta     $7ff110
        lda     #$0020
        sta     $7ff120
        shorta
        lda     #$01
        sta     $74
        lda     #$01
        tsb     $4f
        lda     #$81
        sta     hNMITIMEN
        cli
        ldx     $c7
        stx     $42
        lda     #$80
        sta     $44
@80e9:  jsr     _7f945d
        jsr     _7f95a1
        bcc     @80f4
        brl     @81ba
@80f4:  jsr     _7fa811
        jsr     _7fa527
        jsr     _7fa554
        dec     $44
        bne     @80e9
        lda     #$e0
        sta     $7ff105
        lda     #$c0
        sta     $7ff107
        longa
        lda     #$ebe0
        sta     $7ff114
        lda     #$0020
        sta     $7ff124
        lda     #$efe0
        sta     $7ff116
        lda     #$0020
        sta     $7ff126
        shorta
        lda     #$04
        ora     #$08
        tsb     $74
        lda     #$20
        sta     $44
@8137:  jsr     _7f945d
        jsr     _7f95a1
        bcc     @8142
        brl     @81ba
@8142:  jsr     _7fa811
        jsr     _7fa527
        jsr     _7fb6c5
        lda     $44
        and     #$03
        bne     @815b
        lda     #$02
        jsr     _7fae01
        lda     #$03
        jsr     _7fae01
@815b:  jsr     _7fa554
        dec     $44
        bne     @8137
        lda     #$d0
        sta     $44
@8166:  jsr     _7f945d
        jsr     _7f95a1
        bcc     @8171
        brl     @81ba
@8171:  jsr     _7fa811
        jsr     _7fa527
        lda     $44
        and     #$03
        bne     @8187
        lda     #$02
        jsr     _7fae01
        lda     #$03
        jsr     _7fae01
@8187:  jsr     _7fa554
        dec     $44
        bne     @8166
        ldx     #$0005
        stx     $48
@8193:  jsr     _7f945d
        jsr     _7fa811
        jsr     _7fa554
        dec     $44
        bne     @81a7
        ldx     $48
        dex
        beq     @81f6
        stx     $48
@81a7:  lda     $43
        bne     @81b1
        lda     $42
        bne     @81b1
        bra     @8193
@81b1:  jsr     _7f95ab
        bcs     @81ba
        inc     $4b
        bra     @81f6
@81ba:  lda     #$f0
        sta     $44
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$04
        sta     $72
@81cc:  jsr     _7f945d
        jsr     _7fa811
        jsr     _7fa554
        lda     $71
        bne     @81cc
        jsr     _7f803a
        lda     #$f0
        sta     $1d00
        jsl     ExecSound_ext
        ldx     #$0001
        stx     $1d00
        ldx     #$0418
        stx     $1d02
        jsl     ExecSound_ext
        rts
@81f6:  lda     #$f0
        sta     $1d00
        jsl     ExecSound_ext
        ldx     #$0001
        stx     $1d00
        ldx     #$0f08
        stx     $1d02
        jsl     ExecSound_ext
        lda     #$40
        sta     $44
        ldx     $c7
        stx     $68
@8217:  jsr     _7f945d
        jsr     _7fa8c6
        jsr     _7fa50e
        jsr     _7fa562
        lda     #$02
        jsr     _7fae37
        lda     #$03
        jsr     _7fae37
        dec     $44
        bne     @8217
        jsr     _7fafc1
        jsr     _7f945d
        lda     #$01
        trb     $4f
        lda     #$10
        sta     $7ff103
        longa
        lda     #$e400
        sta     $7ff112
        lda     #$0020
        sta     $7ff122
        shorta
        lda     #$01
        trb     $74
        lda     #$02
        tsb     $74
        lda     #$20
        sta     $44
@825f:  jsr     _7f945d
        lda     #$01
        jsr     _7fae37
        dec     $44
        bne     @825f
        lda     #$11
        sta     $3b
        jsr     _7fbb79
        jsr     _7f945d
        jsr     _7fa797
        lda     #$02
        trb     $74
        jsr     _7f945d
        jsr     _7fbbb0
        jsr     _7f945d
        jsr     _7fbbca
        jsr     _7f945d
        jsr     _7fbbe4
        jsr     _7f945d
        lda     #<hVMDATAH
        sta     $b4
        lda     #$00
        sta     $b3
        ldx     $c7
        stx     $ac
        ldx     #$0000
        stx     $ae
        lda     #$7f
        sta     $b0
        ldx     #$1000
        stx     $b1
        lda     #$02
        tsb     $4f
        jsr     _7f945d
        lda     #<hVMDATAH
        sta     $b4
        ldx     #$1000
        stx     $ac
        ldx     #$1000
        stx     $ae
        lda     #$7f
        sta     $b0
        ldx     #$1000
        stx     $b1
        lda     #$02
        tsb     $4f
        jsr     _7f945d
        lda     #$02
        trb     $4f
        lda     #$01
        tsb     $4f
        ldx     #$0280
        stx     $34
        ldx     #$02a0
        stx     $36
        stz     $40
        jsr     _7fb3fa
        lda     #$a0
        sta     $44
        stz     $46
@82ed:  jsr     _7f945d
        jsr     _7fa538
        jsr     _7fb5eb
        dec     $44
        bne     @82ed
        jsr     _7f945d
        jsr     _7fb5eb
        jsr     _7fa244
        jsr     _7f945d
        jsr     _7fb5eb
        jsr     _7fbe34
        lda     #$48
        sta     $44
        stz     $46
@8312:  jsr     _7f945d
        jsr     _7fb5eb
        dec     $44
        bne     @8312
        stz     $46
        inc     $21
        stz     $42
        stz     $43
@8324:  jsr     _7f945d
        jsr     _7fb667
        jsr     _7fbe85
        dec     $44
        lda     $43
        bne     @833b
        lda     $42
        bne     @833b
        lda     $21
        bne     @8324
@833b:  jsr     _7fc1f4
        jsr     _7fbf3b
        lda     #$50
        sta     $44
        stz     $45
        stz     $46
@8349:  jsr     _7f945d
        jsr     _7fb629
        lda     #$04
        jsr     _7fae37
        lda     #$05
        jsr     _7fae37
        dec     $44
        beq     @8361
        lda     $4e
        bne     @8349
@8361:  jsr     _7fa3a0
        lda     #$30
        sta     $44
        stz     $45
        stz     $46
@836c:  jsr     _7f945d
        jsr     _7fb629
        jsr     _7fbf1b
        jsr     _7f8434
        jsr     _7f9aa8
        jsr     _7f9af2
        inc     $45
        dec     $44
        beq     @8388
        lda     $4e
        bne     @836c
@8388:  jsr     _7fafc1
        jsr     _7f8434
        jsr     _7f9aa8
        jsr     _7f9af2
        jsr     _7f945d
        jsr     _7f8434
        jsr     _7f9aa8
        jsr     _7f9af2
        lda     #$30
        sta     $44
@83a4:  jsr     _7f945d
        jsr     _7f8434
        jsr     _7f9aa8
        jsr     _7f9af2
        inc     $45
        dec     $44
        beq     @83ba
        lda     $4e
        bne     @83a4
@83ba:  lda     #$50
        sta     $44
        stz     $45
@83c0:  jsr     _7f945d
        jsr     _7f846f
        jsr     _7f9aa8
        jsr     _7f9af2
        inc     $45
        dec     $44
        beq     @83d6
        lda     $4e
        bne     @83c0
@83d6:  lda     #$60
        sta     $44
        stz     $45
        lda     $21
        beq     @83ec
@83e0:  ldx     #$4481
        stx     $1d00
        jsl     ExecSound_ext
        bra     @83fa
@83ec:  lda     $4b
        bne     @83e0
        ldx     #$4081
        stx     $1d00
        jsl     ExecSound_ext
@83fa:  lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$04
        sta     $72
@8408:  jsr     _7f945d
        jsr     _7f8498
        jsr     _7f9aa8
        jsr     _7f9af2
        inc     $45
        dec     $44
        beq     @841e
        lda     $4e
        bne     @8408
@841e:  jsr     _7f945d
        lda     $71
        bne     @841e
        jsr     _7f803a
        lda     $21
        bne     @8433
        lda     $4b
        bne     @8433
        brl     @804b
@8433:  rts

; ------------------------------------------------------------------------------

_7f8434:
@8434:  lda     $45
        cmp     #$02
        bne     @8443
        jsr     _7f9a8f
        jsr     _7f9a1e
        brl     _7f9a81
@8443:  cmp     #$04
        bne     @8459
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a39
        brl     _7f9a57
@8459:  cmp     #$06
        bne     @846e
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9abd
        stz     $45
        jsr     _7f9a1e
        brl     _7f9a81
@846e:  rts

; ------------------------------------------------------------------------------

_7f846f:
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     $45
        cmp     #$02
        bne     @847e
        brl     _7f9a8f
@847e:  cmp     #$04
        bne     @8488
        jsr     _7f9a8f
        brl     _7f9abd
@8488:  cmp     #$06
        bne     @8497
        stz     $45
        jsr     _7f9a8f
        jsr     _7f9aa8
        brl     _7f9abd
@8497:  rts

; ------------------------------------------------------------------------------

_7f8498:
        lda     $45
        cmp     #$02
        bne     @84a1
        brl     _7f9a8f
@84a1:  cmp     #$04
        bne     @84ab
        jsr     _7f9a8f
        brl     _7f9abd
@84ab:  cmp     #$06
        bne     @84ba
        stz     $45
        jsr     _7f9a8f
        jsr     _7f9aa8
        brl     _7f9abd
@84ba:  rts

; ------------------------------------------------------------------------------

_7f84bb:
@84bb:  jsr     _7f94a5
        jsr     _7f9465
        jsr     _7f9679
        jsr     _7faff9
        jsr     _7faafc
        jsr     _7f9753
        jsr     _7f988a
        jsr     _7fb273
        jsr     _7fb47e
        jsr     _7fc1f4
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$04
        sta     $72
        ldx     #$ff00
        stx     $58
        ldx     #$8000
        stx     $5c
        ldx     #$8000
        stx     $5e
        ldx     #$0190
        stx     $30
        ldx     #$01a8
        stx     $32
        ldx     #$0210
        stx     $34
        ldx     #$0218
        stx     $36
        jsr     _7f9af2
        lda     #$01
        tsb     $4f
        lda     #$81
        sta     hNMITIMEN
        cli
        rts

; ------------------------------------------------------------------------------

; [ cutscene $02, $04, $06: falling meteor ]

_7f8516:
        jsr     _7f84bb
        lda     #$40
        sta     $44
@851d:  jsr     _7f945d
        jsr     _7fb846
        jsr     _7f9a8f
        jsr     _7f9a8f
        jsr     _7f9ae4
        jsr     _7f9af2
        lda     $00
        cmp     #$f4
        bne     @853b
        jsr     _7faf81
        jsr     _7f9ae4
@853b:  lda     $00
        cmp     #$f6
        bne     @8547
        jsr     _7f9ae4
        jsr     _7f9ae4
@8547:  dec     $44
        bne     @851d
        lda     #$30
        sta     $44
@854f:  jsr     _7f945d
        jsr     _7fb846
        jsr     _7f9a8f
        jsr     _7f9a8f
        jsr     _7f9ae4
        jsr     _7f9abd
        jsr     _7f9aa8
        jsr     _7f9af2
        lda     $00
        cmp     #$f4
        bne     @8573
        jsr     _7faf81
        jsr     _7f9ae4
@8573:  lda     $00
        cmp     #$f6
        bne     @857f
        jsr     _7f9ae4
        jsr     _7f9ae4
@857f:  dec     $44
        bne     @854f
        lda     $00
        cmp     #$f6
        bne     @8597
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8597:  lda     #$10
        sta     $44
@859b:  jsr     _7f945d
        jsr     _7fb846
        jsr     _7f9a8f
        jsr     _7f9a8f
        jsr     _7f9ae4
        jsr     _7f9abd
        jsr     _7f9aa8
        jsr     _7f9af2
        lda     $00
        cmp     #$f4
        bne     @85c1
        jsr     _7faf81
        jsr     _7f9ae4
        bra     @85d2
@85c1:  cmp     #$f6
        bne     @85d2
        jsr     _7f9ae4
        jsr     _7f9ae4
        lda     $71
        bne     @859b
        brl     _7f803a
@85d2:  dec     $44
        bne     @859b
        ldx     #$002d
@85d9:  jsr     _7f9ae4
        dex
        bne     @85d9
        jsr     _7fafc1
        lda     #$40
        sta     $44
@85e6:  jsr     _7f945d
        jsr     _7f9a98
        jsr     _7f9a98
        jsr     _7f9ac9
        jsr     _7f9ab1
        jsr     _7f9aa1
        jsr     _7f9af2
        lda     $00
        cmp     #$f4
        bne     @8607
        jsr     _7faf81
        jsr     _7f9ac9
@8607:  dec     $44
        bne     @85e6
        lda     #$30
        sta     $44
@860f:  jsr     _7f945d
        jsr     _7f9a98
        jsr     _7f9a98
        jsr     _7f9ac9
        jsr     _7f9af2
        lda     $00
        cmp     #$f4
        bne     @862a
        jsr     _7faf81
        jsr     _7f9ac9
@862a:  dec     $44
        bne     @860f
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@863c:  jsr     _7f945d
        jsr     _7f9ac9
        jsr     _7f9a98
        jsr     _7f9a98
        jsr     _7f9af2
        lda     $00
        cmp     #$f4
        bne     @8657
        jsr     _7faf81
        jsr     _7f9ac9
@8657:  inc     $44
        lda     $71
        bne     @863c
        brl     _7f803a

; ------------------------------------------------------------------------------

_7f8660:
@8660:  jsr     _7f94a5
        jsr     _7f9465
        jsr     _7f96b8
        jsr     _7fc1f4
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$02
        sta     $72
        lda     #$01
        tsb     $4f
        rts

; ------------------------------------------------------------------------------

_7f867d:
        jsr     _7f8660
        ldx     #$ff00
        stx     $58
        ldx     #$8000
        stx     $5c
        ldx     #$8000
        stx     $5e
        ldx     #$00e8
        stx     $30
        ldx     #$0200
        stx     $32
        ldx     #$0168
        stx     $34
        ldx     #$0280
        stx     $36
        lda     #$81
        sta     hNMITIMEN
        cli
        lda     #$40
        sta     $44
@86ad:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @86b9
        jsr     _7f9a8f
@86b9:  jsr     _7f9af2
        dec     $44
        bne     @86ad
        lda     #$60
        sta     $44
@86c4:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @86d9
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9ac9
        jsr     _7f9ab1
@86d9:  jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9af2
        dec     $44
        bne     @86c4
        lda     #$60
        sta     $44
@86ea:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @86f9
        jsr     _7f9a8f
        jsr     _7f9ae4
@86f9:  jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9af2
        dec     $44
        bne     @86ea
        lda     #$60
        sta     $44
@8713:  jsr     _7f945d
        jsr     _7f9a8f
        lda     $44
        and     #$03
        bne     @8722
        jsr     _7f9ab1
@8722:  jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9af2
        dec     $44
        bne     @8713
        lda     #$20
        sta     $44
@8736:  jsr     _7f945d
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9af2
        dec     $44
        bne     @8736
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8760:  jsr     _7f945d
        jsr     _7f9a8f
        jsr     _7f9ab1
        jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9af2
        inc     $44
        lda     $71
        bne     @8760
        brl     _7f803a

; ------------------------------------------------------------------------------

; [ cutscene $03:  ]

_7f8784:
        jsr     _7f8660
        ldx     #$ff00
        stx     $58
        ldx     #$4000
        stx     $5c
        ldx     #$8000
        stx     $5e
        ldx     #$01b8
        stx     $30
        ldx     #$01b8
        stx     $32
        ldx     #$0238
        stx     $34
        ldx     #$0238
        stx     $36
        lda     #$81
        sta     hNMITIMEN
        cli
        lda     #$40
        sta     $44
@87b4:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @87c0
        jsr     _7f9a8f
@87c0:  jsr     _7f9af2
        dec     $44
        bne     @87b4
        lda     #$60
        sta     $44
@87cb:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @87dd
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9ae4
@87dd:  jsr     _7f9a39
        jsr     _7f9a57
        jsr     _7f9af2
        dec     $44
        bne     @87cb
        lda     #$60
        sta     $44
@87ee:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @87fd
        jsr     _7f9a8f
        jsr     _7f9ac9
@87fd:  jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a39
        jsr     _7f9a57
        jsr     _7f9af2
        dec     $44
        bne     @87ee
        lda     #$60
        sta     $44
@8817:  jsr     _7f945d
        jsr     _7f9a8f
        lda     $44
        and     #$03
        bne     @8826
        jsr     _7f9ab1
@8826:  jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9af2
        dec     $44
        bne     @8817
        lda     #$60
        sta     $44
@883a:  jsr     _7f945d
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9af2
        dec     $44
        bne     @883a
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8864:  jsr     _7f945d
        jsr     _7f9a8f
        jsr     _7f9ab1
        jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9af2
        inc     $44
        lda     $71
        bne     @8864
        brl     _7f803a

; ------------------------------------------------------------------------------

; [ cutscene $0a: flash red (short) ]

_7f8888:
        jsr     _7f8660
        jsr     _7fab7a
        lda     #$02
        sta     hCGSWSEL
        lda     #$70
        sta     hCGADSUB
        sta     $8e
        lda     #$01
        sta     hTS
        sta     $3a
        lda     #$10
        sta     hTM
        sta     $3b
        jsr     _7f9deb
        ldx     #$ff00
        stx     $58
        ldx     #$5400
        stx     $5c
        ldx     #$5400
        stx     $5e
        ldx     #$005a
        stx     $52
        ldx     #$0070
        stx     $30
        ldx     #$0260
        stx     $32
        ldx     #$00f0
        stx     $34
        ldx     #$02e0
        stx     $36
        lda     #$05
        sta     $72
        lda     #$81
        sta     hNMITIMEN
        cli
        lda     #$60
        sta     $44
@88e1:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @88ed
        jsr     _7f9a8f
@88ed:  jsr     _7f9f2c
        dec     $44
        bne     @88e1
        lda     #$c0
        sta     $44
@88f8:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @890d
        jsr     _7f9a8f
        jsr     _7f9abd
        jsr     _7f9aa8
        jsr     _7f9ae4
@890d:  jsr     _7f9f2c
        dec     $44
        bne     @88f8
        lda     #$90
        sta     $44
@8918:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @892a
        jsr     _7f9ab1
        jsr     _7f9aa8
        jsr     _7f9ae4
@892a:  jsr     _7f9a8f
        jsr     _7f9f2c
        dec     $44
        bne     @8918
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8942:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @8951
        jsr     _7f9ab1
        jsr     _7f9aa8
@8951:  jsr     _7f9ae4
        jsr     _7f9a8f
        jsr     _7f9f2c
        inc     $44
        lda     $71
        bne     @8942
        brl     _7f803a

; ------------------------------------------------------------------------------

; [ cutscene $0b: flash red (long) ]

_7f8963:
        jsr     _7f8660
        jsr     _7fab7a
        lda     #$02
        sta     hCGSWSEL
        lda     #$30
        sta     hCGADSUB
        sta     $8e
        lda     #$01
        sta     hTS
        sta     $3a
        lda     #$10
        sta     hTM
        sta     $3b
        lda     #$01
        tsb     $4f
        jsr     _7f9deb
        ldx     #$8000
        stx     $58
        ldx     #$5800
        stx     $5c
        ldx     #$5800
        stx     $5e
        ldx     $c7
        stx     $52
        ldx     #$0060
        stx     $30
        ldx     #$0220
        stx     $32
        ldx     #$00e0
        stx     $34
        ldx     #$02a0
        stx     $36
        lda     #$05
        sta     $72
        jsr     _7f9f2c
        lda     #$81
        sta     hNMITIMEN
        cli
        lda     #$02
        sta     $48
        stz     $44
@89c4:  jsr     _7f945d
        lda     $44
        bit     #$01
        bne     @89da
        and     #$07
        bne     @89d4
        jsr     _7f9a8f
@89d4:  jsr     _7f9a29
        jsr     _7f9a73
@89da:  jsr     _7f9f2c
        dec     $44
        bne     @89c4
        dec     $48
        bne     @89c4
@89e5:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @89f1
        jsr     _7f9aa8
@89f1:  jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9f2c
        dec     $44
        bne     @89e5
        ldx     #$8081
        stx     $1d00
        jsl     ExecSound_ext
        lda     #$40
        sta     $44
@8a0c:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @8a18
        jsr     _7f9a8f
@8a18:  jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9f2c
        dec     $44
        bne     @8a0c
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8a33:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8a3f
        jsr     _7f9a8f
@8a3f:  jsr     _7f9a49
        jsr     _7f9a65
        inc     $44
        lda     $71
        bne     @8a33
        brl     _7f803a

; ------------------------------------------------------------------------------

_7f8a4e:
@8a4e:  jsr     _7f94a5
        jsr     _7f9465
        jsr     _7f96b8
        jsr     _7faff3
        jsr     _7fb29e
        jsr     _7fac2a
        jsr     _7fc1f4
        lda     #$00
        sta     hCGSWSEL
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$02
        sta     $72
        lda     #$01
        tsb     $4f
        ldx     #$ff00
        stx     $58
        ldx     #$8000
        stx     $5c
        ldx     #$8000
        stx     $5e
        ldx     #$00da
        stx     $30
        ldx     #$0098
        stx     $32
        ldx     #$015a
        stx     $34
        ldx     #$0118
        stx     $36
        lda     #$81
        sta     hNMITIMEN
        cli
        rts

; ------------------------------------------------------------------------------

; [ cutscene $07: lightning bolt ??? ]

_7f8aa2:
        jsr     _7f8a4e
        lda     #$c0
        sta     $44
@8aa9:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8ab5
        jsr     _7f9a8f
@8ab5:  jsr     _7f9ae4
        jsr     _7f9af2
        dec     $44
        bne     @8aa9
        lda     #$c0
        sta     $44
@8ac3:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8ad5
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9ab1
@8ad5:  jsr     _7f9ae4
        jsr     _7f9af2
        jsr     _7faf08
        dec     $44
        bne     @8ac3
        lda     #$c0
        sta     $44
@8ae6:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @8af2
        jsr     _7f9ab1
@8af2:  jsr     _7f9aa8
        jsr     _7f9ac9
        jsr     _7f9af2
        jsr     _7faf08
        dec     $44
        bne     @8ae6
        jsr     _7fb43c
        lda     #$c0
        sta     $44
@8b09:  jsr     _7f945d
        jsr     _7f9ae4
        lda     $44
        and     #$01
        bne     @8b18
        jsr     _7f9a98
@8b18:  lda     $44
        and     #$07
        bne     @8b21
        jsr     _7f9ab1
@8b21:  jsr     _7f9aa8
        jsr     _7f9af2
        jsr     _7faf08
        jsr     _7fba5d
        dec     $44
        bne     @8b09
        lda     #$80
        sta     $44
@8b35:  jsr     _7f945d
        jsr     _7f9ae4
        jsr     _7f9ae4
        jsr     _7f9aa8
        jsr     _7f9abd
        jsr     _7f9af2
        jsr     _7faf08
        jsr     _7fba86
        dec     $44
        bne     @8b35
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8b5f:  jsr     _7f945d
        jsr     _7f9abd
        jsr     _7f9a8f
        jsr     _7f9ae4
        jsr     _7f9ae4
        jsr     _7f9af2
        jsr     _7faf08
        jsr     _7fba86
        inc     $44
        lda     $71
        bne     @8b5f
        brl     _7f803a

; ------------------------------------------------------------------------------

; [ cutscene $09: purple sparklies ]

_7f8b80:
        jsr     _7f8a4e
        jsr     _7fb45d
        ldx     #$00a0
        stx     $52
        lda     #$c0
        sta     $44
@8b8f:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8b9b
        jsr     _7f9a8f
@8b9b:  lda     $44
        and     #$01
        bne     @8ba4
        jsr     _7f9ae4
@8ba4:  jsr     _7f9af2
        dec     $44
        bne     @8b8f
        jsr     _7fb41b
        lda     #$ff
        sta     $44
@8bb2:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8bc4
        jsr     _7f9a8f
        jsr     _7f9aa8
        jsr     _7f9ab1
@8bc4:  lda     $44
        and     #$01
        bne     @8bcd
        jsr     _7f9ae4
@8bcd:  jsr     _7fb828
        jsr     _7f9af2
        jsr     _7fafae
        dec     $44
        bne     @8bb2
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8be8:  jsr     _7f945d
        jsr     _7f9a8f
        lda     $44
        and     #$01
        bne     @8bf7
        jsr     _7f9ae4
@8bf7:  jsr     _7fb828
        jsr     _7f9af2
        jsr     _7fafae
        inc     $44
        lda     $71
        bne     @8be8
        brl     _7f803a

; ------------------------------------------------------------------------------

_7f8c09:
        jsr     _7f8a4e
        ldx     #$1000
        stx     $58
        ldx     #$8000
        stx     $5c
        ldx     #$ff00
        stx     $5e
        lda     #$c0
        sta     $44
@8c1f:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8c2b
        jsr     _7f9a98
@8c2b:  jsr     _7f9ae4
        jsr     _7f9af2
        dec     $44
        bne     @8c1f
        lda     #$c0
        sta     $44
@8c39:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8c4b
        jsr     _7f9a98
        jsr     _7f9aa1
        jsr     _7f9ab1
@8c4b:  jsr     _7f9ae4
        jsr     _7f9af2
        dec     $44
        bne     @8c39
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8c63:  jsr     _7f945d
        jsr     _7f9a98
        jsr     _7f9ae4
        jsr     _7f9af2
        inc     $44
        lda     $71
        bne     @8c63
        brl     _7f803a

; ------------------------------------------------------------------------------

; [ cutscene $00: ending credits ]

_7f8c78:
        jsr     _7f94a5
        jsr     _7f9465
        jsr     _7f96b8
        jsr     _7faff3
        jsr     _7fab3b
        jsr     _7f9780
        lda     #$02
        sta     hCGSWSEL
        lda     #$30
        sta     hCGADSUB
        sta     $8e
        lda     #$01
        sta     hTS
        sta     $3a
        lda     #$10
        sta     hTM
        sta     $3b
        jsr     _7fafc1
        jsr     _7f9deb
        jsr     _7f98d0
        jsr     _7fb30a
        jsr     _7fb49f
        jsr     _7fc1f4
        jsr     _7fbb79
        lda     #$01
        tsb     $4f
        lda     #$81
        sta     hNMITIMEN
        cli
        jsr     _7fbbb0
        jsr     _7f945d
        jsr     _7fbbca
        jsr     _7f945d
        jsr     _7fbbe4
        jsr     _7f945d
        jsr     _7fbe34
        jsr     _7f945d
        lda     #$02
        trb     $70
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$02
        sta     $72
        ldx     #$8000
        stx     $58
        ldx     #$8000
        stx     $5c
        ldx     #$8000
        stx     $5e
        ldx     $c7
        stx     $52
        ldx     #$00c0
        stx     $30
        ldx     #$00c8
        stx     $32
        ldx     #$0140
        stx     $34
        ldx     #$0148
        stx     $36
        stz     $44
        inc     $29
        lda     #$05
        sta     $48
@8d1a:  jsr     _7f945d
        lda     $44
        and     #$03
        bne     @8d29
        jsr     _7f9a1e
        jsr     _7f9a81
@8d29:  jsr     _7fbe7e
        lda     $29
        beq     @8d3c
        dec     $44
        bne     @8d1a
        dec     $48
        bne     @8d1a
        stz     $29
        bra     @8d1a
@8d3c:  dec     $44
        lda     $2a
        bne     @8d1a
        lda     #$40
        sta     $44
@8d46:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8d55
        jsr     _7f9aa1
        jsr     _7f9ae4
@8d55:  jsr     _7f9ab1
        jsr     _7f9f2c
        dec     $44
        bne     @8d46
        lda     #$c0
        sta     $44
@8d63:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8d75
        jsr     _7f9aa8
        jsr     _7f9a1e
        jsr     _7f9a81
@8d75:  jsr     _7f9a39
        jsr     _7f9a57
        jsr     _7f9f2c
        dec     $44
        bne     @8d63
        ldx     #$0030
        stx     $60
        ldx     #$0038
        stx     $62
        ldx     #$0040
        stx     $64
        ldx     #$0048
        stx     $66
        ldx     #$0050
        stx     $68
        ldx     #$0058
        stx     $6a
        ldx     #$0060
        stx     $6c
        ldx     #$0068
        stx     $6e
        stz     $46
        lda     #$05
        sta     $48
        inc     $29
@8db2:  jsr     _7f945d
        jsr     _7f9a39
        jsr     _7f9a57
        lda     $44
        and     #$01
        bne     @8dc7
        jsr     _7f9a1e
        jsr     _7f9a81
@8dc7:  jsr     _7fb8f2
        jsr     _7fbe7e
        jsr     _7fb7bf
        lda     $29
        beq     @8de2
        dec     $46
        dec     $44
        bne     @8db2
        dec     $48
        bne     @8db2
        stz     $29
        bra     @8db2
@8de2:  dec     $44
        lda     $2a
        bne     @8db2
        lda     #$80
        sta     $44
@8dec:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8df8
        jsr     _7f9ac9
@8df8:  jsr     _7f9a39
        jsr     _7f9a57
        jsr     _7f9f2c
        dec     $44
        bne     @8dec
        stz     $44
        lda     #$03
        sta     $48
@8e0b:  jsr     _7f945d
        jsr     _7fbe7e
        lda     $44
        and     #$01
        bne     @8e1d
        jsr     _7f9a1e
        jsr     _7f9a81
@8e1d:  jsr     _7f9a39
        jsr     _7f9a57
        dec     $44
        bne     @8e0b
        dec     $48
        bne     @8e0b
        inc     $29
        lda     #$02
        sta     $48
@8e31:  jsr     _7f945d
        jsr     _7fbe7e
        jsr     _7fb88e
        jsr     _7fb7bf
        lda     $44
        and     #$01
        bne     @8e49
        jsr     _7f9a1e
        jsr     _7f9a81
@8e49:  jsr     _7f9a39
        jsr     _7f9a57
        lda     $29
        beq     @8e5f
        dec     $44
        bne     @8e31
        dec     $48
        bne     @8e31
        stz     $29
        bra     @8e31
@8e5f:  dec     $44
        lda     $2a
        bne     @8e31
        lda     #$c0
        sta     $44
@8e69:  jsr     _7f945d
        lda     $44
        and     #$01
        bne     @8e81
        jsr     _7f9a39
        jsr     _7f9a57
        jsr     _7f9ae4
        jsr     _7f9a8f
        jsr     _7f9aa8
@8e81:  jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9f2c
        dec     $44
        bne     @8e69
        inc     $29
        lda     #$02
        sta     $48
        lda     #$10
        sta     $44
@8e98:  jsr     _7f945d
        jsr     _7fbe7e
        jsr     _7f9a39
        jsr     _7f9a57
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     $29
        beq     @8eba
        dec     $44
        bne     @8e98
        dec     $48
        bne     @8e98
        stz     $29
        bra     @8e98
@8eba:  dec     $44
        lda     $2a
        bne     @8e98
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
@8ece:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a39
        jsr     _7f9a57
        dec     $44
        lda     $71
        bne     @8ece
        jsr     _7f803a
        jsr     _7fb335
        jsr     _7fb4e1
        jsr     _7f9943
        jsr     _7fb360
        jsr     _7fb375
        jsr     _7fb550
        jsr     _7fb593
        lda     #$01
        tsb     $4f
        lda     #$81
        sta     hNMITIMEN
        cli
        lda     #$02
        trb     $70
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$02
        sta     $72
        ldx     #$4000
        stx     $58
        ldx     #$2000
        stx     $5c
        ldx     #$6000
        stx     $5e
        ldx     #$00da
        stx     $30
        ldx     #$0098
        stx     $32
        ldx     #$015a
        stx     $34
        ldx     #$0118
        stx     $36
        ldx     $c7
        stx     $52
        jsr     _7f9f2c
        inc     $29
        stz     $44
        lda     #$02
        sta     $48
@8f47:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fbe7e
        jsr     _7fb7bf
        lda     $29
        beq     @8f6c
        dec     $44
        bne     @8f47
        dec     $48
        bne     @8f47
        stz     $29
        bra     @8f47
@8f6c:  dec     $44
        lda     $2a
        bne     @8f47
        lda     #$60
        sta     $44
@8f76:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb7bf
        jsr     _7fba44
        jsr     _7fba44
        jsr     _7fba44
        lda     $44
        and     #$01
        bne     @8f9a
        jsr     _7fb693
@8f9a:  dec     $44
        bne     @8f76
        lda     #$f0
        sta     $44
@8fa2:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb7bf
        jsr     _7fba44
        lda     $44
        and     #$01
        bne     @8fc0
        jsr     _7fb6de
@8fc0:  dec     $44
        bne     @8fa2
        lda     #$b0
        sta     $44
@8fc8:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     $44
        and     #$03
        bne     @8fe6
        jsr     _7f9aa1
@8fe6:  jsr     _7fb7bf
        jsr     _7fb6f7
        jsr     _7f9f2c
        dec     $44
        bne     @8fc8
        lda     #$55
        sta     $44
@8ff7:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9ae4
        jsr     _7f9f2c
        dec     $44
        bne     @8ff7
        lda     #$01
        trb     $4f
        jsr     _7f945d
        jsr     _7fb38a
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     #$02
        tsb     $4f
        jsr     _7f945d
        jsr     _7fb3a6
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb523
        lda     #$02
        trb     $4f
        lda     #$01
        tsb     $4f
        lda     #$60
        sta     $44
@905a:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     $44
        and     #$01
        bne     @9072
        jsr     _7f9aa8
@9072:  jsr     _7f9f2c
        dec     $44
        bne     @905a
        inc     $29
        lda     #$02
        sta     $48
@907f:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb805
        lda     $44
        and     #$03
        bne     @909a
        jsr     _7fb9cc
@909a:  jsr     _7fbe7e
        lda     $29
        beq     @90ad
        dec     $44
        bne     @907f
        dec     $48
        bne     @907f
        stz     $29
        bra     @907f
@90ad:  dec     $44
        lda     $2a
        bne     @907f
        inc     $29
        lda     #$40
        sta     $44
        lda     #$01
        sta     $48
@90bd:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb805
        jsr     _7fb9e5
        jsr     _7fb9e5
        lda     $44
        and     #$03
        bne     @90de
        jsr     _7fb9cc
@90de:  jsr     _7fbe7e
        lda     $29
        beq     @90f1
        dec     $44
        bne     @90bd
        dec     $48
        bne     @90bd
        stz     $29
        bra     @90bd
@90f1:  dec     $44
        lda     $2a
        bne     @90bd
        inc     $29
        lda     #$40
        sta     $44
        lda     #$02
        sta     $48
@9101:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb805
        jsr     _7fb9e5
        lda     $44
        and     #$03
        bne     @911f
        jsr     _7fb9cc
@911f:  jsr     _7fbe7e
        lda     $29
        beq     @9132
        dec     $44
        bne     @9101
        dec     $48
        bne     @9101
        stz     $29
        bra     @9101
@9132:  dec     $44
        lda     $2a
        bne     @9101
        lda     #$03
        sta     $48
        lda     #$20
        sta     $44
        inc     $29
@9142:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb805
        lda     $44
        and     #$03
        bne     @915d
        jsr     _7fb9cc
@915d:  jsr     _7fbe7e
        lda     $29
        beq     @9170
        dec     $44
        bne     @9142
        dec     $48
        bne     @9142
        stz     $29
        bra     @9142
@9170:  dec     $44
        lda     $2a
        bne     @9142
        lda     #$20
        sta     $44
@917a:  jsr     _7f945d
        jsr     _7f9ae4
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9f2c
        dec     $44
        bne     @917a
        lda     #$01
        trb     $4f
        jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb3c2
        lda     #$02
        tsb     $4f
        jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb3de
        jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fb566
        jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     #$02
        trb     $4f
        lda     #$01
        tsb     $4f
        inc     $29
        lda     #$02
        sta     $48
@91ee:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fbe7e
        jsr     _7fb7e2
        lda     $44
        and     #$03
        bne     @920c
        jsr     _7fb9fe
@920c:  lda     $29
        beq     @921c
        dec     $44
        bne     @91ee
        dec     $48
        bne     @91ee
        stz     $29
        bra     @91ee
@921c:  dec     $44
        lda     $2a
        bne     @91ee
        stz     $44
        inc     $29
        lda     #$02
        sta     $48
@922a:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fbe7e
        jsr     _7fb7e2
        jsr     _7fba17
        lda     $44
        and     #$03
        bne     @924b
        jsr     _7fb9fe
@924b:  lda     $29
        beq     @925b
        dec     $44
        bne     @922a
        dec     $48
        bne     @922a
        stz     $29
        bra     @922a
@925b:  dec     $44
        lda     $2a
        bne     @922a
        lda     #$80
        sta     $44
        lda     #$03
        sta     $48
        inc     $29
@926b:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7fbe7e
        jsr     _7fb7e2
        lda     $44
        and     #$03
        bne     @9289
        jsr     _7fb9fe
@9289:  dec     $44
        bne     @926b
        dec     $48
        bne     @926b
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
        jsr     _7fbf3b
@92a2:  jsr     _7f945d
        jsr     _7f9a1e
        jsr     _7f9a81
        jsr     _7f9a1e
        jsr     _7f9a81
        lda     $44
        and     #$01
        bne     @92b7
@92b7:  inc     $44
        lda     $71
        bne     @92a2
        jsr     _7f803a
        jsr     _7f98d0
        jsr     _7fbbfe
        jsr     _7fafc1
        lda     #$01
        tsb     $4f
        lda     #$81
        sta     hNMITIMEN
        cli
        lda     #$02
        trb     $70
        lda     #$01
        tsb     $70
        stz     $71
        stz     $73
        lda     #$01
        sta     $72
        ldx     #$8000
        stx     $58
        ldx     #$6000
        stx     $5c
        ldx     #$a000
        stx     $5e
        ldx     #$00c0
        stx     $30
        ldx     #$00c8
        stx     $32
        ldx     #$0140
        stx     $34
        ldx     #$0148
        stx     $36
        ldx     #$0017
        stx     $52
        jsr     _7f9f2c
        inc     $29
        stz     $44
        lda     #$05
        sta     $48
@9316:  jsr     _7f945d
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7fbed2
        lda     $29
        beq     @9338
        dec     $44
        bne     @9316
        dec     $48
        bne     @9316
        stz     $29
        bra     @9316
@9338:  dec     $44
        lda     $2a
        bne     @9316
        lda     #$2d
        sta     $44
@9342:  jsr     _7f945d
        jsr     _7f9ae4
        jsr     _7f9aa8
        jsr     _7f9ab1
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9f2c
        dec     $44
        bne     @9342
        inc     $29
        stz     $44
        lda     #$05
        sta     $48
@9369:  jsr     _7f945d
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7fbed2
        lda     $29
        beq     @938b
        dec     $44
        bne     @9369
        dec     $48
        bne     @9369
        stz     $29
        bra     @9369
@938b:  dec     $44
        lda     $2a
        bne     @9369
        lda     #$17
        sta     $44
@9395:  jsr     _7f945d
        jsr     _7f9ac9
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9f2c
        dec     $44
        bne     @9395
        inc     $29
        stz     $44
        lda     #$04
        sta     $48
@93b6:  jsr     _7f945d
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7fbed2
        lda     $29
        beq     @93d8
        dec     $44
        bne     @93b6
        dec     $48
        bne     @93b6
        stz     $29
        bra     @93b6
@93d8:  dec     $44
        lda     $2a
        bne     @93b6
        lda     #$17
        sta     $44
@93e2:  jsr     _7f945d
        jsr     _7f9ac9
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7f9f2c
        dec     $44
        bne     @93e2
        inc     $29
        stz     $44
        lda     #$04
        sta     $48
@9403:  jsr     _7f945d
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        jsr     _7fbed2
        lda     $29
        beq     @9425
        dec     $44
        bne     @9403
        dec     $48
        bne     @9403
        stz     $29
        bra     @9403
@9425:  dec     $44
        lda     $2a
        bne     @9403
        lda     #$01
        trb     $70
        lda     #$02
        tsb     $70
        stz     $73
        lda     #$01
        sta     $72
        jsr     _7fbf3b
@943c:  jsr     _7f945d
        jsr     _7f9a98
        jsr     _7f9a29
        jsr     _7f9a73
        jsr     _7f9a49
        jsr     _7f9a65
        lda     $44
        and     #$01
        bne     @9454
@9454:  inc     $44
        lda     $71
        bne     @943c
        brl     _7f803a

; ------------------------------------------------------------------------------

_7f945d:
@945d:  lda     $07
        bne     @945d
        inc
        sta     $07
        rts

; ------------------------------------------------------------------------------

_7f9465:
        shorta
        longi
        lda     #$5c
        sta     $1f00
        ldx     #$c500
        stx     $1f01
        lda     #$7f
        sta     $1f03
        shorti
        ldx     #$df
        lda     #$00
@947f:  sta     $00,x
        dex
        bne     @947f
        longi
        ldx     #$ffff
        stx     $c5
        lda     #$01
        sta     $07
        jsr     _7fafc1
        ldx     $c7
        stx     $30
        stx     $32
        stx     $52
        ldx     #$0080
        stx     $34
        ldx     #$0100
        stx     $36
        rts

; ------------------------------------------------------------------------------

_7f94a5:
        lda     #$00
        pha
        plb
        lda     #$63
        sta     hOBJSEL
        lda     #$00
        sta     hOAMADDL
        sta     hOAMADDH
        lda     #$09
        sta     hBGMODE
        lda     #$00
        sta     hMOSAIC
        sta     hBG1SC
        sta     hBG2SC
        sta     hBG3SC
        sta     hBG4SC
        sta     hBG12NBA
        sta     hBG34NBA
        sta     hBG1HOFS
        sta     hBG1HOFS
        sta     hBG1VOFS
        sta     hBG1VOFS
        sta     hBG2HOFS
        sta     hBG2HOFS
        sta     hBG2VOFS
        sta     hBG2VOFS
        sta     hBG3HOFS
        sta     hBG3HOFS
        sta     hBG3VOFS
        sta     hBG3VOFS
        sta     hBG4HOFS
        sta     hBG4HOFS
        sta     hBG4VOFS
        sta     hBG4VOFS
        sta     hVMAINC
        sta     hVMADDL
        sta     hVMADDH
        sta     hM7SEL
        sta     hM7A
        lda     #$01
        sta     hM7A
        dec
        sta     hM7B
        sta     hM7B
        sta     hM7C
        sta     hM7C
        sta     hM7D
        inc
        sta     hM7D
        dec
        sta     hM7X
        sta     hM7X
        sta     hM7Y
        sta     hM7Y
        sta     hCGADD
        sta     hW12SEL
        lda     #$03
        sta     hW34SEL
        stz     hWOBJSEL
        stz     hWH0
        stz     hWH1
        stz     hWH2
        stz     hWH3
        stz     hWBGLOG
        stz     hWOBJLOG
        stz     hTMW
        stz     hTSW
        stz     hCGSWSEL
        stz     hCGADSUB
        stz     $8e
        stz     hTM
        stz     hTS
        stz     $3a
        stz     $3b
        lda     #$e0
        sta     hCOLDATA
        stz     hSETINI
        stz     hNMITIMEN
        lda     #$ff
        sta     hWRIO
        stz     hWRMPYA
        stz     hWRMPYB
        stz     hWRDIVL
        stz     hWRDIVH
        stz     hWRDIVB
        stz     hHTIMEL
        stz     hHTIMEH
        stz     hVTIMEL
        stz     hVTIMEH
        stz     hMDMAEN
        stz     hHDMAEN
        rts

; ------------------------------------------------------------------------------

_7f95a1:
        lda     $42
        bne     _7f95ab
        lda     $43
        bne     _7f95ab
        clc
        rts

; ------------------------------------------------------------------------------

_7f95ab:
        longa
        lda     $307ff8
        cmp     #$e41b
        beq     @95d5
        lda     $307ffa
        cmp     #$e41b
        beq     @95d5
        lda     $307ffc
        cmp     #$e41b
        beq     @95d5
        lda     $307ffe
        cmp     #$e41b
        beq     @95d5
        shorta
        clc
        rts
@95d5:  shorta
        sec
        rts

; ------------------------------------------------------------------------------

_7f95d9:
        phb
        longa
        ldx     #$0420
        ldy     #$f000
        lda     #$00c8
        mvn     #$00,#$7f
        shorta
        plb
        rts

; ------------------------------------------------------------------------------

_7f95ec:
        phb
        longa
        ldy     #$0420
        ldx     #$f000
        lda     #$00c8
        mvn     #$7f,#$00
        shorta
        plb
        rts

; ------------------------------------------------------------------------------

_7f95ff:
        lda     #$17
        sta     hBGMODE
        lda     #$40
        sta     hM7SEL
        lda     #$00
        sta     hTS
        sta     $3a
        sta     hTS
        lda     #$01
        sta     hTM
        sta     $3b
        lda     #$01
        sta     hTMW
        lda     #$00
        sta     hCGADSUB
        sta     $8e
        lda     #$e0
        sta     hCOLDATA
        stz     $8b
        stz     $8c
        stz     $8d
        lda     #$00
        sta     hCGSWSEL
        sta     hBG12NBA
        rts

; ------------------------------------------------------------------------------

_7f963a:
        lda     #$17
        sta     hBGMODE
        lda     #$40
        sta     hM7SEL
        lda     #$00
        sta     hTSW
        lda     #$01
        sta     hTS
        sta     $3a
        lda     #$10
        sta     hTM
        sta     $3b
        lda     #$01
        sta     hTMW
        lda     #$30
        sta     hCGADSUB
        sta     $8e
        lda     #$e0
        sta     hCOLDATA
        stz     $8b
        stz     $8c
        stz     $8d
        lda     #$02
        sta     hCGSWSEL
        lda     #$00
        sta     hBG12NBA
        rts

; ------------------------------------------------------------------------------

_7f9679:
        lda     #$17
        sta     hBGMODE
        lda     #$80
        sta     hM7SEL
        lda     #$00
        sta     hTSW
        lda     #$01
        sta     hTS
        sta     $3a
        lda     #$11
        sta     hTM
        sta     $3b
        lda     #$01
        sta     hTMW
        lda     #$70
        sta     hCGADSUB
        sta     $8e
        lda     #$e0
        sta     hCOLDATA
        stz     $8b
        stz     $8c
        stz     $8d
        lda     #$02
        sta     hCGSWSEL
        lda     #$00
        sta     hBG12NBA
        rts

; ------------------------------------------------------------------------------

_7f96b8:
        lda     #$17
        sta     hBGMODE
        lda     #$40
        sta     hM7SEL
        lda     #$00
        sta     hTSW
        lda     #$01
        sta     hTS
        sta     $3a
        lda     #$11
        sta     hTM
        sta     $3b
        lda     #$01
        sta     hTMW
        lda     #$00
        sta     hCGSWSEL
        lda     #$21
        sta     $8e
        sta     hCGADSUB
        sta     $8e
        lda     #$e0
        sta     hCOLDATA
        stz     $8b
        stz     $8c
        stz     $8d
        lda     #$00
        sta     hBG12NBA
        rts

; ------------------------------------------------------------------------------

_7f96f9:
        ldx     $c7
        stx     $30
        stx     $32
        ldx     #$0080
        stx     $34
        ldx     #$0100
        stx     $36
        ldx     $c7
        stx     $52
        rts

; ------------------------------------------------------------------------------

_7f970e:
        lda     #^_c31243
        sta     $d2
        ldx     #near _c31243
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9100
        stx     $d3
        jsr     _7fc00d
        lda     #^_c31c65
        sta     $d2
        ldx     #near _c31c65
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        jsr     _7f97ad
        jsr     _7f97f8
        lda     #^_c333f6
        sta     $d2
        ldx     #near _c333f6
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$4800
        stx     $d3
        brl     _7fc00d

; ------------------------------------------------------------------------------

_7f9753:
        lda     #^_c30368
        sta     $d2
        ldx     #near _c30368
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9100
        stx     $d3
        jsr     _7fc00d
        lda     #^_c305f9
        sta     $d2
        ldx     #near _c305f9
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        brl     _7f97ad

; ------------------------------------------------------------------------------

_7f9780:
        lda     #^_c33909
        sta     $d2
        ldx     #near _c33909
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9100
        stx     $d3
        jsr     _7fc00d
        lda     #^_c34452
        sta     $d2
        ldx     #near _c34452
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        brl     _7f97ad

; ------------------------------------------------------------------------------

_7f97ad:
@97ad:  ldx     #$0000
        stx     hVMADDL
        lda     #$80
        sta     hVMAINC
        ldx     $c7
        stx     $0c
        stx     $0e
@97be:  ldx     $0c
        lda     $7e9100,x
        pha
        and     #$0f
        ldx     $0e
        ora     $7e9000,x
        sta     hVMDATAH
        pla
        and     #$f0
        lsr4
        ora     $7e9000,x
        sta     hVMDATAH
        longa
        lda     $0c
        inc
        cmp     #$2000
        beq     @97f5
        sta     $0c
        and     #$001f
        bne     @97f1
        inc     $0e
@97f1:  shorta
        bra     @97be
@97f5:  shorta
        rts

; ------------------------------------------------------------------------------

_7f97f8:
@97f8:  ldx     $c7
        stx     $0c
        stx     $0e
@97fe:  lda     $7e9100,x
        stx     $0c
        pha
        and     #$0f
        beq     @9813
        ldx     $0e
        lda     #$00
        sta     $7f0000,x
        bra     @981b
@9813:  lda     #$20
        ldx     $0e
        sta     $7f0000,x
@981b:  inx
        pla
        and     #$f0
        beq     @9829
        lda     #$00
        sta     $7f0000,x
        bra     @982f
@9829:  lda     #$20
        sta     $7f0000,x
@982f:  inx
        stx     $0e
        ldx     $0c
        inx
        cpx     #$1800
        bne     @97fe
        rts

; ------------------------------------------------------------------------------

_7f983b:
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        ldx     #$1000
        stx     $d6
        jsr     _7fc1e0
        shorta
        ldx     #$2000
        stx     $14
        jsr     _7f99b6
        ldx     #$0040
        stx     $14
        jsr     _7f99b6
        ldx     $c7
        stx     $14
        jsr     _7f99b6
        ldx     #$2040
        stx     $14
        jsr     _7f99b6
        lda     #^_c31c69
        sta     $d2
        ldx     #near _c31c69
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$2040
        stx     $14
        brl     _7f99ea

; ------------------------------------------------------------------------------

_7f988a:
        lda     #^_c305fd
        sta     $d2
        ldx     #near _c305fd
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$2040
        stx     $14
        jsr     _7f99b6
        longa
        lda     $c7
        tax
@98ac:  sta     $7e9000
        inx2
        cpx     #$1000
        bne     @98ac
        shorta
        ldx     #$2000
        stx     $14
        jsr     _7f99b6
        ldx     #$0040
        stx     $14
        jsr     _7f99b6
        ldx     $c7
        stx     $14
        brl     _7f99b6

; ------------------------------------------------------------------------------

_7f98d0:
        lda     #^_c34469
        sta     $d2
        ldx     #near _c34469
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$0000
        stx     $d3
        jsr     _7fc0f0
        lda     #$7f
        sta     $d2
        ldx     #$0000
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc05d
        ldx     #$2040
        stx     $14
        jsr     _7f99b6
        ldx     $c7
        stx     $14
        jsr     _7f99b6
        lda     #^_c351ef
        sta     $d2
        ldx     #near _c351ef
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$0000
        stx     $d3
        jsr     _7fc0f0
        lda     #$7f
        sta     $d2
        ldx     #$0000
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc05d
        ldx     #$2000
        stx     $14
        jsr     _7f99b6
        ldx     #$0040
        stx     $14
        brl     _7f99b6

; ------------------------------------------------------------------------------

_7f9943:
        lda     #^_c34e34
        sta     $d2
        ldx     #near _c34e34
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$0000
        stx     $d3
        jsr     _7fc0f0
        lda     #$7f
        sta     $d2
        ldx     #$0000
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc05d
        ldx     $c7
        stx     $14
        jsr     _7f99b6
        ldx     #$2040
        stx     $14
        jsr     _7f99b6
        lda     #^_c350d4
        sta     $d2
        ldx     #near _c350d4
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$0000
        stx     $d3
        jsr     _7fc0f0
        lda     #$7f
        sta     $d2
        ldx     #$0000
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc05d
        ldx     #$0040
        stx     $14
        jsr     _7f99b6
        ldx     #$2000
        stx     $14
        brl     _7f99b6

; ------------------------------------------------------------------------------

_7f99b6:
@99b6:  lda     #$00
        sta     hVMAINC
        ldx     $14
        stx     hVMADDL
        ldx     $c7
        ldy     #$0040
@99c5:  lda     $7e9000,x
        sta     hVMDATAL
        cpx     #$0fff
        beq     @99e9
        inx
        dey
        bne     @99c5
        longa
        lda     $14
        clc
        adc     #$0080
        sta     $14
        sta     hVMADDL
        shorta
        ldy     #$0040
        bra     @99c5
@99e9:  rts

; ------------------------------------------------------------------------------

_7f99ea:
@99ea:  lda     #$00
        sta     hVMAINC
        ldx     $14
        stx     hVMADDL
        ldx     $c7
        ldy     #$0020
@99f9:  lda     $7e9000,x
        sta     hVMDATAL
        cpx     #$0400
        beq     @9a1d
        inx
        dey
        bne     @99f9
        longa
        lda     $14
        clc
        adc     #$0080
        sta     $14
        sta     hVMADDL
        shorta
        ldy     #$0020
        bra     @99f9
@9a1d:  rts

; ------------------------------------------------------------------------------

_7f9a1e:
        ldx     $32
        bne     @9a25
        ldx     #$0400
@9a25:  dex
        stx     $32
        rts

; ------------------------------------------------------------------------------

_7f9a29:
        ldx     $32
        cpx     #$03ff
        bne     @9a35
        ldx     $c7
        stx     $32
        rts
@9a35:  inx
        stx     $32
        rts

; ------------------------------------------------------------------------------

_7f9a39:
        ldx     $30
        cpx     #$03ff
        bne     @9a45
        ldx     $c7
        stx     $30
        rts
@9a45:  inx
        stx     $30
        rts

; ------------------------------------------------------------------------------

_7f9a49:
        ldx     $30
        bne     @9a53
        ldx     #$03ff
        stx     $30
        rts
@9a53:  dex
        stx     $30
        rts

; ------------------------------------------------------------------------------

_7f9a57:
        ldx     $34
        inx
        cpx     #$0480
        bne     @9a62
        ldx     #$0080
@9a62:  stx     $34
        rts

; ------------------------------------------------------------------------------

_7f9a65:
        ldx     $34
        dex
        cpx     #$0080
        bne     @9a70
        ldx     #$047f
@9a70:  stx     $34
        rts

; ------------------------------------------------------------------------------

_7f9a73:
        ldx     $36
        inx
        cpx     #$0480
        bne     @9a7e
        ldx     #$0080
@9a7e:  stx     $36
        rts

; ------------------------------------------------------------------------------

_7f9a81:
        ldx     $36
        cpx     #$0080
        bne     @9a8b
        ldx     #$0480
@9a8b:  dex
        stx     $36
        rts

; ------------------------------------------------------------------------------

_7f9a8f:
        lda     $59
        cmp     #$01
        beq     @9a97
        dec     $59
@9a97:  rts

; ------------------------------------------------------------------------------

_7f9a98:
        lda     $59
        cmp     #$ff
        beq     @9aa0
        inc     $59
@9aa0:  rts

; ------------------------------------------------------------------------------

_7f9aa1:
        lda     $5f
        beq     @9aa7
        dec     $5f
@9aa7:  rts

; ------------------------------------------------------------------------------

_7f9aa8:
        lda     $5f
        cmp     #$ff
        beq     @9ab0
        inc     $5f
@9ab0:  rts

; ------------------------------------------------------------------------------

_7f9ab1:
        lda     $5d
        cmp     #$01
        beq     @9aba
        dec     $5d
        rts
@9aba:  stz     $4e
        rts

; ------------------------------------------------------------------------------

_7f9abd:
        lda     $5d
        cmp     #$ff
        beq     @9ac6
        inc     $5d
        rts
@9ac6:  stz     $4e
        rts

; ------------------------------------------------------------------------------

_7f9ac9:
        ldx     $52
        cpx     #$0167
        beq     @9ad4
        inx
        stx     $52
        rts
@9ad4:  ldx     $c7
        stx     $52
        rts

; ------------------------------------------------------------------------------

_7f9ad9:
        ldx     $38
        cpx     #$00e1
        beq     @9ae3
        inx
        stx     $38
@9ae3:  rts

; ------------------------------------------------------------------------------

_7f9ae4:
        ldx     $52
        beq     @9aec
        dex
        stx     $52
        rts
@9aec:  ldx     #$0167
        stx     $52
        rts

; ------------------------------------------------------------------------------

_7f9af2:
        ldx     $52
        cpx     #$010e
        bcs     @9b37
        cpx     #$00b4
        bcs     @9b25
        cpx     #$005a
        bcs     @9b13
        lda     $7ec000,x
        sta     $55
        lda     $7ec05a,x
        sta     $54
        stz     $50
        bra     @9b47
@9b13:  lda     $7ec000,x
        sta     $55
        lda     $7ebfa6,x
        sta     $54
        lda     #$01
        sta     $50
        bra     @9b47
@9b25:  lda     $7ebf4c,x
        sta     $55
        lda     $7ebfa6,x
        sta     $54
        lda     #$80
        sta     $50
        bra     @9b47
@9b37:  lda     $7ebf4c,x
        sta     $55
        lda     $7ebef2,x
        sta     $54
        lda     #$81
        sta     $50
@9b47:  lda     #$0f
        tsb     $40
        lda     #$42
        sta     hDMA0::CTRL
        sta     hDMA1::CTRL
        sta     hDMA2::CTRL
        sta     hDMA3::CTRL
        lda     #<hM7A
        sta     hDMA0::HREG
        lda     #<hM7D
        sta     hDMA1::HREG
        lda     #<hM7B
        sta     hDMA2::HREG
        lda     #<hM7C
        sta     hDMA3::HREG
        ldx     #$8000
        stx     hDMA0::ADDR
        stx     hDMA1::ADDR
        ldx     #$8006
        stx     hDMA2::ADDR
        ldx     #$800c
        stx     hDMA3::ADDR
        lda     #$7e
        sta     hDMA0::ADDR_B
        sta     hDMA1::ADDR_B
        sta     hDMA2::ADDR_B
        sta     hDMA3::ADDR_B
        sta     hDMA0::HDMA_B
        sta     hDMA1::HDMA_B
        sta     hDMA2::HDMA_B
        sta     hDMA3::HDMA_B
        lda     #$ff
        sta     $7e8000
        sta     $7e8006
        sta     $7e800c
        lda     #$e2
        sta     $7e8003
        sta     $7e8009
        sta     $7e800f
        longa
        lda     #$8100
        sta     $7e8001
        lda     #$8200
        sta     $7e8004
        lda     #$8300
        sta     $7e8007
        lda     #$8400
        sta     $7e800a
        lda     #$8500
        sta     $7e800d
        lda     #$8600
        sta     $7e8010
        lda     $5e
        sec
        sbc     $5c
        sta     hWRDIVL
        ldy     #$0071
        sty     hWRDIVB
        sty     $0e
        ldx     $c7
        lda     $5c
        sta     $0a
        lda     hRDDIVL
        sta     $5a
        lda     $58
        sta     hWRDIVL
        shorta
        lda     $50
        beq     @9c0d
        brl     @9c80
@9c0d:  longa
@9c0f:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8300,x
        sta     $7e8302,x
        eor     $c5
        inc
        sta     $7e8500,x
        sta     $7e8502,x
        inx4
        dec     $0e
        beq     @9c7d
        brl     @9c0f
@9c7d:  shorta
        rts
@9c80:  bpl     @9c85
        brl     @9cfb
@9c85:  longa
@9c87:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        eor     $c5
        inc
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8300,x
        sta     $7e8302,x
        eor     $c5
        inc
        sta     $7e8500,x
        sta     $7e8502,x
        inx4
        dec     $0e
        beq     @9cf8
        brl     @9c87
@9cf8:  shorta
        rts
@9cfb:  and     #$7f
        beq     @9d02
        brl     @9d78
@9d02:  longa
@9d04:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        eor     $c5
        inc
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8500,x
        sta     $7e8502,x
        eor     $c5
        inc
        sta     $7e8300,x
        sta     $7e8302,x
        inx4
        dec     $0e
        beq     @9d75
        brl     @9d04
@9d75:  shorta
        rts
@9d78:  longa
@9d7a:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8500,x
        sta     $7e8502,x
        eor     $c5
        inc
        sta     $7e8300,x
        sta     $7e8302,x
        inx4
        dec     $0e
        beq     @9de8
        brl     @9d7a
@9de8:  shorta
        rts

; ------------------------------------------------------------------------------

_7f9deb:
        lda     #$3f
        tsb     $40
        lda     #$42
        sta     hDMA0::CTRL
        sta     hDMA1::CTRL
        sta     hDMA2::CTRL
        sta     hDMA3::CTRL
        sta     hDMA5::CTRL
        lda     #$40
        sta     hDMA4::CTRL
        sta     hDMA6::CTRL
        lda     #<hM7A
        sta     hDMA0::HREG
        lda     #<hM7D
        sta     hDMA1::HREG
        lda     #<hM7B
        sta     hDMA2::HREG
        lda     #<hM7C
        sta     hDMA3::HREG
        lda     #<hCGADD
        sta     hDMA4::HREG
        lda     #<hCGDATA
        sta     hDMA5::HREG
        ldx     #$8000
        stx     hDMA0::ADDR
        stx     hDMA1::ADDR
        ldx     #$8006
        stx     hDMA2::ADDR
        ldx     #$800c
        stx     hDMA3::ADDR
        ldx     #$8012
        stx     hDMA4::ADDR
        ldx     #$8018
        stx     hDMA5::ADDR
        lda     #$7e
        sta     hDMA0::ADDR_B
        sta     hDMA1::ADDR_B
        sta     hDMA2::ADDR_B
        sta     hDMA3::ADDR_B
        sta     hDMA4::ADDR_B
        sta     hDMA5::ADDR_B
        sta     hDMA0::HDMA_B
        sta     hDMA1::HDMA_B
        sta     hDMA2::HDMA_B
        sta     hDMA3::HDMA_B
        sta     hDMA4::HDMA_B
        sta     hDMA5::HDMA_B
        lda     #$ff
        sta     $7e8000
        sta     $7e8006
        sta     $7e800c
        sta     $7e8012
        sta     $7e8018
        sta     $7e801e
        lda     #$e2
        sta     $7e8003
        sta     $7e8009
        sta     $7e800f
        sta     $7e8015
        sta     $7e801b
        longa
        lda     #$8100
        sta     $7e8001
        lda     #$8200
        sta     $7e8004
        lda     #$8300
        sta     $7e8007
        lda     #$8400
        sta     $7e800a
        lda     #$8500
        sta     $7e800d
        lda     #$8600
        sta     $7e8010
        lda     #$8700
        sta     $7e8013
        lda     #$8780
        sta     $7e8016
        lda     #$8800
        sta     $7e8019
        lda     #$8900
        sta     $7e801c
        ldx     $c7
        txa
@9ee8:  sta     $7e8700,x
        inx2
        cpx     #$0100
        bne     @9ee8
        ldx     $c7
        lda     $c7
@9ef7:  sta     $7e8300,x
        sta     $7e8500,x
        inx2
        cpx     #$0200
        bne     @9ef7
        ldx     $c7
        lda     $7ee080
@9f0c:  sta     $7e8800,x
        inx2
        cpx     #$0200
        bne     @9f0c
        ldx     $c7
        lda     #$0100
@9f1c:  sta     $7e8100,x
        inx2
        cpx     #$0200
        bne     @9f1c
        stz     $38
        shorta
        rts

; ------------------------------------------------------------------------------

_7f9f2c:
        ldx     $52
        cpx     #$010e
        bcs     @9f71
        cpx     #$00b4
        bcs     @9f5f
        cpx     #$005a
        bcs     @9f4d
        lda     $7ec000,x
        sta     $55
        lda     $7ec05a,x
        sta     $54
        stz     $50
        bra     @9f81
@9f4d:  lda     $7ec000,x
        sta     $55
        lda     $7ebfa6,x
        sta     $54
        lda     #$01
        sta     $50
        bra     @9f81
@9f5f:  lda     $7ebf4c,x
        sta     $55
        lda     $7ebfa6,x
        sta     $54
        lda     #$80
        sta     $50
        bra     @9f81
@9f71:  lda     $7ebf4c,x
        sta     $55
        lda     $7ebef2,x
        sta     $54
        lda     #$81
        sta     $50
@9f81:  longa
        lda     $5e
        sec
        sbc     $5c
        sta     hWRDIVL
        ldy     #$0071
        sty     hWRDIVB
        lda     #$00e1
        sec
        sbc     $38
        lsr
        inc
        sta     $0e
        lda     $38
        asl
        tax
        lda     $5c
        sta     $0a
        lda     hRDDIVL
        sta     $5a
        lda     $58
        sta     hWRDIVL
        shorta
        lda     $50
        beq     @9fb6
        brl     @a055
@9fb6:  longa
@9fb8:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8300,x
        sta     $7e8302,x
        eor     $c5
        inc
        sta     $7e8500,x
        sta     $7e8502,x
        phx
        lda     $56
        lsr2
        shorta
        sta     hWRMPYA
        sta     hWRMPYB
        longa
        nop2
        lda     hRDMPYL
        lsr2
        xba
        and     $c6
        asl5
        tax
        lda     $7ee000,x
        plx
        sta     $7e8800,x
        sta     $7e8802,x
        inx4
        dec     $0e
        beq     @a052
        brl     @9fb8
@a052:  shorta
        rts
@a055:  bpl     @a05a
        brl     @a0fc
@a05a:  longa
@a05c:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        eor     $c5
        inc
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8300,x
        sta     $7e8302,x
        eor     $c5
        inc
        sta     $7e8500,x
        sta     $7e8502,x
        phx
        lda     $56
        lsr2
        shorta
        sta     hWRMPYA
        sta     hWRMPYB
        longa
        nop2
        lda     hRDMPYL
        lsr2
        xba
        and     $c6
        asl5
        tax
        lda     $7ee000,x
        plx
        sta     $7e8800,x
        sta     $7e8802,x
        inx4
        dec     $0e
        beq     @a0f9
        brl     @a05c
@a0f9:  shorta
        rts
@a0fc:  and     #$7f
        beq     @a103
        brl     @a1a5
@a103:  longa
@a105:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        eor     $c5
        inc
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8500,x
        sta     $7e8502,x
        eor     $c5
        inc
        sta     $7e8300,x
        sta     $7e8302,x
        phx
        lda     $56
        lsr2
        shorta
        sta     hWRMPYA
        sta     hWRMPYB
        longa
        nop2
        lda     hRDMPYL
        lsr2
        xba
        and     $c6
        asl5
        tax
        lda     $7ee000,x
        plx
        sta     $7e8800,x
        sta     $7e8802,x
        inx4
        dec     $0e
        beq     @a1a2
        brl     @a105
@a1a2:  shorta
        rts
@a1a5:  longa
@a1a7:  lda     $0a
        adc     $5a
        xba
        sta     hWRDIVB
        xba
        sta     $0a
        shorta
        lda     $54
        sta     hWRMPYA
        ldy     hRDDIVL
        tya
        sta     hWRMPYB
        sty     $56
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8100,x
        sta     $7e8102,x
        lda     $55
        sta     hWRMPYA
        shorta
        lda     $57
        ldy     hRDMPYH
        sta     hWRMPYB
        sty     $08
        stz     $09
        longa
        lda     hRDMPYL
        adc     $08
        sta     $7e8500,x
        sta     $7e8502,x
        eor     $c5
        inc
        sta     $7e8300,x
        sta     $7e8302,x
        phx
        lda     $56
        lsr2
        shorta
        sta     hWRMPYA
        sta     hWRMPYB
        longa
        nop2
        lda     hRDMPYL
        lsr2
        xba
        and     $c6
        asl5
        tax
        lda     $7ee000,x
        plx
        sta     $7e8800,x
        sta     $7e8802,x
        inx4
        dec     $0e
        beq     @a241
        brl     @a1a7
@a241:  shorta
        rts

; ------------------------------------------------------------------------------

_7fa244:
        lda     #$60
        sta     $40
        lda     #$40
        sta     hDMA5::CTRL
        lda     #$42
        sta     hDMA6::CTRL
        lda     #<hCGADD
        sta     hDMA5::HREG
        lda     #<hCGDATA
        sta     hDMA6::HREG
        ldx     #$8080
        stx     hDMA5::ADDR
        ldx     #$8086
        stx     hDMA6::ADDR
        lda     #$7e
        sta     hDMA5::ADDR_B
        sta     hDMA6::ADDR_B
        sta     hDMA5::HDMA_B
        sta     hDMA6::HDMA_B
        lda     #$ff
        sta     $7e8080
        sta     $7e8086
        lda     #$e2
        sta     $7e8083
        sta     $7e8089
        longa
        lda     #$8900
        sta     $7e8081
        lda     #$8980
        sta     $7e8084
        lda     #$8a00
        sta     $7e8087
        lda     #$8b00
        sta     $7e808a
        ldx     $c7
        lda     $c7
@a2ac:  sta     $7e8900,x
        inx2
        cpx     #$0100
        bne     @a2ac
        ldx     #$00ca
        stx     $1c
        ldx     $c7
        lda     $7ff130
@a2c2:  sta     $7e8a00,x
        inx2
        cpx     $1c
        bne     @a2c2
        lda     $7ff132
        and     #$7c1f
        sta     $08
        lda     $7ff132
        and     #$03e0
        lsr5
        sta     $0a
        asl5
        ora     $08
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        inc     $0a
        lda     $0a
        asl5
        ora     $08
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        inc     $0a
        lda     $0a
        asl5
        ora     $08
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        lda     $1c
        clc
        adc     #$0018
        sta     $1c
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a343:  sta     $7e8a00,x
        inx2
        cpx     $1c
        bne     @a343
        lda     $1c
        clc
        adc     #$0008
        sta     $1c
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a360:  sta     $7e8a00,x
        inx2
        cpx     $1c
        bne     @a360
        lda     $1c
        clc
        adc     #$0008
        sta     $1c
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a37d:  sta     $7e8a00,x
        inx2
        cpx     $1c
        bne     @a37d
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a392:  sta     $7e8a00,x
        inx2
        cpx     #$0200
        bne     @a392
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa3a0:
        longa
        ldx     $c7
        lda     $7ff130
@a3a8:  sta     $7e8a00,x
        inx2
        cpx     #$0200
        bne     @a3a8
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa3b6:
        lda     #$60
        tsb     $40
        lda     #$40
        sta     hDMA5::CTRL
        lda     #$42
        sta     hDMA6::CTRL
        lda     #<hCGADD
        sta     hDMA5::HREG
        lda     #<hCGDATA
        sta     hDMA6::HREG
        ldx     #$8080
        stx     hDMA5::ADDR
        ldx     #$8086
        stx     hDMA6::ADDR
        lda     #$7e
        sta     hDMA5::ADDR_B
        sta     hDMA6::ADDR_B
        sta     hDMA5::HDMA_B
        sta     hDMA6::HDMA_B
        lda     #$ff
        sta     $7e8080
        sta     $7e8086
        lda     #$e2
        sta     $7e8083
        sta     $7e8089
        longa
        lda     #$8900
        sta     $7e8081
        lda     #$8980
        sta     $7e8084
        lda     #$8a00
        sta     $7e8087
        lda     #$8b00
        sta     $7e808a
        ldx     $c7
        lda     $c7
@a41e:  sta     $7e8900,x
        inx2
        cpx     #$0100
        bne     @a41e
        ldx     $c7
        lda     $7ff130
@a42f:  sta     $7e8a00,x
        inx2
        cpx     #$00f8
        bne     @a42f
        lda     #$3d00
        and     #$7c1f
        sta     $08
        lda     $7ff132
        and     #$03e0
        lsr5
        sta     $0a
        asl5
        ora     $08
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        inc     $0a
        lda     $0a
        asl5
        ora     $08
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        inc     $0a
        lda     $0a
        asl5
        ora     $08
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        sta     $7e8a00,x
        inx2
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a4a8:  sta     $7e8a00,x
        inx2
        cpx     #$0110
        bne     @a4a8
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a4be:  sta     $7e8a00,x
        inx2
        cpx     #$0118
        bne     @a4be
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a4d4:  sta     $7e8a00,x
        inx2
        cpx     #$0120
        bne     @a4d4
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a4ea:  sta     $7e8a00,x
        inx2
        cpx     #$0128
        bne     @a4ea
        inc     $0a
        lda     $0a
        asl5
        ora     $08
@a500:  sta     $7e8a00,x
        inx2
        cpx     #$0200
        bne     @a500
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa50e:
        lda     $62
        beq     @a51e
        dec     $62
        dec     $62
        dec     $64
        dec     $64
        inc     $60
        inc     $60
@a51e:  lda     $64
        beq     @a526
        dec     $64
        dec     $64
@a526:  rts

; ------------------------------------------------------------------------------

_7fa527:
        lda     $44
        bit     #$01
        bne     _a537
        ldx     $32
        cpx     #$01cf
        beq     _a537
        inx
        stx     $32
_a537:  rts

; ------------------------------------------------------------------------------

_7fa538:
        lda     $44
        bit     #$01
        bne     _a537
        ldx     $32
        cpx     #$01b8
        beq     @a548
        dex
        stx     $32
@a548:  rts

; ------------------------------------------------------------------------------

_7fa549:
        ldx     $30
        cpx     #$01ff
        beq     @a553
        inx
        stx     $30
@a553:  rts

; ------------------------------------------------------------------------------

_7fa554:
        ldx     $66
        beq     @a55c
        dex
        stx     $66
        rts
@a55c:  ldx     #$021c
        stx     $66
        rts

; ------------------------------------------------------------------------------

_7fa562:
        ldx     $68
        cpx     #$0100
        beq     @a56f
        inx4
        stx     $68
@a56f:  rts

; ------------------------------------------------------------------------------

_7fa570:
        lda     #$7f
        tsb     $40
        lda     #$42
        sta     hDMA1::CTRL
        sta     hDMA2::CTRL
        sta     hDMA3::CTRL
        lda     #$40
        sta     hDMA0::CTRL
        sta     hDMA4::CTRL
        sta     hDMA5::CTRL
        lda     #$42
        sta     hDMA6::CTRL
        lda     #<hCGADSUB
        sta     hDMA0::HREG
        lda     #<hM7D
        sta     hDMA1::HREG
        lda     #<hBG1VOFS
        sta     hDMA2::HREG
        lda     #<hBG1HOFS
        sta     hDMA3::HREG
        lda     #<hM7SEL
        sta     hDMA4::HREG
        lda     #<hCGADD
        sta     hDMA5::HREG
        lda     #<hCGDATA
        sta     hDMA6::HREG
        ldx     #$8000
        stx     hDMA0::ADDR
        ldx     #$8006
        stx     hDMA1::ADDR
        ldx     #$800c
        stx     hDMA2::ADDR
        ldx     #$8012
        stx     hDMA3::ADDR
        ldx     #$8018
        stx     hDMA4::ADDR
        ldx     #$801e
        stx     hDMA5::ADDR
        ldx     #$8024
        stx     hDMA6::ADDR
        lda     #$7e
        sta     hDMA0::ADDR_B
        sta     hDMA1::ADDR_B
        sta     hDMA2::ADDR_B
        sta     hDMA3::ADDR_B
        sta     hDMA4::ADDR_B
        sta     hDMA5::ADDR_B
        sta     hDMA6::ADDR_B
        sta     hDMA0::HDMA_B
        sta     hDMA1::HDMA_B
        sta     hDMA2::HDMA_B
        sta     hDMA3::HDMA_B
        sta     hDMA4::HDMA_B
        sta     hDMA5::HDMA_B
        sta     hDMA6::HDMA_B
        lda     #$ff
        sta     $7e8000
        sta     $7e8006
        sta     $7e800c
        sta     $7e8012
        sta     $7e8018
        sta     $7e801e
        sta     $7e8024
        lda     #$e2
        sta     $7e8003
        sta     $7e8009
        sta     $7e800f
        sta     $7e8015
        sta     $7e801b
        sta     $7e8021
        sta     $7e8027
        longa
        lda     #$8100
        sta     $7e8001
        lda     #$8180
        sta     $7e8004
        lda     #$8300
        sta     $7e8007
        lda     #$8400
        sta     $7e800a
        lda     #$8500
        sta     $7e800d
        lda     #$8600
        sta     $7e8010
        lda     #$8700
        sta     $7e8013
        lda     #$8800
        sta     $7e8016
        lda     #$8900
        sta     $7e8019
        lda     #$8980
        sta     $7e801c
        lda     #$8a00
        sta     $7e801f
        lda     #$8a80
        sta     $7e8022
        lda     #$8b00
        sta     $7e8025
        lda     #$8c00
        sta     $7e8028
        ldx     $c7
        txa
@a6ab:  sta     $7e8a00,x
        inx2
        cpx     #$0100
        bne     @a6ab
        lda     #$007e
        sta     $d5
        lda     #$8b00
        sta     $d3
        lda     $c7
        tay
@a6c3:  sta     [$d3],y
        iny2
        cpy     $60
        bne     @a6c3
        ldx     $c7
@a6cd:  lda     f:_7fc780,x
        sta     [$d3],y
        iny2
        cpx     $62
        beq     @a6dd
        inx2
        bra     @a6cd
@a6dd:  ldx     $64
@a6df:  lda     f:_7fc780,x
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        cpx     $c7
        beq     @a6f3
        dex2
        bra     @a6df
@a6f3:  lda     $c7
@a6f5:  sta     [$d3],y
        iny2
        cpy     #$0200
        bne     @a6f5
        ldx     $c7
        lda     #$3030
@a703:  sta     $7e8100,x
        inx2
        cpx     #$0060
        bne     @a703
        lda     #$7070
@a711:  sta     $7e8100,x
        inx2
        cpx     #$00b0
        bne     @a711
        lda     #$3030
@a71f:  sta     $7e8100,x
        inx2
        cpx     #$0200
        bne     @a71f
        ldx     $c7
        lda     #$c0c0
@a72f:  sta     $7e8900,x
        inx2
        cpx     #$0060
        bne     @a72f
        lda     #$c2c2
@a73d:  sta     $7e8900,x
        inx2
        cpx     #$0100
        bne     @a73d
        ldx     $c7
        lda     $32
@a74c:  sta     $7e8500,x
        inx2
        cpx     #$00c0
        bne     @a74c
        sec
        sbc     #$007a
@a75b:  sta     $7e8500,x
        inx2
        cpx     #$0200
        bne     @a75b
        ldx     $c7
        lda     $30
@a76a:  sta     $7e8700,x
        inx2
        cpx     #$0200
        bne     @a76a
        ldx     $c7
        lda     #$0100
@a77a:  sta     $7e8300,x
        inx2
        cpx     #$00c0
        bne     @a77a
        clc
        adc     #$0040
@a789:  sta     $7e8300,x
        inx2
        cpx     #$0200
        bne     @a789
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa797:
        longa
        ldx     $c7
        txa
@a79c:  sta     $7e8a00,x
        inx2
        cpx     #$0100
        bne     @a79c
        lda     #$007e
        sta     $d5
        lda     #$8b00
        sta     $d3
        lda     $7ff130
        ldy     $c7
@a7b7:  sta     [$d3],y
        iny2
        cpy     #$0200
        bne     @a7b7
        ldx     $c7
        lda     #$3030
@a7c5:  sta     $7e8100,x
        inx2
        cpx     #$0200
        bne     @a7c5
        ldx     $c7
        lda     #$c0c0
@a7d5:  sta     $7e8900,x
        inx2
        cpx     #$0100
        bne     @a7d5
        ldx     $c7
        lda     $32
@a7e4:  sta     $7e8500,x
        inx2
        cpx     #$0200
        bne     @a7e4
        ldx     $c7
        lda     $30
@a7f3:  sta     $7e8700,x
        inx2
        cpx     #$0200
        bne     @a7f3
        ldx     $c7
        lda     #$0100
@a803:  sta     $7e8300,x
        inx2
        cpx     #$0200
        bne     @a803
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa811:
        longa
        lda     #$007e
        sta     $d5
        lda     #$8b00
        sta     $d3
        lda     $c7
        tay
@a820:  sta     [$d3],y
        iny2
        cpy     $60
        bne     @a820
        ldx     $c7
@a82a:  lda     f:_7fc780,x
        sta     [$d3],y
        iny2
        cpx     $62
        beq     @a83a
        inx2
        bra     @a82a
@a83a:  ldx     $64
@a83c:  lda     f:_7fc780,x
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        cpx     $c7
        beq     @a858
        dex2
        bra     @a83c
@a858:  lda     $c7
@a85a:  sta     [$d3],y
        iny2
        cpy     #$0200
        bne     @a85a
        ldx     $c7
        lda     $32
@a867:  sta     $7e8500,x
        inx2
        cpx     #$00c0
        bne     @a867
        sec
        sbc     #$007a
@a876:  sta     $7e8500,x
        inx2
        cpx     #$0200
        bne     @a876
        ldx     $c7
        lda     $30
@a885:  sta     $7e8700,x
        inx2
        cpx     #$00c0
        bne     @a885
        sec
        sbc     #$0002
        sta     $68
        lda     #$007e
        sta     $d2
        lda     #$c000
        sta     $d0
        lda     $66
        tay
@a8a3:  lda     [$d0],y
        and     $c6
        lsr6
        clc
        adc     $68
        sta     $7e8700,x
        iny8
        inx2
        cpx     #$0200
        bne     @a8a3
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa8c6:
        longa
        lda     #$007e
        sta     $d5
        lda     #$8b00
        sta     $d3
        lda     $c7
        tay
@a8d5:  sta     [$d3],y
        iny2
        cpy     $60
        bne     @a8d5
        ldx     $c7
@a8df:  lda     f:_7fc780,x
        sta     [$d3],y
        iny2
        cpx     $62
        beq     @a8ef
        inx2
        bra     @a8df
@a8ef:  ldx     $64
@a8f1:  lda     f:_7fc780,x
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        sta     [$d3],y
        iny2
        cpx     $c7
        beq     @a90d
        dex2
        bra     @a8f1
@a90d:  lda     $c7
@a90f:  sta     [$d3],y
        iny2
        cpy     #$0200
        bne     @a90f
        ldx     $c7
        lda     $32
@a91c:  sta     $7e8500,x
        inx2
        cpx     #$00c0
        bne     @a91c
        sec
        sbc     #$007a
@a92b:  sta     $7e8500,x
        inx2
        cpx     #$0200
        bne     @a92b
        ldx     $c7
        lda     $30
@a93a:  sta     $7e8700,x
        inx2
        cpx     #$00c0
        bne     @a93a
@a945:  lda     $30
        clc
        adc     $68
        sta     $7e8700,x
        inx2
        lda     $30
        clc
        sbc     $68
        sta     $7e8700,x
        inx2
        cpx     #$0200
        bne     @a945
        shorta
        rts

; ------------------------------------------------------------------------------

_7fa963:
        lda     #^_c302b3
        sta     $d2
        ldx     #near _c302b3
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #^_c31d25
        sta     $d2
        ldx     #near _c31d25
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9020
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9020
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$e000
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #$7e
        sta     $d2
        ldx     #$91c0
        stx     $d0
        ldx     #$0020
        stx     $d6
        lda     #$7e
        sta     $d5
        ldx     #$f000
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #$7e
        sta     $d2
        ldx     #$9180
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$f400
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #^_c3331f
        sta     $d2
        ldx     #near _c3331f
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$e800
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9180
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$ec00
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #$7e
        sta     $d5
        ldx     #$91c0
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1e0
        lda     #$7e
        sta     $d5
        ldx     #$9180
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1e0
        lda     #$7e
        sta     $d2
        ldx     #$e800
        stx     $d0
        jsr     _7facab
        lda     #$7e
        sta     $d2
        ldx     #$ec00
        stx     $d0
        jsr     _7facab
        lda     #$7e
        sta     $d5
        ldx     #$f3e0
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1e0
        lda     #$7e
        sta     $d5
        ldx     #$f7e0
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1e0
        lda     #$7e
        sta     $d2
        ldx     #$f000
        stx     $d0
        jsr     _7fad0d
        lda     #$7e
        sta     $d2
        ldx     #$f400
        stx     $d0
        jsr     _7fad0d
        lda     #$7e
        sta     $d2
        ldx     #$9020
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$e000
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        ldx     #$e400
        stx     $d3
        jsr     _7fc1cc
        lda     #$7e
        sta     $d5
        ldx     #$e7e0
        stx     $d3
        longa
        lda     $c7
        ldy     $c7
        sta     [$d3],y
        iny2
        lda     $7e9000
        sta     $7ff130
@aac0:  sta     [$d3],y
        iny2
        cpy     #$0020
        bne     @aac0
        shorta
        lda     #$7e
        sta     $d2
        ldx     #$e400
        stx     $d0
        jsr     _7fad0d
        lda     $7e91ba
        sta     $7ff132
        lda     $7e91bb
        sta     $7ff133
        lda     #$00
        sta     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0200
        stx     $bd
        brl     _7fac54

; ------------------------------------------------------------------------------

_7faafc:
        lda     #^_c302b3
        sta     $d2
        ldx     #near _c302b3
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #^_c30663
        sta     $d2
        ldx     #near _c30663
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$00
        sta     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0200
        stx     $bd
        brl     _7fac54

; ------------------------------------------------------------------------------

_7fab3b:
        lda     #^_c302b3
        sta     $d2
        ldx     #near _c302b3
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #^_c34df8
        sta     $d2
        ldx     #near _c34df8
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$00
        sta     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0200
        stx     $bd
        jsr     _7fac54
; fallthrough

; ------------------------------------------------------------------------------

_7fab7a:
        longa
        lda     #$6e90
        sta     $7e9000
        shorta
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$e3e0
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #$7e
        sta     $d5
        ldx     #$e000
        stx     $d3
        jsr     _7fc1e0
        lda     #$7e
        sta     $d2
        ldx     #$e000
        stx     $d0
        jsr     _7fad0d
        lda     #$7e
        sta     $d2
        ldx     #$91c0
        stx     $d0
        ldx     #$0020
        stx     $d6
        lda     #$7e
        sta     $d5
        ldx     #$f000
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #$7e
        sta     $d2
        ldx     #$9180
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$f400
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1cc
        lda     #$7e
        sta     $d5
        ldx     #$f3e0
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1e0
        lda     #$7e
        sta     $d5
        ldx     #$f7e0
        stx     $d3
        ldx     #$0020
        stx     $d6
        jsr     _7fc1e0
        lda     #$7e
        sta     $d2
        ldx     #$f000
        stx     $d0
        jsr     _7fad0d
        lda     #$7e
        sta     $d2
        ldx     #$f400
        stx     $d0
        brl     _7fad0d

; ------------------------------------------------------------------------------

_7fac2a:
        lda     #^_c30d89
        sta     $d2
        ldx     #near _c30d89
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$80
        sta     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0040
        stx     $bd
        brl     _7fac54

; ------------------------------------------------------------------------------

_7fac54:
@ac54:  lda     $b8
        sta     hCGADD
        lda     #$00
        sta     hDMA7::CTRL
        lda     #<hCGDATA
        sta     hDMA7::HREG
        ldx     $ba
        stx     hDMA7::ADDR
        lda     $bc
        sta     hDMA7::ADDR_B
        ldx     $bd
        stx     hDMA7::SIZE
        lda     #$80
        sta     hMDMAEN
        rts

; ------------------------------------------------------------------------------

_7fac78:
        longa
        and     #$00ff
        asl
        tax
        lda     $7ff110,x
        sta     hDMA7::ADDR
        lda     $7ff120,x
        sta     hDMA7::SIZE
        shorta
        lda     $7ff101,x
        sta     hCGADD
        lda     #$00
        sta     hDMA7::CTRL
        lda     #<hCGDATA
        sta     hDMA7::HREG
        lda     #$7e
        sta     hDMA7::ADDR_B
        lda     #$80
        sta     hMDMAEN
        rts

; ------------------------------------------------------------------------------

_7facab:
@acab:  lda     $d2
        sta     $d5
        longa
        lda     $d0
        clc
        adc     #$0020
        sta     $d3
        ldy     $c7
@acbb:  lda     [$d0],y
        jsr     _7faccc
        sta     [$d3],y
        iny2
        cpy     #$03e0
        bne     @acbb
        shorta
        rts

; ------------------------------------------------------------------------------

_7faccc:
        .a16
@accc:  phy
        sta     $18
        and     #$001f
        beq     @acd5
        dec
@acd5:  sta     $1a
        lsr     $18
        lsr     $18
        lsr     $18
        lsr     $18
        lsr     $18
        lda     $18
        and     #$001f
        beq     @acf2
        dec
        asl5
        ora     $1a
        sta     $1a
@acf2:  lda     $18
        lsr5
        and     #$001f
        beq     @ad09
        dec
        asl8
        asl2
@ad09:  ora     $1a
        ply
        rts
        .a8

; ------------------------------------------------------------------------------

_7fad0d:
@ad0d:  lda     $d2
        sta     $d5
        longa
        ldx     #$0010
@ad16:  jsr     _7fad23
        inc     $d0
        inc     $d0
        dex
        bne     @ad16
        shorta
        rts

; ------------------------------------------------------------------------------

_7fad23:
        .a16
@ad23:  phx
        lda     $d0
        clc
        adc     #$03e0
        sta     $d3
        lda     [$d0]
        and     #$001f
        sta     $0c
        lda     [$d3]
        and     #$001f
        cmp     $0c
        bcs     @ad4c
        eor     $c5
        inc
        clc
        adc     $0c
        asl3
        eor     $c5
        inc
        sta     $86
        bra     @ad54
@ad4c:  sec
        sbc     $0c
        asl3
        sta     $86
@ad54:  lda     [$d0]
        and     #$03e0
        sta     $0c
        lda     [$d3]
        and     #$03e0
        cmp     $0c
        bcs     @ad73
        eor     $c5
        inc
        clc
        adc     $0c
        lsr2
        eor     $c5
        inc
        sta     $88
        bra     @ad7a
@ad73:  sec
        sbc     $0c
        lsr2
        sta     $88
@ad7a:  lda     [$d0]
        and     #$7c00
        sta     $0c
        lda     [$d3]
        and     #$7c00
        cmp     $0c
        bcs     @ad99
        eor     $c5
        inc
        clc
        adc     $0c
        xba
        asl
        eor     $c5
        inc
        sta     $8a
        bra     @ada0
@ad99:  sec
        sbc     $0c
        xba
        asl
        sta     $8a
@ada0:  lda     [$d0]
        pha
        and     #$001f
        xba
        sta     $80
        pla
        pha
        and     #$03e0
        asl3
        sta     $82
        pla
        and     #$7c00
        lsr2
        sta     $84
        lda     $d0
        clc
        adc     #$0020
        sta     $d3
        ldy     #$001f
@adc6:  lda     $80
        clc
        adc     $86
        sta     $80
        xba
        and     #$001f
        sta     $0a
        lda     $82
        clc
        adc     $88
        sta     $82
        lsr3
        and     #$03e0
        ora     $0a
        sta     $0a
        lda     $84
        clc
        adc     $8a
        sta     $84
        asl2
        and     #$7c00
        ora     $0a
        sta     [$d3]
        lda     $d3
        clc
        adc     #$0020
        sta     $d3
        dey
        bne     @adc6
        plx
        rts
        .a8

; ------------------------------------------------------------------------------

_7fae01:
        longa
        and     #$00ff
        asl
        tax
        xba
        asl
        clc
        adc     #$e000
        sta     $0a
        shorta
        lda     $c7
        sta     $7ff100,x
        longa
        lda     $7ff110,x
        cmp     $0a
        beq     @ae2a
        sec
        sbc     #$0020
        sta     $7ff110,x
@ae2a:  shorta
        rts

; ------------------------------------------------------------------------------

_7fae2d:
        lda     $7ff100,x
        inc
        sta     $7ff100,x
        rts

; ------------------------------------------------------------------------------

_7fae37:
        longa
        and     #$00ff
        asl
        tax
        xba
        asl
        clc
        adc     #$e3e0
        sta     $0a
        shorta
        lda     $c7
        sta     $7ff100,x
        longa
        lda     $7ff110,x
        cmp     $0a
        beq     @ae6d
        clc
        adc     #$0020
        sta     $7ff110,x
        shorta
        rts
        lda     $7ff100,x
        inc
        sta     $7ff100,x
        rts
@ae6d:  shorta
        rts

; ------------------------------------------------------------------------------

_7fae70:
        longa
        and     #$00ff
        asl
        tax
        xba
        asl
        clc
        adc     #$e3c0
        sta     $0a
        shorta
        lda     $7ff100,x
        cmp     #$02
        bcc     @aea4
        lda     $c7
        sta     $7ff100,x
        longa
        lda     $7ff110,x
        cmp     $0a
        beq     @aeae
        clc
        adc     #$0020
        sta     $7ff110,x
        shorta
        rts
@aea4:  lda     $7ff100,x
        inc
        sta     $7ff100,x
        rts
        .a16
@aeae:  txa
        xba
        asl
        clc
        adc     #$e000
        sta     $7ff110,x
        shorta
        rts

; ------------------------------------------------------------------------------

_7faebc:
        longa
        and     #$00ff
        asl
        tax
        xba
        asl
        clc
        adc     #$e3c0
        sta     $0a
        shorta
        lda     $7ff100,x
        cmp     #$01
        bcc     @aef0
        lda     $c7
        sta     $7ff100,x
        longa
        lda     $7ff110,x
        cmp     $0a
        beq     @aefa
        clc
        adc     #$0020
        sta     $7ff110,x
        shorta
        rts
@aef0:  lda     $7ff100,x
        inc
        sta     $7ff100,x
        rts
@aefa:  txa
        xba
        asl
        clc
        adc     #$00
        cpx     #$109f
        sbc     ($7f),y
        shorta
        rts

; ------------------------------------------------------------------------------

_7faf08:
        lda     $44
        and     #$0f
        sta     $18
        bne     @af1d
        lda     #$10
        sta     $8c
        stz     $8b
        stz     $8d
        lda     #$b1
        sta     $8e
        rts
@af1d:  cmp     #$01
        bne     @af2e
        lda     #$08
        sta     $8c
        stz     $8b
        stz     $8d
        lda     #$b1
        sta     $8e
        rts
@af2e:  cmp     #$02
        bne     @af3f
        lda     #$04
        stz     $8c
        sta     $8d
        stz     $8b
        lda     #$b1
        sta     $8e
        rts
@af3f:  cmp     #$03
        bne     @af50
        lda     #$02
        sta     $8c
        stz     $8d
        stz     $8b
        lda     #$b1
        sta     $8e
        rts
@af50:  cmp     #$04
        bne     @af61
        lda     #$10
        sta     $8c
        stz     $8d
        sta     $8b
        lda     #$b1
        sta     $8e
        rts
@af61:  cmp     #$05
        bne     @af70
        stz     $8d
        stz     $8b
        stz     $8c
        lda     #$31
        sta     $8e
        rts
@af70:  cmp     #$06
        bne     @af80
        lda     #$08
        sta     $8b
        sta     $8c
        sta     $8d
        lda     #$31
        sta     $8e
@af80:  rts

; ------------------------------------------------------------------------------

_7faf81:
        stz     $8d
        lda     #$71
        sta     $8e
        lda     $8c
        bne     @af95
        lda     $8b
        bne     @af92
        inc     $8c
        rts
@af92:  dec     $8b
        rts
@af95:  lda     $8b
        cmp     #$10
        bne     @af9e
        stz     $8c
        rts
@af9e:  inc     $8b
        rts

; ------------------------------------------------------------------------------

_7fafa1:
        lda     #$31
        sta     $8e
        lda     #$1f
        sta     $8b
        sta     $8d
        sta     $8c
        rts

; ------------------------------------------------------------------------------

_7fafae:
        lda     $8b
        beq     @afb4
        dec     $8b
@afb4:  lda     $8c
        beq     @afba
        dec     $8c
@afba:  lda     $8d
        beq     @afc0
        dec     $8d
@afc0:  rts

; ------------------------------------------------------------------------------

_7fafc1:
        ldx     #$021f
        lda     #$00
@afc6:  sta     $0200,x
        dex
        cpx     #$01ff
        bne     @afc6
@afcf:  lda     $c7
        sta     $0200,x
        dex
        sta     $0200,x
        dex
        lda     #$f0
        sta     $0200,x
        lda     $c7
        dex
        beq     @afe9
        sta     $0200,x
        dex
        bra     @afcf
@afe9:  sta     $0200
        rts

; ------------------------------------------------------------------------------

_7fafed:
        lda     #$22
        sta     hOBJSEL
        rts

; ------------------------------------------------------------------------------

_7faff3:
        lda     #$02
        sta     hOBJSEL
        rts

; ------------------------------------------------------------------------------

_7faff9:
        lda     #$62
        sta     hOBJSEL
        rts

; ------------------------------------------------------------------------------

_7fafff:
        .a16
        phx
        lda     $10
        and     #$00ff
        asl2
        tax
        lda     $14
        sta     $0200,x
        lda     $12
        sta     $0202,x
        lda     $10
        and     #$0007
        asl
        tax
        lda     f:_7fc7f0,x
        sta     $12
        lda     $10
        and     #$00ff
        lsr3
        asl
        tax
        lda     $0400,x
        and     $12
        ora     $16
        sta     $0400,x
        plx
        rts
        .a8

; ------------------------------------------------------------------------------

_7fb035:
        longa
        lda     $10
        and     $c6
        asl2
        tax
        shorta
        lda     $14
        sta     $0200,x
        rts

; ------------------------------------------------------------------------------

_7fb046:
        phx
        lda     $10
        and     $c6
        asl2
        tax
        lda     $0200,x
        shorta
        clc
        adc     $14
        xba
        clc
        adc     $15
        xba
        longa
        sta     $0200,x
        lda     $12
        sta     $0202,x
        plx
        rts

; ------------------------------------------------------------------------------

_7fb067:
@b067:  phx
        lda     $10
        asl2
        tax
        shorta
        lda     $0201,x
        cmp     #$f1
        beq     @b07e
        dec
        sta     $0201,x
        longa
        plx
        rts
@b07e:  lda     $0203,x
        and     #$9dcf
        ora     $02,s
        longa
        plx
        rts

; ------------------------------------------------------------------------------

_7fb08a:
@b08a:  phx
        lda     $10
        asl2
        tax
        shorta
        lda     $0201,x
        cmp     #$e8
        bcs     @b0a1
        inc
        sta     $0201,x
        longa
        plx
        rts
@b0a1:  lda     $0203,x
        and     #$9dcf
        ora     $02,s
        longa
        plx
        rts

; ------------------------------------------------------------------------------

_7fb0ad:
        phx
        lda     $10
        and     $c6
        sta     $10
        lsr3
        asl
        sta     $14
        lda     $10
        and     #$0007
        asl
        tax
        lda     f:_7fc7e0,x
        sta     $12
        ldx     $14
        lda     $0400,x
        and     $12
        bne     @b0f6
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        beq     @b0e4
        dec
        sta     $0200,x
        longa
        plx
        rts
@b0e4:  dec
        sta     $0200,x
        longa
        ldx     $14
        lda     $0400,x
        ora     $12
        sta     $0400,x
        plx
        rts
@b0f6:  longa
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        beq     @b10c
        dec
        sta     $0200,x
        longa
        plx
        rts
@b10c:  dec
        sta     $0200,x
        longa
        lda     $12
        eor     $c5
        sta     $12
        ldx     $14
        lda     $0400,x
        and     $12
        sta     $0400,x
        plx
        rts

; ------------------------------------------------------------------------------

_7fb124:
        phx
        lda     $10
        and     $c6
        sta     $10
        lsr3
        asl
        sta     $14
        lda     $10
        and     #$0007
        asl
        tax
        lda     f:_7fc7e0,x
        sta     $12
        ldx     $14
        lda     $0400,x
        and     $12
        bne     @b16f
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        cmp     $c6
        beq     @b15d
        inc
        sta     $0200,x
        longa
        plx
        rts
@b15d:  inc
        sta     $0200,x
        longa
        ldx     $14
        lda     $0400,x
        ora     $12
        sta     $0400,x
        plx
        rts
@b16f:  longa
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        cmp     $c6
        beq     @b187
        inc
        sta     $0200,x
        longa
        plx
        rts
@b187:  inc
        sta     $0200,x
        longa
        lda     $12
        eor     $c5
        sta     $12
        ldx     $14
        lda     $0400,x
        and     $12
        sta     $0400,x
        plx
        rts

; ------------------------------------------------------------------------------

_7fb19f:
        phx
        lda     $10
        lsr3
        asl
        sta     $14
        lda     $10
        and     #$0007
        asl
        tax
        lda     f:_7fc7e0,x
        sta     $12
        ldx     $14
        lda     $0400,x
        and     $12
        bne     @b1e5
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        beq     @b1d2
        dec
        sta     $0200,x
        longa
        plx
        rts
@b1d2:  lda     $c6
        sta     $0200,x
        longa
        ldx     $14
        lda     $0400,x
        ora     $12
        sta     $0400,x
        plx
        rts
@b1e5:  longa
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        cmp     #$f0
        beq     @b1fb
        dec
        sta     $0200,x
        longa
@b1fb:  plx
        rts

; ------------------------------------------------------------------------------

_7fb1fd:
        .a16
        phx
        lda     $10
        asl2
        tax
        shorta
        lda     $0200,x
        cmp     #$05
        beq     @b214
        dec
        sta     $0200,x
        longa
        plx
        rts
@b214:  .a8
        lda     #$e4
        sta     $0200,x
        longa
        plx
        rts
        .a8

; ------------------------------------------------------------------------------

_7fb21d:
        lda     #^_c32d22
        sta     $d2
        ldx     #near _c32d22
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$4000
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$1200
        stx     $bd
        jsr     _7fc1a3
        lda     #^_c31e83
        sta     $d2
        ldx     #near _c31e83
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$4c00
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$1800
        stx     $bd
        brl     _7fc1a3

; ------------------------------------------------------------------------------

_7fb273:
        lda     #^_c306f5
        sta     $d2
        ldx     #near _c306f5
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$4c00
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0800
        stx     $bd
        brl     _7fc1a3

; ------------------------------------------------------------------------------

_7fb29e:
        lda     #^_c309d2
        sta     $d2
        ldx     #near _c309d2
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$4000
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0800
        stx     $bd
        jsr     _7fc1a3
        lda     #^_c30e70
        sta     $d2
        ldx     #near _c30e70
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$f200
        stx     $d3
        jsr     _7fc00d
        longa
        lda     #$f200
        sta     $7ff180
        shorta
        lda     #^_c30f4a
        sta     $d2
        ldx     #near _c30f4a
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$e800
        stx     $d3
        jsr     _7fc00d
        longa
        lda     #$e800
        sta     $7ff182
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb30a:
        lda     #^_c372e7
        sta     $d2
        ldx     #near _c372e7
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$5c00
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$0400
        stx     $bd
        brl     _7fc1a3

; ------------------------------------------------------------------------------

_7fb335:
        lda     #^_c366d8
        sta     $d2
        ldx     #near _c366d8
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        ldx     #$4c00
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$9000
        stx     $ba
        ldx     #$2000
        stx     $bd
        brl     _7fc1a3

; ------------------------------------------------------------------------------

_7fb360:
        lda     #^_c31e83
        sta     $d2
        ldx     #near _c31e83
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$0000
        stx     $d3
        brl     _7fc00d

; ------------------------------------------------------------------------------

_7fb375:
        lda     #^_c35b1e
        sta     $d2
        ldx     #near _c35b1e
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$2000
        stx     $d3
        brl     _7fc00d

; ------------------------------------------------------------------------------

_7fb38a:
        lda     #<hVMDATAL
        sta     $b4
        lda     #$01
        sta     $b3
        ldx     #$4c00
        stx     $ac
        ldx     #$0000
        stx     $ae
        lda     #$7f
        sta     $b0
        ldx     #$1000
        stx     $b1
        rts

; ------------------------------------------------------------------------------

_7fb3a6:
        lda     #<hVMDATAL
        sta     $b4
        lda     #$01
        sta     $b3
        ldx     #$5400
        stx     $ac
        ldx     #$1000
        stx     $ae
        lda     #$7f
        sta     $b0
        ldx     #$1000
        stx     $b1
        rts

; ------------------------------------------------------------------------------

_7fb3c2:
        lda     #<hVMDATAL
        sta     $b4
        lda     #$01
        sta     $b3
        ldx     #$4c00
        stx     $ac
        ldx     #$2000
        stx     $ae
        lda     #$7f
        sta     $b0
        ldx     #$1000
        stx     $b1
        rts

; ------------------------------------------------------------------------------

_7fb3de:
        lda     #<hVMDATAL
        sta     $b4
        lda     #$01
        sta     $b3
        ldx     #$5400
        stx     $ac
        ldx     #$3000
        stx     $ae
        lda     #$7f
        sta     $b0
        ldx     #$1000
        stx     $b1
        rts

; ------------------------------------------------------------------------------

_7fb3fa:
        lda     #^_c31d48
        sta     $d2
        ldx     #near _c31d48
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        brl     _7fbaa9

; ------------------------------------------------------------------------------

_7fb41b:
        lda     #^_c30e1b
        sta     $d2
        ldx     #near _c30e1b
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        brl     _7fbaa9

; ------------------------------------------------------------------------------

_7fb43c:
        lda     #^_c30da3
        sta     $d2
        ldx     #near _c30da3
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        brl     _7fbaa9

; ------------------------------------------------------------------------------

_7fb45d:
        lda     #^_c30f70
        sta     $d2
        ldx     #near _c30f70
        stx     $d0
        lda     #$7f
        sta     $d5
        ldx     #$f200
        stx     $d3
        jsr     _7fc00d
        longa
        lda     #$f200
        sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb47e:
        lda     #^_c3067c
        sta     $d2
        ldx     #near _c3067c
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        brl     _7fbaa9

; ------------------------------------------------------------------------------

_7fb49f:
        lda     #^_c37a07
        sta     $d2
        ldx     #near _c37a07
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        jsr     _7fbaa9
        lda     #^_c37a69
        sta     $d2
        ldx     #near _c37a69
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$7000
        stx     $d3
        jsr     _7fc00d
        longa
        lda     #$7000
        sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb4e1:
        lda     #^_c37445
        sta     $d2
        ldx     #near _c37445
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        jsr     _7fbaa9
        lda     #^_c3750d
        sta     $d2
        ldx     #near _c3750d
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$7000
        stx     $d3
        jsr     _7fc00d
        longa
        lda     #$7000
        sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb523:
        lda     #^_c3759a
        sta     $d2
        ldx     #near _c3759a
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        jsr     _7fbaa9
        longa
        lda     #$6800
        sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb550:
        lda     #^_c3765c
        sta     $d2
        ldx     #near _c3765c
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$6800
        stx     $d3
        jsr     _7fc00d
        rts

; ------------------------------------------------------------------------------

_7fb566:
        lda     #^_c377ae
        sta     $d2
        ldx     #near _c377ae
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        jsr     _7fbaa9
        longa
        lda     #$6000
        sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb593:
        lda     #^_c37891
        sta     $d2
        ldx     #near _c37891
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$6000
        stx     $d3
        jsr     _7fc00d
        rts

; ------------------------------------------------------------------------------

_7fb5a9:
        lda     #^_c33342
        sta     $d2
        ldx     #near _c33342
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        jsr     _7fbaa9
        lda     #^_c31dfe
        sta     $d2
        ldx     #near _c31dfe
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$7000
        stx     $d3
        jsr     _7fc00d
        longa
        lda     #$7000
        sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb5eb:
        jsr     _7fb8c0
        jsr     _7fb8c0
        jsr     _7fb8c0
        jsr     _7fb8d9
        lda     $46
        cmp     #$01
        bne     @b602
        jsr     _7fb7bf
        bra     @b626
@b602:  cmp     #$02
        bne     @b60e
        jsr     _7fb8a7
        jsr     _7fb729
        bra     @b626
@b60e:  cmp     #$03
        bne     @b61a
        jsr     _7fb742
        jsr     _7fb7a6
        bra     @b626
@b61a:  cmp     #$04
        bne     @b626
        jsr     _7fb6ac
        jsr     _7fb8a7
        stz     $46
@b626:  inc     $46
        rts

; ------------------------------------------------------------------------------

_7fb629:
        jsr     _7fb8c0
        jsr     _7fb8c0
        jsr     _7fb8c0
        jsr     _7fb8d9
        lda     $46
        cmp     #$01
        bne     @b640
        jsr     _7fb7bf
        bra     @b664
@b640:  cmp     #$02
        bne     @b64c
        jsr     _7fb8a7
        jsr     _7fb75b
        bra     @b664
@b64c:  cmp     #$03
        bne     @b658
        jsr     _7fb78d
        jsr     _7fb774
        bra     @b664
@b658:  cmp     #$04
        bne     @b664
        jsr     _7fb710
        jsr     _7fb8a7
        stz     $46
@b664:  inc     $46
        rts

; ------------------------------------------------------------------------------

_7fb667:
        jsr     _7fb8c0
        jsr     _7fb8c0
        jsr     _7fb8c0
        jsr     _7fb8d9
        lda     $46
        cmp     #$01
        bne     @b67e
        jsr     _7fb7bf
        bra     @b690
@b67e:  cmp     #$02
        bne     @b687
        jsr     _7fb8a7
        bra     @b690
@b687:  cmp     #$04
        bne     @b690
        jsr     _7fb8a7
        stz     $46
@b690:  inc     $46
        rts

; ------------------------------------------------------------------------------

_7fb693:
        longa
        lda     #$0030
        sta     $10
@b69a:  jsr     _7fb067
        inc     $10
        lda     $10
        cmp     #$004d
        bne     @b69a
        jsr     _7fb067
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb6ac:
@b6ac:  longa
        lda     #$0064
        sta     $10
@b6b3:  jsr     _7fb067
        inc     $10
        lda     $10
        cmp     #$007f
        bne     @b6b3
        jsr     _7fb067
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb6c5:
        longa
        lda     #$0049
        sta     $10
@b6cc:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$0068
        bne     @b6cc
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb6de:
        longa
        lda     #$0030
        sta     $10
@b6e5:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$004d
        bne     @b6e5
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb6f7:
        longa
        lda     #$0060
        sta     $10
@b6fe:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$0065
        bne     @b6fe
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb710:
@b710:  longa
        lda     #$0064
        sta     $10
@b717:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$007f
        bne     @b717
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb729:
@b729:  longa
        lda     #$0030
        sta     $10
@b730:  jsr     _7fb067
        inc     $10
        lda     $10
        cmp     #$0043
        bne     @b730
        jsr     _7fb067
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb742:
@b742:  longa
        lda     #$004c
        sta     $10
@b749:  jsr     _7fb067
        inc     $10
        lda     $10
        cmp     #$0063
        bne     @b749
        jsr     _7fb067
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb75b:
@b75b:  longa
        lda     #$0030
        sta     $10
@b762:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$0043
        bne     @b762
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb774:
@b774:  longa
        lda     #$004c
        sta     $10
@b77b:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$0063
        bne     @b77b
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb78d:
@b78d:  longa
        lda     #$0046
        sta     $10
@b794:  jsr     _7fb08a
        inc     $10
        lda     $10
        cmp     #$004b
        bne     @b794
        jsr     _7fb08a
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb7a6:
@b7a6:  longa
        lda     #$0046
        sta     $10
@b7ad:  jsr     _7fb067
        inc     $10
        lda     $10
        cmp     #$004b
        bne     @b7ad
        jsr     _7fb067
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb7bf:
@b7bf:  lda     #$7e
        sta     $d2
        longa
        lda     $7ff180
        sta     $d0
        shorta
        jsr     _7fbb00
        longa
        bcs     @b7d9
        lda     #$7000
        bra     @b7db
@b7d9:  lda     $d0
@b7db:  sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb7e2:
        lda     #$7e
        sta     $d2
        longa
        lda     $7ff180
        sta     $d0
        shorta
        jsr     _7fbb00
        longa
        bcs     @b7fc
        lda     #$6000
        bra     @b7fe
@b7fc:  lda     $d0
@b7fe:  sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb805:
        lda     #$7e
        sta     $d2
        longa
        lda     $7ff180
        sta     $d0
        shorta
        jsr     _7fbb00
        longa
        bcs     @b81f
        lda     #$6800
        bra     @b821
@b81f:  lda     $d0
@b821:  sta     $7ff180
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb828:
        lda     #$7f
        sta     $d2
        longa
        lda     $7ff180
        sta     $d0
        shorta
        jsr     _7fbb00
        bcc     @b845
        longa
        lda     $d0
        sta     $7ff180
        shorta
@b845:  rts

; ------------------------------------------------------------------------------

_7fb846:
        longa
        lda     #$0030
        sta     $10
@b84d:  jsr     _7fb0ad
        inc     $10
        lda     $10
        cmp     #$0036
        bne     @b84d
        jsr     _7fb0ad
        lda     #$0037
        sta     $10
@b861:  jsr     _7fb124
        inc     $10
        lda     $10
        cmp     #$0040
        bne     @b861
        jsr     _7fb124
        lda     $44
        and     #$0001
        bne     @b88b
        lda     #$0041
        sta     $10
@b87c:  jsr     _7fb0ad
        inc     $10
        lda     $10
        cmp     #$004a
        bne     @b87c
        jsr     _7fb0ad
@b88b:  shorta
        rts

; ------------------------------------------------------------------------------

_7fb88e:
        longa
        lda     #$0070
        sta     $10
@b895:  jsr     _7fb0ad
        inc     $10
        lda     $10
        cmp     #$0072
        bne     @b895
        jsr     _7fb0ad
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb8a7:
        longa
        lda     #$0064
        sta     $10
@b8ae:  jsr     _7fb1fd
        inc     $10
        lda     $10
        cmp     #$007f
        bne     @b8ae
        jsr     _7fb1fd
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb8c0:
        longa
        lda     #$0030
        sta     $10
@b8c7:  jsr     _7fb1fd
        inc     $10
        lda     $10
        cmp     #$0043
        bne     @b8c7
        jsr     _7fb1fd
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb8d9:
        longa
        lda     #$004c
        sta     $10
@b8e0:  jsr     _7fb1fd
        inc     $10
        lda     $10
        cmp     #$0063
        bne     @b8e0
        jsr     _7fb1fd
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb8f2:
        lda     $44
        and     #$07
        bne     @b915
        xba
        lda     $46
        tax
        lda     f:RNGTbl,x   ; random number table
        and     #$07
        tax
        lda     f:_7fc7b8,x
        sta     $ca
        txa
        asl
        tax
        lda     $60,x
        cmp     $ca
        beq     @b915
        inc
        sta     $60,x
@b915:  longa
        lda     #$0030
        sta     $10
@b91c:  jsr     _7fb067
        jsr     _7fb067
        lda     $10
        cmp     $60
        beq     @b92c
        inc     $10
        bra     @b91c
@b92c:  lda     #$0038
        sta     $10
@b931:  jsr     _7fb067
        jsr     _7fb067
        jsr     _7fb124
        lda     $10
        cmp     $62
        beq     @b944
        inc     $10
        bra     @b931
@b944:  lda     #$0040
        sta     $10
@b949:  jsr     _7fb067
        lda     $10
        cmp     $64
        beq     @b956
        inc     $10
        bra     @b949
@b956:  lda     #$0048
        sta     $10
@b95b:  jsr     _7fb067
        jsr     _7fb124
        jsr     _7fb124
        lda     $10
        cmp     $66
        beq     @b96e
        inc     $10
        bra     @b95b
@b96e:  lda     $44
        and     #$0001
        bne     @b9c9
        lda     #$0050
        sta     $10
@b97a:  jsr     _7fb067
        lda     $10
        cmp     $68
        beq     @b987
        inc     $10
        bra     @b97a
@b987:  lda     #$0058
        sta     $10
@b98c:  jsr     _7fb124
        jsr     _7fb067
        lda     $10
        cmp     $6a
        beq     @b99c
        inc     $10
        bra     @b98c
@b99c:  lda     #$0060
        sta     $10
@b9a1:  jsr     _7fb124
        jsr     _7fb067
        lda     $10
        cmp     $6c
        beq     @b9b1
        inc     $10
        bra     @b9a1
@b9b1:  lda     #$0068
        sta     $10
@b9b6:  jsr     _7fb124
        jsr     _7fb124
        jsr     _7fb067
        lda     $10
        cmp     $6e
        beq     @b9c9
        inc     $10
        bra     @b9b6
@b9c9:  shorta
        rts

; ------------------------------------------------------------------------------

_7fb9cc:
        longa
        lda     #$0060
        sta     $10
@b9d3:  jsr     _7fb0ad
        inc     $10
        lda     $10
        cmp     #$0071
        bne     @b9d3
        jsr     _7fb0ad
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb9e5:
        longa
        lda     #$0030
        sta     $10
@b9ec:  jsr     _7fb0ad
        inc     $10
        lda     $10
        cmp     #$003e
        bne     @b9ec
        jsr     _7fb0ad
        shorta
        rts

; ------------------------------------------------------------------------------

_7fb9fe:
        longa
        lda     #$0060
        sta     $10
@ba05:  jsr     _7fb124
        inc     $10
        lda     $10
        cmp     #$0074
        bne     @ba05
        jsr     _7fb124
        shorta
        rts

; ------------------------------------------------------------------------------

_7fba17:
        longa
        lda     #$0030
        sta     $10
@ba1e:  jsr     _7fb124
        lda     $44
        and     #$0003
        bne     @ba2b
        jsr     _7fb08a
@ba2b:  inc     $10
        lda     $10
        cmp     #$0040
        bne     @ba1e
        lda     $44
        and     #$0003
        bne     @ba3e
        jsr     _7fb08a
@ba3e:  jsr     _7fb124
        shorta
        rts

; ------------------------------------------------------------------------------

_7fba44:
        longa
        lda     #$0030
        sta     $10
@ba4b:  jsr     _7fb124
        inc     $10
        lda     $10
        cmp     #$004d
        bne     @ba4b
        jsr     _7fb124
        shorta
        rts

; ------------------------------------------------------------------------------

_7fba5d:
        lda     $44
        and     #$03
        bne     @ba85
        lda     #$7f
        sta     $d2
        longa
        lda     $7ff180
        sta     $d0
        shorta
        jsr     _7fbb00
        longa
        bcs     @ba7d
        lda     #$f200
        bra     @ba7f
@ba7d:  lda     $d0
@ba7f:  sta     $7ff180
        shorta
@ba85:  rts

; ------------------------------------------------------------------------------

_7fba86:
        lda     #$7f
        sta     $d2
        longa
        lda     $7ff182
        sta     $d0
        shorta
        jsr     _7fbb00
        longa
        bcs     @baa0
        lda     #$e800
        bra     @baa2
@baa0:  lda     $d0
@baa2:  sta     $7ff182
        shorta
        rts

; ------------------------------------------------------------------------------

_7fbaa9:
@baa9:  ldy     $c7
        longa
@baad:  lda     [$d0],y
        bit     #$0080
        beq     @babe
        and     $c6
        cmp     #$008f
        beq     @bad8
        shorta
        rts
@babe:  .a16
        sta     $10
        iny
        lda     [$d0],y
        sta     $14
        iny2
        lda     [$d0],y
        sta     $12
        iny2
        lda     [$d0],y
        sta     $16
        iny2
        jsr     _7fafff
        bra     @baad
@bad8:  shorta
        inc     $10
        iny
        lda     [$d0],y
        clc
        adc     $14
        sta     $14
        iny
        lda     [$d0],y
        clc
        adc     $15
        sta     $15
        iny
        longa
        lda     [$d0],y
        sta     $12
        iny2
        lda     [$d0],y
        sta     $16
        iny2
        jsr     _7fafff
        bra     @baad
        .a8

; ------------------------------------------------------------------------------

_7fbb00:
@bb00:  ldy     $c7
@bb02:  lda     [$d0],y
        bpl     @bb61
        bit     #$40
        bne     @bb2e
        cmp     #$8f
        bne     @bb14
        inc     $10
        longa
        bra     @bb65
@bb14:  .a8
        cmp     #$82
        bne     @bb1e
        jsr     _7fafa1
        iny
        bra     @bb02
@bb1e:  pha
        iny
        longa
        tya
        clc
        adc     $d0
        sta     $d0
        shorta
        pla
        cmp     #$81
        rts
@bb2e:  bit     #$20
        bne     @bb46
        longa
        and     #$0007
        asl
        tax
        iny
        tya
        clc
        adc     $d0
        sta     $7ff138,x
        shorta
        bra     @bb02
@bb46:  ldx     $d0
        phx
        longa
        and     #$0007
        asl
        tax
        lda     $7ff138,x
        sta     $d0
        shorta
        jsr     _7fbb00
        plx
        inx
        stx     $d0
        sec
        rts
@bb61:  longa
        sta     $10
@bb65:  iny
        lda     [$d0],y
        sta     $14
        iny2
        lda     [$d0],y
        sta     $12
        iny2
        jsr     _7fb046
        shorta
        bra     @bb02

; ------------------------------------------------------------------------------

_7fbb79:
        lda     #$7e
        sta     $28
        ldx     #$d000
        stx     $26
        ldx     $c7
        stx     $22
        lda     #^_c3362b
        sta     $d2
        ldx     #near _c3362b
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$d000
        stx     $d3
        jsr     _7fc00d
        lda     #^_c333f6
        sta     $d2
        ldx     #near _c333f6
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$4800
        stx     $d3
        brl     _7fc00d

; ------------------------------------------------------------------------------

_7fbbb0:
        ldx     #$2000
        stx     $d3
        lda     #$7e
        sta     $d5
        ldx     #$0800
        stx     $d6
        jsr     _7fc1e0
        lda     #$27
        sta     $20
        lda     #$10
        tsb     $4f
        rts

; ------------------------------------------------------------------------------

_7fbbca:
        ldx     #$2800
        stx     $d3
        lda     #$7e
        sta     $d5
        ldx     #$0800
        stx     $d6
        jsr     _7fc1e0
        lda     #$20
        tsb     $4f
        lda     #$10
        trb     $4f
        rts

; ------------------------------------------------------------------------------

_7fbbe4:
        ldx     #$3000
        stx     $d3
        lda     #$7e
        sta     $d5
        ldx     #$0800
        stx     $d6
        jsr     _7fc1e0
        lda     #$40
        tsb     $4f
        lda     #$20
        trb     $4f
        rts

; ------------------------------------------------------------------------------

_7fbbfe:
        lda     #$7e
        sta     $28
        ldx     #$d000
        stx     $26
        lda     #^_c37b92
        sta     $d2
        ldx     #near _c37b92
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$d000
        stx     $d3
        jsr     _7fc00d
        jsr     _7fbc3e
        ldx     #$4000
        stx     $b8
        lda     #$7e
        sta     $bc
        ldx     #$4800
        stx     $ba
        ldx     #$1000
        stx     $bd
        jsr     _7fc1a3
        lda     #$40
        sta     $7e
        stz     $25
        stz     $22
        rts

; ------------------------------------------------------------------------------

_7fbc3e:
@bc3e:  phb
        lda     #$7e
        pha
        plb
        ldx     #$4800
        stx     $c0
        ldx     $c7
        txy
@bc4b:  inx
        lda     f:SmallFontGfx+$01f0,x
        sta     ($c0),y
        iny
        lda     $c7
        sta     ($c0),y
        iny
        inx
        txa
        and     #$0f
        bne     @bc4b
@bc5e:  lda     $c7
        sta     ($c0),y
        iny
        cpy     #$1000
        beq     @bc6f
        tya
        and     #$0f
        bne     @bc5e
        bra     @bc4b
@bc6f:  plb
        rts

; ------------------------------------------------------------------------------

_7fbc71:
@bc71:  pha
        lda     #$10
        ora     #$20
        ora     #$40
        ora     #$80
        trb     $4f
        pla
        cmp     #$00
        bne     @bc85
        lda     #$10
        bra     @bc95
@bc85:  cmp     #$01
        bne     @bc8d
        lda     #$20
        bra     @bc95
@bc8d:  cmp     #$02
        bne     @bc97
        lda     #$40
        bra     @bc95
@bc95:  tsb     $4f
@bc97:  inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbc9a:
@bc9a:  longa
        and     #$00ff
        xba
        asl2
        sta     $08
        asl
        clc
        adc     #$2000
        sta     hDMA7::ADDR
        lda     #$0800
        sta     hDMA7::SIZE
        lda     $08
        clc
        adc     #$4000
        sta     hVMADDL
        shorta
        lda     #$01
        sta     hDMA7::CTRL
        lda     #<hVMDATAL
        sta     hDMA7::HREG
        lda     #$7e
        sta     hDMA7::ADDR_B
        lda     #$80
        sta     hVMAINC
        lda     #$80
        sta     hMDMAEN
        rts

; ------------------------------------------------------------------------------

_7fbcd7:
@bcd7:  sta     $24
        longa
        and     $c6
        asl
        tax
        lda     f:_7fc7b0,x
        lsr5
        sta     $22
        shorta
        stz     $25
        lda     [$26]
        and     #$0f
        bne     @bcf9
        stz     $20
        stz     $21
        rts
@bcf9:  ldx     $26
        inx
        stx     $26
        lda     [$26]
        bpl     @bd1d
        cmp     #$86
        bne     @bd17
        ldx     $26
        inx
        stx     $26
        ldx     $c7
        stx     $22
        jsr     _7fbfaf
        lda     #$08
        sta     $20
        rts
@bd17:  jsr     _7fbfaf
        inc     $20
        rts
@bd1d:  bne     @bd25
        inc     $22
        inc     $25
        bra     @bcf9
@bd25:  jsr     _7fbdb3
        bra     @bcf9

; ------------------------------------------------------------------------------

_7fbd2a:
@bd2a:  lda     [$26]
        and     #$0f
        bne     @bd35
        stz     $20
        stz     $21
        rts
@bd35:  ldx     $26
        inx
        stx     $26
        lda     [$26]
        bpl     @bd63
        cmp     #$86
        bne     @bd55
        ldx     $26
        inx
        stx     $26
        jsr     _7fbd88
        stz     $22
        stz     $25
        lda     #$40
        sta     $7e
        inc     $20
        rts
@bd55:  jsr     _7fbd88
        stz     $25
        lda     $7e
        clc
        adc     #$0c
        sta     $7e
        bra     @bd2a
@bd63:  jsr     _7fbd6c
        inc     $22
        inc     $25
        bra     @bd35

; ------------------------------------------------------------------------------

_7fbd6c:
@bd6c:  longa
        and     $c6
        ora     #$3800
        sta     $12
        lda     $22
        sta     $10
        lda     $c7
        sta     $16
        lda     $7e
        xba
        sta     $14
        jsr     _7fafff
        shorta
        rts

; ------------------------------------------------------------------------------

_7fbd88:
@bd88:  lda     $25
        asl3
        sta     $18
        lda     #$ff
        sec
        sbc     $18
        lsr
        sta     $14
        lda     $22
        sec
        sbc     $25
        sta     $10
@bd9e:  jsr     _7fb035
        lda     $10
        cmp     $22
        beq     @bdb2
        lda     $14
        clc
        adc     #$08
        sta     $14
        inc     $10
        bra     @bd9e
@bdb2:  rts

; ------------------------------------------------------------------------------

_7fbdb3:
@bdb3:  longa
        and     $c6
        sta     $18
        lsr4
        asl8
        asl2
        sta     $1e
        lda     $18
        and     #$000f
        asl5
        clc
        adc     $1e
        clc
        adc     #$4800
        sta     $d0
        lda     $22
        lsr4
        asl8
        asl2
        sta     $1e
        lda     $22
        and     #$000f
        asl5
        clc
        adc     $1e
        clc
        adc     #$2000
        sta     $d3
        lda     #$0020
        sta     $d6
        shorta
        lda     #$7e
        sta     $d2
        lda     #$7e
        sta     $d5
        jsr     _7fc1cc
        longa
        lda     $d0
        clc
        adc     #$0200
        sta     $d0
        lda     $d3
        clc
        adc     #$0200
        sta     $d3
        lda     #$0020
        sta     $d6
        inc     $22
        shorta
        jsr     _7fc1cc
        inc     $25
        rts

; ------------------------------------------------------------------------------

_7fbe34:
        lda     #^_c3383c
        sta     $d2
        ldx     #near _c3383c
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$9000
        stx     $d3
        jsr     _7fc00d
        lda     #$7e
        sta     $d2
        ldx     #$9000
        stx     $d0
        brl     _7fbaa9

; ------------------------------------------------------------------------------

_7fbe55:
@be55:  longa
        and     $c6
        cmp     #$0003
        beq     @be79
        xba
        asl3
        clc
        adc     #$2000
        sta     $d3
        shorta
        lda     #$7e
        sta     $d5
        ldx     #$0800
        stx     $d6
        jsr     _7fc1e0
        inc     $20
        rts
@be79:  shorta
        inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbe7e:
        lda     $44
        and     #$01
        beq     _7fbe85
        rts

; ------------------------------------------------------------------------------

_7fbe85:
@be85:  lda     #$01
        sta     $2a
        lda     $20
        cmp     #$04
        bcs     @be92
        brl     _7fbe55
@be92:  cmp     #$08
        bne     @be99
        brl     _7fbf3b
@be99:  bcs     @bea1
        sec
        sbc     #$04
        brl     _7fbcd7
@bea1:  cmp     #$27
        bcs     @bea8
        brl     _7fbf1b
@bea8:  cmp     #$2a
        bcs     @beb8
        sec
        sbc     #$27
        jsr     _7fbc71
        jsr     _7fbfc8
        stz     $2a
        rts
@beb8:  cmp     #$2a
        bne     @bebf
        brl     _7fbf70
@bebf:  cmp     #$ff
        bne     @bec6
        inc     $20
        rts
@bec6:  cmp     #$50
        bcc     @becc
        stz     $2a
@becc:  jsr     _7fbf28
        inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbed2:
        lda     $44
        and     #$01
        bne     @bee3
        lda     #$01
        sta     $2a
        lda     $20
        bne     @bee4
        jsr     _7fbf3b
@bee3:  rts
@bee4:  cmp     #$20
        bcs     @beeb
        brl     _7fbf1b
@beeb:  cmp     #$20
        bne     @bef7
        jsr     _7fafc1
        stz     $2a
        inc     $20
        rts
@bef7:  cmp     #$21
        bne     @bf01
        jsr     _7fbd2a
        stz     $2a
        rts
@bf01:  cmp     #$22
        bne     @bf08
        brl     _7fbf70
@bf08:  cmp     #$ff
        bne     @bf0f
        inc     $20
        rts
@bf0f:  cmp     #$52
        bcc     @bf15
        stz     $2a
@bf15:  jsr     _7fbf28
        inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbf1b:
@bf1b:  lda     #$04
        jsr     _7fae37
        lda     #$05
        jsr     _7fae37
        inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbf28:
@bf28:  lda     #$04
        jsr     _7fae01
        lda     #$05
        jsr     _7fae01
        lda     $44
        and     #$07
        bne     @bf3a
        inc     $20
@bf3a:  rts

; ------------------------------------------------------------------------------

_7fbf3b:
@bf3b:  lda     #$e0
        sta     $7ff109
        lda     #$c0
        sta     $7ff10b
        longa
        lda     #$f000
        sta     $7ff118
        lda     #$0020
        sta     $7ff128
        lda     #$f400
        sta     $7ff11a
        lda     #$0020
        sta     $7ff12a
        shorta
        lda     #$10
        ora     #$20
        tsb     $74
        inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbf70:
@bf70:  lda     #$10
        ora     #$20
        ora     #$40
        ora     #$80
        trb     $4f
        lda     #$e0
        sta     $7ff109
        lda     #$c0
        sta     $7ff10b
        longa
        lda     #$f3e0
        sta     $7ff118
        lda     #$0020
        sta     $7ff128
        lda     #$f7e0
        sta     $7ff11a
        lda     #$0020
        sta     $7ff12a
        shorta
        lda     #$10
        ora     #$20
        tsb     $74
        inc     $20
        rts

; ------------------------------------------------------------------------------

_7fbfaf:
@bfaf:  lda     $24
        shorti
        tax
        lda     $25
        asl3
        sta     $18
        lda     $c6
        sec
        sbc     $18
        lsr
        sta     $7ff134,x
        longi
        rts

; ------------------------------------------------------------------------------

_7fbfc8:
@bfc8:  lda     #$00
        sta     $24
        lda     $7ff134
        jsr     _7fbff4
        lda     #$0c
        sta     $24
        lda     $7ff135
        jsr     _7fbff4
        lda     #$18
        sta     $24
        lda     $7ff136
        jsr     _7fbff4
        lda     #$24
        sta     $24
        lda     $7ff137
        brl     _7fbff4

; ------------------------------------------------------------------------------

_7fbff4:
@bff4:  sta     $14
        ldy     #$000c
        lda     $24
        sta     $10
@bffd:  jsr     _7fb035
        lda     $14
        clc
        adc     #$10
        sta     $14
        inc     $10
        dey
        bne     @bffd
        rts

; ------------------------------------------------------------------------------

; [ decompress ]

; ++$d0: source
; ++$d3: destination

_7fc00d:
@c00d:  lda     [$d0]       ; get compression mode
        ldx     $d0
        inx
        stx     $d0
        pha
        and     #$f0
        beq     @c03c
        pla
        and     #$0f
        bne     @c02d
        longa
        lda     [$d0]
        sta     $d6
        inc     $d0
        inc     $d0
        shorta
        brl     _7fc1cc       ; no compression
@c02d:  cmp     #$01
        bne     @c034
        brl     _7fc0a1       ; rle compression (high nybble set)
@c034:  cmp     #$02
        bne     @c03b
        brl     _7fc0f0       ; lzss compression
@c03b:  rts
@c03c:  pla
        bne     @c04e
        longa
        lda     [$d0]
        sta     $d6         ; compressed length
        inc     $d0
        inc     $d0
        shorta
        brl     _7fc1cc       ; no compression
@c04e:  cmp     #$01
        bne     @c055
        brl     _7fc05d       ; rle compression (high nybble clear)
@c055:  cmp     #$02
        bne     @c05c
        brl     _7fc0f0       ; lzss compression
@c05c:  rts

; ------------------------------------------------------------------------------

; [ rle (high nybble clear) ]

_7fc05d:
@c05d:  stz     $09         ; +$08 = repeat count/string length
        ldy     $c5
        sty     $0c         ; +$0c = source pointer
        sty     $0e         ; +$0e = destination pointer
@c065:  ldy     $0c
        iny
        lda     [$d0],y
        beq     @c0a0       ; null terminator
        bmi     @c084
        sta     $08         ; repeat count
        iny
        lda     [$d0],y     ; repeated value
        sty     $0c
        ldy     $0e
@c077:  iny
        sta     [$d3],y
        sty     $0e
        ldx     $08
        beq     @c065
        dec     $08
        bra     @c077
@c084:  and     #$7f
        sta     $08         ; string length
        sty     $0c
@c08a:  ldy     $0c
        iny
        lda     [$d0],y
        sty     $0c
        ldy     $0e
        iny
        sta     [$d3],y
        sty     $0e
        ldx     $08
        beq     @c065
        dec     $08
        bra     @c08a
@c0a0:  rts

; ------------------------------------------------------------------------------

; [ rle (high nybble set) ]

_7fc0a1:
@c0a1:  stz     $09
        ldy     $c7
        sty     $0c
        sty     $0e
@c0a9:  shorta
        ldy     $0c
        lda     [$d0],y
        beq     @c0ef
        bmi     @c0ce
        sta     $08
        iny
        longa
        lda     [$d0],y
        iny2
        sty     $0c
        ldy     $0e
@c0c0:  sta     [$d3],y
        iny2
        sty     $0e
        ldx     $08
        beq     @c0a9
        dec     $08
        bra     @c0c0
@c0ce:  and     #$857f
        php
        iny
        sty     $0c
        longa
@c0d7:  ldy     $0c
        lda     [$d0],y
        iny2
        sty     $0c
        ldy     $0e
        sta     [$d3],y
        iny2
        sty     $0e
        ldx     $08
        beq     @c0a9
        dec     $08
        bra     @c0d7
@c0ef:  .a8
        rts

; ------------------------------------------------------------------------------

; [ compression mode 2: lzss ]

; same as c3/0053

_7fc0f0:
@c0f0:  phb
        lda     #$7f
        pha
        plb
        lda     #$7f
        sta     $c9
        longa
        lda     #$07ff
        sta     $de
        lda     #$001f
        sta     $c2
        lda     [$d0]
        dec
        sta     $ca
        inc     $d0
        inc     $d0
        ldx     #$07de
        stx     $cc
        ldx     $c7
        txa
        tay
@c117:  sta     $f7ff,x
        inx2
        cpx     $cc
        bne     @c117
        stz     $ce
@c122:  lsr     $ce
        lda     $ce
        and     #$0080
        bne     @c135
        lda     [$d0]
        inc     $d0
        and     $c6
        ora     $c8
        sta     $ce
@c135:  lda     $ce
        and     #$0001
        beq     @c159
        lda     [$d0]
        inc     $d0
        sta     [$d3],y
        cpy     $ca
        bne     @c14a
@c146:  shorta
        plb
        rts
@c14a:  iny
        ldx     $cc
        sta     $f7ff,x
        lda     $cc
        inc
        and     $de
        sta     $cc
        bra     @c122
@c159:  lda     [$d0]
        shorta
        xba
        sta     $da
        lsr5
        xba
        longa
        sta     $d8
        lda     $da
        and     $c2
        inc3
        sta     $da
        stz     $dc
        inc     $d0
        inc     $d0
@c179:  lda     $dc
        cmp     $da
        beq     @c1a0
        lda     $d8
        clc
        adc     $dc
        and     $de
        tax
        lda     $f7ff,x
        sta     [$d3],y
        cpy     $ca
        beq     @c146
        iny
        ldx     $cc
        sta     $f7ff,x
        txa
        inc
        and     $de
        sta     $cc
        inc     $dc
        bra     @c179
@c1a0:  brl     @c122
        .a8

; ------------------------------------------------------------------------------

; [  ]

_7fc1a3:
@c1a3:  ldx     $b8
        stx     hVMADDL
        lda     #$80
        sta     hVMAINC
        lda     #$01
        sta     hDMA7::CTRL
        lda     #<hVMDATAL
        sta     hDMA7::HREG
        ldx     $ba
        stx     hDMA7::ADDR
        lda     $bc
        sta     hDMA7::ADDR_B
        ldx     $bd
        stx     hDMA7::SIZE
        lda     #$80
        sta     hMDMAEN
        rts

; ------------------------------------------------------------------------------

; [ compression mode 0: no compression ]

_7fc1cc:
@c1cc:  phb
        lda     $d5
        pha
        plb
        ldy     $c7
@c1d3:  cpy     $d6
        beq     @c1de
        lda     [$d0],y
        sta     ($d3),y
        iny
        bra     @c1d3
@c1de:  plb
        rts

; ------------------------------------------------------------------------------

_7fc1e0:
@c1e0:  phb
        lda     $d5
        pha
        plb
        ldy     $c7
        lda     #$00        ; fill remaining space with zeroes
@c1e9:  cpy     $d6
        beq     @c1f2
        sta     ($d3),y
        iny
        bra     @c1e9
@c1f2:  plb
        rts

; ------------------------------------------------------------------------------

_7fc1f4:
        lda     #^_c30200
        sta     $d2
        ldx     #near _c30200
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$c000
        stx     $d3
        brl     _7fc00d

; ------------------------------------------------------------------------------

_7fc209:
        lda     #^_c31177
        sta     $d2
        ldx     #near _c31177
        stx     $d0
        lda     #$7e
        sta     $d5
        ldx     #$c000
        stx     $d3
        brl     _7fc00d

; ------------------------------------------------------------------------------

        end_fixed_block

        fixed_block $0280

; ------------------------------------------------------------------------------

_7fc500:
        php
        longa
        pha
        phx
        phy
        phd
        phb
        lda     #$0420
        tcd
        shorta
        lda     #$00
        pha
        plb
        lda     $74
        bit     #$01
        beq     @c51f
        lda     $c7
        jsr     _7fac78
        lda     $74
@c51f:  bit     #$02
        beq     @c52a
        lda     #$01
        jsr     _7fac78
        lda     $74
@c52a:  bit     #$04
        beq     @c535
        lda     #$02
        jsr     _7fac78
        lda     $74
@c535:  bit     #$08
        beq     @c540
        lda     #$03
        jsr     _7fac78
        lda     $74
@c540:  bit     #$10
        beq     @c54b
        lda     #$04
        jsr     _7fac78
        lda     $74
@c54b:  bit     #$20
        beq     @c556
        lda     #$05
        jsr     _7fac78
        lda     $74
@c556:  bit     #$40
        beq     @c561
        lda     #$06
        jsr     _7fac78
        lda     $74
@c561:  bit     #$80
        beq     @c56a
        lda     #$07
        jsr     _7fac78
@c56a:  lda     $4f
        bit     #$01
        beq     @c573
        jsr     TfrSprites
@c573:  lda     $4f
        bit     #$02
        beq     @c57c
        jsr     _7fc678
@c57c:  lda     $4f
        bit     #$10
        beq     @c589
        lda     #$00
        jsr     _7fbc9a
        bra     @c5a8
@c589:  bit     #$20
        beq     @c594
        lda     #$01
        jsr     _7fbc9a
        bra     @c5a8
@c594:  bit     #$40
        beq     @c59f
        lda     #$02
        jsr     _7fbc9a
        bra     @c5a8
@c59f:  bit     #$80
        beq     @c5a8
        lda     #$03
        jsr     _7fbc9a
@c5a8:  lda     #$00
        sta     hCGADD
        lda     $40
        sta     hHDMAEN
        lda     $30
        sta     hBG1HOFS
        lda     $31
        sta     hBG1HOFS
        lda     $32
        sta     hBG1VOFS
        lda     $33
        sta     hBG1VOFS
        lda     $3b
        sta     hTM
        lda     $3a
        sta     hTS
        lda     $34
        sta     hM7X
        lda     $35
        sta     hM7X
        lda     $36
        sta     hM7Y
        lda     $37
        sta     hM7Y
        lda     $8e
        sta     hCGADSUB
        lda     $8b
        ora     #$20
        sta     hCOLDATA
        lda     $8c
        ora     #$40
        sta     hCOLDATA
        lda     $8d
        ora     #$80
        sta     hCOLDATA
        lda     $70
        bit     #$01
        beq     @c61c
        lda     $73
        cmp     $72
        beq     @c60e
        inc     $73
        bra     @c61c
@c60e:  stz     $73
        lda     $71
        inc
        cmp     #$10
        beq     @c61c
        sta     hINIDISP
        sta     $71
@c61c:  lda     $70
        bit     #$02
        beq     @c638
        lda     $73
        cmp     $72
        beq     @c62c
        inc     $73
        bra     @c638
@c62c:  stz     $73
        lda     $71
        beq     @c633
        dec
@c633:  sta     hINIDISP
        sta     $71
@c638:  lda     hHVBJOY
        bit     #$01
        bne     @c638
        ldx     hSTDCNTRL1L
        stx     $42
        stz     $07
        longa
        plb
        pld
        ply
        plx
        pla
        plp
        rti
        .a8

; ------------------------------------------------------------------------------

; [ transfer sprite data to ppu ]

TfrSprites:
@c64f:  lda     #$00
        sta     hOAMADDL
        sta     hOAMADDH
        lda     #$00
        sta     hDMA7::CTRL
        lda     #<hOAMDATA
        sta     hDMA7::HREG
        ldx     #$0200
        stx     hDMA7::ADDR
        lda     #$00
        sta     hDMA7::ADDR_B
        ldx     #$0220
        stx     hDMA7::SIZE
        lda     #$80
        sta     hMDMAEN
        rts

; ------------------------------------------------------------------------------

_7fc678:
@c678:  ldx     $ac
        stx     hVMADDL
        lda     #$80
        sta     hVMAINC
        lda     $b3
        sta     hDMA7::CTRL
        lda     $b4
        sta     hDMA7::HREG
        ldx     $ae
        stx     hDMA7::ADDR
        lda     $b0
        sta     hDMA7::ADDR_B
        ldx     $b1
        stx     hDMA7::SIZE
        lda     #$80
        sta     hMDMAEN
        rts

; ------------------------------------------------------------------------------

        end_fixed_block

; ------------------------------------------------------------------------------

_7fc780:
        .byte   $00,$04,$00,$08,$20,$0c,$20,$10,$20,$14,$40,$14,$40,$18,$60,$1c
        .byte   $60,$20,$60,$24,$80,$28,$80,$2c,$80,$30,$a0,$34,$a0,$38,$c0,$3c
        .byte   $c0,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

_7fc7b0:
        .byte   $00,$00,$00,$03,$00,$06,$00,$09

_7fc7b8:
        .byte   $37,$3f,$47,$4f,$57,$5f,$67,$6f
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

_7fc7e0:
        .byte   $01,$00,$04,$00,$10,$00,$40,$00,$00,$01,$00,$04,$00,$10,$00,$40

_7fc7f0:
        .byte   $fc,$ff,$f3,$ff,$cf,$ff,$3f,$ff,$ff,$fc,$ff,$f3,$ff,$cf,$ff,$3f

; ------------------------------------------------------------------------------
