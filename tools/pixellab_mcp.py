#!/usr/bin/env python3
"""Small MCP HTTP client. Credentials are read from the environment, never saved.
Usage: PIXELLAB_AUTH_HEADER='Bearer …' python3 tools/pixellab_mcp.py get_balance '{}'
"""
import argparse
import json
import os
import pathlib
import urllib.error
import urllib.request

ENDPOINT = 'https://api.pixellab.ai/mcp'


def rpc(method, params):
    auth = os.environ.get('PIXELLAB_AUTH_HEADER', '')
    if not auth:
        raise RuntimeError('Defina PIXELLAB_AUTH_HEADER no ambiente; não salve a chave no projeto.')
    payload = {'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}
    request = urllib.request.Request(ENDPOINT, data=json.dumps(payload).encode(), headers={
        'Authorization': auth, 'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream'})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read().decode()
    except urllib.error.HTTPError as error:
        raise RuntimeError('PixelLab HTTP %s' % error.code) from None
    if body.lstrip().startswith('{'):
        message = json.loads(body)
    else:
        messages = [json.loads(line[6:]) for line in body.splitlines() if line.startswith('data: ')]
        message = next((item for item in messages if item.get('id') == 1), {})
    if 'error' in message:
        raise RuntimeError(str(message['error']))
    return message.get('result', {})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('tool')
    parser.add_argument('arguments', nargs='?', default='{}')
    parser.add_argument('--output', type=pathlib.Path)
    args = parser.parse_args()
    result = rpc('tools/call', {'name': args.tool, 'arguments': json.loads(args.arguments)})
    if args.output:
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2))
    for item in result.get('content', []):
        if item.get('type') == 'text':
            print(item['text'])
    if result.get('isError'):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
