#!/usr/bin/env python3

import json
import os
import sys
import romtools as rt


if __name__ == '__main__':

    asset_path = sys.argv[1]

    # read asset file
    with open(asset_path, 'r', encoding='utf8') as json_file:
        asset_def = json.load(json_file)

    # create a text codec
    text_codec = rt.TextCodec()
    if 'item_size' in asset_def:
        text_codec.item_size = asset_def['item_size']
    for char_table in asset_def['char_tables']:
        text_codec.load_char_table(f'tools/char_table/{char_table}.json')

    # encode each string
    item_list = [text_codec.encode(item) for item in asset_def['text']]

    # condense the array and generate a pointer table
    encoded_bytes, item_ranges = rt.condense_array(item_list, **asset_def)

    # update the include file
    if 'inc_path' in asset_def:
        rt.update_array_inc(item_ranges, **asset_def)

    # write the encoded binary data to the data path
    dat_path = os.path.splitext(asset_path)[0] + '.dat'
    with open(dat_path, 'wb') as f:
        f.write(encoded_bytes)
