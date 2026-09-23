class_name QuestsDb
# Rantai quest per lantai — urutan jelas, satu aktif dalam satu waktu.
# kind: "moved", "kill", "clear_floor", "reach_room", "boss_kill",
#       "open_chest", "descend", "custom"
# need: jumlah untuk kind berhitung (kill/reach_room); 0/1 utk toggle.

static func is_boss_floor(floor_num: int) -> bool:
	return floor_num % 5 == 0


static func for_floor(floor_num: int, room_count: int) -> Array:
	var steps: Array = []
	if floor_num == 1:
		steps.append({"title": "Bangkit", "desc": "Bergeraklah — goyangkan stik kiri", "kind": "moved", "need": 1})
		steps.append({"title": "Pembersihan", "desc": "Bersihkan %d ruangan dari skeleton" % room_count, "kind": "clear_floor", "need": room_count})
		steps.append({"title": "Rampasan Pertama", "desc": "Buka peti harta di ujung lantai", "kind": "open_chest", "need": 1})
		steps.append({"title": "Turun", "desc": "Ketuk layar untuk turun ke Lantai 2", "kind": "descend", "need": 1})
	elif is_boss_floor(floor_num):
		steps.append({"title": "Ruang Takhta", "desc": "Tembus ke ruangan terakhir lantai ini", "kind": "reach_room", "need": room_count - 1})
		steps.append({"title": "Raja Tulang", "desc": "Kalahkan penguasa takhta", "kind": "boss_kill", "need": 1})
		steps.append({"title": "Mahkota", "desc": "Ambil peti rampasan raja", "kind": "open_chest", "need": 1})
		steps.append({"title": "Turun", "desc": "Ketuk untuk turun lebih dalam", "kind": "descend", "need": 1})
	else:
		steps.append({"title": "Sapu Lantai", "desc": "Bersihkan %d ruangan dari skeleton" % room_count, "kind": "clear_floor", "need": room_count})
		steps.append({"title": "Peti Harta", "desc": "Temukan & buka peti di ruangan akhir", "kind": "open_chest", "need": 1})
		steps.append({"title": "Turun", "desc": "Ketuk untuk turun ke lantai berikutnya", "kind": "descend", "need": 1})
	for i in range(steps.size()):
		steps[i]["num"] = i + 1
		steps[i]["total"] = steps.size()
	return steps
