; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: sound/spc/spc-ram.inc                                             |
; |                                                                         |
; | description: spc-700 ram definitions                                    |
; |                                                                         |
; | created: 10/4/2020                                                      |
; +-------------------------------------------------------------------------+

.include "macros.inc"

; ---------------------------------------------------------------------------

; zero page
        ram_org $0000

        ram_word zZero                  ; $00
        ram_byte z02                    ; $02
        ram_byte z03                    ; $03
        ram_byte zChParam               ; $04 channel script parameter
        ram_byte zChPtr                 ; $05 channel pointer (channel id * 2)
        ram_word zScriptOffset          ; $06
        ram_word zPitchFreq             ; $08 calculated pitch frequency
        ram_word zNotePitchConst        ; $0a pitch constant for the note
        ram_res 32, zScriptPtr          ; $0c-$2b script pointer
        ram_word zIntAddr               ; $2c
        ram_word zMoveDest              ; $2e
        ram_res 4                       ; $2f-$33

        ram_byte zScratch0              ; $34
        ram_byte zScratch1              ; $35
        ram_byte zScratch2              ; $36
        ram_byte zScratch3              ; $37
        ram_byte zScratch4              ; $38
        ram_byte zScratch5              ; $39
        ram_byte zScratch6              ; $3a
        ram_byte zScratch7              ; $3b

        ram_byte zTickCounter           ; $3c channel tick counter
        ram_byte zChOctave              ; $3d channel octave
        ram_res 30                      ; $3e-$5b
        ram_byte zRepeatDepth           ; $5c channel repeat depth
        ram_byte zChSample              ; $5d channel sample
        ram_res 30                      ; $5e-$7b
        ram_word zTempo                 ; $7c song tempo
        ram_byte zSongTickCounter       ; $7e song tick counter
        ram_byte zSfxTickCounter        ; $7f sfx tick counter
        ram_byte zTempoCounter          ; $80 tempo envelope counter
        ram_word zTempoRate             ; $81 tempo envelope rate
        ram_word zAbsVol                ; $83 absolute (master) volume
        ram_word zSfxVol                ; $85 game sfx volume
        ram_word zAbsVolRate            ; $87 master volume envelope rate
        ram_word zSfxVolRate            ; $89 sfx volume envelope rate
        ram_byte zAbsVolCounter         ; $8b master volume envelope counter
        ram_byte z8c                    ; $8c unused
        ram_byte zSfxVolCounter         ; $8d sfx volume envelope counter
        ram_byte z8e                    ; $8e unused
        ram_word zRelVol                ; $8f relative volume (multiplier)
        ram_word zSfxRelVol             ; $91
        ram_word zRelVolRate            ; $93 relative volume rate
        ram_word zSfxRelVolRate         ; $95
        ram_byte zRelVolCounter         ; $97 relative volume counter
        ram_byte z98                    ; $98 unused
        ram_byte zSfxRelVolCounter      ; $99
        ram_byte z9a                    ; $9a unused
        ram_word zRelTempoMult          ; $9b relative tempo (multiplier)
        ram_word zSfxTempoMult          ; $9d sfx tempo (multiplier)
        ram_word zRelTempoRate          ; $9f relative tempo rate
        ram_word zSfxTempoRate          ; $a1 sfx tempo rate
        ram_byte zRelTempoCounter       ; $a3 relative tempo counter
        ram_byte za4                    ; $a4 unused
        ram_byte zSfxTempoCounter       ; $a5 sfx tempo multiplier counter
        ram_byte za6                    ; $a6 unused
        ram_word zRelPitchMult          ; $a7 relative pitch
        ram_word zSfxPitchMult          ; $a9
        ram_word zRelPitchRate          ; $ab
        ram_word zSfxPitchRate          ; $ad
        ram_byte zRelPitchCounter       ; $af
        ram_byte zb0                    ; $b0 unused
        ram_byte zSfxPitchCounter       ; $b1
        ram_byte zb2                    ; $b2 unused
        ram_word zEchoVol               ; $b3
        ram_word zEchoVolRate           ; $b5
        ram_byte zEchoVolCounter        ; $b7
        ram_byte zSongVol               ; $b8
        ram_byte zActiveSongCh          ; $b9
        ram_byte zActiveSfxCh           ; $ba
        ram_byte zActiveSysCh           ; $bb
        ram_byte zKeyOn                 ; $bc
        ram_byte zKeyOff                ; $bd
        ram_byte zSysFlags              ; $be
        ram_byte zChMask                ; $bf
        ram_byte zMutedCh               ; $c0
        ram_byte zPort0                 ; $c1
        ram_byte zPort1                 ; $c2
        ram_byte zPort2                 ; $c3
        ram_byte zPort3                 ; $c4
        ram_byte zEchoEn                ; $c5
        ram_byte zNoiseEn               ; $c6
        ram_byte zPitchModEn            ; $c7
        ram_byte zFlags                 ; $c8
        ram_byte zChEchoEn              ; $c9
        ram_byte zSfxEchoEn             ; $ca
        ram_byte zChNoiseEn             ; $cb
        ram_byte zSfxNoiseEn            ; $cc
        ram_byte zChPitchModEn          ; $cd
        ram_byte zSfxPitchModEn         ; $ce
        ram_byte zIsTie                 ; $cf
        ram_byte zSfxIsTie              ; $d0
        ram_byte zCondJumpEn            ; $d1
        ram_byte zNoiseFreq             ; $d2
        ram_byte zSfxNoiseFreq          ; $d3
        ram_byte zEchoFilterId          ; $d4
        ram_byte zEchoFeedback          ; $d5
        ram_byte zNeedVolUpdate         ; $d6
        ram_byte zNeedFreqUpdate        ; $d7
        ram_word zd8                    ; $d8
        ram_res 16, zChWaveVol          ; $da-$e9
        ram_byte zIntEnvCounter         ; $ea
        ram_byte zSuspSongId            ; $eb
        ram_byte zSongId                ; $ec
        ram_byte zTempRepeatDepth       ; $ed

