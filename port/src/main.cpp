#include <SDL2/SDL.h>   // must be included before other SDL headers for SDL_main

#include "platform/gfx/IRenderer.h"
#include "platform/audio/IAudioOutput.h"
#include "platform/input/IInput.h"
#include "engine/assets/AssetManager.h"

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
#include <cstring>
#include <memory>

// Window size: 3× native SNES resolution (256×224 → 768×672)
constexpr int WINDOW_SCALE  = 3;
constexpr int WINDOW_WIDTH  = SNES_WIDTH  * WINDOW_SCALE;
constexpr int WINDOW_HEIGHT = SNES_HEIGHT * WINDOW_SCALE;

// Target frame duration in milliseconds (60 fps)
constexpr double MS_PER_FRAME = 1000.0 / 60.0;

// ---------------------------------------------------------------------------
// loadTestAssets — temporary, exercises the renderer pipeline before any
// game code is ported. Loads the UI window graphics (window.pal +
// window_jp.4bpp), writes them to VRAM/CGRAM, and sets up BG1 to display
// all 48 tiles in a grid. Remove once real game init is ported.
// ---------------------------------------------------------------------------
static void loadTestAssets(IRenderer& renderer, const AssetManager& assets) {
    // --- Palette ---
    // window.pal: 64 bytes = 32 SNES colors = palettes 0 and 1 (16 colors each)
    auto pal = assets.loadPalette("gfx/window.pal");
    if (pal.empty()) {
        std::fprintf(stderr, "Warning: could not load gfx/window.pal\n");
        return;
    }
    renderer.writeCGRAM(0, pal.data(), static_cast<uint16_t>(pal.size()));

    // --- Tile graphics ---
    // window_jp.4bpp: 1536 bytes = 48 tiles × 32 bytes (4bpp)
    // Written to VRAM word 0 (byte 0); charBase=0 → char data starts at byte 0.
    auto tiles = assets.loadBinary("gfx/window_jp.4bpp");
    if (tiles.empty()) {
        std::fprintf(stderr, "Warning: could not load gfx/window_jp.4bpp\n");
        return;
    }
    renderer.writeVRAM(0, tiles.data(), static_cast<uint16_t>(tiles.size()));

    // --- Tilemap ---
    // Place the 48 window tiles in order across the first two rows of the map.
    // Tilemap at scAddr=8 → byte 0x4000 = word 0x2000 in VRAM.
    // Entry format (16-bit LE): bits 9-0 = tile number, bits 12-10 = palette.
    static uint8_t tilemap[32 * 32 * 2] = {};
    std::memset(tilemap, 0, sizeof(tilemap));
    for (int i = 0; i < 48; ++i) {
        tilemap[i * 2 + 0] = static_cast<uint8_t>(i & 0xFF);
        tilemap[i * 2 + 1] = static_cast<uint8_t>((i >> 8) & 0x03);
    }
    renderer.writeVRAM(0x2000, tilemap, static_cast<uint16_t>(sizeof(tilemap)));

    // --- PPU registers ---
    renderer.setBGMode(1, 0, 0);
    renderer.setBGCharBase(0, 0);          // char data at VRAM byte 0
    renderer.setBGTilemapBase(0, 8, false, false);  // tilemap at VRAM byte 0x4000
    renderer.setDisplayBrightness(15);
}

// ---------------------------------------------------------------------------

int main(int argc, char* argv[]) {
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

    if (!audio->init(32000, 2)) {
        std::fprintf(stderr, "Audio init failed\n");
        return 1;
    }

    // Asset root: path to the disassembly's src/ directory.
    // Override with argv[1] if provided; otherwise fall back to a path relative
    // to the default CMake build output location.
    const char* assetRootArg = (argc > 1) ? argv[1] : "../../../../src";
    AssetManager assets(assetRootArg);

    loadTestAssets(*renderer, assets);

    // ── Game loop ───────────────────────────────────────────────────────────

    uint64_t frameStart = SDL_GetTicks64();

    while (!input->isQuitRequested()) {
        input->poll();

        // TODO: game->update(*input)

        renderer->beginFrame();
        // TODO: game->render(*renderer)
        renderer->endFrame();

        // Simple frame cap — vsync handles the common case; this covers
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
