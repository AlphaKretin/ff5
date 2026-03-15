#pragma once
#include <cstdint>

class Engine;

// ---------------------------------------------------------------------------
// Menu
//
// Ported from src/menu/menu-main.asm.
// Entry point mirrors ExecMenu_ext.
// ---------------------------------------------------------------------------
class Menu {
public:
    explicit Menu(Engine& engine);

    // Mirrors ExecMenu_ext. The menu type is passed in WRAM $0134 before
    // calling; common values: 0=main menu, 3=game load/save menu.
    void exec();

private:
    Engine& m_engine;
};
