class_name SkillsDb
# Database skill aktif. Terbuka berdasarkan level run. Cooldown per skill.

const DB := {
	"dash": {
		"name": "Shadow Rush", "short": "DASH", "cd": 5.0, "unlock": 1,
		"desc": "Dash forward, briefly invincible.",
	},
	"whirl": {
		"name": "Whirlwind", "short": "SPIN", "cd": 9.0, "unlock": 3,
		"desc": "360° slash: 2x ATK to all nearby enemies.",
	},
	"thunder": {
		"name": "Vengeful Thunder", "short": "BOLT", "cd": 14.0, "unlock": 5,
		"desc": "Lightning strikes the 3 nearest enemies: 3x ATK + stun.",
	},
	"warcry": {
		"name": "War Cry", "short": "CRY", "cd": 18.0, "unlock": 7,
		"desc": "Roar that knocks enemies back and grants +50% ATK for 5s.",
	},
	"nova": {
		"name": "Soul Nova", "short": "NOVA", "cd": 20.0, "unlock": 9,
		"desc": "Soul blast: 2x ATK to all foes nearby — each kill mends 1 HP.",
	},
	"judge": {
		"name": "Heaven's Judgment", "short": "JUDGE", "cd": 12.0, "unlock": 11,
		"desc": "Smite the nearest foe: 3x ATK — up to 5x against the wounded. A kill pays 2 souls.",
	},
}

const ORDER := ["dash", "whirl", "thunder", "warcry", "nova", "judge"]


static func get_s(id: String) -> Dictionary:
	return DB[id]


static func is_unlocked(id: String, level: int) -> bool:
	return level >= int(DB[id]["unlock"])
