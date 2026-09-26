extends Node
# Autoload "Stats": sheet stat run, XP/level, relic, senjata, snapshot run,
# pengaturan (musik/sfx/kualitas), flag onboarding, dan save user://save.json.

signal xp_changed(cur, need, level)
signal leveled_up(level)
signal relics_changed
signal weapon_changed

const ITEMS = preload("res://items_db.gd")
const WDB = preload("res://weapons_db.gd")
const SAVE_PATH := "user://save.json"
const VERSION := "1.1.0"
const STORE_ID := "com.kimi.dungeonslice"

var floor_num := 1
var level := 1
var xp := 0
var relics: Array = []
var kills := 0
var current_hp := 5.0
var weapon_id := "rusty_blade"
var owned_weapons: Array = ["rusty_blade"]
var weapon_lv: Dictionary = {}
var draft_open := false

# buff sementara (hilang saat run reset / turun lantai sesuai flag)
var buff_atk_pct := 0.0 # berkat altar: run ini saja
var buff_armor := 0 # berkat altar: armor datar run ini
var buff_speed_pct := 0.0 # omen Feather Step
var buff_xp_pct := 0.0
var soul_gain_pct := 0.0
var dead_weight := false # omen Rich Soil / Tide's Toll blessing
var soul_toll_halved := false # Soul Toller foes skim half your soul gains while they live

func earn_souls(n: int) -> void:
	var pay := n
	if dead_weight and n > 0:
		pay = maxi(0, n - 1)
	if soul_toll_halved and pay > 0:
		pay = int(ceilf(pay * 0.5))
	souls += int(ceilf(pay * (1.0 + soul_gain_pct) * (1.0 + 0.04 * float(meta.get("salvor", 0))) * (1.0 + 0.02 * float(meta.get("ferry", 0))) * (1.0 + 0.04 * float(meta.get("keelwright", 0))) * (1.0 + 0.04 * float(meta.get("charterer", 0))) * (1.0 + 0.03 * float(meta.get("keeper", 0)))))
	souls_run += int(ceilf(pay * (1.0 + soul_gain_pct) * (1.0 + 0.04 * float(meta.get("salvor", 0))) * (1.0 + 0.02 * float(meta.get("ferry", 0))) * (1.0 + 0.04 * float(meta.get("keelwright", 0))) * (1.0 + 0.04 * float(meta.get("charterer", 0))) * (1.0 + 0.03 * float(meta.get("keeper", 0)))))
	if relics.has("chain_rose") and pay > 0:
		current_hp = minf(float(get_stat("max_hp")), current_hp + float(get_stat("max_hp")) * 0.02)
	if souls >= 60:
		ach["deeppurse"] = true
	if souls >= 500:
		ach["soulheavy"] = true
var buff_lifesteal := 0.0 # berkat altar Vampiric: run ini saja
var buff_maxhp_pct := 0.0 # omen Leeching Vein: pengorbanan Max HP
var buff_aspd := 0.0 # berkat altar Fury: run ini saja
var buff_crit := 0.0 # berkat altar Eagle's Eye: run ini saja
var warcry_t := 0.0 # skill War Cry: +50% ATK sementara
var deadeye_t := 0.0
var rigger_t := 0.0 # skill Deadeye: +25% crit sementara
var saltskin_t := 0.0 # skill Saltskin: dodge+armor window
var ironwake_t := 0.0 # skill Ironwake: armor+speed window
var brineward_t := 0.0 # skill Brineward: armor+dodge window
var wakeveil_t := 0.0 # skill Wakeveil: dodge+speed window
var shell_t := 0.0 # skill Barnacle Shell: +6 armor sementara
var warpaint_t := 0.0 # skill Warpaint: +30% ATK sementara
var irontide_t := 0.0 # skill Iron Tide: pukulan terpantul sementara
var revive_left := 0 # jiwa bangkit: hidup lagi sekali per run
var ach := {} # prestasi terbuka: id -> true (persist lintas run)
var thorns := 0.0 # duri pantulan: balikkan dmg
var dodge := 0.0 # fase hantu: peluang bebas damage
var magnet := 0.0 # magnet jiwa: perbesar radius serap orb
var berserk := 0.0 # amukan: bonus ATK saat HP kritis
var combo_atk := 0.0 # bonus ATK bertingkat dari streak kombo (8/15/25)
var combo_aspd := 0.0 # bonus attack-speed dari streak kombo
var mahzan_debt := 0.0 # hutang Max HP ke Mahzan (Leech's Bargain)
var reroll_extra := 0
var solo_xp := 0.0 # Kismet Thread: +1 reroll di tiap draft run ini
var soul_bonus := 0 # Crown Shard: jiwa ekstra per kill
var event_soul_bonus := 0
var soul_sealed := false
var hollow_crown := false
var spiteful := false
var kaels_wager := false
var reaper_tithe := false
var deathwish := false # omen: +40% ATK, +30% dmg taken
var relic_burn := 0.0 # Ember Brand: peluang bakar di semua senjata
var cd_reduction := 0.0 # Echo Bone: skill recharge lebih cepat
var curse_dmg := 0.0 # pakta obelisk: musuh lebih keras (stack)
var curse_xp := 0.0 # pakta obelisk: jiwa lebih kaya (stack)

