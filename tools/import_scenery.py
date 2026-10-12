#!/usr/bin/env python3
"""Install the user's downloaded packs locally; do not alter or upload their artwork."""
import argparse
from pathlib import Path
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ('pixel_16_woods v2 free/free_pixel_16_woods.png', 'woods/free_pixel_16_woods.png', (352, 192)),
    ('2D HD Character Knight/Spritesheets/With shadows/Idle.png', 'ambient/knight-idle.png', (1920, 1024)),
    ('Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A/Demon_A_Idle.png', 'ambient/demon-idle.png', (600, 100)),
    ('Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Blood Monster_A/Blood Monster_A/Blood Monster_A_Idle.png', 'ambient/blood-idle.png', (600, 100)),
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--games-dir', type=Path, required=True)
    args = parser.parse_args()
    pending = []
    for relative, target, expected in FILES:
        source = args.games_dir / relative
        header = source.read_bytes()[:24]
        if header[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', header[16:24]) != expected:
            raise ValueError(f'Unexpected PNG sheet: {source}')
        pending.append((source, ROOT / 'assets/third_party' / target))
    for source, target in pending:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        print(target.relative_to(ROOT))
    print('Local installation complete. Godot imports the original PNGs on opening the project.')

if __name__ == '__main__':
    main()
