; +-------------------------------------------------------------------------+
; |                                                                         |
; |                             FINAL FANTASY V                             |
; |                                                                         |
; +-------------------------------------------------------------------------+
; | file: sound/ff5-spc.asm                                                 |
; |                                                                         |
; | description: spc-700 program                                            |
; |                                                                         |
; | created: 10/4/2020                                                      |
; +-------------------------------------------------------------------------+

.include "spc-ca65.inc"

.include "sound/spc-macros.inc"
.include "sound/spc-ram.inc"
.include "sound/spc-dsp.inc"

.segment "code"

; ---------------------------------------------------------------------------

; [ reset (spc entry point) ]

.proc Reset

        clrp
        di

; init stack pointer
        mov     x,#<wStackInit
        mov     sp,x

; clear direct page 0
        mov     a,#0
        mov     x,a
:       mov     (x)+,a
        cmp     x,#hTest
        bne     :-
        decw    zSuspSongId

; initialize dsp registers
        mov     a,#0
        mov     y,#dspMainVolL
        call    !SetDSP
        mov     y,#dspMainVolR
        call    !SetDSP
        mov     y,#dspEchoVolL
        call    !SetDSP
        mov     y,#dspEchoVolR
        call    !SetDSP
        mov     y,#dspPitchMod
        call    !SetDSP
        mov     y,#dspNoiseEn
        call    !SetDSP
        mov     y,#dspEchoEn
        call    !SetDSP
        mov     y,#dspSamplePtr
        mov     a,#>wSamplePtrs
        call    !SetDSP
        mov     y,#dspChGain
        mov     x,#$a0
:       mov     hDSPAddr,y
        mov     hDSPData,x
        mov     a,y
        clrc
        adc     a,#$10
        mov     y,a
        bpl     :-

; clear ports, stop timers
        mov     hCtrlReg,#$f0
        mov     hTimer0,#36             ; init timer 0 (4.5 ms)
        mov     hTimer1,#128            ; init timer 1 (16 ms)
        mov     hCtrlReg,#$03           ; start timer 0 and timer 1

; init the echo buffer
        call    !ClearEchoBuf
        mov     a,#>wEchoBuf
        mov     y,#dspEchoBufPtr
        call    !SetDSP
        mov     a,#5                    ; echo delay (80 ms)
        mov     y,#dspEchoDelay
        call    !SetDSP

; wait for echo buffer to fill with silence
        mov     a,#0
:       mov     y,hCounter1             ; wait for counter 1
        beq     :-
        inc     a
        cmp     a,#16                   ; wait 16 cycles (256 ms total)
        bne     :-

; main volume always set to full
        mov     a,#$7f
        mov     y,#dspMainVolL
        call    !SetDSP
        mov     y,#dspMainVolR
        call    !SetDSP

; init misc variables
        mov     zKeyOff,#$ff
        mov     zIntEnvCounter,#7
        set1    zRelTempoMult+1.7
        set1    zSfxTempoMult+1.7
        set1    zRelPitchMult+1.7
        set1    zSfxPitchMult+1.7
; fall through

.endproc  ; Reset

; ---------------------------------------------------------------------------

; [ main code loop ]

.proc MainLoop

; wait for counter 0
:       call    !CheckInt
        mov     y,hCounter0
        beq     :-

; update dsp registers
        mov     y,#8
:       mov     a,!DSPUpdateRegTbl-1+y
        mov     hDSPAddr,a
        mov     a,!DSPUpdateRAMTbl-1+y
        mov     x,a
        mov     a,(x)
        mov     hDSPData,a
        dbnz    y,:-

; clear all key on/off flags
        mov     zKeyOff,y
        mov     zKeyOn,y

; set the output ports
        bbs     zSysFlags_WaveEn,_02b3
        movw    ya,zActiveSongCh        ; output song/channel info
        movw    hPort2,ya
        mov     a,zCondJumpEn
        mov     hPort1,a
        bra     _02b7
_02b3:  call    !UpdateWaveOutput       ; output waveform

; update interrupt envelopes every 36 ms
_02b7:  movw    ya,zd8
        bne     _02c5
        dec     zIntEnvCounter
        bne     _02c5
        mov     zIntEnvCounter,#7       ; 8 * 4.5 ms = 36 ms
        call    !UpdateIntEnv           ; execute once every 36 ms

; update channel scripts
_02c5:  call    !UpdateChScripts

; update volume and frequency for active song channels
        mov     x,#0
        mov     zChMask,#1
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        eor     a,#<-1
        and     a,zActiveSongCh
        mov     z02,a
_02d7:  lsr     z02
        bcc     _02e0
        mov     zChPtr,x
        call    !UpdateChVolFreq
_02e0:  inc     x
        inc     x
        asl     zChMask
        bne     _02d7

; update volume and frequency for active sound effect channels
        mov     x,#$1e
        mov     zChMask,#$80
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        mov     z02,a
_02f1:  asl     z02
        bcc     _02fa
        mov     zChPtr,x
        call    !UpdateChVolFreq
_02fa:  dec     x
        dec     x
        lsr     zChMask
        bbc     zChMask.3,_02f1
        jmp     !MainLoop

.endproc  ; MainLoop

; ---------------------------------------------------------------------------

; [ update channel scripts ]

.proc UpdateChScripts

_0304:  mov     a,zRelTempoMult+1
        eor     a,#$80
        mov     y,zTempo+1              ; apply tempo multiplier
        mul     ya
        mov     a,y
        bbc     zRelTempoMult+1.7,_0319 ; branch if negative multiplier
        asl     a
        clrc
        adc     a,zTempo+1              ; add to tempo
        bcc     _031c
        mov     a,#$ff                  ; max 255
        bra     _031c
_0319:  bne     _031c
        inc     a                       ; min 1
_031c:  clrc
        adc     a,zSongTickCounter      ; add to tempo tick counter
        mov     zSongTickCounter,a
        bbc     zSysFlags_FastFwd,_0325
        setc                            ; if fast forward, tick every frame
_0325:  bcc     _0383                   ; branch if no tick
        mov     x,#0                    ; update song channels
        mov     zChMask,#1
        mov     z02,zActiveSongCh
_032f:  lsr     z02
        bcc     _0365
        mov     zChPtr,x
        dec     zTickCounter+x
        bne     _033e
        call    !ExecChScript
        bra     _0361
_033e:  mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        and     a,zChMask
        bne     _0365
        mov     a,#2                    ; key off 2 ticks before note ends
        cbne    zTickCounter+x,_0354
        mov     a,zIsTie                ; no key off for tie
        and     a,zChMask
        bne     _0354
        or      zKeyOff,zChMask
_0354:  setp
        mov     a,<wVibDelayCounter+x   ; decrement vibrato and tremolo delay
        beq     _035b
        dec     <wVibDelayCounter+x
_035b:  mov     a,<wTremDelayCounter+x
        beq     _0361
        dec     <wTremDelayCounter+x
_0361:  clrp
        call    !UpdateChEnv
_0365:  inc     x
        inc     x
        asl     zChMask
        bne     _032f
        mov     a,zTempoCounter         ; update tempo envelope
        beq     _0377
        dec     zTempoCounter
        movw    ya,zTempoRate
        addw    ya,zTempo
        movw    zTempo,ya
_0377:  mov     a,zEchoVolCounter       ; update echo volume envelope
        beq     _0383
        dec     zEchoVolCounter
        movw    ya,zEchoVolRate
        addw    ya,zEchoVol
        movw    zEchoVol,ya
_0383:  mov     a,zSfxTempoMult+1
        eor     a,#$80
        mov     y,#120                  ; sfx tempo always 120
        mul     ya
        mov     a,y
        bbc     zSfxTempoMult+1.7,_0398
        asl     a
        clrc
        adc     a,#120
        bcc     _039b
        mov     a,#$ff
        bra     _039b
_0398:  bne     _039b
        inc     a
_039b:  clrc
        adc     a,zSfxTickCounter
        mov     zSfxTickCounter,a
        bbc     zSysFlags_FastFwd,_03a4
        setc
_03a4:  bcc     _03e6
        mov     x,#$18                  ; update sound effect channels
        mov     zChMask,#$10
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        xcn     a
        mov     z02,a
_03b2:  lsr     z02
        bcc     _03e0
        mov     zChPtr,x
        dec     zTickCounter+x
        bne     _03c1
        call    !ExecChScript
        bra     _03dc
_03c1:  mov     a,#2
        cbne    zTickCounter+x,_03cf
        mov     a,zSfxIsTie
        and     a,zChMask
        bne     _03cf
        or      zKeyOff,zChMask
_03cf:  setp
        mov     a,<wVibDelayCounter+x   ; decrement vibrato and tremolo delay
        beq     _03d6
        dec     <wVibDelayCounter+x
_03d6:  mov     a,<wTremDelayCounter+x
        beq     _03dc
        dec     <wTremDelayCounter+x
_03dc:  clrp
        call    !UpdateChEnv
_03e0:  inc     x
        inc     x
        asl     zChMask
        bne     _03b2
_03e6:  ret

.endproc  ; UpdateChScripts

; ---------------------------------------------------------------------------

; [ execute channel script ]

.proc ExecChScript

_03e7:  call    !GetNextParam
        cmp     a,#$d2
        bcc     _03f3
        call    !ExecChCmd
        bra     _03e7
_03f3:  mov     y,#0
        mov     x,#15                   ; divide by 15, y = duration
        div     ya,x
        mov     x,zChPtr
        mov     a,!NoteDurTbl+y         ; note duration
        mov     zTickCounter+x,a        ; set tick counter
        call    !CheckTie
        cmp     zChParam,#$b4
        bcc     _0410                   ; branch if a note
        cmp     zChParam,#$c3
        bcs     _040f                   ; return if a rest
        jmp     !_04bf                  ; jump if a tie
_040f:  ret
_0410:  bsfx    _041c
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        and     a,zChMask
        bne     _040f
_041c:  mov     a,zChParam
        mov     y,#0
        mov     x,#15                   ; divide by 15, a = pitch
        div     ya,x
        mov     zChParam,a
        mov     x,zChPtr
        mov     a,zChOctave+x
        mov     y,#12
        mul     ya
        clrc
        adc     a,zChParam              ; a = pitch + octave * 12
        clrc
        adc     a,!wChTranspose+x       ; add transpose
        setc
        sbc     a,#10                   ; subtact 10 to go from A to C
        mov     !wChPitch+x,a
        call    !CalcFreq
        mov     a,zPitchFreq
        mov     !wChFreq+x,a
        mov     a,zPitchFreq+1
        mov     !wChFreq+1+x,a
        mov     y,#$07                  ; full vib/trem envelope
        mov     a,!wVibAmpl+x
        beq     _046f
        cmp     a,#$c0
        bcs     _0455                   ; branch if balanced vibrato
        mov     a,#0
        bra     _0457
_0455:  mov     a,#$80
_0457:  mov     !wChVibMult+x,a
        mov     a,#1
        mov     !wVibCycleCounter+x,a
        mov     a,!wVibDelay+x          ; reset vibrato delay counter
        mov     !wVibDelayCounter+x,a
        beq     _046a                   ; branch if no vibrato delay
        mov     a,y                     ; init vibrato envelope
        bra     _046c
_046a:  mov     a,#0                    ; no vibrato envelope
_046c:  mov     !wChVibEnv+x,a
_046f:  mov     a,!wTremAmpl+x
        beq     _0498
        cmp     a,#$c0
        bcs     _047c                   ; branch if balanced tremolo
        mov     a,#0
        bra     _047e
_047c:  mov     a,#$80
_047e:  mov     !wChTremMult+x,a
        mov     a,#1
        mov     !wTremCycleCounter+x,a
        mov     a,!wTremDelay+x         ; reset tremolo delay counter
        mov     !wTremDelayCounter+x,a
        beq     _0491                   ; branch if no tremolo delay
        mov     a,y                     ; init tremolo envelope
        bra     _0493
_0491:  mov     a,#0                    ; no tremolo envelope
_0493:  mov     !wChTremEnv+x,a
        mov     a,#0
_0498:  mov     !wChFreqOffset+x,a      ; reset remaining multipliers/offsets
        mov     !wChFreqOffset+1+x,a
        mov     !wChVolMult+x,a
        mov     !wPitchEnvRate+x,a
        mov     !wPitchEnvRate+1+x,a
        bsfx    _04b3
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        and     a,zChMask
        bne     _04bf                   ; no update if sfx active this channel
_04b3:  or      zNeedVolUpdate,zChMask
        or      zNeedFreqUpdate,zChMask
        or      zKeyOn,zChMask
        call    !UpdateChSample
_04bf:  mov     a,!wPitchEnvOffset+x
        beq     _0526
        clrc
        adc     a,!wChPitch+x           ; get target pitch frequency
        mov     !wChPitch+x,a
        call    !CalcFreq
        mov     a,!wChFreq+x
        mov     zScratch0,a
        mov     a,!wChFreq+1+x
        mov     zScratch1,a
        movw    ya,zPitchFreq
        setc
        subw    ya,zScratch0            ; get difference in frequency
        movw    zScratch0,ya
        push    psw
        bcs     _04ea
        eor     zScratch0,#<-1          ; negate
        eor     zScratch1,#<-1
        incw    zScratch0
_04ea:  mov     a,!wPitchEnvDur+x       ; pitch envelope duration
        bne     _04f7
        mov     zScratch0,zScratch1
        mov     zScratch1,#0
        bra     _0504
_04f7:  mov     x,a
        mov     a,zScratch1
        mov     y,#0
        div     ya,x                    ; rate = freq difference / dur
        mov     zScratch1,a
        mov     a,zScratch0
        div     ya,x
        mov     zScratch0,a
_0504:  movw    ya,zScratch0
        bne     _050a
        inc     zScratch0
_050a:  pop     psw
        bcs     _0515
        eor     zScratch0,#<-1
        eor     zScratch1,#<-1
        incw    zScratch0
_0515:  mov     x,zChPtr
        mov     a,zScratch0
        mov     !wPitchEnvRate+x,a
        mov     a,zScratch1
        mov     !wPitchEnvRate+1+x,a
        mov     a,#0
        mov     !wPitchEnvOffset+x,a
_0526:  ret

.endproc  ; ExecChScript

; ---------------------------------------------------------------------------

; [ calculate pitch frequency ]

.proc CalcFreq

