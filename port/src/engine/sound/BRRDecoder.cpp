// Ported from SNES BRR (Bit Rate Reduction) decoder logic.
// Mirrors the decode performed by the SNES DSP hardware.

#include "engine/sound/BRRDecoder.h"
#include <algorithm>

DecodedSample BRRDecoder::decode(const uint8_t* data, int len,
                                 int loopByteOfs) {
    DecodedSample result;
    result.loopStart = (loopByteOfs / 9) * 16;  // convert byte offset → sample index

    if (!data || len < 9) return result;

    int prev1 = 0, prev2 = 0;

    for (int offset = 0; offset + 8 < len; offset += 9) {
        uint8_t header = data[offset];
        int  shift    = (header >> 4) & 0xF;
        int  filter   = (header >> 2) & 0x3;
        bool loopFlag = (header & 0x02) != 0;
        bool endFlag  = (header & 0x01) != 0;

        for (int b = 0; b < 8; b++) {
            uint8_t byte = data[offset + 1 + b];

            // High nibble first, then low nibble
            for (int ni = 1; ni >= 0; ni--) {
                int n = (ni == 1) ? (byte >> 4) : (byte & 0xF);
                if (n >= 8) n -= 16;        // sign-extend 4-bit to int

                // Scale by shift (shifts >= 13 saturate based on sign)
                int s;
                if (shift <= 12) {
                    s = (n << shift) >> 1;  // arithmetic right-shift preserves sign
                } else {
                    s = (n < 0) ? -0x4000 : 0;
                }

                // Apply IIR filter (mirrors SNES DSP BRR filter modes)
                switch (filter) {
                    case 1:
                        s += prev1 - (prev1 >> 4);
                        break;
                    case 2:
                        s += 2*prev1 - ((prev1*3 + 16) >> 5)
                             - prev2  + ((prev2  + 8 ) >> 4);
                        break;
                    case 3:
                        s += 2*prev1 - ((prev1*13 + 32) >> 6)
                             - prev2  + ((prev2* 3 + 16) >> 4);
                        break;
                    default:
                        break;
                }

                s = std::max(-32768, std::min(32767, s));
                result.pcm.push_back(static_cast<int16_t>(s));
                prev2 = prev1;
                prev1 = s;
            }
        }

        if (endFlag) {
            result.loops = loopFlag;
            break;
        }
    }

    return result;
}
