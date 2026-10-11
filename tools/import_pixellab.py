#!/usr/bin/env python3
"""Rebuild the local Godot character manifest from PixelLab character ZIP exports.
No generation, authentication or image processing is performed here.
"""
import json
import pathlib
import struct
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/pixellab'


def dimensions(path):
    return struct.unpack('>II', path.read_bytes()[16:24])


def main():
    manifest = {'version': 1, 'characters': {}}
    for name in ['edward', 'alphonse']:
        folder = ASSETS / name
        metadata = json.loads((folder / 'metadata.json').read_text())['states'][0]
        animations = {'idle': {direction: [path] for direction, path in metadata['frames']['rotations'].items()}}
        animations.update(metadata['frames']['animations'])
        entry = {'pixellab_id': metadata['character']['id'], 'scale': 1.0 if name == 'edward' else 1.08, 'animations': {}}
        for animation, views in animations.items():
            clips = {}
            for direction, paths in views.items():
                width, height = dimensions(folder / paths[0])
                # Template exports share a 64px canvas and the same foot anchor as rotations.
                clips[direction] = {'frames': ['res://assets/pixellab/' + name + '/' + p for p in paths],
                                    'anchor': [width / 2, height - 4], 'fps': 10}
                if animation != 'idle':
                    # Upright template frames sometimes drift vertically within
                    # their canvas. Keep their visible foot baseline on the ground.
                    anchors = []
                    for path in paths:
                        with Image.open(folder / path) as image:
                            bounds = image.convert('RGBA').getchannel('A').getbbox()
                        anchors.append([width / 2, bounds[3] - 1 if bounds else height - 4])
                    clips[direction]['frame_anchors'] = anchors
            entry['animations'][animation] = clips
        # Exact animations crafted using PixelLab's free workbench can live alongside AI exports.
        custom = folder / 'crafted.json'
        if custom.exists():
            entry['animations'].update(json.loads(custom.read_text()))
        manifest['characters'][name.title()] = entry
    (ASSETS / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    print('PIXELLAB_MANIFEST', {n: list(e['animations']) for n, e in manifest['characters'].items()})


if __name__ == '__main__':
    main()