; system flag bitmasks
        .define zSysFlags_Mono          zSysFlags.0
        .define zSysFlags_FastFwd       zSysFlags.1
        .define zSysFlags_WaveCh        zSysFlags.2  ; first/last 4 channels (toggles every frame)
        .define zSysFlags_SfxSwapLR     zSysFlags.3  ; reflect sound effects left <-> right
        .define zSysFlags_WaveEn        zSysFlags.7

; ---------------------------------------------------------------------------

        ram_org $0100

        ram_byte wVibDelayCounter       ; $0100 vibrato delay counter
        ram_byte wTremDelayCounter      ; $0101 tremolo delay counter
        ram_res 30
        ram_byte wPitchEnvOffset        ; $0120 pitch envelope offset
        ram_byte wVibAmpl               ; $0121 vibrato amplitude
        ram_res 30
        ram_byte wTremAmpl              ; $0140 tremolo amplitude
        ram_byte wPanCycleEn            ; $0141 enable pansweep
        ram_res 30
        ram_byte wVibDelay              ; $0160 vibrato delay
        ram_byte wTremDelay             ; $0161 tremolo delay
        ram_res 30

; spc-700 cpu stack
        ram_org $0180
        ram_res $80, wStack             ; $0180
        wStackInit := ::_ram_offset - 1 ; $01ff

; ---------------------------------------------------------------------------

        ram_org $1a00

        ram_res $0080, wSampleFreqMult  ; $1a00
        ram_res $0080, wSampleADSR      ; $1a80
        ram_res $0100, wSamplePtrs      ; $1b00
        ram_res $1000, wSongScripts     ; $1c00
        ram_res $0400, wGameSfxPtrs     ; $2c00
        ram_res $1800, wGameSfxScripts  ; $3000
        ram_res $8a00, wSampleBRR       ; $4800
        ram_res $2800, wEchoBuf         ; $d200

; ---------------------------------------------------------------------------

        ram_org $fa00

        ram_res 32, wChVol              ; $fa00 volume (hi byte active)
        ram_res 32, wChVolRate          ; $fa20 volume envelope rate
        ram_res 32, wChPan              ; $fa40 pan (hi byte active)
        ram_res 32, wChPanRate          ; $fa60 pan envelope rate
        ram_byte wChVolCounter          ; $fa80 volume envelope counter
        ram_byte wChPanCounter          ; $fa81 pan envelope counter
        ram_res 30
        ram_byte wVibCycleDur           ; $faa0 vibrato cycle duration
        ram_byte wTremCycleDur          ; $faa1 tremolo cycle duration
        ram_res 30
        ram_byte wPanCycleDur           ; $fac0 pan cycle duration
        ram_byte wPitchEnvDur           ; $fac1 pitch envelope duration
        ram_res 30
        ram_byte wVibCycleCounter       ; $fae0 vibrato cycle counter
        ram_byte wTremCycleCounter      ; $fae1 tremolo cycle counter
        ram_res 30
        ram_byte wPanCycleCounter       ; $fb00 pan cycle counter
        ram_byte wChVolMult             ; $fb01 volume multiplier (tremolo)
        ram_res 30
        ram_res 32, wChFreqMult         ; $fb20 frequency multiplier (vibrato)
        ram_byte wChDetune              ; $fb40 detune
        ram_byte wChPitch               ; $fb41 pitch value
        ram_res 30
        ram_byte                        ; $fb60 unused
        ram_byte wChTranspose           ; $fb61 transpose
        ram_res 30
        ram_res 32, wPitchEnvRate       ; $fb80 pitch envelope rate
        ram_res 32, wPanCycleRate       ; $fba0 pan cycle rate
        ram_byte wChVibMult             ; $fbc0 vibrato multipler
        ram_byte wChTremMult            ; $fbc1 tremolo offset
        ram_res 30
        ram_byte wPanCycleOffset        ; $fbe0
        ram_byte wChPanOffset           ; $fbe1 pan offset
        ram_res 30
        ram_byte wChVibEnv              ; $fc00 vibrato envelope
        ram_byte wChTremEnv             ; $fc01 tremolo envelope
        ram_res 30
        ram_res 32, wfc20               ; $fc20 unused
        ram_res 32, wChFreqOffset       ; $fc40 frequency offset (vibrato)
        ram_res 32, wChFreq             ; $fc60 frequency
        ram_res 32, wChADSR             ; $fc80
        ram_byte wRepeatCounter         ; $fca0 repeat counter
        ram_byte                        ; $fca1 unused
        ram_res 30
        ram_res $40, wRepeatCount       ; $fcc0
        ram_res $80, wRepeatPtr         ; $fd00

