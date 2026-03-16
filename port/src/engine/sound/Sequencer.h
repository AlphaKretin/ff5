#pragma once

#include "engine/sound/SampleBank.h"
#include <array>
#include <cstdint>
#include <vector>

// ---------------------------------------------------------------------------
// Sequencer
//
// Ported from src/sound/ff5-spc.asm.
// Interprets FF5 song-script bytecodes, manages 8 melodic channels, and
// mixes decoded BRR samples into stereo PCM for IAudioOutput.
//
// Song data format (song_script.dat at a song's byte offset):
//   [0..1]   count     - number of bytes that follow (LE uint16)
//   [2..3]   base_addr - original SPC RAM address of first bytecode (LE uint16)
//   [4..19]  ch_ptrs   - 8 × absolute SPC channel-script addresses (LE uint16)
//   [20..21] sentinel  - inactive-channel marker value (LE uint16)
//   [22..]   bytecodes - channel script data
// ---------------------------------------------------------------------------
class Sequencer {
public:
    explicit Sequencer(SampleBank& bank);

    // Load and start playing a song.
    // songData/songLen: raw bytes from song_script.dat at the song's offset.
    // songIdx: 0-based song index (used to build the SPC sample-slot → instrument map).
    void playSong(const uint8_t* songData, int songLen, int songIdx);

    void stopSong();

    // Generate nFrames stereo float samples into out[0..2*nFrames-1].
    // Interleaved L/R, range approximately [-1, 1].
    void generateAudio(float* out, int nFrames);

    bool isPlaying() const { return m_active; }

private:
    static constexpr int NUM_CHANNELS = 8;

    // SPC-700 envelope phase
    enum class EnvPhase : uint8_t { OFF, ATTACK, DECAY, SUSTAIN, RELEASE };

    // Per-channel repeat stack (mirrors SPC wRepeatPtr / wRepeatCount)
    struct RepeatEntry {
        const uint8_t* ptr       = nullptr;  // script ptr at start of loop body
        int            count     = 0;        // 0 = infinite; >0 = remaining plays
        int            passCount = 0;        // volta repeat pass counter
    };

    struct ChannelState {
        bool            active     = false;
        bool            playing    = false;   // voice producing audio
        bool            isTie      = false;   // current note is a tie continuation

        const uint8_t*  scriptBase = nullptr; // first bytecode byte
        const uint8_t*  scriptPtr  = nullptr; // current read position
        uint16_t        baseAddr   = 0;       // original SPC base address (for jumps)

        int     tickCounter = 0;

        // Musical state
        int    octave     = 0;
        int8_t transpose  = 0;
        int8_t detune     = 0;
        uint8_t sampleId  = 0;
        uint8_t volume    = 255;  // 0..255
        uint8_t pan       = 0x40; // 0x01=left, 0x40=center, 0x7F=right
        uint8_t freqMultLo = 0;
        uint8_t freqMultHi = 0;

        // Voice playback
        uint32_t phaseAccum = 0;  // 20.12 fixed-point sample position
        uint16_t dspFreq    = 0;  // pitch (phase advance per output sample × 4096)

        // ADSR envelope (mirrors SPC-700 DSP ADSR1/ADSR2 registers)
        uint8_t  adsrAttack      = 15;   // AR  0..15  (15 = instant)
        uint8_t  adsrDecay       = 7;    // DR  0..7   (index = DR*2+16 into rate table)
        uint8_t  adsrSustainLvl  = 7;    // SL  0..7   threshold = (SL+1)*256
        uint8_t  adsrSustainRate = 0;    // SR  0..31  (0 = hold; direct index into rate table)
        int      envLevel        = 0;    // 0..2047 (SPC-700 $000..$7FF)
        int      envStepCounter  = 0;    // output samples until next envelope step
        EnvPhase envPhase        = EnvPhase::OFF;

