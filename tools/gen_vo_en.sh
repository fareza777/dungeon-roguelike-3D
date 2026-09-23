#!/bin/bash
# Regenerasi VO cinematic ke English (TTS ElevenLabs, voice yang sama).
set -u
OUT="/home/ubuntu/repos/dungeon-roguelike-3D/game/assets/audio/vo"
mkdir -p "$OUT"
HDR=( -H "xi-api-key: ${ELEVENLABS_API_KEY}" -H "Content-Type: application/json" )
VOICE="pNInz6obpgDQGcFmaJgB"

vo() { # n text
  local f="$OUT/line$1.mp3"
  curl -sf -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE" "${HDR[@]}" \
    -d "{\"text\": \"$2\", \"model_id\": \"eleven_multilingual_v2\", \"voice_settings\": {\"stability\": 0.55, \"similarity_boost\": 0.75}}" -o "$f" \
    && echo "VO $1 OK $(stat -c%s "$f")" || echo "VO $1 FAIL"
  sleep 1
}

vo 1 "In the forgotten depths of the earth, a kingdom of bone has awakened from its slumber."
vo 2 "You are the last warrior who dares descend these stairs."
vo 3 "Every floor grows darker. Every step more dangerous. And at the end, the Bone King waits."
vo 4 "Descend. Survive. And never trust the dark."

echo "VO EN DONE"
ls -la "$OUT"
