#pragma once
#ifdef FF5_INPUT_SDL2

#include "platform/input/IInput.h"
#include <SDL2/SDL.h>
#include <array>

class SDL2Input final : public IInput {
public:
    SDL2Input() = default;
    ~SDL2Input() override = default;

    void poll() override;
    bool isQuitRequested() const override { return m_quit; }
    uint16_t getButtons(int player) const override;
    uint16_t getButtonsPressed(int player) const override;

private:
    static constexpr int MAX_PLAYERS = 2;

    // Converts the current keyboard/gamepad state to a SNES button bitmask.
    static uint16_t readKeyboard();
    static uint16_t readGamepad(int playerIndex);

    bool     m_quit                             = false;
    uint16_t m_buttons[MAX_PLAYERS]             = {};
    uint16_t m_buttonsPrev[MAX_PLAYERS]         = {};
};

#endif // FF5_INPUT_SDL2
