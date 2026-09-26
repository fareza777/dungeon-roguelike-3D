#!/bin/bash
# v6: 3 trek musik biome via ElevenLabs (ember/frozen/verdant).
set -u
OUT="/home/ubuntu/repos/dungeon-roguelike-3D/game/assets/audio/music"
mkdir -p "$OUT"
HDR=( -H "xi-api-key: ${ELEVENLABS_API_KEY}" -H "Content-Type: application/json" )

mus() { # name prompt
  local f="$OUT/$1.mp3"
  [ -s "$f" ] && { echo "MUSIC $1 skip"; return; }
  curl -sf -X POST "https://api.elevenlabs.io/v1/music" "${HDR[@]}" \
    -d "{\"prompt\": \"$2\", \"music_length_ms\": 32000}" -o "$f" \
    && echo "MUSIC $1 OK $(stat -c%s "$f")" || echo "MUSIC $1 FAIL"
  sleep 1
}

mus ember "dark dungeon music with ember glow, slow war drums, low crackling embers, ominous choir drone, volcanic menace, seamless loop"
mus frozen "cold icy dungeon theme, fragile high strings, distant howling wind, glassy bells, melancholic and freezing, seamless loop"
mus verdant "haunted overgrown ruins theme, eerie wooden flutes, rustling ambience, mystical eastern strings, ancient jungle temple, seamless loop"

echo "AUDIO V6 DONE"
ls -la "$OUT" | tail -8