_0527:  mov     x,#12                   ; divide by 12, a = pitch
        mov     y,#0
        div     ya,x
        mov     x,zChPtr
        mov     z03,a
        mov     a,y
        asl     a
        mov     y,a
        mov     a,!PitchConst+y         ; pitch constants
        mov     zNotePitchConst,a
        mov     a,!PitchConst+1+y
        mov     zNotePitchConst+1,a
        mov     y,a
        mov     a,!wChFreqMult+x
        clrc
        adc     a,!wChDetune+x
        push    psw
        push    a
        mul     ya
        movw    zPitchFreq,ya
        mov     y,zNotePitchConst
        pop     a
        mul     ya
        mov     a,y
        mov     y,#0
        addw    ya,zPitchFreq
        movw    zPitchFreq,ya
        mov     a,!wChFreqMult+1+x
        beq     _0562
        mul     ya
        mov     a,y
        mov     y,#0
        addw    ya,zPitchFreq
        bra     _0564
_0562:  mov     a,zPitchFreq
_0564:  pop     psw
        bmi     _0569
        addw    ya,zNotePitchConst
_0569:  movw    zPitchFreq,ya
        mov     a,#4
        mov     y,z03
        bmi     _057f
        cmp     a,z03
        bcs     _0584
_0575:  aslw    zPitchFreq
        inc     a
        cbne    z03,_0575
        bra     _0587
_057f:  lsrw    zPitchFreq
        dec     a
_0584:  cbne    z03,_057f
_0587:  ret

.endproc  ; CalcFreq

; ---------------------------------------------------------------------------

; [ execute channel command ]

.proc ExecChCmd

_0588:  sbc     a,#$d2
        asl     a
        mov     y,a
        mov     a,!ChCmdPtrs+1+y
        push    a
        mov     a,!ChCmdPtrs+y
        push    a
        mov     a,y
        lsr     a
        mov     y,a
        mov     a,!ChCmdParams+y
        beq     _05a6

; get next parameter
::GetNextParam:
        mov     a,[zScriptPtr+x]
        mov     zChParam,a
        inc     zScriptPtr+x
        bne     _05a6
        inc     zScriptPtr+1+x
_05a6:  ret

.endproc  ; ExecChCmd

; ---------------------------------------------------------------------------

; [ check if the next note is a tie ]

.proc CheckTie

_05a7:  mov     a,zScriptPtr+x
        mov     y,zScriptPtr+1+x
        movw    zIntAddr,ya
        mov     a,zRepeatDepth+x
        mov     zTempRepeatDepth,a
_05b1:  mov     y,#0
_05b3:  mov     a,[zIntAddr]+y
        cmp     a,#$d2
        bcc     _062f                   ; branch if a note, tie, or rest
        incw    zIntAddr
        cmp     a,#$f2
        beq     _062f
        cmp     a,#$fa
        bne     _05d1
_05c3:  mov     a,[zIntAddr]+y
        push    a
        inc     y
        mov     a,[zIntAddr]+y
        mov     y,a
        pop     a
        addw    ya,zScriptOffset
        movw    zIntAddr,ya
        bra     _05b1
_05d1:  cmp     a,#$f1
        bne     _05fc
        mov     y,zTempRepeatDepth
        mov     a,!wRepeatCount+y
        beq     _05ed
        dec     a
        bne     _05ed
        dec     zTempRepeatDepth
        mov     a,x
        asl     a
        dec     a
        cbne    zTempRepeatDepth,_05b1
        clrc
        adc     zTempRepeatDepth,#4
        bra     _05b1
_05ed:  mov     a,y
        asl     a
        mov     y,a
        mov     a,!wRepeatPtr+y
        mov     zIntAddr,a
        mov     a,!wRepeatPtr+1+y
        mov     zIntAddr+1,a
        bra     _05b1
_05fc:  cmp     a,#$f9
        bne     _0611
        mov     y,zTempRepeatDepth
        mov     a,!wRepeatCounter+y
        inc     a
        cmp     a,[zIntAddr]+y
        bne     _060d
        inc     y
        bra     _05c3
_060d:  mov     y,#3
        bra     _0629
_0611:  cmp     a,#$fb
        bne     _061f
        mov     a,zChMask
        and     a,zCondJumpEn
        bne     _05c3
        mov     y,#2
        bra     _0629
_061f:  setc
        sbc     a,#$d2
        mov     y,a
        mov     a,!ChCmdParams+y
        beq     _05b1
        mov     y,a
_0629:  incw    zIntAddr
        dbnz    y,_0629
        bra     _05b3
_062f:  mov     y,a
        mov     a,zChMask
        cmp     y,#$c3
        bcs     _0648                   ; branch if a rest
        cmp     y,#$b4
        bcc     _0648                   ; branch if not a tie
        bsfx    _0643
        tset1   !zIsTie
        bra     _0654
_0643:  tset1   !zSfxIsTie
        bra     _0654
_0648:  bsfx    _0651
        tclr1   !zIsTie
        bra     _0654
_0651:  tclr1   !zSfxIsTie
_0654:  ret

.endproc  ; CheckTie

; ---------------------------------------------------------------------------

; [ set dsp register ]

.proc SetDSP

        mov     hDSPAddr,y
        mov     hDSPData,a
        ret

.endproc  ; SetDSP

; ---------------------------------------------------------------------------

; [ channel command $f3: set tempo ]

.proc SetTempo

        bsfx    Done                    ; return if a sound effect
        mov     zTempo+1,a
        mov     a,#0
        mov     zTempo,a

::SetTempo_Done:
        mov     zTempoCounter,a
Done:   ret

.endproc  ; SetTempo

; ---------------------------------------------------------------------------

; [ channel command $f4: set tempo w/ envelope]

.proc SetTempoEnv

        mov     zTempoCounter,a
        call    !GetNextParam
        bsfx    Done
        mov     y,zTempoCounter
        beq     SetTempo
        setc
        sbc     a,zTempo+1
        beq     SetTempo_Done
        push    psw
        bcs     :+
        eor     a,#<-1
        inc     a
:       mov     x,zTempoCounter
        mov     y,#0
        div     ya,x
        mov     zScratch1,a
        mov     a,#0
        div     ya,x
        mov     zScratch0,a
        mov     x,zChPtr
        pop     psw
        bcs     :+
        eor     zScratch0,#<-1
        eor     zScratch1,#<-1
        incw    zScratch0
:       movw    ya,zScratch0
        mov     zTempoRate,a
        mov     zTempoRate+1,y
Done:   ret

.endproc  ; SetTempoEnv

; ---------------------------------------------------------------------------

; [ channel command $f8: set song volume ]

.proc SetSongVol

        mov     zSongVol,a
        ret

.endproc  ; SetSongVol

; ---------------------------------------------------------------------------

; [ channel command $d2: set volume ]

; p1: volume value

.proc SetVol

        mov     !wChVol+1+x,a
        mov     a,#0
        mov     !wChVol+x,a

::SetVol_Done:
        mov     !wChVolCounter+x,a
        ret

.endproc  ; SetVol

; ---------------------------------------------------------------------------

; [ channel command $d3: set volume w/ envelope ]

; p1: envelope duration
; p2: final volume value

.proc SetVolEnv

        mov     zScratch0,a
        mov     !wChVolCounter+x,a
        call    !GetNextParam
        mov     y,zScratch0
        beq     SetVol
        setc
        sbc     a,!wChVol+1+x
        beq     SetVol_Done
        push    psw
        bcs     :+
        eor     a,#<-1
        inc     a
:       mov     x,zScratch0
        mov     y,#0
        div     ya,x
        mov     zScratch1,a
        mov     a,#0
        div     ya,x
        mov     zScratch0,a
        mov     x,zChPtr
        pop     psw
        bcs     :+
        eor     zScratch0,#<-1
        eor     zScratch1,#<-1
        incw    zScratch0
:       mov     a,zScratch0
        mov     !wChVolRate+x,a
        mov     a,zScratch1
        mov     !wChVolRate+1+x,a
        ret

.endproc  ; SetVolEnv

; ---------------------------------------------------------------------------

; [ channel command $f5: set echo volume ]

.proc SetEchoVol

_06ea:  bsfx    _06f6
        lsr     a
        mov     $b4,a
        mov     $b3,#0

::SetEchoVol_Done:
        mov     $b7,a
_06f6:  ret

.endproc  ; SetEchoVol

; ---------------------------------------------------------------------------

; [ channel command $f6: set echo volume w/ envelope ]

.proc SetEchoVolEnv

_06f7:  mov     $b7,a
        call    !GetNextParam
        bsfx    _072f
        mov     y,$b7
        beq     SetEchoVol
        lsr     a
        setc
        sbc     a,$b4
        beq     SetEchoVol_Done
        push    psw
        bcs     _0710
        eor     a,#<-1
        inc     a
_0710:  mov     x,$b7
        mov     y,#0
        div     ya,x
        mov     zScratch1,a
        mov     a,#0
        div     ya,x
        mov     zScratch0,a
        mov     x,zChPtr
        pop     psw
        bcs     _0729
        eor     zScratch0,#<-1
        eor     zScratch1,#<-1
        incw    zScratch0
_0729:  movw    ya,zScratch0
        mov     $b5,a
        mov     $b6,y
_072f:  ret

.endproc  ; SetEchoVolEnv

; ---------------------------------------------------------------------------

; [ channel command $d4: set pan ]

; b1: pan value (01 = left, 40 = center, 7f = right, top bit inactive)

.proc SetPan

_0730:  mov     !wChPan+1+x,a
        mov     a,#0
        mov     !wChPan+x,a

::SetPan_Done:
        mov     !wChPanCounter+x,a
        ret

.endproc  ; SetPan

; ---------------------------------------------------------------------------

; [ channel command $d4: set pan w/ envelope ]

; b1: envelope duration
; b1: final pan value

.proc SetPanEnv

_073c:  mov     $34,a
        mov     !wChPanCounter+x,a      ; set pan counter
        call    !GetNextParam
        mov     y,$34
        beq     SetPan
        setc
        sbc     a,!wChPan+1+x
        beq     SetPan_Done
        push    psw
        bcs     _0754
        eor     a,#<-1
        inc     a
_0754:  mov     x,$34
        mov     y,#0
        div     ya,x
        mov     zScratch1,a
        mov     a,#0
        div     ya,x
        mov     $34,a
        mov     x,zChPtr
        pop     psw
        bcs     _076d
        eor     $34,#<-1
        eor     zScratch1,#<-1
        incw    $34
_076d:  mov     a,$34
        mov     !wChPanRate+x,a         ; set pan rate
        mov     a,zScratch1
        mov     !wChPanRate+1+x,a
        ret

.endproc  ; SetPanEnv

; ---------------------------------------------------------------------------

; [ channel command $d5: set pitch w/ envelope ]

; b1: envelope duration
; b2: pitch offset (signed)

.proc SetPitchEnv

_0778:  inc     a
        mov     !wPitchEnvDur+x,a
        call    !GetNextParam
        mov     !wPitchEnvOffset+x,a
        ret

.endproc  ; SetPitchEnv

; ---------------------------------------------------------------------------

; [ channel command $e8: set transpose (relative) ]

.proc SetTransposeRel

        clrc
        adc     a,!wChTranspose+x
; fallthrough

.endproc  ; SetTransposeRel

; ---------------------------------------------------------------------------

; [ channel command $e7: set transpose (absolute) ]

.proc SetTransposeAbs

        mov     !wChTranspose+x,a
        ret

.endproc  ; SetTransposeAbs

; ---------------------------------------------------------------------------

; [ channel command $f7: set echo feedback ]

; p1: echo feedback
; p2: echo filter id (0-3)

.proc SetEchoFeedback

_078b:  mov     zEchoFeedback,a
        call    !GetNextParam
        bnsfx   SetEchoFeedback_DSP
        ret

::SetEchoFeedback_DSP:
        and     a,#$03
        mov     zEchoFilterId,a
        asl     a
        asl     a
        asl     a
        mov     y,a
        mov     x,#dspFilter
_079f:  mov     a,!EchoFilterTbl+y
        mov     hDSPAddr,x
        mov     hDSPData,a
        inc     y
        mov     a,x
        clrc
        adc     a,#$10
        mov     x,a
        bpl     _079f
        mov     x,zChPtr
        mov     y,#dspEchoFeedback
        mov     a,zEchoFeedback
        jmp     !SetDSP

.endproc  ; SetEchoFeedback

; ---------------------------------------------------------------------------

; [ channel command $d7: enable vibrato ]

.proc EnableVib

_07b7:  mov     !wVibDelay+x,a
        call    !GetNextParam
        inc     a
        mov     !wVibCycleDur+x,a
        mov     a,#1
        mov     !wVibCycleCounter+x,a
        call    !GetNextParam
; fall through

.endproc  ; EnableVib

; ---------------------------------------------------------------------------

; [ channel command $d8: disable vibrato ]

.proc DisableVib

_07c9:  mov     !wVibAmpl+x,a
        ret

.endproc  ; DisableVib

; ---------------------------------------------------------------------------

; [ channel command $d9: enable tremolo ]

.proc EnableTrem

_07cd:  mov     !wTremDelay+x,a
        call    !GetNextParam
        inc     a
        mov     !wTremCycleDur+x,a
        mov     a,#1
        mov     !wTremCycleCounter+x,a
        call    !GetNextParam
; fall through

.endproc  ; EnableTrem

; ---------------------------------------------------------------------------

; [ channel command $da: disable tremolo ]

.proc DisableTrem

_07df:  mov     !wTremAmpl+x,a
        ret

.endproc  ; DisableTrem

; ---------------------------------------------------------------------------

; [ channel command $db: enable pan cycle ]

; p1: cycle duration (in ticks)
; p2: cycle amplitude (signed)

.proc EnablePanCycle

_07e3:  clrc
        inc     a
        mov     !wPanCycleDur+x,a
        bne     _07eb                   ; branch if duration param is not $ff
        setc                            ; duration is $80 ticks
_07eb:  ror     a
        bne     _07ef
        inc     a                       ; min cycle counter is 1
_07ef:  mov     !wPanCycleCounter+x,a   ; cycle counter = duration / 2
        mov     y,a
        call    !GetNextParam
        asl     a
        mov     a,zChParam
        and     a,#$7f
        bcc     _07ff                   ; branch if positive amplitude
        eor     a,#$7f
_07ff:  mov     zScratch0,a
        mov     a,y
        bpl     _0809
        mov     zScratch1,#$00
        bra     _081c
_0809:  mov     x,a
        mov     y,#0
        mov     a,zScratch0
        div     ya,x
        mov     zScratch1,a
        mov     a,#0
        div     ya,x
        mov     zScratch0,a
        movw    ya,zScratch0
        bne     _081c
        inc     zScratch0
_081c:  bcc     _0826
        eor     zScratch0,#<-1
        eor     zScratch1,#<-1
        incw    zScratch0
