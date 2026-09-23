# Database arketipe musuh. Musuh "baru" = entri baru di sini (atau varian elite
# dari entri yang sudah ada). Nilai spd/reach/aggro dikali ukuran tile saat spawn.

const DB := {
	"chaser": {"glb": "Skeleton_Minion.glb", "hp": 3.0, "spd": 0.95, "dmg": 1, "windup": 0.45, "reach": 0.6, "aggro": 2.6, "xp": 1, "tint": Color(1.0, 0.92, 0.85), "scale": 1.0, "kb_resist": 0.0},
	"rogue": {"glb": "Skeleton_Rogue.glb", "hp": 2.0, "spd": 1.4, "dmg": 1, "windup": 0.28, "reach": 0.65, "aggro": 3.2, "xp": 1, "tint": Color(0.95, 0.95, 1.05), "scale": 0.95, "dash": true, "kb_resist": 0.0},
	"mage": {"glb": "Skeleton_Mage.glb", "hp": 2.0, "spd": 0.7, "dmg": 1, "windup": 0.7, "reach": 2.6, "prefer": 2.4, "aggro": 3.6, "xp": 2, "tint": Color(0.9, 0.95, 1.1), "scale": 1.0, "ranged": true, "proj_speed": 3.0, "kb_resist": 0.0},
	"brute": {"glb": "Skeleton_Warrior.glb", "hp": 9.0, "spd": 0.55, "dmg": 2, "windup": 0.8, "reach": 0.75, "aggro": 2.4, "xp": 3, "tint": Color(1.05, 0.9, 0.85), "scale": 1.25, "kb_resist": 0.7},
	# baru v5: pengebom bunuh diri — lari ke player, meledak (juga luka musuh lain)
	"bomber": {"glb": "Skeleton_Minion.glb", "hp": 1.5, "spd": 1.55, "dmg": 2, "windup": 0.7, "reach": 0.55, "aggro": 4.5, "xp": 2, "tint": Color(1.25, 0.7, 0.4), "scale": 0.9, "bomber": true, "kb_resist": 0.0},
	# baru v5: pemanah — ranged cepat, proyektil tipis tapi sering
	"archer": {"glb": "Skeleton_Rogue.glb", "hp": 1.5, "spd": 0.95, "dmg": 1, "windup": 0.55, "reach": 3.2, "prefer": 2.8, "aggro": 4.0, "xp": 2, "tint": Color(0.75, 1.0, 0.9), "scale": 0.95, "ranged": true, "proj_speed": 4.5, "kb_resist": 0.0},
	# BOSS: Raja Tulang — tiap lantai kelipatan 5
	"bone_king": {"glb": "Skeleton_Warrior.glb", "hp": 42.0, "spd": 0.8, "dmg": 2, "windup": 0.85, "reach": 0.95, "aggro": 9.9, "xp": 15, "tint": Color(1.15, 0.45, 0.4), "scale": 1.85, "kb_resist": 0.9, "boss": true},
}

const ELITE := {"hp_mult": 2.5, "dmg_add": 1, "xp_mult": 3, "scale_mult": 1.28, "spd_mult": 1.1, "tint": Color(1.2, 0.42, 0.38)}


static func get_arch(id: String) -> Dictionary:
	return DB.get(id, DB["chaser"])
