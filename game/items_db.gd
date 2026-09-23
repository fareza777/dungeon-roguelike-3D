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
	"debu_nisan": {"name": "Grave Dust", "chip": "GD", "desc": "+10% XP", "rarity": 0, "mods": {"xp_pct": 0.1}},
	# ---- rare ----
	"pedang_berkarat": {"name": "Rusty Sword", "chip": "RS", "desc": "+2 ATK", "rarity": 1, "mods": {"atk": 2.0}},
	"pengisap_darah": {"name": "Blood Leech", "chip": "BL", "desc": "+5% Lifesteal", "rarity": 1, "mods": {"lifesteal": 0.05}},
	"otot_baja": {"name": "Steel Muscle", "chip": "SM", "desc": "+20% ATK, +10% Speed", "rarity": 1, "mods": {"atk_pct": 0.2, "speed_pct": 0.1}},
	"jantung_badak": {"name": "Rhino Heart", "chip": "RH", "desc": "+4 Max HP", "rarity": 1, "mods": {"max_hp": 4.0}},
	"refleks_kucing": {"name": "Cat Reflexes", "chip": "CR", "desc": "+25% Attack Speed", "rarity": 1, "mods": {"atk_speed_pct": 0.25}},
	"sisik_naga": {"name": "Dragon Scale", "chip": "DS", "desc": "+1 Armor, +15% Max HP", "rarity": 1, "mods": {"armor": 1.0, "max_hp_pct": 0.15}},
	"duri_pantulan": {"name": "Reflector Spikes", "chip": "TP", "desc": "Reflect 30% dmg to attacker", "rarity": 1, "mods": {"thorns": 0.3}},
	"fase_hantu": {"name": "Ghost Phase", "chip": "GP", "desc": "12% chance to dodge hits", "rarity": 1, "mods": {"dodge": 0.12}},
	"tulang_rapuh": {"name": "Glass Bones", "chip": "GB", "desc": "+40% ATK, -1 Armor", "rarity": 1, "mods": {"atk_pct": 0.4, "armor": -1.0}},
	"akar_dunia": {"name": "World Root", "chip": "WR", "desc": "+30% Max HP, -10% Speed", "rarity": 1, "mods": {"max_hp_pct": 0.3, "speed_pct": -0.1}},
	"serpihan_mahkota": {"name": "Crown Shard", "chip": "CS", "desc": "+1 soul per kill", "rarity": 1, "mods": {"soul_bonus": 1}},
	"cap_ember": {"name": "Ember Brand", "chip": "EB", "desc": "Attacks scorch: 12% burn", "rarity": 1, "mods": {"burn_proc": 0.12}},
	"buku_hitam": {"name": "Black Grimoire", "chip": "BG", "desc": "+30% XP", "rarity": 1, "mods": {"xp_pct": 0.3}},
	"tangan_tukang": {"name": "Smith's Hand", "chip": "SH", "desc": "Forge your weapon +1 instantly", "rarity": 1, "mods": {}},
	"tulang_gema": {"name": "Echo Bone", "chip": "EO", "desc": "Skills recharge 18% faster", "rarity": 1, "mods": {"cd_red": 0.18}},
	"persembahan_kubur": {"name": "Grave Tithe", "chip": "GT", "desc": "+1 Armor, -10% Speed", "rarity": 0, "mods": {"armor": 1.0, "speed_pct": -0.1}},
	"langkah_seribu": {"name": "Thousand Steps", "chip": "TS", "desc": "+20% Speed, -1 Armor", "rarity": 1, "mods": {"speed_pct": 0.2, "armor": -1.0}},
	# ---- epic ----
	"amarah_dewa": {"name": "Wrath of God", "chip": "WG", "desc": "+50% ATK", "rarity": 2, "mods": {"atk_pct": 0.5}},
	"raja_kritis": {"name": "Crit King", "chip": "CK", "desc": "+25% Crit", "rarity": 2, "mods": {"crit": 0.25}},
	"hidup_abadi": {"name": "Immortal", "chip": "IM", "desc": "+50% Max HP, +5% Lifesteal", "rarity": 2, "mods": {"max_hp_pct": 0.5, "lifesteal": 0.05}},
	"angin_topan": {"name": "Cyclone", "chip": "CY", "desc": "+30% Attack Speed, +15% Speed", "rarity": 2, "mods": {"atk_speed_pct": 0.3, "speed_pct": 0.15}},
	"tulang_naga": {"name": "Dragon Bone", "chip": "DB", "desc": "+3 ATK, +2 Max HP", "rarity": 2, "mods": {"atk": 3.0, "max_hp": 2.0}},
	"jiwa_bangkit": {"name": "Soul Risen", "chip": "SR", "desc": "Revive 1x (50% HP)", "rarity": 2, "mods": {"revive": 1}},
	"amukan": {"name": "Berserk", "chip": "BK", "desc": "+35% ATK under 35% HP", "rarity": 2, "mods": {"berserk": 0.35}},
	"darah_raja": {"name": "King's Blood", "chip": "KB", "desc": "+10% ATK, +2 Max HP, +5% Lifesteal", "rarity": 2, "mods": {"atk_pct": 0.1, "max_hp": 2.0, "lifesteal": 0.05}},
	"tulang_kesatria": {"name": "Bone Squire", "chip": "SQ", "desc": "A loyal squire fights beside you", "rarity": 2, "mods": {"squire": 1}},
	"beban_raja": {"name": "King's Burden", "chip": "KU", "desc": "+40% ATK, -20% Max HP", "rarity": 2, "mods": {"atk_pct": 0.4, "max_hp_pct": -0.2}},
	"mata_cyclops": {"name": "Cyclops Eye", "chip": "CE", "desc": "+40% Crit, -10% ATK", "rarity": 2, "mods": {"crit": 0.4, "atk_pct": -0.1}},
	"piala_darah": {"name": "Sanguine Chalice", "chip": "SC", "desc": "+20% Lifesteal", "rarity": 2, "mods": {"lifesteal": 0.2}},
	"mahkota_darah": {"name": "Bloodied Crown", "chip": "BC", "desc": "+1 soul per kill, -20% Max HP", "rarity": 2, "mods": {"soul_bonus": 1, "max_hp_pct": -0.2}},
	"liontin_dendam": {"name": "Avenger's Charm", "chip": "AV", "desc": "+25% ATK while your nemesis lives", "rarity": 2, "mods": {}},
	"kunci_osuarium": {"name": "Ossuary Key", "chip": "OK", "desc": "Every chest you find is GILDED", "rarity": 2, "mods": {}},
	"taring_neraka": {"name": "Hellfang Spikes", "chip": "HF", "desc": "Reflect 60% dmg to attacker", "rarity": 2, "mods": {"thorns": 0.6}},
	"mata_perenungan": {"name": "Watcher's Eye", "chip": "WE", "desc": "Dwellers reveal at double range — the dark knows it", "rarity": 2, "mods": {}},
	"lensa_jiwa": {"name": "Soul Lens", "chip": "SL", "desc": "Wandering wisps drift to you", "rarity": 2, "mods": {}},
	"stoples_bara": {"name": "Wispfire Jar", "chip": "WJ", "desc": "Wisps caught also grant +3 XP", "rarity": 1, "mods": {}},
	"relik_tempo": {"name": "Relic of Tempo", "chip": "RT", "desc": "Your combo window lasts 45% longer", "rarity": 1, "mods": {}},
	"soulsmith": {"name": "Soulsmith Band", "chip": "SS", "desc": "Soul Forge prices drop 2 souls", "rarity": 1, "mods": {}},
	"leech_seed": {"name": "Leech Seed", "chip": "LS", "desc": "Every 6th kill at full HP ripens into +1 soul", "rarity": 0, "mods": {}},
	"chalice_dust": {"name": "Chalice of Dust", "chip": "CD", "desc": "+2 souls from every kill", "rarity": 2, "mods": {"soul_bonus": 2}},
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
