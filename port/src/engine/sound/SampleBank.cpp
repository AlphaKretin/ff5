// Ported from src/sound/song-data.asm (SampleFreqMult, SampleADSR tables)
// and the sample_brr*.dat / sample_brr.inc data files.

#include "engine/sound/SampleBank.h"
#include <cstdio>

// ---------------------------------------------------------------------------
// Where each instrument lives in the BRR data files.
// file: 0 = sound/sample_brr.dat
//       1 = sound/sample_brr_2f.dat  (UNKNOWN_1, index 29)
//       2 = sound/sample_brr_33.dat  (UNKNOWN_2, index 33)
// ---------------------------------------------------------------------------
struct SampleLoc { int file; int offset; };

// ---------------------------------------------------------------------------
// SampleLoopStart from src/sound/song-data.asm.
// Each value is a byte offset from the start of the instrument's BRR data
// to the loop point (i.e. the relative part of SAMPDIR loop_addr).
// The 65816 init code writes: SAMPDIR.loop_addr = spc_start_addr + k_loopStart[i]
// Values equal to or greater than the BRR data size mean the sample does not
// loop (loop_flag will be 0 in the BRR end block for those instruments).
// ---------------------------------------------------------------------------
static const int k_loopStart[NUM_INSTRUMENTS] = {
    0x0A8C, // 0  BASS_DRUM
    0x0BD9, // 1  SNARE
    0x1194, // 2  HARD_SNARE
    0x05FA, // 3  CYMBAL
    0x15F9, // 4  TOM
    0x0465, // 5  CLOSED_HIHAT
    0x1194, // 6  OPEN_HIHAT
    0x1194, // 7  TIMPANI
    0x04F5, // 8  VIBRAPHONE
    0x029A, // 9  MARIMBA
    0x08F7, // 10 STRINGS
    0x02C7, // 11 CHOIR
    0x034E, // 12 HARP
    0x04DA, // 13 TRUMPET
    0x0252, // 14 OBOE
    0x0489, // 15 FLUTE
    0x0936, // 16 ORGAN
    0x0642, // 17 PIANO
    0x0144, // 18 ELECTRIC_BASS
    0x044A, // 19 BASS_GUITAR
    0x05BB, // 20 GRAND_PIANO
    0x0666, // 21 MUSIC_BOX_INSTR
    0x1194, // 22 WOO
    0x09BD, // 23 METAL_SYSTEM
    0x0384, // 24 SYNTH_CHORD
    0x05BB, // 25 DIST_GUITAR
    0x092D, // 26 KRABI
    0x15F9, // 27 HORN
    0x0318, // 28 MANDOLIN
    0x077D, // 29 UNKNOWN_1
    0x08DC, // 30 CONGA
    0x088D, // 31 CASABA
    0x09E1, // 32 KLAVES
    0x0E7C, // 33 UNKNOWN_2
    0x0B6D, // 34 HAND_CLAP
};

static const SampleLoc k_sampleLoc[NUM_INSTRUMENTS] = {
    {0,      0}, {0,   2702}, {0,   5737}, {0,  10239}, {0,  13904},  // 0-4
    {0,  19531}, {0,  20658}, {0,  25160}, {0,  29662}, {0,  32337},  // 5-9
    {0,  33041}, {0,  41107}, {0,  44655}, {0,  45530}, {0,  47467},  // 10-14
    {0,  48099}, {0,  49586}, {0,  52432}, {0,  56799}, {0,  57287},  // 15-19
    {0,  58711}, {0,  60504}, {0,  63494}, {0,  67996}, {0,  76305},  // 20-24
    {0,  82121}, {0,  84967}, {0,  89109}, {0,  94772},               // 25-28
    {1,      0},                                                        // 29 UNKNOWN_1
    {0,  95647}, {0,  98655}, {0, 100844},                            // 30-32
    {2,      0},                                                        // 33 UNKNOWN_2
    {0, 103375},                                                        // 34
};

