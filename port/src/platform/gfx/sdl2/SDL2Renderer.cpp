#ifdef FF5_GFX_SDL2

#include "SDL2Renderer.h"
#include <SDL2/SDL.h>
#include <cstring>
#include <cstdio>

// ── Lifecycle ─────────────────────────────────────────────────────────────────

SDL2Renderer::~SDL2Renderer() {
    shutdown();
}

bool SDL2Renderer::init(int windowWidth, int windowHeight, const char* title) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        SDL_Log("SDL_Init(VIDEO) failed: %s", SDL_GetError());
        return false;
    }

    m_window = SDL_CreateWindow(
        title,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        windowWidth, windowHeight,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    if (!m_window) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        return false;
    }

    m_renderer = SDL_CreateRenderer(m_window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!m_renderer) {
        SDL_Log("SDL_CreateRenderer failed: %s", SDL_GetError());
        return false;
    }

    // Keep pixel art sharp when scaling
    SDL_RenderSetLogicalSize(m_renderer, SNES_WIDTH, SNES_HEIGHT);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

    // The off-screen render target at native SNES resolution
    m_renderTarget = SDL_CreateTexture(
        m_renderer,
        SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET,
        SNES_WIDTH, SNES_HEIGHT
    );
    if (!m_renderTarget) {
        SDL_Log("SDL_CreateTexture (render target) failed: %s", SDL_GetError());
        return false;
    }

    m_windowWidth  = windowWidth;
    m_windowHeight = windowHeight;
    return true;
}

void SDL2Renderer::shutdown() {
    if (m_tileAtlas)    { SDL_DestroyTexture(m_tileAtlas);    m_tileAtlas    = nullptr; }
    if (m_renderTarget) { SDL_DestroyTexture(m_renderTarget); m_renderTarget = nullptr; }
    if (m_renderer)     { SDL_DestroyRenderer(m_renderer);    m_renderer     = nullptr; }
    if (m_window)       { SDL_DestroyWindow(m_window);        m_window       = nullptr; }
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
}

// ── Frame ─────────────────────────────────────────────────────────────────────

void SDL2Renderer::beginFrame() {
    // Render into the native-resolution target
    SDL_SetRenderTarget(m_renderer, m_renderTarget);

    // Apply master brightness as a black overlay tint (0 = black, 15 = full)
    uint8_t bright = static_cast<uint8_t>((m_brightness * 255) / 15);
    SDL_SetRenderDrawColor(m_renderer, 0, 0, 0, 255);
    SDL_RenderClear(m_renderer);
    // TODO: render BG layers and sprites here as porting progresses
    (void)bright;
}

void SDL2Renderer::endFrame() {
    // Switch to the default (window) target and blit the render target,
    // SDL_RenderSetLogicalSize already handles aspect-correct scaling.
    SDL_SetRenderTarget(m_renderer, nullptr);
    SDL_RenderCopy(m_renderer, m_renderTarget, nullptr, nullptr);
    SDL_RenderPresent(m_renderer);
}

// ── Display control ───────────────────────────────────────────────────────────

void SDL2Renderer::setDisplayBrightness(uint8_t brightness) {
    m_brightness = brightness & 0x0F;
}

// ── BG mode ───────────────────────────────────────────────────────────────────

void SDL2Renderer::setBGMode(uint8_t mode, uint8_t bg3Priority, uint8_t tileSizeFlags) {
    m_bgMode = mode;
    // TODO: store and apply bg3Priority / tileSizeFlags during rendering
    (void)bg3Priority;
    (void)tileSizeFlags;
}

// ── VRAM ──────────────────────────────────────────────────────────────────────

void SDL2Renderer::writeVRAM(uint16_t wordAddr, const uint8_t* data, uint16_t byteCount) {
    uint32_t byteAddr = static_cast<uint32_t>(wordAddr) * 2;
    if (byteAddr + byteCount > VRAM_SIZE_BYTES) {
        SDL_Log("writeVRAM: out-of-bounds write at word 0x%04X", wordAddr);
        byteCount = static_cast<uint16_t>(VRAM_SIZE_BYTES - byteAddr);
    }
    std::memcpy(m_vram + byteAddr, data, byteCount);
    invalidateTileCache();
}

// ── CGRAM ─────────────────────────────────────────────────────────────────────

void SDL2Renderer::writeCGRAM(uint8_t cgAddr, const uint16_t* colors, uint16_t count) {
    for (uint16_t i = 0; i < count && (cgAddr + i) < CGRAM_SIZE; ++i)
        m_cgram[cgAddr + i] = colors[i];
    invalidateTileCache();
}

// ── OAM ───────────────────────────────────────────────────────────────────────

void SDL2Renderer::writeOAM(const uint8_t* oam, uint16_t byteCount) {
    if (byteCount > sizeof(m_oam))
        byteCount = static_cast<uint16_t>(sizeof(m_oam));
    std::memcpy(m_oam, oam, byteCount);
}

// ── BG scroll / tile map ──────────────────────────────────────────────────────

void SDL2Renderer::setBGScroll(int bg, uint16_t hofs, uint16_t vofs) {
    if (bg < 0 || bg > 3) return;
    m_bgHofs[bg] = hofs;
    m_bgVofs[bg] = vofs;
}

void SDL2Renderer::setBGTilemapBase(int bg, uint8_t scAddr, bool hMirror, bool vMirror) {
    if (bg < 0 || bg > 3) return;
    m_bgRegs[bg].scAddr  = scAddr;
    m_bgRegs[bg].hMirror = hMirror;
    m_bgRegs[bg].vMirror = vMirror;
}

void SDL2Renderer::setBGCharBase(int bg, uint8_t charAddr) {
    if (bg < 0 || bg > 3) return;
    m_bgRegs[bg].charBase = charAddr;
    invalidateTileCache();
}

// ── Internal helpers ──────────────────────────────────────────────────────────

SDL_Color SDL2Renderer::snesColorToSDL(uint16_t c) {
    // SNES: 0bxBBBBBGGGGGRRRRR — 5 bits per channel, no alpha
    // Expand each channel from 5 bits to 8 bits (shift left 3, fill low bits)
    uint8_t r = static_cast<uint8_t>((c & 0x001F) << 3 | (c & 0x001F) >> 2);
    uint8_t g = static_cast<uint8_t>(((c >> 5) & 0x1F) << 3 | ((c >> 5) & 0x1F) >> 2);
    uint8_t b = static_cast<uint8_t>(((c >> 10) & 0x1F) << 3 | ((c >> 10) & 0x1F) >> 2);
    return SDL_Color{ r, g, b, 255 };
}

void SDL2Renderer::invalidateTileCache() {
    m_atlasInvalid = true;
}

#endif // FF5_GFX_SDL2
