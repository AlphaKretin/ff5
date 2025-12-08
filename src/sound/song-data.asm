; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: sound/song-data.asm                                               |
; |                                                                         |
; | description: background music data                                      |
; +-------------------------------------------------------------------------+

; c4/3b97: pointers to song scripts
SongScriptPtrs:
        ptr_tbl_far SongScript

; c4/3c6f: pointers to instrument brr samples
SampleBRRPtrs:
        ptr_tbl_far SampleBRR

; c4/3cd8
SampleLoopStart:
        .word   $0a8c           ; BASS_DRUM
        .word   $0bd9           ; SNARE
        .word   $1194           ; HARD_SNARE
        .word   $05fa           ; CYMBAL
        .word   $15f9           ; TOM
        .word   $0465           ; CLOSED_HIHAT
        .word   $1194           ; OPEN_HIHAT
        .word   $1194           ; TIMPANI
        .word   $04f5           ; VIBRAPHONE
        .word   $029a           ; MARIMBA
        .word   $08f7           ; STRINGS
        .word   $02c7           ; CHOIR
        .word   $034e           ; HARP
        .word   $04da           ; TRUMPET
        .word   $0252           ; OBOE
        .word   $0489           ; FLUTE
        .word   $0936           ; ORGAN
        .word   $0642           ; PIANO
        .word   $0144           ; ELECTRIC_BASS
        .word   $044a           ; BASS_GUITAR
        .word   $05bb           ; GRAND_PIANO
        .word   $0666           ; MUSIC_BOX_INSTR
        .word   $1194           ; WOO
        .word   $09bd           ; METAL_SYSTEM
        .word   $0384           ; SYNTH_CHORD
        .word   $05bb           ; DIST_GUITAR
        .word   $092d           ; KRABI
        .word   $15f9           ; HORN
        .word   $0318           ; MANDOLIN
        .word   $077d           ; UNKNOWN_1
        .word   $08dc           ; CONGA
        .word   $088d           ; CASABA
        .word   $09e1           ; KLAVES
        .word   $0e7c           ; UNKNOWN_2
        .word   $0b6d           ; HAND_CLAP

; ---------------------------------------------------------------------------

; c4/3d1e
SampleFreqMult:
        .byte   $c0,$00         ; BASS_DRUM
        .byte   $00,$00         ; SNARE
        .byte   $c0,$00         ; HARD_SNARE
        .byte   $00,$00         ; CYMBAL
        .byte   $60,$00         ; TOM
        .byte   $00,$00         ; CLOSED_HIHAT
        .byte   $00,$00         ; OPEN_HIHAT
        .byte   $fb,$00         ; TIMPANI
        .byte   $fe,$48         ; VIBRAPHONE
        .byte   $e0,$a0         ; MARIMBA
        .byte   $00,$7c         ; STRINGS
        .byte   $fd,$00         ; CHOIR
        .byte   $51,$00         ; HARP
        .byte   $fe,$00         ; TRUMPET
        .byte   $e0,$90         ; OBOE
        .byte   $fc,$60         ; FLUTE
        .byte   $fc,$7f         ; ORGAN
        .byte   $ff,$00         ; PIANO
        .byte   $fc,$c0         ; ELECTRIC_BASS
        .byte   $fc,$a0         ; BASS_GUITAR
        .byte   $fc,$d0         ; GRAND_PIANO
        .byte   $ff,$a0         ; MUSIC_BOX_INSTR
        .byte   $00,$00         ; WOO
        .byte   $00,$00         ; METAL_SYSTEM
        .byte   $00,$00         ; SYNTH_CHORD
        .byte   $00,$00         ; DIST_GUITAR
        .byte   $fe,$00         ; KRABI
        .byte   $e0,$b0         ; HORN
        .byte   $fc,$90         ; MANDOLIN
        .byte   $e0,$c0         ; UNKNOWN_1
        .byte   $00,$00         ; CONGA
        .byte   $00,$00         ; CASABA
        .byte   $0e,$00         ; KLAVES
        .byte   $00,$00         ; UNKNOWN_2
        .byte   $00,$00         ; HAND_CLAP

; ---------------------------------------------------------------------------