# meta (tersimpan)
var best_floor := 0
var total_kills := 0
var floors_cleared := 0
var golden_kills := 0
var arch_kills: Dictionary = {}
var dread_survived := 0 # kill total per arketipe — abadi
var traps_defused := 0
var wisps_caught := 0
var prays := 0
var oaths_sworn := 0
var forges_used := 0
var runs := 0
var boss_kills := 0
var ng_plus := 0 # New Game+: naik tiap kali menang di lantai 25
var tutorial_done := false
var seen_cinematic := false
var onboarded := false
var rated := false
var quality := -1 # -1 auto, 0 hemat, 1 indah
var cam_shake := true
var screen_flash := true
var dmg_numbers := true
var haptics := true
var show_minimap := true
var volume := 0.8 # legacy: dipakai kalau music/sfx belum pernah diset
var music_volume := -1.0
var sfx_volume := -1.0
var saved_run := {}
var lore_seen: Array = [] # baris lore yang pernah ditemukan (codex, persist)
var oaths_seen: Array = [] # omen yang pernah disumpah (persist)
var drowned_deals := 0
var souls := 0 # mata uang meta
var souls_run := 0 # jiwa yang diperoleh run ini — dari kill, dipakai di Hall of Souls
var nemesis := "" # arch_id pembunuh terakhir — kembali lebih kuat sampai dibunuh balik
var nemesis_name := "" # nama tampilan untuk menu
var bestiary := {} # arch_id -> jumlah kill sepanjang masa (codex)
var weapon_kills := {} # weapon_id -> kill sepanjang masa (mastery progress)
var mastered := {} # weapon_id -> 1 bila mastery tercapai (+1 ATK permanen)
const MASTERY_N := 25
var meta: Dictionary = {"vital": 0, "might": 0, "swift": 0, "magnet": 0, "wind": 0, "arcane": 0, "greed": 0, "adamant": 0, "leech": 0, "tempered": 0, "veteran": 0, "haggler": 0, "diver": 0, "foundry": 0, "lampwage": 0, "reckon": 0, "keelcap": 0, "shepherd": 0, "captain": 0, "quarter": 0, "purse": 0, "carto": 0, "sealegs": 0, "scribe": 0, "salvor": 0, "deckhand": 0, "powdermonk": 0, "netmend": 0, "belaypin": 0, "ferry": 0, "lampluck": 0, "kilnman": 0, "chirurgeon": 0, "bellringer": 0, "keelwright": 0, "wayfarer": 0, "charterer": 0, "spinebearer": 0, "helmsman": 0, "saltpray": 0, "sharpsalt": 0, "gloomfight": 0, "wetwork": 0, "tollman": 0, "keeper": 0, "tollkeeper": 0, "wakeline": 0, "crestman": 0}