_0826:  mov     x,$05
        mov     a,zScratch0
        mov     !wPanCycleRate+x,a
        mov     a,zScratch1
        mov     !wPanCycleRate+1+x,a
        mov     a,zChParam
; fall through

.endproc  ; EnablePanCycle

; ---------------------------------------------------------------------------

; [ channel command $dc: disable pan cycle ]

.proc DisablePanCycle

_0834:  mov     !wPanCycleEn+x,a
        mov     a,#0
        mov     !wPanCycleOffset+x,a
        mov     !wChPanOffset+x,a
        ret

.endproc  ; DisablePanCycle

; ---------------------------------------------------------------------------

; [ channel command $e5: increment octave ]

.proc IncOctave

_0840:  mov     a,!zChOctave+x
        inc     a
        bra     SetOctave

.endproc  ; IncOctave

; ---------------------------------------------------------------------------

; [ channel command $e6: decrement octave ]

.proc DecOctave

_0846:  mov     a,!zChOctave+x
        dec     a
; fall through

.endproc  ; DecOctave

; ---------------------------------------------------------------------------

; [ channel command $e4: set octave ]

.proc SetOctave

_084a:  mov     !zChOctave+x,a
        ret

.endproc  ; SetOctave

; ---------------------------------------------------------------------------

; [ channel command $e2: enable echo ]

.proc EnableEcho

_084e:  bsfx    _0857
        or      zChEchoEn,zChMask
        bra     UpdateEcho
_0857:  or      zSfxEchoEn,zChMask

::UpdateEcho:
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        eor     a,#<-1
        and     a,zChEchoEn
        or      a,zSfxEchoEn
        mov     zEchoEn,a
        ret

.endproc  ; EnableEcho

; ---------------------------------------------------------------------------

; [ channel command $e3: disable echo ]

.proc DisableEcho

_0867:  mov     a,zChMask
        bsfx    _0872
        tclr1   !zChEchoEn
        bra     UpdateEcho
_0872:  tclr1   !zSfxEchoEn
        bra     UpdateEcho

.endproc  ; DisableEcho

; ---------------------------------------------------------------------------

; [ channel command $de: enable noise ]

.proc EnableNoise

_0877:  bsfx    _0880
        or      zChNoiseEn,zChMask
        bra     UpdateNoise
_0880:  or      zSfxNoiseEn,zChMask
        set1    zSfxNoiseEn.0

::UpdateNoise:
        mov     zScratch0,zSfxNoiseEn
        clr1    zScratch0.0
        mov     a,zFlags
        and     a,#$e0
        bbs     zSfxNoiseEn.0,_0895
        or      a,zNoiseFreq
        bra     _0897
_0895:  or      a,zSfxNoiseFreq
_0897:  mov     zFlags,a
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        eor     a,#<-1
        and     a,zChNoiseEn
        or      a,zScratch0
        mov     zNoiseEn,a
        ret

.endproc  ; EnableNoise

; ---------------------------------------------------------------------------

; [ channel command $df: disable noise ]

.proc DisableNoise

_08a6:  mov     a,zChMask
        bsfx    _08b1
        tclr1   !zChNoiseEn
        bra     UpdateNoise
_08b1:  tclr1   !zSfxNoiseEn
        mov     a,zSfxNoiseEn
        and     a,#$f0
        bne     UpdateNoise
        clr1    zSfxNoiseEn.0
        bra     UpdateNoise

.endproc  ; DisableNoise

; ---------------------------------------------------------------------------

; [ channel command $dd: set noise frequency ]

.proc SetNoiseFreq

_08be:  and     a,#$1f
        bsfx    _08c8
        mov     zNoiseFreq,a
        bra     UpdateNoise
_08c8:  mov     zSfxNoiseFreq,a
        bra     UpdateNoise

.endproc  ; SetNoiseFreq

; ---------------------------------------------------------------------------

; [ channel command $e0: enable pitch mod ]

.proc EnablePitchMod

_08cc:  bsfx    _08d5
        or      zChPitchModEn,zChMask
        bra     UpdatePitchMod
_08d5:  or      zSfxPitchModEn,zChMask

::UpdatePitchMod:
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        eor     a,#<-1
        and     a,zChPitchModEn
        or      a,zSfxPitchModEn
        mov     zPitchModEn,a
        ret

.endproc  ; EnablePitchMod

; ---------------------------------------------------------------------------

; [ channel command $e1: disable pitch mod ]

.proc DisablePitchMod

_08e5:  mov     a,zChMask
        bsfx    _08f0
        tclr1   !zChPitchModEn
        bra     UpdatePitchMod
_08f0:  tclr1   !zSfxPitchModEn
        bra     UpdatePitchMod

.endproc  ; DisablePitchMod

; ---------------------------------------------------------------------------

; [ channel command $ea: set sample ]

.proc SetSample

_08f5:  mov     zChSample+x,a
        asl     a
        mov     y,a
        mov     a,!wSampleFreqMult+y
        mov     !wChFreqMult+x,a
        mov     a,!wSampleFreqMult+1+y
        mov     !wChFreqMult+1+x,a
        mov     a,!wSampleADSR+y
        mov     !wChADSR+x,a
        mov     a,!wSampleADSR+1+y
        mov     !wChADSR+1+x,a
        ret

.endproc  ; SetSample

; ---------------------------------------------------------------------------

; [ update sample in dsp ]

.proc UpdateChSample

_0912:  mov     y,zChSample+x
        mov     a,x
        xcn     a
        lsr     a
        or      a,#dspChSample
        mov     hDSPAddr,a
        mov     hDSPData,y
        bra     UpdateChADSR

.endproc  ; UpdateChSample

; ---------------------------------------------------------------------------

; [ channel command $eb: set adsr attack ]

.proc SetADSRAttack

_091f:  and     a,#$0f
        mov     zChParam,a
        mov     a,!wChADSR+x
        and     a,#$70
        or      a,zChParam
        or      a,#$80
        mov     !wChADSR+x,a
; fall through

.endproc  ; SetADSRAttack

; ---------------------------------------------------------------------------

; [ update adsr value in dsp ]

.proc UpdateChADSR

_092f:  bsfx    _093c
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        and     a,zChMask
        beq     _093c                   ; branch if no sfx this channel
        ret
_093c:  mov     a,x
        xcn     a
        lsr     a
        or      a,#dspChADSR1
        mov     y,a
        mov     a,!wChADSR+x
        call    !SetDSP
        inc     y
        mov     a,!wChADSR+1+x
        jmp     !SetDSP

.endproc  ; UpdateChADSR

; ---------------------------------------------------------------------------

; [ channel command $ec: set adsr decay ]

.proc SetADSRDecay

_094f:  and     a,#$07
        xcn     a
        mov     zChParam,a
        mov     a,!wChADSR+x
        and     a,#$0f
        or      a,zChParam
        or      a,#$80
        mov     !wChADSR+x,a
        bra     UpdateChADSR

.endproc  ; SetADSRDecay

; ---------------------------------------------------------------------------

; [ channel command $ed: set adsr sustain ]

.proc SetADSRSustain

_0962:  and     a,#$07
        xcn     a
        asl     a
        mov     zChParam,a
        mov     a,!wChADSR+1+x
        and     a,#$1f
        or      a,zChParam
        mov     !wChADSR+1+x,a
        bra     UpdateChADSR

.endproc  ; SetADSRSustain

; ---------------------------------------------------------------------------

; [ channel command $ee: set adsr release ]

.proc SetADSRRelease

_0974:  and     a,#$1f
        mov     zChParam,a
        mov     a,!wChADSR+1+x
        and     a,#$e0
        or      a,zChParam
        mov     !wChADSR+1+x,a
        bra     UpdateChADSR

.endproc  ; SetADSRRelease

; ---------------------------------------------------------------------------

; [ channel command $ef: set adsr to default ]

.proc SetADSRDefault

_0984:  mov     a,zChSample+x
        asl     a
        mov     y,a
        mov     a,!wSampleADSR+y
        mov     !wChADSR+x,a
        mov     a,!wSampleADSR+1+y
        mov     !wChADSR+1+x,a
        bra     UpdateChADSR

.endproc  ; SetADSRDefault

; ---------------------------------------------------------------------------

; [ channel command $fa: unconditional jump ]

.proc UncondJump

_0996:  mov     y,a
        call    !GetNextParam
        bsfx    _09a7
        mov     a,y
        mov     y,zChParam
        addw    ya,zScriptOffset
        mov     zScriptPtr+x,a
        mov     zScriptPtr+1+x,y
_09a7:  ret

.endproc  ; UncondJump

; ---------------------------------------------------------------------------

; [ channel command $f9: volta repeat ]

;  p1: ending number
; +p2: branch pointer

.proc VoltaRepeat

_09a8:  mov     zScratch2,a
        call    !GetNextParam
        mov     zScratch0,a
        call    !GetNextParam
        mov     zScratch1,a
        bsfx    _09cc
        mov     y,zRepeatDepth+x
        mov     a,!wRepeatCounter+y
        inc     a
        mov     !wRepeatCounter+y,a
        cbne    zScratch2,_09cc         ; return if ending number doesn't match
        movw    ya,zScratch0
        addw    ya,zScriptOffset
        mov     zScriptPtr+x,a
        mov     zScriptPtr+1+x,y
_09cc:  ret

.endproc  ; VoltaRepeat

; ---------------------------------------------------------------------------

; [ channel command $f0: start repeat ]

; p1: repeat count

.proc StartRepeat

_09cd:  inc     zRepeatDepth+x
        mov     a,x
        asl     a
        clrc
        adc     a,#4
        cbne    zRepeatDepth+x,_09dc    ; branch if not at max loop depth
        setc
        sbc     a,#4
        mov     zRepeatDepth+x,a
_09dc:  mov     y,zRepeatDepth+x
        mov     a,zChParam
        beq     _09e3
        inc     a
_09e3:  mov     !wRepeatCount+y,a
        bsfx    _09ef
        mov     a,#0
        mov     !wRepeatCounter+y,a
_09ef:  mov     a,y
        asl     a
        mov     y,a
        mov     a,zScriptPtr+x
        mov     !wRepeatPtr+y,a
        mov     a,zScriptPtr+1+x
        mov     !wRepeatPtr+1+y,a
        ret

.endproc  ; StartRepeat

; ---------------------------------------------------------------------------

; [ channel command $f1: end repeat ]

.proc EndRepeat

_09fd:  mov     y,zRepeatDepth+x
        mov     a,!wRepeatCount+y
        beq     _0a19
        dec     a
        bne     _0a16
        mov     a,x
        asl     a
        dec     a
        dec     zRepeatDepth+x
        cbne    zRepeatDepth+x,_0a26
        clrc
        adc     a,#4
        mov     zRepeatDepth+x,a
        bra     _0a26
_0a16:  mov     !wRepeatCount+y,a
_0a19:  mov     a,y
        asl     a
        mov     y,a
        mov     a,!wRepeatPtr+y
        mov     zScriptPtr+x,a
        mov     a,!wRepeatPtr+1+y
        mov     zScriptPtr+1+x,a
_0a26:  ret

.endproc  ; EndRepeat

; ---------------------------------------------------------------------------

; [ channel command $fb: conditional jump ]

.proc CondJump

_0a27:  mov     y,a
        call    !GetNextParam
        bsfx    _0a41
        mov     a,zChMask
        and     a,zCondJumpEn
        beq     _0a41
        tclr1   !zCondJumpEn
        mov     a,y
        mov     y,zChParam
        addw    ya,zScriptOffset
        mov     zScriptPtr+x,a
        mov     zScriptPtr+1+x,y
_0a41:  ret

.endproc  ; CondJump

; ---------------------------------------------------------------------------

; [ channel command $e9: set detune ]

.proc SetDetune

_0a42:  mov     !wChDetune+x,a
        ret

.endproc  ; SetDetune

; ---------------------------------------------------------------------------

; [ channel command $f2: end of script ]

.proc EndScript

_0a46:  pop     a
        pop     a

::EndScript_NoPop:
        mov     a,zChMask
        bsfx    _0a53
        tclr1   !zActiveSongCh
        bra     _0a59
_0a53:  tclr1   !zActiveSfxCh
        tclr1   !zActiveSysCh
_0a59:  call    !DisableNoise
        call    !DisablePitchMod
        jmp     !DisableEcho

.endproc  ; EndScript

; ---------------------------------------------------------------------------

; [ update channel envelope counters ]

.proc UpdateChEnv

_0a62:  mov     a,!wChVolCounter+x
        beq     _0a8d
        dec     a
        mov     !wChVolCounter+x,a
        mov     a,!wChVol+x
        mov     zScratch0,a
        mov     a,!wChVol+1+x
        mov     zScratch1,a
        mov     a,!wChVolRate+1+x
        mov     y,a
        mov     a,!wChVolRate+x
        addw    ya,zScratch0
        mov     !wChVol+x,a
        mov     a,y
        cmp     a,!wChVol+1+x
        mov     !wChVol+1+x,a
        beq     _0a8d
        or      zNeedVolUpdate,zChMask
_0a8d:  mov     a,!wChPanCounter+x
        beq     _0ab8
        dec     a
        mov     !wChPanCounter+x,a
        mov     a,!wChPan+x
        mov     zScratch0,a
        mov     a,!wChPan+1+x
        mov     zScratch1,a
        mov     a,!wChPanRate+1+x
        mov     y,a
        mov     a,!wChPanRate+x
        addw    ya,zScratch0
        mov     !wChPan+x,a
        mov     a,y
        cmp     a,!wChPan+1+x
        mov     !wChPan+1+x,a
        beq     _0ab8
        or      zNeedVolUpdate,zChMask
_0ab8:  mov     a,!wPitchEnvRate+x
        mov     zScratch0,a
        mov     a,!wPitchEnvRate+1+x
        mov     zScratch1,a
        movw    ya,zScratch0
        beq     _0ae8
        mov     a,!wPitchEnvDur+x
        dec     a
        bne     _0ad2
        mov     !wPitchEnvRate+x,a
        mov     !wPitchEnvRate+1+x,a
_0ad2:  mov     !wPitchEnvDur+x,a
        mov     a,!wChFreq+1+x
        mov     y,a
        mov     a,!wChFreq+x
        addw    ya,zScratch0
        mov     !wChFreq+x,a
        mov     a,y
        mov     !wChFreq+1+x,a
        or      zNeedFreqUpdate,zChMask