; c4/3d64
SampleADSR:
        make_adsr 15,15,7,0    ; BASS_DRUM
        make_adsr 15,15,7,0    ; SNARE
        make_adsr 15,15,7,0    ; HARD_SNARE
        make_adsr 15,15,7,16   ; CYMBAL
        make_adsr 15,15,7,0    ; TOM
        make_adsr 15,15,7,0    ; CLOSED_HIHAT
        make_adsr 15,15,7,0    ; OPEN_HIHAT
        make_adsr 15,15,7,0    ; TIMPANI
        make_adsr 15,15,7,16   ; VIBRAPHONE
        make_adsr 15,15,7,21   ; MARIMBA
        make_adsr 15,15,7,0    ; STRINGS
        make_adsr 15,15,7,0    ; CHOIR
        make_adsr 15,15,7,18   ; HARP
        make_adsr 15,15,7,1    ; TRUMPET
        make_adsr 15,15,7,1    ; OBOE
        make_adsr 15,15,7,1    ; FLUTE
        make_adsr 15,15,7,0    ; ORGAN
        make_adsr 15,15,7,13   ; PIANO
        make_adsr 15,15,7,0    ; ELECTRIC_BASS
        make_adsr 15,15,7,12   ; BASS_GUITAR
        make_adsr 15,15,7,10   ; GRAND_PIANO
        make_adsr 15,15,7,19   ; MUSIC_BOX_INSTR
        make_adsr 15,15,7,0    ; WOO
        make_adsr 15,15,7,10   ; METAL_SYSTEM
        make_adsr 15,15,7,10   ; SYNTH_CHORD
        make_adsr 15,15,7,8    ; DIST_GUITAR
        make_adsr 15,15,7,19   ; KRABI
        make_adsr 15,15,7,1    ; HORN
        make_adsr 15,15,7,17   ; MANDOLIN
        make_adsr 15,15,7,20   ; UNKNOWN_1
        make_adsr 15,15,7,19   ; CONGA
        make_adsr 15,15,7,0    ; CASABA
        make_adsr 15,15,7,0    ; KLAVES
        make_adsr 15,15,7,0    ; UNKNOWN_2
        make_adsr 15,15,7,0    ; HAND_CLAP

; ---------------------------------------------------------------------------

; [ make song sample list ]

_song_sample_seq .set 0

.macro add_sample sample_id
        ; use the sample id plus 1 (zero means no sample)
        .word SAMPLE_BRR::sample_id + 1
.endmac

.macro song_sample_list
        ; save the start position for this song's samples
        .ident(.sprintf("_song_sample_%d", _song_sample_seq)) := *
.endmac

.macro end_song_sample_list
        ; fill remaining space with zeroes (32 bytes total)
        .res 32 + .ident(.sprintf("_song_sample_%d", _song_sample_seq)) - *, 0
        _song_sample_seq .set _song_sample_seq + 1
.endmac

; ------------------------------------------------------------------------------

; c4/3daa

SongSamples:

; 00 Ahead on Our Way
        song_sample_list
        add_sample OBOE
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample BASS_DRUM
        add_sample SNARE
        add_sample HARP
        add_sample CYMBAL
        end_song_sample_list

; 01 The Fierce Battle
        song_sample_list
        add_sample TIMPANI
        add_sample TRUMPET
        add_sample BASS_GUITAR
        add_sample STRINGS
        add_sample CYMBAL
        add_sample SNARE
        end_song_sample_list

; 02 A Presentiment
        song_sample_list
        add_sample OBOE
        add_sample FLUTE
        add_sample STRINGS
        add_sample GRAND_PIANO
        add_sample HORN
        add_sample MUSIC_BOX_INSTR
        add_sample CHOIR
        add_sample SYNTH_CHORD
        add_sample CYMBAL
        end_song_sample_list

; 03 Go Go Boko!
        song_sample_list
        add_sample OBOE
        add_sample MARIMBA
        add_sample BASS_GUITAR
        add_sample TRUMPET
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample BASS_DRUM
        add_sample SNARE
        add_sample TOM
        end_song_sample_list

; 04 Pirates Ahoy!
        song_sample_list
        add_sample OBOE
        add_sample FLUTE
        add_sample TRUMPET
        add_sample MANDOLIN
        add_sample BASS_GUITAR
        add_sample TIMPANI
        end_song_sample_list

; 05 Tenderness in the Air
        song_sample_list
        add_sample HARP
        add_sample OBOE
        add_sample HORN
        add_sample STRINGS
        add_sample MANDOLIN
        end_song_sample_list

; 06 Fate in Haze
        song_sample_list
        add_sample FLUTE
        add_sample HARP
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample TOM
        add_sample CASABA
        add_sample CONGA
        add_sample CYMBAL
        end_song_sample_list

; 07 Critter Tripper Fritter!
        song_sample_list
        add_sample OBOE
        add_sample FLUTE
        add_sample MARIMBA
        add_sample TIMPANI
        add_sample BASS_GUITAR
        end_song_sample_list

