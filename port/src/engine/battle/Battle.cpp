// Ported from src/battle/battle-main.asm
// Porting status: STUB

#include "engine/battle/Battle.h"
#include "engine/Engine.h"
#include <cstdio>

Battle::Battle(Engine& engine) : m_engine(engine) {}

void Battle::exec() {
    // TODO: port battle-main.asm ExecBattle
    std::fprintf(stderr, "[Battle] exec() not yet ported\n");
}
