import argparse
import pathlib
import subprocess
p=argparse.ArgumentParser()
p.add_argument('--godot',required=True)
args=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
folder=root/'.impeccable/review'
folder.mkdir(parents=True,exist_ok=True)
for mode in ['menu','connect','lobby','options','arena','result']:
    target=folder/f'{mode}.png'
    result=subprocess.run([args.godot,'--path',str(root),'--','--capture='+str(target),'--capture-mode='+mode],cwd=root,capture_output=True,text=True,timeout=45)
    if result.returncode or 'ERROR' in result.stdout+result.stderr or not target.exists():
        raise RuntimeError(mode+'\n'+result.stdout+result.stderr)
    print('CAPTURE_PASS '+mode,flush=True)
