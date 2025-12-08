#!/usr/bin/env python3

import sys
from ff5_compress import encode_battle_bg_flip

if __name__ == '__main__':

    src_path = sys.argv[1]
    with open(src_path, 'rb') as src_file:
        flip_bytes = bytearray(src_file.read())

    assert len(flip_bytes) == 0x0280, 'Invalid battle bg flip size'

    encoded_flip = encode_battle_bg_flip(flip_bytes)
    dest_path = src_path + '.bgf'
    with open(dest_path, 'wb') as dest_file:
        dest_file.write(encoded_flip)
