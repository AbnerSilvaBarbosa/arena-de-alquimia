#!/usr/bin/env python3
"""Export clients/server and package reproducible source, excluding local secrets/cache."""
import argparse
import os
import pathlib
import subprocess
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD = ROOT / 'builds'


def package(target, files):
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for source, name in files:
            archive.write(source, name)
    print(target.name, target.stat().st_size, 'bytes')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--package-only', action='store_true')
    args = parser.parse_args()
    BUILD.mkdir(exist_ok=True)
    if not args.package_only:
        for preset in ['Windows', 'Linux Server']:
            subprocess.run([args.godot, '--headless', '--path', str(ROOT), '--export-release', preset], check=True)
    font_license = [(ROOT / 'assets/fonts/OFL.txt', 'licenses/OFL-Silkscreen.txt')]
    package(BUILD / 'Arena-Windows-0.1.zip', [(BUILD / 'windows/Arena.exe', 'Arena.exe'), (ROOT / 'README.md', 'README.md')] + font_license)
    package(BUILD / 'Arena-Server-Linux-0.1.zip', [(BUILD / 'linux/arena-server', 'arena-server')] +
            [(ROOT / 'server' / name, name) for name in ['arena.service', 'README.md', 'HERMES.md']] + font_license)
    sources = []
    for name in ['project.godot', 'main.tscn', 'export_presets.cfg', '.gitignore', 'Jogar no Mac.command']:
        sources.append((ROOT / name, name))
    sources.extend((path, path.name) for path in ROOT.glob('*.md'))
    design_record = ROOT / '.impeccable/design.json'
    if design_record.exists():
        sources.append((design_record, '.impeccable/design.json'))
    allowed = {'.gd', '.uid', '.png', '.json', '.md', '.py', '.service', '.wav', '.tres', '.ttf', '.txt'}
    for folder in ['scripts', 'assets', 'server', 'tests', 'tools']:
        for path in (ROOT / folder).rglob('*'):
            if path.is_file() and path.suffix in allowed and '__pycache__' not in path.parts:
                sources.append((path, str(path.relative_to(ROOT))))
    package(BUILD / 'Arena-Source-0.1.zip', sources)


if __name__ == '__main__':
    main()
