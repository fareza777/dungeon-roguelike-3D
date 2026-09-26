import re
p = "game/main.gd"
s = open(p).read()
assert "wicklight" not in s
T = "\t"
# 1. var
s = s.replace("var gilded_drift := false\n", "var gilded_drift := false\nvar wicklight := false\n", 1)
# 2. revert (in floor-start reset)
s = s.replace(T+"if gilded_drift:\n"+T+T+"Stats.soul_gain_pct -= 0.12\n"+T+T+"gilded_drift = false\n",
	T+"if gilded_drift:\n"+T+T+"Stats.soul_gain_pct -= 0.12\n"+T+T+"gilded_drift = false\n"
	+T+"if wicklight:\n"+T+T+"Stats.buff_lifesteal -= 0.08\n"+T+T+"wicklight = false\n", 1)
# 3. roll + apply (end of chain, before "storm_t = 4.0")
old_roll = "gilded_drift = not blood_moon"
i = s.find(old_roll)
j = s.find("\n", i)
gilded_roll_line = s[i:j]
assert "rng.randf()" in gilded_roll_line
wick_roll = gilded_roll_line.replace("gilded_drift = ", "wicklight = ").replace("and Stats.floor_num >= 6", "and not gilded_drift and Stats.floor_num >= 7")
s = s.replace(gilded_roll_line + "\n" + T+"if gilded_drift:\n"+T+T+"Stats.soul_gain_pct += 0.12\n"+T+T+"Stats.event_soul_bonus = 1\n",
	gilded_roll_line + "\n" + T+"if gilded_drift:\n"+T+T+"Stats.soul_gain_pct += 0.12\n"+T+T+"Stats.event_soul_bonus = 1\n"
	+wick_roll+"\n"+T+"if wicklight:\n"+T+T+"Stats.buff_lifesteal += 0.08\n"+T+T+"Stats.event_soul_bonus = 1\n", 1)
# 4. enemy spawn effect
s = s.replace(T+"if gilded_drift:\n"+T+T+"e.dmg += 1\n",
	T+"if gilded_drift:\n"+T+T+"e.dmg += 1\n"+T+"if wicklight:\n"+T+T+"e.speed *= 1.10\n", 1)
# 5. env tint elif
s = s.replace(T+"elif gilded_drift:\n"+T+T+"env.fog_light_color = Color(0.6, 0.55, 0.35)\n"+T+T+"env.ambient_light_color = Color(0.65, 0.58, 0.4)\n"+T+T+"sun.light_energy = 1.0\n",
	T+"elif gilded_drift:\n"+T+T+"env.fog_light_color = Color(0.6, 0.55, 0.35)\n"+T+T+"env.ambient_light_color = Color(0.65, 0.58, 0.4)\n"+T+T+"sun.light_energy = 1.0\n"
	+T+"elif wicklight:\n"+T+T+"env.fog_light_color = Color(0.65, 0.5, 0.3)\n"+T+T+"env.ambient_light_color = Color(0.7, 0.55, 0.35)\n"+T+T+"sun.light_energy = 0.95\n", 1)
# 6. banner + toast elif
s = s.replace(T+"elif gilded_drift:\n"+T+T+'_lvl_banner("≋ GILDED DRIFT — THE CURRENT CARRIES COIN")\n'+T+T+'toast("Souls ride the current +12% • but the dead strike +1 harder • the floor tithes +1 soul")\n'+T+T+'Sfx.play("souls")\n',
	T+"elif gilded_drift:\n"+T+T+'_lvl_banner("≋ GILDED DRIFT — THE CURRENT CARRIES COIN")\n'+T+T+'toast("Souls ride the current +12% • but the dead strike +1 harder • the floor tithes +1 soul")\n'+T+T+'Sfx.play("souls")\n'
	+T+"elif wicklight:\n"+T+T+'_lvl_banner("✚ WICKLIGHT — THE WICK BURNS FOR YOU")\n'+T+T+'toast("Your blade drinks +8% of the hurt it deals • but the dead race +10% faster • the floor tithes +1 soul")\n'+T+T+'Sfx.play("souls")\n', 1)
# 7. tithe elif
s = s.replace(T+T+T+"elif gilded_drift:\n"+T+T+T+T+"Stats.earn_souls(1)\n"+T+T+T+T+"_souls_l()\n"+T+T+T+T+"Stats.save_game()\n"+T+T+T+T+'toast("≋ GILDED DRIFT TITHE — +1 soul")\n',
	T+T+T+"elif gilded_drift:\n"+T+T+T+T+"Stats.earn_souls(1)\n"+T+T+T+T+"_souls_l()\n"+T+T+T+T+"Stats.save_game()\n"+T+T+T+T+'toast("≋ GILDED DRIFT TITHE — +1 soul")\n'
	+T+T+T+"elif wicklight:\n"+T+T+T+T+"Stats.earn_souls(1)\n"+T+T+T+T+"_souls_l()\n"+T+T+T+T+"Stats.save_game()\n"+T+T+T+T+'toast("✚ WICKLIGHT TITHE — +1 soul")\n', 1)
# 8. HUD chip elif
s = s.replace(T+"elif gilded_drift:\n"+T+T+'list.append(["≋ DRIFT", Color(0.9, 0.75, 0.35)])\n',
	T+"elif gilded_drift:\n"+T+T+'list.append(["≋ DRIFT", Color(0.9, 0.75, 0.35)])\n'
	+T+"elif wicklight:\n"+T+T+'list.append(["✚ WICK", Color(1.0, 0.75, 0.3)])\n', 1)
# 9. evf list
s = s.replace(', "gilded_drift"]', ', "gilded_drift", "wicklight"]', 1)
open(p, "w").write(s)
print("hits:", s.count("wicklight"))