_0ae8:  mov     a,!wPanCycleEn+x
        beq     _0b42
        mov     a,!wPanCycleRate+x
        mov     $34,a
        mov     a,!wPanCycleRate+1+x
        mov     zScratch1,a
        mov     a,!wChPanOffset+x
        mov     y,a
        mov     zScratch2,a
        mov     a,!wPanCycleOffset+x
        addw    ya,$34
        mov     !wPanCycleOffset+x,a
        mov     a,y
        bbs     zScratch1.7,_0b12
        bbs     zScratch2.7,_0b19
        bpl     _0b19
        mov     a,#$7f
        bra     _0b19
_0b12:  bbc     zScratch2.7,_0b19
        bmi     _0b19
        mov     a,#$80
_0b19:  cmp     a,!wChPanOffset+x
        mov     !wChPanOffset+x,a
        beq     _0b24
        or      zNeedVolUpdate,zChMask  ; update volume if pan changed
_0b24:  mov     a,!wPanCycleCounter+x
        dec     a
        bne     _0b3f
        eor     zScratch0,#<-1          ; negate cycle rate when counter = 0
        eor     zScratch1,#<-1
        incw    zScratch0
        mov     a,zScratch0
        mov     !wPanCycleRate+x,a
        mov     a,zScratch1
        mov     !wPanCycleRate+1+x,a
        mov     a,!wPanCycleDur+x
_0b3f:  mov     !wPanCycleCounter+x,a
_0b42:  ret

.endproc  ; UpdateChEnv

; ---------------------------------------------------------------------------

; [ update channel volume/frequency ]

.proc UpdateChVolFreq

_0b43:  mov     a,!wVibAmpl+x           ; zScratch1 = amplitude
        beq     _0bb4
        mov     y,a
        mov     a,!wVibDelayCounter+x
        bne     _0bb4
        mov     a,!wVibCycleCounter+x
        dec     a
        bne     _0bb1
        mov     a,!wChVibEnv+x          ; zScratch0 = envelope counter
        movw    zScratch0,ya
        mov     a,!wChVibMult+x         ; zScratch2 = fraction
        mov     zScratch2,a
        call    !CalcVibTremMult
        mov     !wChVibMult+x,a
        asl     a
        bne     _0b6a
        mov     y,a
        bra     _0ba4
_0b6a:  push    psw                     ; save msb of fraction in carry
        push    a
        push    a
        mov     a,zScratch0
        mov     !wChVibEnv+x,a
        mov     y,#15                   ; multiply frequency by 15/255
        mov     a,!wChFreq+1+x
        mul     ya
        movw    zScratch2,ya
        mov     y,#15
        mov     a,!wChFreq+x
        mul     ya
        mov     a,y
        mov     y,#0
        addw    ya,zScratch2
        mov     zScratch2,a
        pop     a                       ; apply multiplier
        mul     ya
        movw    zScratch4,ya
        pop     a
        mov     y,zScratch2
        mul     ya
        mov     a,y
        mov     y,#0
        addw    ya,zScratch4
        pop     psw                     ; get multiplier msb
        bcc     _0ba4
        eor     a,#<-1                  ; negate frequency offset
        mov     zScratch4,a
        mov     a,y
        eor     a,#<-1
        mov     zScratch5,a
        incw    zScratch4
        movw    ya,zScratch4
_0ba4:  mov     !wChFreqOffset+x,a
        mov     a,y
        mov     !wChFreqOffset+1+x,a
        or      zNeedFreqUpdate,zChMask
        mov     a,!wVibCycleDur+x
_0bb1:  mov     !wVibCycleCounter+x,a
_0bb4:  mov     a,!wTremAmpl+x
        beq     _0be6
        mov     y,a
        mov     a,!wTremDelayCounter+x
        bne     _0be6
        mov     a,!wTremCycleCounter+x
        dec     a
        bne     _0be3
        mov     a,!wChTremEnv+x
        movw    zScratch0,ya
        mov     a,!wChTremMult+x
        mov     zScratch2,a
        call    !CalcVibTremMult
        mov     !wChTremMult+x,a
        mov     !wChVolMult+x,a
        mov     a,zScratch0
        mov     !wChTremEnv+x,a
        or      zNeedVolUpdate,zChMask
        mov     a,!wTremCycleDur+x
_0be3:  mov     !wTremCycleCounter+x,a
_0be6:  movw    ya,zNeedVolUpdate
        bne     _0beb
        ret
_0beb:  mov     a,x                     ; calculate this channel's dsp address
        and     a,#$0f
        mov     zScratch0,a
        xcn     a
        lsr     a
        mov     zScratch1,a
        mov     a,zChMask
        and     a,zNeedVolUpdate
        bne     _0bfd
        jmp     !_0cb7                  ; skip volume update
_0bfd:  mov     zScratch2,#$80
        bbs     zSysFlags_Mono,_0c41    ; branch if mono
        mov     a,zChMask
        and     a,zActiveSysCh
        bne     _0c41
        bsfx    _0c11
        mov     a,zRelVol+1
        bra     _0c13
_0c11:  mov     a,zSfxRelVol+1
_0c13:  eor     a,#$80
        clrc
        bmi     _0c21
        adc     a,!wChPan+1+x
        bcc     _0c28
        mov     a,#$ff
        bra     _0c28
_0c21:  adc     a,!wChPan+1+x
        bcs     _0c28
        mov     a,#0
_0c28:  clrc
        adc     a,!wChPanOffset+x       ; add pan offset
        push    a
        mov     a,!wChPanOffset+x
        pop     a
        bmi     _0c39
        bcc     _0c3d
        mov     a,#$ff
        bra     _0c3d
_0c39:  bcs     _0c3d
        mov     a,#0
_0c3d:  eor     a,#<-1
        mov     zScratch2,a
_0c41:  mov     a,!wChVol+1+x
        mov     y,a
        mov     zScratch3,a
        mov     a,!wChVolMult+x
        asl     a
        beq     _0c5d                   ; branch if no volume multiplier
        bcc     _0c52                   ; branch if positive multiplier
        eor     a,#<-1
        inc     a
_0c52:  mul     ya                      ; apply tremolo multiplier
        bcs     _0c5d
        mov     a,y
        adc     a,zScratch3
        bcc     _0c5c
        mov     a,#$ff                  ; max $ff
_0c5c:  mov     y,a
_0c5d:  bsfx    _0c68
        mov     a,zAbsVol+1             ; apply master and song volume
        mul     ya
        mov     a,zSongVol
        bra     _0c74
_0c68:  mov     a,zChMask
        and     a,zActiveSysCh
        beq     _0c72
        mov     a,#$ff                  ; system sfx always max volume
        bra     _0c74
_0c72:  mov     a,zSfxVol+1             ; game sfx use sfx volume
_0c74:  mul     ya
        mov     zScratch3,y
        bnsfx   _0c81
        mov1    c,zSysFlags_SfxSwapLR
        mov1    zScratch0.0,c
_0c81:  mov     a,zScratch2
_0c83:  mov     y,a
        bsfx    _0c89
        mul     ya
_0c89:  mov     a,zScratch3
        mul     ya
        mov     a,zChMask
        and     a,zMutedCh
        beq     _0c94
        mov     y,#0
_0c94:  mov     a,y
        mov     y,zScratch0
        mov     !zChWaveVol+y,a
        lsr     a
        mov     y,a
        mov     a,zScratch1
        bnsfx   _0ca7
        bbc     zSysFlags_SfxSwapLR,_0ca7
        eor     a,#1
_0ca7:  mov     hDSPAddr,a
        mov     hDSPData,y
        mov     a,zScratch2
        eor     a,#<-1
        not1    zScratch0.0
        inc     zScratch1               ; do other side
        bbc     zScratch1.1,_0c83
_0cb7:  set1    zScratch1.1             ; dsp reg for channel freq
        mov     a,zChMask
        and     a,zNeedFreqUpdate
        beq     _0d0e
        mov     a,!wChFreq+x
        mov     zScratch2,a
        mov     a,!wChFreq+1+x
        mov     zScratch3,a
        mov     a,!wChFreqOffset+1+x
        mov     y,a
        mov     a,!wChFreqOffset+x
        addw    ya,zScratch2
        movw    zScratch2,ya
        push    a
        mov     a,zChMask
        and     a,zActiveSysCh
        pop     a
        bne     _0d01
        bsfx    _0ce4
        mov     a,zRelPitchMult+1
        bra     _0ce6
_0ce4:  mov     a,zSfxPitchMult+1
_0ce6:  eor     a,#$80
        push    psw
        push    a
        mul     ya
        movw    zScratch4,ya
        pop     a
        mov     y,zScratch2
        mul     ya
        mov     a,y
        mov     y,#0
        addw    ya,zScratch4
        pop     psw
        bmi     _0d01
        asl     a
        push    a
        mov     a,y
        rol     a
        mov     y,a
        pop     a
        addw    ya,zScratch2
_0d01:  mov     x,zScratch1
        mov     hDSPAddr,x
        mov     hDSPData,a
        inc     x
        mov     hDSPAddr,x
        mov     hDSPData,y
        mov     x,zChPtr
_0d0e:  mov     a,zChMask
        tclr1   !zNeedVolUpdate
        tclr1   !zNeedFreqUpdate
        ret

.endproc  ; UpdateChVolFreq

; ---------------------------------------------------------------------------

; [ calculate vibrato/tremolo multiplier ]

.proc CalcVibTremMult

_0d17:  mov       a,y
        and       a,#$3f
        asl       a
        inc       a
        bbc       zScratch1.7,_0d28     ; branch if not balanced oscillations
        bbc       zScratch1.6,_0d28
        bbc       zScratch2.7,_0d63     ; branch if multiplier is positive
        mov       zScratch2,#0
_0d28:  asl       zScratch2
        bne       _0d55
        mov       y,zScratch0
        beq       _0d57
        bbc       zScratch0.0,_0d3c
        clr1      zScratch0.0           ; first cycle (1/4)
        lsr       a
        lsr       a
        bne       _0d57
        inc       a
        bra       _0d57
_0d3c:  bbc       zScratch0.1,_0d47
        clr1      zScratch0.1           ; second cycle (1/2)
        lsr       a
        bne       _0d57
        inc       a
        bra       _0d57
_0d47:  clr1      zScratch0.2           ; third cycle (3/4)
        lsr       a
        mov       zScratch4,a
        lsr       a
        clrc
        adc       a,zScratch4
        bne       _0d57
        inc       a
        bra       _0d57
_0d55:  mov       a,#0
_0d57:  and       zScratch1,#$40        ; multiplier sign = ~ampl.6
        asl       zScratch1
        eor       zScratch1,#$80
        or        a,zScratch1
        bra       _0d67
_0d63:  mov       a,zScratch2           ; negate multiplier
        or        a,#$80
_0d67:  ret

.endproc  ; CalcVibTremMult

; ---------------------------------------------------------------------------

; [ check interrupts ]

.proc CheckInt

_0d68:  mov     x,hPort0
        beq     _0da7                   ; return if no interrupt
        movw    ya,hPort2
        movw    zPort2,ya
        movw    ya,hPort0
        movw    zPort0,ya
        mov     hPort0,a
_0d76:  cmp     a,hPort0
        beq     _0d76                   ; wait for snes
        mov     x,a
        bpl     _0d8a
        cmp     x,#$fe
        bne     _0d84
        jmp     !TfrData                ; interrupt $fe
_0d84:  mov     hPort0,#0
        jmp     !ExecInt                ; interrupts $8x and $fx
_0d8a:  cmp     x,#1
        beq     PlaySong                ; interrupt $01
        cmp     x,#3
        beq     PlaySong                ; interrupt $03
        mov     $f4,#0
        cmp     x,#2
        bne     _0d9c
        jmp     !PlaySfx                ; interrupt $02
_0d9c:  bnsfx   _0da7
        cmp     x,#$20
        bcs     _0da7
        jmp     !PlaySysSfx             ; interrupts $10-$1f
_0da7:  ret

.endproc  ; CheckInt

; ---------------------------------------------------------------------------

; [ interrupt $01/$03: play song ]

; p0: 1 = don't suspend current song, 3 = suspend current song
; p1: song id
; p2: ddddrrrr
;     d: volume envelope duration (initial to final)
;     r: relative volume
; p3: iiiiffff
;     i: initial absolute volume
;     f: final absolute volume

.proc PlaySong

_0da8:  mov     a,#$ff
        mov     y,#dspKeyOff
        call    !SetDSP
        mov     hCtrlReg,#$00
        mov     hTimer0,#64             ; wait 8 ms
        mov     hCtrlReg,#$01
        mov     a,hCounter0
_0dba:  mov     a,hCounter0
        beq     _0dba
        mov     hCtrlReg,#$00
        mov     hTimer0,#36             ; set timer 0 (4.5 ms)
        mov     hCtrlReg,#$01
        call    !TfrData                ; transfer script and brr data
        cmp     zPort0,#3
        bne     _0dd4
        call    !SuspendSong
        mov     a,#0
_0dd4:  mov     zSongId,zPort1
        mov     y,a
        movw    zActiveSongCh,ya
        mov     zActiveSysCh,a
        movw    zChEchoEn,ya
        movw    zChNoiseEn,ya
        movw    zChPitchModEn,ya
        mov     zEchoEn,a
        mov     zNoiseEn,a
        mov     zPitchModEn,a
        clr1    zSysFlags_FastFwd
        movw    zKeyOn,ya
        mov     zEchoVol+1,a
        mov     zEchoVolCounter,a       ; reset tempo multipliers
        mov     zRelTempoMult+1,a
        mov     zSfxTempoMult+1,a
        set1    zRelTempoMult+1.7
        set1    zSfxTempoMult+1.7
        mov     zRelTempoCounter,a
        mov     zSfxTempoCounter,a
        mov     zRelPitchMult+1,a
        mov     zSfxPitchMult+1,a
        set1    zRelPitchMult+1.7
        set1    zSfxPitchMult+1.7
        mov     zRelPitchCounter,a
        mov     zSfxPitchCounter,a
        movw    zNeedVolUpdate,ya
        movw    zIsTie,ya
        mov     zCondJumpEn,a
        movw    zd8,ya
        mov     zTempo+1,#$01
        mov     zSongTickCounter,#$ff
        mov     zSongVol,#$ff
        bbs     zSysFlags_WaveEn,_0e1e
        mov     zMutedCh,a
_0e1e:  mov     a,#0
        mov     y,#dspEchoEn
        call    !SetDSP
        mov     y,#dspEchoFeedback
        call    !SetDSP
        mov     y,#dspEchoVolL
        call    !SetDSP
        mov     y,#dspEchoVolR
        call    !SetDSP
        call    !ClearEchoBuf
        bbc     zChParam.3,_0e3d
        jmp     !_0eb2
