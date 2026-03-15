// Ported from src/field/field-main.asm
//
// Porting status: STUB — none of the game logic is ported yet.
// This file will grow as field-main.asm is translated function by function.

#include "engine/field/Field.h"
#include "engine/Engine.h"
#include "engine/sound/Sound.h"
#include "engine/cutscene/Cutscene.h"
#include "engine/menu/Menu.h"

#include <cstdio>

Field::Field(Engine& engine) : m_engine(engine) {}

void Field::start() {
    // TODO: port field-main.asm Start
    //
    // Original flow:
    //   InitSound_ext
    //   ShowCutscene($f1)    ← title/credits
    //   ExecMenu_ext(3)      ← game load menu
    //   if new game → init character data, event flags, intro event
    //   if load game → restore save data, load map
    //   FieldLoop

    std::fprintf(stderr, "[Field] start() not yet ported — entering field loop stub\n");
    execFieldLoop();
}

void Field::execFieldLoop() {
    // TODO: port field-main.asm FieldLoop
    //
    // Each iteration:
    //   WaitVBlank
    //   check menu button ($02 & JOY_X) → ExecMenu_ext if pressed
    //   CheckTriggers / ExecTriggerScript
    //   update map scroll, NPCs, sprite animation
    //   update sound (ExecSound_ext)

    std::fprintf(stderr, "[Field] execFieldLoop() not yet ported\n");

    // Temporary: keep the window alive until the user closes it
    auto& input    = m_engine.input();
    auto& renderer = m_engine.renderer();
    while (!input.isQuitRequested()) {
        input.poll();
        renderer.beginFrame();
        renderer.endFrame();
    }
}
