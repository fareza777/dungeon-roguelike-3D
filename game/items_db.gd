# Database relic/item. Menambah item baru = menambah entri di DB. Titik.
# mods: {"atk": +1} flat, {"atk_pct": 0.15} persen. rarity: 0 common, 1 rare, 2 epic.

const DB := {
	# ---- common ----
	"tulang_tajam": {"name": "Tulang Tajam", "chip": "TJ", "desc": "+1 ATK", "rarity": 0, "mods": {"atk": 1.0}},
	"darah_segar": {"name": "Darah Segar", "chip": "DS", "desc": "+2 HP Maks", "rarity": 0, "mods": {"max_hp": 2.0}},
	"kulit_keras": {"name": "Kulit Keras", "chip": "KK", "desc": "+1 Armor", "rarity": 0, "mods": {"armor": 1.0}},
	"langkah_ringan": {"name": "Langkah Ringan", "chip": "LR", "desc": "+12% Kecepatan", "rarity": 0, "mods": {"speed_pct": 0.12}},
	"mata_elang": {"name": "Mata Elang", "chip": "ME", "desc": "+8% Crit", "rarity": 0, "mods": {"crit": 0.08}},
	"tangan_cepat": {"name": "Tangan Cepat", "chip": "TC", "desc": "+15% Kecepatan Serang", "rarity": 0, "mods": {"atk_speed_pct": 0.15}},
	"jimat_palu": {"name": "Jimat Palu", "chip": "JP", "desc": "+15% ATK", "rarity": 0, "mods": {"atk_pct": 0.15}},
	"kantong_nyawa": {"name": "Kantong Nyawa", "chip": "KN", "desc": "+25% HP Maks", "rarity": 0, "mods": {"max_hp_pct": 0.25}},
	# ---- rare ----
	"pedang_berkarat": {"name": "Pedang Berkarat", "chip": "PB", "desc": "+2 ATK", "rarity": 1, "mods": {"atk": 2.0}},
	"pengisap_darah": {"name": "Pengisap Darah", "chip": "PD", "desc": "+5% Lifesteal", "rarity": 1, "mods": {"lifesteal": 0.05}},
	"otot_baja": {"name": "Otot Baja", "chip": "OB", "desc": "+20% ATK, +10% Kecepatan", "rarity": 1, "mods": {"atk_pct": 0.2, "speed_pct": 0.1}},
	"jantung_badak": {"name": "Jantung Badak", "chip": "JB", "desc": "+4 HP Maks", "rarity": 1, "mods": {"max_hp": 4.0}},
	"refleks_kucing": {"name": "Refleks Kucing", "chip": "RC", "desc": "+25% Kecepatan Serang", "rarity": 1, "mods": {"atk_speed_pct": 0.25}},
	"sisik_naga": {"name": "Sisik Naga", "chip": "SN", "desc": "+1 Armor, +15% HP Maks", "rarity": 1, "mods": {"armor": 1.0, "max_hp_pct": 0.15}},
	# ---- epic ----
	"amarah_dewa": {"name": "Amarah Dewa", "chip": "AD", "desc": "+50% ATK", "rarity": 2, "mods": {"atk_pct": 0.5}},
	"raja_kritis": {"name": "Raja Kritis", "chip": "RT", "desc": "+25% Crit", "rarity": 2, "mods": {"crit": 0.25}},
	"hidup_abadi": {"name": "Hidup Abadi", "chip": "HA", "desc": "+50% HP Maks, +5% Lifesteal", "rarity": 2, "mods": {"max_hp_pct": 0.5, "lifesteal": 0.05}},
	"angin_topan": {"name": "Angin Topan", "chip": "AT", "desc": "+30% Kecepatan Serang, +15% Kecepatan", "rarity": 2, "mods": {"atk_speed_pct": 0.3, "speed_pct": 0.15}},
	"tulang_naga": {"name": "Tulang Naga", "chip": "TN", "desc": "+3 ATK, +2 HP Maks", "rarity": 2, "mods": {"atk": 3.0, "max_hp": 2.0}},
	# ---- fallback berulang ----
	"berkat_pandai_besi": {"name": "Berkat Pandai Besi", "chip": "B+", "desc": "+1 ATK", "rarity": 0, "repeat": true, "mods": {"atk": 1.0}},
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