_0e3d:  cmp     zSuspSongId,zSongId
        bne     _0e47
        call    !ResumeSong
        bra     _0e8a
_0e47:  mov     x,#$10
_0e49:  mov     a,!wSongScripts+1+x
        mov     zNotePitchConst+1+x,a
        dec     x
        bne     _0e49
        mov     a,!wSongScripts
        mov     zScriptOffset,a
        mov     a,!wSongScripts+1
        mov     zScriptOffset+1,a
        mov     a,#$14
        mov     y,#$1c
        subw    ya,zScriptOffset
        movw    zScriptOffset,ya
        mov     x,#$0e
        mov     zChMask,#$80
        mov     a,!wSongScripts+18
        mov     y,!wSongScripts+19
        movw    zScratch0,ya
_0e70:  mov     a,zScriptPtr+x
        mov     y,zScriptPtr+1+x
        cmpw    ya,zScratch0
        beq     _0e84
        or      zActiveSongCh,zChMask
        addw    ya,zScriptOffset
        mov     zScriptPtr+x,a
        mov     zScriptPtr+1+x,y
        call    !InitCh
_0e84:  dec     x
        dec     x
        lsr     zChMask
        bne     _0e70
_0e8a:  mov     a,zPort2
        and     a,#$0f
        beq     _0e93
        xcn     a
        mov     zRelVol+1,a
_0e93:  mov     a,zPort3
        and     a,#$f0
        xcn     a
        mov     y,#$11
        mul     ya
        mov     zAbsVol+1,a
        mov     a,zPort2
        and     a,#$f0
        mov     zPort1,a
        mov     a,zPort3
        and     a,#$0f
        or      a,zPort1
        mov     zPort1,a
        mov     a,#$81                  ; do interrupt $81
        mov     zPort0,a
        call    !SetVolAbs
_0eb2:  mov     x,#<wStackInit          ; reset stack pointer
        mov     sp,x
        mov     a,hCounter0
        jmp     !MainLoop

.endproc  ; PlaySong

; ---------------------------------------------------------------------------

; [ initialize channel ]

.proc InitCh

_0eba:  mov     a,x
        asl     a
        mov     zRepeatDepth+x,a
        mov     a,#0
        mov     !wPitchEnvOffset+x,a
        mov     !wPitchEnvRate+x,a
        mov     !wPitchEnvRate+1+x,a
        mov     !wVibAmpl+x,a
        mov     !wTremAmpl+x,a
        mov     !wPanCycleEn+x,a
        mov     !wPanCycleOffset+x,a
        mov     !wChPanOffset+x,a
        mov     !wChDetune+x,a
        mov     !wChTranspose+x,a
        inc     a
        mov     zTickCounter+x,a
        ret

.endproc  ; InitCh

; ---------------------------------------------------------------------------

; [ interrupt $02: play game sound effect ]

; p1: sound effect id
; p2: ddddrrrr
;     d: volume envelope duration (initial to final)
;     r: initial relative volume
; p3: aaaaffff
;     a: absolute volume
;     f: final relative volume

.proc PlaySfx

_0ee2:  mov     zIntAddr,zPort1
        mov     zIntAddr+1,#0
        aslw    zIntAddr
        aslw    zIntAddr
        mov     a,#<wGameSfxPtrs        ; add $2c00
        mov     y,#>wGameSfxPtrs
        addw    ya,zIntAddr
        movw    zIntAddr,ya             ; zIntAddr = ptr to sfx script
        mov     x,#$1e                  ; start in sfx channel 7
        mov     zChMask,#$80
        mov     a,zActiveSfxCh
        bne     _0f05
        mov     a,zActiveSysCh
        eor     a,#$f0
_0f05:  mov     z03,a
_0f07:  mov     a,z03
        and     a,zChMask
        bne     _0f14
        lsr     zChMask                 ; try next sfx channel
        dec     x
        dec     x
        bbc     zChMask.5,_0f07
_0f14:  mov     y,#3                    ; loop through 2 voices
        mov     z03,#0
_0f19:  mov     a,[zIntAddr]+y          ; get channel script pointer
        beq     _0f49                   ; branch if no script for this voice
        mov     zScriptPtr+1+x,a
        dec     y
        mov     a,[zIntAddr]+y
        mov     zScriptPtr+x,a
        or      z03,zChMask
        call    !InitCh
        inc     zTickCounter+x
        mov     a,#$60                  ; set volume
        mov     !wChVol+1+x,a
        mov     a,#$80                  ; pan to center
        mov     !wChPan+1+x,a
        mov     a,#0                    ; clear volume/pan envelope counters
        mov     !wChVolCounter+x,a
        mov     !wChPanCounter+x,a
        push    y
        call    !SetSample
        pop     y                       ; next channel
        dec     x
        dec     x
        lsr     zChMask
        bra     _0f4a
_0f49:  dec     y
_0f4a:  dec     y
        bpl     _0f19
        mov     a,zActiveSfxCh
        or      a,z03
        tclr1   !zKeyOn
        tclr1   !zSfxIsTie
        tset1   !zKeyOff
        mov     z02,a
        mov     x,#$1e
        mov     zChMask,#$80
_0f61:  asl     z02
        bcc     _0f68
        call    !EndScript_NoPop
_0f68:  dec     x
        dec     x
        lsr     zChMask
        bbc     zChMask.3,_0f61
        mov     a,z03
        mov     zActiveSfxCh,a
        tclr1   !zEchoEn
        tclr1   !zPitchModEn
        tclr1   !zNoiseEn
        mov     a,zPort2
        and     a,#$0f                  ; sfx volume
        mov     y,#$11
        mul     ya
        mov     zSfxVol+1,a
        mov     a,zPort3
        beq     _0fa4
        and     a,#$f0
        beq     _0f8f
        mov     zSfxRelVol+1,a
_0f8f:  mov     a,zPort2
        and     a,#$f0
        mov     zPort1,a
        mov     a,zPort3
        and     a,#$0f
        or      a,zPort1
        mov     zPort1,a
        mov     a,#$85                  ; do interrupt $85
        mov     zPort0,a
        jmp     !SetVolRel
_0fa4:  ret

.endproc  ; PlaySfx

; ---------------------------------------------------------------------------

; [ interrupt $10-$1f: play system sound effect ]

; lo nybble is sound effect id

.proc PlaySysSfx

_0fa5:  mov     a,x
        and     a,#$0f
        asl     a
        mov     y,a
        mov     x,#$20                  ; start at sfx channel 7
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        and     a,#$f0
        mov     zChMask,#$80
        cmp     a,#$f0
        beq     _0fc5                   ; all 4 sfx channels already active
_0fb9:  dec     x
        dec     x
        asl     a
        bcc     _0fd2                   ; find an unused channel
        lsr     zChMask
        bbc     zChMask.3,_0fb9
        bra     _0fd2
_0fc5:  dec     x
        dec     x
        mov     a,zActiveSysCh
        and     a,zChMask               ; overwrite a system sfx channel
        bne     _0fd2
        lsr     zChMask
        bbc     zChMask.3,_0fc5
_0fd2:  mov     a,!SysSfxPtrs+1+y       ; pointers to system sound effects
        beq     _0ffd
        mov     zScriptPtr+1+x,a
        mov     a,!SysSfxPtrs+y
        mov     zScriptPtr+x,a
        call    !InitCh
        inc     zTickCounter+x
        call    !EndScript_NoPop
        mov     a,zChMask
        tclr1   !zSfxIsTie
        tset1   !zKeyOff
        tclr1   !zKeyOn
        tclr1   !zEchoEn
        tclr1   !zPitchModEn
        tclr1   !zNoiseEn
        or      zActiveSysCh,zChMask
_0ffd:  ret

.endproc  ; PlaySysSfx

; ---------------------------------------------------------------------------

; [ execute interrupts $8x and $fx ]

.proc ExecInt

_0ffe:  cmp     x,#$f0
        bcs     _1006
        cmp     x,#$90
        bcs     _1013                   ; interrupts $90-$ef have no effect
_1006:  mov     a,x
        and     a,#$1f
        asl     a
        mov     y,a
        mov     a,!IntPtrs+1+y
        push    a
        mov     a,!IntPtrs+y
        push    a
_1013:  ret

.endproc  ; ExecInt

; ---------------------------------------------------------------------------

; [ interrupt $80/$81/$82: set volume (absolute) ]

; p0: $80 = affect song & sfx, $81 = affect song only, $82 = affect sfx only
; p1: ddddmmmm
;     d: duration (multiply by 16)
;     m: volume

.proc SetVolAbs

_1014:  mov     a,zPort1
        and     zPort1,#$f0
        and     a,#$0f
        mov     y,#$11
        mul     ya
        mov     zPort2,a
        mov     x,#0
        mov     a,zPort0
        bbc     zPort0.0,_102a          ; branch if command $81
        inc     a
        bra     _1037
_102a:  bbc     zPort0.1,_1032          ; branch if command $80
        inc     a
        mov     x,#2
        bra     _1037
_1032:  inc     zPort0
        clrc
        adc     a,#3
_1037:  mov     zScratch0,a
_1039:  mov     y,zPort2
        mov     a,zPort1
_103d:  mov     zAbsVolCounter+x,a
        bne     _104b
        mov     zAbsVol+1+x,y
        mov     zAbsVol+x,a
        mov     zAbsVolRate+1+x,a
        mov     zAbsVolRate+x,a
        bra     _1080
_104b:  mov     a,y
        setc
        sbc     a,zAbsVol+1+x           ; get volume difference
        beq     _103d
        push    x
        push    psw
        bcs     _1058
        eor     a,#<-1
        inc     a
_1058:  mov     x,zPort1
        mov     y,#0
        div     ya,x
        mov     zScratch3,a
        mov     a,#0
        div     ya,x
        mov     zScratch2,a
        movw    ya,zScratch2
        bne     _106a
        inc     zScratch2
_106a:  pop     psw
        bcs     _1075
        eor     zScratch2,#<-1
        eor     zScratch3,#<-1
        incw    zScratch2
_1075:  movw    ya,zScratch2
        pop     x
        mov     zAbsVolRate+x,a
        mov     zAbsVolRate+1+x,y
        mov     a,#0
        mov     zAbsVol+x,a
_1080:  inc     zPort0
        cmp     zPort0,zScratch0
        beq     _108b
        inc     x
        inc     x
        bra     _1039
_108b:  mov     zNeedVolUpdate,#$ff
        ret

.endproc  ; SetVolAbs

; ---------------------------------------------------------------------------

; [ interrupt $83/$84/$85: set volume multiplier (relative) ]

; p0: $83 = affect song & sfx, $84 = affect song only, $85 = affect sfx only
; p1: ddddmmmm
;     d: duration (multiply by 16)
;     m: multiplier

.proc SetVolRel

_108f:  inc     zPort0
        mov     a,zPort1
        and     a,#$0f
        beq     _1108
        and     zPort1,#$f0
        xcn     a
        mov     zPort2,a
        mov     x,#0                    ; affect song
        mov     a,zPort0
        bbc     zPort0.0,_10a7
        inc     a
        bra     _10b4
_10a7:  bbc     zPort0.1,_10af
        inc     a
        mov     x,#2                    ; affect sfx
        bra     _10b4
_10af:  inc     zPort0
        clrc
        adc     a,#3                    ; affect both
_10b4:  mov     zScratch0,a
_10b6:  mov     y,zPort2                ; multiplier
        mov     a,zPort1                ; duration
_10ba:  mov     zRelVolCounter+x,a
        bne     _10c8
        mov     zRelVol+1+x,y           ; set multiplier immediately
        mov     zRelVol+x,a
        mov     zRelVolRate+1+x,a
        mov     zRelVolRate+x,a
        bra     _10fd
_10c8:  mov     a,y
        setc
        sbc     a,zRelVol+1+x           ; get change in multiplier
        beq     _10ba                   ; branch if no change
        push    x
        push    psw
        bcs     _10d5
        eor     a,#<-1
        inc     a
_10d5:  mov     x,zPort1
        mov     y,#0
        div     ya,x
        mov     zScratch3,a
        mov     a,#0
        div     ya,x                    ; rate = change / duration
        mov     zScratch2,a
        movw    ya,zScratch2
        bne     _10e7
        inc     zScratch2
_10e7:  pop     psw
        bcs     _10f2
        eor     zScratch2,#<-1
        eor     zScratch3,#<-1
        incw    zScratch2
_10f2:  movw    ya,zScratch2
        pop     x
        mov     zRelVolRate+x,a
        mov     zRelVolRate+1+x,y
        mov     a,#0
        mov     zRelVol+x,a
_10fd:  inc     zPort0
        cmp     zPort0,zScratch0
        beq     _1108
        inc     x
        inc     x
        bra     _10b6
_1108:  mov     zNeedVolUpdate,#$ff
        ret

.endproc  ; SetVolRel

; ---------------------------------------------------------------------------

; [ interrupt $86/$87/$88: set tempo multiplier (relative) ]

; p0: $86 = affect song & sfx, $87 = affect song only, $88 = affect sfx only
; p1: ddddmmmm
;     d: duration (multiply by 16)
;     m: multiplier (signed, multiply by 18)

.proc SetTempoRel

_110c:  mov     a,zPort1
        and     a,#$07
        beq     _111c
        bbc     zPort1.3,_1116
        dec     a
_1116:  mov     y,#18
        mul     ya
        bbs     zPort1.3,_111e
_111c:  eor     a,#$80
_111e:  mov     zPort2,a                ; multiplier
        and     zPort1,#$f0
        mov     x,#0
        mov     a,zPort0
        bbc     zPort0.0,_112d
        inc     a
        bra     _113a
_112d:  bbs     zPort0.1,_1135
        inc     a
        mov     x,#2
        bra     _113a
_1135:  inc     zPort0
        clrc
        adc     a,#3
_113a:  mov     zScratch0,a
_113c:  mov     y,zPort2
        mov     a,zPort1
_1140:  mov     zRelTempoCounter+x,a
        bne     _114e
        mov     zRelTempoMult+1+x,y     ; set immediately
        mov     zRelTempoMult+x,a
        mov     zRelTempoRate+1+x,a
        mov     zRelTempoRate+x,a
        bra     _1183
_114e:  mov     a,y
        setc
        sbc     a,zRelTempoMult+1+x
        beq     _1140
        push    x
        push    psw
        bcs     _115b
        eor     a,#<-1
        inc     a
_115b:  mov     x,zPort1
        mov     y,#0
        div     ya,x
        mov     zScratch3,a
        mov     a,#0
        div     ya,x
        mov     zScratch2,a
        movw    ya,zScratch2
        bne     _116d
        inc     zScratch2
