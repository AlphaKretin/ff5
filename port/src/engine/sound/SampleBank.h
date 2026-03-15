#pragma once

#include "engine/sound/BRRDecoder.h"
#include "engine/assets/AssetManager.h"
#include <array>
#include <cstdint>

static constexpr int NUM_INSTRUMENTS = 35;

// Per-instrument hardware metadata from song-data.asm tables.
struct SampleMeta {
    uint8_t freqMultLo;  // SampleFreqMult lo byte (multiplier / detune base)
    uint8_t freqMultHi;  // SampleFreqMult hi byte (fine tuning)
    uint8_t adsr1;       // SampleADSR byte 0: $80 | attack[3:0] | (decay[2:0]<<4)
    uint8_t adsr2;       // SampleADSR byte 1: release[4:0] | (sustain[2:0]<<5)
};

// ---------------------------------------------------------------------------
// SampleBank
//
// Loads the 35 FF5 BRR instruments from the asset files and decodes them
// to int16 PCM once at startup, ready for the Sequencer to mix.
// ---------------------------------------------------------------------------
class SampleBank {
public:
    SampleBank() = default;

    // Loads and decodes all instruments. Returns false on failure.
    bool load(const AssetManager& assets);

    const DecodedSample& sample(int id) const {
        return m_samples[id >= 0 && id < NUM_INSTRUMENTS ? id : 0];
    }

    const SampleMeta& meta(int id) const {
        return k_meta[id >= 0 && id < NUM_INSTRUMENTS ? id : 0];
    }

private:
    std::array<DecodedSample, NUM_INSTRUMENTS> m_samples;

    // Instrument metadata from song-data.asm (SampleFreqMult + SampleADSR tables)
    static const SampleMeta k_meta[NUM_INSTRUMENTS];
};
