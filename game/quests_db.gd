class_name QuestsDb
# Rantai quest per lantai — urutan jelas, satu aktif dalam satu waktu.
# kind: "moved", "kill", "clear_floor", "reach_room", "boss_kill",
#       "open_chest", "descend", "custom"
# need: jumlah untuk kind berhitung (kill/reach_room); 0/1 utk toggle.

static func is_boss_floor(floor_num: int) -> bool:
	return floor_num % 5 == 0


static func for_floor(floor_num: int, room_count: int, n_elites: int = 0) -> Array:
	var steps: Array = []
	if floor_num == 1:
		steps.append({"title": "Awaken", "desc": "Move — tilt the left stick", "kind": "moved", "need": 1})
		steps.append({"title": "Sweep", "desc": "Clear %d rooms of skeletons" % room_count, "kind": "clear_floor", "need": room_count})
		steps.append({"title": "First Spoils", "desc": "Open the treasure chest at the floor's end", "kind": "open_chest", "need": 1})
		steps.append({"title": "Descend", "desc": "Tap the screen to descend to Floor 2", "kind": "descend", "need": 1})
	elif is_boss_floor(floor_num):
		steps.append({"title": "Throne Room", "desc": "Fight through to the last room of this floor", "kind": "reach_room", "need": room_count - 1})
		steps.append({"title": "Bone King", "desc": "Defeat the Throne's ruler", "kind": "boss_kill", "need": 1})
		steps.append({"title": "The Crown", "desc": "Claim the King's spoils chest", "kind": "open_chest", "need": 1})
		steps.append({"title": "Descend", "desc": "Tap to descend deeper", "kind": "descend", "need": 1})
	else:
		if floor_num >= 3 and n_elites > 0:
			var n_hunt := mini(n_elites, 2)
			steps.append({"title": "Elite Hunter", "desc": "Slay %d crimson elite%s" % [n_hunt, "s" if n_hunt > 1 else ""], "kind": "elite_kill", "need": n_hunt})
		if floor_num >= 4:
			if floor_num % 2 == 0:
				steps.append({"title": "Gem Rush", "desc": "Absorb 6 soul gems", "kind": "gem", "need": 6})
			else:
				steps.append({"title": "Battle Frenzy", "desc": "Reach a x8 kill combo", "kind": "combo", "need": 1})
		if floor_num >= 6:
			steps.append({"title": "Skillful Hands", "desc": "Unleash 2 skills", "kind": "skill", "need": 2})
		if floor_num >= 7 and floor_num % 3 == 1:
			steps.append({"title": "Ghost Dancer", "desc": "Dash through 2 attacks at the last instant", "kind": "pdodge", "need": 2})
		steps.append({"title": "Floor Sweep", "desc": "Clear %d rooms of skeletons" % room_count, "kind": "clear_floor", "need": room_count})
		steps.append({"title": "Treasure Chest", "desc": "Find & open the chest in the final room", "kind": "open_chest", "need": 1})
		steps.append({"title": "Descend", "desc": "Tap to descend to the next floor", "kind": "descend", "need": 1})
	for i in range(steps.size()):
		steps[i]["num"] = i + 1
		steps[i]["total"] = steps.size()
	return steps
