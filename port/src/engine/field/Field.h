#pragma once

class Engine;

// ---------------------------------------------------------------------------
// Field
//
// Ported from src/field/field-main.asm.
// Owns the top-level game flow: title cutscene → save/load menu → field loop.
// Calls into Battle, Menu, Cutscene, and Sound as the game progresses.
// ---------------------------------------------------------------------------
class Field {
public:
    explicit Field(Engine& engine);

    // Entry point — mirrors the SNES reset vector → field-main.asm Start.
    // Initialises hardware, shows the title cutscene, runs the save/load menu,
    // then enters the field loop. Does not return until the user quits.
    void start();

    // The main field game loop — mirrors field-main.asm FieldLoop.
    // Called by start() and re-entered after returning from menus/battles.
    void execFieldLoop();

private:
    Engine& m_engine;
};
