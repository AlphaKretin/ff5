// Ported from src/sound/ff5-spc.asm
//
// Porting status: PARTIAL
//   Implemented: notes, ties, rests, SetVol, SetPan, SetOctave, SetSample,
//                SetTempo, SetTransposeAbs/Rel, SetDetune, IncOctave, DecOctave,
//                StartRepeat, EndRepeat, EndScript, UncondJump, SetSongVol,
//                SetPitchEnv (stub), vibrato/tremolo/echo/noise/ADSR (stubs)
//   Not yet:     ADSR envelope, vibrato, tremolo, echo, pan-cycle,
//                VoltaRepeat, CondJump, SFX channels

#include "engine/sound/Sequencer.h"
#include <algorithm>
#include <cstdio>
#include <cstring>

// ---------------------------------------------------------------------------
// Static tables — from ff5-spc.asm
// ---------------------------------------------------------------------------

// PitchConst[0..11]: base DSP pitch values for C through B.
// At octave 4 with freqMultLo<0x80, freq = pitchConst + (pitchConst * mult / 256).
const uint16_t Sequencer::k_pitchConst[12] = {
    0x0879, 0x08FA, 0x0983, 0x0A14, 0x0AAD, 0x0B50,
    0x0BFC, 0x0CB2, 0x0D74, 0x0E41, 0x0F1A, 0x1000
};

// NoteDurTbl[0..14]: note durations in SPC ticks.
// Index = byte % 15; values from ff5-spc.asm NoteDurTbl.
const int Sequencer::k_noteDurTbl[15] = {
    192, 144, 96, 64, 72, 48, 32, 36, 24, 16, 12, 8, 6, 4, 3
};

// ChCmdParams[0..45]: parameter bytes consumed by commands $D2..$FF.
// Index = command - $D2. From ff5-spc.asm ChCmdParams.
const uint8_t Sequencer::k_cmdParams[46] = {
    1, // $D2 SetVol
    2, // $D3 SetVolEnv
    1, // $D4 SetPan
    2, // $D5 SetPanEnv
    2, // $D6 SetPitchEnv
    3, // $D7 EnableVib
    0, // $D8 DisableVib
    3, // $D9 EnableTrem
    0, // $DA DisableTrem
    2, // $DB EnablePanCycle
    0, // $DC DisablePanCycle
    1, // $DD SetNoiseFreq
    0, // $DE EnableNoise
    0, // $DF DisableNoise
    0, // $E0 EnablePitchMod
    0, // $E1 DisablePitchMod
    0, // $E2 EnableEcho
    0, // $E3 DisableEcho
    1, // $E4 SetOctave
    0, // $E5 IncOctave
    0, // $E6 DecOctave
    1, // $E7 SetTransposeAbs
    1, // $E8 SetTransposeRel
    1, // $E9 SetDetune
    1, // $EA SetSample
    1, // $EB SetADSRAttack
    1, // $EC SetADSRDecay
    1, // $ED SetADSRSustain
    1, // $EE SetADSRRelease
    0, // $EF SetADSRDefault
    1, // $F0 StartRepeat
    0, // $F1 EndRepeat
    0, // $F2 EndScript
    1, // $F3 SetTempo
    2, // $F4 SetTempoEnv
    1, // $F5 SetEchoVol
    2, // $F6 SetEchoVolEnv
    2, // $F7 SetEchoFeedback
    1, // $F8 SetSongVol
    3, // $F9 VoltaRepeat
    2, // $FA UncondJump
    2, // $FB CondJump
    0, // $FC EndScript
    0, // $FD EndScript
    0, // $FE EndScript
    0, // $FF EndScript
};


// ---------------------------------------------------------------------------
// Constructor
// ---------------------------------------------------------------------------

Sequencer::Sequencer(SampleBank& bank) : m_bank(bank) {
    std::fill(m_sampleSlotMap, m_sampleSlotMap + 64, 0xFF);
}