; 08 The Prelude
        song_sample_list
        add_sample HARP
        add_sample STRINGS
        add_sample OBOE
        add_sample HORN
        end_song_sample_list

; 09 The Last Battle
        song_sample_list
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample FLUTE
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample BASS_DRUM
        add_sample HARD_SNARE
        end_song_sample_list

; 0A Requiem
        song_sample_list
        add_sample FLUTE
        add_sample STRINGS
        end_song_sample_list

; 0B Nostalgia
        song_sample_list
        add_sample PIANO
        add_sample CHOIR
        add_sample STRINGS
        add_sample MUSIC_BOX_INSTR
        end_song_sample_list

; 0C Cursed Earths
        song_sample_list
        add_sample OBOE
        add_sample STRINGS
        add_sample GRAND_PIANO
        add_sample TOM
        add_sample TIMPANI
        add_sample METAL_SYSTEM
        end_song_sample_list

; 0D Lenna's Theme
        song_sample_list
        add_sample FLUTE
        add_sample STRINGS
        add_sample MUSIC_BOX_INSTR
        add_sample BASS_GUITAR
        add_sample VIBRAPHONE
        end_song_sample_list

; 0E Victory's Fanfare
        song_sample_list
        add_sample TRUMPET
        add_sample BASS_GUITAR
        add_sample SNARE
        add_sample BASS_DRUM
        add_sample ORGAN
        end_song_sample_list

; 0F Deception
        song_sample_list
        add_sample HARP
        add_sample STRINGS
        add_sample FLUTE
        end_song_sample_list

; 10 The Day will Come
        song_sample_list
        add_sample OBOE
        add_sample HARP
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample CHOIR
        end_song_sample_list

; 11 ...silence
        song_sample_list
        end_song_sample_list

; 12 Exdeath's Castle
        song_sample_list
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample TRUMPET
        add_sample ORGAN
        add_sample CYMBAL
        add_sample TIMPANI
        end_song_sample_list

; 13 My Home, Sweet Home
        song_sample_list
        add_sample FLUTE
        add_sample PIANO
        add_sample STRINGS
        add_sample MANDOLIN
        end_song_sample_list

; 14 Waltz Suomi
        song_sample_list
        add_sample STRINGS
        add_sample FLUTE
        add_sample OBOE
        add_sample SNARE
        add_sample HORN
        add_sample TIMPANI
        end_song_sample_list

; 15 Sealed Away
        song_sample_list
        add_sample OBOE
        add_sample KLAVES
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample TIMPANI
        add_sample KRABI
        add_sample HARP
        add_sample HORN
        end_song_sample_list

; 16 The Four Warriors of Dawn
        song_sample_list
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample TIMPANI
        add_sample SNARE
        add_sample CYMBAL
        end_song_sample_list

; 17 Danger!
        song_sample_list
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample BASS_DRUM
        add_sample HARD_SNARE
        end_song_sample_list

; 18 The Fire-Powered Ship
        song_sample_list
        add_sample BASS_GUITAR
        add_sample STRINGS
        add_sample SNARE
        add_sample TRUMPET
        add_sample CYMBAL
        end_song_sample_list

; 19 As I Feel, You Feel
        song_sample_list
        add_sample STRINGS
        add_sample OBOE
        add_sample HARP
        add_sample FLUTE
        end_song_sample_list

; 1A Mambo de Chocobo!
        song_sample_list
        add_sample TRUMPET
        add_sample UNKNOWN_1
        add_sample BASS_GUITAR
        add_sample KLAVES
        add_sample WOO
        add_sample CASABA
        add_sample UNKNOWN_2
        add_sample CONGA
        end_song_sample_list

; 1B Music Box
        song_sample_list
        add_sample MUSIC_BOX_INSTR
        end_song_sample_list

; 1C Intension of the Earth
        song_sample_list
        add_sample OBOE
        add_sample HARP
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample ELECTRIC_BASS
        add_sample KLAVES
        add_sample CYMBAL
        end_song_sample_list

; 1D The Dragon Spreads its Wings
        song_sample_list
        add_sample TRUMPET
        add_sample HARP
        add_sample BASS_GUITAR
        add_sample STRINGS
        add_sample CLOSED_HIHAT
        add_sample BASS_DRUM
        add_sample SNARE
        end_song_sample_list

; 1E Beyond the Deep Blue Sea
        song_sample_list
        add_sample FLUTE
        add_sample HARP
        add_sample STRINGS
        end_song_sample_list

