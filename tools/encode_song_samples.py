#!/usr/bin/env python3
"""
Convert raw SNES SongSamples data to the port-format song_samples.dat.

Input  (src/sound/song_samples_raw.dat):
  72 songs × 16 slots × 2-byte LE uint16
  value 0   → unused slot
  value N>0 → 1-based instrument index (from sample_brr.inc enum + 1)

Output (src/sound/song_samples.dat):
  72 songs × 16 bytes (uint8)
  0xFF → unused slot
  N    → 0-based instrument index  (= raw value − 1)

Usage in the port (C++ Sequencer):
  When a song script executes SetSample(slot), the instrument is:
    song_samples.dat[ song_idx * 16 + (slot - 32) ]
  (BGM samples always occupy SPC slots 32–47.)

Custom music compatibility:
  Tools generating songs in SNES script format should append a 16-byte row
  to song_samples.dat for each new song, using 0-based instrument indices
  and 0xFF for unused slots.  Instruments are indexed as follows:

   0 BASS_DRUM    1 SNARE        2 HARD_SNARE   3 CYMBAL
   4 TOM          5 CLOSED_HIHAT 6 OPEN_HIHAT   7 TIMPANI
   8 VIBRAPHONE   9 MARIMBA     10 STRINGS      11 CHOIR
  12 HARP        13 TRUMPET     14 OBOE         15 FLUTE
  16 ORGAN       17 PIANO       18 ELECTRIC_BASS 19 BASS_GUITAR
  20 GRAND_PIANO 21 MUSIC_BOX   22 WOO          23 METAL_SYSTEM
  24 SYNTH_CHORD 25 DIST_GUITAR 26 KRABI        27 HORN
  28 MANDOLIN    29 UNKNOWN_1   30 CONGA        31 CASABA
  32 KLAVES      33 UNKNOWN_2   34 HAND_CLAP
"""

import struct
import sys
import os

SONGS = 72
SLOTS = 16
RAW_PATH = os.path.join('src', 'sound', 'song_samples_raw.dat')
OUT_PATH = os.path.join('src', 'sound', 'song_samples.dat')


def main():
    if not os.path.exists(RAW_PATH):
        print(f'Error: {RAW_PATH} not found — run "make rip" first', file=sys.stderr)
        sys.exit(1)

    with open(RAW_PATH, 'rb') as f:
        raw = f.read()

    expected = SONGS * SLOTS * 2
    if len(raw) != expected:
        print(f'Error: {RAW_PATH}: expected {expected} bytes, got {len(raw)}', file=sys.stderr)
        sys.exit(1)

    out = bytearray()
    for song in range(SONGS):
        for slot in range(SLOTS):
            val = struct.unpack_from('<H', raw, (song * SLOTS + slot) * 2)[0]
            out.append(0xFF if val == 0 else val - 1)

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, 'wb') as f:
        f.write(bytes(out))

    print(f'{RAW_PATH} -> {OUT_PATH} ({len(out)} bytes, {SONGS} songs × {SLOTS} slots)')


if __name__ == '__main__':
    main()
