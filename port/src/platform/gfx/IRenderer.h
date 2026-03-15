#pragma once

#include <cstdint>

// Native SNES rendering resolution
constexpr int SNES_WIDTH  = 256;
constexpr int SNES_HEIGHT = 224;

// SNES VRAM is 64 KB, addressed in 16-bit words
constexpr int VRAM_SIZE_BYTES = 65536;
// CGRAM is 256 entries of 15-bit BGR color packed in 16-bit words
constexpr int CGRAM_SIZE = 256;

// Mirrors the SNES PPU interface so ported code can write to the renderer
// using the same operations it used to write to hardware registers.
// Backends translate these calls to their native graphics API.
class IRenderer {
public:
    virtual ~IRenderer() = default;

    // Open a scaled window. Rendering always targets SNES_WIDTH x SNES_HEIGHT
    // internally; the backend scales to fill the window.
    virtual bool init(int windowWidth, int windowHeight, const char* title) = 0;
    virtual void shutdown() = 0;

    // ── Frame ────────────────────────────────────────────────────────────────
    virtual void beginFrame() = 0;
    virtual void endFrame()   = 0;

    // ── Display control ──────────────────────────────────────────────────────
    // hINIDISP equivalent: brightness 0–15, blank flag
    virtual void setDisplayBrightness(uint8_t brightness) = 0;

    // ── BG mode ──────────────────────────────────────────────────────────────
    // hBGMODE: mode 0–7, BG3 priority flag, tile-size flags per layer
    virtual void setBGMode(uint8_t mode, uint8_t bg3Priority, uint8_t tileSizeFlags) = 0;

    // ── VRAM ─────────────────────────────────────────────────────────────────
    // Write raw bytes into the VRAM mirror at the given word address.
    // Mirrors DMA/direct writes to hVMADDL + hVMDATAL/H.
    virtual void writeVRAM(uint16_t wordAddr, const uint8_t* data, uint16_t byteCount) = 0;

    // ── CGRAM (palette) ──────────────────────────────────────────────────────
    // Write SNES 15-bit BGR colors (0bxBBBBBGGGGGRRRRR) starting at cgAddr.
    // Mirrors writes to hCGADD + hCGDATA.
    virtual void writeCGRAM(uint8_t cgAddr, const uint16_t* colors, uint16_t count) = 0;

    // ── OAM (sprites) ────────────────────────────────────────────────────────
    // Write raw OAM bytes (512 + 32 bytes, SNES layout).
    // Mirrors DMA to OAM.
    virtual void writeOAM(const uint8_t* oam, uint16_t byteCount) = 0;

    // ── BG scroll ────────────────────────────────────────────────────────────
    // bg: 0–3, matching BG1–BG4. Mirrors hBG1HOFS/hBG1VOFS etc.
    virtual void setBGScroll(int bg, uint16_t hofs, uint16_t vofs) = 0;

    // ── BG tile map base + character base ────────────────────────────────────
    // Mirrors hBG1SC, hBG12NBA etc.
    virtual void setBGTilemapBase(int bg, uint8_t scAddr, bool hMirror, bool vMirror) = 0;
    virtual void setBGCharBase(int bg, uint8_t charAddr) = 0;

    // ── OBJ (sprite) settings ─────────────────────────────────────────────────
    // Mirrors hOBJSEL ($2101).
    //   bits 2-0: name base — OBJ char data starts at (nameBase * 0x2000) VRAM words
    //   bits 4-3: name select — second 256-tile page offset from base
    //   bits 6-5: size select — which 8 of the 5 available size pairs to use
    virtual void setOBJSEL(uint8_t objsel) = 0;
};
