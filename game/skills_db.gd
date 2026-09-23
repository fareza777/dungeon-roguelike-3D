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
	"sunder": {
		"name": "Sundering Blow", "short": "SNDR", "cd": 13.0, "unlock": 13,
		"desc": "Guard-shattering strike: 2.5x ATK — the foe takes +30% damage for 4s.",
	},
	"chains": {
		"name": "Grave Chains", "short": "CHN", "cd": 16.0, "unlock": 15,
		"desc": "Spectral chains bind all nearby foes for 2.2s + 0.8x ATK.",
	},
	"storm": {
		"name": "Soul Storm", "short": "STORM", "cd": 28.0, "unlock": 17,
		"desc": "Call the deep's fury: lightning smites EVERY awake foe for 1.5x ATK.",
	},
	"mend": {
		"name": "Oracle's Mend", "short": "MEND", "cd": 40.0, "unlock": 19,
		"desc": "Her thread closes wounds: restore 2 HP and shake off chill and chains.",
	},
	"seismic": {"name": "Seismic Slam", "short": "SEIS", "cd": 30.0, "unlock": 23, "desc": "Slam the dungeon floor — nearby foes take 1.8x ATK and are stunned."},
	"kingsfall": {"name": "Kingsfall", "short": "KING", "cd": 45.0, "unlock": 25, "desc": "Bring down the crown — 3x ATK to all awake foes; bosses take half again."},
	"lance": {"name": "Soul Lance", "short": "LANCE", "cd": 22.0, "unlock": 27, "desc": "A piercing line of soul-light — 1.4x ATK through every foe in your facing lane."},
	"gravestep": {"name": "Gravestep", "short": "STEP", "cd": 16.0, "unlock": 29, "desc": "Blink through the dark — 1.2x ATK burst on arrival."},
	"tidecall": {"name": "Tide Call", "short": "TIDE", "cd": 20.0, "unlock": 31, "desc": "Summon the drowned tide — 1.5x ATK, hurls foes back and slows them."},
	"snapjaw": {"name": "Snapjaw", "short": "SNAP", "cd": 18.0, "unlock": 33, "desc": "A spectral clam erupts — foes nearby are clamped shut for 1.5s and bitten for 1.2x ATK."},
	"graveseal": {"name": "Grave Seal", "short": "SEAL", "cd": 22.0, "unlock": 35, "desc": "A wax seal of the King himself — every foe in the room is sealed still for 2.5s."},
	"riptide": {"name": "Riptide", "short": "TIDE", "cd": 24.0, "unlock": 37, "desc": "The floor turns to black water — every foe within 3 tiles is dragged to your feet, soaked and slowed."},
	"soultithe": {"name": "Soul Tithe", "short": "TITHE", "cd": 26.0, "unlock": 39, "desc": "Offer 3 souls to smite every awake foe for 2x ATK — the kill refunds its share."},
	"soulfall": {"name": "Soulfall", "short": "FALL", "cd": 30.0, "unlock": 43, "desc": "Spend 15% of your current HP — foes within 2.2 tiles take double what you paid."},
	"bloodtide": {"name": "Bloodtide", "short": "TIDE", "cd": 16.0, "unlock": 47, "desc": "For 5 seconds every kill pays +1 soul."},
	"sealegs": {"name": "Sea Legs", "short": "LEGS", "cd": 14.0, "unlock": 49, "desc": "Find your sea legs — shed every hex, chill and root; +15% speed for 2.5s."},
	"deadreckon": {"name": "Dead Reckoning", "short": "RECK", "cd": 20.0, "unlock": 51, "desc": "Chart every foe in the room — they take +25% damage for 6s."},
	"becalm": {"name": "Becalm", "short": "CALM", "cd": 18.0, "unlock": 53, "desc": "The sea goes still — every foe in the room drags at half speed for 6s."},
	"irontide": {"name": "Iron Tide", "short": "IRON", "cd": 24.0, "unlock": 55, "desc": "Skin turns to hull-plating — for 5s, every blow against you bites its striker back for half."},
	"dragline": {"name": "Dragline", "short": "DRAG", "cd": 14.0, "unlock": 57, "desc": "Hook the nearest foe and haul it to your blade — 1.2x ATK on arrival."},
	"keelsplit": {"name": "Keel Split", "short": "KEEL", "cd": 22.0, "unlock": 45, "desc": "Split the keel — a full-tile line ahead takes 1.4× ATK and drags slowed for 2s."},
	"anchordrop": {"name": "Anchor Drop", "short": "ANCH", "cd": 28.0, "unlock": 41, "desc": "Drop a spectral anchor — foes within 2 tiles take 1.6x ATK and are pinned in place for 2s."},
	"rites": {
		"name": "Reaper's Toll", "short": "TOLL", "cd": 34.0, "unlock": 21,
		"desc": "Ring the toll: awake foes below 25% HP die outright; the rest take 1x ATK.",
	},
}

const ORDER := ["dash", "whirl", "thunder", "warcry", "nova", "judge", "sunder", "chains", "storm", "mend", "rites", "seismic", "kingsfall", "lance", "gravestep", "tidecall", "snapjaw", "graveseal", "riptide", "soultithe", "anchordrop", "soulfall", "keelsplit", "bloodtide", "sealegs", "deadreckon", "becalm", "irontide", "dragline"]


static func get_s(id: String) -> Dictionary:
	return DB[id]


static func is_unlocked(id: String, level: int) -> bool:
	return level >= int(DB[id]["unlock"])