// ---------------------------------------------------------------------------
// playSong — mirrors ff5-spc.asm PlaySong / InitCh
// ---------------------------------------------------------------------------

void Sequencer::playSong(const uint8_t* songData, int songLen, int songIdx) {
    if (!songData || songLen < 22) {
        std::fprintf(stderr, "[Sequencer] song data too short (%d bytes)\n", songLen);
        return;
    }

    // Build sample slot map: SPC slot → instrument index for this song.
    // BGM samples occupy slots 32–47 in the order listed in the SongSamples
    // table (generated from the ROM by tools/encode_song_samples.py).
    std::fill(m_sampleSlotMap, m_sampleSlotMap + 64, 0xFF);
    for (int k = 0; k < 16; k++) {
        uint8_t inst = m_bank.songInstrument(songIdx, k);
        if (inst == 0xFF) break;
        m_sampleSlotMap[32 + k] = inst;
    }

    // Keep a copy of the song data so pointers remain valid
    m_songBuf.assign(songData, songData + songLen);
    const uint8_t* d = m_songBuf.data();

    // File layout: [0..1]=count, [2..3]=base_addr, [4..19]=ch_ptrs, [20..21]=sentinel, [22+]=bytecodes
    uint16_t baseAddr = (uint16_t)(d[2] | (d[3] << 8));
    uint16_t sentinel = (uint16_t)(d[20] | (d[21] << 8));

    const uint8_t* scriptBase = d + 22;  // start of bytecode data

    // Reset global state
    m_tempo    = 1;      // will be set by $F3 SetTempo early in script
    m_songVol  = 255;
    m_tickAccum   = 255; // zSongTickCounter=$FF → fires on first main-loop pass
    m_sampleCount = 0;

    // Initialise all 8 channels
    for (int i = 0; i < NUM_CHANNELS; i++) {
        ChannelState& ch = m_ch[i];
        ch = ChannelState{};  // zero out

        // Channel pointer is at file offset 4 + i*2
        uint16_t chPtr = (uint16_t)(d[4 + i*2] | (d[4 + i*2 + 1] << 8));

        if (chPtr == sentinel) {
            ch.active = false;
            continue;
        }

        // Compute byte offset into bytecodes
        int byteOfs = (int16_t)(chPtr - baseAddr);  // signed offset from base
        if (byteOfs < 0 || 22 + byteOfs >= songLen) {
            std::fprintf(stderr, "[Sequencer] ch%d: bytecode offset %d out of range\n", i, byteOfs);
            ch.active = false;
            continue;
        }

        ch.active      = true;
        ch.scriptBase  = scriptBase;
        ch.scriptPtr   = scriptBase + byteOfs;
        ch.baseAddr    = baseAddr;
        ch.tickCounter = 1;  // InitCh sets tickCounter=1 → fires on first tick
        ch.octave      = 0;
        ch.transpose   = 0;
        ch.detune      = 0;
        ch.repeatSP    = -1;

        // Load default FreqMult from first instrument (SetSample will override early)
        ch.freqMultLo  = m_bank.meta(0).freqMultLo;
        ch.freqMultHi  = m_bank.meta(0).freqMultHi;
    }

    m_active = true;
}

void Sequencer::stopSong() {
    m_active = false;
    for (auto& ch : m_ch) ch = ChannelState{};
}

// ---------------------------------------------------------------------------
// generateAudio — mix active channels into stereo float PCM
// ---------------------------------------------------------------------------

