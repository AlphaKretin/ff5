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

    // All rendering targets SNES_WIDTH×SNES_HEIGHT; SDL scales to fill the window.
    SDL_RenderSetLogicalSize(m_renderer, SNES_WIDTH, SNES_HEIGHT);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");  // nearest-neighbour — keep pixels sharp

    m_streamTexture = SDL_CreateTexture(
        m_renderer,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING,
        SNES_WIDTH, SNES_HEIGHT
    );
    if (!m_streamTexture) {
        SDL_Log("SDL_CreateTexture (stream) failed: %s", SDL_GetError());
        return false;
    }

    return true;
}

void SDL2Renderer::shutdown() {
    if (m_streamTexture) { SDL_DestroyTexture(m_streamTexture); m_streamTexture = nullptr; }
    if (m_renderer)      { SDL_DestroyRenderer(m_renderer);     m_renderer      = nullptr; }
    if (m_window)        { SDL_DestroyWindow(m_window);          m_window        = nullptr; }
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
}

// ── Frame ─────────────────────────────────────────────────────────────────────

void SDL2Renderer::beginFrame() {
    // Nothing to do: the game updates VRAM/CGRAM/OAM state during the frame.
    // Actual rendering happens in endFrame once all state is settled.
}

void SDL2Renderer::endFrame() {
    buildFrame();

    // Upload the CPU pixel buffer to the streaming texture
    void* pixels = nullptr;
    int   pitch  = 0;
    SDL_LockTexture(m_streamTexture, nullptr, &pixels, &pitch);
    for (int y = 0; y < SNES_HEIGHT; ++y) {
        std::memcpy(
            static_cast<uint8_t*>(pixels) + y * pitch,
            m_framebuf + y * SNES_WIDTH,
            SNES_WIDTH * sizeof(uint32_t)
        );
    }
    SDL_UnlockTexture(m_streamTexture);

    // Apply master brightness (0–15) via SDL color modulation
    uint8_t bright = static_cast<uint8_t>((m_brightness * 255) / 15);
    SDL_SetTextureColorMod(m_streamTexture, bright, bright, bright);

    SDL_RenderClear(m_renderer);
    SDL_RenderCopy(m_renderer, m_streamTexture, nullptr, nullptr);
    SDL_RenderPresent(m_renderer);
}

// ── Display control ───────────────────────────────────────────────────────────

void SDL2Renderer::setDisplayBrightness(uint8_t brightness) {
    m_brightness = brightness & 0x0F;
}

// ── BG mode ───────────────────────────────────────────────────────────────────

void SDL2Renderer::setBGMode(uint8_t mode, uint8_t bg3Priority, uint8_t tileSizeFlags) {
    m_bgMode = mode;
    (void)bg3Priority;
    (void)tileSizeFlags;
    // TODO: store bg3Priority and tileSizeFlags; apply during rendering
}

// ── VRAM ──────────────────────────────────────────────────────────────────────

void SDL2Renderer::writeVRAM(uint16_t wordAddr, const uint8_t* data, uint16_t byteCount) {
    uint32_t byteAddr = static_cast<uint32_t>(wordAddr) * 2;
    if (byteAddr + byteCount > VRAM_SIZE_BYTES) {
        SDL_Log("writeVRAM: out-of-bounds write at word 0x%04X", wordAddr);
        byteCount = static_cast<uint16_t>(VRAM_SIZE_BYTES - byteAddr);
    }
    std::memcpy(m_vram + byteAddr, data, byteCount);
}

// ── CGRAM ─────────────────────────────────────────────────────────────────────

void SDL2Renderer::writeCGRAM(uint8_t cgAddr, const uint16_t* colors, uint16_t count) {
    for (uint16_t i = 0; i < count && (cgAddr + i) < CGRAM_SIZE; ++i) {
        m_cgram[cgAddr + i]    = colors[i];
        m_colorLut[cgAddr + i] = snesColorPacked(colors[i]);
    }
}

// ── OAM ───────────────────────────────────────────────────────────────────────

void SDL2Renderer::writeOAM(const uint8_t* oam, uint16_t byteCount) {
    if (byteCount > sizeof(m_oam))
        byteCount = static_cast<uint16_t>(sizeof(m_oam));
    std::memcpy(m_oam, oam, byteCount);
}

// ── BG scroll / tilemap base / char base ──────────────────────────────────────

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
}

// ── Frame building ────────────────────────────────────────────────────────────

void SDL2Renderer::buildFrame() {
    // Fill with backdrop color (CGRAM entry 0)
    const uint32_t backdrop = m_colorLut[0] | 0xFF000000u;
    for (int i = 0; i < SNES_WIDTH * SNES_HEIGHT; ++i)
        m_framebuf[i] = backdrop;

    // Painter's algorithm: back layers first.
    // Mode 1: BG3 (2bpp) → BG2 (4bpp) → BG1 (4bpp), then sprites.
    // TODO: proper per-tile priority ordering.
    switch (m_bgMode) {
        case 1:
            renderBG(2);  // BG3, 2bpp
            renderBG(1);  // BG2, 4bpp
            renderBG(0);  // BG1, 4bpp
            break;
        default:
            // For unimplemented modes, render all four layers as 4bpp
            for (int i = 3; i >= 0; --i)
                renderBG(i);
            break;
    }

    renderSprites();
}