const ACH_DEF := {
	"kill1": "First Bloodbath",
	"k50": "Corridor Reaper (50 kills)",
	"k200": "Crypt Dweller (200 kills)",
	"f5": "Depth Diver (Floor 5)",
	"f10": "Fearless (Floor 10)",
	"arsenal_full": "Full Arsenal (learned every skill)",
	"decklegend": "Deck Legend (carried 6 blades at once)",
	"f15": "Abyssal Gate (Floor 15)",
	"f20": "Heart of the Deep (Floor 20)",
	"f24": "Throneside (Floor 24)",
	"b1": "Throne Breaker",
	"b3": "King Hunter (3 bosses)",
	"r5": "Relic Collector (5 relics)",
	"w5": "Arsenal (5 weapons)",
	"s25": "Crown Taker (clear Floor 25)",
	"soul1": "Soulbound (bound a meta upgrade)",
	"pact1": "Bloodletter (swore a Blood Pact)",
	"defiant": "Defiant (spat in the King's face)",
	"forge3": "Arms Master (forged a weapon to Lv 3)",
	"master1": "Master at Arms (weapon mastered)",
	"knight1": "Liberator (freed Sir Vane)",
	"reborn": "Oracle's Chosen (bought back your life)",
	"scholar": "Crypt Scholar (filled the bestiary)",
	"st5": "Death's Edge (5 kills at death's door)",
	"hex1": "Hex Plunderer (cracked a Cursed Chest)",
	"nem1": "Debt Collector (slew your nemesis)",
	"trap5": "Saboteur (defused 5 traps)",
	"omen1": "Oathbound (swore an Omen)",
	"pawn1": "Pawn Star (sold a relic to Mahzan)",
	"lore10": "Crypt Chronicler (gathered 10 whispers)",
	"wisp8": "Soul Shepherd (caught 8 wandering wisps)",
	"forge5": "Blade Saint (forged a weapon to +5)",
	"mirror1": "Gazer (let the Mirror trade your blade)",
	"smith3": "Master Smith (forged blades at 3 Soul Forges)",
	"bounty1": "Contract Killer (claimed a Bounty Stone relic)",
	"ng2": "Twice-Crowned (reached NG+2)", "ng4": "Ever-Drowning (reached NG+4)", "ng7": "Grave's Delver (reached NG+7)",
	"bless5": "Favored of the Deep (5 blessings in one run)",
	"choral": "Choral (8 blessings in one run)",
	"dice3": "Loaded Bones (won Bone Dice 3 times in one run)",
	"deeppurse": "Deep Purse (held 60 souls at once)",
	"satchel3": "Full Satchel (carried 3 soul vials at once)",
	"lore30": "Deep Chronicler (read 30 dungeon whispers)",
	"lore60": "Crow's Catalog (60 lore heard)",
	"lore32": "Archivist (heard every whispered line)",
	"col10": "Collector (carried 10 relics in one run)",
	"centurion": "Centurion (100 kills in a single run)",
	"untouchable": "Untouchable (three perfect dodges in a run)",
	"pious": "Pious (five prayers over the fallen)",
	"devout": "Devout (fifteen prayers over the fallen)",
	"pacifist": "Blade Only (a floor cleared without skills)",
	"onedrop": "One Drop Left (took the throne on a single drop of blood)",
	"loaded_dice": "Loaded Dice (5 well tosses in one run)",
	"salvager": "Salvager (claimed 15 sea-borne souls)",
	"accountant": "Soul Accountant (100 souls held)",
	"cove": "Treasure Cove (smashed 8 urns in one run)",
	"saltdog": "Saltdog (put down 10 Keelhounds)",
	"clamsnack": "Clam Snack (got nipped by a Snap Clam)",
	"dreadlord": "Dreadlord (survived 3 Dread Tides)",
	"fullpurse": "Full Purse (held 150 souls at once)",
	"deepcoffers": "Deep Coffers (held 200 souls at once)",
	"cart6": "Deep Cartographer (walked all six biomes in one run)",
	"pinch3": "Pinch Hitter (escaped 3 Void Pinchers in one run)",
	"abyss3": "Void Shepherd (cleared 3 Abyss floors in one run)",
	"wellread": "Well Read (read 5 lore stones in one run)",
	"keelhaul5": "Catch & Release (keelhauled 5 foes at once)",
	"bombsquad": "Bomb Squad (disarmed 5 traps in one run)",
	"arsenal": "Full Arsenal (own 15 weapons at once)",
	"arsenal_master": "Arsenal Master (own 25 weapons at once)",
	"websurgeon": "Web Surgeon (slay 10 Hull Widows)",
	"quarteroath": "Quarter Sworn (swore 25 omens across your runs)",
	"salt_merchant": "Salt Merchant (earned 150 souls in one run)",
	"rustproof": "Rustproof (felled 12 Rust Jaws)",
	"wisp20": "Wispherd (caught 20 wisps across your runs)",
	"thawed": "Thawed Out (felled 12 Bilge Witches across your runs)",
	"lantern_lit": "Lantern Lit (took 20 shrine blessings in one run)",
	"w8": "Full Arsenal (carried 8 weapons at once)",
	"toothdeck": "Tooth Deck (cleared 30 foes on a single floor)",
	"birdkeeper": "Birdkeeper (felled 12 Keelbeaks across your runs)",
	"bilge_dancer": "Bilge Dancer (weathered 3 different floor events in one run)",
	"stormwatcher": "Storm Watcher (survived 5 different floor events in one run)",
	"tideturner": "Tide Turner (cast Riptide 5 times in one run)",
	"completionist": "Completionist (finished 6 quest steps in one run)",
	"potbellied": "Pot-Bellied (smashed 10 urns in one run)",
	"wax_floor": "Waxworks (sealed four traps on one floor)",
	"manifest": "Full Manifest (12 quest steps done in one run)",
	"powdermonkey": "Powder Monkey (put down 8 Boom Bones)",
	"moondisciple": "Moon Disciple (bathed in three Moonpools)",
	"fogwalker": "Fog Walker (cleared a floor under Rolling Fog)",
	"pearlhunter": "Pearl Hunter (pried 12 snap clams)",
	"deepdisciple": "Disciple of the Deep (took 8 Drowned Altar deals)",
	"standingorders": "Standing Orders (15 kills planted on the Steady Rope)",
	"pilgrim": "Pilgrim (10 shrine visits in one run)",
	"seaworthy": "Seaworthy (drank the Drowned Tithe)",
	"drowned20": "Drowned Court (20 kills under the Sunken Tide)",
	"tidebearer": "Tidebearer (cleared the Sunken Reliquary)",
	"untouch": "Untouchable (three flawless floors in one run)",
	"ashfall": "Ashes Rained (cleared a floor under the ashfall)",
	"chorus": "The Chorus Falls Silent (cleared a floor of singing dead)",
	"wolfsbane": "Alpha Killer (survived the pack's floor)",
	"veilwalker": "Veil Walker (cleared a floor through the Thin Veil)",
	"tideprovides": "The Tide Provides (took an Undertow Cache)",
	"shoalwalker": "Shoalwalker (cleared a floor in Low Water)",
	"knotmaster": "Knotmaster (8 Dead Man's Knot payouts in a run)",
	"kilnbreaker": {"name": "Kiln Breaker", "desc": "Smashed 25 urns in one run"},
	"choralist": {"name": "Choralist", "desc": "Joined the Siren's choir 4 times"},
	"saltsown": {"name": "Salt-Sown", "desc": "Fell 10 Saltghasts"},
	"ratlord": "Ratlord (slain 15 Mirelings)",
	"slayer150": "Reaper of Ranks (150 kills in a single run)",
	"slayer250": "The Bone Harvest (250 kills in a single run)",
	"doubloath": "Twice-Sworn (carry two omens in one run)",
	"fatebound": "Fatebound (five oaths sworn across your descents)",
	"pact_stack": "Pact Stack (bear four omens on one floor)",
	"tenthoath": "Tenth Oath (ten oaths sworn across your descents)",
	"mariner": "Mariner (reach floor 10 in a single descent)",
	"quarterdeck": "Quarterdeck (reach floor 20 in a single descent)",
	"abyssal": "Abyssal Reaches (reach floor 30 in a single descent)",
	"oldsalt": "Old Salt (reach floor 25 in a single descent)",
	"relichunter": "Relic Hunter (hold 12 relics in one run)",
	"persistent": "Persistent (complete 25 descents)",
	"oathbound": "Oathbound (swear 12 different pacts, across all your descents)",
	"manyoaths": "Many Oaths (swear 20 different pacts, across all your descents)",
	"unstoppable": "Unstoppable (a ×50 kill streak in one run)",
	"deepvault": "Deep Vault (held 50 souls at once)",
	"fortyknells": "Forty Knells (40 skill casts in one run)",
	"versatile": "Versatile (cast 6 different skills in one run)",
	"bright_purse": "Bright Purse (a single soulspill paid 5+ souls)",
	"century_knells": "Hundred Knells (cast 100 skills in one run)",
	"seventypacts": "Hundred Pacts (swore 70 omens)",
	"eightypacts": "Eighty Pacts (swore 80 omens)",
	"ninetypacts": "Ninety Pacts (swore 90 omens)",
	"hundredpacts": "Oathbroken Century (swore 100 omens)",
	"sevensworn": "Sevenfold Sworn (bore 7 omens on a single floor — the deck groans)",
	"dozenoaths": "Dozen Oaths (swore 12 pacts in a single descent)",
	"smiths_pride": "Weaponsmith's Pride (master 5 weapons)",
	"seasoned": "Seasoned (reach Lv 30)",
	"grizzled": "Grizzled (reach Lv 50)",
	"votive": "Votive (take 12 blessings in one run)",
	"sainted": "Sainted (take 18 blessings in one run)",
	"salthoard": "Salt Hoard (hold 300 souls at once)",
	"soulheavy": "Soul Heavy (hold 500 souls at once)",
	"full_ledger": "Full Ledger (strike 60 bargains in one run)",
	"deep_reckoned": "Deep Reckoned (see 170 different omens)",
	"salt_chronicler": "Salt Chronicler (see 180 different omens)",
	"oath_collector": "Oath Collector (see 200 different omens)",
	"final_signatory": "Final Signatory (see 300 different omens)",
	"crown_signatory": "Crown Signatory (see 400 different omens)",
	"abyssal_signatory": "Abyssal Signatory (see 500 different omens)",
	"thousand_oaths": "Thousand Oaths (see 1000 different omens)",
	"grand_chronicler": "Grand Chronicler (see 2500 different omens)",
	"pact_eternal": "Pact Eternal (see 5000 different omens)",
	"full_satchel": "Full Satchel (hold 3 soul vials at once)",
	"medic": "Ship's Medic (hold 5 soul vials at once)",
	"sixtypacts": "Sixty Pacts (60 omens sworn total)",
	"smokedout": "Powder Burn (clear a GUN SMOKE floor)",
	"saltwalker": "Saltwalker (clear a SALTGRAVE floor)",
	"ringer10": "Ringer of Bells (slay 10 Bell Ringers)",
	"thousand_cuts": "A Thousand Cuts (1,000 lifetime kills)",
	"deepvoyager": "Deep Voyager (seventy-five floors cleared across your descents)",
	"halfcentury": "Half Century (clear 50 floors)",
	"gilded_foe": "Gilded Foe (slay 10 golden foes)",
	"sixtyfathoms": "Sixty Fathoms (survive to floor 60 — the deep remembers names)",
	"ninetyknots": "Ninety Knots (survive to floor 90 — faster than the sea's own hunger)",
	"deepveteran": "Veteran of the Deep (survive to floor 120 — few come back with their name)",
	"pactmaster": "Master of Pacts (swear 120 omens — the deep keeps every one)",
	"deepdebtor": "The Deep's Debtor (swear 140 omens — the ledger never closes)",
	"fullledger": "Full Ledger (swear 160 omens — every pact the deep offers)",
	"threequarters": "Three Quarters (reach Floor 75)",
	"centurion_deep": "Centurion of the Deep (reach Floor 100)",
	"deepwater": "Deep Water (reach Floor 40)",
	"saltveteran": "Salt Veteran (reach Floor 45)",

	"hadal": "Hadal Pilgrim (reach Floor 50)",
	"trenchwalker": "Trench Walker (reach Floor 55)",
	"clear_ledger": "Clear Ledger (repay your Mahzan debt)",
	"river_purse": "River Purse (take 5 drowned deals)",
	"fools_gold": "Fool's Gold (hire the Court Fool)",
	"shadowstep": "Shadowstep (5 perfect dodges in one run)",
	"whitecap": "Whitecap (clear a HIGH SEAS floor)",
	"open_purse": "Open Purse (buy 25 deals in one run)",
	"liberator": "Thrall Liberator (free 15 thralls)",
	"spender": "Spender (buy 15 deals in one run)",
	"fulldeck": "Full Deck (every meta upgrade maxed)",
	"ngdeep": "Void Warden (reached floor 20 in New Game+)",
	"oathkeeper": "Oathkeeper (eight omens in a single descent)",
	"lurcher8": "Toppler (felled 8 Mast Lurchers)",
	"gnatcull": "Gnatsbane (swatted 30 Gunnel Gnats)",
	"gloomfall": "Dimmer (stilled 10 Gloom Lanterns)",
	"godlike": "Godlike (reached a ×40 combo)",
	"ledger_lord": "Ledger Lord (struck 40 bargains in one run)",
	"abyssalchart": "Abyssal Chart (reached floor 18)",
	"thricesworn": "Thrice Sworn (swore 3 omens in a single run)",
}

