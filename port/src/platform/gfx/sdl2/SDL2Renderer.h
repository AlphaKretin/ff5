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
    void setOBJSEL(uint8_t objsel) override;

private:
    // Converts a SNES 15-bit BGR word to a packed ARGB8888 uint32 (0xAARRGGBB).
    static uint32_t snesColorPacked(uint16_t snesColor);

    // Builds the CPU-side frame buffer from current VRAM/CGRAM/OAM state.
    // Called at the start of endFrame before uploading to the GPU.
    void buildFrame();

    // Renders a single BG layer (0–3) into m_framebuf.
    void renderBG(int layer);

    // Renders all OAM sprites into m_framebuf.
    void renderSprites();

    SDL_Window*   m_window        = nullptr;
    SDL_Renderer* m_renderer      = nullptr;

    // Streaming texture: CPU writes m_framebuf here each frame, SDL scales to
    // fill the window via SDL_RenderSetLogicalSize.
    SDL_Texture*  m_streamTexture = nullptr;

    // CPU-side pixel buffer. Each uint32 is ARGB8888 (0xAARRGGBB).
    uint32_t m_framebuf[SNES_WIDTH * SNES_HEIGHT] = {};

    // Mirrors of SNES video memory
    uint8_t  m_vram[VRAM_SIZE_BYTES] = {};
    uint16_t m_cgram[CGRAM_SIZE]     = {};   // SNES 15-bit colors
    uint8_t  m_oam[544]              = {};   // 512 + 32 bytes

    // Precomputed ARGB8888 values for each CGRAM entry.
    // Updated in writeCGRAM to avoid per-pixel color conversion in the hot path.
    uint32_t m_colorLut[CGRAM_SIZE] = {};

    // PPU state
    uint8_t  m_bgMode     = 0;
    uint8_t  m_brightness = 15;
    uint16_t m_bgHofs[4]  = {};
    uint16_t m_bgVofs[4]  = {};

    struct BGRegs {
        uint8_t scAddr   = 0;   // tilemap base:  scAddr   * 0x800 bytes in VRAM
        uint8_t charBase = 0;   // char data base: charBase * 0x2000 bytes in VRAM
        bool    hMirror  = false;
        bool    vMirror  = false;
    };
    BGRegs m_bgRegs[4];

    // OBJSEL ($2101): OBJ name base and size select
    uint8_t m_objsel = 0;
};

#endif // FF5_GFX_SDL2
