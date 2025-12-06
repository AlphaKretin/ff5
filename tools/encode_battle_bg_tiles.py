#!/usr/bin/env python3

import sys
from ff5_compress import encode_battle_bg_tiles

if __name__ == '__main__':

    src_path = sys.argv[1]
    with open(src_path, 'rb') as src_file:
        tilemap_bytes = bytearray(src_file.read())

    assert len(tilemap_bytes) == 0x0500, 'Invalid battle bg tilemap size'

    encoded_tiles = encode_battle_bg_tiles(tilemap_bytes)
    dest_path = src_path + '.bgt'
    with open(dest_path, 'wb') as dest_file:
        dest_file.write(encoded_tiles)
