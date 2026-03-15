// Ported from src/field/field-main.asm
//
// Porting status: PARTIAL — Start() flow is ported; individual sub-routines
// (cutscene, menu, map loading, event system) are still stubs.

#include "engine/field/Field.h"
#include "engine/Engine.h"
#include "engine/sound/Sound.h"
#include "engine/cutscene/Cutscene.h"
#include "engine/menu/Menu.h"
#include "platform/gfx/IRenderer.h"

#include <cstring>
#include <cstdio>

Field::Field(Engine& engine) : m_engine(engine) {}

// ---------------------------------------------------------------------------
// initHardware — mirrors field-main.asm InitHardware
//
// On SNES this wrote to PPU/DMA registers. In the port we translate the
// meaningful ones into IRenderer calls; purely SNES-specific registers
// (window math, colour math, IRQ timing, HDMA) are no-ops here.
// ---------------------------------------------------------------------------
void Field::initHardware() {
    IRenderer& r = m_engine.renderer();

    r.setDisplayBrightness(0);          // hINIDISP=$80  — force blank

    r.setOBJSEL(3);                     // hOBJSEL=3     — nameBase=3 (word addr $6000)

    // hBGMODE=$09 — Mode 1, BG3 high priority, no large tiles
    r.setBGMode(1, /*bg3Priority=*/1, /*tileSizeFlags=*/0);

    // hBG12NBA=$00 — BG1 charBase=0, BG2 charBase=0 (×$2000 bytes each)
    r.setBGCharBase(0, 0);
    r.setBGCharBase(1, 0);

    // hBG34NBA=$04 — BG3 charBase=4 (=$8000 bytes), BG4 charBase=0
    r.setBGCharBase(2, 4);
    r.setBGCharBase(3, 0);

    // hTM=$13, hTS=$04, hTMW=$17 — layer enable registers (no port equivalent yet)
    // Window, colour math, IRQ, HDMA registers — no port equivalent yet
}

// ---------------------------------------------------------------------------
// Start — mirrors field-main.asm Start
// ---------------------------------------------------------------------------
void Field::start() {
    // ── CPU / RAM init ───────────────────────────────────────────────────────
    // sei / clc / xce / longi / shorta — CPU mode setup, no-op in port.
    // hMEMSEL / hMDMAEN / hHDMAEN — SNES bus/DMA config, no-op in port.

    // stx $06 — zero WRAM word at $0006 (used as a zero-source register).
    m_engine.w16(0x06, 0);

    // _c0490a: zero WRAM $0000–$1CFF (RAM clear after reset)
    std::memset(m_engine.wram(), 0, 0x1D00);

    // ── Sound init ───────────────────────────────────────────────────────────
    // jsl InitSound_ext
    m_engine.sound().init();

    // ── Title / credits cutscene ─────────────────────────────────────────────
    // lda #$f1 / jsr ShowCutscene
    // ShowCutscene also calls _c044e3 (reset data bank / direct page — no-op).
    m_engine.cutscene().show(0xF1);

    // ── First InitHardware call ───────────────────────────────────────────────
    // Resets PPU registers after the cutscene leaves them in an arbitrary state.
    initHardware();

    // ── Game-load / save menu ────────────────────────────────────────────────
    // lda #3 / sta $0134 / jsl ExecMenu_ext
    m_engine.w8(0x0134, 3);
    m_engine.menu().exec();

    // ── Second InitHardware + InitInterrupts ─────────────────────────────────
    // Called after menu returns to ensure clean PPU state before field runs.
    // InitInterrupts writes NMI/IRQ vectors into WRAM — no-op in port.
    initHardware();

    // ── New game vs. restore save ────────────────────────────────────────────
    // lda $0139 / beq NewGame
    // $0139 is written by ExecMenu_ext: 0 = new game, non-zero = save slot.
    if (m_engine.r8(0x0139) == 0) {
        // NewGame path:
        //   _c048fa — init character data from CharProp table  (TODO)
        //   _c048ed — init event flags                         (TODO)
        //   _c048dd — init npc flags                           (TODO)
        //   _c04528 — init character names                     (TODO)
        //   _c0450a — init vehicles                            (TODO)
        //   $bd=1 (show party sprite), $bc=1 (enable walk anim)
        //   $ce = event $0010 (intro event)                    (TODO)
        m_engine.w8(0xBD, 1);
        m_engine.w8(0xBC, 1);
        std::fprintf(stderr, "[Field] new game — intro event not yet ported\n");
    } else {
        // Restore-save path:
        //   _c0491d — zero WRAM $0B00–$1CFF                   (TODO)
        //   restore map position from $0AD8/$0AD9
        //   LoadMapNoFade                                      (TODO)
        std::fprintf(stderr, "[Field] load save — map loading not yet ported\n");
    }

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
    m_engine.sound().playSong(0);  // TODO: play the correct song for the current map

    while (!input.isQuitRequested()) {
        input.poll();
        m_engine.sound().exec();
        renderer.beginFrame();
        renderer.endFrame();
    }
}