void Sequencer::generateAudio(float* out, int nFrames) {
    if (!m_active) {
        std::memset(out, 0, nFrames * 2 * sizeof(float));
        return;
    }

    for (int f = 0; f < nFrames; f++) {
        // ── Tick sequencer at 144-sample boundaries ───────────────────────
        m_sampleCount++;
        if (m_sampleCount >= 144) {
            m_sampleCount -= 144;
            m_tickAccum += m_tempo;
            while (m_tickAccum >= 256) {
                m_tickAccum -= 256;
                tickAll();
            }
        }

        // ── Mix active voices ─────────────────────────────────────────────
        float left = 0.0f, right = 0.0f;

        for (int i = 0; i < NUM_CHANNELS; i++) {
            ChannelState& ch = m_ch[i];
            if (!ch.active || !ch.playing) continue;

            const DecodedSample& smp = m_bank.sample(ch.sampleId);
            if (smp.pcm.empty()) continue;

            // Advance phase
            ch.phaseAccum += ch.dspFreq;
            int sampleIdx = (int)(ch.phaseAccum >> 12);

            // Handle looping
            if (smp.loops) {
                int loopLen = (int)smp.pcm.size() - smp.loopStart;
                if (loopLen <= 0) loopLen = 1;
                while (sampleIdx >= (int)smp.pcm.size()) {
                    sampleIdx  -= loopLen;
                    ch.phaseAccum -= (uint32_t)loopLen << 12;
                }
            } else {
                if (sampleIdx >= (int)smp.pcm.size()) {
                    ch.playing = false;
                    continue;
                }
            }

            // Linear interpolation between adjacent samples
            float s0 = smp.pcm[sampleIdx] * (1.0f / 32768.0f);
            float s1 = s0;
            if (sampleIdx + 1 < (int)smp.pcm.size()) {
                s1 = smp.pcm[sampleIdx + 1] * (1.0f / 32768.0f);
            }
            float frac = (float)(ch.phaseAccum & 0xFFF) * (1.0f / 4096.0f);
            float s = s0 + frac * (s1 - s0);

            // Apply volume (0..255) and master song volume
            float vol = (ch.volume / 255.0f) * (m_songVol / 255.0f);
            s *= vol;

            // Apply pan: 0x01=full-left, 0x40=center, 0x7F=full-right (range 1..127 = span 126)
            float panR = std::max(0.0f, std::min(1.0f, (ch.pan - 1) / 126.0f));
            float panL = 1.0f - panR;
            left  += s * panL;
            right += s * panR;
        }

        // Clamp to [-1, 1]
        out[f * 2    ] = std::max(-1.0f, std::min(1.0f, left));
        out[f * 2 + 1] = std::max(-1.0f, std::min(1.0f, right));
    }
}

// ---------------------------------------------------------------------------
// tickAll — called each song tick; decrements channel counters and runs scripts
// ---------------------------------------------------------------------------

void Sequencer::tickAll() {
    bool anyActive = false;

    for (int i = 0; i < NUM_CHANNELS; i++) {
        ChannelState& ch = m_ch[i];
        if (!ch.active) continue;

        anyActive = true;

        ch.tickCounter--;
        if (ch.tickCounter <= 0)
            execScript(ch);
    }

    if (!anyActive)
        m_active = false;
}

// ---------------------------------------------------------------------------
// execScript — reads bytecodes until a note/tie/rest, then returns
// Mirrors ff5-spc.asm ExecChScript
// ---------------------------------------------------------------------------

