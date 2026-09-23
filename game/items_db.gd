# Database relic/item. Menambah item baru = menambah entri di DB. Titik.
# mods: {"atk": +1} flat, {"atk_pct": 0.15} persen. rarity: 0 common, 1 rare, 2 epic.

const DB := {
	# ---- common ----
	"tulang_tajam": {"name": "Sharp Bone", "chip": "SB", "desc": "+1 ATK", "rarity": 0, "mods": {"atk": 1.0}},
	"darah_segar": {"name": "Fresh Blood", "chip": "FB", "desc": "+2 Max HP", "rarity": 0, "mods": {"max_hp": 2.0}},
	"kulit_keras": {"name": "Hard Skin", "chip": "HS", "desc": "+1 Armor", "rarity": 0, "mods": {"armor": 1.0}},
	"langkah_ringan": {"name": "Light Step", "chip": "LS", "desc": "+12% Speed", "rarity": 0, "mods": {"speed_pct": 0.12}},
	"mata_elang": {"name": "Eagle Eye", "chip": "EE", "desc": "+8% Crit", "rarity": 0, "mods": {"crit": 0.08}},
	"tangan_cepat": {"name": "Quick Hands", "chip": "QH", "desc": "+15% Attack Speed", "rarity": 0, "mods": {"atk_speed_pct": 0.15}},
	"jimat_palu": {"name": "Hammer Charm", "chip": "HC", "desc": "+15% ATK", "rarity": 0, "mods": {"atk_pct": 0.15}},
	"kantong_nyawa": {"name": "Life Pouch", "chip": "LP", "desc": "+25% Max HP", "rarity": 0, "mods": {"max_hp_pct": 0.25}},
	"magnet_jiwa": {"name": "Soul Magnet", "chip": "MG", "desc": "+60% pickup range", "rarity": 0, "mods": {"magnet": 0.6}},
	# ---- rare ----
	"pedang_berkarat": {"name": "Rusty Sword", "chip": "RS", "desc": "+2 ATK", "rarity": 1, "mods": {"atk": 2.0}},
	"pengisap_darah": {"name": "Blood Leech", "chip": "BL", "desc": "+5% Lifesteal", "rarity": 1, "mods": {"lifesteal": 0.05}},
	"otot_baja": {"name": "Steel Muscle", "chip": "SM", "desc": "+20% ATK, +10% Speed", "rarity": 1, "mods": {"atk_pct": 0.2, "speed_pct": 0.1}},
	"jantung_badak": {"name": "Rhino Heart", "chip": "RH", "desc": "+4 Max HP", "rarity": 1, "mods": {"max_hp": 4.0}},
	"refleks_kucing": {"name": "Cat Reflexes", "chip": "CR", "desc": "+25% Attack Speed", "rarity": 1, "mods": {"atk_speed_pct": 0.25}},
	"sisik_naga": {"name": "Dragon Scale", "chip": "DS", "desc": "+1 Armor, +15% Max HP", "rarity": 1, "mods": {"armor": 1.0, "max_hp_pct": 0.15}},
	"duri_pantulan": {"name": "Reflector Spikes", "chip": "TP", "desc": "Reflect 30% dmg to attacker", "rarity": 1, "mods": {"thorns": 0.3}},
	"fase_hantu": {"name": "Ghost Phase", "chip": "GP", "desc": "12% chance to dodge hits", "rarity": 1, "mods": {"dodge": 0.12}},
	# ---- epic ----
	"amarah_dewa": {"name": "Wrath of God", "chip": "WG", "desc": "+50% ATK", "rarity": 2, "mods": {"atk_pct": 0.5}},
	"raja_kritis": {"name": "Crit King", "chip": "CK", "desc": "+25% Crit", "rarity": 2, "mods": {"crit": 0.25}},
	"hidup_abadi": {"name": "Immortal", "chip": "IM", "desc": "+50% Max HP, +5% Lifesteal", "rarity": 2, "mods": {"max_hp_pct": 0.5, "lifesteal": 0.05}},
	"angin_topan": {"name": "Cyclone", "chip": "CY", "desc": "+30% Attack Speed, +15% Speed", "rarity": 2, "mods": {"atk_speed_pct": 0.3, "speed_pct": 0.15}},
	"tulang_naga": {"name": "Dragon Bone", "chip": "DB", "desc": "+3 ATK, +2 Max HP", "rarity": 2, "mods": {"atk": 3.0, "max_hp": 2.0}},
	"jiwa_bangkit": {"name": "Soul Risen", "chip": "SR", "desc": "Revive 1x (50% HP)", "rarity": 2, "mods": {"revive": 1}},
	"amukan": {"name": "Berserk", "chip": "BK", "desc": "+35% ATK under 35% HP", "rarity": 2, "mods": {"berserk": 0.35}},
	# ---- fallback berulang ----
	"berkat_pandai_besi": {"name": "Smith's Blessing", "chip": "SM+", "desc": "+1 ATK", "rarity": 0, "repeat": true, "mods": {"atk": 1.0}},
}

const RARITY_COLORS := [Color(0.85, 0.85, 0.9), Color(0.4, 0.7, 1.0), Color(1.0, 0.6, 0.15)]


static func roll_choices(owned: Array, rng: RandomNumberGenerator, n := 3) -> Array:
	var out: Array = []
	var guard := 0
	while out.size() < n and guard < 40:
		guard += 1
		var r := rng.randi_range(0, 99)
		var rarity := 0
		if r >= 90:
			rarity = 2
		elif r >= 60:
			rarity = 1
		var pool: Array = []
		for id in DB:
			var it: Dictionary = DB[id]
			if int(it["rarity"]) != rarity:
				continue
			if owned.has(id) and not it.get("repeat", false):
				continue
			if out.has(id):
				continue
			pool.append(id)
		if pool.is_empty():
			continue
		out.append(pool[rng.randi_range(0, pool.size() - 1)])
	while out.size() < n:
		out.append("berkat_pandai_besi")
	return out
