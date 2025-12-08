#!/usr/bin/env python3

import json
import glob
import os, sys
import romtools as rt

def clean_assets(rip_list):
    # remove text strings from all json files
    for text_def in rip_list['text']:
        json_path = text_def['json_path']
        with open(json_path, 'r', encoding='utf8') as f:
            text_def = json.load(f)

        # clear auto-generated code in the include file
        if 'inc_path' in text_def:
            inc_path = text_def['inc_path']
            rt.insert_asm(inc_path, '')

        # clear the text array
        text_def['text'] = []

        # write back to the json file
        asset_json = json.dumps(text_def, ensure_ascii=False, indent=2)
        with open(json_path, 'w', encoding='utf8') as f:
            f.write(asset_json)

    # remove data assets
    for data_def in rip_list['data'] + rip_list['array']:
        file_path = data_def['file_path']
        if '%s' in file_path:
            file_path = file_path.replace('%s', '*')

        for asset_path in glob.glob(file_path):
            if os.path.exists(asset_path):
                os.remove(asset_path)

        if file_path.endswith('.lz'):
            for asset_path in glob.glob(file_path[:-3]):
                if os.path.exists(asset_path):
                    # remove uncompressed asset files
                    os.remove(asset_path)
        elif file_path.endswith('.cmp'):
            for asset_path in glob.glob(file_path[:-4]):
                if os.path.exists(asset_path):
                    # remove uncompressed asset files
                    os.remove(asset_path)
        elif file_path.endswith('.trm'):
            for asset_path in glob.glob(file_path[:-4]):
                if os.path.exists(asset_path):
                    # remove trimmed monster graphics files
                    os.remove(asset_path)
        elif file_path.endswith('.bgt'):
            for asset_path in glob.glob(file_path[:-4]):
                if os.path.exists(asset_path):
                    # remove trimmed monster graphics files
                    os.remove(asset_path)
        elif file_path.endswith('.bgf'):
            for asset_path in glob.glob(file_path[:-4]):
                if os.path.exists(asset_path):
                    # remove trimmed monster graphics files
                    os.remove(asset_path)

        # clear out automatically generated code from include files
        if 'inc_path' in data_def:
            rt.insert_asm(data_def['inc_path'], '')

        asset_dir = os.path.dirname(file_path)
        if os.path.isdir(asset_dir) and not os.listdir(asset_dir):
            os.rmdir(asset_dir)


if __name__ == '__main__':

    rip_list_path = sys.argv[1]

    with open(rip_list_path, 'r', encoding='utf8') as f:
        rip_list = json.load(f)
    clean_assets(rip_list)