        // Vibrato (mirrors SPC wVibAmpl/wVibDelay/wVibCycleDur)
        uint8_t vibAmpl          = 0;    // 0=off; ≥$C0 = balanced (±); <$C0 = one-sided (+)
        uint8_t vibDelay         = 0;    // ticks before vibrato starts
        uint8_t vibDelayCounter  = 0;    // countdown (decremented per tick)
        uint8_t vibCycleDur      = 1;    // main-loop iterations per triangle step
        uint8_t vibCycleCounter  = 1;    // main-loop countdown until next step
        int     vibPhase         = 0;    // 0..3 (quarter-cycle of triangle wave)
        int16_t vibFreqOffset    = 0;    // current DSP pitch offset applied in mixer

        // Tremolo (mirrors SPC wTremAmpl/wTremDelay/wTremCycleDur)
        uint8_t tremAmpl         = 0;    // 0=off; ≥$C0 = balanced; <$C0 = one-sided
        uint8_t tremDelay        = 0;
        uint8_t tremDelayCounter = 0;
        uint8_t tremCycleDur     = 1;
        uint8_t tremCycleCounter = 1;
        int     tremPhase        = 0;
        float   tremVolMult      = 1.0f; // 0.0..1.0 multiplier applied to voice volume

        // Repeat stack (up to 4 levels, mirroring SPC repeat depth)
        RepeatEntry repeatStack[4];
        int         repeatSP = -1;  // top-of-stack index (-1 = empty)
    };

    // ── Script execution ────────────────────────────────────────────────────
    void    tickAll();
    void    tickChannel(int ch);
    void    execScript(ChannelState& ch);
    void    execCmd(ChannelState& ch, uint8_t cmdByte, uint8_t p1);
    uint8_t readByte(ChannelState& ch);
    void    jumpTo(ChannelState& ch, uint16_t spcAddr);

    // ── Envelope / effects ───────────────────────────────────────────────────
    // Called every 144 output samples (mirrors SPC main-loop UpdateChVolFreq).
    void    tickEffects();
    // Advance ADSR envelope by one output sample.
    void    stepEnvelope(ChannelState& ch);
    // Key-on: reset envelope to attack phase (called when a new note starts).
    void    keyOn(ChannelState& ch);
    // Key-off: switch envelope to release phase (called on rest/new-note-off).
    void    keyOff(ChannelState& ch);

    // ── Pitch calculation (mirrors ff5-spc.asm CalcFreq) ────────────────────
    uint16_t calcFreq(uint8_t pitch, uint8_t freqMultLo,
                      uint8_t freqMultHi, int8_t detune) const;

    // ── Static tables ────────────────────────────────────────────────────────
    // PitchConst[12]: base DSP frequencies for C..B (from ff5-spc.asm PitchConst)
    static const uint16_t k_pitchConst[12];
    // NoteDurTbl[15]: note durations in ticks (from ff5-spc.asm NoteDurTbl)
    static const int k_noteDurTbl[15];
    // ChCmdParams[46]: parameter counts for commands $D2..$FF
    static const uint8_t k_cmdParams[46];
    // GainRate[32]: output samples between SPC-700 envelope steps.
    // Decay uses index DR*2+16; sustain/release use SR directly; 0 = infinite (no step).
    static const int k_gainRate[32];

    SampleBank& m_bank;

    bool    m_active   = false;

    // SPC sample-slot → instrument index map (0xFF = unmapped).
    // Slots 0–31 are SFX (not yet implemented); slots 32–47 are BGM samples,
    // populated in SongSamples order for the current song.
    uint8_t m_sampleSlotMap[64];
    uint8_t m_tempo    = 1;    // zTempo+1: added to tick-accum every 144 samples
    uint8_t m_songVol  = 255;  // global song volume (0..255)

    // Tick accumulator: += m_tempo every 144 samples; tick fires on overflow
    int m_tickAccum   = 255;   // 255 = fire on first main-loop pass (zSongTickCounter=$FF)
    int m_sampleCount = 0;     // samples since last 144-sample main-loop boundary

    // Song data owned by sequencer (kept alive while song is playing)
    std::vector<uint8_t> m_songBuf;

    std::array<ChannelState, NUM_CHANNELS> m_ch;
};