; suspended song data
        ram_byte wSuspTempoCounter      ; $fd80
        ram_byte wSuspSongTickCounter   ; $fd81
        ram_byte wSuspEchoVolCounter    ; $fd82
        ram_byte wSuspActiveSongCh      ; $fd83
        ram_byte wSuspChEchoEn          ; $fd84
        ram_byte wSuspChNoiseEn         ; $fd85
        ram_byte wSuspChPitchModEn      ; $fd86
        ram_byte wSuspIsTie             ; $fd87
        ram_byte wSuspCondJumpEn        ; $fd88
        ram_byte wSuspNoiseFreq         ; $fd89
        ram_byte wSuspEchoFilterId      ; $fd8a
        ram_byte wSuspEchoFeedback      ; $fd8b
        ram_byte wfd8c                  ; $fd8c
        ram_word wSuspScriptOffset      ; $fd8d
        ram_word wSuspTempo             ; $fd8f
        ram_word wSuspTempoRate         ; $fd91
        ram_word wSuspEchoVol           ; $fd93
        ram_word wSuspEchoVolRate       ; $fd95
        ram_byte wSuspTickCounter       ; $fd97
        ram_byte wSuspChOctave          ; $fd98
        ram_res 14
        ram_byte wSuspRepeatDepth       ; $fda7
        ram_byte wSuspChSample          ; $fda8
        ram_res 14
        ram_byte wSuspVibDelayCounter   ; $fdb7
        ram_byte wSuspTremDelayCounter  ; $fdb8
        ram_res 14
        ram_byte wSuspPitchEnvOffset    ; $fdc7
        ram_byte wSuspVibAmpl           ; $fdc8
        ram_res 14
        ram_byte wSuspTremAmpl          ; $fdd7
        ram_byte wSuspPanCycleEn        ; $fdd8
        ram_res 14
        ram_byte wSuspVibDelay          ; $fde7
        ram_byte wSuspTremDelay         ; $fde8
        ram_res 14
        ram_byte wSuspChVolCounter      ; $fdf7
        ram_byte wSuspChPanCounter      ; $fdf8
        ram_res 14
        ram_byte wSuspVibCycleDur       ; $fe07
        ram_byte wSuspTremCycleDur      ; $fe08
        ram_res 14
        ram_byte wSuspPanCycleDur       ; $fe17
        ram_byte wSuspPitchEnvDur       ; $fe18
        ram_res 14
        ram_byte wSuspVibCycleCounter   ; $fe27
        ram_byte wSuspTremCycleCounter  ; $fe28
        ram_res 14
        ram_byte wSuspPanCycleCounter   ; $fe37
        ram_byte wSuspChVolMult         ; $fe38
        ram_res 14
        ram_byte wSuspChDetune          ; $fe47
        ram_byte wSuspChPitch           ; $fe48
        ram_res 14
        ram_byte wfe57                  ; $fe57: unused
        ram_byte wSuspChTranspose       ; $fe58
        ram_res 14
        ram_byte wSuspChVibMult         ; $fe67
        ram_byte wSuspChTremMult        ; $fe68
        ram_res 14
        ram_byte wSuspChVibEnv          ; $fe77
        ram_byte wSuspChTremEnv         ; $fe78
        ram_res 14
        ram_res 16, wSuspScriptPtr      ; $fe87
        ram_res 16, wSuspChVol          ; $fe97
        ram_res 16, wSuspChVolRate      ; $fea7
        ram_res 16, wSuspChPan          ; $feb7
        ram_res 16, wSuspChPanRate      ; $fec7
        ram_res 16, wSuspChFreqMult     ; $fed7
        ram_res 16, wSuspPitchEnvRate   ; $fee7
        ram_res 16, wSuspPanCycleRate   ; $fef7
        ram_res 16, wSuspPanCycleOffset ; $ff07
        ram_res 16, wff17               ; $ff17: unused (from $fc20)
        ram_res 16, wSuspChFreqOffset   ; $ff27
        ram_res 16, wSuspChFreq         ; $ff37
        ram_res 16, wSuspChADSR         ; $ff47
        ram_res 32, wSuspRepeatCounter  ; $ff57-$ff76
        ram_res 32, wSuspRepeatCount    ; $ff77-$ff96
        ram_res 32, wSuspRepeatPtr      ; $ff97-$ffb6

; note: SPC IPL ROM starts at $ffc0

; ---------------------------------------------------------------------------
