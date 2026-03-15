#pragma once

#include <cstdint>
#include <vector>

// ---------------------------------------------------------------------------
// BRRDecoder
//
// Decodes SNES BRR (Bit Rate Reduction) audio blocks to int16 PCM.
//
// sample_brr.dat per-instrument layout:
//   [2-byte LE] loop_start_offset — byte offset from start of BRR data to
//                                   the loop-point block (divisible by 9).
//                                   Non-looping: equals total BRR byte count.
//   [N × 9 bytes] BRR blocks until a block with the end-flag set.
//
// Each 9-byte BRR block:
//   byte 0  (header): range[7:4] | filter[3:2] | loop[1] | end[0]
//   bytes 1-8: 8 data bytes → 16 signed 4-bit nibbles → 16 int16 samples
// ---------------------------------------------------------------------------

struct DecodedSample {
    std::vector<int16_t> pcm;
    int  loopStart = 0;   // PCM sample index where the loop starts
    bool loops     = false;
};

class BRRDecoder {
public:
    // Decodes BRR data starting at `data` for `len` bytes.
    // `loopByteOfs` is the byte offset within `data` of the loop-start block.
    static DecodedSample decode(const uint8_t* data, int len,
                                int loopByteOfs);
};
