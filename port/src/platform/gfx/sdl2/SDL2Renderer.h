#pragma once
#ifdef FF5_GFX_SDL2

#include "platform/gfx/IRenderer.h"
#include <SDL2/SDL.h>
#include <array>
#include <cstdint>

class SDL2Renderer final : public IRenderer {
public:
    SDL2Renderer() = default;
    ~SDL2Renderer() override;

    bool init(int windowWidth, int windowHeight, const char* title) override;
    void shutdown() override;

    void beginFrame() override;
    void endFrame()   override;

    void setDisplayBrightness(uint8_t brightness) override;
    void setBGMode(uint8_t mode, uint8_t bg3Priority, uint8_t tileSizeFlags) override;
    void writeVRAM(uint16_t wordAddr, const uint8_t* data, uint16_t byteCount) override;
    void writeCGRAM(uint8_t cgAddr, const uint16_t* colors, uint16_t count) override;
    void writeOAM(const uint8_t* oam, uint16_t byteCount) override;
    void setBGScroll(int bg, uint16_t hofs, uint16_t vofs) override;
    void setBGTilemapBase(int bg, uint8_t scAddr, bool hMirror, bool vMirror) override;
    void setBGCharBase(int bg, uint8_t charAddr) override;

private:
    // Converts a SNES 15-bit BGR word (0bxBBBBBGGGGGRRRRR) to SDL_Color RGBA.
    static SDL_Color snesColorToSDL(uint16_t snesColor);

    // Marks the tile texture atlas as dirty so it is regenerated on next endFrame.
    void invalidateTileCache();

    SDL_Window*   m_window   = nullptr;
    SDL_Renderer* m_renderer = nullptr;

    // The game renders into this 256×224 texture; it is then scaled to fill
    // the window. This keeps all rendering at native SNES resolution.
    SDL_Texture*  m_renderTarget = nullptr;

    // Mirrors of SNES memory
    uint8_t  m_vram[VRAM_SIZE_BYTES]  = {};
    uint16_t m_cgram[CGRAM_SIZE]      = {};   // SNES 15-bit colors
    uint8_t  m_oam[544]               = {};   // 512 + 32 bytes

    // PPU state
    uint8_t  m_bgMode      = 0;
    uint8_t  m_brightness  = 15;
    uint16_t m_bgHofs[4]   = {};
    uint16_t m_bgVofs[4]   = {};

    struct BGRegs {
        uint8_t scAddr   = 0;
        bool    hMirror  = false;
        bool    vMirror  = false;
        uint8_t charBase = 0;
    };
    BGRegs m_bgRegs[4];

    // Tile atlas: one SDL_Texture that holds decoded 8×8 tiles.
    // Updated lazily when VRAM or CGRAM changes.
    SDL_Texture* m_tileAtlas    = nullptr;
    bool         m_atlasInvalid = true;

    int m_windowWidth  = 0;
    int m_windowHeight = 0;
};

#endif // FF5_GFX_SDL2
