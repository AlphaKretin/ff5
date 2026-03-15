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

void SDL2Renderer::setOBJSEL(uint8_t objsel) {
    m_objsel = objsel;
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
    // OAM layout:
    //   Bytes 0–511:  4 bytes per sprite × 128 sprites
    //     [0] X low 8 bits
    //     [1] Y (1–224 on-screen; 0 or ≥240 off-screen)
    //     [2] tile number within page (0–255)
    //     [3] vhoopppt  v=vflip h=hflip oo=priority ppp=palette t=tile_page
    //   Bytes 512–543: 2 bits per sprite — bit0=X high bit, bit1=size select
    //
    // OBJ char data addressing (from OBJSEL, stored in m_objsel):
    //   name_base    = m_objsel & 0x07   → page-0 tiles at name_base * 0x4000 bytes
    //   name_select  = (m_objsel >> 3) & 0x03
    //   page-1 tiles at name_base * 0x4000 + (name_select + 1) * 0x2000 bytes
    //
    // Sprites use CGRAM entries 128–255 (palettes 0–7 → offsets 128, 144, …, 240).
    // Color index 0 within any sprite palette is transparent.
    //
    // TODO: priority interleaving with BG tiles.
    // TODO: 16×16 (and larger) sprite sizes.

    const uint32_t nameBase   = (m_objsel & 0x07u);
    const uint32_t nameSelect = (m_objsel >> 3) & 0x03u;
    const uint32_t page0Base  = nameBase * 0x4000u;                          // byte address
    const uint32_t page1Base  = page0Base + (nameSelect + 1u) * 0x2000u;    // byte address

    // Iterate sprites in reverse order so sprite 0 ends up on top
    for (int s = 127; s >= 0; --s) {
        const uint8_t* entry = m_oam + s * 4;

        // Auxiliary table byte/bit for this sprite
        const uint8_t auxByte = m_oam[512 + s / 4];
        const int     auxShift = (s % 4) * 2;
        const bool    xHigh   = (auxByte >> auxShift) & 1;

        // X: 9-bit value; treat as signed so sprites can slide off the left edge
        int sx = static_cast<int>(entry[0]) | (xHigh ? 0x100 : 0);
        if (sx >= 256) sx -= 512;   // convert to signed: 256–511 → -256 to -1

        const int     sy       = static_cast<int>(entry[1]);
        const uint8_t tileNum  = entry[2];
        const uint8_t attr     = entry[3];
        const bool    tilePage = attr & 0x01;
        const uint8_t palNum   = (attr >> 1) & 0x07;
        const bool    hFlip    = (attr >> 6) & 0x01;
        const bool    vFlip    = (attr >> 7) & 0x01;

        // Off-screen checks (8×8 sprites only for now)
        if (sy == 0 || sy >= 240) continue;             // Y off-screen
        if (sx <= -8 || sx >= SNES_WIDTH) continue;     // X off-screen

        const uint32_t tileBase = (tilePage ? page1Base : page0Base) + tileNum * 32u;
        if (tileBase + 32u > VRAM_SIZE_BYTES) continue;
        const uint8_t* tile = m_vram + tileBase;

        // Sprites use CGRAM 128–255: base = 128 + palNum * 16
        const uint8_t cgBase = static_cast<uint8_t>(128u + palNum * 16u);

        for (int py = 0; py < 8; ++py) {
            const int screenY = sy + py;        // Y=1 is the first visible row
            if (screenY < 1 || screenY > SNES_HEIGHT) continue;

            const int fpy = vFlip ? (7 - py) : py;
            const int bit4 = 7;  // bit index constant

            for (int px = 0; px < 8; ++px) {
                const int screenX = sx + px;
                if (screenX < 0 || screenX >= SNES_WIDTH) continue;

                const int fpx = hFlip ? (7 - px) : px;
                const int bit = bit4 - fpx;

                const uint8_t pixIdx = static_cast<uint8_t>(
                    ((tile[fpy * 2 + 0]      >> bit) & 1u)
                  | (((tile[fpy * 2 + 1]      >> bit) & 1u) << 1)
                  | (((tile[16 + fpy * 2 + 0] >> bit) & 1u) << 2)
                  | (((tile[16 + fpy * 2 + 1] >> bit) & 1u) << 3)
                );

                if (pixIdx == 0) continue;  // transparent

                m_framebuf[(screenY - 1) * SNES_WIDTH + screenX] =
                    m_colorLut[cgBase + pixIdx] | 0xFF000000u;
            }
        }
    }
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
