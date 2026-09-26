import re
p = "game/main.gd"
s = open(p).read()
assert "starfall_vigil" not in s
T = "\t"
# 1. var
s = s.replace("var wicklight := false\n", "var wicklight := false\nvar starfall_vigil := false\n", 1)
# 2. revert (in floor-start reset)
s = s.replace(T+"if wicklight:\n"+T+T+"Stats.buff_lifesteal -= 0.08\n"+T+T+"wicklight = false\n",
	T+"if wicklight:\n"+T+T+"Stats.buff_lifesteal -= 0.08\n"+T+T+"wicklight = false\n"
	+T+"if starfall_vigil:\n"+T+T+"Stats.buff_xp_pct -= 0.15\n"+T+T+"starfall_vigil = false\n", 1)
# 3. roll + apply (end of chain — after wicklight's roll line)
old_roll = "wicklight = not blood_moon"
i = s.find(old_roll)
j = s.find("\n", i)
wick_roll_line = s[i:j]
assert "rng.randf()" in wick_roll_line
star_roll = wick_roll_line.replace("wicklight = ", "starfall_vigil = ").replace("and Stats.floor_num >= 7", "and not wicklight and Stats.floor_num >= 8")
s = s.replace(wick_roll_line + "\n" + T+"if wicklight:\n"+T+T+"Stats.buff_lifesteal += 0.08\n"+T+T+"Stats.event_soul_bonus = 1\n",
	wick_roll_line + "\n" + T+"if wicklight:\n"+T+T+"Stats.buff_lifesteal += 0.08\n"+T+T+"Stats.event_soul_bonus = 1\n"
	+star_roll+"\n"+T+"if starfall_vigil:\n"+T+T+"Stats.buff_xp_pct += 0.15\n"+T+T+"Stats.event_soul_bonus = 1\n", 1)
# 4. enemy spawn effect
s = s.replace(T+"if wicklight:\n"+T+T+"e.speed *= 1.10\n",
	T+"if wicklight:\n"+T+T+"e.speed *= 1.10\n"+T+"if starfall_vigil:\n"+T+T+"e.hp = int(ceilf(e.hp * 1.12))\n", 1)
# 5. env tint elif
s = s.replace(T+"elif wicklight:\n"+T+T+"env.fog_light_color = Color(0.65, 0.5, 0.3)\n"+T+T+"env.ambient_light_color = Color(0.7, 0.55, 0.35)\n"+T+T+"sun.light_energy = 0.95\n",
	T+"elif wicklight:\n"+T+T+"env.fog_light_color = Color(0.65, 0.5, 0.3)\n"+T+T+"env.ambient_light_color = Color(0.7, 0.55, 0.35)\n"+T+T+"sun.light_energy = 0.95\n"
	+T+"elif starfall_vigil:\n"+T+T+"env.fog_light_color = Color(0.5, 0.45, 0.75)\n"+T+T+"env.ambient_light_color = Color(0.55, 0.5, 0.8)\n"+T+T+"sun.light_energy = 0.9\n", 1)
# 6. banner + toast elif
s = s.replace(T+"elif wicklight:\n"+T+T+'_lvl_banner("✚ WICKLIGHT — THE WICK BURNS FOR YOU")\n'+T+T+'toast("Your blade drinks +8% of the hurt it deals • but the dead race +10% faster • the floor tithes +1 soul")\n'+T+T+'Sfx.play("souls")\n',
	T+"elif wicklight:\n"+T+T+'_lvl_banner("✚ WICKLIGHT — THE WICK BURNS FOR YOU")\n'+T+T+'toast("Your blade drinks +8% of the hurt it deals • but the dead race +10% faster • the floor tithes +1 soul")\n'+T+T+'Sfx.play("souls")\n'
	+T+"elif starfall_vigil:\n"+T+T+'_lvl_banner("☆ STARFALL VIGIL — THE SKY PAYS ITS DEBT")\n'+T+T+'toast("Experience falls like stars +15% • but the dead stand +12% tougher • the floor tithes +1 soul")\n'+T+T+'Sfx.play("souls")\n', 1)
# 7. tithe elif
s = s.replace(T+T+T+"elif wicklight:\n"+T+T+T+T+"Stats.earn_souls(1)\n"+T+T+T+T+"_souls_l()\n"+T+T+T+T+"Stats.save_game()\n"+T+T+T+T+'toast("✚ WICKLIGHT TITHE — +1 soul")\n',
	T+T+T+"elif wicklight:\n"+T+T+T+T+"Stats.earn_souls(1)\n"+T+T+T+T+"_souls_l()\n"+T+T+T+T+"Stats.save_game()\n"+T+T+T+T+'toast("✚ WICKLIGHT TITHE — +1 soul")\n'
	+T+T+T+"elif starfall_vigil:\n"+T+T+T+T+"Stats.earn_souls(1)\n"+T+T+T+T+"_souls_l()\n"+T+T+T+T+"Stats.save_game()\n"+T+T+T+T+'toast("☆ STARFALL TITHE — +1 soul")\n', 1)
# 8. HUD chip elif
s = s.replace(T+"elif wicklight:\n"+T+T+'list.append(["✚ WICK", Color(1.0, 0.75, 0.3)])\n',
	T+"elif wicklight:\n"+T+T+'list.append(["✚ WICK", Color(1.0, 0.75, 0.3)])\n'
	+T+"elif starfall_vigil:\n"+T+T+'list.append(["☆ VIGIL", Color(0.7, 0.6, 1.0)])\n', 1)
# 9. evf list
s = s.replace(', "gilded_drift", "wicklight"]', ', "gilded_drift", "wicklight", "starfall_vigil"]', 1)
open(p, "w").write(s)
print("hits:", s.count("starfall_vigil"))