_116d:  pop     psw
        bcs     _1178
        eor     zScratch2,#<-1
        eor     zScratch3,#<-1
        incw    zScratch2
_1178:  movw    ya,zScratch2
        pop     x
        mov     zRelTempoRate+x,a
        mov     zRelTempoRate+1+x,y
        mov     a,#0
        mov     zRelTempoMult+x,a
_1183:  inc     zPort0
        cmp     zPort0,zScratch0
        beq     _118e
        inc     x
        inc     x
        bra     _113c
_118e:  ret

.endproc  ; SetTempoRel

; ---------------------------------------------------------------------------

; [ interrupt $89/$8a/$8b: set pitch multiplier (relative) ]

; p0: $89 = affect song & sfx, $8a = affect song only, $8b = affect sfx only
; p1: ddddmmmm
;     d: duration (multiply by 16)
;     m: multiplier (signed, multiply by 18)

.proc SetPitchRel

_118f:  inc     zPort0
        mov     a,zPort1
        and     a,#$07
        beq     _11a1
        bbc     zPort1.3,_119b
        dec     a
_119b:  mov     y,#18
        mul     ya
        bbs     zPort1.3,_11a3
_11a1:  eor     a,#$80
_11a3:  mov     zPort2,a
        and     zPort1,#$f0
        mov     x,#0
        mov     a,zPort0
        bbc     zPort0.0,_11b2
        inc     a
        bra     _11bf
_11b2:  bbs     zPort0.1,_11ba
        inc     a
        mov     x,#2
        bra     _11bf
_11ba:  inc     zPort0
        clrc
        adc     a,#3
_11bf:  mov     zScratch0,a
_11c1:  mov     y,zPort2
        mov     a,zPort1
_11c5:  mov     zRelPitchCounter+x,a
        bne     _11d3
        mov     zRelPitchMult+1+x,y
        mov     zRelPitchMult+x,a
        mov     zRelPitchRate+1+x,a
        mov     zRelPitchRate+x,a
        bra     _1208
_11d3:  mov     a,y
        setc
        sbc     a,zRelPitchMult+1+x
        beq     _11c5
        push    x
        push    psw
        bcs     _11e0
        eor     a,#<-1
        inc     a
_11e0:  mov     x,zPort1
        mov     y,#0
        div     ya,x
        mov     zScratch3,a
        mov     a,#0
        div     ya,x
        mov     zScratch2,a
        movw    ya,zScratch2
        bne     _11f2
        inc     zScratch2
_11f2:  pop     psw
        bcs     _11fd
        eor     zScratch2,#<-1
        eor     zScratch3,#<-1
        incw    zScratch2
_11fd:  movw    ya,zScratch2
        pop     x
        mov     zRelPitchRate+x,a
        mov     zRelPitchRate+1+x,y
        mov     a,#0
        mov     zRelPitchMult+x,a
_1208:  inc     zPort0
        cmp     zPort0,zScratch0
        beq     _1213
        inc     x
        inc     x
        bra     _11c1
_1213:  ret

.endproc  ; SetPitchRel

; ---------------------------------------------------------------------------

; [ interrupt $f3/$f4: change to mono/stereo ]

; p0: $f3 = stereo, $f4 = mono

.proc SetMono

_1214:  bbc     zPort0.0,_121b
        clr1    zSysFlags_Mono
        bra     _121d
_121b:  set1    zSysFlags_Mono
_121d:  mov     zNeedVolUpdate,#$ff
        ret

.endproc  ; SetMono

; ---------------------------------------------------------------------------

; [ interrupt $f0/$f1/$f2: stop sound ]

; p0: $f0 = stop music & sfx, $f1 = stop music, $f2 = stop sfx

.proc StopSound

_1221:  bbs     zPort0.1,_124d
        mov     a,zActiveSfxCh
        or      a,zActiveSysCh
        eor     a,#<-1
        tset1   !zKeyOff
        tclr1   !zKeyOn
        tclr1   !zEchoEn
        tclr1   !zPitchModEn
        tclr1   !zNoiseEn
        mov     a,#0
        mov     zActiveSongCh,a
        mov     zd8,a
        mov     zChEchoEn,a
        mov     zChPitchModEn,a
        mov     zChNoiseEn,a
        dec     a
        mov     zSuspSongId,a
        mov     zSongId,a
        bbs     zPort0.0,_126a
_124d:  mov     a,zActiveSfxCh
        tset1   !zKeyOff
        tclr1   !zKeyOn
        mov     z02,a
        mov     x,#$1e
        mov     zChMask,#$80
_125c:  asl     z02
        bcc     _1263
        call    !EndScript_NoPop
_1263:  dec     x
        dec     x
        lsr     zChMask
        bbc     zChMask.3,_125c
_126a:  ret

.endproc  ; StopSound

; ---------------------------------------------------------------------------

; [ interrupt $f5: mute/unmute channels ]

.proc SetMute

_126b:  mov     zMutedCh,zPort1
        mov     zNeedVolUpdate,#$ff
        ret

.endproc  ; SetMute

; ---------------------------------------------------------------------------

; [ interrupt $fb: enable conditional jump ]

.proc EnableCondLoop

_1272:  mov     zCondJumpEn,zActiveSongCh
        ret

.endproc  ; EnableCondLoop

; ---------------------------------------------------------------------------

; [ interrupt $fc: reflect sound effect r/l ]

; p1: 0 = normal, 1 = flipped

.proc ReflectSfx

_1276:  clrc
        mov     a,#$ff
        adc     a,$c2
        mov1    zSysFlags_SfxSwapLR,c
        ret

.endproc  ; ReflectSfx

; ---------------------------------------------------------------------------

; [ interrupt $f6/$f7:  ]

; p0: $f6 = , $f7 =

.proc Unknown_127f

_127f:  bbs     zPort0.0,_12bc
        mov     y,#dspChADSR1
_1284:  mov     hDSPAddr,y              ; disable adsr in all channels
        mov     a,hDSPData
        and     a,#$7f
        mov     hDSPData,a
        mov     a,y
        clrc
        adc     a,#$10
        mov     y,a
        bpl     _1284
        mov     x,#0
        mov     y,#dspChVolL
_1297:  mov     hDSPAddr,y              ; set channel volume to zero
        mov     hDSPData,x
        inc     y
        mov     hDSPAddr,y
        mov     hDSPData,x
        mov     a,y
        clrc
        adc     a,#$0f
        mov     y,a
        bpl     _1297
        movw    ya,zActiveSongCh
        beq     _12b1
        movw    zd8,ya                  ; save active channels
        movw    ya,zZero
        movw    zActiveSongCh,ya
_12b1:  mov     zKeyOn,a
        mov     y,#$10
_12b5:  mov     !zChWaveVol-1+y,a
        dbnz    y,_12b5
        bra     _12da
_12bc:  mov     y,#dspChADSR1
_12be:  mov     hDSPAddr,y              ; enable adsr in all channels
        mov     a,hDSPData
        or      a,#$80
        mov     hDSPData,a
        mov     a,y
        clrc
        adc     a,#$10
        mov     y,a
        bpl     _12be
        movw    ya,zd8
        beq     _12da
        mov     zNeedVolUpdate,#$ff
        movw    zActiveSongCh,ya
        movw    ya,zZero
        movw    zd8,ya
_12da:  ret

.endproc  ; Unknown_127f

; ---------------------------------------------------------------------------

; [ interrupt command $fe: transfer data ]

; p1: transfer mode
;     0 = no transfer
;     1 = one byte at a time
;     2 = two bytes at a time
;     3 = three bytes at a time
;     7 = move chunk
; p2: source address

.proc TfrData

_12db:  mov     a,hPort1
        mov     zChParam,a
        and     a,#7                    ; transfer mode
        mov     hPort1,a
        bne     _12e9
        mov     hPort0,x
        bra     _1304
_12e9:  asl     a
        push    a
        movw    ya,hPort2
        movw    zIntAddr,ya             ; source address
        pop     y
        mov     a,!TfrPtrs+1+y          ; transfer mode jump table
        push    a
        mov     a,!TfrPtrs+y
        push    a
        mov     y,#0
        mov     x,hPort0
        mov     hPort0,x
_12fe:  cmp     x,hPort0
        beq     _12fe
        mov     x,hPort0
_1304:  ret

.endproc  ; TfrData

; ---------------------------------------------------------------------------

; [ transfer mode $03: three bytes at a time ]

.proc Tfr3

_1305:  mov     a,hPort1
        mov     [zIntAddr]+y,a
        incw    zIntAddr
        mov     a,hPort2
        mov     [zIntAddr]+y,a
        incw    zIntAddr
        mov     a,hPort3
        mov     [zIntAddr]+y,a
        incw    zIntAddr
        mov     hPort0,x
_1319:  cmp     x,hPort0
        beq     _1319
        mov     x,hPort0
        bne     Tfr3
        bra     TfrData

.endproc  ; Tfr3

; ---------------------------------------------------------------------------

; [ transfer mode $02: two bytes at a time ]

.proc Tfr2

_1323:  mov     a,hPort2
        mov     [zIntAddr]+y,a
        incw    zIntAddr
        mov     a,hPort3
        mov     [zIntAddr]+y,a
        incw    zIntAddr
        mov     hPort0,x
_1331:  cmp     x,hPort0
        beq     _1331
        mov     x,hPort0
        bne     Tfr2
        bra     TfrData

.endproc  ; Tfr2

; ---------------------------------------------------------------------------

; [ transfer mode $01: one byte at a time ]

.proc Tfr1

_133b:  mov     a,hPort3
        mov     [zIntAddr]+y,a
        incw    zIntAddr
        mov     hPort0,x
_1343:  cmp     x,hPort0
        beq     _1343
        mov     x,hPort0
        bne     Tfr1
        bra     TfrData

.endproc  ; Tfr1

; ---------------------------------------------------------------------------

; [ transfer mode $00: no transfer ]

.proc TfrNone

_134d:  mov     hPort0,x
_134f:  cmp     x,hPort0
        beq     _134f
        mov     x,hPort0
        bne     TfrNone
        jmp     !TfrData

.endproc  ; TfrNone

; ---------------------------------------------------------------------------

; [ transfer mode $07: move chunk ]

.proc MoveChunk

_135a:  movw    ya,hPort2
        movw    zMoveDest,ya            ; transfer destination
        mov     hPort0,x
_1360:  cmp     x,hPort0
        beq     _1360
        mov     x,hPort0
        movw    ya,hPort2
        movw    zScratch0,ya            ; transfer size
        mov     hPort0,x
        mov     y,#0
_136e:  mov     a,[zIntAddr]+y
        mov     [zMoveDest]+y,a
        inc     y
        bne     _1379
        inc     zIntAddr+1
        inc     zMoveDest + 1
_1379:  decw    zScratch0
        bne     _136e
_137d:  cmp     x,hPort0
        beq     _137d
        mov     x,hPort0
        beq     _1393
        movw    ya,hPort2               ; transfer another chunk
        movw    zIntAddr,ya
        mov     hPort0,x
_138b:  cmp     x,hPort0
        beq     _138b
        mov     x,hPort0
        bra     MoveChunk
_1393:  jmp     !TfrData

.endproc  ; MoveChunk

; ---------------------------------------------------------------------------

; [ interrupt $f8/$f9/$fa: enable/disable fast forward ]

; p0: $f8/$f9 = fast forward, $fa = normal

.proc SetFastForward

_1396:  not1    zPort0.1
        mov1    c,zPort0.1
        mov1    zSysFlags_FastFwd,c
        bcs     _13a5
        mov     a,#36                   ; 4.5 ms (normal)
        bra     _13a7
_13a5:  mov     a,#1                    ; 0.125 ms (fast forward)
_13a7:  mov     hCtrlReg,#$00
        mov     hTimer0,a               ; restart timer 0
        mov     hCtrlReg,#$01
        ret

.endproc  ; SetFastForward

; ---------------------------------------------------------------------------

; [ interrupt $ff: set output mode ]

; if ports read $ff,$fe,$fd,$fc, enable waveform mode
; otherwise, disable waveform mode

.proc SetOutputMode

_13b0:  mov     a,#$ff
        mov     y,#$fe
        cmpw    ya,zPort0
        bne     _13c4
        mov     a,#$fd
        mov     y,#$fc
        cmpw    ya,zPort2
        bne     _13c4
        set1    zSysFlags_WaveEn
        bra     _13c6
_13c4:  clr1    zSysFlags_WaveEn
_13c6:  ret

.endproc  ; SetOutputMode

; ---------------------------------------------------------------------------

; [ interrupt $8c/$8d/$8e/$8f: unused ]

.proc UnusedInt

        ret

.endproc  ; UnusedInt

; ---------------------------------------------------------------------------

; [ clear echo buffer ]

.proc ClearEchoBuf

_13c8:  mov     a,#<wEchoBuf
        mov     y,#>wEchoBuf
        movw    zIntAddr,ya
        mov     a,#0
        mov     y,a
_13d1:  mov     [zIntAddr]+y,a
        inc     y
        bne     _13d1
        inc     zIntAddr+1
        cmp     zIntAddr+1,#>wChVol
        bne     _13d1
        ret

.endproc  ; ClearEchoBuf

; ---------------------------------------------------------------------------

; [ suspend song ]

.proc SuspendSong

_13de:  mov     zSuspSongId,zSongId
        mov     a,zTempoCounter
        mov     !wSuspTempoCounter,a
        mov     a,zSongTickCounter
        mov     !wSuspSongTickCounter,a
        mov     a,zSongVol
        mov     !wfd8c,a
        mov     a,zEchoVolCounter
        mov     !wSuspEchoVolCounter,a
        mov     a,zActiveSongCh
        mov     !wSuspActiveSongCh,a
        mov     a,zChEchoEn
        mov     !wSuspChEchoEn,a
        mov     a,zChNoiseEn
        mov     !wSuspChNoiseEn,a
        mov     a,zChPitchModEn
        mov     !wSuspChPitchModEn,a
        mov     a,zIsTie
        mov     !wSuspIsTie,a
        mov     a,zCondJumpEn
        mov     !wSuspCondJumpEn,a
        mov     a,zNoiseFreq
        mov     !wSuspNoiseFreq,a
        mov     a,zEchoFilterId
        mov     !wSuspEchoFilterId,a
        mov     a,zEchoFeedback
        mov     !wSuspEchoFeedback,a
        movw    ya,zScriptOffset
        mov     !wSuspScriptOffset,a
        mov     !wSuspScriptOffset+1,y
        movw    ya,zTempo
        mov     !wSuspTempo,a
        mov     !wSuspTempo+1,y
        movw    ya,zTempoRate
        mov     !wSuspTempoRate,a
        mov     !wSuspTempoRate+1,y
        movw    ya,zEchoVol
        mov     !wSuspEchoVol,a
        mov     !wSuspEchoVol+1,y
        movw    ya,zEchoVolRate
        mov     !wSuspEchoVolRate,a
        mov     !wSuspEchoVolRate+1,y
        mov     x,#$0e
