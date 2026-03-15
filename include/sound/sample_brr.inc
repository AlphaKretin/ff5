.list off
.ifndef SAMPLE_BRR_INC
SAMPLE_BRR_INC = 1

.global SampleBRR, SampleBRRPtrs

; instrument sample ids
.enum SAMPLE_BRR
    BASS_DRUM       ; $01
    SNARE           ; $02
    HARD_SNARE      ; $03
    CYMBAL          ; $04
    TOM             ; $05
    CLOSED_HIHAT    ; $06
    OPEN_HIHAT      ; $07
    TIMPANI         ; $08
    VIBRAPHONE      ; $09
    MARIMBA         ; $0a
    STRINGS         ; $0b
    CHOIR           ; $0c
    HARP            ; $0d
    TRUMPET         ; $0e
    OBOE            ; $0f
    FLUTE           ; $10
    ORGAN           ; $11
    PIANO           ; $12
    ELECTRIC_BASS   ; $13
    BASS_GUITAR     ; $14
    GRAND_PIANO     ; $15
    MUSIC_BOX_INSTR ; $16
    WOO             ; $17
    METAL_SYSTEM    ; $18
    SYNTH_CHORD     ; $19
    DIST_GUITAR     ; $1a
    KRABI           ; $1b
    HORN            ; $1c
    MANDOLIN        ; $1d
    UNKNOWN_1       ; $1e
    CONGA           ; $1f
    CASABA          ; $20
    KLAVES          ; $21
    UNKNOWN_2       ; $22
    HAND_CLAP       ; $23
.endenum

.scope SampleBRR

; ##############################################################################
; ###          AUTOMATICALLY GENERATED CODE, DO NOT MODIFY MANUALLY          ###
; ##############################################################################

        ARRAY_LENGTH = 35

        _0 := SampleBRR + 0
        _1 := SampleBRR + 2702
        _2 := SampleBRR + 5737
        _3 := SampleBRR + 10239
        _4 := SampleBRR + 13904
        _5 := SampleBRR + 19531
        _6 := SampleBRR + 20658
        _7 := SampleBRR + 25160
        _8 := SampleBRR + 29662
        _9 := SampleBRR + 32337
        _10 := SampleBRR + 33041
        _11 := SampleBRR + 41107
        _12 := SampleBRR + 44655
        _13 := SampleBRR + 45530
        _14 := SampleBRR + 47467
        _15 := SampleBRR + 48099
        _16 := SampleBRR + 49586
        _17 := SampleBRR + 52432
        _18 := SampleBRR + 56799
        _19 := SampleBRR + 57287
        _20 := SampleBRR + 58711
        _21 := SampleBRR + 60504
        _22 := SampleBRR + 63494
        _23 := SampleBRR + 67996
        _24 := SampleBRR + 76305
        _25 := SampleBRR + 82121
        _26 := SampleBRR + 84967
        _27 := SampleBRR + 89109
        _28 := SampleBRR + 94772
        _29 := SampleBRR + 1552726
        _30 := SampleBRR + 95647
        _31 := SampleBRR + 98655
        _32 := SampleBRR + 100844
        _33 := SampleBRR + 1091926
        _34 := SampleBRR + 103375

; ##############################################################################

.endscope

.endif
.list on