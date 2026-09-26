#!/bin/bash
# Generate v5 audio: 2 music tracks + 8 SFX via ElevenLabs.
set -u
OUT="/home/ubuntu/repos/dungeon-roguelike-3D/game/assets/audio"
mkdir -p "$OUT/music" "$OUT/sfx"
HDR=( -H "xi-api-key: ${ELEVENLABS_API_KEY}" -H "Content-Type: application/json" )

mus() { # name prompt
  local f="$OUT/music/$1.mp3"
  [ -s "$f" ] && { echo "MUSIC $1 skip"; return; }
  curl -sf -X POST "https://api.elevenlabs.io/v1/music" "${HDR[@]}" \
    -d "{\"prompt\": \"$2\", \"music_length_ms\": 32000}" -o "$f" \
    && echo "MUSIC $1 OK $(stat -c%s "$f")" || echo "MUSIC $1 FAIL"
  sleep 1
}

sfx() { # name prompt secs
  local f="$OUT/sfx/$1.mp3"
  [ -s "$f" ] && { echo "SFX $1 skip"; return; }
  curl -sf -X POST "https://api.elevenlabs.io/v1/sound-generation" "${HDR[@]}" \
    -d "{\"text\": \"$2\", \"duration_seconds\": $3, \"prompt_influence\": 0.7}" -o "$f" \
    && echo "SFX $1 OK $(stat -c%s "$f")" || echo "SFX $1 FAIL"
  sleep 1
}

mus menu "epic dark fantasy main menu theme, solemn strings, low choir pad, medieval lute arpeggio, melancholic and heroic, seamless ambient loop"
mus boss "intense boss battle theme, heavy war drums, aggressive staccato strings, dark epic orchestral, fast paced, menacing brass"

sfx quest "short quest completed fanfare chime, bright golden ding, triumphant mini jingle" 1.5
sfx page "paper page turning swish, soft parchment rustle" 0.8
sfx shrine "holy blessing aura swell, angelic shimmer, gentle choir chord" 2.5
sfx trap "sharp metallic spike trap mechanism snap, fast clank" 0.6
sfx roar "deep monstrous bone king roar, echoing dungeon reverb, terrifying" 2.5
sfx victory "short triumphant victory fanfare, brass and drums, heroic" 3.0
sfx combo "rising magical combo whoosh ding, quick energetic" 0.5
sfx mimic "sneaky creature growl with wooden creak, surprise monster reveal" 1.5

echo "AUDIO V5 DONE"
ls -la "$OUT/music" "$OUT/sfx" | tail -20
