#!/usr/bin/env python3

import os
import binascii
import json
import romtools as rt
from ff5_compress import *


def write_asset_file(asset_bytes, asset_path):

    # create directories
    os.makedirs(os.path.dirname(asset_path), exist_ok=True)

    # decompress the data, if necessary
    if asset_path.endswith('.lz'):
        with open(asset_path[:-3], 'wb') as f:
            f.write(decode_lzss(asset_bytes))
    elif asset_path.endswith('.cmp'):
        with open(asset_path[:-4], 'wb') as f:
            f.write(decode_multi(asset_bytes))
    elif asset_path.endswith('.bgt'):
        with open(asset_path[:-4], 'wb') as f:
            f.write(decode_battle_bg_tiles(asset_bytes))
    elif asset_path.endswith('.bgf'):
        with open(asset_path[:-4], 'wb') as f:
            f.write(decode_battle_bg_flip(asset_bytes))

    # save the raw data
    with open(asset_path, 'wb') as f:
        f.write(asset_bytes)


def extract_text(ae, text_def):
    assert 'json_path' in text_def, 'json_path not found'
    json_path = text_def['json_path']

    # read the json file
    with open(json_path, 'r', encoding='utf8') as json_file:
        asset_def = json.load(json_file)

    # check if the data file already exists and is not empty
    dat_path = os.path.splitext(json_path)[0] + '.dat'
    if os.path.exists(dat_path) and os.stat(dat_path).st_size != 0:
        return

    # otherwise, we need to extract the text and create the data file
    assert 'asset_range' in text_def, 'asset_range not found'
    asset_range = text_def['asset_range']
    print(f'{asset_range} -> {json_path}')

    # for fixed-length text strings, copy the item length to text_def
    if 'item_size' in asset_def:
        text_def['item_size'] = asset_def['item_size']

    # extract the text from the ROM
    asset_bytes, item_ranges = ae.extract_asset(**text_def)

    # update include file
    if 'inc_path' in asset_def:
        rt.update_array_inc(item_ranges, **asset_def)

    # create the text codec
    text_codec = rt.TextCodec()
    if 'item_size' in asset_def:
        text_codec.item_size = asset_def['item_size']
    for char_table in asset_def['char_tables']:
        text_codec.load_char_table(f'tools/char_table/{char_table}.json')

    # decode the text strings
    text_list = []
    for item_range in item_ranges:
        item_bytes = asset_bytes[item_range.begin:item_range.end + 1]
        text_list.append(text_codec.decode(item_bytes))

    asset_def['text'] = text_list

    # write text strings to the asset file
    asset_json = json.dumps(asset_def, ensure_ascii=False, indent=2)
    with open(json_path, 'w', encoding='utf8') as f:
        f.write(asset_json)

    # write data file
    write_asset_file(asset_bytes, dat_path)


def extract_data(ae, data_def):

    # extract the asset from the ROM
    asset_bytes, item_ranges = ae.extract_asset(**data_def)

    # generate a list of file names
    assert 'file_path' in data_def, 'file_path not found'
    file_path = data_def['file_path']
    if 'file_list' in data_def:
        file_list = data_def['file_list']
        assert len(file_list) == len(item_ranges), 'array length mismatch'
    else:
        file_list = [('%04x' % i) for i in range(len(item_ranges))]
    path_list = [
        file_path.replace('%s', file_list[i])
        for i in range(len(item_ranges))
    ]

    assert 'asset_range' in data_def, 'asset_range not found'
    asset_range = data_def['asset_range']
    extracted_one = False
    for i, item_range in enumerate(item_ranges):
        if os.path.exists(path_list[i]):
            continue
        if item_range.is_empty() or item_range.begin < 0:
            continue
        if not extracted_one:
            extracted_one = True
            print(f'{asset_range} -> {file_path}')
        data_bytes = asset_bytes[item_range.begin:item_range.end + 1]
        write_asset_file(data_bytes, path_list[i])


def extract_array(ae, array_def):

    # extract the array data from the ROM
    asset_bytes, item_ranges = ae.extract_asset(**array_def)

    assert 'file_path' in array_def, 'file_path not found'
    file_path = array_def['file_path']
    if os.path.exists(file_path):
        return

    # write data file
    assert 'asset_range' in array_def, 'asset_range not found'
    asset_range = array_def['asset_range']
    print(f'{asset_range} -> {file_path}')
    write_asset_file(asset_bytes, file_path)

    # check if an include file exists
    if 'inc_path' in array_def:
        rt.update_array_inc(item_ranges, **array_def)


if __name__ == '__main__':

    # search the vanilla directory for valid ROM files
    dir_list = os.listdir('vanilla')

    found_one = False
    for file_name in dir_list:

        # skip directory names
        if os.path.isdir(file_name):
            continue
        file_path = os.path.join('vanilla', file_name)

        # read the file and calculate its CRC32
        with open(file_path, 'rb') as file:
            file_bytes = bytearray(file.read())
        crc32 = binascii.crc32(file_bytes) & 0xFFFFFFFF

        if crc32 == 0xC1BC267D:
            rom_name = 'Final Fantasy V 1.0 (J)'
            rom_language = 'jp'
        elif crc32 == 0x17444605:
            rom_name = 'Final Fantasy V 1.10 (RPGe)'
            rom_language = 'en'
        else:
            continue

        print(f'Found ROM: {rom_name}')
        print(f'File: {file_path}')
        found_one = True

        # load rip info
        rip_list_path = os.path.join('tools', f'rip_list_{rom_language}.json')
        with open(rip_list_path, 'r', encoding='utf8') as rip_list_file:
            rip_list = json.load(rip_list_file)

        ae = rt.AssetExtractor(file_bytes, 'hirom')
        [extract_text(ae, text_def) for text_def in rip_list['text']]
        [extract_data(ae, data_def) for data_def in rip_list['data']]
        [extract_array(ae, array_def) for array_def in rip_list['array']]

    if not found_one:
        print('No valid ROM files found!')
        print('Please copy your valid FF5 ROM file(s) into the ' +
              '"vanilla" directory.')
        print('If your ROM has a 512-byte copier header, please remove it ' +
              'first.')
    else:

        # decode world tilemaps
        if not os.path.isdir('src/field/world_tilemap') and os.path.exists('src/field/world_tilemap.dat'):
            os.mkdir('src/field/world_tilemap')
            with open('src/field/world_tilemap.dat', 'rb') as world_tilemap_file:
                world_tilemap_bytes = bytearray(world_tilemap_file.read())
            decoded_bytes = decode_world(world_tilemap_bytes)
            for w in range(5):
                with open('src/field/world_tilemap/world_tilemap_%d.dat' % w, 'wb') as f:
                    f.write(decoded_bytes[0x10000 * w:0x10000 * (w + 1)])
