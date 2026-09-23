# Database senjata. Mesh dipasang ke node handslot.r milik rig KayKit.
# tint = pewarna ulang mesh yang sama -> banyak varian dari sedikit aset.

const DIR := "res://assets/weapons/"

const DB := {
	"rusty_blade": {"name": "Bone Sword", "gltf": "Skeleton_Blade.gltf", "tint": Color(1, 1, 1), "mods": {}, "desc": "A warrior's first blade."},
	"bone_axe": {"name": "Bone Axe", "gltf": "Skeleton_Axe.gltf", "tint": Color(1, 1, 1), "mods": {"atk": 2.0, "atk_speed_pct": -0.1}, "desc": "+2 ATK, -10% AS. CLEAVE: hits splash to nearby foes."},
	"twin_fang": {"name": "Twin Fang", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.8, 1.0, 1.1), "mods": {"atk_speed_pct": 0.3}, "desc": "+30% AS. FLURRY: 25% to strike twice."},
	"hex_staff": {"name": "Hex Staff", "gltf": "Skeleton_Staff.gltf", "tint": Color(1.0, 0.85, 1.1), "mods": {"atk": 1.0, "crit": 0.2}, "desc": "+1 ATK, +20% Crit. HEX: marked foes take +25% dmg."},
	"war_blade": {"name": "War Blade", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.15, 0.6, 0.55), "mods": {"atk": 3.0}, "desc": "+3 ATK. EXECUTIONER: +50% vs weakened foes."},
	"storm_axe": {"name": "Storm Axe", "gltf": "Skeleton_Axe.gltf", "tint": Color(0.7, 0.85, 1.2), "mods": {"atk": 1.0, "speed_pct": 0.15}, "desc": "+1 ATK, +15% Spd. STORM: 20% lightning chain."},
	"frost_fang": {"name": "Frost Fang", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.65, 0.9, 1.25), "mods": {"crit": 0.15, "speed_pct": 0.1}, "desc": "+15% Crit, +10% Spd. FROST: chills foes 50% for 3s."},
	"ember_mace": {"name": "Ember Mace", "gltf": "Skeleton_Staff.gltf", "tint": Color(1.35, 0.7, 0.45), "mods": {"atk": 2.0, "lifesteal": 0.08, "atk_speed_pct": -0.05}, "desc": "+2 ATK, +8% LS, -5% AS. BURN: sets foes alight."},
	"kings_edge": {"name": "King's Edge", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.25, 1.1, 0.55), "mods": {"atk": 4.0, "crit": 0.1, "speed_pct": -0.08}, "desc": "+4 ATK, +10% Crit, -8% Spd. KING'S WRATH: every 5th hit blasts."},
	"grave_scythe": {"name": "Grave Scythe", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.6, 0.4, 0.95), "mods": {"atk": 2.0, "crit": 0.05}, "desc": "+2 ATK, +5% Crit. REAPER: slain foes return 1 HP."},
	"gaoler_brand": {"name": "Gaoler's Brand", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.55, 0.4, 1.15), "mods": {"atk": 2.2}, "desc": "+2.2 ATK. WARDEN: 12% chance to cage a foe where it stands."},
	"moon_katana": {"name": "Moonlit Katana", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.7, 0.85, 1.35), "mods": {"atk": 2.5, "atk_speed_pct": 0.1}, "desc": "+2.5 ATK, +10% AS. RIPOSTE: after a perfect dodge, the next strike deals double."},
}

const POOL := ["bone_axe", "twin_fang", "hex_staff", "war_blade", "storm_axe", "frost_fang", "ember_mace", "kings_edge", "grave_scythe", "moon_katana"]


static func get_w(id: String) -> Dictionary:
	return DB.get(id, DB["rusty_blade"])


static func roll_drop(rng: RandomNumberGenerator, current_id: String) -> String:
	# 30%: duplikat senjata sendiri -> di-forge jadi +1 ATK saat diambil
	if rng.randf() < 0.3:
		return current_id
	var pool: Array = []
	for id in POOL:
		if id != current_id:
			pool.append(id)
	return pool[rng.randi_range(0, pool.size() - 1)]
