#pragma once

#include "engine/sound/SampleBank.h"
#include "engine/sound/Sequencer.h"
#include <cstdint>
#include <memory>

class Engine;

// ---------------------------------------------------------------------------
// Sound
//
// Ported from src/sound/sound-main.asm and src/sound/ff5-spc.asm.
// Owns the SampleBank and Sequencer; drives the audio pipeline.
// ---------------------------------------------------------------------------
class Sound {
public:
    explicit Sound(Engine& engine);

    // Mirrors InitSound_ext — loads sample data and prepares the audio pipeline.
    void init();

    // Mirrors ExecSound_ext — called each frame; submits audio to the backend.
    void exec();

    // Play a specific song by index.
    void playSong(int songIdx);

    void stopSong();

private:
    static constexpr int FRAMES_PER_EXEC = 534;  // 32000 Hz / 60 fps ≈ 534

    Engine&     m_engine;
    SampleBank  m_sampleBank;
    std::unique_ptr<Sequencer> m_sequencer;

    bool  m_ready = false;
    float m_audioBuf[FRAMES_PER_EXEC * 2] = {};
};
