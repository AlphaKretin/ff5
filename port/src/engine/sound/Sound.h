#pragma once
#include <cstdint>

class Engine;

// ---------------------------------------------------------------------------
// Sound
//
// Ported from src/sound/sound-main.asm and src/sound/ff5-spc.asm.
// Manages communication with (the ported version of) the SPC-700 sequencer.
// Entry points mirror InitSound_ext and ExecSound_ext.
// ---------------------------------------------------------------------------
class Sound {
public:
    explicit Sound(Engine& engine);

    // Mirrors InitSound_ext — called once at startup.
    void init();

    // Mirrors ExecSound_ext — called each frame or when music/sfx state changes.
    // Song/SFX command is passed in registers before the call; equivalent data
    // will be passed as parameters once the calling convention is understood.
    void exec();

private:
    Engine& m_engine;
};
