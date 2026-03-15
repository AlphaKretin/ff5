// Ported from src/menu/menu-main.asm
// Porting status: STUB

#include "engine/menu/Menu.h"
#include "engine/Engine.h"
#include <cstdio>

Menu::Menu(Engine& engine) : m_engine(engine) {}

void Menu::exec() {
    // TODO: port menu-main.asm ExecMenu
    // Menu type is in WRAM $0134; common types:
    //   0 = main menu
    //   3 = game load/save menu (called from Start before FieldLoop)
    std::fprintf(stderr, "[Menu] exec() not yet ported (type=%u)\n", m_engine.r8(0x0134));
}
