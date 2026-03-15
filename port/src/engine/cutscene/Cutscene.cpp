// Ported from src/cutscene/cutscene-main.asm
// Porting status: STUB

#include "engine/cutscene/Cutscene.h"
#include "engine/Engine.h"
#include <cstdio>

Cutscene::Cutscene(Engine& engine) : m_engine(engine) {}

void Cutscene::show(uint8_t id) {
    // TODO: port cutscene-main.asm ShowCutscene
    // id $F1 = title screen / credits (called first thing on startup)
    std::fprintf(stderr, "[Cutscene] show(0x%02X) not yet ported\n", id);
}