_144c:  mov     a,zTickCounter+x
        mov     !wSuspTickCounter+x,a
        mov     a,zChOctave+x
        mov     !wSuspChOctave+x,a
        mov     a,zRepeatDepth+x
        mov     !wSuspRepeatDepth+x,a
        mov     a,zChSample+x
        mov     !wSuspChSample+x,a
        mov     a,!wVibDelayCounter+x
        mov     !wSuspVibDelayCounter+x,a
        mov     a,!wTremDelayCounter+x
        mov     !wSuspTremDelayCounter+x,a
        mov     a,!wPitchEnvOffset+x
        mov     !wSuspPitchEnvOffset+x,a
        mov     a,!wVibAmpl+x
        mov     !wSuspVibAmpl+x,a
        mov     a,!wTremAmpl+x
        mov     !wSuspTremAmpl+x,a
        mov     a,!wPanCycleEn+x
        mov     !wSuspPanCycleEn+x,a
        mov     a,!wVibDelay+x
        mov     !wSuspVibDelay+x,a
        mov     a,!wTremDelay+x
        mov     !wSuspTremDelay+x,a
        mov     a,!wChVolCounter+x
        mov     !wSuspChVolCounter+x,a
        mov     a,!wChPanCounter+x
        mov     !wSuspChPanCounter+x,a
        mov     a,!wVibCycleDur+x
        mov     !wSuspVibCycleDur+x,a
        mov     a,!wTremCycleDur+x
        mov     !wSuspTremCycleDur+x,a
        mov     a,!wPanCycleDur+x
        mov     !wSuspPanCycleDur+x,a
        dec     x
        dec     x
        bpl     _144c
        mov     x,#$0e
_14b4:  mov     a,!wPitchEnvDur+x
        mov     !wSuspPitchEnvDur+x,a
        mov     a,!wVibCycleCounter+x
        mov     !wSuspVibCycleCounter+x,a
        mov     a,!wTremCycleCounter+x
        mov     !wSuspTremCycleCounter+x,a
        mov     a,!wPanCycleCounter+x
        mov     !wSuspPanCycleCounter+x,a
        mov     a,!wChDetune+x
        mov     !wSuspChDetune+x,a
        mov     a,!wChPitch+x
        mov     !wSuspChPitch+x,a
        mov     a,!wChTranspose+x
        mov     !wSuspChTranspose+x,a
        mov     a,!wChVibMult+x
        mov     !wSuspChVibMult+x,a
        mov     a,!wChTremMult+x
        mov     !wSuspChTremMult+x,a
        mov     a,!wChVolMult+x
        mov     !wSuspChVolMult+x,a
        mov     a,!wChVibEnv+x
        mov     !wSuspChVibEnv+x,a
        mov     a,!wChTremEnv+x
        mov     !wSuspChTremEnv+x,a
        dec     x
        dec     x
        bpl     _14b4
        mov     x,#$3f
_1502:  mov     a,!wRepeatPtr+x
        mov     !wSuspRepeatPtr+x,a
        dec     x
        cmp     x,#$20
        bcs     _1502
_150d:  mov     a,!wRepeatPtr+x
        mov     !wSuspRepeatPtr+x,a
        mov     a,!wRepeatCount+x
        mov     !wSuspRepeatCount+x,a
        mov     a,!wRepeatCounter+x
        mov     !wSuspRepeatCounter+x,a
        dec     x
        bsfx    _150d
_1524:  mov     a,!wRepeatPtr+x
        mov     !wSuspRepeatPtr+x,a
        mov     a,!wRepeatCount+x
        mov     !wSuspRepeatCount+x,a
        mov     a,!wRepeatCounter+x
        mov     !wSuspRepeatCounter+x,a
        mov     a,zScriptPtr+x
        mov     !wSuspScriptPtr+x,a
        mov     a,!wChVol+x
        mov     !wSuspChVol+x,a
        mov     a,!wChVolRate+x
        mov     !wSuspChVolRate+x,a
        mov     a,!wChPan+x
        mov     !wSuspChPan+x,a
        mov     a,!wChPanRate+x
        mov     !wSuspChPanRate+x,a
        mov     a,!wChFreqMult+x
        mov     !wSuspChFreqMult+x,a
        mov     a,!wPitchEnvRate+x
        mov     !wSuspPitchEnvRate+x,a
        mov     a,!wPanCycleRate+x
        mov     !wSuspPanCycleRate+x,a
        mov     a,!wPanCycleOffset+x
        mov     !wSuspPanCycleOffset+x,a
        mov     a,!wfc20+x
        mov     !wff17+x,a
        mov     a,!wChFreqOffset+x
        mov     !wSuspChFreqOffset+x,a
        mov     a,!wChFreq+x
        mov     !wSuspChFreq+x,a
        mov     a,!wChADSR+x
        mov     !wSuspChADSR+x,a
        dec     x
        bpl     _1524
        ret

.endproc  ; SuspendSong

; ---------------------------------------------------------------------------

; [ resume song ]

.proc ResumeSong

_1587:  mov     zSuspSongId,#$ff
        mov     a,!wSuspTempoCounter
        mov     zTempoCounter,a
        mov     a,!wSuspSongTickCounter
        mov     zSongTickCounter,a
        mov     a,!wfd8c
        mov     zSongVol,a
        mov     a,!wSuspEchoVolCounter
        mov     zEchoVolCounter,a
        mov     a,!wSuspActiveSongCh
        mov     zActiveSongCh,a
        mov     a,!wSuspChEchoEn
        mov     zChEchoEn,a
        mov     zEchoEn,a
        mov     a,!wSuspChNoiseEn
        mov     zChNoiseEn,a
        mov     zNoiseEn,a
        mov     a,!wSuspChPitchModEn
        mov     zChPitchModEn,a
        mov     zPitchModEn,a
        mov     a,!wSuspIsTie
        mov     zIsTie,a
        mov     a,!wSuspCondJumpEn
        mov     zCondJumpEn,a
        mov     a,!wSuspNoiseFreq
        mov     zNoiseFreq,a
        mov     zFlags,a
        mov     a,!wSuspEchoFeedback
        mov     zEchoFeedback,a
        mov     a,!wSuspEchoFilterId
        call    !SetEchoFeedback_DSP
        mov     a,!wSuspScriptOffset
        mov     y,!wSuspScriptOffset+1
        movw    zScriptOffset,ya
        mov     a,!wSuspTempo
        mov     y,!wSuspTempo+1
        movw    zTempo,ya
        mov     a,!wSuspTempoRate
        mov     y,!wSuspTempoRate+1
        movw    zTempoRate,ya
        mov     a,!wSuspEchoVol
        mov     y,!wSuspEchoVol+1
        movw    zEchoVol,ya
        mov     a,!wSuspEchoVolRate
        mov     y,!wSuspEchoVolRate+1
        movw    zEchoVolRate,ya
        mov     x,#$0e
_15fe:  mov     a,!wSuspTickCounter+x
        mov     zTickCounter+x,a
        mov     a,!wSuspChOctave+x
        mov     zChOctave+x,a
        mov     a,!wSuspRepeatDepth+x
        mov     zRepeatDepth+x,a
        mov     a,!wSuspChSample+x
        mov     zChSample+x,a
        mov     a,!wSuspVibDelayCounter+x
        mov     !wVibDelayCounter+x,a
        mov     a,!wSuspTremDelayCounter+x
        mov     !wTremDelayCounter+x,a
        mov     a,!wSuspPitchEnvOffset+x
        mov     !wPitchEnvOffset+x,a
        mov     a,!wSuspVibAmpl+x
        mov     !wVibAmpl+x,a
        mov     a,!wSuspTremAmpl+x
        mov     !wTremAmpl+x,a
        mov     a,!wSuspPanCycleEn+x
        mov     !wPanCycleEn+x,a
        mov     a,!wSuspVibDelay+x
        mov     !wVibDelay+x,a
        mov     a,!wSuspTremDelay+x
        mov     !wTremDelay+x,a
        mov     a,!wSuspChVolCounter+x
        mov     !wChVolCounter+x,a
        mov     a,!wSuspChPanCounter+x
        mov     !wChPanCounter+x,a
        mov     a,!wSuspVibCycleDur+x
        mov     !wVibCycleDur+x,a
        mov     a,!wSuspTremCycleDur+x
        mov     !wTremCycleDur+x,a
        mov     a,!wSuspPanCycleDur+x
        mov     !wPanCycleDur+x,a
        dec     x
        dec     x
        bpl     _15fe
        mov     x,#$0e
_1666:  mov     a,!wSuspPitchEnvDur+x
        mov     !wPitchEnvDur+x,a
        mov     a,!wSuspVibCycleCounter+x
        mov     !wVibCycleCounter+x,a
        mov     a,!wSuspTremCycleCounter+x
        mov     !wTremCycleCounter+x,a
        mov     a,!wSuspPanCycleCounter+x
        mov     !wPanCycleCounter+x,a
        mov     a,!wSuspChDetune+x
        mov     !wChDetune+x,a
        mov     a,!wSuspChPitch+x
        mov     !wChPitch+x,a
        mov     a,!wSuspChTranspose+x
        mov     !wChTranspose+x,a
        mov     a,!wSuspChVibMult+x
        mov     !wChVibMult+x,a
        mov     a,!wSuspChTremMult+x
        mov     !wChTremMult+x,a
        mov     a,!wSuspChVolMult+x
        mov     !wChVolMult+x,a
        mov     a,!wSuspChVibEnv+x
        mov     !wChVibEnv+x,a
        mov     a,!wSuspChTremEnv+x
        mov     !wChTremEnv+x,a
        dec     x
        dec     x
        bpl     _1666
        mov     x,#$3f
_16b4:  mov     a,!wSuspRepeatPtr+x
        mov     !wRepeatPtr+x,a
        dec     x
        cmp     x,#$20
        bcs     _16b4
_16bf:  mov     a,!wSuspRepeatPtr+x
        mov     !wRepeatPtr+x,a
        mov     a,!wSuspRepeatCount+x
        mov     !wRepeatCount+x,a
        mov     a,!wSuspRepeatCounter+x
        mov     !wRepeatCounter+x,a
        dec     x
        bsfx    _16bf
_16d6:  mov     a,!wSuspRepeatPtr+x
        mov     !wRepeatPtr+x,a
        mov     a,!wSuspRepeatCount+x
        mov     !wRepeatCount+x,a
        mov     a,!wSuspRepeatCounter+x
        mov     !wRepeatCounter+x,a
        mov     a,!wSuspScriptPtr+x
        mov     zScriptPtr+x,a
        mov     a,!wSuspChVol+x
        mov     !wChVol+x,a
        mov     a,!wSuspChVolRate+x
        mov     !wChVolRate+x,a
        mov     a,!wSuspChPan+x
        mov     !wChPan+x,a
        mov     a,!wSuspChPanRate+x
        mov     !wChPanRate+x,a
        mov     a,!wSuspChFreqMult+x
        mov     !wChFreqMult+x,a
        mov     a,!wSuspPitchEnvRate+x
        mov     !wPitchEnvRate+x,a
        mov     a,!wSuspPanCycleRate+x
        mov     !wPanCycleRate+x,a
        mov     a,!wSuspPanCycleOffset+x
        mov     !wPanCycleOffset+x,a
        mov     a,!wff17+x
        mov     !wfc20+x,a
        mov     a,!wSuspChFreqOffset+x
        mov     !wChFreqOffset+x,a
        mov     a,!wSuspChFreq+x
        mov     !wChFreq+x,a
        mov     a,!wSuspChADSR+x
        mov     !wChADSR+x,a
        dec     x
        bpl     _16d6
        ret

.endproc  ; ResumeSong

; ---------------------------------------------------------------------------

; [ update waveform output ]

.proc UpdateWaveOutput

_1739:  mov     a,#zScratch0            ; scratchpad location for waveform values (4 bytes)
        mov     zScratch5,a
        mov     a,#zChWaveVol           ; dsp volume for each channel
        mov     z03,#0
        bbs     zSysFlags_WaveCh,_174a
        mov     zChMask,#dspChOutx
        bra     _1752
_174a:  mov     zChMask,#dspChOutx+$40
        clrc
        adc     a,#8
        set1    z03.7
_1752:  mov     zScratch6,a
        clrc
        adc     a,#8
        mov     z02,a                   ; z02 is the where to stop (do 4 channels)
_1759:  mov     x,zScratch6
        mov     y,zChMask
        mov     hDSPAddr,y
        mov     y,hDSPData              ; y = outx
        push    y
        mov     a,(x)+                  ; multiply by channel volume (l)
        mul     ya
        mov     a,y
        and     a,#$70
        mov     zScratch4,a
        pop     y
        mov     a,(x)+                  ; multiply by channel volume (l)
        mul     ya
        mov     a,y
        mov     zScratch6,x             ; save dsp register pointer
        mov     x,zScratch5
        xcn     a
        and     a,#$07                  ; lo nybble = right (3 bits, unsigned)
        or      a,zScratch4             ; hi nybble = left
        or      a,z03                   ; set msb for channels 4-7
        mov     (x)+,a                  ; copy to scratchpad
        mov     zScratch5,x
        clrc
        adc     zChMask,#$10            ; next channel
        cmp     zScratch6,z02
        bne     _1759
        movw    ya,zScratch0            ; copy values to output ports
        movw    hPort0,ya
        movw    ya,zScratch2
        movw    hPort2,ya
        eor     zSysFlags,#$04          ; toggle waveform channels to output ($be.2)
        ret

.endproc  ; UpdateWaveOutput

; ---------------------------------------------------------------------------

; [ update interrupt envelopes ]

.proc UpdateIntEnv

_1790:  mov     a,zAbsVolCounter
        beq     _17a3
        dec     zAbsVolCounter
        movw    ya,zAbsVolRate
        addw    ya,zAbsVol
        cmp     y,zAbsVol+1
        movw    zAbsVol,ya
        beq     _17a3
        or      zNeedVolUpdate,zActiveSongCh
_17a3:  mov     a,zSfxVolCounter
        beq     _17b6
        dec     zSfxVolCounter
        movw    ya,zSfxVolRate
        addw    ya,zSfxVol
        cmp     y,zSfxVol+1
        movw    zSfxVol,ya
        beq     _17b6
        or      zNeedVolUpdate,zActiveSfxCh
