// Ported from src/sound/sound-main.asm + src/sound/ff5-spc.asm
//
// Porting status: PARTIAL
//   Implemented: sample loading, BRR decode, basic song sequencer
//   Not yet: SFX, volume/tempo envelopes, ADSR, echo, vibrato/tremolo

#include "engine/sound/Sound.h"
#include "engine/Engine.h"
#include "platform/audio/IAudioOutput.h"
#include <cstdio>

// ---------------------------------------------------------------------------
// Song byte offsets into song_script.dat (from include/sound/song_script.inc).
// Index 65 ($41) is in the alternate file song_script_41.dat.
// ---------------------------------------------------------------------------
static const int k_songOffsets[72] = {
       0,  1426,  3020,  5231,  6453,  7597,  8550,  9701, 10491, 11504,
   14517, 14775, 15257, 16346, 17045, 17685, 18172, 18825, 18853, 19567,
   20575, 22270, 23482, 24407, 24985, 25809, 26353, 27434, 27848, 29468,
   30425, 54960, 31377, 32786, 34899, 37497, 53544, 39019, 48827, 39388,
   40891, 42189, 42447, 55882, 42866, 43660, 44706, 45861, 46263, 46840,
   48066, 49622, 50958, 52604, 51091, 52774, 51299, 53275, 52986, 51784,
   52195, 54446, 57251, 57798, 59226,    -1, 62867, 64477, 66140, 71434,
   71644, 71702
};
// Index 65 = -1 means it lives in song_script_41.dat at offset 0.

Sound::Sound(Engine& engine) : m_engine(engine) {}

// ---------------------------------------------------------------------------
// init — loads sample data; mirrors InitSound_ext
// ---------------------------------------------------------------------------

void Sound::init() {
    AssetManager& assets = m_engine.assets();

    if (!m_sampleBank.load(assets)) {
        std::fprintf(stderr, "[Sound] SampleBank load failed — audio will be silent\n");
        return;
    }

    m_sequencer = std::make_unique<Sequencer>(m_sampleBank);
    m_ready     = true;
}

// ---------------------------------------------------------------------------
// exec — generate and submit one frame of audio; mirrors ExecSound_ext
// ---------------------------------------------------------------------------

void Sound::exec() {
    if (!m_ready || !m_sequencer) return;

    IAudioOutput& audio = m_engine.audio();

    // Keep the audio queue comfortably filled: target ~2 frames of buffer.
    if (audio.queuedFrames() >= FRAMES_PER_EXEC * 2)
        return;

    m_sequencer->generateAudio(m_audioBuf, FRAMES_PER_EXEC);
    audio.submitSamples(m_audioBuf, FRAMES_PER_EXEC * 2);
}

// ---------------------------------------------------------------------------
// playSong / stopSong
// ---------------------------------------------------------------------------

void Sound::playSong(int songIdx) {
    if (!m_ready || !m_sequencer) return;
    if (songIdx < 0 || songIdx >= 72) {
        std::fprintf(stderr, "[Sound] invalid song index %d\n", songIdx);
        return;
    }

    AssetManager& assets = m_engine.assets();

    // Song 65 ($41) uses an alternate script file
    if (songIdx == 65) {
        auto data = assets.loadBinary("sound/song_script_41.dat");
        if (data.empty()) {
            std::fprintf(stderr, "[Sound] failed to load song_script_41.dat\n");
            return;
        }
        m_sequencer->playSong(data.data(), (int)data.size(), songIdx);
        return;
    }

    int offset = k_songOffsets[songIdx];
    if (offset < 0) {
        std::fprintf(stderr, "[Sound] song %d has no data\n", songIdx);
        return;
    }

    auto dat = assets.loadBinary("sound/song_script.dat");
    if (dat.empty() || offset >= (int)dat.size()) {
        std::fprintf(stderr, "[Sound] failed to load song_script.dat\n");
        return;
    }

    m_sequencer->playSong(dat.data() + offset, (int)dat.size() - offset, songIdx);
}

void Sound::stopSong() {
    if (m_sequencer) m_sequencer->stopSong();
}