const META_DEF := {
	"vital": {"name": "Vitality", "max": 5, "desc": "+1 Max HP per level"},
	"might": {"name": "Might", "max": 5, "desc": "+5% ATK per level"},
	"swift": {"name": "Swiftness", "max": 4, "desc": "+3% Speed per level"},
	"magnet": {"name": "Magnetism", "max": 3, "desc": "+20% soul-pull per level"},
	"wind": {"name": "Second Wind", "max": 1, "desc": "Begin every run with a revive"},
	"arcane": {"name": "Arcane Edge", "max": 3, "desc": "Skills recharge 8% faster per level"},
	"greed": {"name": "Greed", "max": 3, "desc": "+10% souls per kill per level"},
	"adamant": {"name": "Adamant", "max": 3, "desc": "+1 Armor per level"},
	"leech": {"name": "Siphon Vein", "max": 3, "desc": "+2% Lifesteal per level"},
	"tempered": {"name": "Tempered Edge", "max": 3, "desc": "+4% Crit per level"},
	"veteran": {"name": "Battle Memory", "max": 2, "desc": "Start each run with +2 combo heat per level"},
	"haggler": {"name": "Soul Haggler", "max": 3, "desc": "Every soul price drops 1 per level"},
	"diver": {"name": "Deep Diver", "max": 3, "desc": "Reliquary court tithe pays +2 souls per level"},
	"foundry": {"name": "Foundry Rat", "max": 3, "desc": "Every forge price drops 1 per level"},
	"lampwage": {"name": "Lamplighter's Wage", "max": 2, "desc": "Lanterns mend 50% more per level"},
	"reckon": {"name": "Dead Reckoner", "max": 3, "desc": "Clearing a floor pays +1 soul per level"},
	"keelcap": {"name": "Keel Captain", "max": 2, "desc": "Every Abyss floor cleared pays +2 souls per level"},
	"shepherd": {"name": "Wisp Shepherd", "max": 3, "desc": "The wisps pay +1 soul per level"},
	"captain": {"name": "Soul Captain", "max": 3, "desc": "Quest steps completed pay +1 soul per level"},
	"quarter": {"name": "Quartermaster", "max": 3, "desc": "Each descent mends 5% of your Max HP per level"},
	"carto": {"name": "Cartographer's Eye", "max": 3, "desc": "Each floor begins with +1 room charted per level"},
	"sealegs": {"name": "Sea Legs", "max": 3, "desc": "+4% Speed per level"},
	"scribe": {"name": "Bilge Scribe", "max": 3, "desc": "+5% XP per level"},
	"salvor": {"name": "Salvor's Eye", "max": 3, "desc": "+4% souls earned per level"},
	"deckhand": {"name": "Old Deckhand", "max": 5, "desc": "+2% attack damage per level"},
	"powdermonk": {"name": "Powder Monkey", "max": 5, "desc": "-3% skill cooldowns per level"},
	"netmend": {"name": "Net Mender", "max": 5, "desc": "+2% soul vial drop chance per level"},
	"belaypin": {"name": "Belaypin", "max": 5, "desc": "-3% dash cooldown per level"},
	"ferry": {"name": "Ferry Toll", "max": 5, "desc": "+2% souls earned per level"},
	"lampluck": {"name": "Lamplight Luck", "max": 5, "desc": "+1% dodge chance per level"},
	"kilnman": {"name": "Kilnman", "max": 5, "desc": "+3% attack speed per level"},
	"chirurgeon": {"name": "Chirurgeon", "max": 5, "desc": "+8% soul vial healing per level"},
	"bellringer": {"name": "Bellringer", "max": 5, "desc": "+3% skill recharge per level"},
	"keelwright": {"name": "Keelwright", "max": 5, "desc": "+4% soul gain per level"},
	"wayfarer": {"name": "Wayfarer", "max": 4, "desc": "+1% dodge per level"},
	"charterer": {"name": "Charterer", "max": 3, "desc": "+4% souls per level"},
	"spinebearer": {"name": "Spinebearer", "max": 3, "desc": "+3% thorns per level"},
	"helmsman": {"name": "Helmsman's Eye", "max": 3, "desc": "+1% dodge per level"},
	"saltpray": {"name": "Saltpray", "max": 4, "desc": "+1% speed, +1% dodge per level"},
	"sharpsalt": {"name": "Sharpsalt", "max": 4, "desc": "+2% crit chance per level"},
	"gloomfight": {"name": "Gloomfighter", "max": 3, "desc": "+2% ATK, +1% crit per level"},
	"wetwork": {"name": "Wetwork", "max": 3, "desc": "+1.5% lifesteal per level"},
	"tollman": {"name": "Tollman", "max": 4, "desc": "+1 soul per shrine dealt"},
	"keeper": {"name": "Keeper", "max": 4, "desc": "+3% souls per level"},
	"tollkeeper": {"name": "Tollkeeper", "max": 3, "desc": "+1 soul at each floor's end per level"},
	"wakeline": {"name": "Wakeline", "max": 3, "desc": "+1.5% speed per level"},
	"crestman": {"name": "Crestman", "max": 4, "desc": "+1% dodge, +0.5% speed per level"},
}

