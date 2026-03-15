#pragma once

class Engine;

// ---------------------------------------------------------------------------
// Battle
//
// Ported from src/battle/battle-main.asm.
// Entry point mirrors ExecBattle_ext (long-call from field/menu).
// ---------------------------------------------------------------------------
class Battle {
public:
    explicit Battle(Engine& engine);

    // Mirrors ExecBattle_ext / ExecBattle in battle-main.asm.
    void exec();

private:
    Engine& m_engine;
};
