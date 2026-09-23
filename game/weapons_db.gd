# Database senjata. Mesh dipasang ke node handslot.r milik rig KayKit.
# tint = pewarna ulang mesh yang sama -> banyak varian dari sedikit aset.

const DIR := "res://assets/weapons/"

const DB := {
	"rusty_blade": {"name": "Bone Sword", "gltf": "Skeleton_Blade.gltf", "tint": Color(1, 1, 1), "mods": {}, "desc": "A warrior's first blade."},
	"bone_axe": {"name": "Bone Axe", "gltf": "Skeleton_Axe.gltf", "tint": Color(1, 1, 1), "mods": {"atk": 2.0, "atk_speed_pct": -0.1}, "desc": "+2 ATK, -10% Attack Speed"},
	"twin_fang": {"name": "Twin Fang", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.8, 1.0, 1.1), "mods": {"atk_speed_pct": 0.3}, "desc": "+30% Attack Speed"},
	"hex_staff": {"name": "Hex Staff", "gltf": "Skeleton_Staff.gltf", "tint": Color(1.0, 0.85, 1.1), "mods": {"atk": 1.0, "crit": 0.2}, "desc": "+1 ATK, +20% Crit"},
	"war_blade": {"name": "War Blade", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.15, 0.6, 0.55), "mods": {"atk": 3.0}, "desc": "+3 ATK"},
	"storm_axe": {"name": "Storm Axe", "gltf": "Skeleton_Axe.gltf", "tint": Color(0.7, 0.85, 1.2), "mods": {"atk": 1.0, "speed_pct": 0.15}, "desc": "+1 ATK, +15% Speed"},
	"frost_fang": {"name": "Frost Fang", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.65, 0.9, 1.25), "mods": {"crit": 0.15, "speed_pct": 0.1}, "desc": "+15% Crit, +10% Speed"},
	"ember_mace": {"name": "Ember Mace", "gltf": "Skeleton_Staff.gltf", "tint": Color(1.35, 0.7, 0.45), "mods": {"atk": 2.0, "lifesteal": 0.08, "atk_speed_pct": -0.05}, "desc": "+2 ATK, +8% Lifesteal, -5% Attack Speed"},
	"kings_edge": {"name": "King's Edge", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.25, 1.1, 0.55), "mods": {"atk": 4.0, "crit": 0.1, "speed_pct": -0.08}, "desc": "+4 ATK, +10% Crit, -8% Speed — relic of a fallen King"},
}

const POOL := ["bone_axe", "twin_fang", "hex_staff", "war_blade", "storm_axe", "frost_fang", "ember_mace", "kings_edge"]


static func get_w(id: String) -> Dictionary:
	return DB.get(id, DB["rusty_blade"])


static func roll_drop(rng: RandomNumberGenerator, current_id: String) -> String:
	var pool: Array = []
	for id in POOL:
		if id != current_id:
			pool.append(id)
	return pool[rng.randi_range(0, pool.size() - 1)]
