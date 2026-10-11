#!/usr/bin/env python3
"""Prepare free PixelLab workbench recipes; PixelLab renders the actual PNGs."""
import argparse
import json
import pathlib

CHARACTERS = {'edward': 'f89aa2d4-646a-4313-935e-41801f432a7d',
              'alphonse': 'e1ae5b6a-632c-4dd1-a9f9-341fb822f684'}
DIRECTIONS = ['south', 'east', 'north', 'west']


def track(property_name, keys):
    return {'node': 'body', 'property': property_name, 'interpolation': 'step', 'keys': keys}


def recipe(character, state):
    identity = CHARACTERS[character]
    canvas, offset, timings = [96, 96], [16, 20], [40] * 4
    if state == 'hurt':
        canvas, offset, timings = [80, 80], [8, 12], [40, 40, 40, 60]
    elif state == 'ko':
        canvas, offset, timings = [128, 96], [32, 20], [60, 60, 70, 110]
    views = {}
    for direction in DIRECTIONS:
        tracks = []
        if state == 'dash':
            angle = 12 if direction == 'east' else (-12 if direction == 'west' else 0)
            tracks.append(track('angle', [[1, 0], [2, angle], [3, angle], [4, 0]]))
            if direction in ['south', 'north']:
                tracks.append(track('at', [[1, offset], [2, [16, 22]], [3, [16, 22]], [4, offset]]))
        elif state == 'hurt':
            dx = -2 if direction == 'east' else (2 if direction == 'west' else 0)
            dy = 2 if direction == 'north' else (-2 if direction == 'south' else -1)
            tracks.append(track('at', [[1, offset], [2, [8 + dx, 12 + dy]],
                                      [3, [8 - dx // 2, 12 - dy // 2]], [4, offset]]))
        elif state == 'ko':
            tracks.append(track('angle', [[1, 0], [2, 18], [3, 52], [4, 90]]))
        body = {'layer': 'body', 'at': offset, 'pivot': [32, 60], 'draw': [{'op': 'copy', 'part': 'body'}]}
        views[direction] = {'selections': {'body': {}}, 'nodes': {'body': body}, 'tracks': tracks}
    job = {'canvas': canvas, 'frame_count': 4, 'durations_ms': timings,
           'views': [{'id': d, 'offset': offset} for d in DIRECTIONS],
           'source_bookends_exact': True, 'body_palette_exact': True}
    if state != 'ko':
        job['return_to_rest'] = True
    drawing = {'job': job, 'scene': {'layers': [{'id': 'body', 'name': 'Body - ' + state}], 'views': views}}
    sources = {d: 'character:' + identity + ':' + d for d in DIRECTIONS}
    return {'name': 'pixelart_workbench', 'arguments': {
        'argv': ['draw', '--recipe', json.dumps(drawing), '--sources', json.dumps(sources)], 'mode': 'low'}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=pathlib.Path, default=pathlib.Path('assets/pixellab/recipes'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for character in CHARACTERS:
        for state in ['hurt', 'dash', 'ko']:
            (args.output / (character + '-' + state + '-draw.json')).write_text(json.dumps(recipe(character, state), indent=2))


if __name__ == '__main__':
    main()
