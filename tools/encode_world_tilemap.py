#!/usr/bin/env python3

import os
import sys
import romtools as rt
from ff5_compress import encode_world

if __name__ == '__main__':

    # read the raw tilemaps
    world_tilemap_bytes = bytearray(0)
    for w in range(5):
        with open('src/field/world_tilemap/world_tilemap_%d.dat' % w, 'rb') as f:
            world_tilemap_bytes += bytearray(f.read())

    # encode the tilemap rows
    row_bytes = encode_world(world_tilemap_bytes)

    encoded_bytes, row_ranges = rt.condense_array(row_bytes)

    # write the encoded data
    with open('src/field/world_tilemap.dat', 'wb') as f:
        f.write(encoded_bytes)

    # write the row pointers to the include file
    rt.update_array_inc(row_ranges,
                        inc_path='include/field/world_tilemap.inc',
                        asset_label='WorldTilemap',)

