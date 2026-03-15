#ifdef FF5_INPUT_SDL2

#include "SDL2Input.h"
#include <SDL2/SDL.h>

void SDL2Input::poll() {
    // Save previous state for edge detection
    for (int p = 0; p < MAX_PLAYERS; ++p)
        m_buttonsPrev[p] = m_buttons[p];

    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT)
            m_quit = true;
        // Individual key events are handled via SDL_GetKeyboardState below,
        // but SDL_QUIT must be caught from the event queue.
    }

    m_buttons[0] = readKeyboard();
    if (SDL_NumJoysticks() > 0) m_buttons[0] |= readGamepad(0);
    if (SDL_NumJoysticks() > 1) m_buttons[1]  = readGamepad(1);
}

uint16_t SDL2Input::getButtons(int player) const {
    if (player < 0 || player >= MAX_PLAYERS) return 0;
    return m_buttons[player];
}

uint16_t SDL2Input::getButtonsPressed(int player) const {
    if (player < 0 || player >= MAX_PLAYERS) return 0;
    // Rising edge: on this frame but not last frame
    return m_buttons[player] & ~m_buttonsPrev[player];
}

// Default keyboard mapping (player 1):
//   Arrow keys  → D-pad
//   Z/X         → B/A
//   A/S         → Y/X
//   Q/W         → L/R
//   Enter       → Start
//   Right Shift → Select
uint16_t SDL2Input::readKeyboard() {
    const uint8_t* keys = SDL_GetKeyboardState(nullptr);
    uint16_t btns = 0;

    if (keys[SDL_SCANCODE_UP])          btns |= BTN_UP;
    if (keys[SDL_SCANCODE_DOWN])        btns |= BTN_DOWN;
    if (keys[SDL_SCANCODE_LEFT])        btns |= BTN_LEFT;
    if (keys[SDL_SCANCODE_RIGHT])       btns |= BTN_RIGHT;
    if (keys[SDL_SCANCODE_Z])           btns |= BTN_B;
    if (keys[SDL_SCANCODE_X])           btns |= BTN_A;
    if (keys[SDL_SCANCODE_A])           btns |= BTN_Y;
    if (keys[SDL_SCANCODE_S])           btns |= BTN_X;
    if (keys[SDL_SCANCODE_Q])           btns |= BTN_L;
    if (keys[SDL_SCANCODE_W])           btns |= BTN_R;
    if (keys[SDL_SCANCODE_RETURN])      btns |= BTN_START;
    if (keys[SDL_SCANCODE_RSHIFT])      btns |= BTN_SELECT;

    return btns;
}

uint16_t SDL2Input::readGamepad(int playerIndex) {
    // TODO: replace with SDL_GameController API for proper button mapping.
    // This stub opens the raw joystick and maps common layouts.
    SDL_Joystick* joy = SDL_JoystickOpen(playerIndex);
    if (!joy) return 0;

    uint16_t btns = 0;
    // Axis: 0 = left stick X, 1 = left stick Y (threshold ±8192)
    constexpr int16_t THRESHOLD = 8192;
    if (SDL_JoystickGetAxis(joy, 1) < -THRESHOLD) btns |= BTN_UP;
    if (SDL_JoystickGetAxis(joy, 1) >  THRESHOLD) btns |= BTN_DOWN;
    if (SDL_JoystickGetAxis(joy, 0) < -THRESHOLD) btns |= BTN_LEFT;
    if (SDL_JoystickGetAxis(joy, 0) >  THRESHOLD) btns |= BTN_RIGHT;

    // Generic face buttons — actual mapping varies by controller
    if (SDL_JoystickGetButton(joy, 0)) btns |= BTN_B;
    if (SDL_JoystickGetButton(joy, 1)) btns |= BTN_A;
    if (SDL_JoystickGetButton(joy, 2)) btns |= BTN_Y;
    if (SDL_JoystickGetButton(joy, 3)) btns |= BTN_X;
    if (SDL_JoystickGetButton(joy, 4)) btns |= BTN_L;
    if (SDL_JoystickGetButton(joy, 5)) btns |= BTN_R;
    if (SDL_JoystickGetButton(joy, 6)) btns |= BTN_SELECT;
    if (SDL_JoystickGetButton(joy, 7)) btns |= BTN_START;

    SDL_JoystickClose(joy);
    return btns;
}

#endif // FF5_INPUT_SDL2
