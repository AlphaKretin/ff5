.list off
.ifndef SONG_SCRIPT_INC
SONG_SCRIPT_INC = 1

.global SongScript, SongScriptPtrs

; song ids
.enum SONG
        AHEAD_ON_OUR_WAY                ; $00
        THE_FIERCE_BATTLE               ; $01
        A_PRESENTIMENT                  ; $02
        GO_GO_BOKO                      ; $03
        PIRATES_AHOY                    ; $04
        TENDERNESS_IN_THE_AIR           ; $05
        FATE_IN_HAZE                    ; $06
        CRITTER_TRIPPER_FRITTER         ; $07
        THE_PRELUDE                     ; $08
        THE_LAST_BATTLE                 ; $09
        REQUIEM                         ; $0a
        NOSTALGIA                       ; $0b
        CURSED_EARTHS                   ; $0c
        LENNAS_THEME                    ; $0d
        VICTORYS_FANFARE                ; $0e
        DECEPTION                       ; $0f
        THE_DAY_WILL_COME               ; $10
        SILENCE                         ; $11
        EXDEATHS_CASTLE                 ; $12
        MY_HOME_SWEET_HOME              ; $13
        WALTZ_SUOMI                     ; $14
        SEALED_AWAY                     ; $15
        THE_FOUR_WARRIORS_OF_DAWN       ; $16
        DANGER                          ; $17
        THE_FIREPOWERED_SHIP            ; $18
        AS_I_FEEL_YOU_FEEL              ; $19
        MAMBO_DE_CHOCOBO                ; $1a
        MUSIC_BOX_SONG                  ; $1b
        INTENSION_OF_THE_EARTH          ; $1c
        THE_DRAGON_SPREADS_ITS_WINGS    ; $1d
        BEYOND_THE_DEEP_BLUE_SEA        ; $1e
        PRELUDE_OF_EMPTY_SKIES          ; $1f
        SEARCHING_FOR_THE_LIGHT         ; $20
        HARVEST                         ; $21
        GILGAMESH                       ; $22
        FOUR_VALIANT_HEARTS             ; $23
        THE_BOOK_OF_SEALINGS            ; $24
        WHAT                            ; $25
        HURRY_HURRY                     ; $26
        UNKNOWN_LANDS                   ; $27
        THE_AIRSHIP                     ; $28
        FANFARE_1                       ; $29
        FANFARE_2                       ; $2a
        THE_BATTLE                      ; $2b
        WALKING_THE_SNOWY_MOUNTAINS     ; $2c
        THE_EVIL_LORD_EXDEATH           ; $2d
        THE_CASTLE_OF_DAWN              ; $2e
        IM_A_DANCER                     ; $2f
        REMINISCENCE                    ; $30
        RUN                             ; $31
        THE_ANCIENT_LIBRARY             ; $32
        ROYAL_PALACE                    ; $33
        GOOD_NIGHT                      ; $34
        PIANO_LESSON_1                  ; $35
        PIANO_LESSON_2                  ; $36
        PIANO_LESSON_3                  ; $37
        PIANO_LESSON_4                  ; $38
        PIANO_LESSON_5                  ; $39
        PIANO_LESSON_6                  ; $3a
        PIANO_LESSON_7                  ; $3b
        PIANO_LESSON_8                  ; $3c
        MUSICA_MACHINA                  ; $3d
        A_METEOR_IS_FALLING             ; $3e
        THE_LAND_UNKNOWN                ; $3f
        THE_DECISIVE_BATTLE             ; $40
        THE_SILENT_BEYOND               ; $41
        DEAR_FRIENDS                    ; $42
        FINAL_FANTASY                   ; $43
        A_NEW_ORIGIN                    ; $44
        CRICKETS_CHIRPING               ; $45
        A_SHORE                         ; $46
        THE_TIDE_ROLLS_IN               ; $47
.endenum

.scope SongScript

; ##############################################################################
; ###          AUTOMATICALLY GENERATED CODE, DO NOT MODIFY MANUALLY          ###
; ##############################################################################

        ARRAY_LENGTH = 72

        _0 := SongScript + 0
        _1 := SongScript + 1426
        _2 := SongScript + 3020
        _3 := SongScript + 5231
        _4 := SongScript + 6453
        _5 := SongScript + 7597
        _6 := SongScript + 8550
        _7 := SongScript + 9701
        _8 := SongScript + 10491
        _9 := SongScript + 11504
        _10 := SongScript + 14517
        _11 := SongScript + 14775
        _12 := SongScript + 15257
        _13 := SongScript + 16346
        _14 := SongScript + 17045
        _15 := SongScript + 17685
        _16 := SongScript + 18172
        _17 := SongScript + 18825
        _18 := SongScript + 18853
        _19 := SongScript + 19567
        _20 := SongScript + 20575
        _21 := SongScript + 22270
        _22 := SongScript + 23482
        _23 := SongScript + 24407
        _24 := SongScript + 24985
        _25 := SongScript + 25809
        _26 := SongScript + 26353
        _27 := SongScript + 27434
        _28 := SongScript + 27848
        _29 := SongScript + 29468
        _30 := SongScript + 30425
        _31 := SongScript + 54960
        _32 := SongScript + 31377
        _33 := SongScript + 32786
        _34 := SongScript + 34899
        _35 := SongScript + 37497
        _36 := SongScript + 53544
        _37 := SongScript + 39019
        _38 := SongScript + 48827
        _39 := SongScript + 39388
        _40 := SongScript + 40891
        _41 := SongScript + 42189
        _42 := SongScript + 42447
        _43 := SongScript + 55882
        _44 := SongScript + 42866
        _45 := SongScript + 43660
        _46 := SongScript + 44706
        _47 := SongScript + 45861
        _48 := SongScript + 46263
        _49 := SongScript + 46840
        _50 := SongScript + 48066
        _51 := SongScript + 49622
        _52 := SongScript + 50958
        _53 := SongScript + 52604
        _54 := SongScript + 51091
        _55 := SongScript + 52774
        _56 := SongScript + 51299
        _57 := SongScript + 53275
        _58 := SongScript + 52986
        _59 := SongScript + 51784
        _60 := SongScript + 52195
        _61 := SongScript + 54446
        _62 := SongScript + 57251
        _63 := SongScript + 57798
        _64 := SongScript + 59226
        _65 := SongScript + 713240
        _66 := SongScript + 62867
        _67 := SongScript + 64477
        _68 := SongScript + 66140
        _69 := SongScript + 71434
        _70 := SongScript + 71644
        _71 := SongScript + 71702

; ##############################################################################

.endscope

.endif
.list on
