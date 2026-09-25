# Database biome: palet warna + kabut + tabel musuh per biome.
# Biome berganti tiap 2 lantai. Biome baru = entri baru + (opsional) aset baru.

const LIST := [
	{
		"name": "Catacombs",
		"floor": Color(0.78, 0.85, 1.08), "wall": Color(0.9, 0.92, 1.06), "prop": Color(1.05, 0.97, 0.9),
		"fog": Color(0.09, 0.08, 0.16), "fog_d": 0.024, "ambient": Color(0.25, 0.28, 0.45),
		"sun": Color(1.0, 0.86, 0.68), "torch": Color(1.0, 0.55, 0.22), "torch_e": 1.4, "torch_r": 7.0,
		"bg": Color(0.04, 0.03, 0.08),
		"enemies": ["chaser", "chaser", "rogue", "archer", "crawler", "crawler"],
	},
	{
		"name": "Ember Crypt",
		"floor": Color(0.88, 0.92, 1.04), "wall": Color(0.9, 0.92, 1.0), "prop": Color(0.95, 0.94, 0.98),
		"fog": Color(0.08, 0.045, 0.035), "fog_d": 0.02, "ambient": Color(0.3, 0.26, 0.28),
		"sun": Color(1.0, 0.82, 0.62), "torch": Color(1.0, 0.5, 0.18), "torch_e": 1.0, "torch_r": 4.2,
		"bg": Color(0.05, 0.03, 0.03),
		"enemies": ["rogue", "chaser", "mage", "bomber", "crawler", "crawler"],
	},
	{
		"name": "Frozen Deep",
		"floor": Color(0.82, 1.0, 1.18), "wall": Color(0.85, 0.95, 1.1), "prop": Color(0.9, 1.0, 1.12),
		"fog": Color(0.06, 0.1, 0.16), "fog_d": 0.02, "ambient": Color(0.25, 0.35, 0.5),
		"sun": Color(0.75, 0.88, 1.0), "torch": Color(0.6, 0.8, 1.0), "torch_e": 1.2, "torch_r": 5.5,
		"bg": Color(0.02, 0.04, 0.07),
		"enemies": ["mage", "rogue", "brute", "archer", "bomber", "necromancer", "crawler", "crawler", "gaoler", "weeper", "sentinel", "maiden", "revenant", "shieldbearer", "herald", "batterer", "duelist", "hound", "hound", "moth", "orator"],
	},
	{
		"name": "Verdant Ruin",
		"floor": Color(0.8, 1.05, 0.8), "wall": Color(0.85, 1.0, 0.85), "prop": Color(0.95, 1.05, 0.85),
		"fog": Color(0.05, 0.12, 0.06), "fog_d": 0.026, "ambient": Color(0.22, 0.4, 0.25),
		"sun": Color(0.85, 1.0, 0.7), "torch": Color(0.7, 1.0, 0.5), "torch_e": 1.2, "torch_r": 5.5,
		"bg": Color(0.02, 0.06, 0.03),
		"enemies": ["brute", "mage", "chaser", "archer", "bomber", "necromancer", "crawler", "crawler", "gaoler", "weeper", "sentinel", "shade", "hexer", "spiker", "lurker", "golem", "maiden", "revenant", "shieldbearer", "herald", "batterer", "duelist", "hound", "hound", "moth", "orator", "crowned", "digger", "saltghast", "waver"],
	},
	{
		"name": "Marrow Marsh",
		"floor": Color(0.7, 0.78, 0.62), "wall": Color(0.78, 0.82, 0.66), "prop": Color(0.85, 0.8, 0.6),
		"fog": Color(0.06, 0.08, 0.04), "fog_d": 0.034, "ambient": Color(0.3, 0.36, 0.22),
		"sun": Color(0.9, 0.95, 0.6), "torch": Color(0.7, 0.95, 0.45), "torch_e": 1.1, "torch_r": 5.0,
		"bg": Color(0.03, 0.05, 0.02),
		"enemies": ["brute", "rogue", "archer", "bomber", "necromancer", "crawler", "crawler", "crawler", "weeper", "sentinel", "hexer", "spiker", "lurker", "maiden", "revenant", "batterer", "duelist", "hound", "hound", "moth", "orator", "digger", "digger"],
	},
	{
		"name": "Sunken Reliquary",
		"floor": Color(0.55, 0.72, 0.72), "wall": Color(0.6, 0.78, 0.78), "prop": Color(0.9, 0.8, 0.5),
		"fog": Color(0.03, 0.1, 0.1), "fog_d": 0.032, "ambient": Color(0.18, 0.34, 0.32),
		"sun": Color(0.6, 0.95, 0.9), "torch": Color(0.95, 0.8, 0.4), "torch_e": 1.3, "torch_r": 5.2,
		"bg": Color(0.02, 0.05, 0.05),
		"enemies": ["brute", "rogue", "archer", "bomber", "necromancer", "crawler", "gaoler", "weeper", "sentinel", "shade", "hexer", "spiker", "lurker", "golem", "maiden", "revenant", "shieldbearer", "herald", "batterer", "duelist", "moth", "orator", "crowned", "crowned", "tither", "tither", "digger", "drowned", "drowned", "keelhound", "keelhound", "maw", "maw", "mireling", "mireling", "keelbeak", "keelbeak", "bilge_witch", "bilge_witch", "rust_jaw", "rust_jaw", "salt_herald", "salt_herald", "hull_widow", "hull_widow", "deck_gunner", "deck_gunner", "lantern_jack", "lantern_jack"],
	},
	{
		"name": "The Abyss",
		"floor": Color(0.7, 0.62, 0.95), "wall": Color(0.75, 0.7, 1.0), "prop": Color(0.8, 0.72, 1.0),
		"fog": Color(0.07, 0.04, 0.12), "fog_d": 0.03, "ambient": Color(0.2, 0.16, 0.38),
		"sun": Color(0.85, 0.7, 1.0), "torch": Color(0.85, 0.5, 1.0), "torch_e": 1.4, "torch_r": 6.0,
		"bg": Color(0.03, 0.02, 0.06),
		"enemies": ["brute", "mage", "rogue", "archer", "bomber", "bomber", "necromancer", "necromancer", "crawler", "crawler", "crawler", "gaoler", "gaoler", "weeper", "sentinel", "shade", "shade", "hexer", "hexer", "spiker", "spiker", "lurker", "lurker", "golem", "golem", "maiden", "maiden", "revenant", "revenant", "shieldbearer", "shieldbearer", "herald", "batterer", "duelist", "hound", "hound", "moth", "orator", "crowned", "crowned", "tither", "digger", "siren", "siren", "gargoyle", "mireling", "mireling", "hull_widow", "lantern_jack", "reef_caller", "chum_gnawer", "chum_gnawer", "rotting_bride", "salt_cantor", "kelter_husk", "deck_brood", "rust_fanatic", "chimehead", "bilge_sprite", "salt_leech", "gutter_chaplain", "bell_warden", "hookfin", "wrack_eel", "rust_saw", "bell_ringer", "salvage_rat", "kelter_fiend", "gallows_rev", "foamcutter", "salt_gibbet", "keel_ghost", "lantern_jaw", "salt_skiff", "deck_wight", "moorling", "keel_mastiff", "foam_wright", "keel_wretch", "bilge_smith", "salt_sprite", "foam_herald", "gunnel_wight", "bilge_rat", "powder_monkey", "fathom_crab", "quarter_ghost", "salt_eel", "deck_brute", "salt_lich", "bilge_fury", "siren_thrall", "pale_lantern", "gunnel_fiend", "bilge_cantor", "tide_bailiff", "salt_skimmer", "brine_monk", "deck_rigger", "dread_gull", "gale_singer", "snatch_widow", "gunnel_gnat", "deck_reverend", "mast_lurcher", "dirge_singer", "the_boatswain", "gloom_lantern", "wick_tender", "sodden_deckhand", "brine_widow", "keelwright", "bilge_tender", "keel_sapper", "keel_chorister", "pitch_tender", "pitch_tender", "keel_wraith", "brood_keel", "brine_hag", "salt_devout", "jeerjack", "salt_gallows", "soul_toller", "keel_scribe", "salt_widow", "keel_leecher", "keel_summoner", "rust_leech", "pale_tither", "mistral_imp", "bilge_prior", "pallbearer", "keel_sexton", "chain_warden", "salt_curate", "keel_verger", "deep_chaplain", "grey_sexton", "deep_widow", "pale_ferryman", "keel_widow", "deep_verger", "salt_carrier", "grey_clerk", "salt_bailiff", "tithe_wright", "pale_auditor", "deep_usher", "grey_bailiff", "debt_collector"],
	},
]


static func for_floor(f: int) -> Dictionary:
	return LIST[clampi((f - 1) / 2, 0, LIST.size() - 1)]
