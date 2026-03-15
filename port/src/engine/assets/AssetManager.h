#pragma once

#include <cstdint>
#include <filesystem>
#include <fstream>
#include <vector>

// Loads binary asset files extracted from the ROM by the disassembly toolchain.
// Constructed with the root of the disassembly's src/ directory; all load*
// calls take paths relative to that root.
class AssetManager {
public:
    explicit AssetManager(std::filesystem::path root) : m_root(std::move(root)) {}

    // Returns the raw bytes of a file, or an empty vector on failure.
    std::vector<uint8_t> loadBinary(const std::string& path) const {
        std::ifstream f(m_root / path, std::ios::binary);
        if (!f) return {};
        return std::vector<uint8_t>(
            std::istreambuf_iterator<char>(f),
            std::istreambuf_iterator<char>()
        );
    }

    // Loads a .pal file as an array of SNES 15-bit BGR colors (little-endian
    // uint16_t words). Returns empty on failure or malformed input.
    std::vector<uint16_t> loadPalette(const std::string& path) const {
        auto bytes = loadBinary(path);
        if (bytes.empty() || bytes.size() % 2 != 0) return {};
        std::vector<uint16_t> pal(bytes.size() / 2);
        for (size_t i = 0; i < pal.size(); ++i)
            pal[i] = static_cast<uint16_t>(bytes[i * 2]) |
                     static_cast<uint16_t>(bytes[i * 2 + 1] << 8);
        return pal;
    }

    const std::filesystem::path& root() const { return m_root; }

private:
    std::filesystem::path m_root;
};
