"""Read only selected binaries from the official remote template ZIP using HTTP ranges."""
import io
import pathlib
import urllib.request
import zipfile

URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
SIZE = 1281349702
class RemoteZip(io.RawIOBase):
    def __init__(self):
        self.position = 0
        self.url = URL
        self.cached_start = -1
        self.cached = b''
    def readable(self): return True
    def seekable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else SIZE + offset
        return self.position
    def read(self, length=-1):
        if length < 0: length = SIZE - self.position
        length = min(length, SIZE - self.position)
        if length <= 0: return b''
        start = self.position
        if not (self.cached_start <= start and start + length <= self.cached_start + len(self.cached)):
            end = min(SIZE - 1, start + max(length, 4 * 1024 * 1024) - 1)
            request = urllib.request.Request(self.url, headers={'Range': f'bytes={start}-{end}'})
            with urllib.request.urlopen(request, timeout=60) as response:
                if response.status != 206:
                    raise RuntimeError(f'Remote server ignored Range ({response.status}); stopping to avoid full download')
                self.url = response.geturl()
                self.cached_start = start
                self.cached = response.read()
        data = self.cached[start - self.cached_start:start - self.cached_start + length]
        self.position += len(data)
        return data

folder = pathlib.Path(__file__).resolve().parents[1] / 'builds' / 'templates'
folder.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as archive:
    names = ['windows_release_x86_64.exe', 'linux_release.x86_64', 'version.txt']
    for suffix in names:
        name = next(n for n in archive.namelist() if n.endswith('/' + suffix))
        target = folder / suffix
        print(f'Downloading {name} ({archive.getinfo(name).file_size} bytes)', flush=True)
        with archive.open(name) as source, target.open('wb') as out:
            while data := source.read(1024 * 1024):
                out.write(data)
        if suffix.endswith('x86_64'): target.chmod(0o755)
        print(f'Saved {target.name}', flush=True)
