#pragma once

#include <cstdint>

// SNES button bitmask — matches the hardware JOYA/JOYB serial layout.
// Bit 15 is the first button clocked out; bit 4 is the last used bit.
enum SNESButton : uint16_t {
    BTN_B      = 1 << 15,
    BTN_Y      = 1 << 14,
    BTN_SELECT = 1 << 13,
    BTN_START  = 1 << 12,
    BTN_UP     = 1 << 11,
    BTN_DOWN   = 1 << 10,
    BTN_LEFT   = 1 <<  9,
    BTN_RIGHT  = 1 <<  8,
    BTN_A      = 1 <<  7,
    BTN_X      = 1 <<  6,
    BTN_L      = 1 <<  5,
    BTN_R      = 1 <<  4,
};

class IInput {
public:
    virtual ~IInput() = default;

    // Process OS events. Call once per frame before reading button state.
    virtual void poll() = 0;

    // True if the user or OS has requested the application to close.
    virtual bool isQuitRequested() const = 0;

    // Current held buttons for the given player (0-indexed).
    // Returns a bitmask of SNESButton values.
    virtual uint16_t getButtons(int player) const = 0;

    // Buttons pressed this frame (rising edge).
    virtual uint16_t getButtonsPressed(int player) const = 0;
};