# dipakai menu -> game
var pending_restore := false

var base := {"max_hp": 5.0, "atk": 1.0, "speed": 1.0, "crit": 0.05, "lifesteal": 0.0, "atk_speed": 1.0, "armor": 0.0}


func get_stat(n: String) -> float:
	var flat: float = base.get(n, 0.0)
	var mult := 1.0
	for r in relics:
		var mods: Dictionary = ITEMS.DB[r]["mods"]
		if mods.has(n):
			flat += mods[n]
		if mods.has(n + "_pct"):
			mult += mods[n + "_pct"]
	var wmods: Dictionary = WDB.get_w(weapon_id)["mods"]
	if wmods.has(n):
		flat += wmods[n]
	if wmods.has(n + "_pct"):
		mult += wmods[n + "_pct"]
	if n == "atk":
		flat += float(weapon_lv.get(weapon_id, 1) - 1)
		flat += float(mastered.get(weapon_id, 0))
		mult += buff_atk_pct + combo_atk + float(meta.get("might", 0)) * 0.05 + float(meta.get("deckhand", 0)) * 0.02 + float(meta.get("gloomfight", 0)) * 0.02
		if warcry_t > 0.0:
			mult += 0.5
		if warpaint_t > 0.0:
			mult += 0.3
		# amukan: +ATK saat HP di bawah 35%
		if berserk > 0.0 and current_hp <= get_stat("max_hp") * 0.35:
			mult += berserk
		# last stand: +25% ATK saat HP kritis
		if current_hp <= get_stat("max_hp") * 0.2:
			mult += 0.25
		# avenger's charm: +25% ATK selama nemesis masih hidup
		if nemesis != "" and relics.has("liontin_dendam"):
			mult += 0.25
	if n == "atk_speed":
		mult += combo_aspd + buff_aspd + float(meta.get("kilnman", 0)) * 0.03
		if rigger_t > 0.0:
			mult += 0.12
	if n == "max_hp":
		flat += float(meta.get("vital", 0))
		flat -= mahzan_debt
		mult += buff_maxhp_pct
	if n == "armor":
		flat += buff_armor + float(meta.get("adamant", 0))
		if shell_t > 0.0:
			flat += 6.0
	if n == "lifesteal":
		flat += buff_lifesteal + float(meta.get("leech", 0)) * 0.02 + float(meta.get("wetwork", 0)) * 0.015
	if n == "crit":
		flat += buff_crit + float(meta.get("tempered", 0)) * 0.04 + float(meta.get("sharpsalt", 0)) * 0.02 + float(meta.get("gloomfight", 0)) * 0.01
		if deadeye_t > 0.0:
			flat += 0.25
	if n == "speed":
		mult += float(meta.get("swift", 0)) * 0.03 + buff_speed_pct
		mult += float(meta.get("sealegs", 0)) * 0.04 + float(meta.get("saltpray", 0)) * 0.01
		mult += float(meta.get("wakeline", 0)) * 0.015
		mult += float(meta.get("crestman", 0)) * 0.005
		if rigger_t > 0.0:
			mult += 0.22
	return flat * mult


