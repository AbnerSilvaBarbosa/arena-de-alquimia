#!/usr/bin/env python3
"""Prepare PixelLab removal of a detached orange marker in a template export.

Reads pixels to identify the isolated marker; all actual image changes and
rendering are done by PixelLab's workbench. Requires Pillow only for analysis.
"""
import argparse
import base64
import json
import pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]


def marker_regions(path):
    image = Image.open(path).convert('RGBA')
    points = {(x, y) for y in range(image.height) for x in range(image.width)
              if image.getpixel((x, y))[3]}
    components = []
    while points:
        stack, component = [points.pop()], []
        while stack:
            x, y = stack.pop()
            component.append((x, y))
            for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                neighbour = x + dx, y + dy
                if neighbour in points:
                    points.remove(neighbour)
                    stack.append(neighbour)
        components.append(component)
    regions = []
    for component in components:
        warm = sum(image.getpixel(p)[0] - image.getpixel(p)[2] > 40 for p in component)
        # The fireball template's detached marker is always 52 opaque pixels.
        if len(component) != 52 or warm < 40:
            continue
        for y in sorted({p[1] for p in component}):
            row = [p[0] for p in component if p[1] == y]
            regions.append([min(row), y, max(row), y])
    return regions


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('character', choices=['edward', 'alphonse'])
    parser.add_argument('--output', type=pathlib.Path, required=True)
    args = parser.parse_args()
    folder = ROOT / 'assets/pixellab' / args.character
    paths = json.loads((folder / 'metadata.json').read_text())['states'][0]['frames']['animations']['cast']
    sources, views, targets = {}, {}, {}
    for direction, frames in paths.items():
        for index, relative in enumerate(frames):
            path = folder / relative
            regions = marker_regions(path)
            if not regions:
                continue
            name = direction + '-frame-' + str(index)
            sources[name] = 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()
            views[name] = {'selections': {'marker': {'regions': regions}, 'body': {}},
                           'nodes': {'body': {'layer': 'body', 'at': [0, 0],
                                              'draw': [{'op': 'copy', 'part': 'body'}]}}}
            targets[name] = str(path.relative_to(ROOT))
    if not views:
        print('NO_DETACHED_MARKERS', args.character)
        return
    recipe = {'job': {'canvas': [64, 64], 'frame_count': 1,
                     'source_bookends_exact': False, 'body_palette_exact': True,
                     'views': [{'id': name, 'offset': [0, 0]} for name in views]},
              'scene': {'layers': [{'id': 'body', 'name': 'Body - clean casting pose'}], 'views': views}}
    args.output.mkdir(parents=True, exist_ok=True)
    spec = {'name': 'pixelart_workbench', 'arguments': {
        'argv': ['draw', '--recipe', json.dumps(recipe), '--sources', json.dumps(sources)], 'mode': 'low'}}
    (args.output / (args.character + '-cast-cleanup.json')).write_text(json.dumps(spec))
    (args.output / (args.character + '-cast-cleanup-targets.json')).write_text(json.dumps(targets, indent=2))
    print('CAST_CLEANUP_PREPARED', args.character, len(views), 'frames')


if __name__ == '__main__':
    main()
