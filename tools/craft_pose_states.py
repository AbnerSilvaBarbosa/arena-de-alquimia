#!/usr/bin/env python3
"""Prepare PixelLab workbench requests from completed, locally exported poses.

This does not modify images. PixelLab cuts, articulates and renders the PNGs.
The tiny input sprites are embedded as data URLs; no credential is included.
"""
import argparse
import base64
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
DIRECTIONS = ['south', 'east', 'north', 'west']


def track(node, prop, keys):
    return {'node': node, 'property': prop, 'interpolation': 'step', 'keys': keys}


def make_request(character, state):
    folder = ROOT / 'assets/pixellab' / character
    animations = json.loads((folder / 'metadata.json').read_text())['states'][0]['frames']['animations']
    animation, index = ('attack', 1 if state == 'guard' else 2) if state in ['guard', 'grab'] else ('throw', 2)
    sources, views = {}, {}
    for direction in DIRECTIONS:
        data = (folder / animations[animation][direction][index]).read_bytes()
        sources[direction] = 'data:image/png;base64,' + base64.b64encode(data).decode()
        selections = {'body': {}}
        nodes = {'body': {'layer': 'body', 'at': [0, 0], 'draw': [{'op': 'copy', 'part': 'body'}]}}
        tracks = []
        if state == 'guard':
            tracks.append(track('body', 'at', [[1, [0, 0]], [2, [0, 1]], [3, [0, 0]], [4, [0, 0]]]))
        elif state == 'pickup':
            tracks.append(track('body', 'at', [[1, [0, 3]], [2, [0, 2]], [3, [0, 0]], [4, [0, 0]]]))
        elif state == 'grab':
            dx, dy = {'east': (2, 0), 'west': (-2, 0), 'south': (0, 2), 'north': (0, -2)}[direction]
            tracks.append(track('body', 'at', [[1, [0, 0]], [2, [dx, dy]], [3, [0, 0]], [4, [0, 0]]]))
        elif state == 'carry_walk':
            selections = {'left_leg': {'regions': [[0, 45, 31, 63]]},
                          'right_leg': {'regions': [[32, 45, 63, 63]]}, 'body': {}}
            for leg, pivot, sign in [('left_leg', [26, 45], 1), ('right_leg', [38, 45], -1)]:
                nodes[leg] = {'layer': 'legs', 'at': [0, 0], 'pivot': pivot,
                              'draw': [{'op': 'copy', 'part': leg}]}
                tracks.append(track(leg, 'angle', [[1, 0], [2, 5 * sign], [3, 0], [4, -5 * sign]]))
        views[direction] = {'selections': selections, 'nodes': nodes, 'tracks': tracks}
    durations = [300] * 4 if state in ['guard', 'carry'] else ([40, 40, 40, 60] if state == 'pickup' else [100] * 4)
    recipe = {'job': {'canvas': [64, 72], 'frame_count': 4, 'durations_ms': durations,
                     'views': [{'id': d, 'offset': [0, 0]} for d in DIRECTIONS],
                     'source_bookends_exact': state != 'pickup', 'body_palette_exact': True},
              'scene': {'layers': [{'id': 'body', 'name': 'Body - held pose'},
                                   {'id': 'legs', 'name': 'Body - carrying footwork'}], 'views': views}}
    return {'name': 'pixelart_workbench', 'arguments': {
        'argv': ['draw', '--recipe', json.dumps(recipe), '--sources', json.dumps(sources)], 'mode': 'low'}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('character', choices=['edward', 'alphonse'])
    parser.add_argument('--output', type=pathlib.Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for state in ['guard', 'grab', 'pickup', 'carry', 'carry_walk']:
        path = args.output / (args.character + '-' + state + '-draw.json')
        path.write_text(json.dumps(make_request(args.character, state)))
        print(path.name)


if __name__ == '__main__':
    main()