func _process(delta: float) -> void:
	if warcry_t > 0.0:
		warcry_t = maxf(0.0, warcry_t - delta)
	if shell_t > 0.0:
		shell_t = maxf(0.0, shell_t - delta)
	if warpaint_t > 0.0:
		warpaint_t = maxf(0.0, warpaint_t - delta)
	if deadeye_t > 0.0:
		deadeye_t = maxf(0.0, deadeye_t - delta)
	if rigger_t > 0.0:
		rigger_t = maxf(0.0, rigger_t - delta)
	if irontide_t > 0.0:
		irontide_t = maxf(0.0, irontide_t - delta)
		if irontide_t <= 0.0:
			thorns -= 0.5
	if saltskin_t > 0.0:
		saltskin_t = maxf(0.0, saltskin_t - delta)
		if saltskin_t <= 0.0:
			dodge -= 0.15
			buff_armor -= 2
	if ironwake_t > 0.0:
		ironwake_t = maxf(0.0, ironwake_t - delta)
		if ironwake_t <= 0.0:
			buff_armor -= 2
			buff_speed_pct -= 0.10
	if brineward_t > 0.0:
		brineward_t = maxf(0.0, brineward_t - delta)
		if brineward_t <= 0.0:
			buff_armor -= 4
			dodge -= 0.10
	if wakeveil_t > 0.0:
		wakeveil_t = maxf(0.0, wakeveil_t - delta)
		if wakeveil_t <= 0.0:
			dodge -= 0.12
			buff_speed_pct -= 0.06


func mus_vol() -> float:
	return volume if music_volume < 0.0 else music_volume


func sfx_vol() -> float:
	return volume if sfx_volume < 0.0 else sfx_volume


func xp_need() -> int:
	return 3 + level * 2


func add_xp(n: int) -> void:
	xp += int(ceilf(n * (1.0 + curse_xp + buff_xp_pct + solo_xp + float(meta.get("scribe", 0)) * 0.05)))
	while xp >= xp_need():
		xp -= xp_need()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_need(), level)


func add_relic(id: String) -> void:
	if hollow_crown:
		souls += 3
		return
	relics.append(id)
	if relics.size() >= 12 and not ach.has("relichunter"):
		ach["relichunter"] = true
	var mods: Dictionary = ITEMS.DB[id]["mods"]
	if mods.has("revive"):
		revive_left += int(mods["revive"])
	if mods.has("thorns"):
		thorns += float(mods["thorns"])
	if mods.has("dodge"):
		dodge += float(mods["dodge"])
	if mods.has("soul_gain_pct"):
		soul_gain_pct += float(mods["soul_gain_pct"])
	if mods.has("magnet"):
		magnet += float(mods["magnet"])
	if mods.has("berserk"):
		berserk += float(mods["berserk"])
	if id == "driftwood_idol":
		reroll_extra += 1
	if mods.has("soul_bonus"):
		soul_bonus += int(mods["soul_bonus"])
	if mods.has("burn_proc"):
		relic_burn += float(mods["burn_proc"])
	if mods.has("cd_red"):
		cd_reduction += float(mods["cd_red"])
	if mods.has("xp_pct"):
		curse_xp += float(mods["xp_pct"])
	if id == "tangan_tukang":
		weapon_lv[weapon_id] = int(weapon_lv.get(weapon_id, 1)) + 1
	relics_changed.emit()


func remove_relic(id: String) -> void:
	if not relics.has(id):
		return
	relics.erase(id)
	var mods: Dictionary = ITEMS.DB[id]["mods"]
	if mods.has("revive"):
		revive_left = maxi(0, revive_left - int(mods["revive"]))
	if mods.has("thorns"):
		thorns = maxf(0.0, thorns - float(mods["thorns"]))
	if mods.has("dodge"):
		dodge = maxf(0.0, dodge - float(mods["dodge"]))
	if mods.has("soul_gain_pct"):
		soul_gain_pct = maxf(0.0, soul_gain_pct - float(mods["soul_gain_pct"]))
	if mods.has("magnet"):
		magnet = maxf(0.0, magnet - float(mods["magnet"]))
	if mods.has("berserk"):
		berserk = maxf(0.0, berserk - float(mods["berserk"]))
	if mods.has("soul_bonus"):
		soul_bonus = maxi(0, soul_bonus - int(mods["soul_bonus"]))
	if mods.has("burn_proc"):
		relic_burn = maxf(0.0, relic_burn - float(mods["burn_proc"]))
	if mods.has("cd_red"):
		cd_reduction = maxf(0.0, cd_reduction - float(mods["cd_red"]))
	if mods.has("xp_pct"):
		curse_xp = maxf(0.0, curse_xp - float(mods["xp_pct"]))
	relics_changed.emit()


func equip_weapon(id: String) -> void:
	weapon_id = id
	if not owned_weapons.has(id):
		owned_weapons.append(id)
		if owned_weapons.size() >= 6:
			ach["decklegend"] = true
			save_game()
	weapon_changed.emit()


func count_kill() -> void:
	kills += 1
	total_kills += 1
	if not soul_sealed and not (reaper_tithe and randf() < 0.1):
		souls += int(roundf(float(1 + soul_bonus + event_soul_bonus) * (1.0 + 0.1 * float(meta.get("greed", 0))) * (2.0 if kaels_wager else 1.0)))


