#pragma once

#include "platform/gfx/IRenderer.h"
#include "platform/audio/IAudioOutput.h"
#include "platform/input/IInput.h"
#include "engine/assets/AssetManager.h"

#include <cstdint>
#include <cstring>

// Forward declarations of module classes
class Field;
class Battle;
class Menu;
class Cutscene;
class Sound;

// ---------------------------------------------------------------------------
// Engine
//
// Central coordinator for the port. Owns the 128KB WRAM buffer (mirroring
// SNES banks $7E-$7F) and holds references to all platform interfaces.
// Module classes (Field, Battle, Menu, etc.) receive a reference to Engine
// and read/write WRAM and call platform interfaces through it.
//
// The top-level game flow starts at Engine::run(), which calls Field::start().
// ---------------------------------------------------------------------------
class Engine {
public:
    Engine(IRenderer& renderer, IAudioOutput& audio,
           IInput& input, AssetManager& assets);
    ~Engine();

    // Runs the game. Does not return until the user quits.
    void run();

    // ── WRAM access ──────────────────────────────────────────────────────────
    // WRAM spans $7E0000–$7FFFFF on the SNES (128KB). Addresses here are
    // 16-bit offsets within that range (i.e. subtract $7E0000 from any SNES
    // long address). Bank $7F continues from offset $10000.
    uint8_t  r8 (uint16_t addr) const          { return m_wram[addr]; }
    uint16_t r16(uint16_t addr) const          { return m_wram[addr] | (uint16_t(m_wram[addr + 1]) << 8); }
    void     w8 (uint16_t addr, uint8_t  val)  { m_wram[addr] = val; }
    void     w16(uint16_t addr, uint16_t val)  { m_wram[addr] = val & 0xFF; m_wram[addr + 1] = val >> 8; }
    uint8_t* wram()                            { return m_wram; }

    // ── Platform interface accessors ─────────────────────────────────────────
    IRenderer&    renderer() { return m_renderer; }
    IAudioOutput& audio()    { return m_audio; }
    IInput&       input()    { return m_input; }
    AssetManager& assets()   { return m_assets; }

    // ── Module accessors (for cross-module calls) ─────────────────────────────
    Field&    field()    { return *m_field; }
    Battle&   battle()   { return *m_battle; }
    Menu&     menu()     { return *m_menu; }
    Cutscene& cutscene() { return *m_cutscene; }
    Sound&    sound()    { return *m_sound; }

private:
    IRenderer&    m_renderer;
    IAudioOutput& m_audio;
    IInput&       m_input;
    AssetManager& m_assets;

    // 128KB WRAM mirror ($7E0000–$7FFFFF)
    uint8_t m_wram[0x20000] = {};

    // Game modules (owned by Engine, allocated in constructor)
    Field*    m_field    = nullptr;
    Battle*   m_battle   = nullptr;
    Menu*     m_menu     = nullptr;
    Cutscene* m_cutscene = nullptr;
    Sound*    m_sound    = nullptr;
};
