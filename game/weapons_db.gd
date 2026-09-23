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
	"soul_reaver": {"name": "Soul Reaver", "gltf": "Skeleton_Staff.gltf", "tint": Color(0.5, 1.15, 0.85), "mods": {"atk": 1.5, "lifesteal": 0.12}, "desc": "+1.5 ATK, +12% LS. SIPHON: 15% chance each hit steals a soul."},
	"thronebreaker": {"name": "Thronebreaker", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.3, 0.95, 0.35), "mods": {"atk": 3.5, "atk_speed_pct": -0.15}, "desc": "+3.5 ATK, -15% AS. CROWNSPLITTER: +40% damage to the Kings."},
	"hollow_crown": {"name": "Hollow Crown", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.95, 0.75, 1.2), "mods": {"atk": 2.8, "crit": 0.08}, "desc": "+2.8 ATK, +8% Crit. USURPER: elites pay you 2 souls each."},
	"wisp_lantern": {"name": "Grave Lantern", "gltf": "Skeleton_Staff.gltf", "tint": Color(0.55, 1.15, 0.9), "mods": {"atk": 1.8, "crit": 0.05}, "desc": "+1.8 ATK, +5% Crit. WISP: slain foes release a wisp that bites another foe."},
	"mimic_fang": {"name": "Mimic Fang", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.15, 0.35, 0.25), "mods": {"atk": 2.4, "crit": 0.1}, "desc": "+2.4 ATK, +10% Crit. JAW: 20% of kills bite a soul loose."},
	"gravebell": {"name": "Gravebell", "gltf": "Skeleton_Staff.gltf", "tint": Color(0.9, 0.85, 1.3), "mods": {"atk": 1.9, "atk_speed_pct": -0.08}, "desc": "+1.9 ATK, -8% AS. TOLL: 25% of kills ring out — 1x ATK to nearby foes."},
	"titan_maul": {"name": "Titan's Maul", "gltf": "Skeleton_Axe.gltf", "tint": Color(0.6, 0.5, 0.9), "mods": {"atk": 3.4, "atk_speed_pct": -0.18}, "desc": "+3.4 ATK, -18% AS. SHATTER: crits stun the target."},
	"sunderfang": {"name": "Sunderfang", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.2, 0.6, 0.3), "mods": {"atk": 2.1, "atk_speed_pct": 0.05}, "desc": "+2.1 ATK, +5% AS. REND: 25% of hits tear armor — foe takes +25% dmg for 4s."},
	"duskblade": {"name": "Duskblade", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.55, 0.45, 1.15), "mods": {"atk": 2.2, "atk_speed_pct": 0.06}, "desc": "+2.2 ATK, +6% AS. DUSKSTRIDE: strikes within 1.5s of a dash echo for 60%."},
	"oathbrand": {"name": "Oathbrand", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.5, 1.2, 0.9), "mods": {"atk": 1.6, "max_hp": 6.0}, "desc": "+1.6 ATK, +6 HP. BOND: +20% dmg while a sworn ally walks beside you."},
	"keelspike": {"name": "Keelspike", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.3, 0.7, 0.9), "mods": {"atk": 2.1}, "desc": "+2.1 ATK. DROWN: +40% dmg to foes under 30% HP."},
	"pearlrazor": {"name": "Pearlrazor", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.9, 0.95, 1.0), "mods": {"atk": 1.8, "aspd": 0.08}, "desc": "+1.8 ATK, +8% Atk Spd. SALVAGE: every 4th strike pays +1 soul."},
	"snapdragon": {"name": "Snapdragon", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.5, 1.0, 0.7), "mods": {"atk": 1.9}, "desc": "+1.9 ATK. AMBUSH: your first strike on every foe bites 50% deeper."},
	"conchhorn": {"name": "Conchhorn", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.75, 0.55, 1.0), "mods": {"atk": 1.7, "aspd": 0.06}, "desc": "+1.7 ATK, +6% Atk Spd. ECHO: every kill sends 0.5x ATK to the nearest foe."},
	"moonshell": {"name": "Moonshell", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.6, 0.75, 1.1), "mods": {"atk": 1.6}, "desc": "+1.6 ATK. THRALL: 15% of your kills rise to fight for you for 4s."},
	"kingfisher": {"name": "Kingfisher", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.3, 0.9, 0.85), "mods": {"atk": 1.5, "aspd": 0.08}, "desc": "+1.5 ATK, +8% Atk Spd. DIVE: every kill cuts your dash cooldown by 0.5s."},
	"tidebrand": {"name": "Tidebrand", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.85, 0.7, 0.3), "mods": {"atk": 1.8}, "desc": "+1.8 ATK. SALVAGE: killing a foe under 30% HP pays +1 soul."},
	"whelk_maul": {"name": "Whelk Maul", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.55, 0.45, 0.85), "mods": {"atk": 3.0, "atk_speed_pct": -0.18, "speed_pct": -0.08}, "desc": "+3.0 ATK, −18% Attack Speed, −8% Speed. BREACH: every 5th strike breaks through — +60% damage."},
	"guthook": {"name": "Guthook", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.9, 0.35, 0.35), "mods": {"atk": 2.2, "atk_speed_pct": -0.12}, "desc": "+2.2 ATK, −12% Attack Speed. BLEED: every 5th strike rends — heals you 5% Max HP."},
	"chimecleaver": {"name": "Chimecleaver", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.9, 0.8, 0.4), "mods": {"atk": 1.5, "atk_speed_pct": -0.05}, "desc": "+1.50 ATK, −5% Attack Speed. PEAL: every 6th strike rings out — nearby foes stunned 1.2s."},
	"scurvy_blade": {"name": "Scurvy Blade", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.6, 0.8, 0.3), "mods": {"atk": 1.4, "atk_speed_pct": 0.05}, "desc": "+1.40 ATK, +5% Attack Speed. SCURVY: every strike adds 0.8s of rot to the wound — it never stops festering."},
	"storm_petrel": {"name": "Storm Petrel", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.7, 0.8, 1.0), "mods": {"atk": 1.45, "speed_pct": 0.1}, "desc": "+1.45 ATK, +10% Speed. PETREL: each kill refunds 40% of your dash charge."},
	"bilge_saw": {"name": "Bilge Saw", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.7, 0.6, 0.4), "mods": {"atk": 1.35, "atk_speed_pct": 0.15}, "desc": "+1.35 ATK, +15% Attack Speed. SAWED: every 5th strike leaves the wound burning for 3s."},
	"salt_pike": {"name": "Salt Pike", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.6, 0.85, 0.75), "mods": {"atk": 1.5, "atk_speed_pct": -0.05}, "desc": "+1.5 ATK, −5% Attack Speed. GAFF: every 4th strike on an elite hooks +1 soul from its purse."},
	"coral_bludgeon": {"name": "Coral Bludgeon", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.0, 0.6, 0.5), "mods": {"atk": 1.4, "atk_speed_pct": 0.05}, "desc": "+1.4 ATK. REEFING: every 5th strike quickens you — +8% Speed for 4s."},
	"quarterstaff": {"name": "Quarterstaff", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.8, 0.7, 0.5), "mods": {"atk": 1.3, "atk_speed_pct": 0.2}, "desc": "+1.3 ATK, +20% Attack Speed. SWEEP: every 8th strike sweeps the room — every foe near you staggers back."},
	"reef_chorus": {"name": "Reef Chorus", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.5, 0.95, 0.8), "mods": {"atk": 1.4, "atk_speed_pct": 0.15}, "desc": "+1.4 ATK, +15% Attack Speed. CHORUS: every 7th strike hums your longest skill back −3s."},
	"harpooner": {"name": "Harpooner", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.6, 0.75, 0.9), "mods": {"atk": 1.7, "atk_speed_pct": -0.05}, "desc": "+1.7 ATK, −5% Attack Speed. SKEWER: every 5th strike punches through — +50% damage and sunders the foe."},
	"gaff_hook": {"name": "Gaff Hook", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.85, 0.6, 0.4), "mods": {"atk": 1.6, "atk_speed_pct": 0.1}, "desc": "+1.6 ATK, +10% Attack Speed. GAFF: every 7th strike rips 40% into the nearest other foe."},
	"riptide_fang": {"name": "Riptide Fang", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.4, 0.75, 0.85), "mods": {"atk": 1.7, "atk_speed_pct": 0.05}, "desc": "+1.7 ATK, +5% Attack Speed. RIP: every 6th strike slows the foe 1.5s and hastens you 1.5s."},
	"captains_hook": {"name": "Captain's Hook", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.7, 0.5, 0.3), "mods": {"atk": 1.6, "atk_speed_pct": 0.08}, "desc": "+1.6 ATK, +8% Attack Speed. HOOKED: every 5th strike drags the foe to your reach."},
	"murkmaker": {"name": "Murkmaker", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.45, 0.6, 0.75), "mods": {"atk": 1.8, "atk_speed_pct": 0.05}, "desc": "+1.8 ATK, +5% Attack Speed. SLIP: every 5th strike quickens your step for 3s."},
	"saltpeter": {"name": "Saltpeter", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.9, 0.75, 0.5), "mods": {"atk": 2.0, "atk_speed_pct": -0.05}, "desc": "+2.0 ATK, -5% Attack Speed. SPARK: every 4th strike lobs a powder shot at a second foe."},
	"silkfang": {"name": "Silkfang", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.62, 0.55, 0.78), "mods": {"atk": 1.7, "atk_speed_pct": 0.1}, "desc": "+1.7 ATK, +10% Attack Speed. SNARE: every 4th strike webs the foe — slowed 1.5s."},
	"brine_cutlass": {"name": "Brine Cutlass", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.55, 0.75, 0.7), "mods": {"atk": 1.9, "atk_speed_pct": -0.05}, "desc": "+1.9 ATK, -5% Attack Speed. BRINE: every 6th strike soaks the foe — slowed for 2s."},
	"bilge_hook": {"name": "Bilge Hook", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.5, 0.55, 0.6), "mods": {"atk": 1.5}, "desc": "+1.5 ATK. GUT: every 5th strike hooks a soul loose — +1 soul."},
	"oarblade": {"name": "Oarblade", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.65, 0.55, 0.4), "mods": {"atk": 1.8, "atk_speed_pct": -0.05}, "desc": "+1.8 ATK, -5% Attack Speed. SLAP: every 3rd strike slams flat — hurls the foe back a full tile."},
	"whale_saw": {"name": "Whalebone Saw", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.95, 0.85, 0.6), "mods": {"atk": 2.4, "atk_speed_pct": -0.1}, "desc": "+2.4 ATK, -10% Attack Speed. SAW: every 4th strike on a wounded foe saws deep — +40% damage."},
	"tide_shear": {"name": "Tide Shear", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.4, 0.9, 0.8), "mods": {"atk": 1.6, "atk_speed_pct": 0.08}, "desc": "+1.6 ATK, +8% Attack Speed. SHEAR: every 5th strike dulls the foe — its blows drop 20%."},
	"chain_anchor": {"name": "Chain Anchor", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.4, 0.55, 0.9), "mods": {"atk": 3.4, "atk_speed_pct": -0.22, "speed_pct": -0.1}, "desc": "+3.4 ATK, -22% Attack Speed, -10% Speed. MOORING: every 6th strike anchors the foe — stunned 1.5s."},
	"scourge": {"name": "Bone Scourge", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.75, 0.45, 0.95), "mods": {"atk": 0.9, "atk_speed_pct": 0.15, "speed_pct": -0.05}, "desc": "+0.9 ATK, +15% Attack Speed, -5% Speed. LASH: every 4th strike drags foes toward you."},
	"driftnet": {"name": "Driftnet", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.45, 0.8, 0.55), "mods": {"atk": 1.4, "speed_pct": -0.06}, "desc": "+1.4 ATK, −6% Speed. NETS: every 4th strike tangles the foe — slowed for 2s."},
	"harpoon": {"name": "Harpoon", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.5, 0.75, 0.95), "mods": {"atk": 1.6, "speed_pct": -0.04}, "desc": "+1.6 ATK, −4% Speed. REACH: every third strike drags a struck foe to arm's length."},
	"undertow": {"name": "Undertow", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.35, 0.9, 1.0), "mods": {"atk": 1.8, "speed_pct": 0.05}, "desc": "+1.8 ATK, +5% Speed. HAUL: strikes drag foes to your reach."},
	"marsh_claw": {"name": "Marsh Claw", "gltf": "Skeleton_Blade.gltf", "tint": Color(0.6, 0.95, 0.4), "mods": {"atk": 1.9, "crit": 0.05}, "desc": "+1.9 ATK, +5% Crit. LEECHROOT: strikes slow foes 10% (stacks)."},
	"searbrand": {"name": "Searbrand", "gltf": "Skeleton_Blade.gltf", "tint": Color(1.5, 0.45, 0.2), "mods": {"atk": 1.8, "crit": 0.05}, "desc": "+1.8 ATK, +5% Crit. IGNITE: hits set foes ablaze for 4s."},
}

const POOL := ["bone_axe", "twin_fang", "hex_staff", "war_blade", "storm_axe", "frost_fang", "ember_mace", "kings_edge", "grave_scythe", "moon_katana", "soul_reaver", "thronebreaker", "hollow_crown", "wisp_lantern", "gravebell", "titan_maul", "sunderfang", "searbrand", "duskblade", "oathbrand", "marsh_claw", "undertow", "keelspike", "pearlrazor", "snapdragon", "conchhorn", "moonshell", "kingfisher", "tidebrand", "harpoon", "driftnet", "guthook", "whelk_maul", "scourge", "chain_anchor", "tide_shear", "whale_saw", "oarblade", "bilge_hook", "brine_cutlass", "silkfang", "saltpeter", "murkmaker", "captains_hook", "riptide_fang", "gaff_hook", "harpooner", "reef_chorus", "quarterstaff", "coral_bludgeon", "salt_pike", "bilge_saw", "storm_petrel", "scurvy_blade", "chimecleaver"]


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