void SDL2Renderer::renderBG(int layer) {
    const BGRegs& regs = m_bgRegs[layer];

    // In mode 1, BG3 (layer index 2) uses 2bpp; others use 4bpp.
    const bool is2bpp = (m_bgMode == 1 && layer == 2);
    const int  bytesPerTile = is2bpp ? 16 : 32;

    // VRAM byte addresses derived from register fields:
    //   scAddr   is in units of 0x400 VRAM words = 0x800 bytes
    //   charBase is in units of 0x1000 VRAM words = 0x2000 bytes
    const uint32_t tilemapBase = static_cast<uint32_t>(regs.scAddr)   * 0x800u;
    const uint32_t charBase    = static_cast<uint32_t>(regs.charBase) * 0x2000u;

    for (int sy = 0; sy < SNES_HEIGHT; ++sy) {
        for (int sx = 0; sx < SNES_WIDTH; ++sx) {
            // Apply BG scroll (10-bit wrap)
            const uint32_t mx = (static_cast<uint32_t>(sx) + m_bgHofs[layer]) & 0x3FFu;
            const uint32_t my = (static_cast<uint32_t>(sy) + m_bgVofs[layer]) & 0x3FFu;

            const uint32_t tx = (mx >> 3) & 31u;  // tile column within 32-tile map
            const uint32_t ty = (my >> 3) & 31u;  // tile row
            int px = static_cast<int>(mx & 7u);    // pixel within tile
            int py = static_cast<int>(my & 7u);

            // Tilemap entry: 2 bytes at tilemapBase + (ty*32 + tx)*2
            const uint32_t entryByte = tilemapBase + (ty * 32u + tx) * 2u;
            if (entryByte + 1u >= VRAM_SIZE_BYTES) continue;

            const uint16_t entry   = static_cast<uint16_t>(m_vram[entryByte])
                                   | static_cast<uint16_t>(m_vram[entryByte + 1] << 8);
            const uint16_t tileNum = entry & 0x3FFu;
            const uint8_t  palNum  = static_cast<uint8_t>((entry >> 10) & 7u);
            const bool     hFlip   = (entry >> 14) & 1u;
            const bool     vFlip   = (entry >> 15) & 1u;

            if (hFlip) px = 7 - px;
            if (vFlip) py = 7 - py;

            // Tile graphics address
            const uint32_t tileBase = charBase + static_cast<uint32_t>(tileNum) * bytesPerTile;
            if (tileBase + static_cast<uint32_t>(bytesPerTile) > VRAM_SIZE_BYTES) continue;
            const uint8_t* tile = m_vram + tileBase;

            // Decode palette index from bitplanes
            const int bit = 7 - px;
            uint8_t pixIdx;
            if (is2bpp) {
                // 2bpp: planes 0–1 interleaved, 2 bytes per row
                pixIdx = static_cast<uint8_t>(
                    ((tile[py * 2 + 0] >> bit) & 1u)
                  | (((tile[py * 2 + 1] >> bit) & 1u) << 1)
                );
            } else {
                // 4bpp: planes 0–1 in first 16 bytes, planes 2–3 in second 16 bytes
                pixIdx = static_cast<uint8_t>(
                    ((tile[py * 2 + 0]      >> bit) & 1u)
                  | (((tile[py * 2 + 1]      >> bit) & 1u) << 1)
                  | (((tile[16 + py * 2 + 0] >> bit) & 1u) << 2)
                  | (((tile[16 + py * 2 + 1] >> bit) & 1u) << 3)
                );
            }

            if (pixIdx == 0) continue;  // palette index 0 = transparent

            // CGRAM index:
            //   4bpp BG: palettes 0–7, 16 colors each → base = palNum * 16
            //   2bpp BG: palettes 0–7,  4 colors each → base = palNum * 4
            const uint8_t cgIdx = is2bpp
                ? static_cast<uint8_t>(palNum * 4u  + pixIdx)
                : static_cast<uint8_t>(palNum * 16u + pixIdx);

            m_framebuf[sy * SNES_WIDTH + sx] = m_colorLut[cgIdx] | 0xFF000000u;
        }
    }
}

void SDL2Renderer::renderSprites() {
    // TODO: decode OAM and draw 8×8 / 16×16 sprites.
    // Sprites use CGRAM entries 128–255 (palettes 0–7, 16 colors each).
    // Priority interleaving with BG tiles to be added alongside priority system.
}

// ── Color conversion ──────────────────────────────────────────────────────────

uint32_t SDL2Renderer::snesColorPacked(uint16_t c) {
    // SNES format: 0bxBBBBBGGGGGRRRRR
    // Expand 5-bit channels to 8-bit by replicating the high bits into the low bits.
    const uint8_t r = static_cast<uint8_t>( (c & 0x001Fu) << 3 | (c & 0x001Fu) >> 2);
    const uint8_t g = static_cast<uint8_t>(((c >> 5)  & 0x1Fu) << 3 | ((c >> 5)  & 0x1Fu) >> 2);
    const uint8_t b = static_cast<uint8_t>(((c >> 10) & 0x1Fu) << 3 | ((c >> 10) & 0x1Fu) >> 2);
    return 0xFF000000u | (static_cast<uint32_t>(r) << 16)
                       | (static_cast<uint32_t>(g) <<  8)
                       | static_cast<uint32_t>(b);
}

#endif // FF5_GFX_SDL2
