# Database arketipe musuh. Musuh "baru" = entri baru di sini (atau varian elite
# dari entri yang sudah ada). Nilai spd/reach/aggro dikali ukuran tile saat spawn.

const DB := {
	"chaser": {"glb": "Skeleton_Minion.glb", "hp": 3.0, "spd": 0.95, "dmg": 1, "windup": 0.45, "reach": 0.6, "aggro": 2.6, "xp": 1, "tint": Color(1.0, 0.92, 0.85), "scale": 1.0, "kb_resist": 0.0},
	"rogue": {"glb": "Skeleton_Rogue.glb", "hp": 2.0, "spd": 1.4, "dmg": 1, "windup": 0.28, "reach": 0.65, "aggro": 3.2, "xp": 1, "tint": Color(0.95, 0.95, 1.05), "scale": 0.95, "dash": true, "kb_resist": 0.0},
	"mage": {"glb": "Skeleton_Mage.glb", "hp": 2.0, "spd": 0.7, "dmg": 1, "windup": 0.7, "reach": 2.6, "prefer": 2.4, "aggro": 3.6, "xp": 2, "tint": Color(0.9, 0.95, 1.1), "scale": 1.0, "ranged": true, "proj_speed": 3.0, "kb_resist": 0.0},
	"brute": {"glb": "Skeleton_Warrior.glb", "hp": 9.0, "spd": 0.55, "dmg": 2, "windup": 0.8, "reach": 0.75, "aggro": 2.4, "xp": 3, "tint": Color(1.05, 0.9, 0.85), "scale": 1.25, "kb_resist": 0.7},
}

const ELITE := {"hp_mult": 2.5, "dmg_add": 1, "xp_mult": 3, "scale_mult": 1.28, "spd_mult": 1.1, "tint": Color(1.2, 0.42, 0.38)}


static func get_arch(id: String) -> Dictionary:
	return DB.get(id, DB["chaser"])
