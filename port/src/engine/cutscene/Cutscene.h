#pragma once
#include <cstdint>

class Engine;

// ---------------------------------------------------------------------------
// Cutscene
//
// Ported from src/cutscene/cutscene-main.asm.
// Entry point mirrors ShowCutscene_ext.
// ---------------------------------------------------------------------------
class Cutscene {
public:
    explicit Cutscene(Engine& engine);

    // Mirrors ShowCutscene_ext. id $F1 is the title/credits sequence.
    void show(uint8_t id);

private:
    Engine& m_engine;
};
