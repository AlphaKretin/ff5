; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: menu/menu-main.asm                                                |
; |                                                                         |
; | description: menu code                                                  |
; +-------------------------------------------------------------------------+

.p816

.include "macros.inc"
.include "hardware.inc"
.include "const.inc"

inc_lang "text/item_desc_%s.inc"
inc_lang "text/job_desc_%s.inc"
inc_lang "text/ability_desc_%s.inc"

.export ExecMenu_ext, UpdateJoypad_ext, _c2a006, _c2a008
.import ExecSound_ext, _c10009
.import EquipTypeTbl, ArmorElementTbl, EquipStatBonusTbl, MagicSwordAttackTbl

.segment "menu_code"

; ---------------------------------------------------------------------------

        .a16
        .i16

; c2/a000
ExecMenu_ext:
        bra     ExecMenu

UpdateJoypad_ext:
        jsr     _c2ff7d
        rtl

_c2a006:
        bra     _a00a

_c2a008:
        bra     _a00f

_a00a:  jsr     _c2ff56
        bra     _a012
_a00f:  jsr     _c2ff68
_a012:  jsr     _c2fe5b
        rtl

; ---------------------------------------------------------------------------

ExecMenu:
@a016:  jsr     InitMenu
        stz     $39
        lda     $34
        and     #7
        asl
        tax
        lda     f:_c0e600,x
        sta     $c7
        shorta
        jmp     ($01c7)

; ---------------------------------------------------------------------------

CommonReturn:
@a02d:  jsr     _c2b2bd
        .a8

_c2a030:
@a030:  shorta
        rtl

; ---------------------------------------------------------------------------

; [ menu command $00: main menu ]

_c2a033:
_a033:  lda     $35
        sta     $44
        lda     #$01
        bra     _a06b       ; show menu

; ---------------------------------------------------------------------------

; [ menu command $01: collect items after battle ]

_c2a03b:
_a03b:  lda     #$0a
        bra     _a06b       ; show menu

; ---------------------------------------------------------------------------

; [ menu command $02: shop ]

_c2a03f:
_a03f:  lda     #$06
        bra     _a06b       ; show menu

; ---------------------------------------------------------------------------

; [ menu command $03: init menu settings ]

_c2a043:
_a043:  jsr     _c2a1f0     ; init config settings
        jsr     _c2ff7d     ; update joypad config
        jsr     _c2d447     ; update window color
        jsr     _c2f5a9     ; update mono/stereo setting
        lda     #$0c
        bra     _a06b       ; show menu

; ---------------------------------------------------------------------------

; [ menu command $04: tutorial ]

_c2a053:
_a053:  lda     #$80
        tsb     $45         ; enable tutorial mode
        stz     $49         ; clear pause counter
        stz     $4a
        jsr     _c2a394     ; init tutorial script
        lda     #$01
        bra     _a06b       ; show menu

; ---------------------------------------------------------------------------

; [ menu command $06: transfer galuf's stats to krile ]

_c2a062:
_a062:  stz     $35
        jsr     _c2d958
        bra     _c2a030

; ---------------------------------------------------------------------------

; [ menu command $05: name change ]

_c2a069:
_a069:  lda     #$0d

; ---------------------------------------------------------------------------

; [ show menu ]

_c2a06b:
_a06b:  shorta
        sta     $43         ; menu state
        lda     #$7e
        pha
        plb
        longa
        jsr     _c2c16a     ; load tilemap/???/cursor data
        jsr     _c2a16e     ; reset sprite data
        lda     $43         ; menu state
        and     #$00ff
        dec
        asl
        tax
        lda     f:_c0e60e,x
        sta     $c7
        per     @a08f-1
        jmp     ($01c7)
@a08f:  longa
        lda     $43         ; menu state
        and     #$00ff
        cmp     #$000c
        bne     @a0a2
        lda     $39
        jeq     _c2a030
@a0a2:  shorta
        lda     #$00
        pha
        plb
        stz     hCGADD
        longa
        stz     hOAMADDL
        stz     hVMADDL
        ldx     #near _c0f5b2      ; 02 04 00 02 00 20 02 (sprite data)
        jsr     _c2a0f6
        ldx     #near _c0f5b9      ; 02 22 00 73 7E 00 02 (color palettes)
        jsr     _c2a0f6
        ldx     #near _c0f58b      ; 01 18 00 30 7E 00 40 (vram)
        jsr     _c2a0f6
        shorta
        lda     #$04
        sta     $ca
        lda     #$00
        sta     $7e7511
        jsr     _c2a106       ; wait for vblank
        lda     $7e750e
        sta     hHDMAEN
        lda     hRDNMI
        lda     #$81
        sta     hNMITIMEN
        lda     #$00
        sta     $7e7522
        sta     $7e7525
        lda     #$03
        sta     $7e7513
        jmp     _c2a2e9

; ---------------------------------------------------------------------------

; [ dma ]

; +X: address of dma parameters (+$C00000)

_c2a0f6:
        .a16
_a0f6:  ldy     #near hDMA0
        lda     #$0006
        mvn     #$c0,#^hDMA0
        lda     #$0001
        sta     hMDMAEN
        rts

; ---------------------------------------------------------------------------

; [ wait for vblank ]

_c2a106:
_a106:  php
        shorta
@a109:  lda     f:hRDNMI
        bmi     @a109
@a10f:  lda     f:hRDNMI
        bpl     @a10f
        lda     f:hRDNMI
        plp
        rts

; ---------------------------------------------------------------------------

; c2/a11b
InitMenu:
@a11b:  longai
        lda     #$0100      ; set direct page to $0100
        tcd
        ldx     #near _c0f533      ; copy interrupt jump code
        ldy     #$1f00
        lda     #$0007
        mvn     #^_c0f533,#$7e
        stz     $8e
        shorta
        lda     #$80
        sta     f:hINIDISP
        stz     $44
        stz     $45
        stz     $46
        stz     $47
        stz     $48
        jsr     _c2a18a
        jsr     _c2d230
        jsr     _c2d37b
        jsr     _c2d3db
        jsr     _c2a247
        jsr     _c2a1cf
        jsr     _c2ff7d     ; update joypad config
        jsr     _c2d447     ; update window color
        jsr     _c2f5a9     ; update mono/stereo setting
        jsr     _c2a16e     ; reset sprite data
        longa
        ldx     #near _c0f573
        ldy     #$750f
        lda     #$0017
        mvn     #^_c0f573,#$7e
        rts

; ---------------------------------------------------------------------------

; [ reset sprite data ]

_c2a16e:
_a16e:  php
        longa
        ldx #$0220
@a174:  stz $01fe,x
        dex2
        bne @a174
        ldx #$0020
        lda #$aaaa
@a181:  sta $03fe,x
        dex2
        bne @a181
        plp
        rts

; ---------------------------------------------------------------------------

; [ init hardware registers ]

_c2a18a:
_a18a:  phb
        php
        shorta
        lda #$00
        pha
        plb
        lda #$01
        sta hNMITIMEN
        lda #$01
        sta hOBJSEL
        lda #$00        ; mode 0
        sta hBGMODE
        sta hMOSAIC
        lda #$80
        sta hVMAINC
        ldx #$0008
@a1ac:  stz hBG1HOFS - 1,x
        stz hBG1HOFS - 1,x
        dex
        bne @a1ac
        longa
        ldx #near _c0f53b
        ldy #hBG1SC
        lda #$0005
        mvn #^_c0f53b,#$00
        ldy #hTM
        lda #$0005
        mvn #^_c0f53b,#$00
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ init hdma registers ]

_c2a1cf:
        phb
        php
        longa
        lda $8e
        sta f:hHDMAEN
        ldx #near _c0f547
@a1dc:  lda f:bank_start _c0f547,x
        beq @a1ed
        tay
        inx2
        lda #$0004
        mvn #^_c0f547,#$00
        bra @a1dc
@a1ed:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ init config settings ]

_c2a1f0:
_a1f0:  phb
        php
        longa
        ldx #near _c0f342      ; C0/F342 (default config settings)
        ldy #$0970
        lda #$001f
        mvn #^_c0f342,#$00
        lda #$0100      ; set character cursor positions
        sta $042d
        lda #$0302
        sta $042f
        shorta
        stz $59
        stz $5d
        stz $5f
        stz $61
        stz $62
        stz $5e
        stz $5c
        stz $5b
        lda #$02
        sta $60
        lda #$08
        sta $5a
        stz $63
        stz $64
        stz $65
        stz $66
        lda #$07
        sta $67
        sta $68
        sta $69
        Sta $6a
        plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2a23b:
_a23b:  sta ($e0),y
        clc
        adc $e4
        iny2
        cpy $e2
        bne _a23b
        rts

; ---------------------------------------------------------------------------

; [ init rom data pointers (data in bank $D1) ]

_c2a247:
_a247:  php
        longa
        ldx #$d000
        stx $e0
        ldx #$0100
        stx $e2
        ldx #$000c
        stx $e4
        ldy $8e
        lda #$0000                      ; weapon properties
        jsr _c2a23b
        ldx #$01c0
        stx $e2
        lda #$0600                      ; armor properties
        jsr _c2a23b
        ldx #$0008
        stx $e4
        ldx #$0200
        stx $e2
        lda #$0a80                      ; item properties
        jsr _c2a23b
        ldx #$d200
        stx $e0
        ldx #$0009
        stx $e4
        ldy $8e
        lda #$1380                      ; D1/1380 (item names)
        jsr _c2a23b
        ldx #$d400
        stx $e0
        ldx #$00ae
        stx $e2
        ldx #$0006
        stx $e4
        ldy $8e
        lda #$1c80                      ; D1/1C80 (spell names)
        jsr _c2a23b
        ldx #$0200
        stx $e2
        ldx #$0009
        stx $e4
        jsr _c2a23b
        ldx #$d600
        stx $e0
        ldx #$00a2
        stx $e2
        ldx #$0005
        stx $e4
        ldy $8e
        lda #$5800                      ; battle command names
        jsr _c2a23b
        ldx #$0100
        stx $e2
        ldx $8e
        stz $e4
        lda $8e
        jsr _c2a23b
        ldx #$0142
        stx $e2
        ldx #$0008
        stx $e4
        lda #$6200                      ; passive ability names
        jsr _c2a23b
        plp
        rts

; ---------------------------------------------------------------------------

; [ get next input ]

_c2a2e9:
_a2e9:  shorta
        longi
        jsr _c2e66f
        jsr _c2fc2f
        pea $7e7e
        plb
        plb
        bit $45
        bmi @a301       ; branch if in tutorial mode
        jsr _c2a33a     ; get pressed button index
        bra @a320
@a301:  ldx $49         ; decrement pause counter
        bmi @a30c
        dex
        stx $49
        lda $8e
        bra @a320
@a30c:  lda $48
        bne @a314       ; branch if tutorial script pointer is valid
        lda #$08        ; exit menu
        bra @a320
@a314:  lda [$46]       ; tutorial script
        ldx $46
        inx
        stx $46
        ldx #$000f
        stx $49
@a320:  sta $4b
        bit #$10
        beq @a328       ; branch if not a pause
        lda #$07        ; use pause command
@a328:  longa
        and #$000f
        asl
        tax
        lda f:_c0e628,x
        sta $c7
        shorta
        jmp ($01c7)

; ---------------------------------------------------------------------------

; [ get pressed button index ]

_c2a33a:
_a33a:  php
        longa
        ldx $8e
@a33f:  lda $0a         ; buttons pressed
        and f:_c0e7d2,x   ; button mask
        bne @a34f       ; branch if buttons are pressed
        inx3            ; next button
        cpx #$0012
        bne @a33f
@a34f:  lda f:_c0e7d2+2,x   ; button index
        and #$00ff
        plp
        rts

; ---------------------------------------------------------------------------

; [ menu state $14: pause (tutorial) ]

_c2a358:
_a358:  lda $4b
        longa
        and #$000f
        asl
        tax
        lda f:_c0f592,x   ; pause duration
        sta $49
        jmp _c2a4f0

; ---------------------------------------------------------------------------

; [ menu state $0E: A button pressed ]

_c2a36a:
_a36a:  jsr _c2e0b0
        lda $54
        longa
        and #$007f
        asl2
        bra _a386

; ---------------------------------------------------------------------------

; [ menu state $0F: B button pressed ]

_c2a378:
_a378:  jsr _c2e0b8     ; play sound effect
        lda $54
        longa
        and #$007f
        asl2
        inc2
_a386:  tax
        lda f:_c0e724,x
        sta $c7
        lda $8e
        shorta
        jmp ($01c7)

; ---------------------------------------------------------------------------

; [ init tutorial script ]

_c2a394:
_a394:  php
        longa
        ldx #$0500      ; copy sram data to $7E2000 ($0600 bytes)
        ldy #$2000
        lda #$05ff
        mvn #$7e,#$7e
        ldx #$0159      ; copy $12 bytes from $0159 to $7E2600 (cursor memory positions ???)
        ldy #$2600
        lda #$0011
        mvn #$7e,#$7e
        lda $35         ; tutorial index
        and #$0007
        asl2
        tax
        lda f:_c0e841,x   ; pointer to tutorial script
        sta $46
        lda f:_c0e841+2,x
        shorta
        sta $48
        xba             ; tutorial flags
        and #$0f
        tsb $45
        longa
        ldx #near _c0e8df      ; set available abilities for tutorial
        ldy #$08f7      ; copy 20 bytes from $C0E8DF -> $7E08F7
        lda #$0013
        mvn #^_c0e8df,#$7e
        shorta
        lda #$e0        ; set available jobs for tutorial
        sta $0840
        lda #$64
        sta $0841
        lda #$04
        sta $0842
        lda #$05
        trb $0973
        lda #$06
        sta $08f3
        lda #$40
        trb $0500
        stz $051a
        ldx $8e
@a3fd:  lda f:_c0e8f8,x
        beq @a40f
        xba
        lda #$01
        xba
        phx
        jsr _c2e2ce
        plx
        inx
        bra @a3fd
@a40f:  stz $7e
        jsr _c2d4c5
        jsr _c2daa4
        longa
        lda $35
        and #$0007
        tax
        shorta
        lda f:_c0e8f0,x
        sta $d8
        jsr _c2e47d
        lda $da
        sta $053a
        lda $d8
        sta $0501
        ldx $dc
        stx $053b
        jsr _c2eb82
        jsr _c2e6d6
        plp
        rts

; ---------------------------------------------------------------------------

; [ menu state $15: exit menu (tutorial) ]

_c2a441:
_a441:  longa
        ldx #$2000      ; restore sram data
        ldy #$0500
        lda #$05ff
        mvn #$7e,#$7e
        ldx #$2600
        ldy #$0159
        lda #$0011
        mvn #$7e,#$7e
        jmp CommonReturn

; ---------------------------------------------------------------------------

; [ menu state $10: move cursor up ]

_c2a45e:
_a45e:  jsr _c2e4df     ; get pointer to current cursor data
        lda $7604,x
        bra _c2a47c

; ---------------------------------------------------------------------------

; [ menu state $10: move cursor down ]

_c2a466:
_a466:  jsr _c2e4df     ; get pointer to current cursor data
        lda $7605,x
        bra _c2a47c

; ---------------------------------------------------------------------------

; [ menu state $10: move cursor left ]

_c2a46e:
_a46e:  jsr _c2e4df     ; get pointer to current cursor data
        lda $7606,x
        bra _c2a47c

; ---------------------------------------------------------------------------

; [ menu state $10: move cursor right ]

_c2a476:
        jsr _c2e4df     ; get pointer to current cursor data
        lda $7607,x

_c2a47c:
        pea $7e7e
        plb
        plb
        jsr _c2e0a8     ; play sound effect
        shorta
        stz $4f
        sta $56         ; target cursor position
        jsr _c2e4e1     ; get pointer to cursor data
        lda $7601,x
        sta $58
        lda $7600,x
        sta $57
        bmi @a4bb
        cmp $54
        beq @a4a1
        lda #$40
        tsb $4f
@a4a1:  lda $53
        sta $50
        lda $54
        sta $51
        lda $55
        sta $52
        lda $56
        sta $53
        lda $57
        sta $54
        lda $58
        sta $55
        bra @a4bf
@a4bb:  lda #$80
        tsb $4f
@a4bf:  bit $4f
        bmi @a4c7
        bvs @a4d1
        bra @a4e5
@a4c7:  ldx #near _c0e63a
        lda $57
        jsr _c2a4f3
        bra @a4e5
@a4d1:  ldx #near _c0e6af
        lda $51
        jsr _c2a4f3
        bit $4f
        bvc @a4e5
        ldx #near _c0e652
        lda $54
        jsr _c2a4f3
@a4e5:  ldx #near _c0e6e8
        lda $54
        jsr _c2a4f3
        jsr _c2e6ab     ; update cursor sprite

; fall through

; ---------------------------------------------------------------------------

; [ menu state $0D: name change ]

_c2a4f0:
_a4f0:  jmp _c2a2e9     ; get next input

; ---------------------------------------------------------------------------

; [  ]

_c2a4f3:
_a4f3:  shorta
        sta $e0
        ldy $8e
@a4f9:  lda $c00000,x
        beq @a516
        cmp $e0
        beq @a508
        inx3
        bra @a4f9
@a508:  longa
        lda $c00001,x
        sta $c7
        per @a516-1
        jmp ($01c7)
@a516:  shorta
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a519:
        .a16
_a519:  jsr _c2a55f
        bcs @a549
        ldy $8e
@a520:  lda $29ac,y
        clc
        adc $6b
        tax
        lda $7a00,x
        and #$00ff
        ldx $29b0,y
        jsr _c2d8e4
        iny2
        cpy #$0004
        bne @a520
        jsr _c2e367
        jsr _c2fe05
        jsr _c2e66f
        jsr _c2fc2f
        jsr _c2a54a
@a549:  rts

_c2a54a:
_a54a:  shorta
        lda $58
        cmp #$03
        bmi @a55e
        lsr
        and #$02
        dec
        clc
        adc $53
@a559:  sta $53
        jsr _c2e6ab     ; update cursor sprite
@a55e:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a55f:
_a55f:  shorta
        lda $7512
        bne @a5b3
        longa
        lda $58
        and #$0007
        dec
        and #$0001
        asl
        tay
        ldx $298a,y
        ldy #$29a0
        lda #$0015
        mvn #$c0,#$7e
        lda $6b
        clc
        adc $29a0
        bmi @a5b3
        cmp $6d
        beq @a58d
        bcs @a5b3
@a58d:  sta $6b
        shorta
        lda #$01
        sta $7512
        stz $7528
        longa
        ldx $29a6
        ldy $29a8
        lda $29aa
        bpl @a5ae
        and #$7fff
        mvn #$7e,#$7e
        bra @a5b1
@a5ae:  mvp #$7e,#$7e
@a5b1:  clc
        rts
@a5b3:  sec
        rts

; ---------------------------------------------------------------------------

; [ job menu, at first job, pressed left, go to last job ]

_c2a5b5:
_a5b5:  shorta
        lda $6f
        bne @a5e1
        lda $53
        sta $50
        lda $54
        sta $51
        lda $55
        sta $52
        ldx $8e
@a5c9:  lda $7a00,x     ; find the last available job
        bmi @a5d6
        inx
        cpx #$0017
        bpl @a5dc
        bra @a5c9
@a5d6:  dex
        txa
        and #$1f
        sta $53
@a5dc:  jsr _c2e6ab     ; update cursor sprite
        bra @a5e5
@a5e1:  lda $53
        sta $50
@a5e5:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a5e6:
        .a16
_a5e6:  lda $70
        and #$00ff
        bne @a600
        jsr _c2a55f
        bcs @a600
        jsr _c2a607
        jsr _c2fe05
        jsr _c2e66f
        jsr _c2fc2f
        bra @a606
@a600:  shorta
        lda $53
        sta $50
@a606:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a607:
_a607:  lda $29ac
        clc
        adc $6b
        tax
        ldy $29b0
        jsr _c2e3e3
        jsr _c2e367
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a618:
        .a16
_a618:  lda $2802
        bpl @a61e
        rts
@a61e:  lda $2814
        and #$00ff
        sta $85
        lda $58
        and #$000f
        dec
        tax
        shorta
        lda f:_c0f3c1,x
        clc
        adc $85
        cmp $2813
        bmi @a642
        beq @a642
        lda $2813
        bra @a648
@a642:  cmp #$01
        bpl @a648
        lda #$01
@a648:  sta $2814
        jsr _c2f0e6
        shorta
        ldx #$2821
        ldy #$2819
        jsr _c2eec8
        bcs @a65f
@a65b:  lda $85
        bra @a648
@a65f:  lda $2804
        bmi @a671
        ldx #$2815
        ldy #$2819
        jsr _c2eec8
        bcc @a65b
        bra @a671
@a671:  longa
        jsr _c2a67a
        jsr _c2a693
        .a8
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a67a:
        .a16
_a67a:  ldx #$42a4
        ldy #$2819
        lda #$7e73
        jsr _c2e4ed
        ldx #$429a
        ldy #$2814
        lda #$7e21
        jsr _c2e4ed
        rts

; ---------------------------------------------------------------------------

; [  ]

; this subroutine is problematic because the accumulator is often 16-bit
; when called but changes to 8-bit when it returns

_c2a693:
_a693:  ldx     #near _c0f3f9
        bra     _c2a6a0

_c2a698:
        ldx     #near _c0f402
        bra     _c2a6a0

_c2a69d:
        ldx     #near _c0f40b

_c2a6a0:
        longa
        ldy     #$7514
        lda     #$0008
        mvn     #$c0,#$7e
        shorta
        lda     #$01
        sta     $7511
        jsr     _c2e66f
        jsr     _c2fc2f
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a6b9:
_a6b9:  jsr _c2a55f
        bcs @a6dd
        php
        shorta
        lda $29a3
        sta $7528
        plp
        jsr _c2a6de
        jsr _c2fe05
        jsr _c2e66f
        jsr _c2fc2f
        jsr _c2e66f
        jsr _c2fc2f
        jsr _c2a54a
@a6dd:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a6de:
_a6de:  lda $29ac
        clc
        adc $6b
        tax
        ldy $29b0
        jsr _c2e3f3
        lda $29ae
        clc
        adc $6b
        tax
        ldy $29b2
        jsr _c2e3f3
        jsr _c2e367
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a6fc:
        .a16
_a6fc:  lda $2b66
        tay
@a700:  lda $58
        dec
        and #$0003
        asl
        tax
        lda f:_c0f3ab,x
        stz $2b6e
        shorta
        ldx $8e
@a713:  clc
        adc $2b66,x
        jsr _c2a780
        sta $2b66,x
        xba
        inx
        cpx #$0002
        bne @a713
        lda $2b67
        sta f:hWRMPYA
        lda $2b68
        sta f:hWRMPYB
        nop4
        lda f:hRDMPYL
        clc
        adc $2b66
        longa
        and #$00ff
        tax
        lda $7a00,x
        and #$00ff
        cmp #$00ff
        beq @a700
        txa
        inc
        shorta
        ldx $2b6a
        sta $7601,x
        lda $2b66
        and #$0f
        tax
        lda $2b67
        and #$0f
        tay
        shorta
        lda $2b70,x
        ldx $2b6a
        sta $7602,x     ; cursor x position
        lda $2b80,y
        sta $7603,x     ; cursor y position
        jsr _c2e6ab     ; update cursor sprite
        bra @a77f
        tya
        sta $2b66
@a77f:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a780:
_a780:  bpl @a794
        bit $2b6c,x
        bpl @a78e
        inc $2b6e,x
        lda #$00
        bra @a79b
@a78e:  lda $2b68,x
        dec
        bra @a79b
@a794:  cmp $2b68,x
        bmi @a79b
        lda #$00
@a79b:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a79c:
        .a16
_a79c:  lda $55
        and #$00ff
        dec
        tax
        lda $58
        and #$00ff
        dec2
        shorta
        clc
        adc $2c9c,x
        bmi @a7bd
        cmp f:_c0f076,x
        bmi @a7bf
        lda $2c9c,x
        bra @a7bf
@a7bd:  lda #$00
@a7bf:  sta $2c9c,x
        stx $2c94
        cpx #$000a
        bmi @a7cf
        cpx #$000d
        bmi @a7dc
@a7cf:  jsr _c2f7a6
        lda $54
        cmp #$21
        beq @a7f5
        cmp #$22
        beq @a7ed
@a7dc:  jsr _c2f810
        jsr _c2f71c     ; update config settings
        jsr _c2d447     ; update window color
        jsr _c2a698
        .a8
        jsr _c2faf0
        bra @a7fb
@a7ed:  longa
        lda #near _c3b77a
        jsr LoadMenuTilemap
@a7f5:  jsr _c2a693
        .a8
        jsr _c2f71c     ; update config settings
@a7fb:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2a7fc:
_a7fc:  shorta
        stz $750f
        stz $751e
        jsr _c2c0e2
        lda $59
        sta $53
        lda #$02
        trb $7500
        lda #$08
        trb $7509
        lda #$04
        tsb $ca
        jsr _c2e6ab     ; update cursor sprite
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a81d:
_a81d:  stz $6f
        shorta
        lda $50
        sta $59
        rts

_c2a826:
        stz $6f
        shorta
        lda #$02
        tsb $7500
        lda #$08
        tsb $7509
        lda #$04
        tsb $ca
        jsr _c2e67c
        jsr _c2e6ab     ; update cursor sprite
        jsr _c2a85a
        ldx #near _c3adc7
        jsr _c2a8f0
        rts

_c2a848:
_a848:  php
        longa
        lda $55
        and #$000f
        dec
        asl
        tax
        lda f:_c0ea64,x
        tax
        plp
        rts
        .a8

_c2a85a:
_a85a:  jsr _c2a848
        bit $0500,x
        bvc @a877
        lda $55
        cmp #$04
        bne @a870
        dec $53
        dec $53
        dec $53
        dec $53
@a870:  inc $53
        jsr _c2e6ab     ; update cursor sprite
        bra _a85a
@a877:  rts

_c2a878:
_a878:  lda $53
        and #$03
        sta $e0
        lda $50
        and #$03
        inc
        and #$03
        cmp $e0
        beq @a88d
        lda #$ff
        bra @a88f
@a88d:  lda #$01
@a88f:  sta $e2
        rts

_c2a892:
_a892:  php
        shorta
        jsr _c2a878
@a898:  jsr _c2a848
        bit $0500,x
        bvc @a8bf
        lda $55
        clc
        adc $e2
        beq @a8af
        cmp #$05
        beq @a8b3
        lda $e2
        bra @a8b5
@a8af:  lda #$03
        bra @a8b5
@a8b3:  lda #$fd
@a8b5:  clc
        adc $53
        sta $53
        jsr _c2e6ab     ; update cursor sprite
        bra @a898
@a8bf:  plp
        rts
        shorta
        lda $6f
        bne @a8ca
        jsr _c2a892
@a8ca:  rts

_c2a8cb:
_a8cb:  lda $50
        sta $53
        jsr _c2e6ab     ; update cursor sprite
        rts
        shorta
        lda $6f
        beq @a8e2
        jsr _c2a8cb
        lda #$40
        trb $4f
        bra @a8ef
@a8e2:  ldx #near _c3add8
        jsr _c2a8f0
        stz $7510
        lda $50
        sta $5a
@a8ef:  rts

_c2a8f0:
_a8f0:  longa
        txa
        jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        rts

_c2a8fa:
        lda $59
        jsr _c2c0c0
        shorta
        lda #$01
        sta $7510
        jsr _c2e67c
        lda $53
        and #$03
        ora #$0c
        sta $53
        jsr _c2e6ab     ; update cursor sprite
        jsr _c2a85a
        rts
        jsr _c2a892
        rts

_c2a91c:
        shorta
        lda $50
        and #$0b
        sta $5a
        rts

_c2a925:
        jsr _c2d717
        jsr _c2a698
        .a8
        lda #$02
        tsb $7500
        lda #$04
        tsb $ca
        rts

_c2a935:
        .a16
        lda $55
        and #$00ff
        dec
        tax
        shorta
        lda $2b5f,x
        beq @a947
        lda $50
        sta $53
@a947:  rts

_c2a948:
        shorta
        lda $50
        sta $60
        lda #$02
        trb $7500
        lda #$04
        tsb $ca
        rts

_c2a958:
        .a16
        lda #near _c3ae62
        jsr LoadMenuTilemap
        jsr _c2e367
        jsr _c2a698
        .a8
        rts

_c2a965:
        jsr _c2d760
        jsr _c2a698
        .a8
        rts

_c2a96c:
        stz $6f
        rts

_c2a96f:
        .a16
        lda $55
        and #$00ff
        dec
        tax
        shorta
        lda $6f
        bne @a98e
        lda $7a00,x
        bpl @a992
        lda $53
        sec
        sbc $50
        cmp #$01
        bne @a98e
        stz $53
        bra @a992
@a98e:  lda $50
        sta $53
@a992:  jsr _c2e6ab     ; update cursor sprite
        longa
        lda $52
        and #$00ff
        dec
        asl2
        tay
        asl
        tax
        shorta
        lda $0293,x
        and #$f1
        ora #$0c
        sta $0293,x
        sta $0297,x
        lda $0363,y
        and #$f1
        ora #$0c
        sta $0363,y
        sta $0363,y
        jsr _c2cd57
        lda #$01
        sta $7511
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2faf0
        jsr _c2e66f
        jsr _c2a9d9
        jsr _c2cd08
        jsr _c2a69d
        .a8
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2a9d9:
_a9d9:  php
        longa
        lda #near _c3af1a
        jsr LoadMenuTilemap
        lda $55         ; cursor position ???
        and #$00ff
        dec
        tax
        lda $7a00,x     ; job index
        and #$001f
        asl
        tax
.if LANG_EN
        .import _e0315b
        jml _e0315b
        .export _c2a9f5 := *
.else
        lda f:JobDescPtrs,x   ; pointers to job descriptions
.endif
        sta $2ceb
        jsr _c2da16
        plp
        rts

; ---------------------------------------------------------------------------

_c2a9fd:
        .a16
        lda #near _c3b036
        jsr LoadMenuTilemap
        lda #$0002
        tsb $7500
        lda #$0004
        tsb $ca
        jsr _c2a693
        .a8
        rts

_c2aa12:
        stz $6f
        shorta
        lda #$02
        tsb $7500
        lda #$04
        tsb $ca
        lda $74
@aa21:  cmp #$04
        beq @aa29
        cmp #$03
        beq @aa2e
@aa29:  ldx #near _c3b065
        bra @aa31
@aa2e:  ldx #near _c3b07d
@aa31:  jsr _c2a8f0
        rts

_c2aa35:
        jsr _c2e367
        jsr _c2a698
        .a8
        stz $72
        stz $73
        lda #$08
        tsb $7500
        lda #$0c
        tsb $7502
        lda #$04
        tsb $ca
        rts

_c2aa4e:
        .a16
        stz $0208
        stz $020a
        lda #near _c3affa
        jsr LoadMenuTilemap
        jsr _c2a698
        .a8
        stz $70
        lda #$08
        trb $7500
        lda #$0c
        trb $7502
        lda #$04
        tsb $ca
        rts

_c2aa6e:
        .a16
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        tax
        shorta
        lda $7a00,x
        beq @aa84
        jsr _c2aa89
        bra @aa88
@aa84:  lda $50
        sta $53
@aa88:  rts

_c2aa89:
@aa89:  sta $72
        jsr _c2e0f7
        lda $90
        bne @aaaf
        jsr _c2e178
        jsr _c2e211
        lda $73
        jsr _c2e286
        lda $90
        bne @aaaf
        jsr _c2e1a6
        jsr _c2e7b3
        jsr _c2e7cc
        jsr _c2cbf8
        bra @aab7
@aaaf:  longa
        lda #near _c3b005
        jsr LoadMenuTilemap
@aab7:  jsr _c2a698
        .a8
        rts

_c2aabb:
        .a16
        lda #near _c3b26a
        jsr LoadMenuTilemap
        lda #$0004
        jsr _c2eee7
        jsr _c2a16e     ; reset sprite data
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2e66f
        rts

_c2aad1:
        .a16
        shorta
        lda $2801
        and #$07
        bne @aae8
        lda $53
        cmp #$01
        bne @aae8
        lda $50
        and #$03
        eor #$02
        sta $53
@aae8:  rts

_c2aae9:
        .a16
        lda #near _c3b242
        jsr LoadMenuTilemap
        shorta
        lda $2801
        and #$03
        cmp #$03
        bne @ab01
        stz $2886
        longa
        bra @ab0f
@ab01:  longa
        jsr _c2ef89
        jsr _c2ef16
        lda #near _c3b25f
        jsr LoadMenuTilemap
@ab0f:  jsr _c2f10e
        lda #$0000
        jsr _c2eee7
        rts

_c2ab19:
        .a16
        lda #near _c3b254
        jsr LoadMenuTilemap
        rts

_c2ab20:
        jsr _c2ab36
        lda $2801
        and #$c903
        ora $f0,s
        ora #$8920
        sbc $ef1620
        jsr _c2fad4     ; copy sprite data to vram
        rts

_c2ab36:
_ab36:  lda $55
        and #$000f
        dec
        tax
        shorta
        lda $2826,x
        bne @ab4b
        jsr _c2a8cb
        lda #$01
        trb $ca
@ab4b:  rts

_c2ab4c:
        .a16
_ab4c:  jsr _c2a67a
        ldx #$435a
        ldy #$2811
        jsr _c2e4ed
        ldx #$43da
        ldy #$2812
        jsr _c2e4ed
        lda #near _c3b1e0
        jsr LoadMenuTilemap
        lda $2810
        and #$00ff
        asl
        tax
.if LANG_EN
        .import _e03149
        jml _e03149
        .export _c2ab73 := *
.else
        lda f:ItemDescPtrs,x
.endif
        sta $2ceb
        jsr _c2da16
        shorta
        lda $2809
        ldy #$4286
        jsr _c2e44e
        lda #$02
        tsb $7500
        lda #$04
        tsb $ca
        jsr _c2a693
        .a8
        rts

_c2ab91:
        jsr _c2ab4c
        lda #$05
        jsr _c2eee7
        lda $2886
        sta $750f
        rts

_c2aba0:
_aba0:  shorta
        lda #$02
        trb $7500
        lda #$04
        tsb $ca
        stz $750f
        stz $751e
        rts

_c2abb2:
        jsr _c2aba0
        lda $2807
        clc
        adc #$03
        sta $53
        jsr _c2e6ab     ; update cursor sprite
        rts

_c2abc1:
        .a16
        lda #near _c3b275
        jsr LoadMenuTilemap
        jsr _c2f10e
        lda #$0000
        jsr _c2eee7
        rts

_c2abd1:
        .a16
        lda #near _c3b254
        jsr LoadMenuTilemap
        jsr _c2a698
        .a8
        rts

_c2abdb:
        jsr _c2ab36
        rts

_c2abdf:
        .a16
        lda #near _c3b3a9
        jsr LoadMenuTilemap
        jsr _c2a698
        .a8
        lda #$08
        trb $7506
        lda #$04
        tsb $ca
        rts

_c2abf2:
        .a16
        sep #$20
        lda $2d15
        beq @abfd
        lda $50
        sta $53
@abfd:  jsr _c2a698
        .a8
        rts

_c2ac01:
        jsr _c2ac0e
        .a8
        lda #$08
        tsb $7506
        lda #$04
        tsb $ca
        rts

_c2ac0e:
        .a16
        lda #near _c3b3b4
        jsr LoadMenuTilemap
        jsr _c2c7bd
        jsr _c2a69d
        .a8
        jsr _c2e367
        rts

_c2ac1e:
        jsr _c2ac90
        shorta
        stz $29a3
        stz $7528
        jsr _c2ac5e
        jsr _c2a698
        .a8
        lda $2889
        beq @ac5d
        lda $6f
        longa
        and #$00ff
        sec
        sbc $6b
        bmi @ac55
        cmp #$0016
        bpl @ac55
        clc
        adc #$0004
        jsr _c2c0c9
        shorta
        lda #$01
        sta $7510
        bra @ac5d
@ac55:  jsr _c2c0e2
        shorta
        stz $7510
@ac5d:  rts

_c2ac5e:
_ac5e:  php
        longa
        lda #near _c3b3a9
        jsr LoadMenuTilemap
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        tax
        shorta
        lda $7a00,x
        beq _ac8e
        lda $288a,x
        beq _ac8e
        longa
        and #$007f
        asl
        tax
.if LANG_EN
        .import _e0316d
        jml _e0316d
        .export _c2ac88 := *
.else
        lda f:ItemDescPtrs,x
.endif
        sta $2ceb
        jsr _c2da16
_ac8e:  plp
        rts

_c2ac90:
        .a16
        lda $08
        and #$1000
        beq @acc2
        lda $4b
        and #$0007
        cmp #$0003
        beq @acab
        cmp #$0004
        bne @acc2
        lda #$0016
        bra @acae
@acab:  lda #$ffea
@acae:  clc
        adc $6b
        bpl @acb5
        lda $8e
@acb5:  cmp $6d
        bmi @acbd
        beq @acbd
        lda $6d
@acbd:  sta $6b
        jsr _c2ac0e
        .a8
@acc2:  rts

_c2acc3:
        .a16
        lda #near _c3b434
        jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        jsr _c2a69d
        .a8
        ldx $7e
        lda $63,x
        sta $53
        rts

_c2acd6:
        .a16
        lda #near _c3b499
        jsr LoadMenuTilemap
        lda #near _c3b4a4
        jsr LoadMenuTilemap
        lda $7e29e2
        and #$0007
        asl
        tax
        lda f:_c0f3b3,x
        jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        jsr _c2a698
        .a8
        ldx $7e
        lda $50
        sta $63,x
        rts

_c2acff:
        .a16
        lda #near _c3b3fe
        jsr LoadMenuTilemap
        jsr _c2de3e
        jsr _c2df4d
        jsr _c2a69d
        .a8
        lda $54
        cmp #$13
        bne @ad37
        lda $29e2
        cmp #$04
        beq @ad37
        ldx $7e
        lda $0973
        and #$04
        bne @ad28
@ad24:  lda #$07
        sta $67,x
@ad28:  lda $67,x
        cmp #$07
        bmi @ad24
        cmp #$19
        bpl @ad24
        sta $53
        jsr _c2e6ab     ; update cursor sprite
@ad37:  jsr _c2c6ba
        jsr _c2a698
        .a8
        rts

; ---------------------------------------------------------------------------

_c2ad3e:
        .a16
_ad3e:  lda #near _c3b413
        jsr LoadMenuTilemap
        jsr _c2a69d
        .a8
        lda $51
        cmp #$13
        bne @ad5a
        lda $29e2
        cmp #$04
        beq @ad5a
        ldx $7e
        lda $50
        sta $67,x
@ad5a:  rts

; ---------------------------------------------------------------------------

_c2ad5b:
_ad5b:
        .a16
        lda $29e2
        and #$00ff
        cmp #$0006
        beq @adaf
        lda $55
        and #$00ff
        dec
        tax
        lda $7a00,x
        and #$00ff
        cmp #$00ff
        beq @ada9
        pha
        lda #near _c3b48e
        jsr LoadMenuTilemap
        pla
        cmp #$00fe
        beq @ada4
        pha
        and #$00ff
        ldy #$60d2      ; destination: 7E/60D2
        jsr _c2e42c     ; draw spell name
        lda #near _c3b409
        jsr LoadMenuTilemap
        pla
        clc
        adc #$2a9d
        tay
        ldx #$60f4
        lda #$7e31
        jsr _c2e4ed
@ada4:  jsr _c2a69d
        .a8
        bra @adaf
@ada9:  shorta
        lda $50
        sta $53
@adaf:  rts

; ---------------------------------------------------------------------------

_c2adb0:
        .a16
        lda #near _c3b41e
        jsr LoadMenuTilemap
        jsr _c2de3e
        jsr _c2df4d
        ldx #near _c3b8ec
        ldy #$7180
        jsr _c2c1fd
        jsr _c2a69d
        .a8
        stz $2b66
        rts

_c2adcc:
        .a16
        lda #near _c3b429
        jsr LoadMenuTilemap
        ldx #near _c3b8e6
        ldy #$7180
        jsr _c2c1fd
        jsr _c2a69d
        .a8
        rts

_c2addf:
        .a16
        lda #near _c3b2fe
        jsr LoadMenuTilemap
        jsr _c2c7bd
        jsr _c2a69d
        .a8
        lda #$08
        tsb $7500
        lda #$1c
        tsb $7502
        lda #$32
        sta $7505
        lda #$04
        tsb $750e
        lda #$04
        tsb $ca
        lda $2806
        sta $53
        jsr _c2e367
        lda #$07
        jsr _c2eee7
        rts

_c2ae11:
        .a16
        lda #near _c3b310
        jsr LoadMenuTilemap
        shorta
        lda #$08
        trb $7500
        stz $7502
        stz $7505
        lda #$04
        trb $750e
        lda #$04
        tsb $ca
        jsr _c2a698
        .a8
        rts

_c2ae31:
        .a16
        lda $55
@ae33:  and #$000f
        cmp #$0009
        beq @ae40
        jsr _c2f3f6
        bra @ae43
@ae40:  jsr _c2f450
@ae43:  jsr _c2faf0
        rts

_c2ae47:
        stz $2b6e
        rts

_c2ae4b:
        shorta
        lda $2b6f
        beq @ae5b
        lda $2b65
        and #$01
        eor #$01
        sta $53
@ae5b:  rts

; ---------------------------------------------------------------------------

_c2ae5c:
_ae5c:  jsr _c2ab4c
        lda #$08
        jsr _c2eee7
        lda $2886
        sta $750f
        rts

; ---------------------------------------------------------------------------

_c2ae6b:
_ae6b:  jsr _c2aba0
        rts

; ---------------------------------------------------------------------------

_c2ae6f:
_ae6f:  jsr _c2b2bd
        .a8
        longa
        ldx #$0500
        ldy #$2000
        lda #$05ff
        mvn #$7e,#$7e
        jsr _c2bf7d     ; get pointer to save slot in sram
        tax
        ldy #$0500
        lda #$05ff
        phb
        mvn #$30,#$00     ; load sram
        plb
        jsr _c2d230
        jsr _c2d3db
        jsr _c2d447     ; update window color
        jsr _c2a16e     ; reset sprite data
        ldx #near _c0f394
        jsr _c2d04c
        jsr _c2d4db
        ldx #$66ee
        jsr _c2d658
        ldx #$6630
        ldy #$094a
        jsr _c2d662
        lda #near _c3b5b8
        jsr LoadMenuTilemap
        lda $43         ; menu state
        and #$00ff
        cmp #$000c
        beq @aec8
        lda #near _c3b5df
        bra @aecb
@aec8:  lda #near _c3b5cf
@aecb:  jsr LoadMenuTilemap
        ldx #$2000
        ldy #$0500
        lda #$05ff
        mvn #$7e,#$7e
        shorta
        jsr _c2a106
        lda $750e
        sta f:hHDMAEN
        lda f:hRDNMI
        lda #$81
        sta f:hNMITIMEN
        lda #$00
        sta $7522
        sta $7525
        lda #$03
        sta $7513
        jsr _c2a698
        .a8
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2faf0
        lda #$0c
        tsb $7500
        tsb $7502
        lda #$02
        trb $7500
        lda #$04
        tsb $ca
        jsr _c2a69d
        .a8
        rts

; ---------------------------------------------------------------------------

_c2af1b:
        .a16
_af1b:  phb
        php
        ldx #near _c0f384
        jsr _c2d04c
        ldx $8e
@af25:  lda $0242,x
        ora #$2000
        sta $0242,x
        lda $0222,x
        beq @af39
        ora #$2000
        sta $0222,x
@af39:  inx4
        cpx #$0020
        bne @af25
        lda #near _c3b50d
        jsr LoadMenuTilemap
        ldx #near _c0f36a
        lda #$0011
        jsr _c2da9d
        stz $7e
@af53:  lda $7e
        asl
        tax
        lda f:_c0f362,x
        sta $2bba
        jsr _c2ddd7
        lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @af53
        jsr _c2a693
        .a8
        longa
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2faf0
        shorta
        lda $53
        sta $50
        lda $55
        sta $52
        lda $54
        sta $51
        plp
        plb
        rts

_c2af87:
        .a16
        lda $71
        and #$000f
        sta $7e
        jsr _c2d4c5

_c2af91:
        lda #near _c3b518
        jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        stz $7510
        longa
        ldx $8e
@afa1:  stz $0200,x
        inx2
        cpx #$0060
        bne @afa1
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2e66f
        rts
        stz $29ea
        stz $29ec
        stz $0206
        stz $020a
        stz $020e
        stz $0212
        lda $55
        and #$00ff
        cmp #$0005
        beq @aff4
@afce:  shorta
        lda $52
        cmp #$05
        bne @afde
        lda $29ee
        sta $53
        jsr _c2d210
@afde:  jsr _c2a892
        longa
        lda $55
        and #$000f
        dec
        tax
        shorta
        inc $29ea,x
        stz $7510
        bra @b04e
@aff4:  shorta
        lda $29e6
        and #$20
        bne @b005
        jsr _c2e0c0     ; play sound effect (error)
        jsr _c2a8cb
        bra @afce
@b005:  ldy $8e
@b007:  longa
        tya
        asl
        tax
        lda f:_c0ea64,x
        tax
        lda $0500,x
        and #$0040
        bne @b036
        tya
        asl
        tax
        lda f:_c0f37c,x
        pha
        tya
        asl2
        tax
        pla
        sta $0204,x
        lda #$2e02
        sta $0206,x
        shorta
        lda #$01
        sta $29ea,y
@b036:  iny
        cpy #$0004
        bne @b007
        shorta
        lda #$05
        sta $7510
        lda $52
        cmp #$05
        beq @b04e
        lda $50
        sta $29ee
@b04e:  rts

_c2b04f:
        jsr _c2af1b
        shorta
        lda #$08
        trb $7500
        lda #$02
        tsb $7500
        lda #$04
        tsb $ca
        rts
        shorta
        lda #$08
        tsb $7500
        lda #$02
        trb $7500
        lda #$04
        tsb $ca
        longa
        jsr _c2af91
        rts

_c2b079:
        lda #near _c3b7e9
        jsr LoadMenuTilemap
        ldx #near _c0ea04
        lda #$0009
        jsr _c2da9d
        jsr _c2f5c0
        ldx #near _c3b91d
        ldy #$7080
        jsr _c2c1fd
        ldx #near _c0ea1e
        ldy #$0240
        lda #$001f
        mvn #^_c0ea1e,#$7e
        stz $7e
@b0a2:  jsr _c2d4c5
        ldy $80
        lda $0500,y
        and #$0040
        beq @b0c1
        lda $7e
        asl3
        tax
        stz $0240,x
        stz $0242,x
        stz $0244,x
        stz $0246,x
@b0c1:  lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @b0a2
        stz $6f
        stz $71
        lda #$0020
        jsr _c2b154
        .a8
        rts

_c2b0d6:
        .a16
_b0d6:  lda #near _c3b739
        jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        lda #$02
        trb $7500
        lda #$04
        trb $7509
        lda #$20
        trb $750e
        lda #$04
        tsb $ca
        jsr _c2a16e     ; reset sprite data
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2e66f
        lda #$00
        sta f:hBG2VOFS
        sta f:hBG2VOFS
        rts

_c2b106:
        .a16
        lda #near _c3b710
        jsr LoadMenuTilemap
        lda #$0014
        sta $2c94
        stz $7e
@b114:  jsr _c2d4c5
        ldy $80
        lda $7e
        asl
        tax
        lda f:_c0ea8e,x
        tax
        lda $0500,y
        and #$0040
        bne @b133
        txy
        jsr _c2d533
        jsr _c2f7a6
        bra @b13d
@b133:  txy
        ldx #near _c0ea96
        lda #$0031
        mvn #^_c0ea96,#$7e
@b13d:  inc $2c94
        inc $7e
        lda $7e
        cmp #$0004
        bmi @b114
        lda #$0000
        jsr _c2b154
        .a8
        lda #$0e
        sta $50
        rts

_c2b154:
        shorta
        tsb $750e
        jsr _c2a693
        .a8
        lda #$02
        tsb $7500
        lda #$04
        tsb $7509
        lda #$04
        tsb $ca
        jsr _c2e66f
        rts

_c2b16e:
        shorta
        jsr _c2a878
        lda $55
        sec
        sbc #$15
        sta $7e
@b17a:  jsr _c2d4c5
        ldx $80
        bit $0500,x
        bvc @b18f
        lda $7e
        clc
        adc $e2
        and #$03
        sta $7e
        bra @b17a
@b18f:  lda $7e
        clc
        adc #$0f
        sta $53
        jsr _c2e6ab     ; update cursor sprite
        rts

_c2b19a:
        .a16
        lda #near _c3b740
        jsr LoadMenuTilemap
        ldx #near _c3b935
        ldy #$7080
        jsr _c2c1fd
        lda #$0028
        sta $2c94
@b1af:  jsr _c2f7a6
        inc $2c94
        lda $2c94
        cmp #$002f
        bmi @b1af
        lda #near _c3b77a
        jsr LoadMenuTilemap
        lda #$0020
        jsr _c2b154
        .a8
        rts

_c2b1ca:
        shorta
        lda $71
        and #$0f
        bne @b1d6
        lda $52
        sta $71
@b1d6:  dec
        sta $7e
        jsr _c2d4c5
        ldx $80
        bit $0500,x
        bvc @b1eb
        jsr _c2e0c0     ; play sound effect (error)
        stz $71
        jsr _c2a8cb
@b1eb:  rts

; ---------------------------------------------------------------------------

_c2b1ec:
        .a16
_b1ec:  lda #near _c3b3c2
        jsr LoadMenuTilemap
        lda $2d1b
        ldy #$4284
        jsr _c2e44e
        jsr _c2cecc     ; get list of available jobs
        stz $85
@b200:  ldy $85
        lda $7a00,y
        and #$00ff
        cmp #$00ff
        beq @b251
        cmp #$0015
        beq @b251
        asl2
        tax
        lda $85
        asl
        tay
        lda f:JobEquipTbl,x   ; job equipment types
        and $2d1d
        sta $2d21,y
        lda f:JobEquipTbl+2,x
        and $2d1f
        ora $2d21,y
        pha
        tyx
        lda f:_c0e901,x
        sta $99
        ldy $85
        lda $7a00,y
        and #$00ff
        ldy $99
        jsr _c2e4c7
        pla
        bne @b24d
        lda #$0108
        ldx $99
        jsr _c2d6dc
@b24d:  inc $85
        bra @b200
@b251:  lda $8e
        jsr _c2b154
        .a8
        rts

; ---------------------------------------------------------------------------

_c2b257:
_b257:  jsr _c2b0d6
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2b25b:
_b25b:  jmp _c2a4f0

; ---------------------------------------------------------------------------

; [  ]

_c2b25e:
_b25e:  lda $53
        sta $59
        cmp #$00
        beq @b29e
        cmp #$01
        beq @b2b1
        cmp #$03
        beq @b28a
        cmp #$04
        beq @b28a
        cmp #$05
        beq @b28a
        cmp #$02
        beq @b293
        cmp #$07
        beq @b28f
        cmp #$06
        beq @b293
        bra @b287
@b284:  jsr _c2e0c0     ; play sound effect (error)
@b287:  jmp _c2a4f0
@b28a:  lda #$0c
        jmp _c2a47c
@b28f:  lda $44
        bpl @b284
@b293:  jsr _c2b2bd
        .a8
        jsr _c2c0e2
        lda $55
        jmp _c2a06b     ; show menu
@b29e:  longa
        lda $0840       ; available jobs
        bne @b2ad
        lda $0842
        and #$00f8
        beq @b284
@b2ad:  shorta
        bra @b28a
@b2b1:  longa
        lda $08f3
        ora $08f5
        bne @b2ad
        bra @b284

; ---------------------------------------------------------------------------

; accumulator can be 16-bit when called but will always be 8-bit on return

_c2b2bd:
        shorta
        lda #$00
        sta $7e7510
        sta $7e750f
        sta $7e751d
        sta $7e751e
        stz $ca
        lda #$04
        sta $7e7513
@b2d9:  jsr _c2e66f
        jsr _c2fc2f
        lda $7e7513
        bne @b2d9
        lda #$01
        sta f:hNMITIMEN
        jsr _c2a106
        lda #$00
        sta f:hHDMAEN
        lda #$80
        sta f:hINIDISP
        rts

; ---------------------------------------------------------------------------

_c2b2fb:
        lda $53
        sta $59
        jmp CommonReturn     ; exit menu

; ---------------------------------------------------------------------------

; [ order/row A button pressed ]

_c2b302:
_b302:  lda $6f
        bne @b317       ; branch if first selection is made
        lda $55
        sta $6f         ; select first character
        lda $53
        jsr _c2c0c4
        lda #$01
        sta $7510
        jmp _c2a4f0
@b317:  lda $55
        sta $70
        cmp $6f
        bne @b345       ; branch if not the same character
        dec
        sta $7e
        jsr _c2d4c5
        ldx $80
        lda $0500,x     ; toggle character row
        eor #$80
        sta $0500,x
        ldx #near _c0f394
        jsr _c2d04c
        jsr _c2e6ab     ; update cursor sprite
        jsr _c2c0e2
        stz $6f
        shorta
        stz $7510
        jmp _c2a4f0
@b345:  dec $6f
        dec $70
        stz $7510
        longa
        lda $6f
        jsr _c2b3e9
        lda $70
        jsr _c2b3e9
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2e66f
        phb
        shorta
        lda #^_c0effb
        pha
        plb
        longa
        lda $6f
        and #$0003
        asl
        tax
        lda $70
        and #$0003
        asl
        tay
        lda _c0effb,x
        sta $e0
        lda _c0effb,y
        sta $e2
        lda #near _c0f053
        sta $e4
@b384:  lda ($e0)
        tax
        lda ($e2)
        tay
        lda ($e4)
        beq @b39f
        jsr _c2e610
        inc $e0
        inc $e0
        inc $e2
        inc $e2
        inc $e4
        inc $e4
        bra @b384
@b39f:  plb
        longa
        lda $6f
        jsr _c2b3db
        ldx #near _c0f394
        jsr _c2d04c
        jsr _c2c0e2
        lda $70
        jsr _c2b3db
        jsr _c2faf0
        jsr _c2e6ab     ; update cursor sprite
        jsr _c2e66f
        jsr _c2d4db
        stz $ca
        jsr _c2a698
        .a8
        lda $6f
        sta a:$0000
        lda $70
        sta a:$0001
        jsl _c10009     ; swap character saved cursor positions
        stz $6f
        stz $70
        jmp _c2a4f0

; ---------------------------------------------------------------------------

; [  ]

_c2b3db:
        .a16
_b3db:  and #$0003
        asl
        tax
        lda f:_c0f3cd,x
        tax
        jsr _c2a6a0
        rts

_c2b3e9:
        .a16
_b3e9:  and #$0003
        asl
        tax
        lda f:_c0eb08,x
        tax
        stz a:$0000,x
        stz a:$0002,x
        stz a:$0004,x
        stz a:$0006,x
        txa
        sec
        sbc #$0020
        tax
        stz a:$0000,x
        stz a:$0002,x
        rts

; ---------------------------------------------------------------------------

; [ order/row B button pressed ]

_c2b40c:
_b40c:  jsr _c2c0e2
        stz $7510
        jsr _c2fad4     ; copy sprite data to vram
        lda $6f
        bne @b422
        lda $53
        sta $5a
        lda $59
        jmp _c2a47c
@b422:  stz $6f
        stz $70
        jmp _c2a4f0

; ---------------------------------------------------------------------------

; [  ]

_c2b429:
        .a16
_b429:  lda $55
        dec
        sta $71
        longa
        and #$000f
        asl
        tax
        lda f:_c0ea64,x
        tay
        shorta
        lda $59
        jsr _c2e4e1     ; get pointer to cursor data
        lda $7601,x
        cmp #$05
        beq @b463
        cmp #$02
        bne @b45c
        lda $55
        dec
        longa
        and #$000f
        tax
        shorta
        lda $08f3,x
        beq @b47a
@b45c:  lda $051a,y
        and #$c2
        bne @b47a
@b463:  lda $53
        and #$0b
        sta $5a
        jsr _c2c0e2
        jsr _c2b2bd
        .a8
        lda $59
        jsr _c2e4e1     ; get pointer to cursor data
        lda $7601,x
        jmp _c2a06b     ; show menu
@b47a:  jsr _c2e0c0     ; play sound effect (error)
        jmp _c2a4f0

_c2b480:
        stz $7510
        lda $53
        sec
        sbc #$04
        sta $5a
        lda $59
        jmp _c2a47c

_c2b48f:
        lda $55
        cmp #$04
        beq _c2b4a8
        lda #$01
        sta $7510
        lda $55
        sta $6f
        lda $53
        jsr _c2c0c0
        lda #$04
        jmp _c2a47c

_c2b4a8:
@b4a8:  lda $45
        bpl @b4b0
        and #$02
        bne @b4d4
@b4b0:  longa
        stz $0200
        stz $0202
        jsr _c2fad4     ; copy sprite data to vram
        shorta
        lda $2d12
        ora $2d11
        beq @b4cc
        jsr _c2b676
        lda #$04
        bra @b4d1
@b4cc:  jsr _c2b2bd
        .a8
        lda #$01
@b4d1:  jmp _c2a06b     ; show menu
@b4d4:  jmp _c2a4f0

; ---------------------------------------------------------------------------

; [  ]

_c2b4d7:
_b4d7:  longa
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        tax
        ldy $80
        lda $0501,y     ; job
        and #$00ff
        tay
        lda $6f
        and #$00ff
        cpy #$0014
        beq @b4f7       ; branch if mimic
        dec
@b4f7:  clc
        adc $80
        tay
        shorta
        lda $7a00,x
        sta $0516,y
        lda #$01
        sta $2d12
        jsr _c2e973
        jsr _c2cfa4
        jsr _c2a698
        .a8

_c2b511:
        jsr _c2c0e2
        stz $7510
        lda $6f
        dec
        stz $6f
        stz $70
        jmp _c2a47c

; ---------------------------------------------------------------------------

_c2b521:
_b521:  lda $6f
        jne @b56d
        lda $55
        sta $6f
        longa
        and #$00ff
        dec
        asl3
        tax
        lda $0292,x
        and #$fe00
        sta $0292,x
        sta $0296,x
        lda $0290,x
        sta $0240
        lda $0294,x
        sta $0244
        lda #$0b8c
        sta $0242
        lda #$0bac
        sta $0246
        shorta
        jsr _c2faf0
        stz $751e
        stz $751d
        lda #$01
        sta $750f
        jmp _c2a4f0
@b56d:  lda $55
        sta $70
        lda #$01
        sta $2d11
        stz $750f
        stz $751e
        longa
        jsr _c2d503
        jsr _c2e464
        lda $6f
        and #$00ff
        dec
        tax
        lda $7a00,x
        and #$001f
        sta $d8
        jsr _c2e47d
        ldy $80
        lda $dc
        sta $053b,y
        shorta
        lda $da
        sta $053a,y
        lda $d8
        sta $0501,y
        longa
        jsr _c2cdc6
        jsr _c2d45f
        jsr _c2d298
        longa
        stz $6f
        stz $0240
        stz $0242
        stz $0244
        stz $0246
        lda $7e
        jsr _c2b3db
        jsr _c2cde3     ; init job sprites
        jsr _c2cd57
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2faf0
        jsr _c2e66f
        stz $ca
        jsr _c2a698
        .a8
        jsr _c2daa4
        phx
        ldx $7e
        inc $0420,x
        plx
        jsr _c2eb82

_c2b5ea:
        lda $6f
        bne @b637
        lda $45
        bpl @b5f9
        and #$01
        jne _c2a4f0
@b5f9:  lda $2d11
        bne @b606
        jsr _c2b2bd
        .a8
        lda #$01
        jmp _c2a06b
@b606:  ldx $7e
        lda $08f3,x
        beq @b62f
        longa
        lda #near _c3af2b
        jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        lda #$02
        tsb $7500
        lda #$04
        tsb $ca
        ldx #$0028
        jsr _c2e65b
        jsr _c2b2bd
        .a8
        lda #$02
        jmp _c2a06b
@b62f:  jsr _c2b676
        lda #$04
        jmp _c2a06b
@b637:  stz $750f
        stz $751e
        longa
        stz $0242
        stz $0246
        lda $6f
        and #$00ff
        dec
        tay
        lda $7a00,y
        and #$00ff
        tax
        lda f:_c0ee6a,x
        and #$00ff
        ora #$0b00
        pha
        tya
        asl3
        tay
        pla
        sta $0292,y
        clc
        adc #$0020
        sta $0296,y
        jsr _c2fad4     ; copy sprite data to vram
        stz $6f
        jmp _c2a4f0

_c2b676:
        php
        shorta
        lda $0973
        and #$01
        longa
        bne @b687
        lda #near _c3aec8
        bra @b68a
@b687:  lda #near _c3aed9
@b68a:  jsr LoadMenuTilemap
        jsr _c2a693
        .a8
        lda #$02
        tsb $7500
        lda #$04
        tsb $ca
        jsr _c2e658
        jsr _c2b2bd
        .a8
        jsr _c2daa4
        ldx $7e
        inc $0420,x
        jsr _c2e6d6
        lda $0973
        and #$01
        bne @b6b7
        jsr _c2faad
        jsr _c2f869
@b6b7:  plp
        rts

_c2b6b9:
        lda $74
        cmp #$03
        beq @b6c6
        cmp #$04
        beq @b6f3
        jmp _c2a4f0
@b6c6:  lda $55
        sta $6f
        stz $70
        jsr _c2e178
        jsr _c2e211
        lda $73
        jsr _c2e286
        lda $90
        beq @b6e0
        jsr _c2e0c0     ; play sound effect (error)
        bra @b6e8
@b6e0:  lda #$01
        xba
        lda $73
        jsr _c2e2ce
@b6e8:  jsr _c2e18f
        jsr _c2b7a0
        .a8
        stz $6f
        jmp _c2a4f0
@b6f3:  lda $55
        sta $6f
        stz $70
        lda $6f
        cmp #$03
        bpl @b704
        jsr _c2ed87
        bra @b707
@b704:  jsr _c2ed5e
@b707:  ldx $75
        beq @b745
        jsr _c2e66f
        jsr _c2ee94
        longa
        lda $75
        sec
        sbc #$0009
        bpl @b71e
        lda #$0000
@b71e:  sta $6d
        stz $6b
        jsr _c2caa5
        lda $6f
        and #$00ff
        dec
        jsr _c2c0c0
        lda $0204
        sta $0208
        lda $0206
        sta $020a
        jsr _c2c0e2
        jsr _c2a69d
        .a8
        lda #$0a
        jmp _c2a47c
@b745:  jsr _c2e0c0
        jmp _c2a4f0

_c2b74b:
        stz $6f
        lda #$05
        jmp _c2a47c

_c2b752:
        lda $55
        sta $74
        cmp #$04
        beq @b76c
        cmp #$03
        beq @b76c
        cmp #$02
        beq @b771
        cmp #$01
        beq @b77c
        cmp #$05
        beq _c2b796
        bra @b791
@b76c:  lda #$00
        jmp _c2a47c
@b771:  jsr _c2daa4
        jsr _c2e66f
        jsr _c2b7a0
        .a8
        bra @b791
@b77c:  jsr _c2daa4
        jsr _c2e66f
        jsr _c2faad
        jsr _c2e66f
        jsr _c2f869
        jsr _c2e66f
        jsr _c2b7a0
        .a8
@b791:  lda #$05
        jmp _c2a47c

_c2b796:
@b796:  jsr _c2b2bd
        .a8
        stz $74
        lda #$01
        jmp _c2a06b

_c2b7a0:
@b7a0:  jsr _c2e76c
        jsr _c2cac8
        jsr _c2cc9e
        jsr _c2a698
        .a8
        rts

_c2b7ad:
        jsr _c2e0f7
        lda $90
        bne @b7f6
        jsr _c2e286
        lda $90
        bne @b7f6
        jsr _c2e178
        jsr _c2e211
        lda #$01
        xba
        lda $73
        jsr _c2e2ce
        jsr _c2e1a6
        lda #$01
        xba
        lda $72
        jsr _c2e328
        jsr _c2e18f
        longa
        lda #near _c3b005
        jsr LoadMenuTilemap
        jsr _c2b7a0
        .a8
        stz $2d11
        stz $2d12
        stz $70
        stz $73
        stz $72
        lda $6f
        dec
        and #$07
        jmp _c2a47c

@b7f6:  jsr _c2e0c0
        jmp _c2a4f0

_c2b7fc:
        longa
        lda #near _c3b005
        jsr LoadMenuTilemap
        jsr _c2a698
        .a8
        stz $70
        lda $6f
        dec
        and #$07
        jmp _c2a47c

_c2b811:
@b811:  lda $71
        inc
        and #$03
        sta $71
        sta $7e
        stz $7f
        jsr _c2d4c5
        ldx $80
        lda $0500,x
        and #$40
        bne @b811
        longa
        lda #near _c3b095
        jsr LoadMenuTilemap
        lda #near _c3b0d3
        jsr LoadMenuTilemap
        jsr _c2c8a0
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2a698
        .a8
        jsr _c2a69d
        .a8
        jmp _c2a4f0

_c2b845:
        jsr _c2b2bd
        .a8
        lda #$01
        jmp _c2a06b

_c2b84d:
        lda $55
        cmp #$01
        beq @b85e
        cmp #$02
        beq @b86f
        cmp #$03
        beq _c2b879
        jmp _c2a4f0
@b85e:  stz $2804
        lda $2802
        bmi @b86a
        lda #$03
        bra @b86c
@b86a:  lda #$10
@b86c:  jmp _c2a47c
@b86f:  lda #$80
        sta $2804
        lda #$18
        jmp _c2a47c

_c2b879:
@b879:  jmp CommonReturn

_c2b87c:
        lda $55
        dec
        sta $2807
        stz $2808
        ldx $2807
        lda $2826,x
        sta $2809
        lda $287e,x
        sta $2810
        longa
        txa
        asl
        tax
        asl
        tay
        lda $284e,x
        sta $280a
        lda $282e,y
        sta $280c
        lda $2830,y
        sta $280e
        rts

_c2b8ae:
        jsr _c2b87c
        jsr _c2f070
        shorta
        lda $2813
@b8b9:  beq @b8d0
        ldx #$2815
        ldy #$2819
        jsr _c2eec8
        bcc @b8dc
        bit $2805
        bmi @b8fd
        lda #$0b
        jmp _c2a47c
@b8d0:  jsr _c2e0c0     ; play sound effect (error)
        lda #$03
        jsr _c2eee7
        lda #$01
        bra @b8f2
@b8dc:  jsr _c2e0c0     ; play sound effect (error)
        lda #$02
        jsr _c2eee7
        lda $2801
        cmp #$03
        bne @b8f0
        jsr _c2e658
        bra @b8f5
@b8f0:  lda #$00
@b8f2:  jsr _c2eefd
@b8f5:  lda #$00
        jsr _c2eee7
        jmp _c2a4f0
@b8fd:  lda #$01
        sta $39
        jsr _c2b922
        jsr _c2e0c0     ; play sound effect (error)
        longa
        lda #near _c3b349
        jsr LoadMenuTilemap
        jsr _c2a698
        .a8
        lda #$00
        jsr _c2eefd
        jsr _c2e658
        jmp CommonReturn

_c2b91d:
        lda #$00
        jmp _c2a47c

_c2b922:
        lda $281d
        sta $2815
        sta $0947
        lda $281e
        sta $2816
        sta $0948
        lda $281f
        sta $2817
        sta $0949
        lda $2814
        xba
        lda $2809
        jsr _c2e2ce
        rts

_c2b948:
        .a16
_b948:  lda #$0001
        jsr _c2eee7
        lda #$0038
        jsr _c2e0d9     ; play sound effect
        rts

_c2b955:
        ldx #$2815
        ldy #$2819
        jsr _c2eec8
        bcc @b97e
        jsr _c2b922
        longa
        ldx #$51e8
        ldy #$2815
        lda #$7e73
        jsr _c2e4ed
        jsr _c2b948
        jsr _c2e658
        shorta
        lda #$03
        jmp _c2a47c
@b97e:  jsr _c2e0c0     ; play sound effect (error)
        lda #$02
        jsr _c2eee7
        lda #$00
        jsr _c2eefd
        lda #$00
        jsr _c2eee7
        jmp _c2a4f0

_c2b993:
        lda #$03
        jmp _c2a47c

_c2b998:
        jsr _c2b87c
        jsr _c2f03e
        shorta
        lda $2811
        bne @b9e1
        ldx #$2815
        ldy #$2819
        jsr _c2eec8
        bcc @b9ee
        lda $281d
        sta $2815
        sta $0947
        lda $281e
        sta $2816
        sta $0948
        lda $281f
        sta $2817
@b9c8:  sta $0949
        jsr _c2efe3
        longa
        ldx #$51e8
        ldy #$2815
        lda #$7e73
        jsr _c2e4ed
        jsr _c2b948
        bra @b9f9
@b9e1:  longa
        jsr _c2e0c0     ; play sound effect (error)
        lda #$006
        jsr _c2eee7
        bra @b9f9
@b9ee:  longa
        jsr _c2e0c0     ; play sound effect (error)
        lda #$0002
        jsr _c2eee7
@b9f9:  jsr _c2e658
        lda #$0000
        jsr _c2eee7
        jmp _c2a4f0
        .a8

_c2ba05:
        lda #$00
        jmp _c2a47c

_c2ba0a:
        stz $6f
        stz $70
        lda #$00
        sta $2889
        lda $55
        cmp #$01
        beq @ba24
        cmp #$03
        beq @ba37
        cmp #$04
        beq @ba44
        jmp _c2a4f0
@ba24:  lda $0973
        and #$04
        bne @ba2f
        lda #$04
        bra @ba34
@ba2f:  lda $5b
        clc
        adc #$04
@ba34:  jmp _c2a47c
@ba37:  longa
        jsr _c2e002
        jsr _c2ac0e
        .a8
        lda #$00
        jmp _c2a47c
@ba44:  longa
        lda #near _c3b3b4
        jsr LoadMenuTilemap
        lda #near _c3b360
        jsr LoadMenuTilemap
        jsr _c2c73d
        jsr _c2a69d
        .a8
        jsr _c2a698
        .a8
        lda #$01
        sta $2d15
        jmp _c2a4f0

_c2ba63:
        lda $2d15
        beq @ba75
        stz $2d15
        longa
        jsr _c2ac0e
        .a8
        lda #$00
        jmp _c2a47c
@ba75:  jsr _c2b2bd
        .a8
        lda #$01
        jmp _c2a06b

_c2ba7d:
        lda $2889
        bne @baa1
        longa
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        shorta
        sta $6f
        lda $53
        jsr _c2c0c9
        lda #$01
        sta $7510
        sta $2889
        jmp _c2a4f0
@baa1:  longa
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        shorta
        sta $70
        cmp $6f
        beq @baf8
        longa
        lda $6f
        and #$00ff
        tax
        lda $70
        and #$00ff
        tay
        shorta
        lda $0640,x
        xba
        lda $0640,y
        sta $0640,x
        xba
        sta $0640,y
        lda $0740,x
        xba
        lda $0740,y
        sta $0740,x
        xba
        sta $0740,y
        stz $7510
        jsr _c2c0e2
        jsr _c2c7bd
        jsr _c2a69d
        .a8
        stz $6f
        stz $70
        stz $2889
        lda $53
        jmp _c2a47c
@baf8:  longa
        lda $70
        and #$00ff
        tax
        shorta
        lda $7a00,x
        sta $29e7
        phx
        jsr _c2dada
        plx
        lda $29e7
        bne @bb15
@bb12:  jmp @bbac
@bb15:  lda #$40
        sta $29e6
        lda $7b00,x
        bmi @bb12
        beq @bb12
        cmp #$64
        bpl @bb12
        sta $29e8
        stz $29e9
        lda $29e7
        cmp #$f0
        beq @bb90
        cmp #$f1
        beq @bb90
        longa
        and #$00ff
        cmp #$00f8
        bmi @bb47
        cmp #$00fc
        bpl @bb47
        bra @bb66
@bb47:  asl
        tax
        lda $d000,x
        tax
        ldy #$29f3
        lda #$0007
        mvn #$d1,#$7e
        shorta
        lda $55
        dec
        sta $5b
        lda $6b
        sta $5c
        lda #$1c
        jmp _c2a47c
        .a16
@bb66:  and #$00ff
        sec
        sbc #$00f8      ; subtract 248 from item index
        tax
        lda f:_c0eeae,x   ; spells learned from items (ifrit, ramuh, shoat, golem)
        jsr _c2f00b     ; give spell
        lda f:_c0eeb2,x   ; sound effect to play
        jsr _c2e0d9     ; play sound effect
        lda $29e7
        and #$00ff
        ora #$0100
        jsr _c2e328
        jsr _c2c7bd
        jsr _c2a69d
        .a8
        bra @bbeb
@bb90:  sta $39
        stz $3a
        bit $44
        bpl @bba6
        longa
        and #$00ff
        ora #$0100
        jsr _c2e328
        jmp CommonReturn     ; exit menu
@bba6:  stz $39
        stz $3a
        bra @bbeb
@bbac:  lda $7a00,x
        longa
        and #$00ff
        beq @bbeb
        cmp #$00e0
        bpl @bbeb
        sta $2d1b
        jsr _c2d9ab
        lda $9d
        and #$003f
        asl2
        tax
        lda f:EquipTypeTbl,x   ; item equipment
        sta $2d1d
        lda f:EquipTypeTbl+2,x
        sta $2d1f
        stz $6f
        jsr _c2c0e2
        shorta
        stz $2889
        lda $55
        dec
        sta $5b
        lda #$22
        jmp _c2a47c
@bbeb:  shorta
        stz $6f
        stz $70
        stz $2889
        jsr _c2c0e2
        jmp _c2a4f0

_c2bbfa:
        lda $2889
        bne @bc14
        stz $6f
        stz $70
        stz $2889
        lda $55
        dec
        sta $5b
        lda $6b
        sta $5c
        lda #$00
        jmp _c2a47c
@bc14:  stz $6f
        stz $70
        stz $2889
        stz $7510
        jsr _c2c0e2
        jsr _c2fad4     ; copy sprite data to vram
        jmp _c2a4f0

_c2bc27:
@bc27:  jmp _c2a4f0

_c2bc2a:
@bc2a:  jmp _c2a4f0

_c2bc2d:
@bc2d:  ldx $7e
        lda $53
        sta $63,x
        lda $55
        dec
        sta $29e2
        longa
        and #$0007
        tax
        lda f:_c0f3a4,x
        shorta
        jmp _c2a47c

_c2bc48:
        jsr _c2b2bd
        .a8
        lda #$00
        xba
        lda $71
        tax
        lda $53
        sta $63,x
        lda $71
        sta $5d
        lda #$01
        jmp _c2a06b     ; show menu

_c2bc5e:
        longa
        lda $55
        and #$00ff
        dec
        tax
        lda $7a00,x
        and #$00ff
        tax
        shorta
        bit $29fb,x
        bvc @bca9
        sta $29e7
        lda $29fb,x
        sta $29e6
        lda $2a9d,x
        sta $29e8
        stz $29e9
        lda $29e7
        cmp #$3e
        beq @bcb1
        longa
        txa
        asl3
        clc
        adc #$0b80
        tax
        ldy #$29f3
        lda #$0007
        mvn #$d1,#$7e
        shorta
        lda #$1f
        jmp _c2a47c
@bca9:  stz $39
        jsr _c2e0c0     ; play sound effect (error)
        jmp _c2a4f0
@bcb1:  sta $39
        lda $44
        and #$02
        beq @bca9
        stz $3a
        longa
        lda $71
        and #$000f
        sta $7e
        jsr _c2d4c5
        ldy $80
        lda $050a,y
        sec
        sbc $29e8
        sta $050a,y
        sta $29df
        jmp CommonReturn     ; exit menu

_c2bcd9:
        ldx $7e
        lda $63,x
        jmp _c2a47c

; ---------------------------------------------------------------------------

; [  ]

_c2bce0:
_bce0:  longa
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        tax
        shorta
        lda $7a00,x     ; item index
        beq @bd37       ; branch if no item
        sta $2809
        lda $288a,x
        sta $2810
        lda $53
        sta $2806
        stz $2825
        jsr _c2f29f     ; get item price
        bit $280a
        bmi @bd37       ; branch if item can't be sold
        bvc @bd1c       ; branch if item doesn't sell for 5gp
        lda #$0a
        sta $280c       ; price is 10gp
        stz $280d
        stz $280e
        stz $280f
@bd1c:  longa
        lsr $280e       ; divide price by 2
        ror $280c
        jsr _c2f070
        shorta
        lda $2811
        sta $2813
        stz $2886
        lda #$32
        jmp _c2a47c
@bd37:  jsr _c2e0c0     ; play sound effect (error)
        jmp _c2a4f0

; ---------------------------------------------------------------------------

; [  ]

_c2bd3d:
_bd3d:  lda $53
        sta $2806
        lda #$00
        jmp _c2a47c

_c2bd47:
        lda $55
        cmp #$05
        bpl @bd72
        dec
        sta $6f
        lda $53
        sta $62
        jsr _c2bda5
        .a16
        beq @bd64
        jsr _c2bef7     ; save sram
        jsr _c2b2bd
        .a8
        lda #$0b
        jmp _c2a06b     ; show menu
@bd64:  shorta
        lda $53
        sta $62
        stz $2d13
        lda #$04
        jmp _c2a47c
@bd72:  cmp #$09
        beq @bd90
        dec
        and #$03
        sta $6f
        jsr _c2bda5
        .a16
        bne @bd9f
        shorta
        lda $53
        sta $62
        lda #$01
        sta $2d13
        lda #$05
        jmp _c2a47c
@bd90:  stz $62
        longa
        stz $39
        jsr _c2a1f0     ; init config settings
        jsr _c2ff7d     ; update joypad config
        jmp CommonReturn     ; exit menu
@bd9f:  jsr _c2e0c0     ; play sound effect (error)
        jmp _c2a4f0

_c2bda5:
        longa
        and #$0003
        asl5
        tax
        lda $7e2c14,x
        rts
        .a8

_c2bdb5:
        lda $43         ; menu state
        cmp #$0c
        jeq _c2a4f0
        jsr _c2b2bd
        .a8
        lda #$01
        jmp _c2a06b

_c2bdc6:
        lda $55
        cmp #$03
        beq @bddb
        dec
        sta $2b65
        jsr _c2c4da
        jsr _c2a69d
        .a8
        lda #$03
        jmp _c2a47c
@bddb:  ldx $8e
@bddd:  lda $0990,x
        cmp #$ff
        bne @bdf0
        inx
        cpx #$0006
        bne @bddd
        jsr _c2e0c0       ; play sound effect (error)
        jmp _c2a4f0
@bdf0:  jmp CommonReturn     ; exit menu

_c2bdf3:
        jmp _c2a4f0

_c2bdf6:
        longa
        lda $55
        and #$00ff
        dec
        tax
        shorta
        jsr _c2c51d
        cmp #$ff
        beq @be2b
        ldy $2b92
        sta $0990,y
        cpy #$0005
        bpl @be14
        iny
@be14:  sty $2b92
        jsr _c2c551
        longa
        ldx #$51c4
        ldy #$0990      ; butz's name
        lda #$0006
        jsr _c2e59d
        jsr _c2a698
        .a8
@be2b:  jmp _c2a4f0

; ---------------------------------------------------------------------------

_c2be2e:
_be2e:  ldx $2b92
        lda $0990,x
        cmp #$ff
        beq @be3f
        lda #$ff
        sta $0990,x
        bra @be4a
@be3f:  cpx #$0000
        beq @be4a
        dex
        lda #$ff
        sta $0990,x
@be4a:  stx $2b92
        jsr _c2c551
        longa
        ldx #$51c4
        ldy #$0990
        lda #$0006
        jsr _c2e59d
        jsr _c2a698
        .a8
        jmp _c2a4f0

_c2be64:
        longa
        lda $2815
        clc
        adc $2819
        sta $2815
        lda $2817
        adc $281b
        sta $2817
        shorta
        ldx #$2821
        ldy #$2815
        jsr _c2eec8
        bcs @be94
        longa
        lda $2821
        sta $2815
        lda $2823
        sta $2817
@be94:  shorta
        lda $2814
        xba
        lda $2809
        jsr _c2e328
        longa
        ldx #$51e8
        ldy #$2815
        lda #$7e73
        jsr _c2e4ed
        lda $2815
        sta $0947
        lda $2817
        sta $0949
        jsr _c2b948
        jsr _c2e658
        lda #$0000
        jsr _c2eee7
        shorta

_c2bec8:
        lda #$18
        jmp _c2a47c

_c2becd:
        lda $55
        cmp #$01
        beq @beda
        cmp #$02
        beq @bef1
        jmp _c2a4f0
@beda:  ldy $8e
@bedc:  lda $2b9a,y
        beq @beeb
        xba
        lda $2ba2,y
        beq @beeb
        xba
        jsr _c2e2ce
@beeb:  iny
        cpy #$0008
        bne @bedc
@bef1:  jmp CommonReturn     ; exit menu

; ---------------------------------------------------------------------------

_c2bef4:
        jmp _c2a4f0

; ---------------------------------------------------------------------------

; [ save sram ]

_c2bef7:
_bef7:  php
        longa
        inc $09c2
        jsr _c2bf7d     ; get pointer to save slot in sram
        phx
        tay
        ldx #$0500      ; copy $0600 bytes from 00/0500
        lda #$05ff
        phb
        phy
        mvn #$00,#$30     ; save sram
        ply
        plb
        sty $fc
        jsr _c2f588
        plx
        sta $307ff0,x
        lda #$e41b
        sta $307ff8,x
        lda $6f
        and #$0003
        sta $307fe0
        jsr _c2e0c8
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

; [ load sram ]

_c2bf2e:
_bf2e:  lda $55
        cmp #$01
        jne _c2bf89
        lda $2d13
        bne @bf47
        jsr _c2bef7     ; save sram
        jsr _c2b2bd
        .a8
        lda #$0b
        jmp _c2a06b     ; show menu
@bf47:  jsr _c2a1f0     ; init config settings
        lda $094a
        pha
        php
        longa
        jsr _c2bf7d     ; get pointer to save slot in sram
        tax
        ldy #$0500
        lda #$05ff
        phb
        mvn #$30,#$00     ; load sram
        plb
        plp
        pla
        clc
        adc $0af9       ; update random
        sta $0af9
        lda $6f
        sta $62
        longa
        lda #$0001
        sta $39
        jsr _c2ff7d     ; update joypad config
        jsr _c2f5a9     ; update mono/stereo setting
        jmp CommonReturn     ; exit menu

; ---------------------------------------------------------------------------

; [ get pointer to save slot in sram ]

_c2bf7d:
_bf7d:  lda $6f
        and #$0003      ; save slot
        asl
        tax
        lda f:_c0f8ef,x   ; pointer to save slot in sram
        rts

; ---------------------------------------------------------------------------

_c2bf89:
_bf89:  jsr _c2d447     ; update window color
        jsr _c2b2bd
        .a8
        lda $2d13
        bne @bf98
        lda #$0b
        bra @bf9a
@bf98:  lda #$0c
@bf9a:  jmp _c2a06b     ; show menu

; ---------------------------------------------------------------------------

_c2bf9d:
_bf9d:  jsr _c2dc1b
        longa
        lda $71
        and #$000f
        sta $7e
        jsr _c2d4c5
        jsr _c2c6ba
        shorta
        jsr _c2af1b
        jsr _c2a698
        .a8
        ldx #$0005
        jsr _c2e65b
        longa
        lda $29df
        cmp $29e8
        jpl _c2a4f0
        jsr _c2e653
_c2bfcd:
        shorta
        lda #$07
        jmp _c2a47c

_c2bfd4:
        jsr _c2daef
        jsr _c2c7bd
        jsr _c2a69d
        .a8
        jsr _c2af1b
        jsr _c2a698
        .a8
        ldx #$0005
        jsr _c2e65b
        lda $29e8
        jne _c2a4f0
        jsr _c2e653
_c2bff4:
        stz $6f
        stz $70
        stz $2889
        lda $5b
        clc
        adc #$04
        jmp _c2a47c

_c2c003:
        lda $55
        cmp #$05
        beq @c01c
        sta $71
        longa
        and #$00ff
        dec
        asl2
        clc
        adc #$0021
        shorta
        jmp _c2a47c
@c01c:  longa
@c01e:  ldx #near _c0f352
        ldy #$2cb4
        lda #$000f
        mvn #^_c0f352,#$7e
        stz $6f
        jsr _c2c0ed
        .a8
        ldx $8e
@c031:  inc $0420,x
        inx
        cpx #$0004
        bne @c031
        stz $71
        lda #$1b
        jmp _c2a47c

_c2c041:
        lda #$03
        jmp _c2a47c

_c2c046:
        lda #$00
        xba
        lda $55
        dec
        tax
        lda $2c9c,x
        beq @c05b
        lda f:_c0f069,x
        jne _c2a47c
@c05b:  jmp _c2a4f0

_c2c05e:
        jsr _c2f71c     ; update config settings
        jsr _c2b2bd
        .a8
        lda #$01
        jmp _c2a06b

_c2c069:
        jmp _c2a4f0

_c2c06c:
        lda #$09
        jmp _c2a47c

_c2c071:
        lda $55
        cmp #$01
        jne _c2a4f0
        ldx $8e
        txa
@c07d:  ora $2ca9,x
        inx
        cpx #$0007
        bmi @c07d
        and #$fc
        cmp #$fc
        bne @c097
        jsr _c2f71c     ; update config settings
        jsr _c2ff7d     ; update joypad config
        lda #$08
        jmp _c2a47c
@c097:  jsr _c2e0c0
        longa
        lda #near _c3b7d2
        jsr LoadMenuTilemap
        jsr _c2a693
        jsr _c2a16e     ; reset sprite data
        jsr _c2fad4     ; copy sprite data to vram
        ldx #$0078
        jsr _c2e65b
        longa
        jsr _c2b19a
        shorta
        lda $53
        jmp _c2a47c

_c2c0bd:
        jmp _c2a4f0

; ---------------------------------------------------------------------------

; [  ]

_c2c0c0:
_c0c0:  ldy $8e
        bra _c0cc

_c2c0c4:
        ldy #$fc04
        bra _c0cc

_c2c0c9:
        ldy #$ff02
_c0cc:  jsr _c2e4e1       ; get pointer to cursor data
        php
        longa
        tya
        clc
        adc $7602,x
        sta $0204
        lda #$2e02
        sta $0206
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2c0e2:
_c0e2:  php
        longa
        stz $0204
        stz $0206
        plp
        rts

_c2c0ed:
_c0ed:  jsr _c2f5c0
        jsr _c2a693
        .a8
        jsr _c2e66f
        rts

_c2c0f7:
        lda $6f
        bne @c10c
        lda #$01
        sta $7510
        lda $55
        sta $6f
        lda $53
        jsr _c2c0c9
@c109:  jmp _c2a4f0
@c10c:  lda $55
        cmp $6f
        beq @c109
        dec
        longa
        and #$000f
        tax
        lda $6f
        dec
        and #$000f
        tay
        shorta
        lda $2cb4,x
        xba
        lda $2cb4,y
        sta $2cb4,x
        xba
        sta $2cb4,y
        stz $7510
        jsr _c2c0ed
        .a8
        longa
        lda $71
        and #$000f
        dec
        tax
        shorta
        inc $0420,x
        bra _c155

_c2c146:
        lda $6f
        bne _c155
        lda $71
        dec
        and #$03
        clc
        adc #$1b
        jmp _c2a47c
_c155:  longa
        stz $6f
        jsr _c2c0e2
        jsr _c2fad4     ; copy sprite data to vram
        jmp _c2a4f0
        .a8

; ---------------------------------------------------------------------------

_c2c162:
_c162:  lda $5b
        clc
        adc #$04
        jmp _c2a47c

; ---------------------------------------------------------------------------

; [  ]

_c2c16a:
        .a16
_c16a:  phb
        lda $43         ; menu state
        and #$00ff
        dec
        asl
        tax
        lda f:_c0f5e7,x   ; pointer to ??? ($+C00000)
        tax
        ldy #$2bdc      ; copy 24 bytes to 7E/2BDC
        lda #$0017
        mvn #^_c0f5e7,#$7e
        ldx $8e
_c183:  lda f:_c0f5cf,x   ; mvn destination address (+$7E0000)
        sta $e6
        phx
        lda f:_c0e7e7,x   ; jump address
        sta $c7
        lda $2bdc,x     ; pointer to data
        per @c199-1
        jmp ($01c7)
@c199:  plx
        inx2
        cpx #$0018
        bne _c183
        plb
        jsr _c2a18a
        rts

; ---------------------------------------------------------------------------

; [ load menu cursor/hardware register data ]

_c2c1a6:
_c1a6:  phb
        tax
        beq @c1b6
        ldy $e6                         ; pointer to data ($+7E0000)
        lda $c30000,x                   ; length of data
        dec                             ; -1 for mvn instruction
        inx2
        mvn #$c3,#$7e
@c1b6:  plb
        rts

; ---------------------------------------------------------------------------

; [ load menu tilemap ]

; +A: address of tilemap data (+$C30000)

LoadMenuTilemap:
        .a16
_c1b8:  phb
        pea $c3c3
        plb
        plb
        tax
        beq @c1ed
@c1c1:  pea $c3c3
        plb
        plb
        lda a:$0000,x
        inx
        and #$000f
        beq @c1f5
        asl
        tay
        lda $ad31,y                     ; number of bytes to load
        beq @c1de
        phy
        ldy #$01e0
        mvn #$c3,#$00
        ply
@c1de:  pea $7e7e
        plb
        plb
        phx
        php
        tyx
        jsr (near _c2ffea,x)
        plp
        plx
        bra @c1c1
@c1ed:  pea $7e7e
        plb
        plb
        jsr _c2c25f
@c1f5:  plb
        rts

; ---------------------------------------------------------------------------

; [ load v-scroll hdma table ]

; +A: table data offset (+$C30000)

_c2c1f7:
_c1f7:  ldy $e6
        tax
        bne _c2c1fd                     ; return if no data
        rts

; ---------------------------------------------------------------------------

; [ load v-scroll hdma table ]

; +X: table data offset (+$C30000)
; +Y: HDMA table offset

_c2c1fd:
_c1fd:  phb
        php
        stz $85
@c201:  shorta
        lda $c30000,x
        beq @c23a
        bmi @c221                       ; branch if more than 127 lines
@c20b:  sta a:$0000,y                   ; number of lines
        longa
        lda $85
        sta a:$0001,y                   ; v-scroll offset
        clc
        adc #$0004                      ; add 4 to v-scroll offset
        sta $85
        iny3
        inx
        bra @c201
        .a8
@c221:  pha
        lda #$7f
        sta a:$0000,y                   ; 127 lines
        lda $85
        sta a:$0001,y
        lda #$00
        sta a:$0002,y
        iny3
        pla
        and #$7f
        inc
        bra @c20b
@c23a:  lda #$00
        sta a:$0000,y
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2c242:
        .a16
_c242:  pha
        php
        lda $e3
        and #$003f
        xba
        lsr2
        sta $e8
        lda $e2
        and #$001f
        asl
        clc
        adc $e8
        clc
        adc $e6
        sta $e8
        plp
        pla
        rts

; [ menu tilemap command $00: clear tilemap buffer ]

_c2c25f:
_c25f:  stz $e0

; [ menu tilemap command $01: fill tilemap buffer ]

_c2c261:
        lda $e0
        ldy #$1000
@c266:  dey2
        sta ($e6),y
        bne @c266
        rts

; [ menu tilemap command $05: set tilemap location ]

_c2c26d:
        lda $e0
        sta $e6
        rts

_c2c272:
_c272:  sta a:$0000,x
        inx2
        dey
        bne _c272
        rts

_c2c27b:
@c27b:  dey2
        dec
        sta a:$0000,x
        inx2
        inc
        jsr _c2c272
        inc
        sta a:$0000,x
        rts

_c2c28c:
        .a16
_c28c:  pha
        ldy $8e
@c28f:  lda $01,s
        sta ($ec),y
        txa
        sta ($ee),y
        dec $ea
        beq @c2a2
        tya
        clc
        adc #$0040
        tay
        bra @c28f
@c2a2:  pla
        rts

; [ menu tilemap command $02: fill bg ]

_c2c2a4:
        .a16
_c2a4:  jsr _c2c242
        lda $e5
        and #$00ff
        sta $ea
        ldx $e8
        lda $e4
        and #$007f
        tay
@c2b6:  phx
        phy
        lda $e0
        jsr _c2c272
        ply
        plx
        dec $ea
        beq @c2cb
        txa
        clc
        adc #$0040
        tax
        bra @c2b6
@c2cb:  rts

_c2c2cc:
        jsr _c2c2e8
        lda #$00ff
        sta $e0
        shorta
        inc $e2
        inc $e3
        dec $e4
        dec $e4
        dec $e5
        dec $e5
        longa
        jsr _c2c2a4
        rts

; [ menu tilemap command $03:  ]

_c2c2e8:
_c2e8:  jsr _c2c242
        lda $e8
        tax
        clc
        adc #$0040
        sta $ec
        lda $e4
        and #$003f
        tay
        lda $e0
        jsr _c2c27b
        txa
        clc
        adc #$0040
        sta $ee
        lda $e5
        and #$007f
        dec2
        sta $ea
        lda #$0004
        ldx #$0005
        jsr _c2c28c
        tya
        clc
        adc #$0080
        adc $e8
        tax
        lda $e4
        and #$003f
        tay
        lda #$0007
        jsr _c2c27b
        rts

; ---------------------------------------------------------------------------

; [ menu tilemap command $04: draw menu text ]

_c2c32d:
        jsr _c2c242
        lda $e0
        and #$00ff
        asl
        tax
        lda f:MenuTextPtrs,x
        tay
.if LANG_EN
        .import _e02ff0
        jml _e02ff0
        .export _c2c340 := *
        jsr _c2e59d
        nop6
        .export _c2c349 := *
.else
        ldx $e8
        lda $e4
        and #$00ff
        ora #$c000
        jsr _c2e59d
.endif
        rts

; ---------------------------------------------------------------------------

; [ menu state $08:  ]

_c2c34a:
_c34a:  jsr _c2f63d
        lda $8e
        sta $7e2c94
@c353:  jsr _c2f7a6
        lda $7e2c94
        inc
        sta $7e2c94
        cmp #$000a
        bne @c353
        jsr _c2f810
        shorta
        stz $53
        jsr _c2d210
        rts

; ---------------------------------------------------------------------------

; [ menu state $09:  ]

_c2c36f:
_c36f:  pea $7e7e
        plb
        plb
        shorta
        stz $53
        jsr _c2d210
        ldx #$0008
@c37e:  stz $2b99,x
        stz $2ba1,x
        stz $2ba9,x
        stz $2bb1,x
        dex
        bne @c37e
        ldy $8e
@c38f:  lda $013b,y
        beq @c3b1
        ldx $8e
@c396:  lda $2b9a,x
        beq @c3a8
        cmp $013b,y
        beq @c3ae
        inx
        cpx #$0008
        bne @c396
        bra @c3b1
@c3a8:  lda $013b,y
        sta $2b9a,x
@c3ae:  inc $2ba2,x
@c3b1:  iny
        cpy #$0008
        bne @c38f
        ldy $8e
@c3b9:  lda $2b9a,y
        beq @c3c8
        jsr _c2c419
        sta $2baa,y
        xba
        sta $2bb2,y
@c3c8:  iny
        cpy #$0008
        bne @c3b9
        jsr _c2c3d2
        rts

_c2c3d2:
_c3d2:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        ldx #$5246
        stx $99
        ldx #$0008
        stx $85
        ldx $8e
        jsr _c2c3fd
        ldx #$5264
        stx $99
        ldx #$0008
        stx $85
        ldx #$0010
        jsr _c2c3fd
        plp
        plb
        rts

_c2c3fd:
_c3fd:  lda $2b9a,x
        xba
        lda $2ba2,x
        xba
        php
        phx
        ldy $99
        jsr _c2e3a6
        longa
        jsr _c2cb8c
        plx
        plp
        inx
        dec $85
        bne _c3fd
        rts

_c2c419:
_c419:  php
        ldx $8e
@c41c:  cmp $0640,x
        beq @c43b
        inx
        cpx #$0100
        bne @c41c
        ldx $8e
@c429:  lda $0640,x
        beq @c435
        inx
        cpx #$0100
        bne @c429
        dex
@c435:  longa
        lda $8e
        bra @c440
@c43b:  xba
        lda $0740,x
        xba
@c440:  plp
        rts

; ---------------------------------------------------------------------------

; [ menu state $0C:  ]

_c2c442:
_c442:  pea $7e7e
        plb
        plb
        shorta
        lda #$01
        sta $2b65
        stz $2b66
        stz $2b67
        lda #$0a
        sta $2b68
        sta $2b69
        stz $2b6c
        lda #$80
        sta $2b6d
        stz $2b6e
        stz $2b6f
        stz $53
        jsr _c2d210
        jsr _c2c4da
.if LANG_EN
        .import _e0311e
        jml _e0311e
        .a16
        nop
        .export _c2c477 := *
.else
        longa
        stz $2b92
.endif
        jsr _c2c551
        lda #$ffff
.if LANG_EN
        .import _e0312a
        jml _e0312a
        nop5
        .export _c2c486 := *
.else
        sta $0990
        sta $0992
        sta $0994
.endif
        ldx #$51c4
        ldy #$0990
        lda #$0006
        jsr _c2e59d
        ldx #near _c0ec07
        ldy #$2b70
        lda #$0009
        mvn #^_c0ec07,#$7e
        ldx #near _c0ec11
        ldy #$2b80
        lda #$0009
        mvn #^_c0ec11,#$7e
        lda #$0018
        sta $2b6a
        ldx #$0080
@c4b3:  stz $79fe,x
        dex2
        bne @c4b3
        lda #$ffff
        sta $7a62
        stz $7e
@c4c2:  jsr _c2d4c5
        ldx $80
        lda $0500,x
        and #$0007
        beq @c4d3
        inc $7e
        bra @c4c2
@c4d3:  lda #$3c1c
        jsr _c2c8de
        rts

_c2c4da:
_c4da:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        ldx #$6194
        stx $99
        longa
        ldx $8e
@c4ec:  ldy $8e
@c4ee:  jsr _c2c544
        cpy #$000a
        bne @c4ee
        lda #$00ff
        sta $2b3f,y
        iny
@c4fd:  jsr _c2c544
        cpy #$0015
        bmi @c4fd
        phx
        ldx $99
        ldy #$2b3f
        lda #$7e14
        jsr _c2e59d
        jsr _c2cb8c
        plx
        cpx #$0064
        bne @c4ec
        plp
        plb
        rts

_c2c51d:
_c51d:  php
        longa
        lda f:_c0f414,x
        and #$00ff
        cmp #$0048
        beq @c53f
        cmp #$0053
        bmi @c53b
        cmp #$0060
        bmi @c53f
        cmp #$00c4
        bpl @c53f
@c53b:  clc
.if LANG_EN
        nop3
.else
        adc $2b65
.endif
@c53f:  and #$00ff
        plp
        rts
        .a8

_c2c544:
_c544:  jsr _c2c51d
        ora #$00
        sbc $2b3f99,x
        iny2
        inx
        rts

_c2c551:
_c551:  php
        phb
        longa
        lda #near _c3b62b
        jsr LoadMenuTilemap
        plb
        longa
        lda $2b92
        asl
        tax
        lda #$00e0
        sta $5204,x
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

; [ menu state $0B:  ]

_c2c56b:
        .a16
_c56b:  phb
        php
        stz $39
        jsr _c2f4d4
        ldx $8e
@c574:  lda $7e2c14,x
        beq @c587
        txa
        clc
        adc #$0020
        tax
        cpx #$0080
        bne @c574
        bra @c599
@c587:  inc $39
        shorta
        lda $307fe0
        and #$03
        inc
        sta $53
        jsr _c2c59c
        stz $6f
@c599:  plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2c59c:
_c59c:  jsr _c2d210
        jsr _c2f463
        jsr _c2f450
        jsr _c2f3f6
        jsr _c2f39c
        longa
        lda #$6000
        sta $e6
        lda #near _c3ada6
        jsr LoadMenuTilemap
        rts

; ---------------------------------------------------------------------------

; [ menu state $0A: collect items after battle ]

_c2c5b9:
_c5b9:  jsr _c2f4d4
        shorta
        lda $62
        sta $53
        jsr _c2c59c
        stz $6f
        rts

; ---------------------------------------------------------------------------

; [ menu state $07:  ]

_c2c5c8:
        .a16
_c5c8:  lda $71
        and #$0007
        sta $7e
        jsr _c2d4c5
        jsr _c2c6ba
        lda #near _c3b434
        jsr LoadMenuTilemap
        pea $7e7e
        plb
        plb
        ldx #$0950      ; known spells
        ldy #$29b8
        lda #$001f
        mvn #$7e,#$7e
        ldx $80
        ldy $8e
        shorta
@c5f2:  lda $053d,x     ; spell level
        pha
        and #$f0
        lsr4
        pha
        asl
        clc
        adc $01,s
        sta $29d8,y
        pla
        pla
        iny
        cpy #$0005
        beq @c61b
        and #$0f
        pha
        asl
        clc
        adc $01,s
        sta $29d8,y
        pla
        iny
        inx
        bra @c5f2
@c61b:  lda #$20
        sta $29d8,y
        lda #$08
        sta $29d9,y
        ldx #$00a2
@c628:  stz $29f9,x
        stz $2a9b,x
        dex
        bne @c628
        ldy $8e
@c633:  tya
        jsr _c2f01d
        and $29b8,x
        beq @c63e
        lda #$80
@c63e:  sta $29fb,y
        tya
        longa
        and #$00ff
        asl3
        tax
        shorta
        lda $d10b83,x                   ; attack properties
        and #$7f
        sta $2a9d,y
        lda $d10b80,x
        and #$c0
        lsr2
        ora $29fb,y
        sta $29fb,y
        iny
        cpy #$00a0
        bne @c633
        shorta
        stz $29e2
        stz $6f
        stz $70
        ldx $7e
        lda $0973
        and #$04
        bne @c682
        stz $63,x
        lda #$07
        sta $67,x
@c682:  lda $63,x
        sta $53
        jsr _c2d210
        lda #$03
        sta $2b68
        lda #$0a
        sta $2b69
        longa
        stz $2b6c
        stz $2b6e
        ldx #near _c0ebfa
        ldy #$2b70
        lda #$0002
        mvn #^_c0ebfa,#$7e
        ldx #near _c0ebfd
        ldy #$2b80
        lda #$0009
        mvn #^_c0ebfd,#$7e
        lda #$00c8
        sta $2b6a
        rts

_c2c6ba:
_c6ba:  phb
        php
        longa
        ldx #near _c0ef85
        lda #$0017
        jsr _c2da9d
        lda #$5000
        sta $2bba
        jsr _c2ddd7
        lda #$3012
        jsr _c2c8de
        ldx $80
        lda $050a,x
        sta $29df
        shorta
        lda $051a,x
        sta $29e1
        plp
        plb
        rts

_c2c6e9:
_c6e9:  php
        longa
        ldy #$2ce5
        lda #$0005
        mvn #$c0,#$7e
        plp
        rts

; ---------------------------------------------------------------------------

; [ menu state $06: shop ]

_c2c6f7:
_c6f7:  shorta
        lda #$7e
        pha
        plb
        lda $0973
        and #$04
        bne @c708
        stz $5c
        stz $5b
@c708:  longa
        lda $5c
        and #$00ff
        sta $6b
        jsr _c2c7bd
        shorta
        lda $5b
        clc
        adc #$04
        sta $53
        jsr _c2d210
        stz $2d15
        stz $2887
        stz $2889
        lda #$02
        sta $29b6
        jsr _c2e367
        ldx #near _c0e94e
        jsr _c2c6e9
        longa
        jsr _c2ac5e
        rts

_c2c73d:
_c73d:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldy $8e
        stz $85
_c74a:  phy
        tya
        shorta
        jsr _c2f01d
        and $0a4a,x
        beq _c776
        longa
        ldx $85
.if LANG_EN
        .import _e736a0
        lda f:_e736a0,x
.else
        lda f:_c0e974,x
.endif
        sec
        sbc #$00c2
        inx2
        stx $85
        tax
.if LANG_EN
        .import _e02fd3
        jml _e02fd3
        .export _c2c76b := *
        clc
        adc #$3500                      ; key item names
        tay
        lda #$e70d
.else
        tya
        asl3
        clc
        adc #near KeyItemName
        tay
        lda #make_word 8, ^KeyItemName
.endif
        jsr _c2e59d
_c776:  ply
        iny
        cpy #$0020
        bne _c74a
        plp
        plb
        rts

_c2c780:
_c780:  php
        ldx $8e
@c783:  shorta
        lda $7a00,x
        bne @c792
        stz $7b00,x
        stz $288a,x
        bra @c7b5
@c792:  phx
        longa
        and #$00ff
        pha
        jsr _c2d9ab
        pla
        cmp #$00e0
        shorta
        bmi @c7aa
        lda $9e
        and #$3f
        bra @c7b1
@c7aa:  lda $9f
        and #$3f
        clc
        adc #$00
@c7b1:  plx
        sta $288a,x
@c7b5:  inx
        cpx #$0100
        bne @c783
        plp
        rts

_c2c7bd:
_c7bd:  phb
        php
        longa
        lda #$00ea
        sta $6d
        stz $6f
        ldx #$0640
        ldy #$7a00
        lda #$01ff
        mvn #$7e,#$7e
        jsr _c2c780
        ldx $8e
        lda $6b
        and #$00ff
        tay
@c7df:  lda f:_c0ed8f,x
        phx
        phy
        tyx
        tay
        jsr _c2e3f3
        ply
        plx
        inx2
        iny
        cpx #$0030
        bne @c7df
        ldx #near _c0f250
        ldy #$298a
        lda #$0015
        mvn #^_c0f250,#$7e
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ menu state $05:  ]

_c2c803:
_c803:  shorta
        lda #$7e
        pha
        plb
        lda $35
        sta $2800
        stz $39
        stz $2805
        lda $2800
        cmp #$3e
        beq @c81e
        cmp #$3f
        bne @c823
@c81e:  lda #$80
        sta $2805
@c823:  stz $2804
        jsr _c2f18f
        longa
        ldx $8e
@c82d:  stz $2807,x
        inx2
        cpx #$001e
        bne @c82d
        lda $0947
        sta $2815
        lda $0949
        and #$00ff
        sta $2817
        lda #$967f
        sta $2821
        lda #$0098
        sta $2823
        ldx #$51e8
        ldy #$2815
        lda #$7e73
        jsr _c2e4ed
        jsr _c2f15b
        shorta
        lda #$0b
        jsr _c2cfbd
        .a16
        shorta
        stz $5c
        stz $5b
        lda #$18
        sta $2806
        longa
        stz $6b
        stz $6f
        lda #$0003
        sta $29b6
        ldx #near _c0e954
        jsr _c2c6e9
        ldy $8e
@c887:  sty $7e
        jsr _c2d4c5
        ldx $80
        lda $0500,x
        and #$1f07
        phy
        jsr _c2d492
        ply
        iny
        cpy #$0004
        bne @c887
        rts

; ---------------------------------------------------------------------------

; [ menu state $04:  ]

_c2c8a0:
_c8a0:  shorta
        lda #$0a
        jsr _c2cfbd
        .a16
        jsr _c2e76c
        jsr _c2c954
        ldy $80
        lda $051a,y
        and #$007f
        beq @c8bc
        lda #$3b28
        bra @c8bf
@c8bc:  lda #$3b3c
@c8bf:  jsr _c2c8de
        ldx $8e
        ldy $80
@c8c6:  phx
        phy
        lda f:_c0ee4b,x
        tax
        lda $0516,y
        jsr _c2d8e4
        ply
        plx
        iny
        inx2
        cpx #$0008
        bne @c8c6
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2c8de:
_c8de:  phb
        php
        longa
        pha
        jsr _c2d0b2
        lda $7e
        asl
        tax
        lda f:_c0eb08,x
        tax
        phx
        ldy #$0348
        lda #$0007
        mvn #$7e,#$7e
        plx
        stz a:$0000,x
        stz a:$0002,x
        stz a:$0004,x
        stz a:$0006,x
        lda $0348
        clc
        adc $01,s
        sta $0348
        lda $034c
        clc
        adc $01,s
        sta $034c
        txa
        sec
        sbc #$0020
        tax
        lda a:$0002,x
        beq @c93d
        phx
        ldy #$0340
        lda #$0003
        mvn #$7e,#$7e
        plx
        lda $0340
        clc
        adc $01,s
        sta $0340
        stz a:$0000,x
        stz a:$0002,x
@c93d:  pla
        plp
        plb
        rts

_c2c941:
        .a16
_c941:  php
        lda $80
        clc
        adc #$0500
        tax
        ldy #$2700
        lda #$0045
        mvn #$7e,#$7e
        plp
        rts

_c2c954:
        .a16
_c954:  phb
        php
        longa
        ldx #near _c0ef9d
        lda #$0017
        jsr _c2da9d
        lda #$5000
        sta $2bba
        jsr _c2ddd7
        jsr _c2c941
        lda $2702
        and #$00ff
        pha
        asl
        clc
        adc $01,s
        tax
        pla
        lda $2703
        sta $2746
        lda $2705
        and #$00ff
        sta $2748
        lda $d15000,x                   ; experience progression values
        sec
        sbc $2746
        sta $2746
        lda $d15002,x
        and #$00ff
        sbc $2748
        sta $2748
        lda $2702
        and #$00ff
        cmp #$0063
        bmi @c9b2
        stz $2746
        stz $2748
@c9b2:  ldx $7e
        lda $08f3,x
        and #$00ff
        sta $274a
        ldx $8e
@c9bf:  phx
        lda f:_c0ee03,x
        tay
        lda f:_c0ee1b,x
        pha
        lda f:_c0ee33,x
        tax
        pla
        jsr _c2e4ed
        plx
        inx2
        cpx #$0018
        bne @c9bf
        lda $2702
        and #$00ff
        cmp #$0063
        bmi @c9f2
        ldx #near _c0edf5
        ldy #$5510
        lda #$000d
        mvn #^_c0edf5,#$7e
@c9f2:  lda $2715
        and #$00ff
        cmp #$00ff
        beq @ca18
        pha
        lda #near _c3b195
        jsr LoadMenuTilemap
        pla
        asl3
        clc
        adc #$5c00      ; D0/5C00 (monster names)
        tay
        ldx #$56c8      ; copy 8 bytes to 7E/56C8
        lda #$d008
        jsr _c2e59d
        bra @ca34
@ca18:  lda #near _c3b185
        jsr LoadMenuTilemap
        lda $2740
        sta $f9
        lda $2742
        sta $fb
        ldy #$5686
        jsr _c2d802
        ldy #$56c6
        jsr _c2d7f6
@ca34:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ menu state $03:  ]

_c2ca37:
_ca37:  lda $71
        sta $7e
        jsr _c2d4c5
        stz $6f
        stz $72
        shorta
        lda $2d12
        ora $2d11
        beq @ca57
        lda $0973
        and #$01
        bne @ca57
        lda #$06
        bra @ca59
@ca57:  lda #$05
@ca59:  sta $53
        jsr _c2e6ab     ; update cursor sprite
        longa
        lda #near _c3b036
        jsr LoadMenuTilemap
        lda #$1e98
        jsr _c2c8de
        ldy #$51ac
        jsr _c2d533
        ldy #$522c
        jsr _c2d554
        jsr _c2e76c
        jsr _c2cac8
        jsr _c2cc9e
        ldy #$52ae
        jsr _c2d7ca
        longa
        stz $6b
        lda #$00f6
        sta $6d
        longa
        ldx #near _c0f2d4
        ldy #$298a
        lda #$0015
        mvn #^_c0f2d4,#$7e
        lda #$0001
        sta $29b6
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2caa5:
_caa5:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx $8e
        lda #$63c4
        sta $99
@cab5:  phx
        ldy $99
        jsr _c2cb8c
        jsr _c2e3e3
        plx
        inx
        cpx #$000a
        bne @cab5
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2cac8:
_cac8:  phb
        php
        longa
        stz $2cdf
        stz $2ce1
        lda #$0001
        sta $2ce3
        ldx $80
        shorta
        ldy $8e
        lda #$20
        and $0521,x
        beq @caeb
        lda #$91
        sta $2cdf,y
        iny
@caeb:  lda #$01
        and $0521,x
        beq @caf7
        lda #$92
        sta $2cdf,y
@caf7:  ldx $80
        lda $0513,x
        bne @cb04
        lda $0511,x
        jsr _c2cbf1
@cb04:  sta $f0
        lda $0514,x
        bne @cb11
        lda $0512,x
        jsr _c2cbf1
@cb11:  sta $f1
        lda $050e,x
        jsr _c2cbf1
        sta $f2
        lda $050f,x
        jsr _c2cbf1
        sta $f3
        lda $0510,x
        jsr _c2cbf1
        sta $f4
        lda $f0
        bne @cb35
        lda $f1
        beq @cb6b
        bra @cb39
@cb35:  lda $f1
        bne @cb6b
@cb39:  lda $f0
        ora $f1
        jsr _c2d9ab
        lda $9f
        bit #$80
        bne @cb53
        bit #$40
        beq @cb6b
        ldx $80
        lda $0521,x
        and #$20
        beq @cb6b
@cb53:  lda $f0
        beq @cb61
        lda #$02
        sta $2ce1
        inc $2ce4
        bra @cb6b
@cb61:  lda #$02
        sta $2ce3
        inc $2ce2
        bra @cb6b
@cb6b:  longa
        ldx $8e
        lda #$5192
        sta $99
@cb74:  phx
        ldy $99
        jsr _c2cb8c
        lda $f0,x
        jsr _c2e44e
        plx
        inx
        cpx #$0005
        bne @cb74
        jsr _c2cb95
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2cb8c:
_cb8c:  lda $99
        clc
        adc #$0080
        sta $99
        rts

_c2cb95:
        longa
        lda $2cdf
        and #$00ff
        beq @cba5
        ldx #$5328
        jsr _c2cbe1
@cba5:  lda $2ce0
        and #$00ff
        beq @cbb3
        ldx #$53a8
        jsr _c2cbe1
@cbb3:  ldx $8e
@cbb5:  phx
        lda f:_c0ea44,x
        sta $e6
        lda $2ce1,x
        pha
        and #$000f
        asl
        tax
        lda f:_c0ea3e,x
        jsr LoadMenuTilemap
        pla
        and #$ff00
.if LANG_EN
        ora #$0006
.else
        ora #$0004
.endif
        ldx $e6
        jsr _c2d6dc
        plx
        inx2
        cpx #$0004
        bne @cbb5
        rts
        .a8

_c2cbe1:
        .a16
        phx
        asl
        tax
        lda $7ed600,x                   ; pointers to battle command names
        tay
        plx
        lda #$d108
        jsr _c2e59d
        rts
        .a8

_c2cbf1:
        cmp #$80
        bne @cbf7
        lda #$00
@cbf7:  rts

_c2cbf8:
_cbf8:  phb
        php
        lda $f1
        sta $2723
        lda $f2
        sta $272c
        lda $f3
        sta $272d
        lda $f5
        sta $272f
        longa
        lda $eb
        sta $2728
        lda $ed
        sta $272a
        lda $f6
        sta $2744
        ldx $8e
@cc21:  phx
        lda f:_c0ee09,x
        sta $f6
        tay
        lda f:_c0edbf,x
        sta $fe
        lda f:_c0ee21,x
        sta $f8
        lsr4
        and #$000f
        sta $fc
        lda f:_c0ede3,x
        sta $fa
        tax
        lda $f8
        jsr _c2e4ed
        lda $fe
        clc
        adc $80
        tax
        lda $01,s
        tay
        lda a:$0000,x
        cpy #$0008
        beq @cc5e
        and #$00ff
@cc5e:  and #$01ff
        sta $fe
        ldy $f6
        lda $01,s
        tax
        lda a:$0000,y
        cpx #$0008
        beq @cc73
        and #$00ff
@cc73:  and #$01ff
        cmp $fe
        beq @cc93
        bpl @cc81
        lda #$8100
        bra @cc84
@cc81:  lda #$8200
@cc84:  cpx #$0010
        bne @cc8c
        eor #$0300
@cc8c:  ora $fc
        ldx $fa
        jsr _c2d6dc
@cc93:  plx
        inx2
        cpx #$0012
        bne @cc21
        plp
        plb
        rts
        .a8

_c2cc9e:
_cc9e:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        jsr _c2c941
        ldx $8e
@ccac:  phx
        lda f:_c0ee09,x
        tay
        lda f:_c0ee21,x
        pha
        lda f:_c0edd1,x
        tax
        pla
        jsr _c2e4ed
        plx
        inx2
        cpx #$0012
        bne @ccac
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

; [ menu state $02: job menu ]

_c2cccb:
_cccb:  phb
        shorta
        lda #$06
        jsr _c2cfbd
        .a16
        stz $53
        jsr _c2d210     ; init cursor ???
        stz $6f
        jsr _c2d503
        jsr _c2e464
        jsr _c2cdc6     ; update current character data
        jsr _c2d388
        jsr _c2cecc     ; get list of available jobs
        jsr _c2cde3     ; update job sprites
        jsr _c2cd57     ; update selected job palette
        phb
        ldx #near _c0ee53
        jsr _c2d9fb
        plb
        stz $2d11
        ldx #near _c0e95a
        jsr _c2c6e9
        jsr _c2a9d9
        jsr _c2cd08     ; update job name, level, and equipment
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2cd08:
_cd08:  php
        longa
        lda $55
        and #$00ff
        dec
        tax
        lda $7a00,x
        and #$001f
        shorta
        sta $d8
        jsr _c2e47d
        longa
        ldy #$65c4
        lda $d8
        jsr _c2e4c7
        ldy #$65d4
        jsr _c2d93f
        ldy #$65d6
        jsr _c2d588
        ldy #$65da
        jsr _c2d59d
        lda $d8
        and #$001f
        asl2
        tax
        lda f:JobEquipTbl,x                   ; job equipment types
        sta $f9
        lda f:JobEquipTbl+2,x
        sta $fb
        ldy #$65f2
        jsr _c2d7d8
        plp
        rts

; ---------------------------------------------------------------------------

; [ update selected job palette ]

_c2cd57:
_cd57:  php
        longa
        lda $55
        and #$00ff
        dec
        tay
        ldx $80
        shorta
        lda $7a00,y
        sta $eb
        lda $0500,x
        and #$07
        sta $ea
        longa
        lda #$c180
        sta $e4
        jsr _c2d2db
        lda #$000c
        ldx #near _c0ed31
        jsr _c2d304
        ldx #near _c0ee53
        ldy #$7514
        lda #$0008
        mvn #^_c0ee53,#$7e
        longa
        lda $ea
        and #$1f07
        ldy #$0005
        jsr _c2d492
        lda $55
        and #$00ff
        dec
        asl2
        tay
        asl
        tax
        shorta
        lda $0293,x
        and #$f1
        ora #$0a
        sta $0293,x
        sta $0297,x
        lda $0363,y
        and #$f1
        ora #$08
        sta $0363,y
        sta $0363,y
        plp
        rts

; ---------------------------------------------------------------------------

; [ update current character data ]

_c2cdc6:
_cdc6:  php
        longa
        ldx #near _c0efc7
        lda #$0011
        jsr _c2da9d
        lda #$5000
        sta $2bba
        jsr _c2ddd7
        lda #$1016
        jsr _c2c8de
        plp
        rts

; ---------------------------------------------------------------------------

; [ update job sprites ]

_c2cde3:
_cde3:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        lda $80
        clc
        adc #$054a      ; job stat modifiers
        tay
        ldx #near _c0e92b      ; C0/E92B (default stat modifiers)
        lda #$0005
        mvn #^_c0e92b,#$7e     ; copy to ram
        stz $85
        stz $d8
        ldx #$0090      ; start at sprite 36
        stx $ec
        ldy $8e
@ce07:  shorta
        lda $7a00,y
        bmi @ce5a       ; branch if at end of available job list
        longa
        and #$00ff
        sta $d8         ; job index
        tax
        lda f:_c0ee6a,x   ; tile offset
        and #$00ff
        ora #$0d00      ; priority 0, palette 6, tile offset msb set
        sta $e2
        clc
        adc #$0020
        sta $e6
        tya
        asl
        tax
        lda f:_c0ee82,x   ; sprite xy position
        sta $e0
        clc
        adc #$1000
        sta $e4
        ldx $ec
        lda $e0
        sta $0200,x     ; top sprite
        lda $e2
        sta $0202,x
        lda $e4
        sta $0204,x     ; bottom sprite
        lda $e6
        sta $0206,x
        txa
        clc
        adc #$0008
        sta $ec
        jsr _c2ce5d     ; update character sprite
        iny
        bra @ce07       ; next job
@ce5a:  plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

; [ update character sprite ]

_c2ce5d:
        .a16
_ce5d:  jsr _c2e47d     ; get character job data
        ldx $d8
        cpx #$0015
        bne @ce70       ; branch if not freelancer
        lda $85
        cmp #$0015
        beq @ce7b
        bra @ce9d
@ce70:  lda $d152ea,x   ; number of abilities for each job
        and #$00ff
        cmp $da
        bne @ce9d
@ce7b:  lda #$0c04      ; xy position
        sta $e2
        lda $e0
        sec
        sbc #$0900      ; switch to palette 4
        sta $e0
        tya
        asl2
        tax
        lda $e0
        sta $0360,x
        lda $e2
        sta $0362,x
        inc $85
        phy
        jsr _c2ce9e     ; udpate job stats and abilities
        ply
@ce9d:  rts
        .a8

; ---------------------------------------------------------------------------

; [ update job stats and abilities ]

_c2ce9e:
        .a16
_ce9e:  lda $d8         ; job index
        and #$001f
        asl2
        tax
        ldy #$054a
        shorta
@ceab:  lda f:JobStatTbl,x   ; stat modifiers for each job
        cmp ($80),y     ; compare to current stat modifier
        bmi @ceb5
        sta ($80),y     ; set stat modifier if greater
@ceb5:  inx
        iny
        cpy #$054e
        bne @ceab
        longa
        lda $d8
        jsr _c2e916     ; get job innate abilities
        ldy $80
        ora $054e,y
        sta $054e,y
        rts
        .a8

; ---------------------------------------------------------------------------

; [ get list of available jobs ]

_c2cecc:
_cecc:  phb
        php
        shorta
        ldx #$0100
        lda #$ff
@ced5:  sta $79ff,x
        dex
        bne @ced5
        ldx $8e
        ldy #$0840      ; available jobs
        lda #$00        ; start at 0
        sta $e3
        lda #$16        ; 22 jobs
        jsr _c2d8b1     ; build list from ram bits
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ menu state $01: ability menu ]

_c2ceec:
_ceec:  shorta
        lda #$04
        jsr _c2cfbd
        .a16
        ldx #near _c0efb5
        lda #$0011
        jsr _c2da9d
        lda #$5000
        sta $2bba
        jsr _c2ddd7
        jsr _c2cfa4
        lda #$1016
        jsr _c2c8de
        lda #$08f3      ; number of abilities
        clc
        adc $7e         ; character index
        tay
        ldx #$51f6
        lda #$0031
        jsr _c2e4ed
        lda $7e         ; character index
        asl
        tax
        lda f:_c0f33a,x   ; pointer to character abilities
        tax
        ldy $80
        shorta
        lda $0501,y     ; job
        cmp #$14
        bne @cf39       ; branch if not mimic
        lda #$48        ; include fight and item
        ora a:$0000,x
        bra @cf3e
@cf39:  lda #$b7        ; remove fight and item
        and a:$0000,x
@cf3e:  sta a:$0000,x
        longa
        stz $6b
        lda #$0040
        sta $6d
        jsr _c2d851     ; get list of available abilities
        jsr _c2d837
        ldx #near _c0f292
        ldy #$298a
        lda #$0015
        mvn #^_c0f292,#$7e
        stz $29b6
        jsr _c2e367
        ldx $80
        lda $0501,x
        and #$001f
        tax
        lda f:_c0ed61,x   ; ability menu to use for each job
        and #$00ff
        asl2
        tax
        shorta
        lda f:_c0ed77,x
        sta $53
        longa
        lda f:_c0ed77+1,x
        and #$000f
        sta $2b63
        lda f:_c0ed77+2,x
        tax
        ldy #$2b5f
        lda #$0003
        mvn #^_c0ed77,#$7e
        jsr _c2d210
        jsr _c2d717
        ldx #near _c0e960
        jsr _c2c6e9
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2cfa4:
_cfa4:  phb
        php
        longa
        ldx #near _c0ee5c
        ldy #$51d2
        lda #$000d
        mvn #^_c0ee5c,#$7e
        ldy #$51d2
        jsr _c2d7ca
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2cfbd:
_cfbd:  shorta
        sta $54
        jsr _c2e67c
        jsr _c2d210
        longa
        lda $8e
        sta $0204
        sta $0206
        lda $71
        and #$00ff
        sta $7e
        jsr _c2d4c5
        rts

; ---------------------------------------------------------------------------

; [ menu state $00: main menu ]

_c2cfdc:
_cfdc:  jsr _c2d230
        jsr _c2d3db
        ldx #near _c0f394
        jsr _c2d04c
        jsr _c2d4db
        ldx #$66ee
        jsr _c2d658
        ldx #$6630
        ldy #$094a
        jsr _c2d662
        lda $44
        and #$0080
        bne @d00a
        ldx #$64f2
.if LANG_EN
        lda #$0104
.else
        lda #$0103
.endif
        jsr _c2d6dc
@d00a:  pea $7e7e
        plb
        plb
        lda $0840       ; available jobs
        bne @d025
        lda $0842
        and #$00f8
        bne @d025
        ldx #$60f2
        lda #$0103
        jsr _c2d6dc
@d025:  lda $08f3       ; number of abilities
        ora $08f5
        bne @d036
        ldx #$6172
        lda #$0105
        jsr _c2d6dc
@d036:  stz $0204
        stz $0206
        stz $2d11
        shorta
        lda #$01
        sta $54
        jsr _c2e67c
        jsr _c2d210
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2d04c:
_d04c:  phb
        pea $7e7e
        plb
        plb
        shorta
        lda #$c0
        stx $82
        sta $84
        longa
        stz $7e
@d05e:  shorta
        jsr _c2d4c5
        ldx $80
        bit $0500,x
        bvs @d0a5
        jsr _c2d0b2
        longa
        lda $7e
        asl3
        tay
        lsr
        ldx $80
        shorta
        bit $0500,x
        longa
        bpl @d083
        inc2
@d083:  tyx
        tay
        lda [$82],y
        clc
        adc $0240,x
        sta $0240,x
        lda [$82],y
        clc
        adc $0244,x
        sta $0244,x
        lda $0222,x
        beq @d0a5
        lda [$82],y
        clc
        adc $0220,x
        sta $0220,x
@d0a5:  longa
        inc $7e
        lda $7e
        cmp #$0004
        bne @d05e
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d0b2:
_d0b2:  phb
        php
        jsr _c2d4c5
        ldx $80
        shorta
        lda #$7e
        pha
        plb
        lda $051a,x
        sta $e8
        lda $0500,x
        sta $ea
        lda $0501,x
        sta $eb
        ldx $8e
        lda $e8
        bpl @d0d5
        inx
@d0d5:  and #$30
        beq @d0db
        inx2
@d0db:  longa
        txa
        asl2
        tax
        lda f:_c0eac8,x
        sta $e0
        lda f:_c0eac8+2,x
        sta $e4
        ldx $7e
        shorta
        lda $e8
        and #$30
        beq @d0ff
        ldx #$0004
        and #$20
        beq @d0ff
        inx
@d0ff:  longa
        txa
        asl3
        tax
        shorta
        lda $e8
        beq @d11a
        bmi @d114
        and #$45
        bne @d116
        bra @d11a
@d114:  inx2
@d116:  inx4
@d11a:  lda f:_c0ead8,x
        sta $e2
        lda f:_c0ead8+1,x
        sta $e6
        jsr _c2d45f
        lda $7e
        asl
        and #$0e
        sta $e3
        sta $e7
        longa
        lda $7e
        asl
        tax
        lda f:_c0eb08,x
        tay
        ldx #$01e0
        lda #$0007
        mvn #$00,#$7e
        lda $7e
        asl
        tax
        lda f:_c0f23e,x
        tay
        shorta
        lda #$04
        and $e8
        beq @d167
        longa
        lda #$7edb
        sta a:$0008,y
        lda #$4dd3
        sta a:$0010,y
        shorta
@d167:  lda #$02
        and $e8
        beq @d181
        longa
        lda #$3af5
        sta a:$0008,y
        lda #$3210
        sta a:$0010,y
        lda #$7fff
        sta a:$0006,y
@d181:  longa
        stz $e2
        shorta
        lda $e8
        bit #$01
        beq @d1f1
        bit #$a0
        bne @d1f1
        bit #$10
        longa
        beq @d19e
        ldx #$000a
        lda $8e
        bra @d1ab
@d19e:  lda $ea
        and #$0007
        asl
        tax
        lda $eb
        and #$00ff
        asl
@d1ab:  clc
        adc f:_c0eb10,x
        tax
        shorta
        lda f:_c0eb1c,x
        clc
        adc $e0
        sta $e0
        lda f:_c0eb1c+1,x
        clc
        adc $e1
        sta $e1
        lda $ea
        and #$07
        beq @d1d9
        cmp #$01
        bne @d1ea
        lda $eb
        and #$1f
        cmp #$0a
        beq @d1e5
        bra @d1ea
@d1d9:  lda $eb
        and #$1f
        cmp #$04
        beq @d1e5
        cmp #$0a
        bne @d1ea
@d1e5:  ldx #$4e20
        bra @d1ed
@d1ea:  ldx #$0e20
@d1ed:  stx $e2
        bra @d1f5
@d1f1:  stz $e0
        stz $e1
@d1f5:  longa
        lda $7e
        asl
        tax
        lda f:_c0eb08,x
        sec
        sbc #$0020
        tay
        ldx #$01e0
        lda #$0003
        mvn #$00,#$00
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ init cursor ??? ]

_c2d210:
_d210:  php
        shorta
        jsr _c2e6ab     ; update cursor sprite
        lda #$01
        trb $ca
        lda $53
        sta $50
        lda $55
        sta $52
        lda $54
        sta $51
        stz $4f
        stz $56
        stz $57
        stz $58
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2d230:
_d230:  phb
        php
        longa
        ldx #$2000
        lda $8e
@d239:  dex2
        stz $9000,x
        bne @d239
        stz $7e
@d242:  jsr _c2d298
        lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @d242
        jsr _c2d25b
        ldx #near _c0efeb
        jsr _c2d9fb
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d25b:
        .a16
_d25b:  ldx $8e
@d25d:  phx
        lda f:_c0ecc3,x
        sta $e0
        lda f:_c0ecc3+2,x
        sta $e2
        lda f:_c0ecc3+4,x
        sta $e4
        lda f:_c0ecc3+6,x
        pha
        lda f:_c0ecc3+8,x
        plx
        jsr _c2d304
        pla
        clc
        adc #$000a
        tax
        cpx #$001e
        bne @d25d
        jsr _c2d34c
        ldx #near _c3b9a0
        ldy #$9080
        lda #$003f
        mvn #^_c3b9a0,#$7e
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d298:
        .a16
_d298:  phb
        php
        lda $7e
        asl
        tax
        lda f:_c0ec1b,x
        sta $e4
        jsr _c2d4c5
        ldx $80
        lda f:$000500,x
        sta $ea
        jsr _c2d2db
        lda #$0018
        ldx #near _c0ec37
        jsr _c2d304
        lda $ea
        and #$0007
        asl2
        tax
        lda f:DeadCharGfxPtrs,x
        sta $e0
        lda f:DeadCharGfxPtrs+2,x
        sta $e2
        lda #$0006
        ldx #near _c0ecab
        jsr _c2d304
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d2db:
_d2db:  php
        longa
        lda $eb
        and #$001f
        asl
        pha
        asl
        adc $01,s
        xba
        sta $01,s
        lda $ea
        and #$0007
        asl2
        tax
        pla
        adc f:BattleCharGfxPtrs,x
        sta $e0
        lda $8e
        adc f:BattleCharGfxPtrs+2,x
        sta $e2
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d304:
        .a16
_d304:  phb
        php
        sta $e8
@d308:  phx
        lda $e4
        clc
        adc $c00002,x
        tay
        lda $e0
        clc
        adc $c00000,x
        tax
        lda $e2
        adc $8e
        and #$00ff
        cmp #$00d4
        beq @d33a
        cmp #$00d3
        beq @d332
        lda #$001f
        mvn #$d2,#$7e
        bra @d340
@d332:  lda #$001f
        mvn #$d3,#$7e
        bra @d340
@d33a:  lda #$001f
        mvn #$d4,#$7e
@d340:  plx
        inx4
        dec $e8
        bne @d308
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d34c:
        .a16
_d34c:  ldx $8e
@d34e:  phx
        txa
        clc
        adc #$0017
        tax
        clc
        adc #$0007
        tay
        lda #$0008
        sta $85
@d35f:  lda $9000,x
        and #$00ff
        sta $9000,y
        dex
        dey2
        dec $85
        bne @d35f
        pla
        clc
        adc #$0020
        tax
        cmp #$0800
        bne @d34e
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d37b:
_d37b:  phb
        php
        longa
        ldx #near _c0efe2
        jsr _c2d9fb
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2d388:
_d388:  phb
        php
        longa
        ldx #$1800
@d38f:  stz $affe,x
        dex2
        bne @d38f
        ldx $80
        lda $0500,x
        and #$0007
        sta $ea
        ldy #$0016
@d3a3:  longa
        lda $eb
        and #$0018
        asl2
        ora $eb
        and #$0067
        asl
        xba
        lsr3
        adc #$b000
        sta $e4
        phy
        jsr _c2d2db
        lda #$0006
        ldx #$ed31
        jsr _c2d304
        ply
        shorta
        inc $eb
        dey
        bne @d3a3
        longa
        ldx #near _c0efd9
        jsr _c2d9fb
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2d3db:
        .a16
_d3db:  phb
        php
        longa
        stz $7e
@d3e1:  jsr _c2d45f
        lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @d3e1
        ldx #near _c3b9e0
        ldy #$7480
        lda #$001f
        mvn #^_c3b9e0,#$7e
        ldx #near _c0f867
        ldy #$74c0
        lda #$001f
        mvn #^_c0f867,#$7e
        ldx #near _c3b960
        ldy #$74e0
        lda #$001f
        mvn #^_c3b960,#$7e
        jsr _c2d42e
        ldx #near _c0eff4
        ldy #near hDMA0
        lda #$0006
        mvn #^_c0eff4,#^hDMA0
        shorta
        stz hCGADD
        lda #$01
        sta hMDMAEN
        plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2d42e:
        .a16
_d42e:  lda #$0004
        sta $e8
        ldy #$7300
@d436:  ldx #near _c0f827
        lda #$003f
        mvn #^_c0f827,#$7e
        dec $e8
        bne @d436
        jsr _c2d447     ; update window color
        rts

; ---------------------------------------------------------------------------

; [ update window color ]

_c2d447:
        .a16
_d447:  php
        longa
        ldy $8e
@d44c:  lda $0971       ; window color
        sta $7302,y
        tya
        clc
        adc #$0008
        tay
        cmp #$0100
        bne @d44c
        plp
        rts

; ---------------------------------------------------------------------------

_c2d45f:
_d45f:  phb
        php
        shorta
        jsr _c2d4c5
        ldx $80
        lda $0500,x
        and #$07
        xba
        lda $0501,x
        and #$1f
        ldy $7e
        bit $051a,x
        bvs @d484
        bpl @d47e
        lda #$15
@d47e:  xba
        jsr _c2d492
        bra @d48f
@d484:  ldx #near _c0f807              ; grayscale battle character palette ???
        longa
        jsr _c2d4b4
        mvn #^_c0f807,#$7e
@d48f:  plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2d492:
_d492:  phb
        php
        phx
        longa
        pha
        and #$0007
        asl
        tax
        pla
        and #$1f00
        lsr3
        clc
        adc f:BattleCharPalPtrs,x
        tax
        jsr _c2d4b4
        mvn #^BattleCharPal,#$7e
        plx
        plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2d4b4:
        .a16
_d4b4:  tya
        and #$0007
        xba
        lsr3
        clc
        adc #$7400
        tay
        lda #$001f
        rts

; ---------------------------------------------------------------------------

_c2d4c5:
_d4c5:  phx
        php
        longa
        lda $7e
        and #$0003
        sta $7e
        asl
        tax
        lda f:_c0ea64,x
        sta $80
        plp
        plx
        rts

; ---------------------------------------------------------------------------

_c2d4db:
_d4db:  phb
        longa
        ldx #near _c0ef6d
        lda #$0017
        jsr _c2da9d
        stz $7e
@d4e9:  lda $7e
        asl
        tax
        lda f:_c0ea5c,x
        sta $2bba
        jsr _c2ddd7
        lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @d4e9
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2d503:
_d503:  ldx $80
        lda $0501,x
        and #$001f
        sta $d8
        lda $053a,x
        and #$000f
        sta $da
        lda $053b,x
        and #$0fff
        sta $dc
        lda $d8
        asl
        tax
        lda $da
        asl
        clc
        adc $da
        adc $d152c0,x   ; pointers to job ability data
        tax
        lda $d10000,x
        sta $de
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2d533:
_d533:  ldx $80
        lda $0500,x
        and #$0007
        asl
        tax
        lda f:_c0ea50,x                   ; pointers to character names (RAM)
        tyx
        tay
        lda #$0006
        jsr _c2e59d
        rts

_c2d54a:
        ldx $80
        lda $051a,x
        and #$007f
        bne _d55c

_c2d554:
        ldx $80
        lda $0501,x
        jsr _c2e4c7
_d55c:  rts

_c2d55d:
        lda $7e
        and #$0003
        asl
        tax
        lda f:_c0ea48,x
        tyx
        tay
        lda #$0021
        jsr _c2e4ed
        rts

_c2d571:
        tyx
        lda $d8
        cmp #$0015
        beq @d57e
        ldy #near _c0ea74
        bra @d581
@d57e:  ldy #near _c0ea81
@d581:  lda #$c08c
        jsr _c2e59d
        rts

_c2d588:
_d588:  lda $d8
        cmp #$0015
        beq @d59c
        tyx
        lda $da
        and #$000f
        clc
        adc #$0053
        sta a:$0000,x
@d59c:  rts

_c2d59d:
_d59d:  ldx $d8
        cpx #$0015
        beq @d5d2
        lda $d152ea,x                   ; number of abilities for each job
        and #$00ff
        cmp $da
        beq @d5c8
        tyx
        ldy #$01dc
        lda #$0032
        jsr _c2e4ed
        inx8
        iny2
        jsr _c2e4ed
        bra @d5d2
@d5c8:  tyx
        ldy #near _c0ea6c
        lda #$c087
        jsr _c2e59d
@d5d2:  rts

_c2d5d3:
        tyx
        lda $80
        clc
        adc #$0506
        tay

_c2d5db:
_d5db:  lda #$7e42
        jsr _c2e4ed
        pha
        txa
        clc
        adc #$000a
        tax
        pla
        iny2
        jsr _c2e4ed
        rts

_c2d5ef:
        tyx
        lda $80
        clc
        adc #$050a
        tay
        lda #$7e32
        jsr _c2e4ed
        pha
        txa
        clc
        adc #$000a
        tax
        pla
        iny2
        jsr _c2e4ed
        rts

_c2d60b:
        phb
        php
        ldx $80
        lda $051a,x
        xba
        asl
        and #$fe00
        beq @d655
        sta $e0
        tyx
        lda #$003a
        sta $e4
        lda #$0008
        sta $e2
        tay
        dey
@d628:  asl $e0
        bcc @d63c
        lda $e4
        sta a:$0000,x
        lda #$00ff
        sta $7dffc0,x
        inx2
        dec $e2
@d63c:  inc $e4
        dey
        bne @d628
        ldy $e2
        iny
        lda #$00ff
@d647:  dey
        beq @d655
        sta a:$0000,x
        sta $7dffc0,x
        inx2
        bra @d647
@d655:  plp
        plb
        rts

_c2d658:
        .a16
_d658:  ldy #$0947
        lda #$0073
        jsr _c2e4ed
        rts

_c2d662:
        php
        shorta
        lda #$3c
        sta $8d
        cpy #$2d17
        beq @d674
        jsr _c2d6a4
        ldy #$0189
@d674:  jsr _c2d6a4
        ldy #$0189
        jsr _c2d6a4
        sta $8b
        longa
        lda #$0032
        ldy $89
        cpy #$03e8
        bmi @d68e
        ora #$0080
@d68e:  ldy #$0189
        jsr _c2e4ed
        iny2
        txa
        clc
        adc #$0008
        tax
        lda #$00a1
        jsr _c2e4ed
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d6a4:
@d6a4:  phx
        iny3
        lda #$00
        ldx #$0004
@d6ad:  sta f:hWRDIVH
        lda a:$0000,y
        sta f:hWRDIVL
        dey
        lda $8d
        sta f:hWRDIVB
        nop8
        lda f:hRDDIVL
        sta $88,x
        lda f:hRDMPYL
        dex
        bne @d6ad
        pha
        lda #$3c
        sta $8d
        pla
        plx
        rts

; ---------------------------------------------------------------------------

; [ set font color ??? ]

; $E0: text length
;   A: palette index
;  +X: text address

_c2d6dc:
_d6dc:  phb
        php
        shorta
        sta $e0
        lda $e0
        beq @d714
        xba
        pha
        and #$07
        asl2
        sta $e1
        pla
        and #$80
        sta $e2
        inx
@d6f4:  lda a:$0000,x
        and #$e3
        ora $e1
        sta a:$0000,x
        bit $e2
        bmi @d70e
        lda $7dffc0,x
        and #$e3
        ora $e1
        sta $7dffc0,x
@d70e:  inx2
        dec $e0
        bne @d6f4
@d714:  plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2d717:
        .a16
_d717:  phb
        php
        lda $2b63
        and #$000f
        asl2
        tax
        lda f:_c0f316,x
        phx
        jsr LoadMenuTilemap
        plx
        lda f:_c0f316+2,x
        tax
        ldy #$7100
        jsr _c2c1fd
        lda $2b63
        and #$000f
        asl3
        tax
        lda #$0004
        sta $85
        ldy $80
@d747:  lda f:_c0f322,x
        beq @d756
        phx
        tax
        lda $0516,y
        jsr _c2d8e4
        plx
@d756:  inx2
        iny
        dec $85
        bne @d747
        plp
        plb
        rts

_c2d760:
        .a16
        lda #near _c3ae53
        jsr LoadMenuTilemap
        lda $55
        and #$00ff
        dec
        clc
        adc $6b
        tax
        lda $7a00,x
        and #$00ff
        shorta
        bit #$80
        beq @d781
        and #$7f
        clc
        adc #$4e
@d781:  longa
        and #$00ff
        pha
        asl
        tax
.if LANG_EN
        .import _e0317f
        jml _e0317f
        .export _c2d78d := *
.else
        lda f:AbilityDescPtrs,x
.endif
        sta $7e2ceb
        jsr _c2da16
        pla
        tax
        shorta
        lda f:_c0f739,x
        beq @d7c9
        pha
        and #$1f
        sta $e0
        pla
        and #$e0
        lsr5
        sta $e1
        lda $e0
        ldy #$568c
        jsr _c2e4c7
        longa
        ldx #$56a4
        ldy #$01e1
        lda #$0011
        jsr _c2e4ed
        lda #near _c3ae37
        jsr LoadMenuTilemap
@d7c9:  rts
        .a8

_c2d7ca:
_d7ca:  ldx $80
        lda f:$000540,x
        sta $f9
        lda f:$000542,x
        sta $fb

_c2d7d8:
        .a16
        lda $f9
        cmp #$ffff
        bne @d7f2
        lda $fb
        cmp #$ffff
        bne @d7f2
        tyx
        ldy #near _c0f7a8
        lda #$c004
        jsr _c2e59d
        bra @d7f5
@d7f2:  jsr _c2d802
@d7f5:  rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2d7f6:
        .a16
_d7f6:  lda #$0005
        sta $85
        ldx #$0041
        jsr _c2d80d
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d802:
        .a16
_d802:  lda #$000d
        sta $85
        ldx $8e
        jsr _c2d80d
        rts
        .a8

; ---------------------------------------------------------------------------

_c2d80d:
        .a16
_d80d:  lda $f9
        and f:_c0f7ad,x
        sta $fd
        lda $fb
        and f:_c0f7ad+2,x
        ora $fd
        beq @d82d
        lda f:_c0f7ad+4,x
        and #$00ff
        beq @d82d
        sta a:$0000,y
        iny2
@d82d:  inx5
        dec $85
        bne _d80d
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2d837:
        .a16
_d837:  ldy $6b
        ldx $8e
@d83b:  phx
        lda f:_c0f478,x
        tax
        lda $7a00,y
        jsr _c2d8e4
        plx
        iny
        inx2
        cpx #$0020
        bne @d83b
        rts
        .a8

; ---------------------------------------------------------------------------

; [ get list of available abilities ]

_c2d851:
_d851:  php
        ldx #$0200
@d855:  dex2
        stz $7a00,x
        bne @d855
        lda $7e
        asl
        tax
        lda f:_c0f33a,x   ; pointer to character abilities
        tay
        shorta
        ldx $8e
        inx
        stz $e0
        lda #$01        ; start at $01
        sta $e3
        lda #$2c        ; end at $2C
        jsr _c2d8b1     ; build list from ram bits
        lda #$80
        sta $e0
        iny
        lda #$32
        jsr _c2d8b1     ; build list from ram bits
        iny
        lda #$38
        jsr _c2d8b1     ; build list from ram bits
        iny
        lda #$3e
        jsr _c2d8b1     ; build list from ram bits
        iny
        lda #$44
        jsr _c2d8b1     ; build list from ram bits
        iny
        lda #$49
        jsr _c2d8b1     ; build list from ram bits
        iny
        lda #$4c
        jsr _c2d8b1     ; build list from ram bits
        stz $e0
        iny
        lda #$4e
        jsr _c2d8b1     ; build list from ram bits
        iny
        lda #$80        ; start at $80
        sta $e3
        lda #$a1        ; end at $A1
        jsr _c2d8b1     ; build list from ram bits
        plp
        rts

; ---------------------------------------------------------------------------

; [ build list from ram bits ]

_c2d8b1:
_d8b1:  sta $e4         ; end bit
@d8b3:  lda a:$0000,y
        sta $e2
        lda #$08        ; 8 bits
        sta $e5
@d8bc:  asl $e2
        bcc @d8ca
        lda $e3         ; start bit
        sta $7a00,x
        bit $e0
        bmi @d8ca
        inx
@d8ca:  inc $e3
        lda $e3
        cmp $e4
        bpl @d8d9
        dec $e5         ; next bit
        bne @d8bc
        iny             ; next byte
        bra @d8b3
@d8d9:  bit $e0
        bpl @d8e3
        lda $7a00,x
        beq @d8e3
        inx
@d8e3:  rts

; ---------------------------------------------------------------------------

; [  ]

_c2d8e4:
_d8e4:  phb
        phy
        php
        pea $7e7e
        plb
        plb
        longa
        and #$00ff
        pha
        phx
        asl
        tax
        lda $7ed600,x                   ; pointers to battle command names
        tay
        plx
        pla
        bit #$0080
        beq @d909
        lda #$d108
        jsr _c2e59d
        bra @d93b
@d909:  phx
        phy
        pha
        ldx #near _c0f4a3
        ldy #$2b3f
        lda #$0007
        mvn #^_c0f4a3,#$7e
        pla
        ply
        plx
        and #$007f
        beq @d926
        lda #$00c9
        sta $2b3f
@d926:  phx
.if LANG_EN
        .import _e00f50
        jsl _e00f50
        lda #$0006
        mvn #$e0,#$7e
.else
        tyx
        ldy #$2b40
        lda #$0004
        mvn #$d1,#$7e
.endif
        plx
        ldy #$2b3f
        lda #$7e08
        jsr _c2e59d
@d93b:  plp
        ply
        plb
        rts
        .a8

_c2d93f:
_d93f:  tyx
        longa
        lda $d8
        cmp #$0015
        beq @d94e
        ldy #near _c0f498
        bra @d951
@d94e:  ldy #near _c0f4a3
@d951:  lda #make_word 10 | BIT_7, ^_c0f4a3
        jsr _c2e59d
        rts
        .a8

; ---------------------------------------------------------------------------

; [ menu command $06: transfer galuf's stats to krile ]

_c2d958:
_d958:  php
        phb
        stz $7e
@d95c:  jsr _c2d4c5
        ldx $80
        lda $0500,x
        and #$07
        cmp #$04
        beq @d974
        inc $7e
        lda $7e
        cmp #$04
        beq @d9a8
        bra @d95c
@d974:  longa
        jsr _c2d503
        jsr _c2e464
        jsr _c2daa4
        shorta
        ldx $7e
        inc $0420,x
        lda #$15
        sta $d8
        jsr _c2e47d     ; get character job data
        ldx $80
        lda $da
        sta $053a,x     ; job level
        lda $d8
        sta $0501,x     ; job
        longa
        lda $dc
        sta $053b,x
        shorta
        jsr _c2eb82
        jsr _c2e6d6
@d9a8:  plb
        plp
        rts

; ---------------------------------------------------------------------------

_c2d9ab:
_d9ab:  php
        phb
        phy
        longa
        and #$00ff
        pha
        asl
        tax
        lda $7ed000,x
        tax
        phx
        ldy #$019b
        lda #$000b
        mvn #$d1,#$00
        plx
        pla
        cmp #$0061
        beq @d9d3
        cmp #$0063
        beq @d9ef
        bra @d9f7
@d9d3:  lda $09b5
        and #$00ff
        pha
        lda $a2
        and #$00ff
        sec
        sbc $01,s
        sta $01,s
        pla
        bpl @d9e9
        lda $8e
@d9e9:  shorta
        sta $a2
        bra @d9f7
@d9ef:  shorta
        lda $09b5
        lsr
        sta $a2
@d9f7:  ply
        plb
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2d9fb:
        .a16
_d9fb:  lda $c00000,x
        sta f:hVMADDL
        inx2
        ldy #near hDMA0
        lda #$0006
        mvn #$c0,#^hDMA0
        shorta
        lda #$01
        sta hMDMAEN
        rts

_c2da16:
_da16:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        lda $2ce5
        sta $2ced
        stz $2cef
@da28:  ldx $2ceb
        ldy #$2cf1
        lda $2ce7
.if LANG_EN
        .import _e03191
        jsl _e03191
.else
        dec
        mvn #$d1,#$7e
.endif
        inc
        sta a:$0000,y
        ldx $8e
        shorta
@da3d:  lda $2cf1,x
        cmp #$01
        beq @da4c
        inx
        cpx $2ce7
        bne @da3d
        bra @da4f
@da4c:  stz $2cf1,x
@da4f:  longa
        ldx $2ced
        ldy #$2cf1
        lda $2ce7
        and #$00ff
        ora #$7e00
        jsr _c2e59d
        tya
        sec
        sbc #$2cf1
        clc
        adc $2ceb
        tax
        lda $d10000,x
        and #$00ff
        beq @da9a
        cmp #$0001
        bne @da7c
        inx
@da7c:  stx $2ceb
        lda $2ced
        clc
        adc #$0080
        sta $2ced
        lda $2ce7
        clc
        adc $2cef
        sta $2cef
        cmp $2ce9
        beq @da9a
        bra @da28
@da9a:  plp
        plb
        rts

_c2da9d:
_da9d:  ldy #$2bbe
        mvn #$c0,#$7e
        rts

_c2daa4:
_daa4:  phb
        php
        longa
        lda $6f
        pha
        shorta
        jsr _c2e178
        lda #$01
@dab2:  sta $6f
        jsr _c2e211
        lda $73
        jsr _c2e286
        lda $90
        bne @dac8
        lda #$01
        xba
        lda $73
        jsr _c2e2ce
@dac8:  lda $6f
        inc
        cmp #$06
        bne @dab2
        jsr _c2e18f
        longa
        pla
        sta $6f
        plp
        plb
        rts

_c2dada:
_dada:  ldx $8e
@dadc:  lda f:_c0eed2,x
        beq @daeb
        cmp $29e7
        beq @daee
        inx2
        bra @dadc
@daeb:  stz $29e7
@daee:  rts

_c2daef:
_daef:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        stz $29f1
        shorta
        lda $29f8
        sta f:hWRMPYA
        lda $29f9
        sta f:hWRMPYB
        nop3
        longa
        lda f:hRDMPYL
        sta $29ef
        shorta
        lda $29e7
        jsr _c2dada
        lda $29e7
        beq @db63
        longa
        lda f:_c0e82b,x
        sta $c7
        shorta
        ldy $8e
@db30:  lda $29ea,y
        bne @db3d
        iny
        cpy #$0004
        bne @db30
        bra @db63
@db3d:  sty $7e
        jsr _c2d4c5
        ldy $80
        per @db4a-1
        jmp ($01c7)
@db4a:  lda $29f1
        beq @db63
        longa
        lda $29e7
        and #$00ff
        ora #$0100
        jsr _c2e328
        dec $29e8
        jsr _c2e0c8
@db63:  plp
        plb
        rts
        .a8

_c2db66:
        php
        lda $051a,y
        bit #$c2
        longa
        bne @db90
        lda $050a,y
        cmp $050c,y
        beq @db90
        lda $29ef
        clc
        adc $050a,y
        sta $050a,y
        lda $050c,y
        cmp $050a,y
        bpl @db8d
        sta $050a,y
@db8d:  inc $29f1
@db90:  plp
        rts
        .a8

_c2db92:
        php
        lda $051a,y
        bit #$c2
        longa
        bne @dbbb
        lda $0508,y
        cmp $0506,y
        bne @dbac
        lda $050c,y
        cmp $050a,y
        beq @dbbb
@dbac:  lda $0508,y
        sta $0506,y
        lda $050c,y
        sta $050a,y
        inc $29f1
@dbbb:  plp
        rts
        .a8

_c2dbbd:
        lda $051a,y
        bit #$20
        beq @dbcd
        and $29f8
        sta $051a,y
        inc $29f1
@dbcd:  rts

_c2dbce:
        php
        lda $051a,y
        bit #$02
        beq @dbe6
        and #$fd
        sta $051a,y
        longa
        lda #$0001
        sta $0506,y
        inc $29f1
@dbe6:  plp
        rts
        .a8

_c2dbe8:
        lda $051a,y
        bit #$01
        beq @dbf8
        and $29f8
        sta $051a,y
        inc $29f1
@dbf8:  rts

_c2dbf9:
        lda $051a,y
        bit #$40
        beq @dc09
        and $29f8
        sta $051a,y
        inc $29f1
@dc09:  rts

_c2dc0a:
        lda $051a,y
        bit #$10
        beq @dc1a
        and $29f8
        sta $051a,y
        inc $29f1
@dc1a:  rts

_c2dc1b:
_dc1b:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        stz $29f1
        lda $71
        and #$000f
        sta $7e
        jsr _c2d4c5
        ldx $80
        shorta
        lda $0502,x
        sta f:hWRMPYA
        lda $052b,x
        sta f:hWRMPYB
        nop4
        lda f:hRDMPYH
        clc
        adc #$04
        sta f:hWRMPYA
        lda $29f9
        sta f:hWRMPYB
        nop3
        longa
        lda f:hRDMPYL
        tay
        lda $55
        and #$000f
        cmp #$0005
        bne @dc70
        tya
        lsr
        tay
@dc70:  sty $29ef
        shorta
        ldx $8e
@dc77:  lda f:_c0eeba,x
        beq @dccf
        cmp $29e7
        beq @dc86
        inx2
        bra @dc77
@dc86:  longa
        lda f:_c0e815,x
        sta $c7
        shorta
        ldy $8e
@dc92:  lda $29ea,y
        beq @dca6
        phy
        sty $7e
        jsr _c2d4c5
        ldy $80
        per @dca5-1
        jmp ($01c7)
@dca5:  ply
@dca6:  iny
        cpy #$0004
        bne @dc92
        lda $29f1
        beq @dccf
        longa
        lda $71
        and #$000f
        sta $7e
        jsr _c2d4c5
        ldy $80
        lda $050a,y
        sec
        sbc $29e8
        sta $050a,y
        sta $29df
        jsr _c2e0c8
@dccf:  plp
        plb
        rts
        .a8

_c2dcd2:
@dcd2:  php
        lda $051a,y
        bit #$c2
        longa
        bne @dcfc
        lda $0506,y
        cmp $0508,y
        beq @dcfc
        lda $29ef
        clc
        adc $0506,y
        sta $0506,y
        lda $0508,y
        cmp $0506,y
        bpl @dcf9
        sta $0506,y
@dcf9:  inc $29f1
@dcfc:  plp
        rts
        .a8

_c2dcfe:
        lda $051a,y
        bit #$04
        beq @dd0e
        and $29f8
        sta $051a,y
        inc $29f1
@dd0e:  rts

_c2dd0f:
        lda $051a,y
        bit #$c2
        bne @dd1f
        eor $29fa
        sta $051a,y
        inc $29f1
@dd1f:  rts

_c2dd20:
        php
        lda $051a,y
        bit #$80
        beq @dd58
        and #$7f
        sta $051a,y
        longa
        lda $0508,y
        shorta
        sta f:hM7A
        xba
        sta f:hM7A
        lda $29fa
        sta f:hM7B
        sta f:hM7B
        longa
        lda f:hMPYL
        lsr4
        sta $0506,y
        inc $29f1
@dd58:  plp
        rts
        .a8

_c2dd5a:
        lda $051a,y
        bit #$75
        beq @dd6a
        and $29f8
        sta $051a,y
        inc $29f1
@dd6a:  rts

_c2dd6b:
        lda $55
        cmp #$05
        jeq _c2dcd2
        lda $051a,y
        bit #$c2
        bne @dd8d
        php
        longa
        lda $0508,y
        cmp $0506,y
        beq @dd8c
        sta $0506,y
        inc $29f1
@dd8c:  plp
@dd8d:  rts
        .a8

_c2dd8e:
        php
        lda $051a,y
        bit #$80
        beq @dda6
        and #$7f
        sta $051a,y
        longa
        lda $0508,y
        sta $0506,y
        inc $29f1
@dda6:  plp
        rts
        .a8

_c2dda8:
        lda $051a,y
        and $29f8
        sta $051a,y
        inc $29f1
        rts

_c2ddb5:
        lda $051a,y
        bit #$c0
        bne @ddc5
        eor $29fa
        sta $051a,y
        inc $29f1
@ddc5:  rts

_c2ddc6:
        lda $051a,y
        bit #$c2
        bne @ddd6
        ora $29fa
        sta $051a,y
        inc $29f1
@ddd6:  rts

_c2ddd7:
_ddd7:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        lda $2bba
        sta $e6
        lda $2bbe
        beq @dded
        jsr LoadMenuTilemap
@dded:  jsr _c2d4c5
        jsr _c2d503
        ldx $80
        lda $0500,x
        and #$0040
        bne @de3b
        lda $2bba
        sta $e6
        lda $2bc0
        beq @de0a
        jsr LoadMenuTilemap
@de0a:  lda $2bc2
        sta $2bbc
        ldx $8e
        txy
@de13:  lsr $2bbc
        bcc @de34
        lda $2bba
        clc
        adc $2bc4,y
        phx
        phy
        php
        tay
        lda f:_c0e7ff,x
        sta $c7
        per @de2f-1
        jmp ($01c7)
@de2f:  plp
        ply
        plx
        iny2
@de34:  inx2
        cpx #$0016
        bne @de13
@de3b:  plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

_c2de3e:
_de3e:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx #$0200
        lda #$ffff
@de4d:  sta $79fe,x
        dex2
        bne @de4d
        lda #$7a00
        sta $e0
        lda $29e2
        and #$00ff
        asl2
        tax
        lda f:_c0ef19+1,x
        and #$00ff
        sta $e4
        lda f:_c0ef19+2,x
        and #$00ff
        sta $e6
        lda f:_c0ef19,x
        and #$00ff
        tax
@de7c:  shorta
        ldy $e6
        sty $85
        ldy $8e
@de84:  lda $29fb,x
        bpl @de94
        txa
        sta ($e0),y
        iny
        phx
        phy
        jsr _c2dec7
        ply
        plx
@de94:  shorta
        inx
        dec $85
        bne @de84
        lda $29e2
        cmp #$06
        beq @deb8
        lda #$fe
@dea4:  cpy $e6
        beq @dead
        sta ($e0),y
        iny
        bra @dea4
@dead:  longa
        lda $e0
        clc
        adc $e6
        sta $e0
        bra @dec0
@deb8:  longa
        tya
        clc
        adc $e0
        sta $e0
@dec0:  dec $e4
        bne @de7c
        plp
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

_c2dec7:
        .a16
_dec7:  php
        longa
        and #$00ff
        sta $29e4
        cmp #$0048
        bpl @df3e
        cmp #$0012
        bmi @df3e
        shorta
        ldx $8e
@dede:  lda f:_c0eef4,x
        cmp #$ff
        beq @df3e
        cmp $29e4
        beq @def0
        inx3
        bra @dede
@def0:  longa
        lda f:_c0eef4+1,x
        and #$000f
        tay
        lda f:_c0eef4+2,x
        shorta
        cmp $29d8,y
        beq @df07
        bpl @df3e
@df07:  longa
        ldx $29e4
        lda $2a9d,x
        and #$00ff
        cmp $29df
        beq @df1b
        bmi @df1b
        bra @df3e
@df1b:  shorta
        lda $29e1
        bit #$c2
        bne @df3e
        bit #$20
        beq @df2f
        lda $29e4
        cmp #$29
        bne @df3e
@df2f:  shorta
        ldx $29e4
        lda $29fb,x
        ora #$40
        sta $29fb,x
        bra @df4b
@df3e:  shorta
        ldx $29e4
        lda $29fb,x
        and #$bf
        sta $29fb,x
@df4b:  plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2df4d:
_df4d:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        lda $29e2
        and #$00ff
        tax
        lda $29d8,x
        and #$00ff
        sta $f0
        txa
        asl
        tax
        lda f:_c0ef43,x   ; source bank and string length
        sta $ed
        lda f:_c0ef35,x   ; number of spells ???
        sta $85
        lda f:_c0e966,x
        tax
        ldy $8e
        stz $f2
        inc $f2

; ---------------------------------------------------------------------------

; start of loop
_c2df7f:
_df7f:  lda $c00000,x
        sta $eb
        inx2
        lda $7a00,y
        and #$00ff
        cmp #$00ff
        beq @dff6
        cmp #$00fe
        beq @dff6
        phx
        phy
        tax
        shorta
        lda $29fb,x
        sta $e8
        longa
        txa
        asl
        tax
        lda $d400,x     ; pointer to spell name
        sta $e9
        ldx $eb
        lda $29e2
        and #$00ff
        cmp #$0005
        bne @dfbc
        dex2
        stx $eb
@dfbc:  ldy $e9
        lda $ed
        jsr _c2e59d     ; draw text
        ldx $eb
        lda $29e2
        and #$00ff
        beq @dfd2
        cmp #$0004
        bmi @dfda
@dfd2:  lda $f0
        cmp $f2
        bpl @dff4
        bra @dfe9
@dfda:  lda $e8
        and #$0040
        bne @dff4
        lda $f0
        cmp $f2
        bmi @dfe9
        inx2
@dfe9:  lda $ed
        and #$007f
        ora #$0100
        jsr _c2d6dc     ; set font color
@dff4:  ply
        plx
@dff6:  iny
        longa
        inc $f2
        dec $85
        bne _df7f
        plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2e002:
_e002:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx $8e
@e00d:  stz $7f00,x
        inx2
        cpx #$0300
        bne @e00d
        longa
        ldy $8e
        lda #$00e0
        ldx #$0100
        jsr _c2e050
        lda $8e
        ldx #$0080
        jsr _c2e050
        lda #$0080
        ldx #$00e0
        jsr _c2e050
        ldx #$8000
        ldy #$0640
        lda #$01ff
        mvn #$7e,#$7e
        ldx #$7f00
        ldy #$288a
        lda #$00ff
        mvn #$7e,#$7e
        plp
        plb
        rts

_c2e050:
        .a16
_e050:  sta $93
        stx $95
        ldx $8e
@e056:  lda $0640,x
        and #$00ff
        beq @e09b
        cmp #$0001
        beq @e09b
        cmp #$0080
        beq @e09b
        sta $e0
        lda $0740,x
        and #$00ff
        beq @e09b
        cmp #$0064
        bmi @e07a
        lda #$0063
@e07a:  sta $e2
        lda $e0
        cmp $93
        bmi @e09b
        cmp $95
        bpl @e09b
        shorta
        lda $e0
        sta $8000,y
        lda $e2
        sta $8100,y
        lda $288a,x
        sta $7f00,y
        iny
        longa
@e09b:  inx
        cpx #$0100
        bne @e056
        tya
        inc
        and #$fffe
        tay
        rts

; ---------------------------------------------------------------------------

; [ play sound effect ]

_c2e0a8:
_e0a8:  pha
        php
        shorta
        lda #$11        ; cursor 1
        bra _e0ce

_c2e0b0:
        pha
        php
        shorta
        lda #$10        ; cursor 2
        bra _e0ce

_c2e0b8:
        pha
        php
        shorta
        lda #$11        ; cursor 1
        bra _e0ce

_c2e0c0:
        pha
        php
        shorta
        lda #$12        ; error
        bra _e0ce

_c2e0c8:
        pha
        php
        shorta
        lda #$13        ; system sound effect $13
_e0ce:  sta f:$001d00
        jsl ExecSound_ext
        plp
        pla
        rts

; ---------------------------------------------------------------------------

; [ play sound effect ]

; a: game sound effect id

_c2e0d9:
_e0d9:  phb
        php
        longa
        pha
        ldx #near _c0eeb6      ; C0/EEB6: $02, $5B, $0F, $88
        ldy #$1d00
        lda #$0003
        mvn #^_c0eeb6,#$7e     ; this is a pretty roundabout way of copying 4 bytes
        pla
        shorta
        sta $1d01
        jsl ExecSound_ext
        plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2e0f7:
_e0f7:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        stz $90
        lda $6f
        cmp #$03
        bpl @e167
        dec
        longa
        and #$0001
        asl2
        tax
        lda f:_c0ef53,x
        clc
        adc $80
        tay
        lda $72
        sta $e0
        shorta
        lda $0500,y
        bne @e126
        lda $04fe,y
@e126:  sta $e2
        jsr @e16a
        sta $e3
        lda $e0
        jsr @e16a
        sta $e1
        ldy $80
        lda $e0
        bmi @e155
        lda $e2
        bmi @e14f
        beq @e167
        cmp #$01
        beq @e167
        lda $0521,y
        and #$01
        beq @e165
        lda $e3
        bmi @e165
@e14f:  lda $e1
        bmi @e165
        bra @e167
@e155:  lda $e2
        bmi @e165
        beq @e167
        cmp #$01
        beq @e167
        lda $e3
        bmi @e165
        bra @e167
@e165:  inc $90
@e167:  plp
        plb
        rts
@e16a:  bmi @e175
        and #$7f
        jsr _c2d9ab
        lda $9f
        bra @e177
@e175:  lda #$00
@e177:  rts

_c2e178:
_e178:  phb
        php
        longa
        lda $80
        clc
        adc #$050e
        tax
        ldy #$01e0
        lda #$0006
        mvn #$7e,#$7e
        plp
        plb
        rts

_c2e18f:
_e18f:  phb
        php
        longa
        lda $80
        clc
        adc #$050e
        tay
        ldx #$01e0
        lda #$0006
        mvn #$7e,#$7e
        plp
        plb
        rts

_c2e1a6:
_e1a6:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        lda $6f
        cmp #$01
        beq @e1ca
        cmp #$02
        beq @e1ca
        dec3
        longa
        and #$0003
        tay
        shorta
        lda $72
        sta $01e0,y
        bra @e20e
@e1ca:  dec
        longa
        and #$0001
        tay
        shorta
        lda $72
        bmi @e1e1
        sta $01e5,y
        lda #$00
        sta $01e3,y
        bra @e1e9
@e1e1:  sta $01e3,y
        lda #$00
        sta $01e5,y
@e1e9:  longa
        tya
        inc
        and #$0001
        tax
        shorta
        lda $01e5,y
        beq @e202
        lda $e5,x
        cmp #$01
        bne @e20e
        stz $e5,x
        bra @e20e
@e202:  lda $e5,x
        ora $e3,x
        bne @e20e
        lda #$01
        sta $e5,x
        stz $e3,x
@e20e:  plp
        plb
        rts

_c2e211:
_e211:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        stz $73
        lda $6f
        cmp #$01
        beq @e240
        cmp #$02
        beq @e240
        dec3
        longa
        and #$0003
        tax
        shorta
        lda $e0,x
        beq @e283
        cmp #$80
        beq @e283
        sta $73
        lda #$80
        sta $e0,x
        bra @e283
@e240:  dec
        longa
        and #$0001
        tay
        shorta
        lda $01e5,y
        bne @e253
        lda $01e3,y
        beq @e262
@e253:  cmp #$01
        beq @e262
        sta $73
        lda #$00
        sta $01e3,y
        inc
        sta $01e5,y
@e262:  longa
        tya
        inc
        and #$0001
        tax
        shorta
        lda $e5,x
        beq @e27b
        cmp #$01
        beq @e283
        lda #$00
        sta $01e5,y
        bra @e283
@e27b:  lda $e3,x
        bne @e283
        lda #$01
        sta $e5,x
@e283:  plp
        plb
        rts

_c2e286:
_e286:  phb
        phx
        php
        pea $7e7e
        plb
        plb
        shorta
        stz $90
        cmp #$00
        beq @e2ca
        cmp #$01
        beq @e2ca
        cmp #$80
        beq @e2ca
        ldx $8e
@e2a0:  cmp $0640,x
        beq @e2ad
        inx
        cpx #$0100
        beq @e2b9
        bra @e2a0
@e2ad:  lda $0740,x
        inc
        cmp #$64
        bmi @e2ca
        inc $90
        bra @e2ca
@e2b9:  ldx $8e
@e2bb:  lda $0640,x
        beq @e2ca
        inx
        cpx #$0100
        bne @e2bb
        inc $90
        inc $90
@e2ca:  plp
        plx
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e2ce:
_e2ce:  phb
        phx
        php
        pea $7e7e
        plb
        plb
        shorta
        stz $90
        cmp #$00
        beq @e324
        cmp #$01
        beq @e324
        cmp #$80
        beq @e324
        ldx $8e
@e2e8:  cmp $0640,x
        beq @e2f5
        inx
        cpx #$0100
        beq @e305
        bra @e2e8
@e2f5:  xba
        clc
        adc $0740,x
        cmp #$64
        bmi @e300
        lda #$63
@e300:  sta $0740,x
        bra @e324
@e305:  ldx $8e
        pha
@e308:  lda $0640,x
        beq @e315
        inx
        cpx #$0100
        beq @e31f
        bra @e308
@e315:  pla
        sta $0640,x
        xba
        sta $0740,x
        bra @e324
@e31f:  pla
        inc $90
        inc $90
@e324:  plp
        plx
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e328:
_e328:  phb
        phx
        php
        pea $7e7e
        plb
        plb
        shorta
        stz $90
        ldx $8e
@e336:  cmp $0640,x
        beq @e343
        inx
        cpx #$0100
        beq @e361
        bra @e336
@e343:  xba
        pha
        sec
        lda $0740,x
        sbc $01,s
        bpl @e350
        pla
        bra @e361
@e350:  sta $0740,x
        pla
        lda $0740,x
        bne @e363
        stz $0640,x
        stz $288a,x
        bra @e363
@e361:  inc $90
@e363:  plp
        plx
        plb
        rts

_c2e367:
_e367:  php
        longa
        lda $6d
        beq @e394
        ldy $8e
        lda $6b
        beq @e37a
        cmp $6d
        beq @e379
        iny
@e379:  iny
@e37a:  tya
        asl2
        tay
        lda $7e29b6
        and #$000f
        asl2
        tax
        phx
        jsr @e396
        iny2
        plx
        inx2
        jsr @e396
@e394:  plp
        rts
@e396:  lda f:_c0e9c6,x
        pha
        tyx
        lda f:_c0e9d6,x
        plx
        sta $7e0000,x
        rts

_c2e3a6:
_e3a6:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        sta $91
        xba
        sta $92
        lda $92
        beq @e3d4
        lda $91
        beq @e3d4
        jsr _c2e44e
        longa
        lda #$00cf
        sta a:$0000,x
        inx2
        ldy #$0192
        lda #$0021
        jsr _c2e4ed
        bra @e3e0
@e3d4:  longa
        tyx
        ldy #near _c0ef59
        lda #make_word 12, ^_c0ef59
        jsr _c2e59d
@e3e0:  plp
        plb
        rts

_c2e3e3:
_e3e3:  php
        shorta
        lda $7a00,x
        xba
        lda $7b00,x
        xba
        jsr _c2e3a6
        plp
        rts

_c2e3f3:
_e3f3:  phy
        jsr _c2e3e3
        ply
        php
        longa
        lda $54
        and #$00ff
        cmp #$0016
        beq @e42a
        lda $91
        and #$00ff
        cmp #$00e0
        bmi @e421
        shorta
        ldx $8e
@e413:  lda f:_c0eed2,x
        beq @e421
        cmp $91
        beq @e42a
        inx2
        bra @e413
@e421:  tyx
        longa
        lda #$010c
        jsr _c2d6dc
@e42a:  plp
        rts

; ---------------------------------------------------------------------------

; [ draw spell name ]

;  A: spell id
; +Y: destination address

_c2e42c:
_e42c:  php
        longa
        and #$00ff
        pha
        asl
        tax
        lda $7ed400,x   ; pointer to spell name ???
        tyx
        tay
        pla
        cmp #$0057
        bpl @e446
        lda #$d106      ; spells $00-$56: 6 bytes each
        bra @e449
@e446:  lda #$d108      ; spells $57-...: 8 bytes each
@e449:  jsr _c2e59d
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

; [ draw item name ]

_c2e44e:
_e44e:  php
        longa
        and #$00ff
        asl
        tax
        lda $7ed200,x   ; pointer to item name ???
        tyx
        tay
        lda #$d109
        jsr _c2e59d
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

_c2e464:
        .a16
_e464:  phb
        php
        lda $d8
        jsr _c2e4b2
        lda $da
        and #$000f
        asl4
        xba
        ora $dc
        sta $0843,x
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ get character job data ]

; +$7E: character index
; +$D8: job index
; +$DA: job level (out)
; +$DC: current abp (out)
; +$DE: abp to next level (out)

_c2e47d:
_e47d:  phb
        php
        longa
        lda $d8
        jsr _c2e4b2     ; get pointer to character job data
        lda $0843,x     ; job level/abp
        pha
        and #$0fff      ; abp
        sta $dc
        pla
        xba
        lsr4
        and #$000f
        sta $da
        lda $d8
        asl
        tax
        lda $da
        asl
        clc
        adc $da
        adc $d152c0,x   ; pointers to job ability data
        tax
        lda $d10000,x   ; number of ability points to next level
        sta $de
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ get pointer to character job data ]

_c2e4b2:
_e4b2:  php
        longa
        and #$00ff
        pha
        lda $7e
        asl
        tax
        pla
        asl
        clc
        adc f:_c0ef65,x   ; pointers to character job data (+$0843)
        tax
        plp
        rts

; ---------------------------------------------------------------------------

_c2e4c7:
_e4c7:  php
        longa
        and #$001f
        asl3
        clc
        adc #$5600              ; job names
        tax
        tyx
        tay
.if LANG_EN
        lda #$d108
.else
        lda #$d107
.endif
        jsr _c2e59d
        plp
        rts

; ---------------------------------------------------------------------------

; [ get pointer to current cursor data ]

_c2e4df:
_e4df:  lda $53         ; current cursor position

_c2e4e1:
        php
        longa
        and #$00ff
        asl3            ; 8 bytes each
        tax
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e4ed:
_e4ed:  phb
        pha
        phx
        phy
        php
        longai
        stz $d2
        stz $d4
        stx $d6
        shorta
        xba
        pha
        plb
        xba
        tax
        lsr4
        and #$07
        sta $ce
        txa
        and #$0f
        sta $cd
        txa
        eor #$80
        sta $d1
        ldx $8e
@e515:  lda a:$0000,y
        phy
        longa
        and #$00ff
        sta $cb
        ldy #$0008
@e523:  lsr $cb
        bcc @e53a
        sed
        clc
        lda f:_c0f887,x
        adc $d2
        sta $d2
        lda f:_c0f887+2,x
        adc $d4
        sta $d4
        cld
@e53a:  inx4
        dey
        bne @e523
        ply
        shorta
        iny
        dec $cd
        bne @e515
        jsr _c2e552
        plp
        ply
        plx
        pla
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e552:
_e552:  shorta
        lda #$7e
        pha
        plb
        ldy $d6
        lda #$00
        xba
        lda $ce
        dec
        and #$07
        lsr
        tax
        bcc @e56f
@e566:  lda $d2,x
        lsr4
        jsr _c2e57f
@e56f:  cpx #$0000
        bne @e576
        stz $d1
@e576:  lda $d2,x
        jsr _c2e57f
        dex
        bpl @e566
        rts

_c2e57f:
_e57f:  and #$0f
        bne @e58b
        bit $d1
        bpl @e58b
        lda #$ff
        bra @e590
@e58b:  stz $d1
        clc
        adc #$53
@e590:  longa
        and #$00ff
        sta a:$0000,y
        iny2
        shorta
        rts

; ---------------------------------------------------------------------------

; [ draw text ]

;  A: text length (msb does something)
;  B: source bank
; +Y: source address
; +X: destination address

_c2e59d:
_e59d:  phb
        php
        shorta
        xba
        pha
        plb
        xba
        pha
        and #$7f
        sta $7b         ; length
        stz $7c
        pla
        stz $79
        stz $7a
        and #$80
        sta $7d
        bmi @e5b9
        dec $7a
@e5b9:  shorta
        lda a:$0000,y
        beq @e5ea
        iny
        bit $7d
        bmi @e5db
        jsr _c2e5ed     ; get dakuten
        .a16
        pha
        and #$00ff
        sta $7e0000,x
        pla
        xba
        and #$00ff
        sta $7dffc0,x   ; dakuten
        bra @e5e4
@e5db:  longa
        and #$00ff
        sta $7e0000,x
@e5e4:  inx2
        dec $7b
        bne @e5b9
@e5ea:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ get dakuten ]

_c2e5ed:
_e5ed:  longa
        and #$00ff
        cmp #$0053
        bpl @e60d
        cmp #$0049
        bpl @e607
        cmp #$0020
        bmi @e60d
        clc
        adc #$5140
        bra @e60f
@e607:  clc
        adc #$5217
        bra @e60f
@e60d:  ora $79
@e60f:  rts
        .a8

; ---------------------------------------------------------------------------

_c2e610:
_e610:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        sta $85
        lda $85
@e61d:  beq @e650
        cmp #$0001
        beq @e640
        lda a:$0000,x
        sta $87
        lda a:$0000,y
        sta a:$0000,x
        lda $87
        sta a:$0000,y
        inx2
        iny2
        lda $85
        dec2
        sta $85
        bra @e61d
@e640:  shorta
        lda a:$0000,x
        xba
        lda a:$0000,y
        sta a:$0000,x
        xba
        sta a:$0000,y
@e650:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e653:
_e653:  ldx #$0014
        bra _c2e65b

_c2e658:
        ldx #$0028

_c2e65b:
@e65b:  php
        longa
        pha
@e65f:  jsr _c2e66f
        lda $0a
        and #$8080
        bne @e66c
        dex
        bne @e65f
@e66c:  pla
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2e66f:
_e66f:  php
        shorta
        lda #$80
        sta $c9
@e676:  bit $c9
        bmi @e676
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e67c:
_e67c:  php
        longa
        lda $54
        and #$00ff
        tax
        shorta
        lda f:$000973     ; cursor setting (reset/memory)
        and #$04
        bne @e697
@e68f:  lda f:_c0e9e2,x
        sta $53
        bra @e6a9
@e697:  lda f:_c0e9f3,x
        beq @e68f
        longa
        and #$00ff
        tax
        shorta
        lda $00,x
        sta $53         ; current cursor position
@e6a9:  plp
        rts

; ---------------------------------------------------------------------------

; [ update cursor sprite ]

_c2e6ab:
_e6ab:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        jsr _c2e4df     ; get pointer to current cursor data
        longa
        lda $7602,x     ; xy position
        sta $0200
        lda #$2e02      ; priority 2, palette 7, tile 2
        sta $0202
        shorta
        lda $7600,x
        sta $54
        lda $7601,x
        sta $55
        jsr _c2fad4     ; copy sprite data to vram
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e6d6:
_e6d6:  jsr _c2ebbd
        jsr _c2e76c
        jsr _c2e9ce
        rts

; ---------------------------------------------------------------------------

; [ update spell levels ]

_c2e6e0:
_e6e0:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        stz $e0         ; clear all spell levels
        stz $e1
        stz $e2
        stz $e3
        stz $e4
        stz $e5
        lda #$04        ; loop through all 4 battle command slots
        sta $e6
        ldy $80
        ldx $8e
@e6fc:  lda $0516,y     ; battle command
        bmi @e746
        cmp #$2c
        bmi @e746
        cmp #$49
        bpl @e72b

; spellblade, white, black, time, summon magic
        sec
        sbc #$2c
        longa
        and #$00ff
        tax
        lda f:_c0e931,x   ; spell level / spell type (lo/hi nybble)
        and #$000f
        pha
        lda f:_c0e931,x
        lsr4
        and #$000f
        tax
        pla
        shorta
        bra @e743

@e72b:  cmp #$4c        ; x-magic
        beq @e73f
        bpl @e746

; red magic
        sec
        sbc #$48        ; red mage spell level
@e734:  ldx #$0001      ; white
        jsr _c2e765
        ldx #$0002      ; black
        bra @e743

; x-magic
@e73f:  lda #$03        ; use spell level 3 (black and white)
        bra @e734
@e743:  jsr _c2e765
@e746:  iny             ; next command slot
        dec $e6
        bne @e6fc
        ldy $80
        ldx $8e
@e74f:  lda $e0,x
        asl4
        ora $e1,x
        sta $053d,y     ; spell level
        iny
        inx2
        cpx #$0006
        bne @e74f
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ set spell level ]

_c2e765:
_e765:  cmp $e0,x       ; use highest level found so far
        bmi @e76b
        sta $e0,x
@e76b:  rts

; ---------------------------------------------------------------------------

; [ update character properties ]

_c2e76c:
_e76c:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        jsr _c2e973
        jsr _c2e933
        jsr _c2e879
        jsr _c2d4c5
        jsr _c2e178
        jsr _c2e7b3
        jsr _c2e7cc
        ldy $80
        longa
        lda $eb         ; update stats
        sta $0528,y
        lda $ed
        sta $052a,y
        lda $f2
        sta $052c,y
        lda $f4
        sta $052e,y
        lda $f6         ; update attack power
        sta $0544,y
        shorta
        lda $f1         ; update equipment weight
        sta $0523,y
        jsr _c2e6e0     ; update spell levels
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e7b3:
_e7b3:  php
        ldx $80
        longa
        lda f:$000524,x   ; get base stats
        sta $e7
        lda f:$000526,x
        sta $e9
        lda f:$000520,x
        sta $ef
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e7cc:
_e7cc:  phb
        php
        shorta
        stz $f1
        stz $f2
        stz $f3
        stz $f4
        stz $f5
        ldx $8e
@e7dc:  lda $e0,x
        phx
        jsr _c2d9ab
        txy
        plx
        lda $9c
        clc
        adc $f1
        sta $f1
        lda $a1
        clc
        adc $f2
        sta $f2
        lda $a2
        clc
        adc $f3
        sta $f3
        lda $a3
        clc
        adc $f4
        sta $f4
        lda $a4
        clc
        adc $f5
        sta $f5
        inx
        cpx #$0005
        bne @e7dc
        stz $f8
        lda $f0
        and #$20
        beq @e827
        lda $e3
        ora $e4
        bne @e827
        lda $e5
        beq @e823
        lda $e6
        bne @e827
@e823:  lda #$80
        sta $f8
@e827:  stz $f6
        stz $f7
        ldx $8e
@e82d:  lda $e5,x
        phx
        jsr _c2d9ab
        txy
        plx
        lda $a2
        sta $f6,x
        bit $9f
        bvc @e845
        lda $f8
        bpl @e845
        ora #$01
        sta $f8
@e845:  inx
        cpx #$0002
        bne @e82d
        shorta
        lda $e5
        cmp #$01
        bne @e85b
        lda $e6
        cmp #$01
        bne @e85b
        stz $f7
@e85b:  lda $f6
        clc
        adc $f7
        sta $f6
        lda $8e
        rol
        and #$01
        sta $f7
        lda $f8
        cmp #$81
        bne @e873
        asl $f6
        rol $f7
@e873:  jsr _c2ec76
        plp
        plb
        rts

_c2e879:
_e879:  phb
        php
        shorta
        stz $e0
        stz $e1
        stz $e2
        stz $e3
        stz $e4
        stz $e5
        stz $e6
        stz $e7
        jsr _c2d4c5
        lda #$05
        sta $85
        ldx $80
@e896:  phx
        lda f:$00050e,x
        jsr _c2d9ab
        lda $9e
        bmi @e8a4
        tsb $e0
@e8a4:  lda $a0
        tsb $e2
        lda $a5
        longa
        and #$00ff
        pha
        asl2
        clc
        adc $01,s
        tax
        pla
        lda f:ArmorElementTbl,x                   ; armor elemental properties
        tsb $e3
        lda f:ArmorElementTbl+2,x
        tsb $e5
        shorta
        lda $d12584,x
        tsb $e7
        plx
        inx
        dec $85
        bne @e896
        ldx $80
        lda #$02
        sta $85
@e8d7:  lda f:$000513,x
        phx
        jsr _c2d9ab
        plx
        lda $9e
        bmi @e8e6
        tsb $e0
@e8e6:  lda $a0
        tsb $e1
        inx
        dec $85
        bne @e8d7
        shorta
        lda #$7e
        pha
        plb
        ldy $80
        lda $e0
        sta $0522,y
        phy
        ldx $8e
@e8ff:  lda $e3,x
        sta $0530,y
        inx
        iny
        cpx #$0005
        bne @e8ff
        ply
        longa
        lda $e1
        sta $0538,y
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ get job innate abilities ]

_c2e916:
_e916:  phy
        phx
        and #$001f
        cmp #$0014
        bmi @e92a       ; branch if not mimic or freelancer
        ldy $80
        lda $054e,y
        and #$f7ff
        bra @e930
@e92a:  asl
        tax
        lda f:JobPassiveAbilityTbl,x   ; job passive abilities
@e930:  plx
        ply
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e933:
_e933:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        jsr _c2d4c5
        ldy $80
        lda $0501,y
        jsr _c2e916     ; get job innate abilities
        sta $ef
        lda #$0004
        sta $85
@e94e:  shorta
        lda $0516,y     ; battle command
        longa
        bpl @e962
        and #$007f
        asl
        tax
        lda $d1638c,x                   ; passive ability properties
        tsb $ef
@e962:  iny
        dec $85
        bne @e94e
        ldy $80
        longa
        lda $ef
        sta $0520,y
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e973:
_e973:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        jsr _c2d4c5
        ldy $80
        lda $0501,y
        and #$001f
        asl2
        tax
        lda f:JobEquipTbl,x                   ; job equipment types
        sta $e0
        lda f:JobEquipTbl+2,x
        sta $e2
        lda #$0004
        sta $85
@e99b:  shorta
        lda $0516,y
        bpl @e9b8
        longa
        and #$007f
        asl2
        tax
        lda $d163ce,x                   ; passive ability equipment types
        tsb $e0
        lda $d163d0,x
        tsb $e2
        shorta
@e9b8:  iny
        dec $85
        bne @e99b
        ldy $80
        longa
        lda $e0
        sta $0540,y
        lda $e2
        sta $0542,y
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2e9ce:
_e9ce:  phb
        php
        pea $7e7e
        plb
        plb
        jsr _c2d4c5
        longa
        ldy $80
        lda $0502,y
        and #$00ff
        dec
        asl
        tax
        lda $d15129,x                   ; hp progression values
        sta $e0
        stz $e2
        shorta
        lda $0526,y
        sta $e9
        jsr _c2eaac
        .a16
        lda $e0
        and #$7fff
        cmp #$2710
        bmi @ea04
        lda #$270f
@ea04:  sta $0508,y
        lda $d151ef,x                   ; mp progression values
        sta $e0
        stz $e2
        shorta
        lda $0527,y
        sta $e9
        jsr _c2eaac
        .a16
        lda $e0
        and #$7fff
        cmp #$03e8
        bmi @ea26
        lda #$03e7
@ea26:  sta $050c,y
        ldy $80
        tyx
        shorta
        lda #$04
        sta $85
@ea32:  lda $0516,y
        cmp #$8b
        beq @ea4b
        cmp #$8c
        beq @ea4b
        cmp #$8d
        beq @ea4b
        cmp #$8e
        beq @ea68
        cmp #$8f
        beq @ea68
        bra @ea88
@ea4b:  sec
        sbc #$8a
        sta $e8
        longa
        lda $0508,x
        jsr _c2eaee
        and #$7fff
        cmp #$2710
        bmi @ea63
        lda #$270f
@ea63:  sta $0508,x
        bra @ea88
        .a8
@ea68:  sec
        sbc #$8d
        cmp #$02
        bne @ea70
        inc
@ea70:  sta $e8
        longa
        lda $050c,x
        jsr _c2eaee
        and #$7fff
        cmp #$03e8
        bmi @ea85
        lda #$03e7
@ea85:  sta $050c,x
@ea88:  shorta
        iny
        dec $85
        bne @ea32
        longa
        ldx $80
        lda $0508,x
        cmp $0506,x
        bpl @ea9e
        sta $0506,x
@ea9e:  lda $050c,x
        cmp $050a,x
        bpl @eaa9
        sta $050a,x
@eaa9:  plp
        plb
        rts
        .a8

_c2eaac:
_eaac:  lda $e0
        sta f:hM7A
        lda $e1
        sta f:hM7A
        lda $e9
        clc
        adc #$20
        sta f:hM7B
        sta f:hM7B
        longa
        lda f:hMPYL
        sta $e0
        lda f:hMPYH
        and #$00ff
        sta $e2
        asl $e0
        rol $e2
        asl $e0
        rol $e2
        asl $e0
        rol $e2
        lda $e1
        sta $e0
        lda $e3
        and #$00ff
        sta $e2
        rts

_c2eaee:
_eaee:  php
        longa
        sta $e0
        stz $e2
        shorta
        lda $e8
        asl3
        clc
        adc $e8
        adc $e8
        sta $e8
        stz $e4
        stz $e5
        stz $e6
        stz $e7
        lda $e0
        sta f:hM7A
        lda $e1
        sta f:hM7A
        lda $e8
        sta f:hM7B
        sta f:hM7B
        lda f:hMPYM
        sta f:hWRDIVL
        lda f:hMPYH
        sta f:hWRDIVH
        lda #$64
        sta f:hWRDIVB
        nop8
        lda f:hRDDIVL
        sta $e5
        lda f:hRDDIVH
        sta $e6
        lda f:hMPYL
        sta f:hWRDIVL
        lda f:hRDMPYL
        sta f:hWRDIVH
        lda #$64
        sta f:hWRDIVB
        nop8
        lda f:hRDDIVL
        sta $e4
        longa
        lda $e0
        clc
        adc $e4
        sta $e0
        lda $e2
        adc $e6
        sta $e2
        lda $e0
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2eb82:
_eb82:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldy $80
        lda $0501,y     ; job
        and #$001f
        pha
        asl2
        tax
        pla
        jsr _c2e916     ; get job innate abilities
        sta $0520,y     ; innate abilities
        lda f:JobCmdTbl,x
        sta $0516,y     ; battle commands
        lda f:JobCmdTbl+2,x
        sta $0518,y
        lda f:JobEquipTbl,x
        sta $0540,y     ; equipment types
        lda f:JobEquipTbl+2,x
        sta $0542,y
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2ebbd:
_ebbd:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        jsr _c2d4c5
        stz $e7
        stz $e8
        stz $e9
        stz $ea
        lda #$d1
        sta $84
        lda #$04
        sta $85
        ldx $80
@ebda:  lda $0516,x
        pha
        bmi @ebe5
        ldy #$5e00
        bra @ebe8
@ebe5:  ldy #$6308
@ebe8:  sty $82
        pla
        and #$7f
        jsr _c2ec54
        inx
        dec $85
        bne @ebda
        ldy #near JobStatTbl
        sty $82
        lda #^JobStatTbl
        sta $84
        ldx $80
        lda $0501,x
        and #$1f
        cmp #$14
        bmi @ec18       ; branch if not mimic or freelancer
        longa
        txa
        clc
        adc #$054a
        sta $82
        shorta
        stz $84
        lda #$00
@ec18:  jsr _c2ec54
        ldy #near CharStatMod
        sty $82
        lda #^CharStatMod
        sta $84
        longa
        lda $0500,x     ; character index
        and #$0007
        asl2
        tay
        shorta
        ldx $8e
@ec33:  lda [$82],y
        clc
        adc $e7,x
        sta $e7,x
        iny
        inx
        cpx #$0004
        bne @ec33
        ldx $8e
        ldy $80
@ec45:  lda $e7,x
        sta $0524,y
        iny
        inx
        cpx #$0004
        bne @ec45
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ apply stat bonus ]

_c2ec54:
_ec54:  phx
        phy
        php
        longa
        and #$00ff
        asl2
        tay
        shorta
        ldx $8e
@ec63:  lda [$82],y
        cmp $e7,x
        bmi @ec6b       ; branch if less than current bonus
        sta $e7,x
@ec6b:  iny
        inx
        cpx #$0004
        bne @ec63
        plp
        ply
        plx
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2ec76:
_ec76:  phb
        php
        shorta
        stz $eb
        stz $ec
        stz $ed
        stz $ee
        ldx $8e
@ec84:  lda $e0,x
        phx
        jsr _c2d9ab
        plx
        lda $9e
        bpl @ecbd
        phx
        pha
        longa
        and #$0007
        asl
        tax
        lda f:EquipStatBonusTbl,x                   ; item stat bonus values
        sta $f9
        shorta
        pla
        and #$78
        asl
        ldx $8e
@eca6:  asl
        xba
        bcc @ecae
        lda $fa
        bra @ecb0
@ecae:  lda $f9
@ecb0:  clc
        adc $eb,x
        sta $eb,x
        xba
        inx
        cpx #$0004
        bne @eca6
        plx
@ecbd:  inx
        cpx #$0007
        bne @ec84
        ldx $8e
@ecc5:  lda $e7,x
        clc
        adc $eb,x
        bpl @ecce
        lda #$00
@ecce:  sta $eb,x
        inx
        cpx #$0004
        bne @ecc5
        plp
        plb
        rts

_c2ecd9:
        pea $7e7e
        plb
        plb
        longa
        stz $75
        ldy $80
        lda $0540,y
        sta $e0
        lda $0542,y
        sta $e2
        stz $e6
        stz $e8
        rts

_c2ecf3:
_ecf3:  ldy $8e
@ecf5:  longa
        lda $0740,y
        and #$00ff
        beq @ed47
        sta $e8
        lda $0640,y
        and #$00ff
        sta $e6
        cmp $93
        bmi @ed47
        cmp $95
        bpl @ed47
        jsr _c2d9ab
        lda $e4
        bmi @ed1e
        lda $9b
        and $e4
        beq @ed47
@ed1e:  lda $9d
        and #$003f
        asl2
        tax
        lda f:EquipTypeTbl,x           ; item equipment types
        and $e0
        bne @ed36
        lda f:EquipTypeTbl+2,x
        and $e2
        beq @ed47
@ed36:  shorta
        ldx $75
        lda $e6
        sta $7a00,x
        lda $e8
        sta $7b00,x
        inx
        stx $75
@ed47:  iny
        cpy #$0100
        bne @ecf5
        shorta
        ldx $75
@ed51:  stz $7a00,x
        stz $7b00,x
        inx
        cpx #$0100
        bne @ed51
        rts

_c2ed5e:
        .a16
_ed5e:  phb
        php
        jsr _c2ecd9
        lda #$0089
        sta $93
        lda #$00e0
        sta $95
        shorta
        lda $6f
        dec3
        longa
        and #$0003
        asl
        tax
        lda f:_c0f5c9,x
        sta $e4
        jsr _c2ecf3
        plp
        plb
        rts
        .a8

_c2ed87:
        .a16
_ed87:  phb
        php
        jsr _c2ecd9
        lda #$0002
        sta $93
        lda #$0080
@ed94:  sta $95
        lda #$8000
        sta $e4
        jsr _c2ecf3
        longa
        lda #$0080
        sta $93
        lda #$00e0
        sta $95
        lda #$0008
        sta $e4
        jsr _c2ecf3
        plp
        plb
        rts

_c2edb5:
        ldy $8e
@edb7:  shorta
        lda $7a00,y
        beq @edd2
        jsr _c2d9ab
        lda $a2
        sta $7e00,y
        cpy $75
        beq @edd2
        cpy #$00ff
        beq @edd2
        iny
        bra @edb7
@edd2:  rts

_c2edd3:
_edd3:  longa
        ldx #$0100
@edd8:  dex2
        stz $7f00,x
        bne @edd8
        shorta
        ldy $8e
@ede3:  lda $7a00,y
        beq @ee02
        lda $7e00,y
        longa
        and #$00ff
        tax
        shorta
        inc $7f00,x
        cpy $75
        beq @ee02
        cpy #$00ff
        beq @ee02
        iny
        bra @ede3
@ee02:  rts

_c2ee03:
_ee03:  shorta
        ldy #$00fe
@ee08:  lda $7f00,y
        clc
        adc $7f01,y
        sta $7f00,y
        cpy #$0000
        beq @ee1a
        dey
        bra @ee08
@ee1a:  rts

_c2ee1b:
_ee1b:  shorta
        ldy $8e
@ee1f:  lda $7a00,y
        beq @ee62
        lda $7e00,y
        beq @ee56
        cmp #$ff
        bne @ee32
        ldx #$0000
        bra @ee40
@ee32:  inc
        longa
        and #$00ff
        tax
        lda $7f00,x
        and #$00ff
        tax
@ee40:  shorta
@ee42:  lda $8000,x
        beq @ee4a
        inx
        bra @ee42
@ee4a:  lda $7a00,y
        sta $8000,x
        lda $7b00,y
        sta $8100,x
@ee56:  cpy $75
        beq @ee62
        cpy #$00ff
        beq @ee62
        iny
        bra @ee1f
@ee62:  rts

_c2ee63:
        longa
        lda $7f01
        and #$00ff
        tax
        shorta
        ldy $8e
@ee70:  lda $7a00,y
        beq @ee93
        lda $7e00,y
        bne @ee87
        lda $7a00,y
        sta $8000,x
        lda $7b00,y
        sta $8100,x
        inx
@ee87:  cpy $75
        beq @ee93
        cpy #$00ff
        beq @ee93
        iny
        bra @ee70
@ee93:  rts

_c2ee94:
_ee94:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        longa
        ldx #$0400
@eea1:  dex2
        stz $7e00,x
        bne @eea1
        jsr _c2edb5
        jsr _c2edd3
        jsr _c2ee03
        jsr _c2ee1b
        jsr _c2ee63
        longa
        ldx #$8000
        ldy #$7a00
        lda #$01ff
        mvn #$7e,#$7e
        plp
        plb
        rts
        .a8

_c2eec8:
_eec8:  phb
        pea $7e7e
        plb
        plb
        stx $f2
        sty $f4
        lda #$04
        sta $f6
        ldy $8e
        sec
@eed9:  lda ($f2),y
        sbc ($f4),y
        sta $281d,y
        iny
        dec $f6
        bne @eed9
        plb
        rts

_c2eee7:
_eee7:  phb
        php
        longa
        and #$000f
        asl
        tax
        lda f:_c0f208,x
        jsr LoadMenuTilemap
        jsr _c2a698
        .a8
        plp
        plb
        rts

_c2eefd:
_eefd:  jsr _c2efc5
        jsr _c2ef16
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2e658
        jsr _c2ef89
        jsr _c2ef16
        jsr _c2fad4     ; copy sprite data to vram
        jsr _c2e66f
        rts

_c2ef16:
_ef16:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        stz $f1
        stz $7e
@ef23:  jsr _c2d4c5
        ldx $80
        lda $0500,x
        and #$0040
        bne @ef75
        lda $0540,x
        sta $eb
        lda $0542,x
        sta $ed
        lda $55
        dec
        and #$000f
        asl2
        tay
        lda $eb
        and $285e,y
        bne @ef53
        lda $ed
        and $2860,y
        bne @ef53
        bra @ef75
@ef53:  lda $7e
        asl3
        tay
        lda $0240,y
        sec
        sbc #$000c
        sta $0240,y
        lda $0244,y
        sec
        sbc #$000c
        sta $0244,y
        ldx $7e
        lda f:_c0f204,x
        tsb $f1
@ef75:  lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @ef23
        shorta
        lda $f1
        sta $2886
        plp
        plb
        rts

_c2ef89:
        phb
        php
        longa
        ldx #near _c0f4b4
        ldy #$0240
        lda #$001f
        mvn #^_c0f4b4,#$7e
        jsr _c2ef9f
        plp
        plb
        rts

_c2ef9f:
        .a16
        stz $7e
@efa1:  jsr _c2d4c5
        ldy $80
        lda $7e
        asl3
        tax
        lda $0500,y
        and #$0040
        beq @efba
        stz $0242,x
        stz $0246,x
@efba:  lda $7e
        inc
        sta $7e
        cmp #$0004
        bne @efa1
        rts

_c2efc5:
        phb
        php
        longa
        and #$0001
        inc
        asl
        tax
        lda f:_c0f4ae,x
        tax
        ldy #$0240
        lda #$001f
        mvn #^_c0f4ae,#$7e
        jsr _c2ef9f
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2efe3:
_efe3:  phb
        php
        pea $7e7e
        plb
        plb
        lda $2809
        jsr _c2f00b                     ; give spell
        ldx $8e
@eff2:  lda f:MagicSwordAttackTbl,x                   ; spellblade spells
        beq @f008
        cmp $2809
        beq @f001
        inx2
        bra @eff2
@f001:  lda f:MagicSwordAttackTbl+1,x
        jsr _c2f00b                     ; give spell
@f008:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ give spell ]

_c2f00b:
_f00b:  phx
        php
        shorta
        jsr _c2f01d
        ora f:$000950,x   ; known spells
        sta f:$000950,x
        plp
        plx
        rts

; ---------------------------------------------------------------------------

_c2f01d:
_f01d:  php
        phy
        longa
        and #$00ff
        pha
        lsr3
        tax
        pla
        and #$0007
        tay
        shorta
        lda #$80
@f032:  cpy #$0000
        beq @f03b
        dey
        lsr
        bra @f032
@f03b:  ply
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2f03e:
_f03e:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        stz $2811
        stz $2812
        stz $2813
        lda $2809
        longa
        and #$00ff
        jsr _c2f01d
        shorta
        and $0950,x     ; spells known
        beq @f065       ; branch if spell is not known
        inc $2811
@f065:  lda #$01
        sta $2814
        jsr _c2f0e6
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2f070:
_f070:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        lda $2809
        ldx $8e
@f07e:  cmp $0640,x     ; item index
        beq @f08b
        inx
        cpx #$0100
        beq @f093
        bra @f07e
@f08b:  lda $0740,x     ; item quantity
        sta $2811
        bra @f096
@f093:  stz $2811
@f096:  stz $2812
        ldy $8e
@f09b:  sty $7e
        jsr _c2d4c5
        ldx $80
        bit $0500,x
        bvs @f0bb       ; branch if character is not present
        phy
        ldy #$0007
@f0ab:  lda $050e,x
        cmp $2809
        bne @f0b6
        inc $2812
@f0b6:  inx
        dey
        bne @f0ab
        ply
@f0bb:  iny
        cpy #$0004
        bne @f09b
        lda #$63
        sec
        sbc $2811
        sbc $2812
        bpl @f0ce
        lda #$00
@f0ce:  sta $2813
        lda $2805
        bpl @f0db
        lda #$01
        sta $2813
@f0db:  lda #$01
        sta $2814
        jsr _c2f0e6
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2f0e6:
_f0e6:  php
        shorta
        lda $7e2814
        sta $e0
        longa
        lda $7e280c
        sta $e1
        lda $7e280e
        sta $e3
        jsr _c2f2fb
        lda $e5
        sta $7e2819
        lda $e7
        sta $7e281b
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2f10e:
_f10e:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldy $8e
@f119:  tya
        asl
        tax
        lda f:_c0f1f4,x
        tax
        lda $2826,y
        and #$00ff
        beq @f158
        phy
        phx
        txy
        bit $2802
        bmi @f136
        jsr _c2e44e     ; draw item name
        bra @f139
@f136:  jsr _c2e42c     ; draw spell name
@f139:  pla
        clc
        adc #$0014
        tax
        lda 1,s
        and #$000f
        asl2
        clc
        adc #$282e
        tay
        lda #$7e73
        jsr _c2e4ed
        ply
        iny
        cpy #$0008
        bne @f119
@f158:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ draw shop type name ]

_c2f15b:
_f15b:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        lda $2801       ; shop type
        and #$0007
        asl3
        clc
        adc #near ShopName
        tay
        ldx #$50c4
        lda #make_word 5, ^ShopName
        jsr _c2e59d
        bit $2802
        bmi @f18c
        ldx #$51ce
.if LANG_EN
        ldy #near _c0faa0
        lda #make_word 3, ^_c0faa0
.else
        ldy #near _c0f514
        lda #make_word 2, ^_c0f514
.endif
        jsr _c2e59d
@f18c:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ load shop properties ]

_c2f18f:
_f18f:  phb
        php
        shorta
        lda #$7e
        pha
        plb
        lda $2800       ; shop index
        longa
        and #$00ff
        pha
        asl3            ; multiply by 9
        clc
        adc $01,s
        tax
        pla
        shorta
        lda f:ShopProp,x   ; shop properties
        sta $2801       ; shop type
        inx
        txy
        and #$07
        xba
        lda #$00
        xba
        tax
        lda f:_c0f1ec,x
        pha
        xba
        pla
        longa
        sta $2802
        tya
        clc
        adc #near ShopProp      ; pointer to items
        tax
        ldy #$2826      ; copy to 7E/2826
        lda #$0007      ; copy 8 bytes
        mvn #^ShopProp,#$7e
        shorta
        lda $2802
        sta $2825
        ldx $8e
@f1df:  shorta
        lda $2826,x     ; item index
        sta $2809
        jsr _c2f29f     ; get item price
        longa
        txa
        asl
        tay
        lda $280a       ; item price
        sta $284e,y
        lda $2801
        and #$0080
        beq @f212       ; branch if no discount
        shorta
        bit $2805
        longa
        bpl @f20c
        lsr $280e       ; divide price by 4
        ror $280c
@f20c:  lsr $280e       ; divide price by 2
        ror $280c
@f212:  txa
        asl2
        tay
        lda $280c
        sta $282e,y
        lda $280e
        sta $2830,y
        inx
        cpx #$0008
        bne @f1df
        ldx $8e
@f22a:  stz $285e,x
        stz $2860,x
        inx4
        cpx #$0020
        bne @f22a
        lda $2801
        and #$0007
        beq @f29c       ; branch if a magic shop
        ldy $8e
@f243:  longa
        lda $2826,y
        jsr _c2d9ab
        lda $2826,y
        and #$00ff
        beq @f290
        cmp #$00e0
        shorta
        bpl @f283
        lda $9d
        longa
        and #$003f
        asl2
        tax
        phy
        tya
        asl2
        tay
        lda f:EquipTypeTbl,x   ; item equipment types
        sta $285e,y
        lda f:EquipTypeTbl+2,x
        sta $2860,y
        ply
        shorta
        lda $9f
        and #$3f
        clc
        adc #$00
        bra @f287
@f283:  lda $9e
        and #$3f
@f287:  sta $287e,y
        iny
        cpy #$0008
        bne @f243
@f290:  tyx
@f291:  cpx #$0008
        beq @f29c
        stz $287e,x
        inx
        bra @f291
@f29c:  plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ get item price ]

_c2f29f:
_f29f:  phb
        phx
        php
        pea $7e7e
        plb
        plb
        longa
        lda $2809
        and #$00ff
        asl
        tax
        lda $2825
        and #$0080
        bne @f2bf
        lda f:ItemPriceTbl,x   ; item price
        bra @f2c3
@f2bf:  lda f:MagicPriceTbl,x   ; spell price
@f2c3:  sta $280a
        jsr _c2f2cd
        plp
        plx
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2f2cd:
_f2cd:  php
        shorta
        lda $280b
        sta $e0
        lda $280a
        longa
        and #$001f
        asl2
        tax
        lda f:_c0f517,x   ; price multiplier
        sta $e1
        lda f:_c0f517+2,x
        sta $e3
        jsr _c2f2fb     ; multiply
        lda $e5
        sta $280c       ; set item price
        lda $e7
        sta $280e
        plp
        rts

; ---------------------------------------------------------------------------

_c2f2fb:
_f2fb:  php
        longa
        stz $e5
        stz $e7
        shorta
        lda $e0
        sta f:hWRMPYA
        ldx $8e
@f30c:  shorta
        lda $e1,x
        sta f:hWRMPYB
        nop3
        longa
        lda f:hRDMPYL
        clc
        adc $e5,x
        sta $e5,x
        inx
        cpx #$0003
        bne @f30c
        plp
        rts

_c2f32a:
_f32a:  phb
        php
        lda $2bf4
        bne @f393
        lda #near _c3b59e
        jsr LoadMenuTilemap
        ldx $e6
        ldy #$2c04
        lda #$7e06
        jsr _c2e59d
        lda $e6
        clc
        adc #$0034
        tax
        ldy #$2bf6
        lda #$7e21
        jsr _c2e4ed
        lda $e6
        clc
        adc #$00a6
        tax
        ldy #$2bf8
        jsr _c2d5db
        lda $e6
        clc
        adc #$0080
        tax
        ldy #$2c0c
        jsr _c2d662
        lda $2c0a
        asl3
        tax
        lda $2c12
        sta $7362,x
        lda $e6
        sec
        sbc #$0082
        tax
        lda $2c0a
        inc4
        xba
        and #$0700
        ora #$80c0
        jsr _c2d6dc
        bra @f399
@f393:  lda #near _c3b5b1
        jsr LoadMenuTilemap
@f399:  plp
        plb
        rts

_c2f39c:
        .a16
_f39c:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx $8e
        ldy #$2c14
@f3aa:  phx
        phy
        lda f:_c0f3c5,x
        sta $e6
        tyx
        ldy #$2bf4
        lda #$001f
        mvn #$7e,#$7e
        jsr _c2f32a
        ply
        plx
        inx2
        tya
        clc
        adc #$0020
        tay
        cpx #$0008
        bne @f3aa
        plp
        plb
        rts

_c2f3d1:
        .a16
_f3d1:  and #$000f
        dec
        and #$0003
        xba
        lsr3
        rts

_c2f3dd:
        .a8
_f3dd:  asl
        pha
        lda $0293,x
        and #$f1
        ora $01,s
        sta $0293,x
        sta $0297,x
        pla
        inx8
        rts

_c2f3f6:
_f3f6:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        lda $52
        and #$00ff
        cmp #$0009
        beq @f41a
        jsr _c2f3d1
        tax
        shorta
        ldy #$0004
@f412:  lda #$06
        jsr _c2f3dd
        dey
        bne @f412
@f41a:  longa
        lda $55
        jsr _c2f3d1
        tay
        pha
        stz $85
@f425:  lda $2c1c,y
        and #$1f07
        phy
        ldy $85
        jsr _c2d492
        ply
        iny2
        lda $85
        inc
        sta $85
        cmp #$0004
        bne @f425
        plx
        shorta
        ldy $8e
@f443:  tya
        jsr _c2f3dd
        iny
        cpy #$0004
        bne @f443
        plp
        plb
        rts

_c2f450:
_f450:  phb
        php
        longa
        ldx #near _c0f907
        ldy #$0290
        lda #$007f
        mvn #^_c0f907,#$7e
        plp
        plb
        rts

_c2f463:
_f463:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx #$1800
        lda $8e
@f471:  sta $affe,x
        dex2
        bne @f471
        stz $f6
@f47a:  lda $f6
        asl5
        tay
        lda $2c14,y
        bne @f4c1
        lda $f6
        asl
        tax
        lda f:_c0f8ff,x
        sta $e4
        lda #$0004
        sta $85
@f496:  lda $2c1c,y
        bit #$0040
        bne @f4b3
        and #$1f07
        sta $ea
        phy
        phb
        jsr _c2d2db
        lda #$0006
        ldx #$ed31
        jsr _c2d304
        plb
        ply
@f4b3:  iny2
        lda $e4
        clc
        adc #$0040
        sta $e4
        dec $85
        bne @f496
@f4c1:  lda $f6
        inc
        sta $f6
        cmp #$0004
        bne @f47a
        ldx #near _c0efd9
        jsr _c2d9fb
        plp
        plb
        rts

_c2f4d4:
_f4d4:  phb
        php
        pea $3030
        plb
        plb
        longa
        stz $f6
@f4df:  jsr _c2f4ef
        lda $f6
        inc
        sta $f6
        cmp #$0004
        bne @f4df
        plp
        plb
        rts

_c2f4ef:
        .a16
_f4ef:  lda $f6
        asl
        tax
        lda f:_c0f8e7,x
        clc
        adc #$6000
        sta $fc
        tax
        lda $044a,x
@f501:  sta $f8
        lda $044c,x
        sta $fa
        lda $0490,x
        sta $f0
        lda $0492,x
        sta $f2
        lda $0494,x
        sta $f4
        lda $0471,x
        sta $fe
        jsr _c2f561
        ldy $fc
        ldx $8e
@f523:  lda a:$0000,y
        sta $e8,x
        and #$0007
        bne @f53c
        lda $0002,y
        sta $e2
        lda a:$0006,y
        sta $e4
        lda a:$0008,y
        sta $e6
@f53c:  tya
        clc
        adc #$0050
        tay
        inx2
        cpx #$0008
        bne @f523
        lda $f6
        and #$0003
        asl
        tax
        lda f:_c0f8f7,x
        tay
        ldx #$01e0
        lda #$001f
        phb
        mvn #$00,#$7e
        plb
        rts

_c2f561:
        .a16
@f561:  lda $f6
        and #$0003
        asl
        tax
        lda $7ff8,x
        cmp #$e41b
        bne @f57d
        jsr _c2f588
        cmp $7ff0,x
        bne @f582
        lda #$0000
        bra @f585
@f57d:  lda #$8000
        bra @f585
@f582:  lda #$4000
@f585:  sta $e0
        rts

_c2f588:
_f588:  phb
        phx
        phy
        php
        pea $3030
        plb
        plb
        longa
        ldx $fc
        ldy #$0600
        lda $8e
        clc
@f59b:  adc a:$0000,x
        inx2
        dey2
        bne @f59b
        plp
        ply
        plx
        plb
        rts

; ---------------------------------------------------------------------------

; [ update mono/stereo setting ]

_c2f5a9:
_f5a9:  php
        shorta
        lda f:$000973
        and #$02
        lsr
        clc
        adc #$f3        ; $F3 = stereo, $F4 = mono
        sta f:$001d00
        jsl ExecSound_ext
        plp
        rts

; ---------------------------------------------------------------------------

_c2f5c0:
_f5c0:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        stz $85
        stz $7e
@f5cd:  lda $7e
        asl
        tax
        lda f:_c0ea0e,x
        sta $2bba
        jsr _c2d4c5
        jsr _c2ddd7
        ldx $80
        lda $0500,x
        and #$0040
        beq @f5f2
        lda $85
        clc
        adc #$0004
        sta $85
        bra @f631
@f5f2:  txa
        clc
        adc #$0516
        sta $82
        ldx $8e
@f5fb:  phx
        lda f:_c0ea16,x
        clc
        adc $2bba
        pha
        ldx $85
        lda $2cb4,x
        inx
        stx $85
        and #$0003
        tay
        lda ($82),y
        and #$00ff
        plx
        phx
        pha
        jsr _c2d8e4
        pla
        plx
        cmp #$0080
        bmi @f629
        lda #$0108
        jsr _c2d6dc
@f629:  plx
        inx2
        cpx #$0008
        bne @f5fb
@f631:  inc $7e
        lda $85
        cmp #$0010
        bne @f5cd
        plp
        plb
        rts

_c2f63d:
_f63d:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        ldx #$002f
@f649:  stz $2c9b,x
        dex
        bne @f649
        longa
        lda $8e
        shorta
        ldx $8e
@f657:  phx
        lda f:_c0f0a5,x
        tay
        lda f:_c0f0a5+2,x
        pha
        lda f:_c0f0a5+1,x
        tax
        pla
        and $0970,y
        beq @f670
        inc $2c9c,x
@f670:  plx
        inx3
        cpx #$0018
        bne @f657
        shorta
        lda $0970
        pha
        and #$07
        sta $2c9d
        pla
        lsr4
        and #$07
        sta $2c9e
        longa
        lda $0971
        ldx $8e
@f695:  jsr _c2f709
        cpx #$0003
        bne @f695
        ldx #$0975
        ldy #$2ca9
        lda #$001a
        mvn #$7e,#$7e
        jsr _c2f6af
        plp
        plb
        rts

_c2f6af:
_f6af:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        ldx $8e
@f6ba:  ldy $8e
        lda $2ca9,x
@f6bf:  asl
        bcs @f6c9
        iny
        cpy #$0006
        bmi @f6bf
        dey
@f6c9:  tya
        sta $2cc4,x
        inx
        cpx #$0007
        bmi @f6ba
        plp
        plb
        rts

_c2f6d6:
_f6d6:  phb
        php
        pea $7e7e
        plb
        plb
        shorta
        ldx $8e
@f6e1:  ldy $8e
        lda $2cc4,x
        xba
        lda #$80
        xba
@f6ea:  cmp #$00
        beq @f6fc
        dec
        xba
        lsr
        xba
        iny
        cpy #$0006
        bmi @f6ea
        xba
        lda #$04
        xba
@f6fc:  xba
        sta $2ca9,x
        inx
        cpx #$0007
        bmi @f6e1
        plp
        plb
        rts

_c2f709:
        .a16
_f709:  pha
        php
        and #$001f
        shorta
        sta $2ca6,x
        plp
        pla
        lsr5
        inx
        rts

; ---------------------------------------------------------------------------

; [ update config settings ]

_c2f71c:
_f71c:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx $8e
@f727:  stz $0970,x
        inx2
        cpx #$0020
        bne @f727
        ldx $8e
        txa
        shorta
@f736:  phx
        lda f:_c0f0a5,x
        tay
        lda f:_c0f0a5+1,x
        tax
        lda $2c9c,x
        beq @f753
        plx
        lda f:_c0f0a5+2,x
        ora $0970,y
        sta $0970,y
        bra @f754
@f753:  plx
@f754:  inx3
        cpx #$0018
        bne @f736
        shorta
        lda $2c9e
        asl4
        ora $2c9d
        and #$77
        ora $0970
        sta $0970
        jsr _c2f5a9     ; update mono/stereo setting
        longa
        ldx #$0002
        ldy $8e
@f77a:  lda $0971
        asl5
        sta $0971
        lda $2ca6,x
        and #$001f
        ora $0971
        sta $0971
        dex
        bpl @f77a
        jsr _c2f6d6
        ldx #$2ca9
        ldy #$0975
        lda #$001a
        mvn #$7e,#$7e
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2f7a6:
_f7a6:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldx $2c94
        lda f:_c0f1bd,x
        tay
        lda f:_c0f18e,x
        sta $2c9a
        lda f:_c0f0c3,x
        and #$00ff
        sta $2c96
        asl
        tax
        lda f:_c0f0f2,x
        tax
        tya
        and #$00ff
        ora #$0100
        jsr _c2f7fc
        ldy $2c9a
        ldx $2c94
        lda $2c9c,x
        and #$00ff
        clc
        adc $2c96
        asl
        tax
        lda f:_c0f0f2,x
        tax
        lda $2c9a
        and #$00ff
        jsr _c2f7fc
        plp
        plb
        rts

_c2f7fc:
_f7fc:  ldy $2c94
        cpy #$0001
        beq @f809
        cpy #$0002
        bne @f80c
@f809:  ora #$8000
@f80c:  jsr _c2d6dc
        rts

_c2f810:
        phb
        php
        pea $7e7e
        plb
        plb
        longa
        ldy $8e
@f81b:  tya
        asl
        tax
        lda f:_c0f0bd,x
        tax
        phy
        lda $2ca6,y
        pha
        and #$001c
        lsr2
@f82d:  tay
        beq @f83d
        phy
        lda #$00fe
@f834:  sta a:$0000,x
        inx2
        dey
        bne @f834
        ply
@f83d:  pla
        and #$0003
        beq @f84f
        dec
        asl
        clc
        adc #$00f8
        sta a:$0000,x
        inx2
        iny
@f84f:  lda #$000c
@f852:  cpy #$0008
        beq @f85f
        sta a:$0000,x
        inx2
        iny
        bra @f852
@f85f:  ply
        iny
        cpy #$0003
        bne @f81b
        plp
        plb
        rts

_c2f869:
_f869:  phb
        php
        pea $7e7e
        plb
        plb
        longa
        stz $2cd1
        stz $2cd3
        stz $2cd5
        stz $2cd7
        shorta
        lda #$01
        sta $6f
        jsr _c2ed87
        ldx $75
        beq @f8ae
        jsr _c2ee94
        ldx $8e
        ldy $80
        lda $0521,y
        bit #$21
        beq @f8a4
        inx
        bit #$01
        beq @f8a4
        inx
        bit #$20
        beq @f8a4
        inx
@f8a4:  longa
        txa
        asl
        tax
        shorta
        jsr (near _c2fff8,x)
@f8ae:  plp
        plb
        rts

_c2f8b1:
_f8b1:  php
        shorta
        stx $2ccd
        and #$03
        dec
        sta $2ccf
        stz $2cd0
        stz $2ccb
        stz $2ccc
        ldy $8e
@f8c8:  lda $7b00,y
        beq @f8f5
        lda $7a00,y
        bmi @f8f5
        and #$7f
        jsr _c2d9ab
        lda $9f
        and $2ccd
        eor $2cce
        beq @f8f5
        lda $a2
        sta $2ccc
        lda $7a00,y
        sta $2ccb
        lda $7b00,y
        dec
        sta $7b00,y
        bra @f8fa
@f8f5:  iny
        cpy $75
        bmi @f8c8
@f8fa:  ldx $2ccf
        lda $2ccb
        sta $2cd1,x
        lda $2ccc
        sta $2cd5,x
        plp
        rts

_c2f90b:
_f90b:  php
        shorta
        and #$03
        dec
        sta $2ccf
        stz $2cd0
        ldx $2ccf
        ldy $8e
@f91c:  lda $7b00,y
        beq @f92b
        lda $7a00,y
        bpl @f92b
        sta $2cd1,x
        bra @f930
@f92b:  iny
        cpy $75
        bmi @f91c
@f930:  plp
        rts

; ---------------------------------------------------------------------------

_c2f932:
_f932:  ldy $75
        dey
@f935:  lda $7a00,y
        bmi @f93f
        sta $2cd1
        bra @f942
@f93f:  sta $2cd2
@f942:  dey
        bpl @f935
        jsr _c2fa75
        rts

; ---------------------------------------------------------------------------

_c2f949:
_f949:  ldx #$0040
        lda #$01
        jsr _c2f8b1
        ldx #$c0c0
        lda #$02
        jsr _c2f8b1
        lda #$03
        jsr _c2f90b
        longa
        lda $2cd6
        and #$00ff
        pha
        lda $2cd5
        and #$00ff
        asl
        cmp $01,s
        beq @f979
        bmi @f979
        stz $2cd2
        bra @f97f
@f979:  lda $2cd2
        sta $2cd1
@f97f:  plx
        jsr _c2fa75
        rts
        .a8

; ---------------------------------------------------------------------------

_c2f984:
_f984:  ldx #$0080
        lda #$01
        jsr _c2f8b1
        ldx #$8080
        lda #$02
        jsr _c2f8b1
        ldx #$8080
        lda #$03
        jsr _c2f8b1
        lda $2cd3
        bne @f9a6
        lda #$03
        jsr _c2f90b
@f9a6:  longa
        lda $2cd6
        and #$00ff
        pha
        lda $2cd7
        and #$00ff
        clc
        adc $01,s
        sta $01,s
        lda $2cd5
        and #$00ff
        cmp $01,s
        beq @f9cb
        bmi @f9cb
        stz $2cd2
        bra @f9d1
@f9cb:  lda $2cd2
        sta $2cd1
@f9d1:  plx
        jsr _c2fa75
        rts
        .a8

; ---------------------------------------------------------------------------

_c2f9d6:
_f9d6:  ldx #$0040
        lda #$01
        jsr _c2f8b1
        ldx #$0080
        lda #$02
        jsr _c2f8b1
        ldx #$8080
        lda #$03
        jsr _c2f8b1
        lda $2cd1
        bne @fa14
        lda $2cd3
        sta $2cd1
        lda $2cd7
        sta $2cd3
        ldx #$8080
        lda #$03
        jsr _c2f8b1
        longa
        lda $2cd5
        and #$00ff
        sta $2cd9
        bra @fa20
@fa14:  longa
        lda $2cd5
        and #$00ff
        asl
        sta $2cd9
@fa20:  lda $2cd6
        and #$00ff
        sta $2cdb
        lda $2cd5
        and #$00ff
        sta $2cdd
        lda $2cd7
        and #$00ff
        clc
        adc $2cdd
        sta $2cdd
        cmp $2cdb
        beq @fa4d
        bmi @fa4d
        cmp $2cd9
        bmi @fa6c
        bra @fa62
@fa4d:  lda $2cdb
        cmp $2cd9
        bmi @fa6c
        shorta
        lda $2cd2
        sta $2cd1
        stz $2cd2
        bra @fa71
@fa62:  shorta
        lda $2cd3
        sta $2cd2
        bra @fa71
@fa6c:  shorta
        stz $2cd2
@fa71:  jsr _c2fa75
        rts

_c2fa75:
_fa75:  shorta
        lda #$01
        sta $6f
        lda $2cd1
        beq @fa85
        sta $72
        jsr _c2fa92
@fa85:  lda $2cd2
        beq @fa91
        sta $72
        inc $6f
        jsr _c2fa92
@fa91:  rts

_c2fa92:
_fa92:  php
        jsr _c2e0f7
        lda $90
        bne @faab
        jsr _c2e178
        jsr _c2e1a6
        jsr _c2e18f
        lda #$01
        xba
        lda $72
        jsr _c2e328
@faab:  plp
        rts

_c2faad:
_faad:  phb
        php
        shorta
        lda #$03
        sta $6f
@fab5:  jsr _c2ed5e
        ldx $75
        beq @fac8
        jsr _c2ee94
        lda $7e7a00
        sta $72
        jsr _c2fa92
@fac8:  lda $6f
        inc
        sta $6f
        cmp #$06
        bne @fab5
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ copy sprite data to vram ]

_c2fad4:
_fad4:  phb
        php
        longa
        ldx #near _c0f5b2      ; 02 04 00 02 00 20 02 (sprite data)
        ldy #near hDMA0
        lda #$0006
        mvn #^_c0f5b2,#^hDMA0
        stz hOAMADDL
        shorta
        lda #$01
        tsb $ca
        plp
        plb
        rts

; ---------------------------------------------------------------------------

_c2faf0:
_faf0:  phb
        php
        longa
        ldx #near _c0f5b9
        ldy #near hDMA1
        lda #$0006
        mvn #^_c0f5b9,#^hDMA1
        shorta
        stz hCGADD
        lda #$02
        tsb $ca
        plp
        plb
        rts

; ---------------------------------------------------------------------------

; [ menu nmi ]

MenuNMI:
_fb0c:  phb
        phd
        php
        longa
        pha
        php
        phx
        phy
        shorta
        lda #$00
        pha
        plb
        lda hRDNMI
        lda #$01
        sta hNMITIMEN
        stz hHDMAEN
        lda #$80
        sta hINIDISP
        pea $0100       ; set dp
        pld
        lda $c9
        jeq @fbe7
        stz $c9
        lda $ca
        and #$03
        beq @fb43
        trb $ca
        sta hMDMAEN
@fb43:  lda #$04
        bit $ca
        beq @fb90
        trb $ca
        phd
        pea $2100                       ; use video register dp
        pld
        ldx #$7500
        stx <hWMADDL
        stz <hWMADDH
        lda <hWMDATA                    ; $7500
        sta <hTM
        lda <hWMDATA                    ; $7501
        sta <hTS
        lda <hWMDATA                    ; $7502
        sta <hTMW
        lda <hWMDATA                    ; $7503
        sta <hTSW
        lda <hWMDATA                    ; $7504
        sta <hW12SEL
        lda <hWMDATA                    ; $7505
        sta <hW34SEL
        lda <hWMDATA                    ; $7506
        sta <hWOBJSEL
        lda <hWMDATA                    ; $7507
        sta <hWBGLOG
        lda <hWMDATA                    ; $7508
        sta <hWOBJLOG
        lda <hWMDATA                    ; $7509
        sta <hCGADSUB
        lda <hWMDATA                    ; $750a
        sta <hCGSWSEL
        lda <hWMDATA                    ; $750b
        sta <hCOLDATA
        lda <hWMDATA                    ; $750c
        sta <hCOLDATA
        lda <hWMDATA                    ; $750d
        sta <hCOLDATA
        pld
@fb90:  stz $0c
        stz $0d         ; selected character (multi controller)
        jsr _c2fe5b     ; update joypad input
        shorta
        lda #$7e
        pha
        plb
        lda #$ff
        bit $750f
        beq @fba7
        dec $751d
@fba7:  bit $7510
        beq @fbaf
        dec $751f
@fbaf:  lda $7511
        beq @fbe7
        longa
        lda $7514
        sta f:hVMADDL
        lda $7516
        sta f:hDMA0::CTRL
        lda $7518
        sta f:hDMA0::ADDR
        lda $751a
        sta f:hDMA0::ADDR_B
        lda $751b
        sta f:hDMA0::SIZE
        shorta
        lda $7511
        and #$01
        sta f:hMDMAEN
        stz $7511
@fbe7:  longa
        lda #$0001
        clc
        adc $094a
        sta $094a
        lda $8e
        adc $094c
        sta $094c
        lda $0afb
        and #$00ff
        cmp #$0002
        bne @fc0f
        lda $0afc
        beq @fc0f
        dec
        sta $0afc
@fc0f:  shorta
        lda $7e750e
        sta f:hHDMAEN
        lda #$81
        sta f:hNMITIMEN
        lda $7e7525
        sta f:hINIDISP
        ply
        plx
        plp
        pla
        plp
        pld
        plb
; fallthrough

; ---------------------------------------------------------------------------

; [ menu irq ]

MenuIRQ:
_fc2e:  rti

; ---------------------------------------------------------------------------

; [  ]

_c2fc2f:
_fc2f:  phb
        shorta
        lda #$7e
        pha
        plb
        lda $7512
        beq @fc3e
        jsr _c2fd75
@fc3e:  lda $750f
        beq @fc53
        lda $751d
        bpl @fc53
        lda #$10
        sta $751d
        jsr _c2fcb1
        jsr _c2fad4
@fc53:  lda $7510
        beq @fc68
        lda $751f
        bpl @fc68
        lda #$01
        sta $751f
        jsr _c2fd09
        jsr _c2fad4
@fc68:  lda $7513
        beq @fc70
        jsr _c2fd2e
@fc70:  lda $43         ; menu state
        cmp #$01
        bne @fcaf
        lda $0afb
        cmp #$02
        beq @fc82
        ldy #$094a
        bra @fc92
@fc82:  longa
        lda $0afc
        sta $2d17
        stz $2d19
        ldy #$2d17
        shorta
@fc92:  php
        ldx #$6630
        jsr _c2d662
        longa
        ldx #near _c0f5c0
        ldy #$7514
        lda #$0008
        mvn #^_c0f5c0,#$7e
        shorta
        lda #$01
        sta $7511
        plp
@fcaf:  plb
        rts

_c2fcb1:
_fcb1:  lda $751e
        longa
        and #$0001
        asl
        tax
        ldy $8e
        shorta
        lda $750f
@fcc2:  lsr
        bcc @fcf3
        pha
        lda $0241,y
        clc
        adc f:_c0f21a,x
        sta $0241,y
        lda $0242,y
        clc
        adc f:_c0f21a+1,x
        sta $0242,y
        lda $0245,y
        clc
        adc f:_c0f21a,x
        sta $0245,y
        lda $0246,y
        clc
        adc f:_c0f21a+1,x
        sta $0246,y
        pla
@fcf3:  iny8
        cpy #$0020
        bne @fcc2
        lda $751e
        eor #$01
        sta $751e
        rts

_c2fd09:
_fd09:  shorta
        lda $7510
        longa
        and #$0007
        asl2
        sta $7520
        shorta
        ldx $8e
@fd1c:  lda $0206,x
        eor #$02
        sta $0206,x
        inx4
        cpx $7520
        bne @fd1c
        rts

_c2fd2e:
_fd2e:  shorta
        lda $7522
        bne @fd54
        lda $7513
        longa
        and #$0007
        dec
        asl2
        tax
        lda f:_c0f21e,x
        sta $7523
        lda f:_c0f21e+2,x
        sta $7525
        shorta
        inc $7522
@fd54:  lda $7523
        beq @fd68
        dec $7523
        lda $7524
        clc
        adc $7525
        sta $7525
        bra @fd74
@fd68:  lda $7526
        sta $7525
        stz $7522
        stz $7513
@fd74:  rts

_c2fd75:
_fd75:  shorta
        lda $7527
        cmp #$04
        beq @fd8c
        cmp #$03
        beq @fd90
        cmp #$02
        beq @fd94
        cmp #$01
        beq @fd90
        bra @fd9c
@fd8c:  lda #$00
        bra @fd99
@fd90:  lda #$02
        bra @fd99
@fd94:  jsr _c2fe41
        lda #$02
@fd99:  jsr _c2fdca
@fd9c:  shorta
        lda $7528
        beq @fdbd
        ldx $8e
@fda5:  lda $0205,x
        beq @fdb1
        clc
        adc $7528
        sta $0205,x
@fdb1:  inx4
        cpx #$0020
        bne @fda5
        jsr _c2fad4
@fdbd:  lda $7527
        dec
        sta $7527
        bne @fdc9
        stz $7512
@fdc9:  rts

_c2fdca:
        php
        longa
        clc
        adc $29a2
        and #$000f
        asl2
        tax
        ldy $29b4
        shorta
        lda a:$0000,y
        clc
        adc f:_c0f22e,x
        sta a:$0000,y
        iny3
@fdea:  shorta
        lda a:$0000,y
        beq @fe03
        iny
        longa
        lda a:$0000,y
        clc
        adc f:_c0f22e+2,x
        sta a:$0000,y
        iny2
        bra @fdea
@fe03:  plp
        rts

_c2fe05:
_fe05:  php
        longa
        ldx #$298e
        ldy #$7514
        lda #$0008
        mvn #$7e,#$7e
        shorta
        lda $7528
        beq @fe35
        ldx $8e
@fe1d:  lda $0205,x
        beq @fe29
        clc
        adc $7528
        sta $0205,x
@fe29:  inx4
        cpx #$0020
        bne @fe1d
        jsr _c2fad4
@fe35:  lda #$01
        sta $7511
        lda #$04
        sta $7527
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2fe41:
_fe41:  php
        longa
        ldx #$2997
        ldy #$7514
        lda #$0008
        mvn #$7e,#$7e
        shorta
        lda #$01
        sta $7511
        stz $ca
        plp
        rts

; ---------------------------------------------------------------------------

; [ update joypad input ]

_c2fe5b:
        php
        longa
        pha
        php
        phx
        phy
        phb
        phd
        shorta
        longi
        lda     #$00
        pha
        plb
        pea     $0100
        pld
        lda     #$01
@fe72:  bit     hHVBJOY
        bne     @fe72
        ldy     #$0000
        lda     $4d
        beq     @fe97
        lda     $0974
        and     #$80
        beq     @fe97       ; branch if single controller
        lda     $010d
        longa
        and     #$0003
        tax
        lda     $097c,x     ; character assigned to controller
        and     #$00ff
        beq     @fe97
        iny
@fe97:  longa
        sty     $12
        tya
        asl
        tax
        lda     hSTDCNTRL1L,x     ; joypad register
        sta     $06
        and     #$000f
        beq     @feaa
        stz     $06
@feaa:  lda     $14,x
        sta     $0e
        jsr     _c2fed0
        lda     $12
        asl
        tax
        lda     $0e
        sta     $14,x
        pld                 ; pull previous direct page
        lda     $010a
        sta     $00
        lda     $0108
        sta     $02
        lda     $0106
        sta     $04
        plb
        ply
        plx
        plp
        pla
        plp
        rts

; ---------------------------------------------------------------------------

; [  ]

_c2fed0:
@fed0:  .a16
        lda     $0974
        and     #$0040
        bne     @fede       ; branch if custom button config
        lda     $06
        sta     $08
        bra     @fefb
@fede:  lda     $06
        and     #$1f0f
        sta     $08
        ldx     #$0000
@fee8:  lda     $06
        and     f:_c0e7b8,x
        beq     @fef4
        lda     $26,x
        tsb     $08
@fef4:  inx2
        cpx     #$000e
        bne     @fee8
@fefb:  lda     $0e
        eor     #$ffff
        and     $08
        sta     $0a
        lda     $08
        and     $0e
        shorta
        bit     $010c
        longa
        bmi     @ff14
        and     #$7f7f
@ff14:  sta     $10
        lda     $08
        sta     $0e
        ldx     #$0000
        ldy     $12
@ff1f:  longa
        lda     f:_c0e7c6,x
        bit     $0a
        bne     @ff43       ; branch if already in repeat mode
        and     $10
        beq     @ff45
        shorta
        lda     $011a,y     ; decrement delay counter
        dec
        beq     @ff37
        bpl     @ff45
@ff37:  longa
        lda     f:_c0e7c6,x
        tsb     $0a         ; set repeat mode
        lda     $19
        bra     @ff45
@ff43:  lda     $18
@ff45:  shorta
        sta     $011a,y
        iny2                ; next button
        inx2
        cpx     #$000c
        bne     @ff1f
        longa
        rts
        .a8

; ---------------------------------------------------------------------------

; [ set controller settings (battle) ]

_c2ff56:
        php
        longa
        pha
        lda     #$0310      ; delay = 16 frames, rate = 3 frames
        sta     f:$000118     ; repeat settings
        sta     f:$00014d     ; allow multipler controllers
        pla
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

; [ set controller settings (field) ]

_c2ff68:
        php
        longa
        pha
        lda     #$0416      ; delay = 22 frames, rate = 4 frames
        sta     f:$000118     ; repeat settings
        lda     #$0000
        sta     f:$00014d     ; single controller
        pla
        plp
        rts
        .a8

; ---------------------------------------------------------------------------

; [ update joypad config ]

_c2ff7d:
        phb
        phd
        pha
        phx
        phy
        php
        pea     a:$0000
        plb
        plb
        longai
        pea     $0100
        pld
        lda     #$0416      ; delay = 22 frames, rate = 4 frames
        sta     $18
        stz     $4d         ; single controller
        ldy     #$0000
        tyx
@ff99:  lda     $0975,y     ; joypad config
        jsr     _c2ffc2
        sta     $26,x
        iny
        inx2
        cpy     #$0007
        bne     @ff99
        stz     $0e
        stz     $14
        stz     $16
        lda     #$0101
        ldx     #$000c
@ffb5:  dex2
        sta     $1a,x
        bne     @ffb5
        plp
        ply
        plx
        pla
        pld
        plb
        rts
        .a8

; ---------------------------------------------------------------------------

; [  ]

_c2ffc2:
@ffc2:  .a16
        phx
        and     #$00fc
        xba
        ldx     #$0000
@ffca:  asl
        bcs     @ffd7
        inx2
        cpx     #$000c
        bne     @ffca
        ldx     #$0000
@ffd7:  lda     f:_c0e7b8,x
        plx
        rts

; ---------------------------------------------------------------------------

.segment "menu_vectors"

_c2ffea:
        .addr   _c2c25f,_c2c261,_c2c2a4,_c2c2e8,_c2c32d,_c2c26d,_c2c2cc

_c2fff8:
        .addr   _c2f932,_c2f949,_c2f984,_c2f9d6

; ---------------------------------------------------------------------------

.segment "key_item_name"

; c0/e500: key item names
.if LANG_EN
        .res    256,$ff
.else
KeyItemName:
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $2a,$a6,$64,$9b,$89,$45,$b7,$ff  ; "ガラフのうでわ" (galuf's bracelet)
        .byte   $6b,$7f,$9f,$9b,$65,$6f,$af,$ff  ; "かたみのふくろ"
        .byte   $77,$af,$9b,$6a,$2c,$ff,$ff,$ff  ; "しろのカギ" (white key)
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $4f,$b8,$3e,$b8,$86,$ff,$ff,$ff
        .byte   $4f,$b8,$3e,$b8,$86,$ff,$ff,$ff
        .byte   $89,$b9,$2b,$9b,$6b,$2d,$ff,$ff
        .byte   $63,$a9,$c1,$89,$7d,$89,$ff,$ff
        .byte   $79,$39,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $8a,$3e,$9c,$b8,$7e,$8c,$86,$ff
        .byte   $a4,$c5,$2e,$a8,$9b,$71,$ff,$00
        .byte   $63,$7d,$63,$7d,$89,$ff,$ff,$ff
        .byte   $81,$c3,$89,$af,$89,$9b,$8f,$3f
        .byte   $65,$89,$8d,$b9,$9b,$77,$c3,$ff
        .byte   $7b,$6d,$21,$b9,$54,$ff,$ff,$ff
        .byte   $7b,$6d,$21,$b9,$55,$ff,$ff,$ff
        .byte   $7b,$6d,$21,$b9,$56,$ff,$ff,$ff
        .byte   $7b,$6d,$21,$b9,$57,$ff,$ff,$ff
        .byte   $7b,$6b,$8d,$81,$39,$ff,$ff,$ff
        .byte   $87,$31,$ff,$ff,$ff,$ff,$ff,$ff
.endif

; ---------------------------------------------------------------------------

.segment "menu_data"

; c0/e600
_c0e600:
        .addr   _c2a033,_c2a03b,_c2a03f,_c2a043,_c2a053,_c2a069,_c2a062

; c0/e60e
_c0e60e:
        .addr   _c2cfdc,_c2ceec,_c2cccb,_c2ca37,_c2c8a0,_c2c803,_c2c6f7,_c2c5c8
        .addr   _c2c34a,_c2c36f,_c2c5b9,_c2c56b,_c2c442

; c0/e628
_c0e628:
        .addr   _c2a4f0,_c2a36a,_c2a378,_c2a45e,_c2a466,_c2a46e,_c2a476,_c2a358,_c2a441

; c0/e63a
_c0e63a:
        .byte   $80
        .addr   _c2a519
        .byte   $82
        .addr   _c2a5b5
        .byte   $83
        .addr   _c2a5e6
        .byte   $85
        .addr   _c2a618
        .byte   $86
        .addr   _c2a6b9
        .byte   $87
        .addr   _c2a6fc
        .byte   $89
        .addr   _c2a79c
        .byte   $00
        .addr   $0000

; c0/e652
_c0e652:
        .byte   $01
        .addr   _c2a7fc
        .byte   $02
        .addr   _c2a826
        .byte   $03
        .addr   _c2a8fa
        .byte   $04
        .addr   _c2a925
        .byte   $05
        .addr   _c2a958
        .byte   $06
        .addr   _c2a96c
        .byte   $08
        .addr   _c2a9fd
        .byte   $09
        .addr   _c2aa35
        .byte   $0b
        .addr   _c2aabb
        .byte   $0c
        .addr   _c2aae9
        .byte   $0d
        .addr   _c2ab91
        .byte   $0e
        .addr   _c2abc1
        .byte   $0f
        .addr   _c2abdf
        .byte   $10
        .addr   _c2ac01
        .byte   $12
        .addr   _c2acc3
        .byte   $13
        .addr   _c2acff
        .byte   $14
        .addr   _c2adb0
        .byte   $15
        .addr   _c2acff
        .byte   $16
        .addr   _c2addf
        .byte   $19
        .addr   _c2ae47
        .byte   $1a
        .addr   _c2ae5c
        .byte   $1c
        .addr   _c2ae6f
        .byte   $1d
        .addr   _c2af1b
        .byte   $1e
        .addr   _c2b04f
        .byte   $1f
        .addr   _c2b079
        .byte   $20
        .addr   _c2b0d6
        .byte   $21
        .addr   _c2b106
        .byte   $22
        .addr   _c2b19a
        .byte   $23
        .addr   _c2b1ca
        .byte   $24
        .addr   _c2b1ec
        .byte   $00
        .addr   0

; c0/e6af
_c0e6af:
        .byte   $01,$1d,$a8,$02,$d3,$a8,$03,$1c,$a9,$04,$48,$a9,$08,$12,$aa,$09
        .byte   $4e,$aa,$0c,$19,$ab,$0d,$b2,$ab,$0e,$d1,$ab,$12,$d6,$ac,$13,$3e
        .byte   $ad,$14,$cc,$ad,$15,$3e,$ad,$16,$11,$ae,$1a,$6b,$ae,$1d,$87,$af
        .byte   $1e,$63,$b0,$24,$57,$b2,$00,$00,$00

; c0/e6e8
_c0e6e8:
        .byte   $02,$c1,$a8,$03,$18,$a9,$04,$35,$a9,$05,$65,$a9,$06,$6f,$a9,$09
        .byte   $6e,$aa,$0b,$d1,$aa,$0c,$20,$ab,$0e,$db,$ab,$0f,$f2,$ab,$10,$1e
        .byte   $ac,$13,$5b,$ad,$14,$5b,$ad,$16,$90,$ac,$17,$31,$ae,$19,$4b,$ae
        .byte   $1d,$b2,$af,$1e,$b2,$af,$21,$6e,$b1,$00,$00,$00

; c0/e724
_c0e724:
        .addr   _c2b25b,_c2b25b,_c2b25e,_c2b2fb,_c2b302,_c2b40c,_c2b429,_c2b480
        .addr   _c2b48f,_c2b4a8,_c2b4d7,_c2b511,_c2b521,_c2b5ea,_c2b6b9,_c2b74b
        .addr   _c2b752,_c2b796,_c2b7ad,_c2b7fc,_c2b811,_c2b845,_c2b84d,_c2b879
        .addr   _c2b8ae,_c2b91d,_c2b955,_c2b993,_c2b998,_c2ba05,_c2ba0a,_c2ba63
        .addr   _c2ba7d,_c2bbfa,_c2bc27,_c2bc2a,_c2bc2d,_c2bc48,_c2bc5e,_c2bcd9
        .addr   _c2bcd9,_c2bcd9,_c2bcd9,_c2bcd9,_c2bce0,_c2bd3d,_c2bd47,_c2bdb5
        .addr   _c2bdc6,_c2bdf3,_c2bdf6,_c2be2e,_c2be64,_c2bec8,_c2becd,_c2bef4
        .addr   _c2bf2e,_c2bf89,_c2bf9d,_c2bfcd,_c2bfd4,_c2bff4,_c2c003,_c2c041
        .addr   _c2c046,_c2c05e,_c2c069,_c2c06c,_c2c071,_c2c0bd,_c2c0f7,_c2c146
        .addr   _c2c162,_c2c162

_c0e7b8:
        .word   $0080,$8000,$0040,$4000,$0020,$0010,$2000

_c0e7c6:
        .word   $0080,$8000,$0800,$0400,$0200,$0100

; ---------------------------------------------------------------------------

; c0/e7d2
_c0e7d2:
        .byte   $80,$00,$01
        .byte   $00,$80,$02
        .byte   $00,$08,$03
        .byte   $00,$04,$04
        .byte   $00,$02,$05
        .byte   $00,$01,$06
        .byte   $00,$00,$00

; c0/e7e7
_c0e7e7:
        .addr   LoadMenuTilemap,LoadMenuTilemap,LoadMenuTilemap,LoadMenuTilemap
        .addr   _c2c1f7,_c2c1f7,_c2c1f7,_c2c1f7
        .addr   _c2c1a6,_c2c1a6,_c2c1a6,_c2c1a6

; c0/e7ff
_c0e7ff:
        .addr   _c2d533,_c2d54a,_c2d554,_c2d55d,_c2d571,_c2d93f,_c2d588,_c2d59d
        .addr   _c2d5d3,_c2d5ef,_c2d60b

; c0/e815
_c0e815:
        .addr   _c2dcd2,_c2dcfe,_c2dd0f,_c2dcd2,_c2dd20,_c2dd5a,_c2dd6b,_c2dd8e
        .addr   _c2dda8,_c2ddb5,_c2ddc6

; c0/e82b
_c0e82b:
        .addr   _c2dcd2,_c2dcd2,_c2db66,_c2db92,_c2dd20,_c2dbbd,_c2dbce,_c2dcfe
        .addr   _c2dbe8,_c2dbf9,_c2dc0a

; c0/e841: pointers to menu tutorial scripts
_c0e841:
        .addr   _c0e861,$01c0
        .addr   _c0e873,$02c0
        .addr   _c0e884,$00c0
        .addr   _c0e891,$01c0
        .addr   _c0e8a2,$00c0
        .addr   _c0e8bb,$00c0
        .addr   _c0e8ce,$00c0
        .addr   _c0e8dd,$00c0

; c0/e861: menu tutorial scripts
_c0e861:
        .byte   $11,$03,$03,$11,$01,$11,$01,$11,$06,$06,$06,$06,$11,$01,$11,$01,$12,$08
_c0e873:
        .byte   $11,$03,$11,$01,$11,$01,$11,$01,$11,$06,$11,$01,$11,$04,$01,$12,$08
_c0e884:
        .byte   $11,$04,$04,$11,$01,$11,$01,$11,$06,$11,$01,$12,$08
_c0e891:
        .byte   $11,$03,$03,$11,$01,$11,$01,$11,$06,$06,$06,$11,$01,$11,$01,$11,$08
_c0e8a2:
        .byte   $11,$03,$03,$11,$01,$11,$01,$11,$01,$11,$01,$11,$01,$04,$06,$11,$01,$11,$04,$11,$01,$11,$02,$12,$08
_c0e8bb:
        .byte   $11,$05,$11,$04,$04,$03,$03,$11,$01,$11,$01,$11,$01,$11,$01,$11,$06,$12,$08
_c0e8ce:
        .byte   $11,$05,$11,$01,$04,$04,$03,$11,$01,$11,$01,$03,$01,$11,$06
_c0e8dd:
        .byte   $12,$08

; c0/e8df: known abilities for tutorial
_c0e8df:
        .byte   $01,$00,$00,$80,$00,$00,$00,$80,$80,$00,$00,$00,$00,$00,$00,$08,$08

; c0/e8f0
_c0e8f0:
        .byte   $15,$0a,$0a,$0a,$09,$15,$15,$15

; c0/e8f8
_c0e8f8:
        .byte   $0e,$83,$8b,$9c,$03,$31,$89,$a7,$00

; c0/e901
_c0e901:
        .word   $4306,$431a,$432c,$4386,$439a,$43ac,$4406,$441a
        .word   $442c,$4486,$449a,$44ac,$4506,$451a,$452c,$4586
        .word   $459a,$45ac,$4606,$461a,$462c

; c0/e92b
_c0e92b:
        .byte   $18,$18,$18,$18,$00,$00

; c0/e931: spell list for battle $2c-$48 (spellblade-summon)
_c0e931:
        .byte   $01,$02,$03,$04,$05,$06,$11,$12,$13,$14,$15,$16,$21,$22,$23,$24
        .byte   $25,$26,$31,$32,$33,$34,$35,$36,$41,$42,$43,$44,$45

; c0/e94e
_c0e94e:
        .byte   $c4,$51,$1c,$00,$38,$00

; c0/e954
_c0e954:
        .byte   $c4,$44,$17,$00,$45,$00

; c0/e95a
_c0e95a:
        .byte   $44,$66,$1c,$00,$38,$00

; c0/e960
_c0e960:
        .byte   $04,$57,$1c,$00,$54,$00

; c0/e966
_c0e966:
        .addr   _c0e974,_c0e974,_c0e974,_c0e974,_c0e974,_c0e974,_c0e9b6

; c0/e974
_c0e974:
        .word   $6388,$639a,$63ac,$6408,$641a,$642c,$6488,$649a
        .word   $64ac,$6508,$651a,$652c,$6588,$659a,$65ac,$6608
        .word   $661a,$662c,$6688,$669a,$66ac,$6708,$671a,$672c
        .word   $6788,$679a,$67ac,$6808,$681a,$682c,$6888,$689a
        .word   $68ac

; c0/e9b6
_c0e9b6:
        .word   $638a,$63a6,$640a,$6426,$648a,$64a6,$650a,$6526

; c0/e9c6
_c0e9c6:
        .word   $52fc,$55fc,$545c,$585c,$537c,$573c,$52fc,$57fc

; c0/e9d6
_c0e9d6:
        .byte   $05,$00,$e0,$80,$e0,$00,$05,$00,$e0,$00,$e0,$80

; c0/e9e2
_c0e9e2:
        .byte   $00,$02,$08,$0C,$00,$04,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00
        .byte   $04

; c0/e9f3
_c0e9f3:
        .byte   $00,$59,$5a,$5a,$00,$60,$00,$5e,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

; c0/ea04
_c0ea04:
        .addr   _c3b807,0
        .byte   $03,$00,$82,$00,$82,$01

; c0/ea0e
_c0ea0e:
        .byte   $42,$41,$42,$43,$42,$45,$42,$47

; c0/ea16
_c0ea16:
        .word   $00a0,$0116,$012a,$01a0

; c0/ea1e
_c0ea1e:
        .byte   $44,$24,$40,$20
        .byte   $44,$2c,$50,$20
        .byte   $44,$50,$70,$22
        .byte   $44,$58,$80,$22
        .byte   $44,$7c,$a0,$24
        .byte   $44,$84,$b0,$24
        .byte   $44,$a8,$d0,$26
        .byte   $44,$b0,$e0,$26

; c0/ea3e
_c0ea3e:
        .addr   _c3b016,_c3b01d,_c3b024

; c0/ea44
_c0ea44:
        .word   $5184,$5204

; c0/ea48
_c0ea48:
        .word   $0502,$0552,$05a2,$05f2

; c0/ea50: pointers to character names (RAM)
_c0ea50:
        .word   $0990,$0996,$099c,$09a2,$09a8,$09ae

; c0/ea5c
_c0ea5c:
        .word   $5084,$5244,$5404,$55c4

; c0/ea64
_c0ea64:
        .word   $0000,$0050,$00a0,$00f0

; c0/ea6c
_c0ea6c:
.if LANG_EN
        .byte   $6c,$60,$72,$73,$64,$71,$c9,$00
.else
        .byte   $db,$d3,$dd,$df,$d9,$d8,$c9,$00
.endif

; c0/ea74: "Ｌざ　　ー　　　／　　　"
_c0ea74:
.if LANG_EN
        .byte   $6b,$75,$ff,$ff,$c5,$ff,$ff,$ff,$ce,$ff,$ff,$ff,$00
.else
        .byte   $d7,$35,$ff,$ff,$c5,$ff,$ff,$ff,$ce,$ff,$ff,$ff,$00
.endif

; c0/ea81: blank text for ??
_c0ea81:
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00

; c0/ea8e
_c0ea8e:
        .word   $42c8,$4348,$43c8,$4448

; c0/ea96
_c0ea96:
        .byte   $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
        .byte   $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
        .byte   $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
        .byte   $ff,$00

; c0/eac8
_c0eac8:
        .word   $0004,$0804,$0800,$0808,$0804,$0804,$1004,$1004

; c0/ead8
_c0ead8:
        .byte   $40,$50,$42,$52,$44,$54,$46,$47,$70,$80,$72,$82,$74,$84,$76,$77
        .byte   $a0,$b0,$a2,$b2,$a4,$b4,$a6,$a7,$d0,$e0,$d2,$e2,$d4,$e4,$d6,$d7
        .byte   $08,$08,$0a,$0a,$0c,$0c,$0e,$0e,$28,$28,$2a,$2a,$2c,$2c,$2e,$2e

; c0/eb08
_c0eb08:
        .word   $0240,$0248,$0250,$0258

; c0/eb10
_c0eb10:
        .word   $0002,$002e,$005a,$0086,$00b2,$0000

; c0/eb1c
_c0eb1c:
        .byte   $01,$05,$fe,$05,$fe,$05,$ff,$07,$02,$07,$01,$07,$fe,$06,$00,$08
        .byte   $02,$08,$fe,$06,$00,$07,$01,$08,$ff,$05,$00,$07,$fe,$06,$02,$07
        .byte   $fe,$06,$00,$06,$02,$08,$fe,$06,$fe,$06,$fe,$06,$fe,$06,$fe,$06
        .byte   $fe,$06,$fe,$07,$fe,$07,$fe,$06,$fe,$06,$ff,$07,$01,$07,$fe,$07
        .byte   $00,$07,$00,$09,$fe,$05,$fe,$06,$fe,$07,$fe,$06,$ff,$07,$fe,$06
        .byte   $fe,$07,$fe,$06,$fe,$06,$ff,$07,$ff,$07,$fe,$06,$fe,$06,$fd,$04
        .byte   $fe,$06,$02,$07,$fd,$05,$fe,$06,$fe,$06,$fe,$06,$fe,$05,$01,$08
        .byte   $fe,$05,$fe,$06,$fe,$06,$fe,$06,$fd,$06,$fe,$06,$ff,$06,$fd,$05
        .byte   $fd,$05,$00,$00,$fd,$05,$fe,$06,$fe,$06,$00,$07,$fe,$06,$ff,$06
        .byte   $fe,$07,$ff,$07,$ff,$07,$ff,$07,$ff,$07,$00,$08,$ff,$07,$fe,$06
        .byte   $fe,$06,$fe,$06,$fe,$06,$fe,$06,$00,$07,$00,$07,$00,$07,$00,$07
        .byte   $00,$07,$ff,$0a,$ff,$0a,$fd,$09,$ff,$09,$ff,$09,$ff,$09,$00,$09
        .byte   $ff,$0a,$ff,$0a,$00,$09,$ff,$09,$ff,$09,$ff,$09,$ff,$0a,$00,$0a
        .byte   $ff,$09,$ff,$09,$00,$09,$ff,$09,$ff,$0a,$ff,$0a,$ff,$0a

; c0/ebfa
_c0ebfa:
        .byte   $08,$50,$98

; c0/ebfd
_c0ebfd:
        .byte   $56,$62,$6e,$7a,$86,$92,$9e,$aa,$b6,$c2

; c0/ec07
_c0ec07:
        .byte   $40,$50,$60,$70,$80,$98,$a8,$b8,$c8,$d8

; c0/ec11
_c0ec11:
        .byte   $2e,$3e,$4e,$5e,$6e,$7e,$8e,$9e,$ae,$be

; c0/ec1b
_c0ec1b:
        .word   $9800,$9e00,$a400,$aa00

; ---------------------------------------------------------------------------

.import BattleCharGfx_0, DeadCharGfx_0
.import BattleCharGfx_1, DeadCharGfx_1
.import BattleCharGfx_2, DeadCharGfx_2
.import BattleCharGfx_3, DeadCharGfx_3
.import BattleCharGfx_4, DeadCharGfx_4

; c0/ec23: pointers to battle character graphics
BattleCharGfxPtrs:
        .dword  BattleCharGfx_0
        .dword  BattleCharGfx_1
        .dword  BattleCharGfx_2
        .dword  BattleCharGfx_3
        .dword  BattleCharGfx_4

; ---------------------------------------------------------------------------

; c0/ec37
_c0ec37:
        .word   $0000,$0000,$0020,$0020,$0040,$0200,$0060,$0220
        .word   $0080,$0400,$00a0,$0420,$03c0,$0040,$03e0,$0060
        .word   $0400,$0240,$0420,$0260,$0440,$0440,$0460,$0460
        .word   $01c0,$0080,$01e0,$00a0,$0200,$0280,$0220,$02a0
        .word   $0240,$0480,$0260,$04a0,$0480,$0140,$04a0,$0160
        .word   $04c0,$0340,$04e0,$0360,$0500,$0540,$0520,$0560

; ---------------------------------------------------------------------------

; c0/ec97: pointers to dead character graphics
DeadCharGfxPtrs:
        .dword  DeadCharGfx_0
        .dword  DeadCharGfx_1
        .dword  DeadCharGfx_2
        .dword  DeadCharGfx_3
        .dword  DeadCharGfx_4

; ---------------------------------------------------------------------------

; c0/ecab
_c0ecab:
        .word   $0000,$00c0,$0020,$00e0,$0040,$0100
        .word   $0060,$02c0,$0080,$02e0,$00a0,$0300

; ---------------------------------------------------------------------------

; c0/ecc3
_c0ecc3:
        .dword  $d497c0
        .word   $9100
        .addr   _c0ecf9
        .word   14

        .dword  $d49b50
        .word   $9500
        .addr   _c0ecf9
        .word   14

        .dword  $d49f40
        .word   $9000
        .addr   _c0ece1
        .word   6


; c0/ece1
_c0ece1:
        .byte   $00,$00,$40,$00
        .byte   $18,$00,$60,$00
        .byte   $80,$01,$40,$02
        .byte   $98,$01,$60,$02
        .byte   $f0,$00,$00,$04
        .byte   $08,$01,$20,$04

; c0/ecf9
_c0ecf9:
        .byte   $00,$00,$00,$00
        .byte   $18,$00,$20,$00
        .byte   $30,$00,$00,$02
        .byte   $48,$00,$20,$02
        .byte   $e0,$01,$40,$00
        .byte   $f8,$01,$60,$00
        .byte   $10,$02,$40,$02
        .byte   $28,$02,$60,$02
        .byte   $20,$01,$80,$00
        .byte   $38,$01,$a0,$00
        .byte   $50,$01,$80,$02
        .byte   $68,$01,$a0,$02
        .byte   $a0,$02,$c0,$00
        .byte   $b8,$02,$e0,$00

; ---------------------------------------------------------------------------

; c0/ed31
_c0ed31:
        .byte   $00,$00,$00,$00
        .byte   $20,$00,$20,$00
        .byte   $40,$00,$00,$02
        .byte   $60,$00,$20,$02
        .byte   $80,$00,$00,$04
        .byte   $a0,$00,$20,$04

        .byte   $c0,$03,$40,$00
        .byte   $e0,$03,$60,$00
        .byte   $00,$04,$40,$02
        .byte   $20,$04,$60,$02
        .byte   $40,$04,$40,$04
        .byte   $60,$04,$60,$04

; c0/ed61: ability menu to use for each job
_c0ed61:
        .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2

; c0/ed77
_c0ed77:
        .byte   2,0
        .addr   _c0ed83
        .byte   0,1
        .addr   _c0ed8b
        .byte   1,2
        .addr   _c0ed87

; c0/ed83
_c0ed83:
        .byte   1,1,0,0
_c0ed87:
        .byte   1,0,0,0
_c0ed8b:
        .byte   0,0,0,0

; c0/ed8f
_c0ed8f:
        .word   $62c6,$62e2,$6346,$6362,$63c6,$63e2,$6446,$6462
        .word   $64c6,$64e2,$6546,$6562,$65c6,$65e2,$6646,$6662
        .word   $66c6,$66e2,$6746,$6762,$67c6,$67e2,$6846,$6862

; c0/edbf
_c0edbf:
        .word   $0528,$0529,$052a,$052b,$0544,$052d,$052c,$052f,$0523

; c0/edd1
_c0edd1:
        .word   $5470,$54f0,$5570,$55f0,$566e,$56ee,$5770,$57ee,$5870

; c0/ede3
_c0ede3:
        .word   $5478,$54f8,$5578,$55f8,$5676,$56f6,$5776,$57f6,$5878

; c0/edf5
_c0edf5:
        .byte   $ff,$00,$ff,$00,$ff,$00,$c5,$00,$c5,$00,$c5,$00,$c5,$00

; c0/ee03
_c0ee03:
        .word   $274a,$2746,$2703

; c0/ee09
_c0ee09:
        .word   $2728,$2729,$272a,$272b,$2744,$272d,$272c,$272f,$2723

; c0/ee1b
_c0ee1b:
        .word   $7e31,$7e73,$7e73

; c0/ee21
_c0ee21:
        .word   $7e21,$7e21,$7e21,$7e21,$7e32,$7e31,$7e21,$7e31,$7e21

; c0/ee33
_c0ee33:
        .word   $55d8,$5510,$5450,$6438
        .word   $64b8,$6538,$65b8,$6636
        .word   $66b6,$6736,$67b6,$6838

; c0/ee4b
_c0ee4b:
        .word   $61e6,$6266,$62e6,$6366

; c0/ee53: dma data for vram transfer
_c0ee53:
        .word   $38c0  ; vram destination
        .byte   $01,$18,$80,$c1,$7e,$80,$06  ; copied to $4300-$4306

; c0/ee5c:
_c0ee5c:
        .byte   $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00

; c0/ee6a
_c0ee6a:
        .byte   $00,$02,$04,$06,$08,$0a,$0c,$0e
        .byte   $40,$42,$44,$46,$48,$4a,$4c,$4e
        .byte   $80,$82,$84,$86,$88,$8a,$8c,$8e

; c0/ee82: job sprite xy positions
_c0ee82:
        .byte   $24,$3e,$40,$3e,$5c,$3e,$78,$3e,$94,$3e,$b0,$3e,$cc,$3e
        .byte   $16,$62,$32,$62,$4e,$62,$6a,$62,$86,$62,$a2,$62,$be,$62,$da,$62
        .byte   $24,$86,$40,$86,$5c,$86,$78,$86,$94,$86,$b0,$86,$cc,$86

; c0/eeae: spells learned from items (ifrit, ramuh, shoat, golem)
_c0eeae:
        .byte   $4d,$4c,$50,$4f

; c0/eeb2: sound effects for spells learned from items
_c0eeb2:
        .byte   $76,$44,$47,$4b

; c0/eeb6: spc commands for spells learned from items
_c0eeb6:
        .byte   $02,$5b,$0f,$88

; c0/eeba
_c0eeba:
        .word   $1312,$1314,$1317,$1318,$1319,$131d,$131e,$1321
        .word   $1323,$1329,$133b,$0000

; c0/eed2
_c0eed2:
        .word   $13e0,$13e1,$13e2,$13e3,$13e4,$13e5,$13e6,$13e8
        .word   $13e9,$13ec,$13ed,$00f0,$00f1,$44f9,$47fa,$4bfb
        .word   $0000

; c0/eef4
_c0eef4:
        .byte   $12,$01,$03
        .byte   $14,$01,$03
        .byte   $17,$01,$06
        .byte   $18,$01,$09
        .byte   $19,$01,$09
        .byte   $1d,$01,$0c
        .byte   $1e,$01,$0f
        .byte   $21,$01,$12
        .byte   $23,$01,$12
        .byte   $29,$02,$06
        .byte   $3b,$03,$06
        .byte   $3e,$03,$09
        .byte   $ff

; c0/ef19
_c0ef19:
        .byte   $00,$06,$03,$12
        .byte   $12,$06,$03,$12
        .byte   $24,$06,$03,$12
        .byte   $36,$06,$03,$12
        .byte   $48,$05,$03,$0f
        .byte   $82,$1e,$01,$1e
        .byte   $57,$08,$01,$08

; c0/ef35
_c0ef35:
        .word   $0012,$0012,$0012,$0012,$000f,$001e,$0008

; c0/ef43
_c0ef43:
        .byte   $06,$d1,$06,$d1,$06,$d1,$06,$d1,$06,$d1,$08,$d1,$09,$d1,$13,$00

; c0/ef53
_c0ef53:
        .word   $0014,$0014,$0013

; c0/ef59:
_c0ef59:
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; c0/ef65: pointers to character job data (+$0843)
_c0ef65:
        .word   $0000,$002c,$0058,$0084

; c0/ef6d
_c0ef6d:
        .addr   _c3ad5d,_c3ad4a
        .byte   $db,$07,$40,$00
        .byte   $4e,$00,$88,$00,$90,$00,$96,$00
        .byte   $9a,$00,$16,$01,$58,$01,$4e,$00

; c0/ef85
_c0ef85:
        .byte   $00,$00,$00,$00,$eb,$07,$0c,$02
        .byte   $28,$02,$20,$02,$68,$02,$6a,$02
        .byte   $6e,$02,$52,$02,$94,$02,$28,$02

; c0/ef9d
_c0ef9d:
        .byte   $00,$00,$00,$00,$dd,$07,$04,$01
        .byte   $84,$01,$1a,$01,$c6,$01,$cc,$01
        .byte   $d0,$01,$4c,$03,$8e,$03,$d0,$02

; c0/efb5
_c0efb5:
        .word   $0000,$0000,$00ed,$00cc,$00da,$0152,$015a,$015c,$0160

; c0/efc7
_c0efc7:
        .word   $0000,$0000,$00ed,$00cc,$00da,$0152,$015a,$015c,$0160

; c0/efd9
_c0efd9:
        .word   $3000  ; vram destination
        .byte   $01,$18,$00,$b0,$7e,$00,$20

; c0/efe2
_c0efe2:
        .word   $7000  ; vram destination
        .byte   $01,$18,$00,$f0,$d1,$00,$10

; c0/efeb
_c0efeb:
        .word   $2000  ; vram destination
        .byte   $01,$18,$00,$90,$7e,$00,$20

; c0/eff4: copied to DMA0 registers ($4300-$4306)
_c0eff4:
        .byte   $02,$22,$00,$73,$7e,$00,$02

; c0/effb
_c0effb:
        .addr   _c0f003,_c0f017,_c0f02b,_c0f03f

_c0f003:
        .word   $0500,$0843,$08f3,$08f7,$0980,$9800,$9a00,$9c00,$7400,$097c
_c0f017:
        .word   $0550,$086f,$08f4,$090b,$0984,$9e00,$a000,$a200,$7420,$097d
_c0f02b:
        .word   $05a0,$089b,$08f5,$091f,$0988,$a400,$a600,$a800,$7440,$097e
_c0f03f:
        .word   $05f0,$08c7,$08f6,$0933,$098c,$aa00,$ac00,$ae00,$7460,$097f

; c0/f053
_c0f053:
        .word   $0050,$002c,$0001,$0014,$0004,$0180,$0180,$0180,$0020,$0001,$0000

; c0/f069
_c0f069:
        .byte   $00,$00,$00,$1b,$00,$00,$00,$00,$13,$0f,$00,$00,$00

; c0/f076
_c0f076:
        .byte   2,6,6,2,2,2,2,2,2,2,32,32,32,6,6,6
        .byte   6,6,6,6,2,2,2,2,3,3,3,3,3,3,3,3
        .byte   3,3,3,3,3,3,3,3,6,6,6,6,6,6,6

; c0/f0a5
_c0f0a5:
        .byte   $00,$00,$08,$00,$03,$80,$03,$04,$80,$03,$05,$02,$03,$06,$04,$03
        .byte   $07,$01,$04,$08,$40,$04,$09,$80

; c0/f0bd
_c0f0bd:
        .word   $56a4,$5724,$57a4

; c0/f0c3
_c0f0c3:
        .byte   $00,$02,$08,$0e,$10,$12,$14,$16,$18,$1a,$00,$00,$00,$24,$2a,$30
        .byte   $36,$3c,$42,$48,$1c,$1e,$20,$22,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$24,$2a,$30,$36,$3c,$42,$48

; c0/f0f2
_c0f0f2:
        .word   $519e,$51ac,$521e,$5222,$5226,$522a,$522e,$5232
        .word   $529e,$52a2,$52a6,$52aa,$52ae,$52b2,$531e,$532c
        .word   $539e,$53ac,$541e,$542c,$549e,$54ac,$551e,$552c
        .word   $559e,$55ac,$561e,$562c,$42d8,$42ea,$4358,$436a
        .word   $43d8,$43ea,$4458,$446a,$4208,$4210,$4218,$4220
        .word   $4228,$4230,$42c8,$42d0,$42d8,$42e0,$42e8,$42f0
        .word   $4388,$4390,$4398,$43a0,$43a8,$43b0,$4448,$4450
        .word   $4458,$4460,$4468,$4470,$4508,$4510,$4518,$4520
        .word   $4528,$4530,$45c8,$45d0,$45d8,$45e0,$45e8,$45f0
        .word   $4688,$4690,$4698,$46a0,$46a8,$46b0

; c0/f18e
_c0f18e:
.if LANG_EN
        .byte   $06,$01,$01,$06,$06,$06,$06,$06,$06,$06,$01,$01,$01,$04,$04,$04
        .byte   $04,$04,$04,$04,$08,$08,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$04,$04,$04,$04,$04,$04,$04
.else
        .byte   $05,$01,$01,$05,$02,$04,$03,$06,$04,$04,$01,$01,$01,$04,$04,$04
        .byte   $04,$04,$04,$04,$08,$08,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$04,$04,$04,$04,$04,$04,$04
.endif

; c0/f1bd
_c0f1bd:
.if LANG_EN
        .byte   $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$01,$01,$01,$18,$18,$18
        .byte   $18,$18,$18,$18,$11,$11,$11,$11,$01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$18,$18,$18,$18,$18,$18,$18
.else
        .byte   $0b,$0b,$0b,$0c,$09,$0b,$0a,$0d,$0b,$0a,$01,$01,$01,$18,$18,$18
        .byte   $18,$18,$18,$18,$11,$11,$11,$11,$01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$18,$18,$18,$18,$18,$18,$18
.endif

; c0/f1ec
_c0f1ec:
        .byte   $80,$00,$00,$00,$00,$00,$00,$00

; c0/f1f4
_c0f1f4:
        .word   $52c6,$5346,$53c6,$5446,$54c6,$5546,$55c6,$5646

; c0/f204
_c0f204:
        .byte   $01,$02,$04,$08

; c0/f208
_c0f208:
        .addr   _c3b287,_c3b2ed,_c3b2ba,_c3b2cb,_c3b2a9,_c3b298,_c3b2dc,_c3b31b,_c3b332

; c0/f21a
_c0f21a:
        .lobytes -1,2,1,-2

; c0/f21e
_c0f21e:
        .byte   $0f,$00,$0f,$0f
        .byte   $80,$00,$80,$80
        .byte   $02,$05,$00,$0f
        .byte   $02,$fb,$0f,$00

; c0/f22e
_c0f22e:
        .byte   $09,$00,$f7,$ff
        .byte   $f7,$ff,$09,$00
        .byte   $fd,$ff,$03,$00
        .byte   $03,$00,$fd,$ff

; c0/f23e
_c0f23e:
        .word   $7400,$7420,$7440,$7460

; ---------------------------------------------------------------------------

.import BattleCharPal
.import BattleCharPal_0
.import BattleCharPal_1
.import BattleCharPal_2
.import BattleCharPal_3
.import BattleCharPal_4

; c0/f246: pointers to battle character palettes (+$d40000)
BattleCharPalPtrs:
        .addr   BattleCharPal_0
        .addr   BattleCharPal_1
        .addr   BattleCharPal_2
        .addr   BattleCharPal_3
        .addr   BattleCharPal_4

; ---------------------------------------------------------------------------

; c0/f250
_c0f250:
        .addr   _c0f266,_c0f27c
        .byte   $03,$19,$01,$18,$06,$62,$7e,$80,$06,$7e,$11,$01
        .byte   $18,$fc,$52,$7e,$40,$05

; c0/f266
_c0f266:
        .byte   $02,$00,$00,$fd,$02,$00,$86,$62,$06,$62,$7f,$85,$14,$00,$15,$00
        .byte   $c6,$67,$e2,$67,$80,$71

; c0/f27c
_c0f27c:
        .byte   $fe,$ff,$01,$03,$02,$00,$f9,$67,$79,$68,$7f,$05,$00,$00,$01,$00
        .byte   $c6,$62,$e2,$62,$80,$71

; ---------------------------------------------------------------------------

; c0/f292
_c0f292:
        .addr   _c0f2a8,_c0f2be
        .byte   $ec,$18,$01,$18,$d8,$61,$7e,$80,$04,$21,$11,$01
        .byte   $18,$42,$52,$7e,$40,$03

; c0/f2a8
_c0f2a8:
        .byte   $02,$00,$00,$00,$00,$00,$5a,$62,$da,$61,$ff,$83,$0e,$00,$0f,$00
        .byte   $1a,$66,$2c,$66,$80,$71

; c0/f2be
_c0f2be:
        .byte   $fe,$ff,$01,$00,$00,$00,$bb,$65,$3b,$66,$ff,$03,$00,$00,$01,$00
        .byte   $9a,$62,$ac,$62,$80,$71

; ---------------------------------------------------------------------------

; c0/f2d4
_c0f2d4:
        .addr   _c0f2ea,_c0f300
        .byte   $82,$19,$01,$18,$04,$63,$7e,$80,$05,$22,$12,$01
        .byte   $18,$44,$54,$7e,$40,$04

; c0/f2ea
_c0f2ea:
        .byte   $01,$00,$00,$00,$01,$00,$84,$63,$04,$63,$ff,$84,$09,$00,$00,$00
        .byte   $44,$68,$00,$00,$80,$71

; c0/f300
_c0f300:
        .byte   $ff,$ff,$01,$00,$01,$00,$db,$67,$5b,$68,$ff,$04,$00,$00,$00,$00
        .byte   $c4,$63,$00,$00,$80,$71

; ---------------------------------------------------------------------------

; c0/f316
_c0f316:
        .addr   _c3ae6d,_c3b82f
        .addr   _c3ae98,_c3b83f
        .addr   _c3aeb0,_c3b83f

; c0/f322
_c0f322:
        .word   $0000,$53c6,$5586,$0000
        .word   $0000,$53c6,$5486,$5546
        .word   $0000,$5486,$5546,$0000

; c0/f33a: pointers to character abilities
_c0f33a:
        .word   $08f7,$090b,$091f,$0933

; c0/f342: default config settings
_c0f342:
        .byte   $2a,$00,$40,$00,$00,$80,$40,$20,$10,$08,$04,$04,$00,$00,$00,$00

; c0/f352
_c0f352:
        .byte   0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3

; c0/f362
_c0f362:
        .word   $42c8,$43c8,$44c8,$45c8

; c0/f36a
_c0f36a:
        .addr   $0000,_c3b523
        .byte   $0b,$07,$06,$00,$86,$00,$2c,$00,$5e,$00,$a0,$00
        .byte   $86,$00

; c0/f37c
_c0f37c:
        .word   $6008,$8008,$a008,$c008

; c0/f384:
_c0f384:
        .word   $5818,$5818,$7818,$7818,$9818,$9818,$b818,$b818

; c0/f394:
_c0f394:
        .word   $2414,$242c,$5414,$542c,$8414,$842c,$b414,$b42c

; c0/f3a4:
_c0f3a4:
        .byte   $07,$07,$07,$07,$07,$19,$1a

; c0/f3ab
_c0f3ab:
        .word   $ff00,$0100,$00ff,$0001

; c0/f3b3
_c0f3b3:
        .addr   _c3b4fd,_c3b4af,_c3b4bf,_c3b4cf,_c3b4d9,_c3b4e3,_c3b4f3

; c0/f3c1
_c0f3c1:
        .byte   $01,$ff,$0a,$f6

; c0/f3c5
_c0f3c5:
        .word   $4204,$4384,$4504,$4684

; c0/f3cd
_c0f3cd:
        .addr   _c0f3d5,_c0f3de,_c0f3e7,_c0f3f0

_c0f3d5:
        .byte   $00,$24,$01,$18,$00,$98,$7e,$00,$06
_c0f3de:
        .byte   $00,$27,$01,$18,$00,$9e,$7e,$00,$06
_c0f3e7:
        .byte   $00,$2a,$01,$18,$00,$a4,$7e,$00,$06
_c0f3f0:
        .byte   $00,$2d,$01,$18,$00,$aa,$7e,$00,$06

; c0/f3f9
_c0f3f9:
        .byte   $20,$08,$01,$18,$40,$40,$7e,$00,$09

; c0/f402
_c0f402:
        .byte   $20,$10,$01,$18,$40,$50,$7e,$00,$09

; c0/f40b
_c0f40b:
        .byte   $20,$18,$01,$18,$40,$60,$7e,$00,$09

; c0/f414: letters for name menu
_c0f414:
.if LANG_EN
        .byte   $60,$61,$62,$63,$64
        .byte   $7a,$7b,$7c,$7d,$7e
        .byte   $65,$66,$67,$68,$69
        .byte   $7f,$80,$81,$82,$83
        .byte   $6a,$6b,$6c,$6d,$6e
        .byte   $84,$85,$86,$87,$88
        .byte   $6f,$70,$71,$72,$73
        .byte   $89,$8a,$8b,$8c,$8d
        .byte   $74,$75,$76,$77,$78
        .byte   $8e,$8f,$90,$91,$92
        .byte   $79,$c5,$9e,$9f,$a3
        .byte   $93,$95,$94,$97,$98
        .byte   $9b,$9c,$9d,$99,$9a
        .byte   $a0,$a1,$a2,$d0,$d1
        .byte   $ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff
        .byte   $ff,$ff,$ff,$ff,$ff
.else
        .byte   $8a,$8c,$88,$8e,$90
        .byte   $34,$36,$38,$3a,$3c
        .byte   $6a,$6c,$6e,$70,$72
        .byte   $3e,$40,$42,$44,$46
        .byte   $74,$76,$78,$7a,$7c
        .byte   $20,$22,$24,$26,$28
        .byte   $7e,$80,$82,$84,$86
        .byte   $49,$4b,$4d,$4f,$51
        .byte   $92,$94,$96,$98,$9a
        .byte   $bc,$be,$c0,$c2,$ba
        .byte   $60,$62,$64,$66,$68
        .byte   $c4,$c6,$c8,$ca,$cc
        .byte   $9c,$9e,$a0,$a2,$a4
        .byte   $c5,$48,$c9,$cb,$c7
        .byte   $b0,$b2,$b4,$b6,$b8
        .byte   $53,$54,$55,$56,$57
        .byte   $a6,$a8,$aa,$ac,$ae
        .byte   $58,$59,$5a,$5b,$5c
        .byte   $2a,$2c,$2e,$30,$32
        .byte   $ce,$d0,$d1,$ff,$ff
.endif

; c0/f478:
_c0f478:
        .word   $629a,$62ac,$631a,$632c,$639a,$63ac,$641a,$642c
        .word   $649a,$64ac,$651a,$652c,$659a,$65ac,$661a,$662c

; ---------------------------------------------------------------------------

; c0/f498: "Ｌ　ー　　　／　　　"
_c0f498:
.if LANG_EN
        .byte   $6b,$ff,$c5,$ff,$ff,$ff,$ce,$ff,$ff,$ff,$00
.else
        .byte   $d7,$ff,$c5,$ff,$ff,$ff,$ce,$ff,$ff,$ff,$00
.endif

; c0/f4a3: blank text for ???
_c0f4a3:
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00

; ---------------------------------------------------------------------------

; c0/f4ae
_c0f4ae:
        .addr   _c0f4b4,_c0f4d4,_c0f4f4

; ---------------------------------------------------------------------------

; c0/f4b4
_c0f4b4:
        .byte   $e2,$48,$40,$00
        .byte   $e2,$50,$50,$00
        .byte   $e2,$64,$70,$02
        .byte   $e2,$6c,$80,$02
        .byte   $e2,$80,$a0,$04
        .byte   $e2,$88,$b0,$04
        .byte   $e2,$9c,$d0,$06
        .byte   $e2,$a4,$e0,$06

_c0f4d4:
        .byte   $e4,$46,$4a,$00
        .byte   $e4,$4e,$5a,$00
        .byte   $e4,$62,$7a,$02
        .byte   $e4,$6a,$8a,$02
        .byte   $e4,$7e,$aa,$04
        .byte   $e4,$86,$ba,$04
        .byte   $e4,$9a,$da,$06
        .byte   $e4,$a2,$ea,$06

_c0f4f4:
        .byte   $e2,$48,$44,$00
        .byte   $e2,$50,$54,$00
        .byte   $e2,$64,$74,$02
        .byte   $e2,$6c,$84,$02
        .byte   $e2,$80,$a4,$04
        .byte   $e2,$88,$b4,$04
        .byte   $e2,$9c,$d4,$06
        .byte   $e2,$a4,$e4,$06

; ---------------------------------------------------------------------------

; c0/f514: "うる" (sell)
_c0f514:
        .byte   $89,$ab,$00

; ---------------------------------------------------------------------------

; c0/f517: shop price multipliers
_c0f517:
        .dword  1
        .dword  10
        .dword  100
        .dword  1000
        .dword  10000
        .dword  100000
        .dword  1000000

; ---------------------------------------------------------------------------

; c0/f533: interrupt jump code
_c0f533:
        jml     MenuNMI
        jml     MenuIRQ

; ---------------------------------------------------------------------------

; c0/f53b
_c0f53b:
; copied to $2107-$210c
        .byte   $02,$0a,$12,$1a,$77,$77
; copied to $212c-$2131
        .byte   $00,$00,$00,$00,$00,$00

; c0/f547: hdma register values
_c0f547:
        .word   hDMA4
        .byte   $02,$0e,$00,$70,$7e
        .word   hDMA5
        .byte   $02,$10,$80,$70,$7e
        .word   hDMA6
        .byte   $02,$12,$00,$71,$7e
        .word   hDMA7
        .byte   $02,$14,$80,$71,$7e
        .word   hDMA2
        .byte   $01,$26,$00,$72,$7e
        .word   hDMA3
        .byte   $01,$28,$80,$72,$7e
        .word   0

; c0/f573:
_c0f573:
        .byte   $00,$00,$00,$00
        .byte   $00,$00,$00,$01
        .byte   $18,$00,$30,$7e
        .byte   $00,$10,$01,$00
        .byte   $01,$00,$00,$00
        .byte   $00,$00,$00,$00

; c0/f58b:
_c0f58b:
        .byte   $01,$18,$00,$30,$7e,$00,$40

; c0/f592: pause duration for tutorial scripts
_c0f592:
        .word   $0019,$0028,$0064,$00b4,$00f0,$012c,$0168,$01a4
        .word   $01e0,$021c,$0258,$0294,$02d0,$030c,$0348,$0384

; c0/f5b2
_c0f5b2:
        .byte   $02,$04,$00,$02,$00,$20,$02

; c0/f5b9
_c0f5b9:
        .byte   $02,$22,$00,$73,$7e,$00,$02

; c0/f5c0
_c0f5c0:
        .byte   $18,$1b,$01,$18,$30,$66,$7e,$0c,$00

; c0/f5c9
_c0f5c9:
        .word   $0004,$0002,$0001

; c0/f5cf: buffer addresses for menu tilemap data (bg 1-4)

; first row: tilemap buffers for each bg layer
; second row: v-scroll hdma tables for each bg layer (dma channel 4-7)
; third row:
;       window 1 position hdma table (dma channel 2)
;       window 2 position hdma table (dma channel 3)
;       cursor data
;       hardware values (see MenuNMI)

_c0f5cf:
        .word   $3000,$4000,$5000,$6000
        .word   $7000,$7080,$7100,$7180
        .word   $7200,$7280,$7600,$7500

; c0/f5e7
_c0f5e7:
        .addr   _c0f601,_c0f619,_c0f631,_c0f649,_c0f661,_c0f679,_c0f691,_c0f6a9
        .addr   _c0f6c1,_c0f6d9,_c0f6f1,_c0f709,_c0f721

; c0/f601
_c0f601:
        .addr   0,      0,      _c3ad3f,_c3ad65
        .addr   0,      0,      _c3b816,_c3b822
        .addr   _c3ac86,_c3ac98,_c3a300,_c3abba

_c0f619:
        .addr   0,      _c3ade3,_c3adf4,_c3ae5e
        .addr   0,      _c3b82c,_c3b82f,_c3b84f
        .addr   _c3acce,0,      _c3a382,_c3abcb

_c0f631:
        .addr   0,      0,      _c3aeea,_c3af0f
        .addr   0,      0,      _c3b85c,_c3b862
        .addr   0,      0,      _c3a434,_c3abdc

_c0f649:
        .addr   0,      _c3af3c,_c3af4d,_c3b02b
        .addr   0,      _c3b868,_c3b87a,_c3b88c
        .addr   _c3acda,0,      _c3a4ee,_c3abed

_c0f661:
        .addr   0,      0,      _c3b095,_c3b0d3
        .addr   0,      0,      _c3b89a,_c3b8a0
        .addr   _c3ace6,0,      _c3a598,_c3abfe

_c0f679:
        .addr   0,      _c3b19f,_c3b1eb,_c3b237
        .addr   0,      _c3b8b0,_c3b8bb,_c3b8d1
        .addr   _c3acf2,0,      _c3a5a2,_c3ac0f

_c0f691:
        .addr   0,      0,      _c3b363,_c3b3b7
        .addr   0,      0,      _c3b8c9,_c3b8d1
        .addr   _c3acf2,_c3ad01,_c3a73c,_c3ac20

_c0f6a9:
        .addr   0,      0,      _c3b3d6,_c3b3f3
        .addr   0,      0,      _c3b8e0,_c3b8e6
        .addr   0,      0,      _c3a856,_c3ac31

_c0f6c1:
        .addr   0,      0,      _c3b66e,0
        .addr   0,      0,      _c3b93e,0
        .addr   0,      0,      _c3aa38,_c3ac75

_c0f6d9:
        .addr   0,      0,      _c3b636,0
        .addr   0,      0,      _c3b919,0
        .addr   0,      0,      _c3aa26,_c3ac64

_c0f6f1:
        .addr   0,      _c3b536,_c3ad3f,0
        .addr   0,      _c3b8fd,_c3b816,_c3b905
        .addr   _c3ad1f,0,      _c3a978,_c3ac42

_c0f709:
        .addr   0,      _c3b56a,_c3ad3f,0
        .addr   0,      _c3b8fd,_c3b816,_c3b905
        .addr   _c3ad1f,0,      _c3a9aa,_c3ac42

_c0f721:
        .addr   0,      0,      _c3b5f5,_c3b620
        .addr   0,      0,      _c3b90f,0
        .addr   _c3ad10,0,      _c3a9e4,_c3ac53

; c0/f739:
_c0f739:
        .byte   $00,$00,$00,$00,$00,$00,$40,$00,$21,$61,$42,$82,$c2,$23,$43,$24
        .byte   $44,$84,$25,$45,$a5,$27,$47,$87,$cc,$2d,$8d,$2f,$4f,$8f,$00,$50
        .byte   $70,$90,$b0,$31,$00,$32,$00,$00,$72,$33,$53,$34,$48,$68,$88,$a8
        .byte   $c8,$e8,$29,$49,$69,$89,$a9,$c9,$2a,$4a,$6a,$8a,$aa,$ca,$2b,$4b
        .byte   $6b,$8b,$ab,$cb,$2c,$4c,$6c,$8c,$ac,$2e,$4e,$6e,$8e,$6d,$80,$a0
        .byte   $73,$c0,$63,$85,$46,$67,$6f,$52,$e2,$a1,$c1,$e1,$e9,$ea,$41,$60
        .byte   $a4,$30,$20,$81,$65,$4d,$28,$26,$a2,$64,$22,$71,$51,$eb,$62

; c0/f7a8: "なんでも" (anything)
_c0f7a8:
.if LANG_EN
        .byte   $60,$87,$92,$ff,$00
.else
        .byte   $93,$b9,$45,$a5,$00
.endif

; c0/f7ad
_c0f7ad:
        .byte   $03,$00,$00,$00,$e7
        .byte   $0c,$00,$00,$00,$e3
        .byte   $10,$00,$00,$00,$e8
        .byte   $60,$00,$00,$00,$e9
        .byte   $80,$00,$00,$00,$ea
        .byte   $00,$01,$00,$00,$eb
        .byte   $00,$06,$00,$00,$ec
        .byte   $00,$08,$00,$00,$ed
        .byte   $00,$10,$00,$00,$ee
        .byte   $00,$20,$00,$00,$ef
        .byte   $00,$40,$00,$00,$f0
        .byte   $00,$80,$00,$00,$00
        .byte   $00,$00,$01,$00,$f1
        .byte   $00,$00,$0e,$00,$f2
        .byte   $00,$00,$70,$00,$f3
        .byte   $00,$00,$80,$00,$00
        .byte   $00,$00,$00,$03,$f4
        .byte   $00,$00,$00,$04,$00

; c0/f807: grayscale battle character palette ???
_c0f807:
        .word   $0000,$1084,$7fff,$18c6,$6b5a,$4210,$318c,$2108
        .word   $5294,$294a,$6318,$7fff,$4210,$5294,$318c,$294a

; c0/f827: ??? color palettes
_c0f827:
        .word   $0000,$4000,$39ce,$7fff,$0000,$4000,$2108,$3def
        .word   $0000,$4000,$0280,$037f,$0000,$4000,$40ff,$2e7f
        .word   $0000,$4000,$39ce,$7fff,$0000,$4000,$39ce,$7fff
        .word   $0000,$4000,$39ce,$7fff,$0000,$4000,$39ce,$7fff

; c0/f867: ??? color palette
_c0f867:
        .word   $0000,$1084,$7fff,$0cec,$67df,$5255,$3dd1,$292e
        .word   $571a,$2d4e,$5af8,$4a77,$35b0,$4a77,$210c,$188a

; c0/f887: powers of two weirdly converted from decimal to hex
_c0f887:
        .dword  $00000001
        .dword  $00000002
        .dword  $00000004
        .dword  $00000008
        .dword  $00000016
        .dword  $00000032
        .dword  $00000064
        .dword  $00000128
        .dword  $00000256
        .dword  $00000512
        .dword  $00001024
        .dword  $00002048
        .dword  $00004096
        .dword  $00008192
        .dword  $00016384
        .dword  $00032768
        .dword  $00065536
        .dword  $00131072
        .dword  $00262144
        .dword  $00524288
        .dword  $01048576
        .dword  $02097152
        .dword  $04194304
        .dword  $08388608

; c0/f8e7
_c0f8e7:
        .word   $0000,$0700,$0e00,$1500

; c0/f8ef
_c0f8ef:
        .word   $6000,$6700,$6e00,$7500

; c0/f8f7
_c0f8f7:
        .word   $2c14,$2c34,$2c54,$2c74

; c0/f8ff
_c0f8ff:
        .word   $b000,$b100,$b800,$b900

; c0/f907: ??? sprite data
_c0f907:
        .byte   $48,$34,$00,$2d
        .byte   $48,$44,$20,$2d
        .byte   $60,$34,$02,$2d
        .byte   $60,$44,$22,$2d
        .byte   $78,$34,$04,$2d
        .byte   $78,$44,$24,$2d
        .byte   $90,$34,$06,$2d
        .byte   $90,$44,$26,$2d
        .byte   $48,$60,$08,$2d
        .byte   $48,$70,$28,$2d
        .byte   $60,$60,$0a,$2d
        .byte   $60,$70,$2a,$2d
        .byte   $78,$60,$0c,$2d
        .byte   $78,$70,$2c,$2d
        .byte   $90,$60,$0e,$2d
        .byte   $90,$70,$2e,$2d
        .byte   $48,$8c,$40,$2d
        .byte   $48,$9c,$60,$2d
        .byte   $60,$8c,$42,$2d
        .byte   $60,$9c,$62,$2d
        .byte   $78,$8c,$44,$2d
        .byte   $78,$9c,$64,$2d
        .byte   $90,$8c,$46,$2d
        .byte   $90,$9c,$66,$2d
        .byte   $48,$b8,$48,$2d
        .byte   $48,$c8,$68,$2d
        .byte   $60,$b8,$4a,$2d
        .byte   $60,$c8,$6a,$2d
        .byte   $78,$b8,$4c,$2d
        .byte   $78,$c8,$6c,$2d
        .byte   $90,$b8,$4e,$2d
        .byte   $90,$c8,$6e,$2d

; ---------------------------------------------------------------------------

        inc_lang "text/menu_text_%s.inc"

; c0/f987: pointers to menu text
MenuTextPtrs:
        ptr_tbl MenuText

.if LANG_EN
        .res 3
; c0/faa0: "Sell"
_c0faa0:
        .byte   $72,$7e,$98,$00
.else
; c0/fa9d: menu text
MenuText:
        .incbin "src/text/menu_text_jp.dat"
.endif

; ---------------------------------------------------------------------------

.segment "menu_tilemaps"

; [ cursor/input data ]

; 0: menu state
; 1: position index
; 2: x position
; 3: y position
; 4: up
; 5: down
; 6: left
; 7: right

; c3/a300: ??? cursor data
_c3a300:
        .word   $0080
        .byte   $01,$03,$b8,$12,$07,$01,$08,$00
        .byte   $01,$02,$b8,$22,$00,$02,$08,$01
        .byte   $01,$07,$b8,$3e,$01,$03,$08,$02
        .byte   $01,$08,$b8,$4e,$02,$04,$08,$03
        .byte   $01,$04,$b8,$5e,$03,$05,$08,$04
        .byte   $01,$05,$b8,$6e,$04,$06,$08,$05
        .byte   $01,$09,$b8,$7e,$05,$07,$08,$06
        .byte   $01,$0b,$b8,$8e,$06,$00,$08,$07
        .byte   $02,$01,$08,$27,$0b,$09,$08,$00
        .byte   $02,$02,$08,$57,$08,$0a,$09,$00
        .byte   $02,$03,$08,$87,$09,$0b,$0a,$00
        .byte   $02,$04,$08,$b7,$0a,$08,$0b,$00
        .byte   $03,$01,$08,$27,$0f,$0d,$0f,$0d
        .byte   $03,$02,$08,$57,$0c,$0e,$0c,$0e
        .byte   $03,$03,$08,$87,$0d,$0f,$0d,$0f
        .byte   $03,$04,$08,$b7,$0e,$0c,$0e,$0c

; c3/a382
_c3a382:
        .word   $00b0
        .byte   $04,$01,$08,$5a,$03,$01,$00,$00
        .byte   $04,$02,$08,$6e,$00,$02,$01,$01
        .byte   $04,$03,$08,$82,$01,$03,$02,$02
        .byte   $04,$04,$08,$a2,$02,$03,$03,$03
        .byte   $05,$01,$58,$44,$12,$06,$14,$05
        .byte   $05,$02,$a0,$44,$12,$07,$04,$06
        .byte   $05,$03,$58,$50,$04,$08,$05,$07
        .byte   $05,$04,$a0,$50,$05,$09,$06,$08
        .byte   $05,$05,$58,$5c,$06,$0a,$07,$09
        .byte   $05,$06,$a0,$5c,$07,$0b,$08,$0a
        .byte   $05,$07,$58,$68,$08,$0c,$09,$0b
        .byte   $05,$08,$a0,$68,$09,$0d,$0a,$0c
        .byte   $05,$09,$58,$74,$0a,$0e,$0b,$0d
        .byte   $05,$0a,$a0,$74,$0b,$0f,$0c,$0e
        .byte   $05,$0b,$58,$80,$0c,$10,$0d,$0f
        .byte   $05,$0c,$a0,$80,$0d,$11,$0e,$10
        .byte   $05,$0d,$58,$8c,$0e,$13,$0f,$11
        .byte   $05,$0e,$a0,$8c,$0f,$13,$10,$15
        .byte   $80,$02,$00,$00,$00,$00,$00,$00
        .byte   $80,$01,$00,$00,$00,$00,$00,$00
        .byte   $80,$04,$00,$00,$00,$00,$00,$00
        .byte   $80,$03,$00,$00,$00,$00,$00,$00

; c3/a434
_c3a434:
        .word   $00b8
        .byte   $06,$01,$14,$48,$0f,$07,$16,$01
        .byte   $06,$02,$30,$48,$10,$08,$00,$02
        .byte   $06,$03,$4c,$48,$11,$09,$01,$03
        .byte   $06,$04,$68,$48,$12,$0a,$02,$04
        .byte   $06,$05,$84,$48,$13,$0b,$03,$05
        .byte   $06,$06,$a0,$48,$14,$0c,$04,$06
        .byte   $06,$07,$bc,$48,$15,$0d,$05,$07
        .byte   $06,$08,$06,$6c,$00,$0f,$06,$08
        .byte   $06,$09,$22,$6c,$01,$10,$07,$09
        .byte   $06,$0a,$3e,$6c,$02,$11,$08,$0a
        .byte   $06,$0b,$5a,$6c,$03,$12,$09,$0b
        .byte   $06,$0c,$76,$6c,$04,$13,$0a,$0c
        .byte   $06,$0d,$92,$6c,$05,$14,$0b,$0d
        .byte   $06,$0e,$ae,$6c,$06,$15,$0c,$0e
        .byte   $06,$0f,$ca,$6c,$06,$15,$0d,$0f
        .byte   $06,$10,$14,$90,$07,$00,$0e,$10
        .byte   $06,$11,$30,$90,$08,$01,$0f,$11
        .byte   $06,$12,$4c,$90,$09,$02,$10,$12
        .byte   $06,$13,$68,$90,$0a,$03,$11,$13
        .byte   $06,$14,$84,$90,$0b,$04,$12,$14
        .byte   $06,$15,$a0,$90,$0c,$05,$13,$15
        .byte   $06,$16,$bc,$90,$0d,$06,$14,$00
        .byte   $82,$01,$00,$00,$00,$00,$00,$00

; c3/a4ee
_c3a4ee:
        .word   $00a8
        .byte   $07,$01,$38,$1f,$04,$01,$04,$01
        .byte   $07,$02,$38,$2b,$00,$02,$00,$02
        .byte   $07,$03,$38,$3b,$01,$03,$01,$03
        .byte   $07,$04,$38,$47,$02,$04,$02,$04
        .byte   $07,$05,$38,$53,$03,$00,$03,$00
        .byte   $08,$04,$08,$0f,$05,$05,$09,$06
        .byte   $08,$01,$30,$0f,$06,$06,$05,$07
        .byte   $08,$03,$68,$0f,$07,$07,$06,$08
        .byte   $08,$02,$90,$0f,$08,$08,$07,$09
        .byte   $08,$05,$c8,$0f,$09,$09,$08,$05
        .byte   $09,$01,$00,$67,$13,$0b,$13,$0b
        .byte   $09,$02,$00,$73,$0a,$0c,$0a,$0c
        .byte   $09,$03,$00,$7f,$0b,$0d,$0b,$0d
        .byte   $09,$04,$00,$8b,$0c,$0e,$0c,$0e
        .byte   $09,$05,$00,$97,$0d,$0f,$0d,$0f
        .byte   $09,$06,$00,$a3,$0e,$10,$0e,$10
        .byte   $09,$07,$00,$af,$0f,$11,$0f,$11
        .byte   $09,$08,$00,$bb,$10,$12,$10,$12
        .byte   $09,$09,$00,$c7,$11,$14,$11,$14
        .byte   $83,$02,$00,$00,$00,$00,$00,$00
        .byte   $83,$01,$00,$00,$00,$00,$00,$00

; c3/a598
_c3a598:
        .word   $0008
        .byte   $0a,$01,$ff,$df,$00,$00,$00,$00

; c3/a5a2
_c3a5a2:
        .word   $0198
        .byte   $0b,$01,$08,$30,$00,$00,$02,$01
        .byte   $0b,$02,$28,$30,$01,$01,$00,$02
        .byte   $0b,$03,$48,$30,$02,$02,$01,$00
        .byte   $0c,$01,$08,$4a,$0a,$04,$03,$03
        .byte   $0c,$02,$08,$56,$03,$05,$04,$04
        .byte   $0c,$03,$08,$62,$04,$06,$05,$05
        .byte   $0c,$04,$08,$6e,$05,$07,$06,$06
        .byte   $0c,$05,$08,$7a,$06,$08,$07,$07
        .byte   $0c,$06,$08,$86,$07,$09,$08,$08
        .byte   $0c,$07,$08,$92,$08,$0a,$09,$09
        .byte   $0c,$08,$08,$9e,$09,$03,$0a,$0a
        .byte   $0d,$01,$08,$4c,$0e,$0f,$0d,$0c
        .byte   $85,$01,$00,$00,$00,$00,$00,$00
        .byte   $85,$02,$00,$00,$00,$00,$00,$00
        .byte   $85,$03,$00,$00,$00,$00,$00,$00
        .byte   $85,$04,$00,$00,$00,$00,$00,$00
        .byte   $0e,$01,$08,$4a,$17,$11,$10,$10
        .byte   $0e,$02,$08,$56,$10,$12,$11,$11
        .byte   $0e,$03,$08,$62,$11,$13,$12,$12
        .byte   $0e,$04,$08,$6e,$12,$14,$13,$13
        .byte   $0e,$05,$08,$7a,$13,$15,$14,$14
        .byte   $0e,$06,$08,$86,$14,$16,$15,$15
        .byte   $0e,$07,$08,$92,$15,$17,$16,$16
        .byte   $0e,$08,$08,$9e,$16,$10,$17,$17
        .byte   $16,$01,$08,$4e,$2e,$1a,$30,$19
        .byte   $16,$02,$78,$4e,$2e,$1b,$18,$1a
        .byte   $16,$03,$08,$5a,$18,$1c,$19,$1b
        .byte   $16,$04,$78,$5a,$19,$1d,$1a,$1c
        .byte   $16,$05,$08,$66,$1a,$1e,$1b,$1d
        .byte   $16,$06,$78,$66,$1b,$1f,$1c,$1e
        .byte   $16,$07,$08,$72,$1c,$20,$1d,$1f
        .byte   $16,$08,$78,$72,$1d,$21,$1e,$20
        .byte   $16,$09,$08,$7e,$1e,$22,$1f,$21
        .byte   $16,$0a,$78,$7e,$1f,$23,$20,$22
        .byte   $16,$0b,$08,$8a,$20,$24,$21,$23
        .byte   $16,$0c,$78,$8a,$21,$25,$22,$24
        .byte   $16,$0d,$08,$96,$22,$26,$23,$25
        .byte   $16,$0e,$78,$96,$23,$27,$24,$26
        .byte   $16,$0f,$08,$a2,$24,$28,$25,$27
        .byte   $16,$10,$78,$a2,$25,$29,$26,$28
        .byte   $16,$11,$08,$ae,$26,$2a,$27,$29
        .byte   $16,$12,$78,$ae,$27,$2b,$28,$2a
        .byte   $16,$13,$08,$ba,$28,$2c,$29,$2b
        .byte   $16,$14,$78,$ba,$29,$2d,$2a,$2c
        .byte   $16,$15,$08,$c6,$2a,$2f,$2b,$2d
        .byte   $16,$16,$78,$c6,$2b,$2f,$2c,$31
        .byte   $86,$02,$00,$00,$00,$00,$00,$00
        .byte   $86,$01,$00,$00,$00,$00,$00,$00
        .byte   $86,$04,$00,$00,$00,$00,$00,$00
        .byte   $86,$03,$00,$00,$00,$00,$00,$00
        .byte   $1a,$01,$08,$4c,$0e,$0f,$0d,$0c

; c3/a73c
_c3a73c:
        .word   $0118
        .byte   $0f,$01,$40,$10,$00,$00,$00,$02
        .byte   $0f,$02,$58,$10,$01,$01,$00,$02
        .byte   $0f,$03,$70,$10,$02,$02,$00,$03
        .byte   $0f,$04,$a8,$10,$03,$03,$02,$03
        .byte   $10,$01,$08,$4e,$1a,$06,$20,$05
        .byte   $10,$02,$78,$4e,$1a,$07,$04,$06
        .byte   $10,$03,$08,$5a,$04,$08,$05,$07
        .byte   $10,$04,$78,$5a,$05,$09,$06,$08
        .byte   $10,$05,$08,$66,$06,$0a,$07,$09
        .byte   $10,$06,$78,$66,$07,$0b,$08,$0a
        .byte   $10,$07,$08,$72,$08,$0c,$09,$0b
        .byte   $10,$08,$78,$72,$09,$0d,$0a,$0c
        .byte   $10,$09,$08,$7e,$0a,$0e,$0b,$0d
        .byte   $10,$0a,$78,$7e,$0b,$0f,$0c,$0e
        .byte   $10,$0b,$08,$8a,$0c,$10,$0d,$0f
        .byte   $10,$0c,$78,$8a,$0d,$11,$0e,$10
        .byte   $10,$0d,$08,$96,$0e,$12,$0f,$11
        .byte   $10,$0e,$78,$96,$0f,$13,$10,$12
        .byte   $10,$0f,$08,$a2,$10,$14,$11,$13
        .byte   $10,$10,$78,$a2,$11,$15,$12,$14
        .byte   $10,$11,$08,$ae,$12,$16,$13,$15
        .byte   $10,$12,$78,$ae,$13,$17,$14,$16
        .byte   $10,$13,$08,$ba,$14,$18,$15,$17
        .byte   $10,$14,$78,$ba,$15,$19,$16,$18
        .byte   $10,$15,$08,$c6,$16,$1b,$17,$19
        .byte   $10,$16,$78,$c6,$17,$1b,$18,$21
        .byte   $86,$02,$00,$00,$00,$00,$00,$00
        .byte   $86,$01,$00,$00,$00,$00,$00,$00
        .byte   $1e,$01,$08,$60,$1f,$1d,$1c,$1c
        .byte   $1e,$02,$08,$80,$1c,$1e,$1d,$1d
        .byte   $1e,$03,$08,$a0,$1d,$1f,$1e,$1e
        .byte   $1e,$04,$08,$c0,$1e,$1c,$1f,$1f
        .byte   $86,$04,$00,$00,$00,$00,$00,$00
        .byte   $86,$03,$00,$00,$00,$00,$00,$00
        .byte   $24,$01,$00,$00,$22,$22,$22,$22

; c3/a856
_c3a856:
        .word   $0120
        .byte   $12,$02,$00,$0d,$06,$01,$00,$00
        .byte   $12,$03,$00,$1d,$00,$02,$01,$01
        .byte   $12,$04,$00,$2d,$01,$03,$02,$02
        .byte   $12,$05,$00,$45,$02,$04,$03,$03
        .byte   $12,$01,$00,$55,$03,$05,$04,$04
        .byte   $12,$06,$00,$65,$04,$06,$05,$05
        .byte   $12,$07,$00,$75,$05,$00,$06,$06
        .byte   $13,$01,$10,$5e,$16,$0a,$09,$08
        .byte   $13,$02,$58,$5e,$17,$0b,$07,$09
        .byte   $13,$03,$a0,$5e,$18,$0c,$08,$07
        .byte   $13,$04,$10,$6e,$07,$0d,$0c,$0b
        .byte   $13,$05,$58,$6e,$08,$0e,$0a,$0c
        .byte   $13,$06,$a0,$6e,$09,$0f,$0b,$0a
        .byte   $13,$07,$10,$7e,$0a,$10,$0f,$0e
        .byte   $13,$08,$58,$7e,$0b,$11,$0d,$0f
        .byte   $13,$09,$a0,$7e,$0c,$12,$0e,$0d
        .byte   $13,$0a,$10,$8e,$0d,$13,$12,$11
        .byte   $13,$0b,$58,$8e,$0e,$14,$10,$12
        .byte   $13,$0c,$a0,$8e,$0f,$15,$11,$10
        .byte   $13,$0d,$10,$9e,$10,$16,$15,$14
        .byte   $13,$0e,$58,$9e,$11,$17,$13,$15
        .byte   $13,$0f,$a0,$9e,$12,$18,$14,$13
        .byte   $13,$10,$10,$ae,$13,$07,$18,$17
        .byte   $13,$11,$58,$ae,$14,$08,$16,$18
        .byte   $13,$12,$a0,$ae,$15,$09,$17,$16
        .byte   $14,$01,$08,$56,$1b,$1c,$1d,$1e
        .byte   $15,$01,$00,$00,$1a,$1a,$1a,$1a
        .byte   $87,$01,$00,$00,$00,$00,$00,$00
        .byte   $87,$02,$00,$00,$00,$00,$00,$00
        .byte   $87,$03,$00,$00,$00,$00,$00,$00
        .byte   $87,$04,$00,$00,$00,$00,$00,$00
        .byte   $1d,$01,$08,$60,$22,$20,$23,$23
        .byte   $1d,$02,$08,$80,$1f,$21,$23,$23
        .byte   $1d,$03,$08,$a0,$20,$22,$23,$23
        .byte   $1d,$04,$08,$c0,$21,$1f,$23,$23
        .byte   $1d,$05,$00,$00,$1f,$1f,$1f,$1f

; c3/a978
_c3a978:
        .word   $0030
        .byte   $17,$01,$00,$32,$03,$01,$00,$00
        .byte   $17,$02,$00,$5e,$00,$02,$01,$01
        .byte   $17,$03,$00,$8a,$01,$03,$02,$02
        .byte   $17,$04,$00,$b6,$02,$00,$03,$03
        .byte   $1c,$01,$c0,$3a,$04,$05,$04,$04
        .byte   $1c,$02,$c0,$4a,$04,$05,$05,$05

; c3/a9aa
_c3a9aa:
        .word   $0038
        .byte   $17,$09,$00,$10,$00,$01,$00,$00
        .byte   $17,$05,$00,$32,$00,$02,$01,$01
        .byte   $17,$06,$00,$5e,$01,$03,$02,$02
        .byte   $17,$07,$00,$8a,$02,$04,$03,$03
        .byte   $17,$08,$00,$b6,$03,$04,$04,$04
        .byte   $1c,$01,$c0,$3a,$05,$06,$05,$05
        .byte   $1c,$02,$c0,$4a,$05,$06,$06,$06

; c3/a9e4
_c3a9e4:
        .word   $0040
        .byte   $18,$02,$40,$0e,$00,$03,$00,$01
        .byte   $18,$01,$70,$0e,$01,$03,$00,$02
        .byte   $18,$03,$c0,$0e,$02,$03,$01,$02
        .byte   $19,$01,$40,$30,$04,$05,$06,$07
        .byte   $87,$01,$00,$00,$00,$00,$00,$00
        .byte   $87,$02,$00,$00,$00,$00,$00,$00
        .byte   $87,$03,$00,$00,$00,$00,$00,$00
        .byte   $87,$04,$00,$00,$00,$00,$00,$00

; c3/aa26
_c3aa26:
        .word   $0010
        .byte   $1b,$01,$08,$16,$00,$00,$01,$01
        .byte   $1b,$02,$a0,$16,$01,$01,$00,$00

; c3/aa38
_c3aa38:
        .word   $0180
        .byte   $20,$01,$68,$22,$00,$01,$0e,$0d
        .byte   $20,$02,$68,$32,$00,$02,$0e,$0d
        .byte   $20,$03,$68,$42,$01,$03,$0e,$0d
        .byte   $20,$04,$68,$4e,$02,$04,$0e,$0d
        .byte   $20,$05,$68,$5a,$03,$05,$0e,$0d
        .byte   $20,$06,$68,$6a,$04,$06,$0e,$0d
        .byte   $20,$07,$68,$76,$05,$07,$0e,$0d
        .byte   $20,$08,$68,$82,$06,$08,$0e,$0d
        .byte   $20,$09,$68,$92,$07,$09,$0e,$0d
        .byte   $20,$0a,$68,$9e,$08,$0a,$0e,$0d
        .byte   $20,$0b,$68,$ae,$09,$0b,$0e,$0d
        .byte   $20,$0c,$68,$ba,$0a,$0c,$0e,$0d
        .byte   $20,$0d,$68,$c6,$0b,$0c,$0e,$0d
        .byte   $89,$03,$00,$00,$00,$00,$00,$00
        .byte   $89,$01,$00,$00,$00,$00,$00,$00
        .byte   $21,$15,$50,$56,$12,$10,$0e,$0d
        .byte   $21,$16,$50,$66,$0f,$11,$0e,$0d
        .byte   $21,$17,$50,$76,$10,$12,$0e,$0d
        .byte   $21,$18,$50,$86,$11,$0f,$0e,$0d
        .byte   $22,$29,$08,$3a,$13,$14,$0e,$0d
        .byte   $22,$2a,$08,$4e,$13,$15,$0e,$0d
        .byte   $22,$2b,$08,$62,$14,$16,$0e,$0d
        .byte   $22,$2c,$08,$76,$15,$17,$0e,$0d
        .byte   $22,$2d,$08,$8a,$16,$18,$0e,$0d
        .byte   $22,$2e,$08,$9e,$17,$19,$0e,$0d
        .byte   $22,$2f,$08,$b2,$18,$1a,$0e,$0d
        .byte   $22,$01,$08,$c2,$19,$1a,$1a,$1a
        .byte   $1f,$01,$34,$30,$1f,$1c,$1b,$21
        .byte   $1f,$02,$34,$5c,$1b,$1d,$1c,$25
        .byte   $1f,$03,$34,$88,$1c,$1e,$1d,$29
        .byte   $1f,$04,$34,$b4,$1d,$1e,$1e,$2d
        .byte   $1f,$05,$10,$0e,$1f,$1b,$1f,$1f
        .byte   $23,$01,$78,$24,$20,$23,$21,$22
        .byte   $23,$02,$50,$30,$20,$23,$1b,$22
        .byte   $23,$03,$a0,$30,$20,$23,$21,$22
        .byte   $23,$04,$78,$3c,$20,$23,$21,$22
        .byte   $23,$05,$78,$50,$24,$27,$25,$26
        .byte   $23,$06,$50,$5c,$24,$27,$1c,$26
        .byte   $23,$07,$a0,$5c,$24,$27,$25,$26
        .byte   $23,$08,$78,$68,$24,$27,$25,$26
        .byte   $23,$09,$78,$7c,$28,$2b,$29,$2a
        .byte   $23,$0a,$50,$88,$28,$2b,$1d,$2a
        .byte   $23,$0b,$a0,$88,$28,$2b,$29,$2a
        .byte   $23,$0c,$78,$94,$28,$2b,$29,$2a
        .byte   $23,$0d,$78,$a8,$2c,$2f,$2d,$2e
        .byte   $23,$0e,$50,$b4,$2c,$2f,$1e,$2e
        .byte   $23,$0f,$a0,$b4,$2c,$2f,$2d,$2e
        .byte   $23,$10,$78,$c0,$2c,$2f,$2d,$2e

; ---------------------------------------------------------------------------

; [ hardware values ]

; hardware values get copied to $7500-$750e

; c3/abba: ??? hardware values
_c3abba:
        .word   $000f
        .byte   $1c,$00,$0c,$00,$00,$23,$30,$00,$00,$80,$10,$2a,$4a,$8a,$c4

; c3/abcb
_c3abcb:
        .word   $000f
        .byte   $1e,$00,$0c,$00,$00,$32,$00,$00,$00,$00,$32,$20,$40,$80,$e4

; c3/abdc
_c3abdc:
        .word   $000f
        .byte   $1c,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$20,$40,$80,$c0

; c3/abed
_c3abed:
        .word   $000f
        .byte   $16,$00,$00,$00,$00,$32,$00,$00,$00,$00,$30,$20,$40,$80,$e4

; c3/abfe
_c3abfe:
        .word   $000f
        .byte   $1c,$00,$0c,$00,$00,$32,$00,$00,$00,$00,$30,$20,$40,$80,$c4

; c3/ac0f
_c3ac0f:
        .word   $000f
        .byte   $14,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$20,$40,$80,$e0

; c3/ac20
_c3ac20:
        .word   $000f
        .byte   $1c,$00,$1c,$00,$00,$32,$0c,$00,$00,$80,$00,$2a,$4a,$8a,$cc

; c3/ac31
_c3ac31:
        .word   $000f
        .byte   $1e,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$20,$40,$80,$c0

; c3/ac42
_c3ac42:
        .word   $000f
        .byte   $12,$00,$00,$00,$00,$23,$00,$00,$00,$00,$30,$20,$40,$80,$e4

; c3/ac53
_c3ac53:
        .word   $000f
        .byte   $1c,$00,$0c,$00,$00,$32,$00,$00,$00,$00,$30,$20,$40,$80,$44

; c3/ac64
_c3ac64:
        .word   $000f
        .byte   $14,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$20,$40,$80,$40

; c3/ac75
_c3ac75:
        .word   $000f
        .byte   $14,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$2a,$4a,$8a,$40

; ---------------------------------------------------------------------------

; c3/ac86: ??? window 1 hdma table
_c3ac86:
        .word   $0010
        .byte   $7f,$00,$bf
        .byte   $20,$00,$bf
        .byte   $1c,$00,$b7
        .byte   $1c,$00,$af
        .byte   $01,$00,$00
        .byte   $00

; c3/ac98: ??? window 2 hdma table
_c3ac98:
        .word   $0034
        .byte   $13,$00,$00
        .byte   $01,$0f,$29
        .byte   $1e,$0e,$2a
        .byte   $01,$0f,$29
        .byte   $10,$00,$00
        .byte   $01,$0f,$29
        .byte   $1e,$0e,$2a
        .byte   $01,$0f,$29
        .byte   $10,$00,$00
        .byte   $01,$0f,$29
        .byte   $1e,$0e,$2a
        .byte   $01,$0f,$29
        .byte   $10,$00,$00
        .byte   $01,$0f,$29
        .byte   $1e,$0e,$2a
        .byte   $01,$0f,$29
        .byte   $01,$00,$00
        .byte   $00

; c3/acce
_c3acce:
        .word   $000a
        .byte   $40,$00,$00
        .byte   $54,$68,$ef
        .byte   $01,$00,$00
        .byte   $00

; c3/acda
_c3acda:
        .word   $000a
        .byte   $64,$00,$00
        .byte   $6c,$10,$6f
        .byte   $01,$00,$00
        .byte   $00

; c3/ace6
_c3ace6:
        .word   $0007
        .byte   $7f,$80,$ff
        .byte   $58,$80,$ff
        .byte   $01,$00,$00
        .byte   $00

; c3/acf2
_c3acf2:
        .word   $000d
        .byte   $4b,$00,$00
        .byte   $7f,$18,$e7
        .byte   $05,$18,$e7
        .byte   $01,$00,$00
        .byte   $00

; c3/ad01
_c3ad01:
        .word   $000d
        .byte   $4b,$00,$00
        .byte   $7f,$08,$f7
        .byte   $09,$08,$f7
        .byte   $01,$00,$00
        .byte   $00

; c3/ad10
_c3ad10:
        .word   $000d
        .byte   $2b,$00,$00
        .byte   $7f,$50,$ef
        .byte   $1d,$50,$ef
        .byte   $01,$00,$00
        .byte   $00

; c3/ad1f
_c3ad1f:
        .word   $0010
        .byte   $63,$00,$af
        .byte   $3c,$00,$ff
        .byte   $1c,$00,$b7
        .byte   $1c,$00,$af
        .byte   $01,$00,$00
        .byte   $00

; ---------------------------------------------------------------------------

; c3/ad31: number of bytes of each type of menu tilemap data
        .word   0,1,5,5,4,1,5

; ---------------------------------------------------------------------------

; [ menu tilemaps ]

; c3/ad3f
_c3ad3f:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$01,$01,$1e,$1f
        .byte   $00

; c3/ad4a
_c3ad4a:
        .byte   $04,$01,$00,$01,$02,$80
        .byte   $04,$03,$00,$08,$04,$80
        .byte   $04,$04,$00,$08,$05,$80
        .byte   $00

; c3/ad5d
_c3ad5d:
        .byte   $02,$ff,$00,$00,$00,$14,$06
        .byte   $00

; c3/ad65
_c3ad65:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$18,$01,$07,$07
        .byte   $04,$05,$00,$19,$03,$00
        .byte   $04,$06,$00,$19,$05,$00
        .byte   $06,$02,$00,$18,$08,$07,$0d
        .byte   $04,$07,$00,$19,$09,$80
        .byte   $04,$08,$00,$19,$0b,$00
        .byte   $04,$09,$00,$19,$0d,$00
        .byte   $04,$0a,$00,$19,$0f,$00
        .byte   $04,$0b,$00,$19,$11,$00
        .byte   $04,$0c,$00,$19,$13,$00

; c3/ada6
_c3ada6:
        .byte   $06,$0e,$00,$17,$15,$08,$05
        .byte   $04,$0d,$00,$18,$16,$80
        .byte   $04,$0e,$00,$19,$18,$80
        .byte   $06,$0e,$00,$16,$1a,$09,$05
        .byte   $04,$0f,$00,$1c,$1d,$00
        .byte   $00

; c3/adc7
_c3adc7:
        .byte   $05,$00,$40
        .byte   $06,$02,$00,$18,$01,$07,$03
        .byte   $04,$10,$00,$19,$02,$80
        .byte   $00

; c3/add8
_c3add8:
        .byte   $05,$00,$40
        .byte   $02,$00,$00,$18,$01,$07,$03
        .byte   $00

; c3/ade3
_c3ade3:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$14,$0c,$03
        .byte   $04,$84,$00,$03,$15,$80
        .byte   $00

; c3/adf4
_c3adf4:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$01,$1e,$21
        .byte   $03,$02,$00,$18,$01,$07,$05
        .byte   $04,$06,$00,$19,$03,$00
        .byte   $03,$0e,$00,$0c,$09,$13,$10
        .byte   $04,$01,$00,$07,$05,$80
        .byte   $04,$12,$00,$11,$07,$00
        .byte   $04,$06,$00,$15,$07,$00
        .byte   $04,$30,$00,$1a,$07,$80
        .byte   $04,$13,$00,$02,$07,$00
        .byte   $04,$30,$00,$08,$07,$80
        .byte   $00

; c3/ae37
_c3ae37:
        .byte   $05,$00,$50
        .byte   $04,$15,$00,$02,$1a,$00
        .byte   $04,$17,$00,$0e,$1a,$80
        .byte   $04,$31,$00,$0f,$1a,$00
        .byte   $04,$16,$00,$14,$1a,$00
        .byte   $00

; c3/ae53
_c3ae53:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$02,$19,$1c,$08
        .byte   $00

; c3/ae5e
_c3ae5e:
        .byte   $01,$ff,$00
        .byte   $00

; c3/ae62
_c3ae62:
        .byte   $05,$00,$50
        .byte   $03,$0e,$00,$0c,$09,$13,$10
        .byte   $00

; c3/ae6d
_c3ae6d:
        .byte   $05,$00,$50
        .byte   $06,$0e,$00,$01,$09,$0c,$10
        .byte   $03,$0e,$00,$02,$0d,$0a,$04
        .byte   $03,$0e,$00,$02,$14,$0a,$04
        .byte   $04,$05,$00,$03,$0b,$00
        .byte   $04,$49,$00,$06,$0b,$00
        .byte   $04,$06,$00,$03,$12,$00
        .byte   $00

; c3/ae98
_c3ae98:
        .byte   $05,$00,$50
        .byte   $06,$0e,$00,$01,$09,$0c,$10
        .byte   $03,$0e,$00,$02,$0d,$0a,$0b
        .byte   $04,$06,$00,$03,$0b,$00
        .byte   $00

; c3/aeb0
_c3aeb0:
        .byte   $05,$00,$50
        .byte   $06,$0e,$00,$01,$09,$0c,$10
        .byte   $03,$02,$00,$02,$10,$0a,$08
        .byte   $04,$06,$00,$03,$0e,$00
        .byte   $00

; c3/aec8
_c3aec8:
        .byte   $05,$00,$40
        .byte   $06,$02,$00,$01,$14,$1e,$08
        .byte   $04,$86,$00,$0a,$17,$00
        .byte   $00

; c3/aed9
_c3aed9:
        .byte   $05,$00,$40
        .byte   $06,$02,$00,$01,$14,$1e,$08
        .byte   $04,$87,$00,$0b,$17,$00
        .byte   $00

; c3/aeea
_c3aeea:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$01,$1e,$06
        .byte   $06,$02,$00,$18,$01,$07,$05
        .byte   $04,$05,$00,$19,$03,$00
        .byte   $04,$01,$00,$07,$05,$80
        .byte   $06,$02,$00,$01,$07,$1e,$0f
        .byte   $00

; c3/af0f
_c3af0f:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$01,$15,$1e,$08
        .byte   $00

; c3/af1a
_c3af1a:
        .byte   $05,$00,$60
        .byte   $02,$ff,$00
        .byte   $02,$16,$1c
        .byte   $06,$04,$88,$00,$15,$17,$00
        .byte   $00

; c3/af2b: sell confirmation message
_c3af2b:
        .byte   $05,$00,$40
        .byte   $06,$02,$00,$01,$14,$1e,$08  ; border 30x8 at (1,20)
        .byte   $04,$85,$00,$09,$17,$00  ; "　うりたいんだい？」" (do you want to sell?)
        .byte   $00

; c3/af3c: equip menu title
_c3af3c:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$18,$01,$07,$04  ; border 7x4 at (24,1)
        .byte   $04,$09,$00,$1a,$03,$00  ; "そうび" (equipment)
        .byte   $00

; c3/af4d: equip menu character and status windows
_c3af4d:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$01,$01,$1e,$0f  ; border 30x15 at (1,1)
        .byte   $06,$0e,$00,$0f,$10,$10,$13  ; border 16x19 at (15,16)
        .byte   $04,$1e,$00,$02,$0a,$00  ; "あたま" (head)
        .byte   $04,$1f,$00,$02,$0c,$00  ; "からだ" (body)
        .byte   $04,$20,$00,$02,$0e,$00  ; "アクセサリ" (accessories)
        .byte   $04,$09,$00,$13,$0a,$00  ; "そうび" (equipment)
        .byte   $04,$30,$00,$16,$0a,$80  ; "："
        .byte   $04,$21,$00,$10,$11,$80  ; "ちから" (strength)
        .byte   $04,$22,$00,$10,$13,$00  ; "すばやさ" (speed)
        .byte   $04,$23,$00,$10,$15,$00  ; "たいりょく" (stamina)
        .byte   $04,$24,$00,$10,$17,$00  ; "まりょく" (power)
        .byte   $04,$25,$00,$10,$19,$00  ; "こうげき" (attack)
        .byte   $04,$26,$00,$10,$1b,$00  ; "ぼうぎょ" (defense)
        .byte   $04,$27,$00,$10,$1d,$00  ; "かいひりつ" (evade)
        .byte   $04,$08,$00,$10,$1f,$00  ; "まほう" (magic)
        .byte   $04,$26,$00,$13,$1f,$00  ; "ぼうぎょ" (defense)
        .byte   $04,$09,$00,$10,$21,$00  ; "そうび" (equipment)
        .byte   $04,$28,$00,$13,$21,$00  ; "のおもさ" (weight)
        .byte   $04,$29,$00,$1a,$11,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$13,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$15,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$17,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$19,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$1b,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$1d,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$1f,$80  ; "＿"
        .byte   $04,$29,$00,$1a,$21,$80  ; "＿"
        .byte   $04,$2a,$00,$1d,$1d,$80  ; "％"
; fallthrough

; c3/affa
_c3affa:
        .byte   $05,$00,$50
        .byte   $06,$0e,$00,$01,$10,$0e,$13
        .byte   $00

; c3/b005
_c3b005:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$1b,$11,$03,$11
        .byte   $04,$2a,$00,$1d,$1d,$80
        .byte   $00

; c3/b016
_c3b016:
        .byte   $04,$1b,$00,$00,$00,$00
        .byte   $00

; c3/b01d
_c3b01d:
        .byte   $04,$1c,$00,$00,$00,$00
        .byte   $00

; c3/b024
_c3b024:
        .byte   $04,$1d,$00,$00,$00,$00
        .byte   $00

; c3/b02b
_c3b02b:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$01,$0c,$0e,$18
        .byte   $00

; c3/b036
_c3b036:
        .byte   $05,$00,$40
        .byte   $06,$0e,$00,$01,$01,$1e,$04
        .byte   $04,$09,$00,$03,$03,$00
        .byte   $04,$18,$00,$08,$03,$00
        .byte   $04,$1a,$00,$0f,$03,$00
        .byte   $04,$19,$00,$14,$03,$00
        .byte   $04,$1a,$00,$17,$03,$00
        .byte   $04,$50,$00,$1b,$03,$00
        .byte   $00

; c3/b065
_c3b065:
        .byte   $05,$00,$40
        .byte   $02,$00,$00,$01,$01,$1e,$04
        .byte   $06,$0e,$00,$18,$01,$07,$04
        .byte   $04,$09,$00,$1a,$03,$00
        .byte   $00

; c3/b07d
_c3b07d:
        .byte   $05,$00,$40
        .byte   $02,$00,$00,$01,$01,$1e,$04
        .byte   $06,$0e,$00,$18,$01,$07,$04
        .byte   $04,$1a,$00,$1a,$03,$00
        .byte   $00

; c3/b095
_c3b095:
        .byte   $05,$00,$50
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$02,$1e,$1b
        .byte   $04,$31,$00,$0a,$04,$00
        .byte   $04,$03,$00,$03,$0d,$80
        .byte   $04,$04,$00,$03,$0e,$80
        .byte   $04,$2b,$00,$03,$10,$00
        .byte   $04,$2c,$00,$03,$13,$00
        .byte   $04,$12,$00,$03,$16,$00
        .byte   $04,$06,$00,$07,$16,$00
        .byte   $04,$2f,$00,$0c,$16,$00
        .byte   $00

; c3/b0d3
_c3b0d3:
        .byte   $05,$00,$60
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$0f,$01,$10,$21
        .byte   $03,$02,$00,$18,$01,$07,$03
        .byte   $04,$0a,$00,$19,$02,$80
        .byte   $04,$49,$00,$12,$03,$00
        .byte   $03,$0e,$00,$12,$05,$0a,$0a
        .byte   $04,$21,$00,$10,$10,$00
        .byte   $04,$22,$00,$10,$12,$00
        .byte   $04,$23,$00,$10,$14,$00
        .byte   $04,$24,$00,$10,$16,$00
        .byte   $04,$24,$00,$13,$18,$00
        .byte   $04,$25,$00,$10,$18,$00
        .byte   $04,$24,$00,$13,$1a,$00
        .byte   $04,$26,$00,$10,$1a,$00
        .byte   $04,$27,$00,$10,$1c,$00
        .byte   $04,$08,$00,$10,$1e,$00
        .byte   $04,$26,$00,$13,$1e,$00
        .byte   $04,$09,$00,$10,$20,$00
        .byte   $04,$28,$00,$13,$20,$00
        .byte   $04,$29,$00,$19,$10,$80
        .byte   $04,$29,$00,$19,$12,$80
        .byte   $04,$29,$00,$19,$14,$80
        .byte   $04,$29,$00,$19,$16,$80
        .byte   $04,$29,$00,$19,$18,$80
        .byte   $04,$29,$00,$19,$1a,$80
        .byte   $04,$29,$00,$19,$1c,$80
        .byte   $04,$2a,$00,$1d,$1c,$80
        .byte   $04,$29,$00,$19,$1e,$80
        .byte   $04,$29,$00,$19,$20,$80
        .byte   $00

; c3/b185
_c3b185:
        .byte   $05,$00,$50
        .byte   $04,$13,$00,$03,$19,$00
        .byte   $04,$2d,$00,$09,$19,$00
        .byte   $00

; c3/b195
_c3b195:
        .byte   $05,$00,$50
        .byte   $04,$7b,$00,$03,$19,$00
        .byte   $00

; c3/b19f
_c3b19f:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$08,$19,$09
        .byte   $04,$30,$00,$0c,$0a,$80
        .byte   $04,$29,$00,$10,$0a,$80
        .byte   $04,$0f,$00,$17,$0c,$00
        .byte   $04,$37,$00,$04,$0d,$00
        .byte   $04,$38,$00,$03,$0d,$00
        .byte   $04,$30,$00,$0c,$0d,$80
        .byte   $04,$09,$00,$03,$0f,$00
        .byte   $04,$37,$00,$06,$0f,$00
        .byte   $04,$30,$00,$0c,$0f,$80
        .byte   $00

; c3/b1e0
_c3b1e0:
        .byte   $05,$00,$40
        .byte   $06,$0e,$00,$01,$11,$19,$08
        .byte   $00

; c3/b1eb
_c3b1eb:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$02,$02,$1c,$02
        .byte   $03,$02,$00,$01,$01,$07,$04
        .byte   $03,$02,$00,$08,$01,$17,$04
        .byte   $04,$32,$00,$09,$03,$00
        .byte   $02,$ff,$00,$02,$06,$1c,$02
        .byte   $03,$0e,$00,$01,$05,$0e,$04
        .byte   $03,$0e,$00,$0f,$05,$10,$04
        .byte   $04,$33,$00,$03,$07,$00
        .byte   $04,$35,$00,$0b,$07,$00
        .byte   $04,$36,$00,$10,$07,$00
        .byte   $04,$0f,$00,$1c,$07,$00
        .byte   $00

; c3/b237
_c3b237:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$03,$08,$1a,$1a
        .byte   $00

; c3/b242
_c3b242:
        .byte   $05,$00,$50
        .byte   $02,$00,$00,$01,$09,$1e,$15
        .byte   $06,$02,$00,$01,$09,$19,$13
        .byte   $00

; c3/b254
_c3b254:
        .byte   $05,$00,$50
        .byte   $02,$00,$00,$01,$09,$19,$13
        .byte   $00

; c3/b25f
_c3b25f:
        .byte   $05,$00,$50
        .byte   $06,$02,$00,$1a,$09,$05,$14
        .byte   $00

; c3/b26a
_c3b26a:
        .byte   $05,$00,$50
        .byte   $02,$00,$00,$1a,$09,$05,$14
        .byte   $00

; c3/b275
_c3b275:
        .byte   $05,$00,$50
        .byte   $02,$00,$00,$01,$09,$1e,$15
        .byte   $06,$02,$00,$01,$09,$19,$13
        .byte   $00

; c3/b287
_c3b287:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$39,$00,$09,$03,$00
        .byte   $00

; c3/b298
_c3b298:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$3a,$00,$09,$03,$00
        .byte   $00

; c3/b2a9
_c3b2a9:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$32,$00,$09,$03,$00
        .byte   $00

; c3/b2ba
_c3b2ba:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$3b,$00,$09,$03,$00
        .byte   $00

; c3/b2cb
_c3b2cb:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$3c,$00,$09,$03,$00
        .byte   $00

; c3/b2dc
_c3b2dc:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$3d,$00,$09,$03,$00
        .byte   $00

; c3/b2ed
_c3b2ed:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$3e,$00,$09,$03,$00
        .byte   $00


; c3/b2fe
_c3b2fe:
        .byte   $05,$00,$50
        .byte   $06,$02,$00,$01,$09,$1e,$18
        .byte   $02,$00,$00,$03,$0b,$1a,$14
        .byte   $00

; c3/b310
_c3b310:
        .byte   $05,$00,$50
        .byte   $02,$00,$00,$01,$09,$1e,$18
        .byte   $00

; c3/b31b
_c3b31b:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$53,$00,$09,$03,$00
        .byte   $04,$55,$00,$0d,$03,$00
        .byte   $00

; c3/b332
_c3b332:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$09,$02,$15,$02
        .byte   $04,$54,$00,$09,$03,$00
        .byte   $04,$55,$00,$0d,$03,$00
        .byte   $00

; c3/b349
_c3b349:
        .byte   $05,$00,$50
        .byte   $06,$02,$00,$01,$02,$1e,$08
        .byte   $04,$71,$00,$03,$04,$00
        .byte   $04,$72,$00,$03,$07,$00
        .byte   $00

; c3/b360
_c3b360:
        .byte   $05,$00,$50

; c3/b363
_c3b363:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$02,$02,$1c,$08
        .byte   $03,$0e,$00,$01,$01,$06,$04
        .byte   $04,$07,$00,$02,$03,$00
        .byte   $03,$0e,$00,$07,$01,$18,$04
        .byte   $04,$11,$00,$0a,$03,$00
        .byte   $04,$40,$00,$10,$03,$00
        .byte   $04,$41,$00,$17,$03,$00
        .byte   $03,$0e,$00,$01,$05,$1e,$06
        .byte   $06,$0e,$00,$01,$0b,$1e,$13
        .byte   $02,$00,$00,$03,$0d,$1a,$0f
        .byte   $00

; c3/b3a9
_c3b3a9:
        .byte   $05,$00,$50
        .byte   $02,$ff,$00,$02,$06,$1c,$04
        .byte   $00

; c3/b3b4
_c3b3b4:
        .byte   $05,$00,$60

; c3/b3b7
_c3b3b7:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$03,$08,$1a,$1a
        .byte   $00

; c3/b3c2
_c3b3c2:
        .byte   $05,$00,$40
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$01,$08,$1e,$13
        .byte   $04,$3f,$00,$0b,$0a,$00
        .byte   $00

; c3/b3d6
_c3b3d6:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$01,$06,$1e,$06
        .byte   $04,$01,$00,$0e,$08,$80
        .byte   $04,$03,$00,$06,$09,$80
        .byte   $04,$04,$00,$06,$0a,$80
        .byte   $00

; c3/b3f3
_c3b3f3:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$08,$01,$17,$06
        .byte   $00

; c3/b3fe
_c3b3fe:
        .byte   $05,$00,$60
        .byte   $06,$02,$00,$01,$0c,$1e,$0f
        .byte   $00

; c3/b409
_c3b409:
        .byte   $05,$00,$60
        .byte   $04,$48,$00,$12,$03,$00
        .byte   $00

; c3/b413
_c3b413:
        .byte   $05,$00,$60
        .byte   $02,$00,$00,$01,$0c,$1e,$0f
        .byte   $00

; c3/b41e
_c3b41e:
        .byte   $05,$00,$60
        .byte   $06,$0e,$00,$01,$0c,$1e,$16
        .byte   $00

; c3/b429
_c3b429:
        .byte   $05,$00,$60
        .byte   $02,$00,$00,$01,$0c,$1e,$16
        .byte   $00

; c3/b434
_c3b434:
        .byte   $05,$00,$40
        .byte   $02,$ff,$00,$02,$02,$05,$0e
        .byte   $03,$02,$00,$01,$01,$07,$07
        .byte   $03,$02,$00,$01,$08,$07,$09
        .byte   $04,$42,$00,$02,$02,$80
        .byte   $04,$08,$00,$04,$02,$80
        .byte   $04,$43,$00,$02,$04,$00
        .byte   $04,$08,$00,$04,$04,$00
        .byte   $04,$44,$00,$02,$06,$00
        .byte   $04,$45,$00,$02,$09,$80
        .byte   $04,$08,$00,$02,$0b,$00
        .byte   $04,$51,$00,$05,$0b,$00
        .byte   $04,$46,$00,$02,$0d,$00
        .byte   $04,$08,$00,$04,$0d,$00
        .byte   $04,$47,$00,$02,$0f,$00

; c3/b48e
_c3b48e:
        .byte   $05,$00,$60
        .byte   $06,$0e,$00,$08,$01,$17,$06
        .byte   $00

; c3/b499
_c3b499:
        .byte   $05,$00,$40
        .byte   $02,$00,$00,$01,$01,$07,$10
        .byte   $00

; c3/b4a4
_c3b4a4:
        .byte   $05,$00,$50
        .byte   $06,$0e,$00,$01,$01,$07,$05
        .byte   $00

; c3/b4af
_c3b4af:
        .byte   $05,$00,$50
        .byte   $04,$42,$00,$02,$03,$00  ; (2,3) "しろ" (white)
        .byte   $04,$08,$00,$04,$03,$00  ; (4,3) "まほう" (magic)
        .byte   $00

; c3/b4bf
_c3b4bf:
        .byte   $05,$00,$50
        .byte   $04,$43,$00,$02,$03,$00  ; (2,3) "くろ" (black)
        .byte   $04,$08,$00,$04,$03,$00  ; (4,3) "まほう" (magic)
        .byte   $00

; c3/b4cf
_c3b4cf:
        .byte   $05,$00,$50
        .byte   $04,$44,$00,$02,$03,$00  ; (2,3) "じくう" (jikuu)
        .byte   $00

; c3/b4d9
_c3b4d9:
        .byte   $05,$00,$50
        .byte   $04,$45,$00,$02,$03,$00
        .byte   $00

; c3/b4e3
_c3b4e3:
        .byte   $05,$00,$50
        .byte   $04,$46,$00,$02,$03,$00
        .byte   $04,$08,$00,$04,$03,$00
        .byte   $00

; c3/b4f3
_c3b4f3:
        .byte   $05,$00,$50
        .byte   $04,$47,$00,$02,$03,$00
        .byte   $00

; c3/b4fd
_c3b4fd:
        .byte   $05,$00,$50
        .byte   $04,$08,$00,$02,$03,$00
        .byte   $04,$51,$00,$05,$03,$00
        .byte   $00

; c3/b50d
_c3b50d:
        .byte   $05,$00,$40
        .byte   $06,$0e,$00,$02,$09,$1c,$12
        .byte   $00

; c3/b518
_c3b518:
        .byte   $05,$00,$40
        .byte   $02,$00,$00,$02,$09,$1c,$12
        .byte   $00

; c3/b523
_c3b523:
        .byte   $04,$01,$00,$13,$00,$80
        .byte   $04,$03,$00,$0c,$01,$80
        .byte   $04,$04,$00,$0c,$02,$80
        .byte   $00

; c3/b536
_c3b536:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$01,$1e,$05
        .byte   $04,$0c,$00,$0e,$03,$00
        .byte   $02,$ff,$00,$02,$07,$1c,$16
        .byte   $03,$0e,$00,$01,$06,$1e,$06
        .byte   $03,$0e,$00,$01,$0c,$1e,$06
        .byte   $03,$0e,$00,$01,$12,$1e,$06
        .byte   $03,$0e,$00,$01,$18,$1e,$06
        .byte   $00

; c3/b56a
_c3b56a:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$01,$01,$1e,$05
        .byte   $04,$5b,$00,$0d,$03,$00
        .byte   $02,$ff,$00,$02,$07,$1c,$16
        .byte   $03,$0e,$00,$01,$06,$1e,$06
        .byte   $03,$0e,$00,$01,$0c,$1e,$06
        .byte   $03,$0e,$00,$01,$12,$1e,$06
        .byte   $03,$0e,$00,$01,$18,$1e,$06
        .byte   $00

; c3/b59e
_c3b59e:
        .byte   $04,$01,$00,$13,$00,$80
        .byte   $04,$17,$00,$17,$02,$80
        .byte   $04,$30,$00,$03,$02,$80
        .byte   $00

; c3/b5b1
_c3b5b1:
        .byte   $04,$5a,$00,$00,$00,$80
        .byte   $00

; c3/b5b8
_c3b5b8:
        .byte   $05,$00,$60
        .byte   $06,$02,$00,$16,$01,$09,$0d
        .byte   $04,$82,$00,$1a,$09,$00
        .byte   $04,$83,$00,$1a,$0b,$00
        .byte   $00

; c3/b5cf
_c3b5cf:
        .byte   $05,$00,$60
        .byte   $04,$7d,$00,$17,$03,$00
        .byte   $04,$7e,$00,$17,$05,$00
        .byte   $00

; c3/b5df
_c3b5df:
        .byte   $05,$00,$60
        .byte   $04,$7f,$00,$17,$03,$00
        .byte   $04,$80,$00,$17,$05,$00
        .byte   $04,$81,$00,$17,$07,$00
        .byte   $00

; c3/b5f5
_c3b5f5:
        .byte   $01,$00,$00
        .byte   $06,$0e,$00,$09,$05,$16,$1a
        .byte   $06,$0e,$00,$01,$05,$08,$09
        .byte   $06,$0e,$00,$09,$01,$16,$04
        .byte   $04,$4e,$00,$0a,$03,$00
        .byte   $04,$4f,$00,$10,$03,$00
        .byte   $04,$50,$00,$1a,$03,$00
        .byte   $00

; c3/b620
_c3b620:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$0a,$05,$14,$14  ; 20x20 fill at (10,5)
        .byte   $00

; c3/b62b
_c3b62b:
        .byte   $05,$00,$50
        .byte   $03,$0e,$00,$01,$05,$08,$04
        .byte   $00

; c3/b636: treasure menu
_c3b636:
        .byte   $01,$00,$00
        .byte   $02,$ff,$00,$02,$03,$1c,$16  ; 28x22 fill at (2,3)
        .byte   $03,$0e,$00,$01,$02,$1e,$04  ; 30x4 border at (1,2)
        .byte   $03,$02,$00,$01,$06,$0f,$14  ; 15x20 border at (1,6)
        .byte   $03,$02,$00,$10,$06,$0f,$14  ; 15x20 border at (16,6)
        .byte   $04,$56,$00,$03,$04,$00  ; (3,4) "ぜんぶもっていく" (take all)
        .byte   $04,$57,$00,$16,$04,$00  ; (22,4) "ぜんぜんいらない" (take none)
        .byte   $04,$58,$00,$02,$07,$80  ; (2,7) "おたから" (treasure)
        .byte   $04,$59,$00,$11,$07,$80  ; (17,7) "もちもの" (inventory)
        .byte   $00

; c3/b66e
_c3b66e:
        .byte   $01,$00,$00
        .byte   $06,$02,$00,$02,$04,$1b,$1c
        .byte   $06,$0e,$00,$17,$01,$07,$04
        .byte   $04,$0b,$00,$18,$03,$00
        .byte   $04,$5c,$00,$04,$06,$00
        .byte   $04,$5e,$00,$06,$08,$00
        .byte   $04,$61,$00,$0f,$08,$80
        .byte   $04,$60,$00,$0f,$09,$80
        .byte   $04,$5f,$00,$06,$0a,$00
        .byte   $04,$61,$00,$0f,$0a,$80
        .byte   $04,$62,$00,$06,$0c,$00
        .byte   $04,$63,$00,$06,$0e,$00
        .byte   $04,$64,$00,$04,$10,$00
        .byte   $04,$66,$00,$04,$12,$00
        .byte   $04,$68,$00,$04,$14,$00
        .byte   $04,$18,$00,$0f,$14,$00
        .byte   $04,$19,$00,$16,$14,$00
        .byte   $04,$1a,$00,$19,$14,$00
        .byte   $04,$69,$00,$04,$16,$00
        .byte   $04,$6b,$00,$0f,$18,$00
        .byte   $04,$6c,$00,$04,$1a,$00
        .byte   $04,$6d,$00,$0f,$1a,$80
        .byte   $04,$6e,$00,$0f,$1c,$80
        .byte   $04,$6f,$00,$0f,$1e,$80
        .byte   $04,$70,$00,$11,$1a,$80
        .byte   $04,$70,$00,$11,$1c,$80
        .byte   $04,$70,$00,$11,$1e,$80
        .byte   $00

; c3/b710
_c3b710:
        .byte   $05,$00,$40
        .byte   $06,$02,$00,$01,$07,$1d,$0d
        .byte   $04,$5d,$00,$02,$08,$80
        .byte   $04,$65,$00,$0c,$0b,$00
        .byte   $04,$65,$00,$0c,$0d,$00
        .byte   $04,$65,$00,$0c,$0f,$00
        .byte   $04,$65,$00,$0c,$11,$00
        .byte   $00

; c3/b739
_c3b739:
        .byte   $05,$00,$40
        .byte   $01,$00,$00
        .byte   $00

; c3/b740
_c3b740:
        .byte   $05,$00,$40
        .byte   $06,$02,$00,$01,$03,$1e,$1b
        .byte   $04,$7a,$00,$04,$08,$00
        .byte   $04,$7a,$00,$04,$0b,$00
        .byte   $04,$7a,$00,$04,$0e,$00
        .byte   $04,$7a,$00,$04,$11,$00
        .byte   $04,$7a,$00,$04,$14,$00
        .byte   $04,$7a,$00,$04,$17,$00
        .byte   $04,$7a,$00,$04,$1a,$00
        .byte   $04,$67,$00,$02,$05,$00

; c3/b77a
_c3b77a:
        .byte   $05,$00,$40
        .byte   $04,$73,$00,$03,$07,$00
        .byte   $04,$4c,$00,$04,$07,$00
        .byte   $04,$74,$00,$03,$0a,$00
        .byte   $04,$4c,$00,$04,$0a,$00
        .byte   $04,$75,$00,$03,$0d,$00
        .byte   $04,$4c,$00,$04,$0d,$00
        .byte   $04,$76,$00,$03,$10,$00
        .byte   $04,$4c,$00,$04,$10,$00
        .byte   $04,$77,$00,$03,$13,$00
        .byte   $04,$4c,$00,$04,$13,$00
        .byte   $04,$78,$00,$03,$16,$00
        .byte   $04,$4c,$00,$04,$16,$00
        .byte   $04,$79,$00,$03,$19,$00
        .byte   $04,$6a,$00,$03,$1c,$00
        .byte   $00

; c3/b7d2
_c3b7d2:
        .byte   $05,$00,$40
        .byte   $06,$0e,$00,$01,$18,$1e,$06
        .byte   $04,$89,$00,$03,$1a,$00
        .byte   $04,$8a,$00,$03,$1c,$00
        .byte   $00

; c3/b7e9
_c3b7e9:
        .byte   $05,$00,$40
        .byte   $06,$0e,$00,$0f,$01,$10,$04
        .byte   $04,$7c,$00,$10,$03,$00
        .byte   $06,$0e,$00,$01,$01,$0a,$04
        .byte   $04,$40,$00,$04,$03,$00
        .byte   $00

; c3/b807
_c3b807:
        .byte   $06,$0e,$00,$00,$00,$1e,$08
        .byte   $03,$0e,$00,$0a,$00,$14,$08
        .byte   $00

; ---------------------------------------------------------------------------

; [ v-scroll hdma tables ]

; each byte is the number of lines before increasing v-scroll by 4

; c3/b816
_c3b816:
        .byte   $07,$1c,$14,$1c,$14,$1c,$14,$1c,$14,$0c,$0c,$00

; c3/b822
_c3b822:
        .byte   $0f,$1c,$74,$0c,$0c,$04,$0c,$0c,$0c,$00

; c3/b82c
_c3b82c:
        .byte   $6f,$70,$00

; c3/b82f
_c3b82f:
        .byte   $0f,$0c,$1c,$04,$04,$0c,$04,$04,$24,$04,$04,$1c,$1c,$0c,$1c,$00

; c3/b83f
_c3b83f:
        .byte   $0f,$0c,$1c,$04,$04,$0c,$04,$1c,$14,$0c,$0c,$04,$1c,$0c,$1c,$00

; c3/b84f
_c3b84f:
        .byte   $27,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$34,$00

; c3/b85c
_c3b85c:
        .byte   $0f,$0c,$84,$04,$3c,$00

; c3/b862
_c3b862:
        .byte   $9f,$04,$04,$1c,$1c,$00

; c3/b868
_c3b868:
        .byte   $07,$04,$0c,$04,$0c,$1c,$0c,$0c,$04,$0c,$0c,$0c,$1c,$0c,$0c,$1c
        .byte   $0c,$00

; c3/b87a: ??? v-scroll hdma table
_c3b87a:
        .byte   $07,$04,$0c,$04,$0c,$1c,$0c,$0c,$04,$0c,$0c,$0c,$1c,$0c,$0c,$1c
        .byte   $0c,$00

; c3/b88c
_c3b88c:
        .byte   $47,$04,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$00

; c3/b89a
_c3b89a:
        .byte   $07,$0c,$24,$4c,$5c,$00

; c3/b8a0
_c3b8a0:
        .byte   $1f,$04,$04,$0c,$0c,$0c,$14,$0c,$0c,$0c,$1c,$0c,$0c,$0c,$1c,$00

; c3/b8b0
_c3b8b0:
        .byte   $57,$2c,$04,$0c,$0c,$14,$0c,$0c,$0c,$04,$00

; c3/b8bb
_c3b8bb:
        .byte   $27,$04,$1c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$1c,$1c,$00

; c3/b8c9
_c3b8c9:
        .byte   $07,$04,$14,$04,$0c,$14,$9c,$00

; c3/b8d1
_c3b8d1:
        .byte   $3f,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$00

; c3/b8e0
_c3b8e0:
        .byte   $07,$14,$0c,$04,$24,$00

; c3/b8e6
_c3b8e6:
        .byte   $07,$04,$0c,$0c,$04,$00

; c3/b8ec
_c3b8ec:
        .byte   $07,$04,$0c,$0c,$2c,$04,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$14
        .byte   $00

; c3/b8fd
_c3b8fd:
        .byte   $0f,$0c,$0c,$2c,$2c,$2c,$2c,$00

; c3/b905
_c3b905:
        .byte   $1f,$0c,$0c,$74,$0c,$04,$0c,$0c,$0c,$00

; c3/b90f
_c3b90f:
        .byte   $07,$04,$14,$04,$2c,$04,$04,$2c,$5c,$00

; c3/b919
_c3b919:
        .byte   $0f,$04,$0c,$00

; c3/b91d
_c3b91d:
        .byte   $07,$04,$14,$04,$0c,$0c,$0c,$04,$04,$0c,$0c,$0c,$04,$04,$0c,$0c
        .byte   $0c,$04,$04,$0c,$0c,$0c,$04,$00

; c3/b935
_c3b935:
        .byte   $1f,$24,$14,$14,$14,$14,$14,$2c,$00

; c3/b93e
_c3b93e:
        .byte   $07,$04,$14,$2c,$0c,$1c,$0c,$1c,$1c,$0c,$1c,$00

; ---------------------------------------------------------------------------

.segment "menu_pal"

; c3/b960
_c3b960:
        .word   $0180,$0000,$7fff,$6739,$5ef7,$318c,$4210,$294a
        .word   $0180,$1084,$0155,$035f,$7e60,$7f80,$7d00,$7fff

        .word   $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
        .word   $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

; c3/b9a0
_c3b9a0:
        .word   $0001,$0112,$102e,$0268,$508c,$007d,$245b,$0024
        .word   $0000,$0001,$0011,$0017,$0873,$3902,$0024,$0000

        .word   $0000,$0090,$10e8,$c02c,$14e2,$807c,$48b4,$0048
        .word   $0000,$0000,$0010,$00d0,$a01c,$3880,$0048,$0000

; c3/b9e0
_c3b9e0:
        .word   $0000,$1084,$0000,$0000,$03ff,$201f,$025f,$5560
        .word   $615f,$017a,$0000,$0000,$0000,$0000,$0000,$0000

; ---------------------------------------------------------------------------

.segment "shop_prop"

; d1/2a00: item prices
ItemPriceTbl:
        .byte   $01,$00,$01,$00,$01,$0f,$01,$1e,$01,$2d,$01,$3c,$01,$5a,$02,$1a
        .byte   $02,$33,$02,$22,$02,$44,$04,$02,$04,$02,$01,$1c,$01,$30,$01,$58
        .byte   $02,$1c,$02,$2a,$02,$54,$02,$38,$02,$6e,$44,$02,$44,$03,$01,$0a
        .byte   $01,$0a,$01,$4f,$02,$1b,$02,$36,$02,$66,$02,$51,$02,$6c,$44,$02
        .byte   $04,$03,$01,$41,$01,$69,$02,$20,$02,$40,$02,$60,$02,$80,$44,$02
        .byte   $44,$03,$02,$3a,$01,$0a,$02,$76,$02,$58,$02,$94,$44,$02,$44,$02
        .byte   $44,$03,$01,$14,$01,$4b,$01,$4b,$01,$4b,$02,$0f,$02,$1e,$04,$02
        .byte   $01,$14,$01,$32,$02,$12,$02,$09,$02,$1b,$04,$02,$04,$03,$02,$19
        .byte   $02,$19,$02,$19,$02,$26,$02,$32,$02,$4b,$44,$02,$44,$03,$02,$08
        .byte   $02,$10,$02,$20,$44,$02,$02,$0b,$02,$21,$02,$16,$04,$02,$02,$2c
        .byte   $01,$32,$03,$09,$44,$02,$02,$0f,$01,$0a,$03,$10,$03,$13,$02,$64
        .byte   $02,$6e,$01,$6e,$42,$19,$43,$19,$00,$02,$03,$0f,$01,$4e,$02,$4e
        .byte   $04,$01,$04,$03,$00,$02,$00,$02,$02,$6e,$02,$0f,$02,$55,$03,$0a
        .byte   $04,$02,$02,$3b,$04,$04,$00,$02,$02,$44,$02,$3a,$04,$02,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$00,$01,$09,$01,$1d,$01,$27,$01,$3b,$02,$1e,$02,$2d,$02,$3c
        .byte   $02,$5a,$01,$05,$01,$19,$01,$23,$01,$37,$02,$23,$02,$46,$02,$69
        .byte   $01,$23,$02,$0f,$02,$1e,$02,$2d,$04,$03,$00,$02,$02,$23,$02,$19
        .byte   $02,$41,$02,$19,$01,$08,$01,$28,$01,$32,$01,$46,$02,$28,$02,$50
        .byte   $03,$0c,$01,$23,$01,$2d,$01,$3c,$02,$1e,$02,$3c,$02,$5a,$01,$1e
        .byte   $01,$32,$02,$14,$02,$0a,$02,$28,$03,$08,$03,$08,$01,$0a,$04,$03
        .byte   $03,$03,$03,$05,$02,$28,$00,$02,$01,$19,$04,$05,$01,$3c,$01,$32
        .byte   $02,$28,$02,$2d,$02,$19,$02,$1e,$04,$05,$04,$05,$04,$05,$00,$02
        .byte   $01,$07,$03,$0f,$02,$1e,$02,$32,$04,$04,$04,$01,$03,$14,$03,$19
        .byte   $03,$1e,$03,$0f,$04,$02,$03,$4b,$00,$02,$04,$04,$00,$02,$02,$3a
        .byte   $02,$62,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$04,$01,$24,$02,$0f,$44,$05,$03,$01,$01,$06,$01,$0f,$01,$0f
        .byte   $01,$03,$01,$02,$03,$05,$45,$01,$01,$0f,$01,$05,$01,$00,$04,$01
        .byte   $01,$19,$01,$3c,$01,$0b,$01,$0b,$01,$0b,$01,$0b,$01,$0b,$80,$02
        .byte   $80,$02,$83,$05,$83,$05,$83,$05,$02,$02,$02,$02,$02,$02,$81,$00

; d1/2c00: magic prices
MagicPriceTbl:
        .byte   $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
        .byte   $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
        .byte   $01,$00,$01,$00,$01,$12,$01,$08,$01,$09,$01,$1c,$01,$1c,$01,$1e
        .byte   $01,$3e,$01,$46,$01,$41,$02,$1e,$02,$1e,$02,$1e,$02,$3c,$02,$3c
        .byte   $02,$3c,$02,$64,$02,$64,$02,$64,$01,$0f,$01,$0f,$01,$0f,$01,$1d
        .byte   $01,$1e,$01,$1e,$01,$3c,$01,$3c,$01,$3c,$02,$1e,$02,$1e,$02,$1e
        .byte   $02,$3c,$02,$3c,$02,$3c,$02,$64,$02,$64,$02,$64,$01,$03,$01,$08
        .byte   $01,$0a,$01,$20,$01,$20,$01,$1e,$01,$3e,$01,$3a,$01,$3c,$02,$1e
        .byte   $02,$1e,$02,$1e,$02,$3c,$02,$3c,$02,$3c,$02,$64,$02,$64,$02,$64
        .byte   $01,$1e,$01,$23,$01,$19,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a
        .byte   $01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a,$01,$0a

; d1/2d00: shop names
ShopName:
        incbin_lang "src/text/shop_name_%s.dat"

; d1/2d40: shop properties
ShopProp:
        .byte   $01,$0d,$31,$38,$00,$00,$00,$00,$00
        .byte   $02,$81,$89,$9a,$00,$00,$00,$00,$00
        .byte   $03,$e0,$f0,$00,$00,$00,$00,$00,$00
        .byte   $00,$24,$25,$26,$12,$13,$14,$00,$00
        .byte   $01,$03,$0e,$31,$38,$00,$00,$00,$00
        .byte   $02,$82,$8a,$9b,$a1,$a7,$00,$00,$00
        .byte   $03,$e0,$e8,$e9,$e5,$ed,$ec,$e4,$f0
        .byte   $00,$24,$25,$26,$28,$12,$14,$15,$16
        .byte   $01,$21,$0e,$03,$00,$00,$00,$00,$00
        .byte   $02,$83,$8b,$9c,$a2,$a7,$00,$00,$00
        .byte   $00,$37,$38,$39,$3a,$48,$49,$4a,$00
        .byte   $01,$04,$0f,$22,$32,$33,$34,$5e,$00
        .byte   $01,$19,$05,$4b,$50,$00,$00,$00,$00
        .byte   $02,$84,$8c,$90,$9d,$a3,$a8,$b6,$b7
        .byte   $03,$e0,$e8,$e9,$e5,$ed,$ec,$e4,$f0
        .byte   $00,$2a,$2b,$2c,$27,$28,$24,$25,$26
        .byte   $00,$18,$19,$1a,$15,$16,$12,$13,$14
        .byte   $00,$3c,$3d,$3a,$39,$37,$38,$00,$00
        .byte   $01,$3f,$40,$41,$47,$00,$00,$00,$00
        .byte   $02,$90,$aa,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $04,$bd,$be,$bc,$00,$00,$00,$00,$00
        .byte   $02,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$23,$10,$06,$1a,$29,$65,$00,$00
        .byte   $02,$97,$a4,$aa,$00,$00,$00,$00,$00
        .byte   $03,$e2,$e6,$f1,$f2,$f3,$f4,$f5,$f6
        .byte   $05,$05,$5a,$fc,$fd,$fe,$00,$00,$00
        .byte   $02,$97,$a4,$00,$00,$00,$00,$00,$00
        .byte   $00,$1d,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$09,$24,$29,$13,$1b,$42,$48,$4c
        .byte   $02,$85,$8d,$97,$91,$9e,$a4,$a9,$00
        .byte   $03,$e1,$e0,$e4,$ec,$e5,$ed,$e9,$e8
        .byte   $01,$09,$24,$29,$13,$1b,$42,$48,$4c
        .byte   $02,$85,$8d,$97,$91,$9e,$a4,$a9,$c2
        .byte   $01,$08,$43,$35,$5a,$fc,$fd,$fe,$00
        .byte   $02,$96,$b9,$ba,$00,$00,$00,$00,$00
        .byte   $00,$1b,$1c,$1d,$00,$00,$00,$00,$00
        .byte   $00,$2d,$2e,$2f,$00,$00,$00,$00,$00
        .byte   $00,$3f,$40,$41,$00,$00,$00,$00,$00
        .byte   $01,$12,$1d,$2c,$25,$00,$00,$00,$00
        .byte   $02,$85,$8d,$96,$91,$9e,$b9,$a9,$c2
        .byte   $01,$0a,$44,$00,$00,$00,$00,$00,$00
        .byte   $02,$87,$8e,$c3,$92,$9f,$a5,$ab,$b8
        .byte   $00,$1e,$1f,$20,$1b,$1c,$1d,$00,$00
        .byte   $00,$30,$31,$32,$2d,$2e,$2f,$00,$00
        .byte   $00,$42,$43,$44,$3f,$40,$41,$00,$00
        .byte   $01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $83,$e2,$e0,$e8,$e9,$ed,$e5,$ec,$f0
        .byte   $00,$21,$23,$34,$35,$46,$47,$00,$00
        .byte   $01,$26,$5f,$67,$2d,$00,$00,$00,$00
        .byte   $02,$88,$8f,$98,$93,$a0,$a6,$ac,$ad
        .byte   $03,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$57,$58,$26,$5f,$67,$2d,$1c,$00
        .byte   $05,$5b,$5a,$1e,$59,$fc,$fd,$fe,$00
        .byte   $02,$88,$8f,$98,$93,$a0,$a6,$ac,$ad
        .byte   $04,$b5,$bc,$bd,$be,$99,$bb,$00,$00
        .byte   $00,$21,$23,$34,$35,$46,$47,$00,$00
        .byte   $00,$17,$29,$36,$3b,$3e,$48,$49,$4a
        .byte   $03,$e0,$e1,$e4,$e5,$e8,$e9,$ec,$ed
        .byte   $06,$e3,$e2,$e6,$f2,$f3,$f4,$f5,$f6
        .byte   $81,$04,$0f,$22,$32,$33,$34,$5e,$00
        .byte   $82,$84,$8c,$9d,$a3,$a8,$b6,$b7,$00

; ---------------------------------------------------------------------------

.segment "char_stat"

; d1/551e
CharStatMod:
        .byte   4,1,3,1
        .byte   1,2,1,4
        .byte   3,0,4,0
        .byte   3,3,2,2
        .byte   1,4,0,3

; ---------------------------------------------------------------------------

.segment "job_prop"

; d1/56b0: job stat modifiers (22 items, 4 bytes each)
JobStatTbl:
        .byte   $2f,$19,$2c,$0a
        .byte   $32,$19,$32,$01
        .byte   $19,$28,$1a,$12
        .byte   $2a,$1d,$27,$0c
        .byte   $27,$26,$1b,$0e
        .byte   $2b,$1a,$2b,$0c
        .byte   $2d,$0f,$31,$01
        .byte   $28,$24,$19,$13
        .byte   $26,$26,$26,$19
        .byte   $11,$19,$18,$31
        .byte   $0f,$18,$16,$37
        .byte   $13,$1a,$15,$30
        .byte   $0e,$17,$17,$39
        .byte   $10,$19,$1b,$2f
        .byte   $20,$1d,$12,$20
        .byte   $25,$19,$20,$15
        .byte   $1a,$1b,$1e,$14
        .byte   $1c,$1a,$1c,$30
        .byte   $10,$20,$0f,$23
        .byte   $1d,$1d,$0e,$13
        .byte   $18,$18,$18,$18
        .byte   $18,$18,$18,$18

; d1/5708: job equipment types (22 items, 4 bytes each)
JobEquipTbl:
        .byte   $0d,$00,$b3,$01
        .byte   $00,$00,$a4,$02
        .byte   $01,$00,$a4,$06
        .byte   $11,$00,$b3,$01
        .byte   $03,$00,$a4,$02
        .byte   $81,$00,$b3,$01
        .byte   $61,$00,$b3,$01
        .byte   $01,$08,$a4,$02
        .byte   $05,$00,$b3,$01
        .byte   $00,$06,$c0,$12
        .byte   $01,$01,$c0,$12
        .byte   $01,$07,$c0,$12
        .byte   $01,$01,$c0,$12
        .byte   $05,$01,$e5,$12
        .byte   $05,$03,$e4,$12
        .byte   $01,$20,$a4,$02
        .byte   $01,$06,$e4,$1a
        .byte   $01,$40,$c0,$12
        .byte   $01,$10,$c0,$12
        .byte   $01,$00,$ec,$12
        .byte   $01,$03,$f7,$1f
        .byte   $ff,$ff,$ff,$ff

; d1/5760: job default commands (22 items, 4 bytes each)
JobCmdTbl:
        .byte   $05,$06,$00,$02
        .byte   $05,$07,$00,$02
        .byte   $05,$0b,$00,$02
        .byte   $05,$0d,$00,$02
        .byte   $05,$11,$00,$02
        .byte   $05,$13,$00,$02
        .byte   $05,$00,$00,$02
        .byte   $05,$16,$00,$02
        .byte   $05,$31,$00,$02
        .byte   $05,$37,$00,$02
        .byte   $05,$3d,$00,$02
        .byte   $05,$43,$00,$02
        .byte   $05,$48,$00,$02
        .byte   $05,$4d,$00,$02
        .byte   $05,$4b,$00,$02
        .byte   $05,$1d,$00,$02
        .byte   $05,$20,$00,$02
        .byte   $05,$23,$00,$02
        .byte   $05,$28,$00,$02
        .byte   $05,$2a,$00,$02
        .byte   $2b,$00,$00,$00
        .byte   $05,$00,$00,$02

; d1/57b8: job passive abilities (22 items, 2 bytes each)
JobPassiveAbilityTbl:
        .byte   $00,$80
        .byte   $80,$40
        .byte   $09,$04
        .byte   $00,$00
        .byte   $00,$03
        .byte   $40,$00
        .byte   $00,$08
        .byte   $00,$00
        .byte   $20,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $10,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$10
        .byte   $06,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00

; ---------------------------------------------------------------------------
