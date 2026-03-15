// Ported from src/sound/sound-main.asm + src/sound/ff5-spc.asm
// Porting status: STUB

#include "engine/sound/Sound.h"
#include "engine/Engine.h"
#include <cstdio>

Sound::Sound(Engine& engine) : m_engine(engine) {}

void Sound::init() {
    // TODO: port sound-main.asm InitSound
    // Sets up the SPC-700 communication protocol and loads the SPC program.
}

void Sound::exec() {
    // TODO: port sound-main.asm ExecSound + ff5-spc.asm sequencer
    // Sends queued music/SFX commands to the SPC-700 sequencer.
}
