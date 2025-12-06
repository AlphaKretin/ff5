#!/usr/bin/env python3

import sys
import numpy as np


def encode_rle16(src):
    if len(src) == 0:
        return bytearray(0)

    # make sure the length is even
    if len(src) & 1:
        src = src + b'\x00'

    # source pointer
    s = 0

    # destination buffer
    dest = bytearray(0x10000)
    d = 0

    # raw string buffer
    buffer = bytearray(0x0100)
    b = 0

    def put_buffer():
        nonlocal b, d
        if b == 0:
            return
        # write the raw buffer
        dest[d] = (b // 2 - 1) | 0x80
        d += 1
        dest[d:d + b] = buffer[:b]
        d += b
        b = 0

    while s < len(src):

        # check if rle can be used
        run = 2
        while (s + run < len(src)) and (src[s:s + 2] == src[s + run:s + run + 2]):
            run += 2

        if run > 2:
            # long enough to use RLE
            put_buffer()
            run = min(run, 0x0100)
            dest[d] = run // 2 - 1
            d += 1
            dest[d] = src[s]
            dest[d + 1] = src[s + 1]
            d += 2
            s += run
        else:
            # not long enough for RLE
            buffer[b] = src[s]
            buffer[b + 1] = src[s + 1]
            b += 2
            s += 2

        # don't let the raw buffer get longer than 128 bytes
        if b == 0x0100:
            put_buffer()

    # write any remaining raw bytes
    put_buffer()

    # add the null terminator
    dest[d] = 0
    d += 1

    return dest[:d]

def decode_rle16(src):
    # return an empty buffer if the source buffer is empty
    if len(src) == 0:
        return bytearray(0)

    s = 0  # source pointer

    # destination buffer
    dest = bytearray(0x10000)
    d = 0

    while s < len(src):
        b = src[s]
        s += 1

        if b == 0:
            # null terminator
            break

        elif b & 0x80:
            # raw string
            b &= 0x7F
            n = (b + 1) * 2
            dest[d:d + n] = src[s:s + n]
            s += n
            d += n

        else:
            # repeated 16-bit value
            n = b + 1
            n *= 2
            val1 = src[s]
            val2 = src[s + 1]
            dest[d:d + n] = [val1, val2] * n
            s += 2
            d += n

    return dest[:d]

def encode_rle8(src):
    if len(src) == 0:
        return bytearray(0)

    # source pointer
    s = 0

    # destination buffer
    dest = bytearray(0x10000)
    d = 0

    # raw string buffer
    buffer = bytearray(0x80)
    b = 0

    def put_buffer():
        nonlocal b, d
        if b == 0:
            return
        # write the raw buffer
        dest[d] = (b - 1) | 0x80
        d += 1
        dest[d:d + b] = buffer[:b]
        d += b
        b = 0

    while s < len(src):

        # check if rle can be used
        run = 1
        while (s + run < len(src)) and (src[s] == src[s + run]):
            run += 1

        if run > 1:
            # long enough to use RLE
            put_buffer()
            run = min(run, 0x80)
            dest[d] = run - 1
            d += 1
            dest[d] = src[s]
            d += 1
            s += run
        else:
            # not long enough for RLE
            buffer[b] = src[s]
            b += 1
            s += 1

        # don't let the raw buffer get longer than 128 bytes
        if b == 0x80:
            put_buffer()

    # write any remaining raw bytes
    put_buffer()

    # add the null terminator
    dest[d] = 0
    d += 1

    return dest[:d]

def decode_rle8(src):

    # return an empty buffer if the source buffer is empty
    if len(src) == 0:
        return bytearray(0)

    s = 0  # source pointer

    # destination buffer
    dest = bytearray(0x10000)
    d = 0

    while s < len(src):
        b = src[s]
        s += 1

        if b == 0:
            # null terminator
            break

        elif b & 0x80:
            # raw string
            b &= 0x7F
            n = b + 1
            dest[d:d + n] = src[s:s + n]
            s += n
            d += n

        else:
            # repeated 8-bit value
            n = b + 1
            val = src[s]
            dest[d:d + n] = [val] * n
            s += 1
            d += n

    return dest[:d]

def encode_lzss(src):

    # remember the source length
    src_len = len(src)

    if src_len == 0:
        # return empty if length is zero
        return bytearray(0)
    elif src_len == 1:
        # submap tilemaps filled with a single byte
        return bytearray(src)

    # create a source buffer preceded by 2K of empty space
    # (this increases compression for some data)
    src = bytearray(0x0800) + src
    s = 0x0800  # start at 0x0800 to ignore the 2K of empty space

    # destination buffer
    dest = bytearray(0x10000)
    d = 2  # start at 2 so we can fill in the length at the end

    # lzss header byte and mask
    header = 0
    mask = 1

    # lzss line buffer
    line = bytearray(17)
    l = 1  # start at 1 so we can fill in the header at the end
    b = 0x07DE  # buffer position

    while s < len(src):
        # find the longest sequence that matches the decompression buffer
        best_run = 0
        best_offset = 0

        for run in range(34, 2, -1):
            if s + run > len(src):
                continue

            offset = src[s - 0x0800:s + run - 1].rfind(src[s:s + run])

            '''
            Due to a bug in the vanilla decompression subroutine, an offset
            of zero will cause the decompressed data to be corrupted. To fix
            this, set the BUGFIX_DECOMP config variable in include/const.inc
            to 1 and comment out the next two lines.
            '''
            if offset == 0:
                continue

            if offset != -1:
                best_run = run
                best_offset = (b + offset) & 0x07FF
                break

        # check if the longest sequence is compressible
        if best_run != 0:
            # sequence is compressible
            # add compressed data to line buffer
            line[l] = best_offset & 0xFF
            line[l + 1] = ((best_offset >> 3) & 0xE0) | (best_run - 3)
            l += 2
            s += best_run
            b += best_run
        else:
            # sequence is not compressible
            # update header byte and add byte to line buffer
            header |= mask
            line[l] = src[s]
            l += 1
            s += 1
            b += 1

        b &= 0x07FF
        mask <<= 1

        if mask == 0x0100:
            # finished a line, copy it to the destination
            line[0] = header
            dest[d:d + l] = line[0:l]

            d += l
            header = 0
            l = 1
            mask = 1

    if mask != 1:
        # we're done with all the data but we're still in the middle of a line
        line[0] = header
        dest[d:d + l] = line[0:l]
        d += l

    # fill in the length
    dest[0] = src_len & 0xFF
    dest[1] = (src_len >> 8) & 0xFF

    return dest[:d]


def decode_lzss(src):

    # return an empty buffer if the source buffer is empty
    if len(src) == 0:
        return bytearray(0)
    elif len(src) == 1:
        # submap tilemaps filled with a single byte
        return src

    s = 0  # source pointer

    # destination buffer
    dest = bytearray(0x10000)
    d = 0

    # lzss buffer
    buffer = bytearray(0x0800)
    b = 0x0800 - 34  # buffer pointer

    # current line
    line = bytearray(34)

    # read the compressed data length
    length = src[s] | (src[s + 1] << 8)
    s += 2

    while d < length:

        # read header byte
        header = src[s]
        s += 1

        for p in range(8):
            l = 0
            if (header & 1) == 1:
                # single byte (uncompressed)
                c = src[s]
                s += 1
                line[l] = c
                buffer[b] = c
                l += 1
                b = (b + 1) & 0x07FF
            else:
                # 2-bytes (compressed)
                w = src[s]
                s += 1
                r = src[s]
                s += 1
                w |= (r & 0xE0) << 3
                r = (r & 0x1F) + 3

                for i in range(r):
                    c = buffer[(w + i) & 0x07FF]
                    line[l] = c
                    buffer[b] = c
                    l += 1
                    b = (b + 1) & 0x07FF

            if (d + l) > len(dest):
                # maximum destination buffer length exceeded
                dest[d:] = line[:len(dest) - d]
                return dest
            else:
                # copy this pass to the destination buffer
                dest[d:d + l] = line[:l]
                d += l

            # reached end of compressed data
            if (d >= length):
                break

            header >>= 1

    return dest[:d]


def encode_multi(src):

    # try all compression modes to find the best option
    raw_bytes = bytearray([0, len(src) & 0xFF, len(src) >> 8]) + src
    raw_len = len(raw_bytes)

    rle8_bytes = b'\x01' + encode_rle8(src_bytes)
    rle8_len = len(rle8_bytes)

    rle16_bytes = b'\x11' + encode_rle16(src_bytes)
    rle16_len = len(rle16_bytes)

    lzss_bytes = b'\x02' + encode_lzss(src_bytes)
    lzss_len = len(lzss_bytes)

    # find the mode with the shortest compressed length
    len_list = [raw_len, rle8_len, rle16_len, lzss_len]
    best_index = len_list.index(min(len_list))

    bytes_list = [raw_bytes, rle8_bytes, rle16_bytes, lzss_bytes]
    return bytes_list[best_index]


def decode_multi(src):
    mode = src[0]
    mode_lo = mode & 0x0F
    mode_hi = mode & 0xF0
    if mode_lo == 0:
        # no compression
        length = src[1] | (src[2] << 8)
        return src[3:3 + length]

    elif mode_lo == 1:
        # rle

        if mode_hi == 0:
            # 8-bit rle
            return decode_rle8(src[1:])

        elif mode_hi == 1:
            # 16-bit rle
            return decode_rle16(src[1:])

        else:
            raise ValueError('Invalid compression mode: 0x%02X' % mode)

    elif mode_lo == 2:
        # lzss
        return decode_lzss(src[1:])

    else:
        raise ValueError('Invalid compression mode: 0x%02X' % mode)


def encode_world(src):

    # destination buffer
    dest = bytearray(0x10000 * 5)
    d = 0

    row_bytes = []

    for row in range(256 * 5):

        s = 0  # source pointer
        src_row = src[row * 256:row * 256 + 256]

        dest = bytearray(256)
        d = 0

        while s < 256:
            b = src_row[s]
            if b in [0x0C, 0x1C, 0x2C]:
                # mountain tiles
                dest[d] = b
                d += 1
                s += 3
                continue

            # determine the repeated run length
            run = 1
            while (s + run) < 256 and b == src_row[s + run] and run < 64:
                run += 1

            if run > 1:
                # run can be compressed with rle
                dest[d] = 0xC0 + run - 1
                dest[d + 1] = b
                d += 2
                s += run
            else:
                # raw byte can't be compressed
                dest[d] = b
                d += 1
                s += 1

        row_bytes.append(dest[:d])

    return row_bytes

def decode_world(src):

    s = 0  # source pointer

    # destination buffer
    dest = bytearray(0x10000 * 5)
    d = 0

    while s < len(src):
        b = src[s]
        s += 1

        if b >= 0xC0:
            # rle encoded
            run = b - 0xBF
            b = src[s]
            s += 1
            dest[d:d + run] = [b] * run
            d += run
        elif b in [0x0C, 0x1C, 0x2C]:
            # mountain tiles
            dest[d] = b
            dest[d + 1] = b + 1
            dest[d + 2] = b + 2
            d += 3
        else:
            # raw byte
            dest[d] = b
            d += 1

    return dest


def decode_battle_bg_tiles(src):

    s = 0  # source pointer

    # destination buffer
    dest = bytearray(0x0280)
    d = 0

    while d < 0x0280:
        b = src[s]
        s += 1
        if b != 0xFF:
            dest[d] = b
            d += 1
            continue

        control = src[s]
        tile1 = src[s + 1]
        tile2 = src[s + 2]
        s += 3

        if control & 0x80:
            # alternating tiles
            for i in range(control & 0x3F):
                dest[d] = tile1
                dest[d + 1] = tile2
                d += 2
        elif control & 0x40:
            # tile run with constant decrement
            for i in range(control & 0x3F):
                dest[d] = tile1
                d += 1
                tile1 -= tile2
        else:
            # tile run with constant increment
            for i in range(control & 0x3F):
                dest[d] = tile1
                d += 1
                tile1 += tile2

    # move the palette bit to the correct bit and set bit 7 of the tile index
    dest16 = np.empty(0x0280, dtype=np.uint16)
    for i in range(0x0280):
        tile = dest[i]
        pal = (tile & 0x80) << 3
        tile &= 0x7F
        dest16[i] = tile | pal | 0x80

    return dest16.tobytes()


def encode_battle_bg_tiles(src):
    src16 = np.frombuffer(src, dtype=np.uint16)
    src8 = bytearray(0x0280)
    for i in range(0x0280):
        tile = src16[i]
        pal = (tile >> 3) & 0x80
        tile &= 0x7F
        src8[i] = tile | pal

    s = 0

    dest = bytearray(0x0280)
    d = 0

    while s < 0x0280:

        if s == 0x027F:
            dest[d] = t1
            d += 1
            break

        t1 = src8[s]
        t2 = src8[s + 1]

        # check for alternating tiles
        alt_run = 2
        while s + alt_run < 0x027F and src8[s + alt_run] == t1 and src8[s + alt_run + 1] == t2:
            alt_run += 2
        alt_run = min(alt_run, 0x7E)

        # check for repeating inc/dec
        delta_run = 2
        delta = t2 - t1
        while s + delta_run < 0x0280 and src8[s + delta_run - 1] + delta == src8[s + delta_run]:
            delta_run += 1
        delta_run = min(delta_run, 0x3F)

        if delta_run >= alt_run and delta_run > 4:
            # repeating inc/dec
            dest[d] = 0xFF
            dest[d + 2] = t1
            if delta >= 0:
                dest[d + 1] = delta_run
                dest[d + 3] = delta
            else:
                dest[d + 1] = delta_run | 0x40
                dest[d + 3] = -delta
            d += 4
            s += delta_run

        elif alt_run > 4:
            # alternating tiles
            dest[d] = 0xFF
            dest[d + 1] = (alt_run // 2) | 0x80
            dest[d + 2] = t1
            dest[d + 3] = t2
            d += 4
            s += alt_run

        else:
            dest[d] = t1
            d += 1
            s += 1

    return dest[:d]


def decode_battle_bg_flip(src):

    s = 0  # source pointer

    # destination buffer
    dest = bytearray(0x0280)
    d = 0

    while d < 0x0280:
        b = src[s]
        s += 1

        if b == 0:
            # repeat zero
            d += src[s] * 8
            s += 1
            continue

        # copy 8 bits
        for _ in range(8):
            if b & 0x80:
                dest[d] = 1
            b <<= 1
            d += 1

    return dest


def encode_battle_bg_flip(src):

    s = 0

    dest = bytearray(0x50)
    d = 0

    run = 0
    while s < 0x0280:
        b = 0
        # get the next 8 bits
        for _ in range(8):
            b <<= 1
            if src[s] != 0:
                b |= 1
            s += 1

        if b == 0:
            run += 1
            continue

        if run != 0:
            # encode sequential zeros
            dest[d] = 0
            dest[d + 1] = run
            d += 2
            run = 0
        dest[d] = b
        d += 1

    if run != 0:
        # fill in leftover run of zeros
        dest[d] = 0
        dest[d + 1] = run
        d += 2

    return dest[:d]


if __name__ == '__main__':
    src_path = sys.argv[1]

    try:
        mode = sys.argv[2]
    except IndexError:
        # use lzss by default
        mode = 'lzss'

    if mode == 'multi':
        encode_fn = encode_multi
        dest_path = src_path + '.cmp'
    elif mode == 'rle8':
        encode_fn = encode_rle8
        dest_path = src_path + '.rle8'
    elif mode == 'rle16':
        encode_fn = encode_rle16
        dest_path = src_path + '.rle16'
    elif mode == 'lzss':
        encode_fn = encode_lzss
        dest_path = src_path + '.lz'
    else:
        raise ValueError('Invalid compressions mode: ' + mode)

    with open(src_path, 'rb') as f:
        src_bytes = bytearray(f.read())

    with open(dest_path, 'wb') as f:
        f.write(encode_fn(src_bytes))