void Sequencer::execScript(ChannelState& ch) {
    for (int safety = 0; safety < 1024; safety++) {
        uint8_t b = readByte(ch);

        if (b >= 0xD2) {
            // Command byte — consume its first parameter (if any) then dispatch
            int cmdIdx = b - 0xD2;
            if (cmdIdx >= 46) {
                // $FC..$FF = EndScript
                ch.active  = false;
                ch.playing = false;
                return;
            }
            uint8_t p1 = (k_cmdParams[cmdIdx] >= 1) ? readByte(ch) : 0;
            execCmd(ch, b, p1);

            if (!ch.active) return;
            continue;
        }

        // Note-class byte (0x00..0xD1)
        int durIdx = b % 15;
        ch.tickCounter = k_noteDurTbl[durIdx];

        if (b >= 0xC3) {
            // Rest ($C3..$D1)
            ch.playing = false;
            ch.isTie   = false;
            return;
        }

        if (b >= 0xB4) {
            // Tie ($B4..$C2): continue current note without key-on
            return;
        }

        // Note byte ($00..$B3)
        int semitone = b / 15;   // 0..11
        int pitch = ch.octave * 12 + semitone + (int)ch.transpose - 10;
        pitch = std::max(0, std::min(127, pitch));
        ch.dspFreq = calcFreq((uint8_t)pitch,
                              ch.freqMultLo, ch.freqMultHi, ch.detune);

        if (!ch.isTie) {
            // New note: key-on → reset phase to beginning of sample
            ch.phaseAccum = 0;
        }
        ch.playing = true;

        // Look ahead to see if the following note-class byte is a tie.
        // This suppresses phase-reset for the tied continuation note.
        // (Simplified: only skips commands, does not follow jumps/loops)
        ch.isTie = false;
        {
            const uint8_t* peek = ch.scriptPtr;
            for (int n = 0; n < 256; n++) {
                uint8_t nx = *peek++;
                if (nx < 0xD2) {
                    ch.isTie = (nx >= 0xB4 && nx < 0xC3);
                    break;
                }
                int ci = nx - 0xD2;
                if (ci < 46) peek += k_cmdParams[ci];
            }
        }
        return;
    }

    // Safety limit hit — deactivate to avoid infinite loop
    ch.active = false;
}

// ---------------------------------------------------------------------------
// readByte — advance script pointer and return next byte
// ---------------------------------------------------------------------------

uint8_t Sequencer::readByte(ChannelState& ch) {
    return *ch.scriptPtr++;
}

// ---------------------------------------------------------------------------
// jumpTo — set script pointer from an absolute SPC address
// Mirrors the addw ya, zScriptOffset calculation in ff5-spc.asm
// ---------------------------------------------------------------------------

void Sequencer::jumpTo(ChannelState& ch, uint16_t spcAddr) {
    int ofs = (int)(int16_t)(spcAddr - ch.baseAddr);
    ch.scriptPtr = ch.scriptBase + ofs;
}

// ---------------------------------------------------------------------------
// execCmd — execute a single script command (p1 already consumed)
// Mirrors ff5-spc.asm ExecChCmd dispatch table
// ---------------------------------------------------------------------------

