"""Launch a real Godot server and two separate ENet client processes."""
import argparse
import pathlib
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True)
parser.add_argument('--rtt-ms',type=int,default=0)
parser.add_argument('--loss',type=float,default=0)
parser.add_argument('--packed-server')
parser.add_argument('--duel',action='store_true',help='Complete two rounds and confirm rematch over ENet')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
base = [args.godot, '--headless', '--path', str(root)]
port = 17007
processes = []
proxy = None
client_port = port
client_flags = ['--duel'] if args.duel else []
if args.rtt_ms or args.loss:
    from udp_proxy import UDPProxy
    client_port = port + 1
    proxy = UDPProxy(client_port, port, args.rtt_ms, args.loss)
with tempfile.TemporaryDirectory(prefix='arena-network-') as temp:
    code = pathlib.Path(temp) / 'code.txt'
    try:
        server_base = base + (['--main-pack', args.packed_server] if args.packed_server else [])
        server = subprocess.Popen(server_base + ['--', '--server', f'--port={port}'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        processes.append(server)
        time.sleep(0.7)
        creator = subprocess.Popen(base + ['--script', 'tests/network_peer.gd', '--', '--mode=create', f'--code-file={code}', f'--port={client_port}'] + client_flags, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        processes.append(creator)
        deadline = time.monotonic() + 6
        while not code.exists() and time.monotonic() < deadline and creator.poll() is None:
            time.sleep(0.05)
        if not code.exists():
            raise RuntimeError('Creator did not publish a room code')
        joiner = subprocess.Popen(base + ['--script', 'tests/network_peer.gd', '--', '--mode=join', f'--code-file={code}', f'--port={client_port}'] + client_flags, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        processes.append(joiner)
        time.sleep(1.0 if args.rtt_ms else 0.25)
        rejections = []
        for expected in ['full','missing','version']:
            rejection = subprocess.Popen(base + ['--script','tests/network_reject.gd','--',f'--expect={expected}',f'--code-file={code}',f'--port={client_port}'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
            processes.append(rejection)
            rejections.append(rejection)
        for rejection in rejections:
            output, _ = rejection.communicate(timeout=10)
            print(output[-2000:])
            if rejection.returncode != 0 or 'REJECTION_PASS' not in output or 'ERROR:' in output:
                raise RuntimeError('Rejection checks failed')
        failed = False
        for client in [creator, joiner]:
            output, _ = client.communicate(timeout=60 if args.duel else 15)
            print(output[-6000:])
            if client.returncode != 0 or 'NETWORK_PASS' not in output or 'SCRIPT ERROR' in output:
                failed = True
        if failed:
            raise RuntimeError('Network integration test failed')
        print(f'NETWORK_RESULT: two real clients passed; RTT={args.rtt_ms}ms loss={args.loss} duel={args.duel}')
    finally:
        if proxy:
            proxy.close()
        for process in processes:
            if process.poll() is None:
                process.terminate()
                try:
                    output, _ = process.communicate(timeout=3)
                    if output:
                        print(output[-3000:])
                        if 'ERROR:' in output:
                            raise RuntimeError('Server reported runtime errors')
                except subprocess.TimeoutExpired:
                    process.kill()
