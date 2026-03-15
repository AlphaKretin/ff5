#include <SDL2/SDL.h>   // must be included before other SDL headers for SDL_main

#include "platform/gfx/IRenderer.h"
#include "platform/audio/IAudioOutput.h"
#include "platform/input/IInput.h"
#include "engine/assets/AssetManager.h"
#include "engine/Engine.h"

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

int main(int argc, char* argv[]) {
    // ── Platform backends ───────────────────────────────────────────────────

#ifdef FF5_GFX_SDL2
    auto renderer = std::make_unique<SDL2Renderer>();
#else
#  error "No graphics backend selected."
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

    if (!renderer->init(WINDOW_WIDTH, WINDOW_HEIGHT, "Final Fantasy V")) {
        std::fprintf(stderr, "Renderer init failed\n");
        return 1;
    }
    if (!audio->init(32000, 2)) {
        std::fprintf(stderr, "Audio init failed\n");
        return 1;
    }

    // Asset root: path to the disassembly's src/ directory.
    // Override with argv[1] if provided; the default is relative to the
    // standard CMake build output location (port/build/sdl2-windows/Debug/).
    const char* assetRoot = (argc > 1) ? argv[1] : "../../../../src";
    AssetManager assets(assetRoot);

    // ── Run the game ────────────────────────────────────────────────────────

    Engine engine(*renderer, *audio, *input, assets);
    engine.run();

    // ── Shutdown ────────────────────────────────────────────────────────────

    audio->shutdown();
    renderer->shutdown();
    SDL_Quit();

    return 0;
}