; 1F Prelude of Empty Skies
        song_sample_list
        add_sample BASS_DRUM
        add_sample BASS_GUITAR
        add_sample STRINGS
        add_sample TRUMPET
        add_sample FLUTE
        add_sample KLAVES
        add_sample HAND_CLAP
        add_sample CYMBAL
        end_song_sample_list

; 20 Searching the Light
        song_sample_list
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample SNARE
        add_sample CYMBAL
        add_sample TIMPANI
        end_song_sample_list

; 21 Harvest
        song_sample_list
        add_sample OBOE
        add_sample HAND_CLAP
        add_sample FLUTE
        add_sample ELECTRIC_BASS
        add_sample MANDOLIN
        add_sample TOM
        end_song_sample_list

; 22 Gilgamesh
        song_sample_list
        add_sample ORGAN
        add_sample TRUMPET
        add_sample BASS_GUITAR
        add_sample DIST_GUITAR
        add_sample CYMBAL
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample BASS_DRUM
        add_sample HARD_SNARE
        add_sample TOM
        end_song_sample_list

; 23 Four Valiant Hearts
        song_sample_list
        add_sample FLUTE
        add_sample STRINGS
        add_sample TIMPANI
        add_sample BASS_GUITAR
        add_sample SNARE
        add_sample HARP
        add_sample CYMBAL
        add_sample HORN
        add_sample TRUMPET
        end_song_sample_list

; 24 The Book of Sealings
        song_sample_list
        add_sample HARP
        add_sample VIBRAPHONE
        add_sample METAL_SYSTEM
        add_sample CHOIR
        add_sample CONGA
        add_sample STRINGS
        add_sample MANDOLIN
        add_sample CYMBAL
        end_song_sample_list

; 25 What?
        song_sample_list
        add_sample TOM
        add_sample CONGA
        add_sample CASABA
        add_sample BASS_GUITAR
        add_sample VIBRAPHONE
        add_sample WOO
        end_song_sample_list

; 26 Hurry! Hurry!
        song_sample_list
        add_sample STRINGS
        add_sample KRABI
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample CONGA
        add_sample BASS_DRUM
        add_sample SNARE
        add_sample VIBRAPHONE
        add_sample BASS_GUITAR
        add_sample CYMBAL
        end_song_sample_list

; 27 Unknown Lands
        song_sample_list
        add_sample FLUTE
        add_sample STRINGS
        add_sample HARP
        add_sample BASS_GUITAR
        add_sample OPEN_HIHAT
        add_sample CLOSED_HIHAT
        add_sample BASS_DRUM
        add_sample HARD_SNARE
        add_sample SNARE
        end_song_sample_list

; 28 The Airship
        song_sample_list
        add_sample FLUTE
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample TIMPANI
        add_sample BASS_DRUM
        add_sample SNARE
        end_song_sample_list

; 29 Fanfare #1
        song_sample_list
        add_sample TRUMPET
        add_sample TIMPANI
        add_sample CYMBAL
        add_sample STRINGS
        end_song_sample_list

; 2A Fanfare #2
        song_sample_list
        add_sample TRUMPET
        add_sample STRINGS
        add_sample FLUTE
        add_sample CYMBAL
        add_sample SNARE
        add_sample TIMPANI
        end_song_sample_list

; 2B The Battle
        song_sample_list
        add_sample STRINGS
        add_sample TRUMPET
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample BASS_DRUM
        add_sample SNARE
        add_sample VIBRAPHONE
        end_song_sample_list

; 2C Walking the Snowy Mountains
        song_sample_list
        add_sample TRUMPET
        add_sample ORGAN
        add_sample MANDOLIN
        add_sample BASS_GUITAR
        add_sample DIST_GUITAR
        add_sample CYMBAL
        add_sample CLOSED_HIHAT
        add_sample OPEN_HIHAT
        add_sample BASS_DRUM
        add_sample SNARE
        add_sample SYNTH_CHORD
        end_song_sample_list

; 2D The Evil Lord, Exdeath
        song_sample_list
        add_sample STRINGS
        add_sample CHOIR
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample BASS_DRUM
        add_sample HARD_SNARE
        add_sample DIST_GUITAR
        end_song_sample_list

; 2E The Castle of Dawn
        song_sample_list
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample HORN
        add_sample SNARE
        add_sample CYMBAL
        end_song_sample_list

; 2F I'm a Dancer
        song_sample_list
        add_sample BASS_GUITAR
        add_sample TRUMPET
        add_sample MANDOLIN
        add_sample KLAVES
        add_sample HAND_CLAP
        end_song_sample_list

; 30 Reminiscence
        song_sample_list
        end_song_sample_list

