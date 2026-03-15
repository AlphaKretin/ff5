#include "engine/Engine.h"
#include "engine/field/Field.h"
#include "engine/battle/Battle.h"
#include "engine/menu/Menu.h"
#include "engine/cutscene/Cutscene.h"
#include "engine/sound/Sound.h"

#include <SDL2/SDL.h>
#include <cstdio>

Engine::Engine(IRenderer& renderer, IAudioOutput& audio,
               IInput& input, AssetManager& assets)
    : m_renderer(renderer), m_audio(audio), m_input(input), m_assets(assets)
{
    m_field    = new Field(*this);
    m_battle   = new Battle(*this);
    m_menu     = new Menu(*this);
    m_cutscene = new Cutscene(*this);
    m_sound    = new Sound(*this);
}

Engine::~Engine() {
    delete m_sound;
    delete m_cutscene;
    delete m_menu;
    delete m_battle;
    delete m_field;
}

void Engine::run() {
    // The field module owns the top-level game flow, mirroring the SNES reset
    // vector which jumps straight into field-main.asm's Start procedure.
    m_field->start();
}
