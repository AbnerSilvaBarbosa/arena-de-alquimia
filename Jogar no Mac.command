#!/bin/zsh
set -eu
game_root="${0:A:h}"
game_godot="${GODOT_BIN:-$HOME/Downloads/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$game_godot" ]]; then
  game_godot="/Applications/Godot.app/Contents/MacOS/Godot"
fi
exec "$game_godot" --path "$game_root" "$@"