void Sequencer::execCmd(ChannelState& ch, uint8_t cmd, uint8_t p1) {
    switch (cmd) {

    // ── $D2 SetVol: set channel volume ──────────────────────────────────────
    case 0xD2:
        ch.volume = p1;  // 0..255
        break;

    // ── $D3 SetVolEnv: set volume with envelope (skip 2nd param) ───────────
    case 0xD3:
        readByte(ch);    // consume p2 (final volume)
        ch.volume = p1;  // p1 = duration; use as instant set
        break;

    // ── $D4 SetPan: set stereo pan ──────────────────────────────────────────
    case 0xD4:
        ch.pan = p1;
        break;

    // ── $D5 SetPanEnv: pan envelope (consume p2) ───────────────────────────
    case 0xD5:
        readByte(ch);           // p2 = target pan
        ch.pan = p1;
        break;

    // ── $D6 SetPitchEnv: pitch envelope (p1=dur, p2=offset) ────────────────
    case 0xD6:
        readByte(ch);           // p2 = pitch offset (ignored for now)
        break;

    // ── $D7 EnableVib: p1=delay, p2=rate, p3=depth (consume extras) ────────
    case 0xD7:
        readByte(ch);           // p2
        readByte(ch);           // p3
        break;

    // ── $D8 DisableVib ──────────────────────────────────────────────────────
    case 0xD8:
        break;

    // ── $D9 EnableTrem: p1=delay, p2=rate, p3=depth ─────────────────────────
    case 0xD9:
        readByte(ch);           // p2
        readByte(ch);           // p3
        break;

    // ── $DA DisableTrem ─────────────────────────────────────────────────────
    case 0xDA:
        break;

    // ── $DB EnablePanCycle: p1=rate, p2=depth ───────────────────────────────
    case 0xDB:
        readByte(ch);           // p2
        break;

    // ── $DC DisablePanCycle ─────────────────────────────────────────────────
    case 0xDC:
        break;

    // ── $DD SetNoiseFreq ────────────────────────────────────────────────────
    case 0xDD:
        break;

    // ── $DE EnableNoise / $DF DisableNoise ──────────────────────────────────
    case 0xDE: case 0xDF:
        break;

    // ── $E0 EnablePitchMod / $E1 DisablePitchMod ────────────────────────────
    case 0xE0: case 0xE1:
        break;

    // ── $E2 EnableEcho / $E3 DisableEcho ────────────────────────────────────
    case 0xE2: case 0xE3:
        break;

    // ── $E4 SetOctave ───────────────────────────────────────────────────────
    case 0xE4:
        ch.octave = (int)(p1 & 0x0F);
        break;

    // ── $E5 IncOctave ───────────────────────────────────────────────────────
    case 0xE5:
        ch.octave = std::min(ch.octave + 1, 7);
        break;

    // ── $E6 DecOctave ───────────────────────────────────────────────────────
    case 0xE6:
        ch.octave = std::max(ch.octave - 1, 0);
        break;

    // ── $E7 SetTransposeAbs ─────────────────────────────────────────────────
    case 0xE7:
        ch.transpose = (int8_t)p1;
        break;

    // ── $E8 SetTransposeRel ─────────────────────────────────────────────────
    case 0xE8:
        ch.transpose += (int8_t)p1;
        break;

    // ── $E9 SetDetune ───────────────────────────────────────────────────────
    case 0xE9:
        ch.detune = (int8_t)p1;
        break;

    // ── $EA SetSample ───────────────────────────────────────────────────────
    // p1 is a SPC RAM slot index (not a direct instrument index).
    // Slots 32–47 are BGM samples, mapped via m_sampleSlotMap from SongSamples.
    case 0xEA: {
        uint8_t id = (p1 < 64) ? m_sampleSlotMap[p1] : 0xFF;
        if (id == 0xFF) {
            std::fprintf(stderr, "[Sequencer] SetSample: unmapped slot 0x%02x\n", p1);
            break;
        }
        ch.sampleId   = id;
        ch.freqMultLo = m_bank.meta(id).freqMultLo;
        ch.freqMultHi = m_bank.meta(id).freqMultHi;
        break;
    }

    // ── $EB..$EF ADSR controls (stubbed; ADSR not yet emulated) ─────────────
    case 0xEB: case 0xEC: case 0xED: case 0xEE: case 0xEF:
        break;

    // ── $F0 StartRepeat: p1 = repeat count (0=infinite, else play count+1) ──
    case 0xF0: {
        int sp = ch.repeatSP + 1;
        if (sp > 3) sp = 3;  // clamp to max depth
        ch.repeatSP = sp;
        RepeatEntry& e = ch.repeatStack[sp];
        e.ptr   = ch.scriptPtr;    // loop body starts here (after StartRepeat + param)
        e.count = (p1 == 0) ? 0 : (p1 + 1);  // 0=infinite; else total-plays count
        break;
    }

    // ── $F1 EndRepeat ───────────────────────────────────────────────────────
    case 0xF1: {
        if (ch.repeatSP < 0) break;  // no active repeat
        RepeatEntry& e = ch.repeatStack[ch.repeatSP];
        if (e.count == 0) {
            // Infinite loop: always jump back
            ch.scriptPtr = e.ptr;
        } else {
            e.count--;
            if (e.count == 0) {
                ch.repeatSP--;   // pop stack (loop exhausted)
            } else {
                ch.scriptPtr = e.ptr;  // jump back
            }
        }
        break;
    }

    // ── $F2 / $FC..$FF EndScript ────────────────────────────────────────────
    case 0xF2: case 0xFC: case 0xFD: case 0xFE: case 0xFF:
        ch.active  = false;
        ch.playing = false;
        break;

    // ── $F3 SetTempo ────────────────────────────────────────────────────────
    // p1 = new tempo byte (zTempo+1). Affects how many ticks fire per second.
    case 0xF3:
        m_tempo = (p1 == 0) ? 1 : p1;  // guard against 0 (would never tick)
        break;

    // ── $F4 SetTempoEnv (p1=duration, p2=target) ────────────────────────────
    case 0xF4:
        readByte(ch);           // p2 = target tempo (ignored for now)
        m_tempo = (p1 == 0) ? 1 : p1;
        break;

    // ── $F5 SetEchoVol ──────────────────────────────────────────────────────
    case 0xF5:
        break;

    // ── $F6 SetEchoVolEnv (p1=duration, p2=target) ──────────────────────────
    case 0xF6:
        readByte(ch);           // p2
        break;

    // ── $F7 SetEchoFeedback (p1=feedback, p2=filter_id) ─────────────────────
    case 0xF7:
        readByte(ch);           // p2
        break;

    // ── $F8 SetSongVol ──────────────────────────────────────────────────────
    case 0xF8:
        m_songVol = p1;  // 0..255
        break;

    // ── $F9 VoltaRepeat (p1=ending_num, p2=dest_lo, p3=dest_hi) ────────────
    // Minimal implementation: skip for now (consume remaining params)
    case 0xF9:
        readByte(ch);           // p2 dest_lo (already consumed p1=ending_num)
        readByte(ch);           // p3 dest_hi
        break;

    // ── $FA UncondJump (p1=dest_lo, p2=dest_hi) ─────────────────────────────
    case 0xFA: {
        uint8_t hi = readByte(ch);  // p2
        uint16_t spcAddr = (uint16_t)(p1 | (hi << 8));
        jumpTo(ch, spcAddr);
        break;
    }

    // ── $FB CondJump (p1=dest_lo, p2=dest_hi) ───────────────────────────────
    // Conditional jump based on zCondJumpEn (not yet tracked); skip.
    case 0xFB:
        readByte(ch);           // p2
        break;

    default:
        break;
    }
}

