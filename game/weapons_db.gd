# Database senjata. Mesh dipasang ke node handslot.r milik rig KayKit.
# tint = pewarna ulang mesh yang sama -> banyak varian dari sedikit aset.

const DIR := "res://assets/weapons/"

const DB := {
	"rusty_blade": {"name": "Pedang Tulang", "gltf": "Skeleton_Blade.gltf", "tint": Color(1, 1, 1), "mods": {}, "desc": "Senjata awal prajurit."},
	"bone_axe": {"name": "Kapak Tulang", "gltf": "Skeleton_Axe.gltf", "tint": Color(1, 1, 1), "mods": {"atk": 2.0, "atk_speed_pct": -0.1}, "desc": "+2 ATK, -10% Kecepatan Serang"},
	"twin_fang": {"name": "Taring Kembar", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.8, 1.0, 1.1), "mods": {"atk_speed_pct": 0.3}, "desc": "+30% Kecepatan Serang"},
	"hex_staff": {"name": "Tongkat Hex", "gltf": "Skeleton_Staff.gltf", "tint": Color(1.0, 0.85, 1.1), "mods": {"atk": 1.0, "crit": 0.2}, "desc": "+1 ATK, +20% Crit"},
	"war_blade": {"name": "Pedang Perang", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.15, 0.6, 0.55), "mods": {"atk": 3.0}, "desc": "+3 ATK"},
	"storm_axe": {"name": "Kapak Badai", "gltf": "Skeleton_Axe.gltf", "tint": Color(0.7, 0.85, 1.2), "mods": {"atk": 1.0, "speed_pct": 0.15}, "desc": "+1 ATK, +15% Kecepatan"},
}

const POOL := ["bone_axe", "twin_fang", "hex_staff", "war_blade", "storm_axe"]


static func get_w(id: String) -> Dictionary:
	return DB.get(id, DB["rusty_blade"])


static func roll_drop(rng: RandomNumberGenerator, current_id: String) -> String:
	var pool: Array = []
	for id in POOL:
		if id != current_id:
			pool.append(id)
	return pool[rng.randi_range(0, pool.size() - 1)]