// ---------------------------------------------------------------------------
// Per-instrument metadata from song-data.asm.
// SampleFreqMult: {lo, hi} pairs.
// SampleADSR:     make_adsr(attack,decay,sustain,release) →
//                   byte0 = $80|(attack&$0f)|((decay&$07)<<4)
//                   byte1 = (release&$1f)|((sustain&$07)<<5)
// ---------------------------------------------------------------------------
const SampleMeta SampleBank::k_meta[NUM_INSTRUMENTS] = {
    {0xC0,0x00, 0xFF,0xE0}, // 0  BASS_DRUM
    {0x00,0x00, 0xFF,0xE0}, // 1  SNARE
    {0xC0,0x00, 0xFF,0xE0}, // 2  HARD_SNARE
    {0x00,0x00, 0xFF,0xF0}, // 3  CYMBAL         release=16
    {0x60,0x00, 0xFF,0xE0}, // 4  TOM
    {0x00,0x00, 0xFF,0xE0}, // 5  CLOSED_HIHAT
    {0x00,0x00, 0xFF,0xE0}, // 6  OPEN_HIHAT
    {0xFB,0x00, 0xFF,0xE0}, // 7  TIMPANI
    {0xFE,0x48, 0xFF,0xF0}, // 8  VIBRAPHONE     release=16
    {0xE0,0xA0, 0xFF,0xF5}, // 9  MARIMBA        release=21
    {0x00,0x7C, 0xFF,0xE0}, // 10 STRINGS
    {0xFD,0x00, 0xFF,0xE0}, // 11 CHOIR
    {0x51,0x00, 0xFF,0xF2}, // 12 HARP           release=18
    {0xFE,0x00, 0xFF,0xE1}, // 13 TRUMPET        release=1
    {0xE0,0x90, 0xFF,0xE1}, // 14 OBOE           release=1
    {0xFC,0x60, 0xFF,0xE1}, // 15 FLUTE          release=1
    {0xFC,0x7F, 0xFF,0xE0}, // 16 ORGAN
    {0xFF,0x00, 0xFF,0xED}, // 17 PIANO          release=13
    {0xFC,0xC0, 0xFF,0xE0}, // 18 ELECTRIC_BASS
    {0xFC,0xA0, 0xFF,0xEC}, // 19 BASS_GUITAR    release=12
    {0xFC,0xD0, 0xFF,0xEA}, // 20 GRAND_PIANO    release=10
    {0xFF,0xA0, 0xFF,0xF3}, // 21 MUSIC_BOX_INSTR release=19
    {0x00,0x00, 0xFF,0xE0}, // 22 WOO
    {0x00,0x00, 0xFF,0xEA}, // 23 METAL_SYSTEM   release=10
    {0x00,0x00, 0xFF,0xEA}, // 24 SYNTH_CHORD    release=10
    {0x00,0x00, 0xFF,0xE8}, // 25 DIST_GUITAR    release=8
    {0xFE,0x00, 0xFF,0xF3}, // 26 KRABI          release=19
    {0xE0,0xB0, 0xFF,0xE1}, // 27 HORN           release=1
    {0xFC,0x90, 0xFF,0xF1}, // 28 MANDOLIN       release=17
    {0xE0,0xC0, 0xFF,0xF4}, // 29 UNKNOWN_1      release=20
    {0x00,0x00, 0xFF,0xF3}, // 30 CONGA          release=19
    {0x00,0x00, 0xFF,0xE0}, // 31 CASABA
    {0x0E,0x00, 0xFF,0xE0}, // 32 KLAVES
    {0x00,0x00, 0xFF,0xE0}, // 33 UNKNOWN_2
    {0x00,0x00, 0xFF,0xE0}, // 34 HAND_CLAP
};

uint8_t SampleBank::songInstrument(int songIdx, int slotK) const {
    if (songIdx < 0 || songIdx >= NUM_SONGS || slotK < 0 || slotK >= SONG_SLOTS)
        return 0xFF;
    if (m_songSamples.empty())
        return 0xFF;
    return m_songSamples[(size_t)songIdx * SONG_SLOTS + slotK];
}

bool SampleBank::load(const AssetManager& assets) {
    // Load song-sample slot table (generated by tools/encode_song_samples.py).
    m_songSamples = assets.loadBinary("sound/song_samples.dat");
    if (m_songSamples.size() != (size_t)NUM_SONGS * SONG_SLOTS) {
        std::fprintf(stderr,
            "[SampleBank] song_samples.dat: expected %d bytes, got %zu — "
            "run 'make rip' to regenerate\n",
            NUM_SONGS * SONG_SLOTS, m_songSamples.size());
        m_songSamples.assign((size_t)NUM_SONGS * SONG_SLOTS, 0xFF);
    }

    auto dat    = assets.loadBinary("sound/sample_brr.dat");
    auto dat_2f = assets.loadBinary("sound/sample_brr_2f.dat");
    auto dat_33 = assets.loadBinary("sound/sample_brr_33.dat");

    if (dat.empty()) {
        std::fprintf(stderr, "[SampleBank] failed to load sound/sample_brr.dat\n");
        return false;
    }

    const std::vector<uint8_t>* files[3] = {&dat, &dat_2f, &dat_33};

    for (int i = 0; i < NUM_INSTRUMENTS; i++) {
        const SampleLoc& loc  = k_sampleLoc[i];
        const auto&      file = *files[loc.file];
        int offset = loc.offset;

        if (offset + 2 > (int)file.size()) {
            std::fprintf(stderr, "[SampleBank] instrument %d: offset %d out of range (%zu bytes)\n",
                         i, offset, file.size());
            continue;
        }

        // 2-byte LE prefix = BRR data size in bytes (used for bounds checking).
        // Loop byte offset comes from k_loopStart[] (from SampleLoopStart in song-data.asm):
        //   SAMPDIR.loop_addr = spc_start_addr + k_loopStart[i]
        // i.e. k_loopStart[i] is a relative byte offset within the BRR data.
        int brrSize     = (int)file[offset] | ((int)file[offset + 1] << 8);
        int loopByteOfs = k_loopStart[i];

        const uint8_t* brrData = file.data() + offset + 2;

        // Scan to find the end-flagged block so we don't over-decode
        int brrLen = 0;
        for (int b = 0; b + 8 < brrSize; b += 9) {
            brrLen = b + 9;
            if (brrData[b] & 0x01) break;  // end-flag bit
        }

        m_samples[i] = BRRDecoder::decode(brrData, brrLen, loopByteOfs);
    }

    return true;
}
