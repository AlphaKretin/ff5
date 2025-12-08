
; dsp registers

        dspChVolL                       := $00
        dspChVolR                       := $01
        dspChPitchL                     := $02
        dspChPitchH                     := $03
        dspChSample                     := $04
        dspChADSR1                      := $05
        dspChADSR2                      := $06
        dspChGain                       := $07
        dspChEnvx                       := $08
        dspChOutx                       := $09
        dspMainVolL                     := $0c
        dspMainVolR                     := $1c
        dspEchoVolL                     := $2c
        dspEchoVolR                     := $3c
        dspKeyOn                        := $4c
        dspKeyOff                       := $5c
        dspFlags                        := $6c
        dspEndSample                    := $7c
        dspEchoFeedback                 := $0d
        dspPitchMod                     := $2d
        dspNoiseEn                      := $3d
        dspEchoEn                       := $4d
        dspSamplePtr                    := $5d
        dspEchoBufPtr                   := $6d
        dspEchoDelay                    := $7d
        dspFilter                       := $0f

; hardware registers

        hTest                           := $f0
        hCtrlReg                        := $f1
        hDSPAddr                        := $f2
        hDSPData                        := $f3
        hPort0                          := $f4
        hPort1                          := $f5
        hPort2                          := $f6
        hPort3                          := $f7
        hTimer0                         := $fa
        hTimer1                         := $fb
        hTimer2                         := $fc
        hCounter0                       := $fd
        hCounter1                       := $fe
        hCounter2                       := $ff
