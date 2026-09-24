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
	"second_wind": {"name": "Second Wind", "chip": "SW", "desc": "Clearing a floor mends 20% Max HP", "rarity": 1, "mods": {}},
	"echo_strike": {"name": "Echo Strike", "chip": "ES", "desc": "Every 4th hit lands twice", "rarity": 2, "mods": {}},
	"pact_broker": {"name": "Pact Broker", "chip": "PB", "desc": "All soul prices -1", "rarity": 1, "mods": {}},
	"kings_ledger": {"name": "King's Ledger", "chip": "KL", "desc": "Every elite slain pays +2 souls", "rarity": 1, "mods": {}},
	"drowned_oar": {"name": "Drowned Oar", "chip": "DO", "desc": "The Ferryman charges 3 fewer souls", "rarity": 1, "mods": {}},
	"soul_creel": {"name": "Soul Creel", "chip": "SC", "desc": "Wisps pay +1 soul when netted", "rarity": 1, "mods": {}},
	"clamheart": {"name": "Clamheart", "chip": "CH", "desc": "Disarming a trap pays +1 soul", "rarity": 1, "mods": {}},
	"pressure_suit": {"name": "Pressure Suit", "chip": "PS", "desc": "Roots and chills end twice as fast", "rarity": 1, "mods": {}},
	"tidebound_anklet": {"name": "Tidebound Anklet", "chip": "TA", "desc": "Snap Clams can only hold you a moment", "rarity": 1, "mods": {}},
	"keelhook": {"name": "Keelhook", "chip": "KH", "desc": "Every Keelhound you drop spills +2 souls", "rarity": 1, "mods": {}},
	"deaf_cap": {"name": "Deaf Cap", "chip": "DC", "desc": "Waxed ears — no siren's pull can move you", "rarity": 1, "mods": {}},
	"choir_alms": {"name": "Choir Alms", "chip": "CA", "desc": "Entering a Choir Below floor pays +3 souls", "rarity": 1, "mods": {}},
	"trenchfoot": {"name": "Trenchfoot", "chip": "TF", "desc": "Barnacle grip — +12% speed on the drowned floors (11+)", "rarity": 1, "mods": {}},
	"siren_farewell": {"name": "Siren's Farewell", "chip": "SF", "desc": "Every siren you silence refunds +2 souls", "rarity": 1, "mods": {}},
	"shellshield": {"name": "Shell Shield", "chip": "SH", "desc": "The first clam you pry each floor pays +2 extra souls", "rarity": 1, "mods": {}},
	"bone_tithe": {"name": "Bone Tithe", "chip": "BT", "desc": "Disarming a trap grants +1 Armor for the rest of the floor", "rarity": 2, "mods": {}},
	"tide_lock": {"name": "Tide Lock", "chip": "TL", "desc": "Every floor event that rolls pays you +1 soul on arrival", "rarity": 1, "mods": {}},
	"choir_hush": {"name": "Choir's Hush", "chip": "CH", "desc": "Silencing a siren stuns every other foe for 1s", "rarity": 2, "mods": {}},
	"keel_mark": {"name": "Keel Mark", "chip": "KM", "desc": "Foes you keelhaul are marked — each marked kill pays +1 soul", "rarity": 1, "mods": {}},
	"grave_rose": {"name": "Grave Rose", "chip": "GR", "desc": "Your first blow on every foe is always a crit", "rarity": 2, "mods": {}},
	"shellback": {"name": "Shellback", "chip": "SB", "desc": "Standing still for a heartbeat hardens you — 30% less damage taken", "rarity": 1, "mods": {}},
	"pilot_fish": {"name": "Pilot Fish", "chip": "PF", "desc": "It leads you to open water — +8% Speed while you're under half HP", "rarity": 1, "mods": {}},
	"bilge_rat": {"name": "Bilge Rat", "chip": "BR", "desc": "Every trap you disarm frees a wandering soul wisp", "rarity": 2, "mods": {}},
	"ferry_token": {"name": "Ferry Token", "chip": "FT", "desc": "The Ferryman's six-soul toll is halved for token-holders", "rarity": 1, "mods": {}},
	"float_suit": {"name": "Float Suit", "chip": "FS", "desc": "Venom and poison ticks bite at half strength", "rarity": 1, "mods": {}},
	"signal_fire": {"name": "Signal Fire", "chip": "SF", "desc": "Casting Whirl lights the whole floor on your map", "rarity": 1, "mods": {}},
	"oyster_king": {"name": "Oyster King", "chip": "OK", "desc": "Snap Clams never bite you and pay +1 soul when pried", "rarity": 2, "mods": {}},
	"fog_lantern": {"name": "Fog Lantern", "chip": "FL", "desc": "Rolling Fog rolls twice as long for the dead — and twice as deep", "rarity": 1, "mods": {}},
	"galley_whip": {"name": "Galley Whip", "chip": "GW", "desc": "Keelhauled foes arrive tenderized — +25% damage taken for 2s", "rarity": 1, "mods": {}},
	"sextant": {"name": "Dead Reckoning", "chip": "SX", "desc": "Your map reads a room ahead — entering a hall charts the next one too", "rarity": 1, "mods": {}},
	"steady_rope": {"name": "Steady Rope", "chip": "SR", "desc": "Plant your feet — hold still a breath and your arm swings +8% harder", "rarity": 1, "mods": {}},
	"ballast": {"name": "Ballast", "chip": "BA", "desc": "Weight that keeps you upright — +18% Max HP, +1 Armor, −8% Speed", "rarity": 1, "mods": {"max_hp_pct": 0.18, "armor": 1.0, "speed_pct": -0.08}},
	"sea_lantern": {"name": "Sea Lantern", "chip": "SE", "desc": "Souls shine brighter — +12% souls earned", "rarity": 1, "mods": {"soul_gain_pct": 0.12}},
	"gunners_badge": {"name": "Gunner's Badge", "chip": "GB", "desc": "An old powder-crew mark — hostile shots fly 15% slower", "rarity": 1, "mods": {}},
	"lucky_lantern": {"name": "Lucky Lantern", "chip": "LL", "desc": "A lantern that never empties — kills sometimes spill a wandering soul", "rarity": 1, "mods": {}},
	"silk_greaves": {"name": "Silk Greaves", "chip": "SG", "desc": "Woven hull-silk — roots and webs wear off half again as fast", "rarity": 1, "mods": {}},
	"warm_blood": {"name": "Warm Blood", "chip": "WB", "desc": "The furnace in your chest — chills and freezes wear off twice as fast", "rarity": 1, "mods": {}},
	"bilge_pearl": {"name": "Bilge Pearl", "chip": "BP", "desc": "+15% Max HP, −5% Speed", "rarity": 1, "mods": {"max_hp_pct": 0.15, "speed_pct": -0.05}},
	"sea_chart": {"name": "Sea Chart", "chip": "SC", "desc": "+10% Speed, +5% Crit", "rarity": 1, "mods": {"speed_pct": 0.1, "crit": 0.05}},
	"splintered_oar": {"name": "Splintered Oar", "chip": "SO", "desc": "The oar remembers rowing — your dash carries you 30% farther", "rarity": 0, "mods": {}},
	"deck_plank": {"name": "Deck Plank", "chip": "DP", "desc": "Sure footing on any deck — +5% Speed, +5% Attack Speed", "rarity": 0, "mods": {"speed_pct": 0.05, "atk_speed_pct": 0.05}},
	"bitter_chart": {"name": "Bitter Chart", "chip": "BC", "desc": "The drowned mapped this water in blood — −1 Armor, +25% XP", "rarity": 1, "mods": {"armor": -1.0, "xp_pct": 0.25}},
	"kelp_wrap": {"name": "Kelp Wrap", "chip": "KWP", "desc": "+1 Armor, +5% speed — the weed binds and buoys", "rarity": 2, "mods": {"armor": 1, "speed_pct": 0.05}},
	"windlass": {"name": "Windlass", "chip": "WDL", "desc": "+12% attack speed, −5% dodge — the drum turns fast, but it takes your footing", "rarity": 2, "mods": {"atk_speed_pct": 0.12, "dodge": -0.05}},
	"sailmakers_palm": {"name": "Sailmaker's Palm", "chip": "SMP",
	"undertow_idol": {"name": "Undertow Idol", "chip": "UTI", "desc": "A drowned god's little likeness — it pulls for you — +6% ATK, +4% souls.", "rarity": "uncommon", "mods": {"atk_pct": 0.06, "soul_gain_pct": 0.04}},
"grief_bell": {"name": "Grief Bell", "chip": "GRB", "desc": "Its toll hardens every hand that hears it — +10% ATK, −6% dodge.", "rarity": "rare", "mods": {"atk_pct": 0.10, "dodge": -0.06}},
"bilge_stone": {"name": "Bilge Stone", "chip": "BST", "desc": "Ballast that learned to keep a man standing — +1 Armor, +8% Max HP.", "rarity": "common", "mods": {"armor": 1, "max_hp_pct": 0.08}},
"keel_plate": {"name": "Keel Plate", "chip": "KPL", "desc": "A slab of hull iron strapped to your chest — +2 Armor, −6% speed.", "rarity": "uncommon", "mods": {"armor": 2, "speed_pct": -0.06}},
"sirens_comb": {"name": "Siren's Comb", "chip": "SRC", "desc": "Teeth of whalebone that hum your swings faster — +6% ATK speed, −4% Max HP.", "rarity": "uncommon", "mods": {"atk_speed_pct": 0.06, "max_hp_pct": -0.04}},
"mizzen_rat": {"name": "Mizzen Rat", "chip": "MZR", "desc": "+10% souls, −4% XP — it knows where the ship hides its crumbs", "rarity": 2, "mods": {"soul_gain_pct": 0.1, "xp_pct": -0.04}}, "desc": "+8% attack speed, +4% crit — leather palm, needle-quick hands", "rarity": 2, "mods": {"atk_speed_pct": 0.08, "crit": 0.04}},
	"salt_bounty": {"name": "Salt Bounty", "chip": "◈", "rarity": 2, "mods": {"soul_gain_pct": 0.15, "dodge": -0.05}, "desc": "the sea pays more, but you sway slower"},
	"tarred_sole": {"name": "Tarred Sole", "chip": "TSL", "desc": "+8% speed, +4% dodge — tar sticks, but never to you", "rarity": 2, "mods": {"speed_pct": 0.08, "dodge": 0.04}},
	"keel_tape": {"name": "Keel Tape", "chip": "KTP", "desc": "+10% attack speed, −5% crit — measured twice, swung once", "rarity": 2, "mods": {"atk_speed_pct": 0.1, "crit": -0.05}},
	"salt_compass": {"name": "Salt Compass", "chip": "SCT", "desc": "+6% dodge, +10% souls — the needle still points at paydirt", "rarity": 2, "mods": {"dodge": 0.06, "soul_gain_pct": 0.1}},
	"salt_pearl": {"name": "Salt Pearl", "chip": "SP", "desc": "+10% dodge, +10% speed — nacre the size of a skipping stone", "rarity": 2, "mods": {"dodge": 0.1, "speed_pct": 0.1}},
	"gunners_knot": {"name": "Gunner's Knot", "chip": "GK", "desc": "+12% attack speed, +5% crit — tied in a powder-hand's rope", "rarity": 3, "mods": {"atk_speed_pct": 0.12, "crit": 0.05}},
	"tide_token": {"name": "Tide Token", "chip": "TOKEN", "desc": "+15% souls, +5% dodge — a ferryman's clipped fare", "rarity": 3, "mods": {"soul_gain_pct": 0.15, "dodge": 0.05}},
	"blue_wick": {"name": "Blue Wick", "chip": "WICK", "desc": "The blue flame burns quick — +12% XP, +5% speed", "rarity": 1, "mods": {"xp_pct": 0.12, "speed_pct": 0.05}},
	"gallows_chit": {"name": "Gallows Chit", "chip": "GALW", "desc": "The hanged men's toll is paid forward — +10% souls, +1 Armor", "rarity": 2, "mods": {"soul_gain_pct": 0.1, "armor": 1}},
	"crows_foot": {"name": "Crow's Foot", "chip": "CROW", "desc": "The lucky foot remembers every purse — +15% souls, +8% dodge", "rarity": 2, "mods": {"soul_gain_pct": 0.15, "dodge": 0.08}},
	"keel_anvil": {"name": "Keel Anvil", "chip": "ANVL", "desc": "An anchor's burden — +20% ATK, −12% speed", "rarity": 2, "mods": {"atk_pct": 0.2, "speed_pct": -0.12}},
	"undying_lung": {"name": "Undying Lung", "chip": "UL", "desc": "A third lung, drowned but patient — once per run, death refuses you", "rarity": 3, "mods": {"revive": 1}},
	"dowsers_eye": {"name": "Dowser's Eye", "chip": "DE", "desc": "A glass eye that trembles toward weakness — +12% crit", "rarity": 2, "mods": {"crit": 0.12}},
	"anchorite_beads": {"name": "Anchorite's Beads", "chip": "AB", "desc": "Beads of a hermit who never moved again — +2 Armor, −5% speed", "rarity": 2, "mods": {"armor": 2, "speed_pct": -0.05}},
	"pearl_scrip": {"name": "Pearl Scrip", "chip": "PS", "desc": "A promissory note written on nacre — +15% souls", "rarity": 2, "mods": {"soul_gain_pct": 0.15}},
	"long_spine": {"name": "Long Spine", "chip": "LS", "desc": "A keel-wale rib lashed to the grip — +15% reach", "rarity": 1, "mods": {"reach": 0.15}},
	"pelican_bone": {"name": "Pelican Bone", "chip": "PB", "desc": "It swallowed more than fish — +12% souls", "rarity": 1, "mods": {"soul_gain_pct": 0.12}},
	"salt_prayer": {"name": "Salt Prayer", "chip": "SP", "desc": "Knuckles brined hard as ironwood — +1 Armor, −5% speed", "rarity": 0, "mods": {"armor": 1, "speed_pct": -0.05}},
	"salt_horn": {"name": "Salt Horn", "chip": "SN", "desc": "Its blast calls the lessons closer — +15% XP", "rarity": 1, "mods": {"xp_pct": 0.15}},
	"dead_reckoner": {"name": "Dead Reckoner", "chip": "DR", "desc": "Every room you clear pays +1 soul", "rarity": 1, "mods": {}},
	"tar_beads": {"name": "Tar Beads", "chip": "TB", "desc": "Rosary strung with tar — skills recharge +8% faster", "rarity": 1, "mods": {"cd_red": 0.08}},
	"knotmaster_ring": {"name": "Knotmaster's Ring", "chip": "KR", "desc": "A braid of cord and gold — +8% crit", "rarity": 2, "mods": {"crit": 0.08}},
	"salted_dice": {"name": "Salted Dice", "chip": "SD", "desc": "Loaded bones that favor the holder — +6% crit, +6% dodge", "rarity": 2, "mods": {"crit": 0.06, "dodge": 0.06}},
	"powder_flask": {"name": "Powder Flask", "chip": "PF", "desc": "Blackpowder on your belt — +10% ATK", "rarity": 2, "mods": {"atk_pct": 0.1}},
	"prow_plate": {"name": "Prow Plate", "chip": "PP", "desc": "Ship's bow-iron bolted to your chest — +1 Armor", "rarity": 2, "mods": {"armor": 1}},
	"undertow_charm": {"name": "Undertow Charm", "chip": "UC", "desc": "The current slips you sideways — +6% dodge", "rarity": 1, "mods": {"dodge": 0.06}},
	"crows_lens": {"name": "Crow's Lens", "chip": "CL", "desc": "The dead are more interesting to watch — +10% XP", "rarity": 0, "mods": {"xp_pct": 0.1}},
	"tarred_rope": {"name": "Tarred Rope", "chip": "TR", "desc": "The pitch won't let go — the dead's snares cannot root you", "rarity": 1, "mods": {}},
	"crow_claw": {"name": "Crow's Claw", "chip": "CC", "desc": "The claw tastes a chain — kills at combo ×5 or better pay +1 soul", "rarity": 1, "mods": {}},
	"lucky_coin": {"name": "Lucky Coin", "chip": "LC", "desc": "Heads every time — souls pay +10% more", "rarity": 1, "mods": {"soul_gain_pct": 0.1}},
	"signal_flag": {"name": "Signal Flag", "chip": "SF", "desc": "The crew answers the colors — your skills recharge 5% faster", "rarity": 0, "mods": {}},
	"eel_skin": {"name": "Eel Skin", "chip": "ES", "desc": "Slippery as the tide itself — +6% dodge", "rarity": 1, "mods": {"dodge": 0.06}},
	"deadmans_toll": {"name": "Deadman's Toll", "chip": "DT", "desc": "Every floor you cross pays its fare — +1 soul on each floor clear", "rarity": 1, "mods": {}},
	"bosun_whistle": {"name": "Bosun Whistle", "chip": "BW", "desc": "The shrill call of command — your skills recharge 8% faster", "rarity": 1, "mods": {}},
	"sharktooth": {"name": "Sharktooth Pendant", "chip": "SH", "desc": "+8% Crit, +4% Lifesteal", "rarity": 1, "mods": {"crit": 0.08, "lifesteal": 0.04}},
	"wormwood": {"name": "Wormwood Charm", "chip": "WW", "desc": "Bitter root sewn in sailcloth — venom cannot take hold in your blood", "rarity": 1, "mods": {}},
	"pendulum": {"name": "Pendulum Weight", "chip": "PW", "desc": "A keel-weight that swings for you — heavy attacks charge in 0.4s instead of 0.6s", "rarity": 1, "mods": {}},
	"purifiers_salt": {"name": "Purifier's Salt", "chip": "PS", "desc": "Salt blessed at a drowned altar — soul vials also scour hexes, chill, root and rust", "rarity": 1, "mods": {}},
	"brine_ration": {"name": "Brine Ration", "chip": "BR", "desc": "Salt preserves — soul vials mend +10% more", "rarity": 1, "mods": {}},
	"rusted_penny": {"name": "Rusted Penny", "chip": "RP", "desc": "The ferryman's toll — your first shrine price each floor drops 1 soul", "rarity": 0, "mods": {}},
	"netminder": {"name": "Netminder's Charm", "chip": "NM", "desc": "A fisher's knot — every fifth wisp you herd pays a soul", "rarity": 1, "mods": {}},
	"polishing_rag": {"name": "Polishing Rag", "chip": "PR", "desc": "An oilcloth wrapped round your grip — rust wears off your blade twice as fast", "rarity": 0, "mods": {}},
	"brine_whistle": {"name": "Brine Whistle", "chip": "BW", "desc": "Its note drags every foe into the shallows — they spawn slowed for 2.5s", "rarity": 1, "mods": {}},
	"driftwood_idol": {"name": "Driftwood Idol", "chip": "DI", "desc": "Every draft offers one more reroll", "rarity": 1, "mods": {}},
	"wet_fuse": {"name": "Wet Fuse", "chip": "WF", "desc": "Kills on event floors pay +1 soul each", "rarity": 2, "mods": {}},
	"powder_horn": {"name": "Powder Horn", "chip": "PH", "desc": "Your skills recharge 10% faster", "rarity": 1, "mods": {"cd_red": 0.1}},
	"murk_pearl": {"name": "Murk Pearl", "chip": "MP", "desc": "The first time you weather a floor event, +15% XP for the rest of the run", "rarity": 2, "mods": {}},
	"sea_biscuit": {"name": "Sea Biscuit", "chip": "SB", "desc": "Each floor begins with a soul vial in your satchel when it stands empty", "rarity": 2, "mods": {}},
	"pilgrim_wage": {"name": "Pilgrim's Wage", "chip": "PW", "desc": "Every floor where you take a shrine's blessing pays +1 soul at its end", "rarity": 1, "mods": {}},
	"gilded_keel": {"name": "Gilded Keel", "chip": "GK", "desc": "A keel plated in court gold — every gilded chest pays +2 souls", "rarity": 2, "mods": {}},
	"wicker_net": {"name": "Wicker Net", "chip": "WN", "desc": "Tighter weave — the Driftnet tangles every third strike", "rarity": 1, "mods": {}},
	"dead_knot": {"name": "Dead Man's Knot", "chip": "DK", "desc": "A sailor's last tie — every 8th kill each floor pays +1 soul", "rarity": 1, "mods": {}},
	"brine_rat": {"name": "Brine Rat", "chip": "BR", "desc": "The smallest crewmember — curses on you drain a third faster", "rarity": 1, "mods": {}},
	"barbed_line": {"name": "Barbed Line", "chip": "BL", "desc": "Your REACH bites quicker — the Harpoon drags foes every second strike", "rarity": 1, "mods": {}},
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