_17b6:  mov     a,zRelVolCounter
        beq     _17c9
        dec     zRelVolCounter
        movw    ya,zRelVolRate
        addw    ya,zRelVol
        cmp     y,zRelVol+1
        movw    zRelVol,ya
        beq     _17c9
        or      zNeedVolUpdate,zActiveSongCh
_17c9:  mov     a,zSfxRelVolCounter
        beq     _17dc
        dec     zSfxRelVolCounter
        movw    ya,zSfxRelVolRate
        addw    ya,zSfxRelVol
        cmp     y,zSfxRelVol+1
        movw    zSfxRelVol,ya
        beq     _17dc
        or      zNeedVolUpdate,zActiveSfxCh
_17dc:  mov     a,zRelTempoCounter
        beq     _17e8
        dec     zRelTempoCounter
        movw    ya,zRelTempoRate
        addw    ya,zRelTempoMult
        movw    zRelTempoMult,ya
_17e8:  mov     a,zSfxTempoCounter
        beq     _17f4
        dec     zSfxTempoCounter
        movw    ya,zSfxTempoRate
        addw    ya,zSfxTempoMult
        movw    zSfxTempoMult,ya
_17f4:  mov     a,zRelPitchCounter
        beq     _1807
        dec     zRelPitchCounter
        movw    ya,zRelPitchRate
        addw    ya,zRelPitchMult
        cmp     y,zRelPitchMult+1
        movw    zRelPitchMult,ya
        beq     _1807
        or      zNeedFreqUpdate,zActiveSongCh
_1807:  mov     a,zSfxPitchCounter
        beq     _181a
        dec     zSfxPitchCounter
        movw    ya,zSfxPitchRate
        addw    ya,zSfxPitchMult
        cmp     y,zSfxPitchMult+1
        movw    zSfxPitchMult,ya
        beq     _181a
        or      zNeedFreqUpdate,zActiveSfxCh
_181a:  ret

.endproc  ; UpdateIntEnv

; ---------------------------------------------------------------------------

.proc TfrPtrs

_181b:  .addr   TfrNone                 ; 0
        .addr   Tfr1                    ; 1
        .addr   Tfr2                    ; 2
        .addr   Tfr3                    ; 3
        .addr   TfrNone                 ; 4
        .addr   TfrNone                 ; 5
        .addr   TfrNone                 ; 6
        .addr   MoveChunk               ; 7

.endproc  ; TfrPtrs

; ---------------------------------------------------------------------------

.proc ChCmdPtrs

_182b:  .addr   SetVol                  ; $d2 v
        .addr   SetVolEnv               ; $d3 v
        .addr   SetPan                  ; $d4 p
        .addr   SetPanEnv               ; $d5 p
        .addr   SetPitchEnv             ; $d6 %p
        .addr   EnableVib               ; $d7 %v
        .addr   DisableVib              ; $d8 %v
        .addr   EnableTrem              ; $d9 %t
        .addr   DisableTrem             ; $da %t
        .addr   EnablePanCycle          ; $db
        .addr   DisablePanCycle         ; $dc
        .addr   SetNoiseFreq            ; $dd %n
        .addr   EnableNoise             ; $de
        .addr   DisableNoise            ; $df
        .addr   EnablePitchMod          ; $e0 %m
        .addr   DisablePitchMod         ; $e1
        .addr   EnableEcho              ; $e2 %e
        .addr   DisableEcho             ; $e3
        .addr   SetOctave               ; $e4 o
        .addr   IncOctave               ; $e5 >, o+
        .addr   DecOctave               ; $e6 <, o-
        .addr   SetTransposeAbs         ; $e7 t
        .addr   SetTransposeRel         ; $e8 t
        .addr   SetDetune               ; $e9 z
        .addr   SetSample               ; $ea i
        .addr   SetADSRAttack           ; $eb
        .addr   SetADSRDecay            ; $ec
        .addr   SetADSRSustain          ; $ed
        .addr   SetADSRRelease          ; $ee
        .addr   SetADSRDefault          ; $ef
        .addr   StartRepeat             ; $f0 [
        .addr   EndRepeat               ; $f1 ]
        .addr   EndScript               ; $f2 x
        .addr   SetTempo                ; $f3 q
        .addr   SetTempoEnv             ; $f4 q
        .addr   SetEchoVol              ; $f5
        .addr   SetEchoVolEnv           ; $f6
        .addr   SetEchoFeedback         ; $f7
        .addr   SetSongVol              ; $f8
        .addr   VoltaRepeat             ; $f9 |
        .addr   UncondJump              ; $fa j
        .addr   CondJump                ; $fb
        .addr   EndScript               ; $fc
        .addr   EndScript               ; $fd
        .addr   EndScript               ; $fe
        .addr   EndScript               ; $ff

.endproc  ; ChCmdPtrs

; ---------------------------------------------------------------------------

.proc ChCmdParams

_1887:  .byte   1                       ; SetVol
        .byte   2                       ; SetVolEnv
        .byte   1                       ; SetPan
        .byte   2                       ; SetPanEnv
        .byte   2                       ; SetPitchEnv
        .byte   3                       ; EnableVib
        .byte   0                       ; DisableVib
        .byte   3                       ; EnableTrem
        .byte   0                       ; DisableTrem
        .byte   2                       ; EnablePanCycle
        .byte   0                       ; DisablePanCycle
        .byte   1                       ; SetNoiseFreq
        .byte   0                       ; EnableNoise
        .byte   0                       ; DisableNoise
        .byte   0                       ; EnablePitchMod
        .byte   0                       ; DisablePitchMod
        .byte   0                       ; EnableEcho
        .byte   0                       ; DisableEcho
        .byte   1                       ; SetOctave
        .byte   0                       ; IncOctave
        .byte   0                       ; DecOctave
        .byte   1                       ; SetTransposeAbs
        .byte   1                       ; SetTransposeRel
        .byte   1                       ; SetDetune
        .byte   1                       ; SetSample
        .byte   1                       ; SetADSRAttack
        .byte   1                       ; SetADSRDecay
        .byte   1                       ; SetADSRSustain
        .byte   1                       ; SetADSRRelease
        .byte   0                       ; SetADSRDefault
        .byte   1                       ; StartRepeat
        .byte   0                       ; EndRepeat
        .byte   0                       ; EndScript
        .byte   1                       ; SetTempo
        .byte   2                       ; SetTempoEnv
        .byte   1                       ; SetEchoVol
        .byte   2                       ; SetEchoVolEnv
        .byte   2                       ; SetEchoFeedback
        .byte   1                       ; SetSongVol
        .byte   3                       ; VoltaRepeat
        .byte   2                       ; UncondJump
        .byte   2                       ; CondJump
        .byte   0                       ; EndScript
        .byte   0                       ; EndScript
        .byte   0                       ; EndScript
        .byte   0                       ; EndScript

.endproc  ; ChCmdParams

; ---------------------------------------------------------------------------

.proc IntPtrs

_18b5:  .addr   SetVolAbs               ; $80
        .addr   SetVolAbs               ; $81
        .addr   SetVolAbs               ; $82
        .addr   SetVolRel               ; $83
        .addr   SetVolRel               ; $84
        .addr   SetVolRel               ; $85
        .addr   SetTempoRel             ; $86
        .addr   SetTempoRel             ; $87
        .addr   SetTempoRel             ; $88
        .addr   SetPitchRel             ; $89
        .addr   SetPitchRel             ; $8a
        .addr   SetPitchRel             ; $8b
        .addr   UnusedInt               ; $8c
        .addr   UnusedInt               ; $8d
        .addr   UnusedInt               ; $8e
        .addr   UnusedInt               ; $8f
        .addr   StopSound               ; $f0
        .addr   StopSound               ; $f1
        .addr   StopSound               ; $f2
        .addr   SetMono                 ; $f3
        .addr   SetMono                 ; $f4
        .addr   SetMute                 ; $f5
        .addr   Unknown_127f            ; $f6
        .addr   Unknown_127f            ; $f7
        .addr   SetFastForward          ; $f8
        .addr   SetFastForward          ; $f9
        .addr   SetFastForward          ; $fa
        .addr   EnableCondLoop          ; $fb
        .addr   ReflectSfx              ; $fc
        .addr   UnusedInt               ; $fd
        .addr   UnusedInt               ; $fe
        .addr   SetOutputMode           ; $ff

.endproc  ; IntPtrs

; ---------------------------------------------------------------------------

.proc PitchConst

_18f5:  .word   $0879
        .word   $08fa
        .word   $0983
        .word   $0a14
        .word   $0aad
        .word   $0b50
        .word   $0bfc
        .word   $0cb2
        .word   $0d74
        .word   $0e41
        .word   $0f1a
        .word   $1000
        .word   $10f3

.endproc  ; PitchConst

; ---------------------------------------------------------------------------

.proc EchoFilterTbl

_190f:  .byte   $7f,$00,$00,$00,$00,$00,$00,$00
        .byte   $0c,$21,$2b,$2b,$13,$fe,$f3,$f9
        .byte   $58,$bf,$db,$f0,$fe,$07,$0c,$0c
        .byte   $34,$33,$00,$d9,$e5,$01,$fc,$eb

.endproc  ; EchoFilterTbl

; ---------------------------------------------------------------------------

.proc NoteDurTbl

_192f:  .byte   192                     ; 0: whole note
        .byte   144                     ; 1: dotted half note
        .byte   96                      ; 2: half note
        .byte   64                      ; 3: half note triplet
        .byte   72                      ; 4: dotted quarter note
        .byte   48                      ; 5: quarter note
        .byte   32                      ; 6: quarter note triplet
        .byte   36                      ; 7: dotted eighth note
        .byte   24                      ; 8: eighth note
        .byte   16                      ; 9: triplet
        .byte   12                      ; a: sixteenth note
        .byte   8                       ; b: sixteenth note triplet
        .byte   6                       ; c: thirty-second note
        .byte   4                       ; d: thirty-second note triplet
        .byte   3                       ; e: sixty-fourth note

.endproc  ; NoteDurTbl

; ---------------------------------------------------------------------------

.proc SysSfxPtrs

_193e:  .word   SysSfx_10
        .word   SysSfx_11
        .word   SysSfx_12
        .word   SysSfx_13
        .word   0
        .word   0
        .word   0
        .word   0
        .word   SysSfx_18
        .word   SysSfx_19
        .word   SysSfx_1a
        .word   0
        .word   0
        .word   0
        .word   0
        .word   SysSfx_1f

.endproc  ; SysSfxPtrs

; ---------------------------------------------------------------------------

.proc SysSfx_10

; v120 i5 p6,16 o6 g4 x

_195e:  .byte   $d2,$78
        .byte   $ea,$05
        .byte   $d6,$06,$0c
        .byte   $e4,$06
        .byte   $74
        .byte   $f2

.endproc  ; SysSfx_10

; ---------------------------------------------------------------------------

.proc SysSfx_11

; v120 i5 p6,16 o6 {b-16} x

_1969:  .byte   $d2,$78
        .byte   $ea,$05
        .byte   $d6,$06,$0c
        .byte   $e4,$06
        .byte   $a1
        .byte   $f2

.endproc  ; SysSfx_11

; ---------------------------------------------------------------------------

.proc SysSfx_12

; v255 o4 [i6 e-64 i7 e-64]3 x

_1974:  .byte   $d2,$ff
        .byte   $e4,$04
        .byte   $f0,$03
        .byte   $ea,$06
        .byte   $3b
        .byte   $ea,$07
        .byte   $3b
        .byte   $f1
        .byte   $f2

.endproc  ; SysSfx_12

; ---------------------------------------------------------------------------

.proc SysSfx_13

; v128 i3 %e+ ...

_1982:  .byte   $d2,$80
        .byte   $ea,$03
        .byte   $e2
        .byte   $eb,$0e
        .byte   $ee,$16
        .byte   $e4,$07
        .byte   $2a
        .byte   $3a
        .byte   $58
        .byte   $75
        .byte   $84
        .byte   $9a
        .byte   $f2

.endproc  ; SysSfx_13

; ---------------------------------------------------------------------------

.proc SysSfx_18

_1994:  .byte   $d2,$e6
        .byte   $d7,$00,$0c,$7f
        .byte   $ea,$07
        .byte   $e4,$05
        .byte   $92
        .byte   $e5
        .byte   $d2,$b4
        .byte   $47
        .byte   $d2,$82
        .byte   $47
        .byte   $d2,$64
        .byte   $47
        .byte   $d2,$32
        .byte   $47
        .byte   $f2

.endproc  ; SysSfx_18

; ---------------------------------------------------------------------------

.proc SysSfx_19

_19ad:  .byte   $d2,$e6
        .byte   $d7,$00,$0c,$7f
        .byte   $ea,$07
        .byte   $e4,$05
        .byte   $47
        .byte   $d2,$b4
        .byte   $b0
        .byte   $d2,$82
        .byte   $b0
        .byte   $d2,$64
        .byte   $b0
        .byte   $d2,$32
        .byte   $b0
        .byte   $f2

.endproc  ; SysSfx_19

; ---------------------------------------------------------------------------

.proc SysSfx_1a

_19c5:  .byte   $d2,$ff
        .byte   $ea,$00
        .byte   $de
        .byte   $dd,$10
        .byte   $eb,$0e
        .byte   $ed,$05
        .byte   $ee,$0e
        .byte   $00
        .byte   $f2

.endproc  ; SysSfx_1a

; ---------------------------------------------------------------------------

.proc SysSfx_1f

_19d4:  .byte   $d2,$80
        .byte   $ea,$04
        .byte   $e2
        .byte   $e4,$1d
        .byte   $ee,$12
        .byte   $0e
        .byte   $4b
        .byte   $f2

.endproc  ; SysSfx_1f

; ---------------------------------------------------------------------------

.proc DSPUpdateRegTbl

_19e0:  .byte   dspKeyOn
        .byte   dspKeyOff
        .byte   dspPitchMod
        .byte   dspNoiseEn
        .byte   dspEchoEn
        .byte   dspEchoVolL
        .byte   dspEchoVolR
        .byte   dspFlags

.endproc  ; DSPUpdateRegTbl

; ---------------------------------------------------------------------------

.proc DSPUpdateRAMTbl

_19e8:  .byte   zKeyOn
        .byte   zKeyOff
        .byte   zPitchModEn
        .byte   zNoiseEn
        .byte   zEchoEn
        .byte   zEchoVol+1
        .byte   zEchoVol+1
        .byte   zFlags

.endproc  ; DSPUpdateRAMTbl

; ---------------------------------------------------------------------------

