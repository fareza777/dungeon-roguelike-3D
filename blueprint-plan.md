# Rencana blueprint environment (repo blueprint — baru)

Repo belum punya blueprint. Usulan isi:

## initialize
- Unduh Godot 4.7.2 Linux x86_64 ke `tools/godot/` (sama seperti sesi ini) + chmod +x. Binary ~50MB, gitignored — harus diunduh tiap snapshot.
- Import asset headless sekali (`--headless --import --path game`) supaya snapshot hangat.

## maintenance
- `--headless --import` lagi (incremental, cepat) — bukan rebuild penuh.

## knowledge
- `autotest`: `DISPLAY=:0 tools/godot/Godot_v4.7.2-stable_linux.x86_64 --path game --resolution 540x1200 -- --autotest --seed=N` → screenshot `game/out_*.png`, cek `SCRIPT ERROR`.
- `import`: `tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --import --path game`
- `notes`: regen aset butuh secret ELEVENLABS_API_KEY / MESHY_API_KEY (`tools/gen_audio_v5.sh`); string game Bahasa Indonesia.