func reset_run() -> void:
	floor_num = 1
	level = 1
	xp = 0
	relics.clear()
	kills = 0
	weapon_id = "rusty_blade"
	owned_weapons = ["rusty_blade"]
	weapon_lv = {}
	buff_atk_pct = 0.0
	buff_armor = 0
	buff_speed_pct = 0.0
	buff_xp_pct = 0.0
	soul_gain_pct = 0.0
	dead_weight = false
	soul_toll_halved = false
	souls_run = 0
	buff_lifesteal = 0.0
	buff_maxhp_pct = 0.0
	buff_aspd = 0.0
	buff_crit = 0.0
	warcry_t = 0.0
	shell_t = 0.0
	warpaint_t = 0.0
	deadeye_t = 0.0
	rigger_t = 0.0
	saltskin_t = 0.0
	ironwake_t = 0.0
	brineward_t = 0.0
	wakeveil_t = 0.0
	revive_left = int(meta.get("wind", 0))
	thorns = 0.0 + float(meta.get("spinebearer", 0)) * 0.03
	dodge = 0.0
	magnet = float(meta.get("magnet", 0)) * 0.2
	dodge += float(meta.get("wayfarer", 0)) * 0.01
	dodge += float(meta.get("lampluck", 0)) * 0.01
	dodge += float(meta.get("helmsman", 0)) * 0.01
	dodge += float(meta.get("saltpray", 0)) * 0.01
	dodge += float(meta.get("crestman", 0)) * 0.01
	berserk = 0.0
	combo_atk = 0.0
	combo_aspd = 0.0
	mahzan_debt = 0.0
	curse_dmg = 0.0
	reroll_extra = 0
	if relics.has("driftwood_idol"):
		reroll_extra += 1
	solo_xp = 0.0
	curse_xp = 0.0
	soul_bonus = 0
	event_soul_bonus = 0
	soul_sealed = false
	reaper_tithe = false
	deathwish = false
	hollow_crown = false
	spiteful = false
	kaels_wager = false
	relic_burn = 0.0
	cd_reduction = 0.0
	current_hp = get_stat("max_hp")
	draft_open = false
	saved_run = {}
	relics_changed.emit()
	weapon_changed.emit()
	xp_changed.emit(0, xp_need(), 1)


func register_kill(xp_val: int) -> void:
	kills += 1
	total_kills += 1
	add_xp(xp_val)


func meta_cost(id: String) -> int:
	var lv: int = int(meta.get(id, 0))
	return 40 if id == "wind" else 5 + lv * 5


func buy_meta(id: String) -> bool:
	var lv: int = int(meta.get(id, 0))
	if lv >= int(META_DEF[id]["max"]) or souls < meta_cost(id):
		return false
	souls -= meta_cost(id)
	meta[id] = lv + 1
	var all_max := true
	for mk in META_DEF.keys():
		if int(meta.get(mk, 0)) < int(META_DEF[mk]["max"]):
			all_max = false
	if all_max and not ach.has("fulldeck"):
		ach["fulldeck"] = true
		save_game()
	save_game()
	return true


func note_floor() -> void:
	if floor_num >= 10 and not ach.has("mariner"):
		ach["mariner"] = true
	if floor_num >= 20 and not ach.has("quarterdeck"):
		ach["quarterdeck"] = true
	if floor_num >= 25 and not ach.has("oldsalt"):
		ach["oldsalt"] = true
	if floor_num >= 30 and not ach.has("abyssal"):
		ach["abyssal"] = true
	if floor_num >= 40 and not ach.has("deepwater"):
		ach["deepwater"] = true
	if floor_num >= 45 and not ach.has("saltveteran"):
		ach["saltveteran"] = true

	if floor_num >= 50 and not ach.has("hadal"):
		ach["hadal"] = true
	if total_kills >= 1000 and not ach.has("thousand_cuts"):
		ach["thousand_cuts"] = true
	if floors_cleared >= 75 and not ach.has("deepvoyager"):
		ach["deepvoyager"] = true
	if floors_cleared >= 50 and not ach.has("halfcentury"):
		ach["halfcentury"] = true
	if golden_kills >= 10 and not ach.has("gilded_foe"):
		ach["gilded_foe"] = true
	if floor_num >= 55 and not ach.has("trenchwalker"):
		ach["trenchwalker"] = true

	if floor_num >= 60 and not ach.has("sixtyfathoms"):
		ach["sixtyfathoms"] = true
	if floor_num >= 90 and not ach.has("ninetyknots"):
		ach["ninetyknots"] = true
	if floor_num >= 120 and not ach.has("deepveteran"):
		ach["deepveteran"] = true
	if floor_num >= 75 and not ach.has("threequarters"):
		ach["threequarters"] = true
	if floor_num >= 100 and not ach.has("centurion_deep"):
		ach["centurion_deep"] = true
	if floor_num > best_floor:
		best_floor = floor_num
	save_game()


# snapshot run supaya tombol "Lanjutkan" di menu berarti
func save_run() -> void:
	saved_run = {"floor": floor_num, "level": level, "xp": xp, "relics": relics.duplicate(), "weapon_id": weapon_id, "owned": owned_weapons.duplicate(), "hp": current_hp, "kills": kills, "revive": revive_left, "thorns": thorns, "dodge": dodge, "magnet": magnet, "berserk": berserk, "mahzan_debt": mahzan_debt, "weapon_lv": weapon_lv.duplicate(), "curse_dmg": curse_dmg, "curse_xp": curse_xp, "cd_reduction": cd_reduction}
	save_game()


func has_run() -> bool:
	return not saved_run.is_empty()


func clear_run() -> void:
	saved_run = {}
	save_game()


func restore_run() -> bool:
	if saved_run.is_empty():
		return false
	floor_num = int(saved_run.get("floor", 1))
	level = int(saved_run.get("level", 1))
	xp = int(saved_run.get("xp", 0))
	relics = saved_run.get("relics", [])
	weapon_id = saved_run.get("weapon_id", "rusty_blade")
	var ow = saved_run.get("owned", [])
	owned_weapons = ow if ow is Array and not ow.is_empty() else [weapon_id]
	kills = int(saved_run.get("kills", 0))
	revive_left = int(saved_run.get("revive", 0))
	thorns = float(saved_run.get("thorns", 0.0))
	dodge = float(saved_run.get("dodge", 0.0))
	magnet = float(saved_run.get("magnet", 0.0))
	berserk = float(saved_run.get("berserk", 0.0))
	weapon_lv = saved_run.get("weapon_lv", {})
	curse_dmg = float(saved_run.get("curse_dmg", 0.0))
	curse_xp = float(saved_run.get("curse_xp", 0.0))
	cd_reduction = float(saved_run.get("cd_reduction", 0.0))
	mahzan_debt = float(saved_run.get("mahzan_debt", 0.0))
	buff_atk_pct = 0.0
	current_hp = float(saved_run.get("hp", get_stat("max_hp")))
	draft_open = false
	relics_changed.emit()
	weapon_changed.emit()
	xp_changed.emit(xp, xp_need(), level)
	return true


