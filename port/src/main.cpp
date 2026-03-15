#include <SDL2/SDL.h>   // must be included before other SDL headers for SDL_main

#include "platform/gfx/IRenderer.h"
#include "platform/audio/IAudioOutput.h"
#include "platform/input/IInput.h"

#ifdef FF5_GFX_SDL2
#  include "platform/gfx/sdl2/SDL2Renderer.h"
#endif
#ifdef FF5_AUDIO_SDL2
#  include "platform/audio/sdl2/SDL2AudioOutput.h"
#endif
#ifdef FF5_INPUT_SDL2
#  include "platform/input/sdl2/SDL2Input.h"
#endif

#include <cstdio>
#include <memory>

// Window size: 3× native SNES resolution (256×224 → 768×672)
constexpr int WINDOW_SCALE  = 3;
constexpr int WINDOW_WIDTH  = SNES_WIDTH  * WINDOW_SCALE;
constexpr int WINDOW_HEIGHT = SNES_HEIGHT * WINDOW_SCALE;

// Target frame duration in milliseconds (60 fps)
constexpr double MS_PER_FRAME = 1000.0 / 60.0;

int main(int /*argc*/, char* /*argv*/[]) {
    // ── Create platform backends ────────────────────────────────────────────

#ifdef FF5_GFX_SDL2
    auto renderer = std::make_unique<SDL2Renderer>();
#else
#  error "No graphics backend selected. Enable FF5_GFX_SDL2 or add another backend."
#endif

#ifdef FF5_AUDIO_SDL2
    auto audio = std::make_unique<SDL2AudioOutput>();
#else
#  error "No audio backend selected."
#endif

#ifdef FF5_INPUT_SDL2
    auto input = std::make_unique<SDL2Input>();
#else
#  error "No input backend selected."
#endif

    // ── Initialise ─────────────────────────────────────────────────────────

    if (!renderer->init(WINDOW_WIDTH, WINDOW_HEIGHT, "Final Fantasy V")) {
        std::fprintf(stderr, "Renderer init failed\n");
        return 1;
    }

    // SNES native audio rate; stereo
    if (!audio->init(32000, 2)) {
        std::fprintf(stderr, "Audio init failed\n");
        return 1;
    }

    // ── Game loop ───────────────────────────────────────────────────────────

    uint64_t frameStart = SDL_GetTicks64();

    while (!input->isQuitRequested()) {
        input->poll();

        // TODO: game->update(*input)

        renderer->beginFrame();
        // TODO: game->render(*renderer)
        renderer->endFrame();

        // Simple frame cap — vsync handles the common case, this covers
        // situations where vsync is unavailable.
        uint64_t elapsed = SDL_GetTicks64() - frameStart;
        if (elapsed < static_cast<uint64_t>(MS_PER_FRAME))
            SDL_Delay(static_cast<uint32_t>(MS_PER_FRAME - elapsed));
        frameStart = SDL_GetTicks64();
    }

    // ── Shutdown ────────────────────────────────────────────────────────────

    audio->shutdown();
    renderer->shutdown();
    SDL_Quit();

    return 0;
}