; 31 Run!
        song_sample_list
        add_sample TRUMPET
        add_sample STRINGS
        add_sample FLUTE
        add_sample MARIMBA
        add_sample TIMPANI
        add_sample CYMBAL
        add_sample HORN
        add_sample SNARE
        end_song_sample_list

; 32 The Ancient Library
        song_sample_list
        add_sample TOM
        add_sample OPEN_HIHAT
        add_sample SNARE
        add_sample UNKNOWN_2
        add_sample KLAVES
        add_sample STRINGS
        add_sample BASS_GUITAR
        end_song_sample_list

; 33 Royal Palace
        song_sample_list
        add_sample OBOE
        add_sample TRUMPET
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample HARP
        add_sample SNARE
        add_sample TIMPANI
        add_sample VIBRAPHONE
        end_song_sample_list

; 34 Good Night!
        song_sample_list
        end_song_sample_list

; 35 Piano lesson 1
        song_sample_list
        add_sample VIBRAPHONE
        add_sample KLAVES
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

; 36 Piano lesson 2
        song_sample_list
        add_sample VIBRAPHONE
        add_sample KLAVES
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

; 37 Piano lesson 3
        song_sample_list
        add_sample VIBRAPHONE
        add_sample KLAVES
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

;38 Piano lesson 4
        song_sample_list
        add_sample VIBRAPHONE
        add_sample KLAVES
        add_sample VIBRAPHONE
        add_sample UNKNOWN_2
        add_sample ORGAN
        end_song_sample_list

; 39 Piano lesson 5
        song_sample_list
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

; 3A Piano lesson 6
        song_sample_list
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

; 3B Piano lesson 7
        song_sample_list
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

; 3C Piano lesson 8
        song_sample_list
        add_sample VIBRAPHONE
        add_sample ORGAN
        end_song_sample_list

; 3D Musica Machina
        song_sample_list
        add_sample TIMPANI
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample STRINGS
        add_sample TRUMPET
        add_sample FLUTE
        end_song_sample_list

; 3E (a meteor is falling)
        song_sample_list
        end_song_sample_list

; 3F The Land Unknown
        song_sample_list
        add_sample MANDOLIN
        add_sample HARP
        add_sample CHOIR
        add_sample STRINGS
        add_sample BASS_GUITAR
        add_sample FLUTE
        add_sample BASS_DRUM
        add_sample CASABA
        add_sample VIBRAPHONE
        add_sample KLAVES
        end_song_sample_list

; 40 The Decisive Battle
        song_sample_list
        add_sample STRINGS
        add_sample TRUMPET
        add_sample TOM
        add_sample BASS_GUITAR
        add_sample CYMBAL
        add_sample SNARE
        add_sample OPEN_HIHAT
        add_sample CLOSED_HIHAT
        add_sample BASS_DRUM
        add_sample DIST_GUITAR
        end_song_sample_list

; 41 The Silent Beyond
        song_sample_list
        add_sample FLUTE
        add_sample OBOE
        add_sample HARP
        add_sample BASS_GUITAR
        add_sample STRINGS
        end_song_sample_list

; 42 Dear Friends
        song_sample_list
        add_sample MANDOLIN
        add_sample FLUTE
        end_song_sample_list

; 43 Final Fantasy
        song_sample_list
        add_sample HORN
        add_sample STRINGS
        add_sample HARP
        add_sample MUSIC_BOX_INSTR
        add_sample FLUTE
        add_sample VIBRAPHONE
        end_song_sample_list

; 44 A New Origin
        song_sample_list
        add_sample STRINGS
        add_sample TRUMPET
        add_sample HORN
        add_sample CYMBAL
        add_sample SNARE
        add_sample TIMPANI
        add_sample FLUTE
        add_sample HARP
        end_song_sample_list

; 45 (crickets chirping)
        song_sample_list
        end_song_sample_list

; 46 a shore
        song_sample_list
        end_song_sample_list

; 47 the tide rolls in
        song_sample_list
        end_song_sample_list

; ---------------------------------------------------------------------------

; c4/46aa
SampleBRR:
        .incbin "sample_brr.dat"

; ---------------------------------------------------------------------------

; c5/e5e8
SongScript:
        .incbin "song_script.dat"

; ---------------------------------------------------------------------------

.segment "song_script_41"

; d0/c800
        .incbin "song_script_41.dat"

; ---------------------------------------------------------------------------

.segment "sample_brr_33"

; d4/f000
        .incbin "sample_brr_33.dat"

.segment "sample_brr_2f"

; db/f800
        .incbin "sample_brr_2f.dat"

; ---------------------------------------------------------------------------