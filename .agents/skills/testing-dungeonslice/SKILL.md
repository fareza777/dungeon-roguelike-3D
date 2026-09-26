---
name: testing-dungeonslice
description: How to launch, drive, and E2E-test the DungeonSlice Godot game headlessly on this VM (launch cmd, input, save, autotest, pitfalls)
---

# Testing DungeonSlice (Godot 4.7.2 Android roguelike) on this VM

## Launch
```bash
cd /home/ubuntu/repos/dungeon-roguelike-3D
DISPLAY=:0 tools/godot/Godot_v4.7.2-stable_linux.x86_64 --path game --resolution 540x1200
```
- Renderer is llvmpipe software → ~5 FPS is NORMAL, not a bug. Real time still ticks normally: enemies act during your tool latency (~1-3s/action), so real-time combat is nearly unplayable interactively — expect deaths while clicking. Use `--autotest` for combat/floor-loop evidence.
- Two concurrent instances spawn two windows — kill old PIDs before relaunching or clicks land in the wrong window.

## Input mapping (computer tool → game coordinates)
Game window 540x1200 sits inside the 1024x768 tool space; empirically:
`tool_x = 339 + 0.64*game_x`, `tool_y = 18 + 0.64*game_y`
- LANJUT/MULAI/menu buttons ≈ tool (512, 685/750…); Lewati ">" ≈ (645, 41)
- ATK button ≈ tool (608, 697); DASH ≈ (608, 497); skill rows below it
- WASD keys move the player (hold_key with text="w"); mouse-drag on left-bottom = virtual joystick
- left_mouse_down/up have NO coordinate param — mouse_move first.

## Save / fresh-run state
`user://save.json` = `~/.local/share/godot/app_userdata/DungeonSlice/save.json`
- Delete/move aside → boot shows onboarding (3 slides) + cinematic (4 panels) once.
- Fields: onboarded, seen_cinematic, run{} (non-empty → LANJUTKAN button appears, label shows run.floor), best_floor, total_kills, boss_kills, quality, volumes.
- A crafted save with `run:{"floor":2,...}` + onboarded/seen_cinematic=true is the quickest way to verify LANJUTKAN→floor-N restore.

## Scripted autotest (markers + screenshots)
```bash
DISPLAY=:0 tools/godot/Godot_v4.7.2-stable_linux.x86_64 --path game --resolution 540x1200 -- --autotest --seed=7
```
Runs ~3-4 min, prints markers (ROOM/COLLISION/ATK_ANIM/GATE*/PICKUP/DRAFT/RELIK/GATES/GEMS/FASE1/FLOOR2/SKILL*/EQUIP/DEATH/RETRY/BOSS*/SHRINE/SAVE/AUTOTEST V5 DONE) and writes `game/out_*.png` (shell_onboarding/cinematic/menu/settings, v4_spawn/attack/weapon/draft/cleared/skills/hero/died, v5_9_boss, v5_10_slam, v5_11_bossdown). Check for `SCRIPT ERROR`/`Failed` lines. SFX markers report `playing=false` because the VM has no audio device (dummy driver) — environmental, not a bug.

## Godot-UI pitfalls seen in this codebase (check siblings when editing)
- Controls added under a CanvasLayer during the parent's `_ready` can end up with `size=(0,0)` if `set_anchors_preset(FULL_RECT)` is called inside the child's own `_ready` — the anchor layout may never resolve. Verify `control.size` after add; set size explicitly or use `set_anchors_and_offsets_preset` deferred if it happens.
- A full-rect ColorRect/Container with MOUSE_FILTER_STOP added *after* a dialog will both hide it and eat every click (later children draw/steal first). Order matters in `_build_ui`.
- Children of a "tap anywhere" root (bg rects, PanelContainers) with default STOP filter swallow taps before the parent's `gui_input` — taps only reach the parent's exposed rect. Make non-interactive children MOUSE_FILTER_IGNORE.
- Emoji: system font renders ⚑/☠ but 🗡 shows as a missing-glyph box on Linux.
- Container subclasses (PanelContainer/VBox/HBox/CenterContainer) default to MOUSE_FILTER_IGNORE already — explicit IGNORE on them is a no-op. The real tap-swallowers are leaf Controls (Label, RichTextLabel, TextureRect, ColorRect, Button) which default STOP.

## Level navigation (room-lock arena flow)
- Rooms stack vertically, contiguous, ONE door in each room's north wall (random column). Wall-mounted torches always flank the door (door_i±1) — follow the torch to find the exit.
- On entering a room with live enemies: "Ruangan terkunci" toast + portcullis gates slam (behind AND ahead). Kill all room enemies → "Ruangan bersih — gerbang terbuka!". `_room_at(z)` is z-only (x-blind) — trigger is crossing the room's z-band by ~0.3 tile.
- Enemies steer straight at the player via move_and_slide (no navmesh) — they slide along walls but can't find far gaps; they only ACTIVATE when you enter their room, so walls of enemies you see while locked-out just idle-wander.
- Gate portcullis is dark bars that SINK when open (open doorway = bare arch); a solid RED double-door prop is a different decoration, not a gate.
- Stdout prints `RUANGAN <i> TERKUNCI (musuh=n)` + `ENEMY DIED arch=…` — redirect the game log (`>/tmp/ds.log 2>&1`) to track room/lock/kill state live during interactive runs.
- Interactive floor-clear at ~5fps is near-impossible legit (enemies act during tool click latency). For evidence runs patch temporarily, e.g. in `_new_run`: `Stats.buff_atk_pct=20.0` (one-shot), `Stats.base["lifesteal"]=0.5`, and/or an early `return` at the top of `player.gd take_hit` (god-mode — armor can't fully block, damage is clamped min 1). ALWAYS revert + verify `git diff` clean after.

## Useful paths
- Repo: `/home/ubuntu/repos/dungeon-roguelike-3D` (game code in `game/`, e.g. `main.gd`, `dialogue.gd`, `stats.gd`, `app/menu.gd`)
- Artifacts collected: `/home/ubuntu/test_artifacts/`; tool screenshots land in `/home/ubuntu/screenshots/`
- No xclip/xsel installed → clipboard readback unavailable; verify share via toast instead.