func wipe_progress() -> void:
	best_floor = 0
	total_kills = 0
	arch_kills = {}
	traps_defused = 0
	wisps_caught = 0
	prays = 0
	oaths_sworn = 0
	forges_used = 0
	runs = 0
	boss_kills = 0
	ng_plus = 0
	tutorial_done = false
	onboarded = false
	rated = false
	saved_run = {}
	lore_seen = []
	oaths_seen = []
	drowned_deals = 0
	souls = 0
	bestiary = {}
	weapon_kills = {}
	mastered = {}
	meta = {"vital": 0, "might": 0, "swift": 0, "magnet": 0, "wind": 0, "arcane": 0, "greed": 0, "adamant": 0, "leech": 0, "tempered": 0, "veteran": 0, "haggler": 0, "diver": 0, "foundry": 0, "lampwage": 0, "reckon": 0, "keelcap": 0, "shepherd": 0, "captain": 0, "quarter": 0, "purse": 0, "carto": 0, "sealegs": 0, "scribe": 0, "salvor": 0, "deckhand": 0, "powdermonk": 0, "netmend": 0, "belaypin": 0, "ferry": 0, "lampluck": 0, "kilnman": 0, "chirurgeon": 0, "bellringer": 0, "keelwright": 0, "wayfarer": 0, "charterer": 0, "spinebearer": 0, "helmsman": 0, "saltpray": 0, "sharpsalt": 0, "gloomfight": 0, "wetwork": 0, "tollman": 0, "keeper": 0, "tollkeeper": 0, "wakeline": 0, "crestman": 0}
	reset_run()
	save_game()


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"best_floor": best_floor, "total_kills": total_kills, "floors_cleared": floors_cleared, "golden_kills": golden_kills, "runs": runs, "arch_kills": arch_kills, "dread_survived": dread_survived,
			"boss_kills": boss_kills, "ng_plus": ng_plus,
			"traps_defused": traps_defused,
	"wisps_caught": wisps_caught, "forges_used": forges_used, "prays": prays, "oaths_sworn": oaths_sworn,
			"tutorial_done": tutorial_done, "seen_cinematic": seen_cinematic,
			"onboarded": onboarded, "rated": rated,
			"quality": quality, "volume": volume,
			"music_volume": music_volume, "sfx_volume": sfx_volume,
			"cam_shake": cam_shake,
			"screen_flash": screen_flash,
			"dmg_numbers": dmg_numbers,
			"show_minimap": show_minimap,
			"run": saved_run,
			"ach": ach,
			"lore": lore_seen, "oaths": oaths_seen,
			"souls": souls,
			"meta": meta,
			"bestiary": bestiary,
			"weapon_kills": weapon_kills,
			"mastered": mastered,
			"nemesis": nemesis,
			"nemesis_name": nemesis_name,
			"drowned_deals": drowned_deals,
		}))


func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if d is Dictionary:
			best_floor = int(d.get("best_floor", 0))
			floors_cleared = int(d.get("floors_cleared", 0))
			golden_kills = int(d.get("golden_kills", 0))
			total_kills = int(d.get("total_kills", 0))
			arch_kills = d.get("arch_kills", {})
			dread_survived = int(d.get("dread_survived", 0))
			runs = int(d.get("runs", 0))
			boss_kills = int(d.get("boss_kills", 0))
			traps_defused = int(d.get("traps_defused", 0))
			wisps_caught = int(d.get("wisps_caught", 0))
			prays = int(d.get("prays", 0))
			oaths_sworn = int(d.get("oaths_sworn", 0))
			forges_used = int(d.get("forges_used", 0))
			ng_plus = int(d.get("ng_plus", 0))
			tutorial_done = d.get("tutorial_done", false)
			seen_cinematic = d.get("seen_cinematic", false)
			onboarded = d.get("onboarded", false)
			rated = d.get("rated", false)
			quality = int(d.get("quality", -1))
			volume = float(d.get("volume", 0.8))
			music_volume = float(d.get("music_volume", -1.0))
			sfx_volume = float(d.get("sfx_volume", -1.0))
			cam_shake = bool(d.get("cam_shake", true))
			screen_flash = bool(d.get("screen_flash", true))
			dmg_numbers = bool(d.get("dmg_numbers", true))
			show_minimap = bool(d.get("show_minimap", true))
			var r = d.get("run", {})
			if r is Dictionary:
				saved_run = r
			var a2 = d.get("ach", {})
			if a2 is Dictionary:
				ach = a2
			var lo = d.get("lore", [])
			if lo is Array:
				lore_seen = lo
			if d.has("oaths") and d["oaths"] is Array:
				oaths_seen = d["oaths"]
			souls = int(d.get("souls", 0))
			var me = d.get("meta", {})
			if me is Dictionary:
				for k in META_DEF.keys():
					meta[k] = int(me.get(k, 0))
			drowned_deals = int(d.get("drowned_deals", 0))
			var be = d.get("bestiary", {})
			if be is Dictionary:
				bestiary = be
			var wk = d.get("weapon_kills", {})
			if wk is Dictionary:
				weapon_kills = wk
			var ms = d.get("mastered", {})
			if ms is Dictionary:
				mastered = ms
			nemesis = str(d.get("nemesis", ""))
			nemesis_name = str(d.get("nemesis_name", ""))
