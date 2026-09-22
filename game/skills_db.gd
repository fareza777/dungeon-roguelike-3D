class_name SkillsDb
# Database skill aktif. Terbuka berdasarkan level run. Cooldown per skill.

const DB := {
	"dash": {
		"name": "Terjang Bayangan", "short": "DASH", "cd": 5.0, "unlock": 1,
		"desc": "Menyundul cepat ke depan, kebal sebentar.",
	},
	"whirl": {
		"name": "Putaran Badai", "short": "PUTAR", "cd": 9.0, "unlock": 3,
		"desc": "Tebasan 360 derajat: 2x ATK ke semua musuh sekitar.",
	},
	"thunder": {
		"name": "Guntur Pembalasan", "short": "PETIR", "cd": 14.0, "unlock": 5,
		"desc": "Petir menyambar 3 musuh terdekat: 3x ATK + stun.",
	},
}

const ORDER := ["dash", "whirl", "thunder"]


static func get_s(id: String) -> Dictionary:
	return DB[id]


static func is_unlocked(id: String, level: int) -> bool:
	return level >= int(DB[id]["unlock"])