// ---------------------------------------------------------------------------
// calcFreq — mirrors ff5-spc.asm CalcFreq
//
// Converts a semitone pitch index + instrument frequency multiplier + detune
// into a 16-bit DSP pitch register value.
// DSP pitch register: 0x1000 = play exactly one BRR sample per output sample.
// ---------------------------------------------------------------------------

uint16_t Sequencer::calcFreq(uint8_t pitch, uint8_t freqMultLo,
                              uint8_t freqMultHi, int8_t detune) const {
    int oct  = pitch / 12;
    int semi = pitch % 12;

    uint16_t pc   = k_pitchConst[semi];
    uint8_t  pcHi = (uint8_t)(pc >> 8);
    uint8_t  pcLo = (uint8_t)(pc & 0xFF);

    // mult = freqMultLo + detune (8-bit wrapping add)
    uint8_t mult = (uint8_t)((int)freqMultLo + (int)detune);

    // positive: bit 7 of mult is clear → we add base pitchConst at end
    bool positive = (mult < 0x80);

    // freq = (pcHi * mult) + high_byte(pcLo * mult)
    uint32_t freq = (uint32_t)pcHi * mult;
    freq += ((uint32_t)pcLo * mult) >> 8;

    // if freqMultHi != 0: freq += high_byte(freq_hi * freqMultHi)
    if (freqMultHi != 0) {
        uint8_t freqHi = (uint8_t)(freq >> 8);
        freq += ((uint32_t)freqHi * freqMultHi) >> 8;
    }

    // if positive (mult < 0x80): add base pitch constant
    if (positive)
        freq += pc;

    // Apply octave shift relative to reference octave 4
    if (oct > 4)
        freq <<= (oct - 4);
    else if (oct < 4)
        freq >>= (4 - oct);

    return (uint16_t)(freq & 0xFFFF);
}
