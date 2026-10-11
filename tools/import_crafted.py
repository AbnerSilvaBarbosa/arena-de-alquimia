#!/usr/bin/env python3
"""Download workbench-exported sprite sheets and record their foot anchor.
Images remain exactly as rendered by PixelLab; no local image edits.
"""
import argparse
import json
import pathlib
import struct
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]


def pair(value):
    return [int(v) for v in value.split(',')]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('character', choices=['edward', 'alphonse'])
    parser.add_argument('animation')
    parser.add_argument('drawing_id')
    parser.add_argument('--canvas', required=True, type=pair)
    parser.add_argument('--anchor', required=True, type=pair)
    parser.add_argument('--frames', type=int, default=4)
    parser.add_argument('--fps', type=float, default=10)
    parser.add_argument('--eight-directions', action='store_true')
    args = parser.parse_args()
    directions = ['south', 'east', 'north', 'west']
    if args.eight_directions:
        directions += ['south-east', 'north-east', 'north-west', 'south-west']
    base = 'https://api.pixellab.ai/mcp/pixel-tools/' + args.drawing_id
    folder = ROOT / 'assets/pixellab' / args.character / 'crafted' / args.animation
    folder.mkdir(parents=True, exist_ok=True)
    clips = {}
    for direction in directions:
        with urllib.request.urlopen(base + '/assets/' + direction + '/full.png', timeout=45) as response:
            data = response.read()
        if not data.startswith(b'\x89PNG\r\n\x1a\n'):
            raise RuntimeError('PixelLab returned a non-PNG payload')
        width, height = struct.unpack('>II', data[16:24])
        cw, ch = args.canvas
        if width % cw or height % ch or (width // cw) * (height // ch) < args.frames:
            raise RuntimeError('Sprite sheet dimensions do not match the requested canvas')
        path = folder / (direction + '.png')
        path.write_bytes(data)
        clips[direction] = {'sheet': 'res://' + str(path.relative_to(ROOT)),
                            'frame_size': args.canvas, 'columns': width // cw,
                            'frame_count': args.frames, 'anchor': args.anchor, 'fps': args.fps}
        print('CRAFTED_IMPORT', args.character, args.animation, direction, flush=True)
    with urllib.request.urlopen(base + '/recipe.json', timeout=45) as response:
        folder.joinpath('recipe.json').write_bytes(response.read())
    custom = ROOT / 'assets/pixellab' / args.character / 'crafted.json'
    metadata = json.loads(custom.read_text()) if custom.exists() else {}
    metadata[args.animation] = clips
    custom.write_text(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
