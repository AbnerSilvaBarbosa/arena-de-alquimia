#!/usr/bin/env python3
"""Import an existing PixelLab character export without altering its images.

PixelLab locks the ZIP while that character has animation jobs in progress.
This script never generates, retries paid operations or needs an API credential.
"""
import argparse
import io
import pathlib
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
CHARACTERS = {'edward': 'f89aa2d4-646a-4313-935e-41801f432a7d',
              'alphonse': 'e1ae5b6a-632c-4dd1-a9f9-341fb822f684'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('character', choices=CHARACTERS)
    args = parser.parse_args()
    url = 'https://api.pixellab.ai/mcp/characters/' + CHARACTERS[args.character] + '/download'
    with urllib.request.urlopen(url, timeout=60) as response:
        payload = response.read()
    folder = (ROOT / 'assets/pixellab' / args.character).resolve()
    count = 0
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        for entry in archive.infolist():
            target = (folder / entry.filename).resolve()
            if not target.is_relative_to(folder):
                raise RuntimeError('Unsafe ZIP member')
            if entry.is_dir() or target.suffix not in {'.png', '.json'}:
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(entry))
            count += 1
    print('CHARACTER_IMPORTED', args.character, count, 'files')


if __name__ == '__main__':
    main()
