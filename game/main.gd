extends Node3D
# Orchestrator roguelike v5: lantai multi-ruangan + gerbang portcullis, skill
# aktif, draft relic, biome, tutorial, layar hero — plus rantai quest berurutan
# per lantai, dialog karakter berpotret, lantai BOSS tiap kelipatan 5 (Raja
# Tulang: enrage + slam + summon), jebakan duri, altar arwah, peti mimic,
# kombo kill, minimap, dan musik adaptif (dungeon/boss).

const CHARS := "res://assets/characters/"
const M = preload("res://materials.gd")
const RG = preload("res://room_gen.gd")
const EDB = preload("res://enemies_db.gd")
const BIO = preload("res://biomes_db.gd")
const ITEMS = preload("res://items_db.gd")
const WDB = preload("res://weapons_db.gd")
const WPICK = preload("res://weapon_pickup.gd")
const GATE = preload("res://gate.gd")
const GEM = preload("res://xp_gem.gd")
const HORB = preload("res://health_orb.gd")
const SK = preload("res://skills_db.gd")
const QDB = preload("res://quests_db.gd")
const DLG = preload("res://dialogue.gd")
const TRAP = preload("res://trap.gd")
const VIAL = preload("res://vial.gd")
const WISP = preload("res://wisp.gd")
const SQUIRE = preload("res://squire.gd")
const SHRINE = preload("res://shrine.gd")
const LSTONE = preload("res://lore_stone.gd")
const CAGE = preload("res://cage.gd")
const URN = preload("res://urn.gd")
const OBEL = preload("res://dread_obelisk.gd")
const TOMB = preload("res://tombstone.gd")
const DUNGEON := "res://assets/dungeon/"

# baris lore dunia — bisikan Oracle saat menyentuh batu pengetahuan
const EPITAPHS := [
	"The dark keeps what it catches.",
	"Not an ending — a counting pause.",
	"The throne applauds another empty chair.",
	"Souls remember. Floors forget.",
	"He was so close, the stone sighed.",
	"Down here, even a brave death is just... a death.",
	"The Ferryman hums. He's seen your name.",
	"Bones don't argue. They wait.",
]

const LORE_LINES := [
	"The Bone King was King Aldric once — the crown still sits on his skull.",
	"He buried this kingdom to keep it. Now you dig through his grave.",
	"The Oracle was his queen. She stayed to watch him fall.",
	"Mahzan sells blessings to the dead — you are his only living customer.",
	"Every throne needs a body. He keeps trying to make yours fit.",
	"The torches still burn for a court of bones. Someone keeps them lit.",
	"Floor by floor, the walls remember less kindness.",
	"The gates open only for victors. The King designed it that way.",
	"The mimics learned his greed: hoard everything, devour the rest.",
	"The deeper you go, the older his magic — and the colder.",
	"Kael, he knew your name before you ever drew your blade.",
	"The last hero left his sword in the Bone King's chest. It is still there.",
	"Skeletons don't dream — yet they all march in the same direction.",
	"Beneath the thirtieth floor, even the stone forgets the sun.",
	"The Reliquary sank whole — treasury, guards, and all their unpaid debts.",
	"Every pearl in these vaults was once somebody's ransom.",
	"The clams of the deep don't bite out of hunger. They bite out of loyalty.",
	"The water here remembers every drowning — and teaches it to the next.",
	"The cages were built by a gaoler with no face — he collects what the King forgets.",
	"Sir Vane died defending the nursery door. The bars never forgave him.",
	"The Gaoler was the King's twin brother, once — the crown chose the crueler of two shadows.",
	"The Oracle threads every soul she saves into a rope. Yours, she says, is her favorite strand.",
	"Aldric's last decree was carved in gold: 'None shall outlive the throne.' He meant it literally.",
	"The King's ledger lists every hero who ever fell — page after page, all in his own hand.",
	"The Weeper was the court's choir-master. He still can't bear to hear bones break.",
	"The Sentinels were archers who swore never to retreat — the King took the words literally.",
	"Mahzan once bet the Bone King a throne could be bought. He is still collecting.",
	"The Hex Priests were Aldric's confessors — they still silence prayer itself.",
	"The Shade was the King's champion duelist. He blinked once too often, and the dark kept him.",
	"Kael's name is already in the ledger — only the page number is still being written.",
	"The Golem was every fallen knight at once — it swings with all their weight, and none of their mercy.",
	"Somewhere below, the Soul Forge still burns for a smith who never came back for his blade.",
	"The Wailing Maidens were choir-sisters once. They still sing — only at funerals now.",
	"Mahzan's ledger has one page he refuses to sell — the one with his own name on it.",
	"The Bounty Stones were the dungeon's own bounty board — it pays in relics for dead heroes' bones.",
	"On Giant's Hall nights the tomb-walls stretch, and the dead remember being taller.",
	"The Ferryman rows a river no map shows. His oar is a femur; his fare is always six.",
	"The Crowned fell defending the throne. They still do — the throne just moved.",
	"Somewhere below, the Well counts every soul you've thrown. It keeps a ledger too.",
	"The pack that hunts you was Aldric's kennel once. They remember hand-feeding.",
	"Mahzan was the court physician. He prescribed the burial.",
	"The Sunken Reliquary drowned when the King refused the sea its tithe. The sea took the treasury anyway.",
	"Drowned Ones walked out of the vaults on their own once the water rose. The dead don't mind the wet — it's the gold they came for.",
	"The Drowned Altar was the sailors' shrine before the kingdom forgot it had sailors.",
	"The Emissary was the last tax-collector to enter the Reliquary. He's still collecting.",
	"Sir Vane led the King's vanguard once — the only knight who refused to kneel to a skull. So they chained him in light.",
	"Vane's cell was carved from the throne's own foundation stone. The King keeps his bravest prisoner closest.",
	"The Keelhounds were the harbor's watchdogs once. They drowned loyal, and loyal still — now they guard every purse that sinks.",
	"Mahzan keeps one contract he never speaks of: whatever the Bone King owes him is worth more than a throne.",
	"The Fog doesn't rise from the sea — it seeps up from the graveyard below, carrying the drowned crew's last orders. They still slow the ship for the new dead.",
	"The Steady Rope was the last knot the bosun ever tied — sailors say a planted fighter still holds his watch.",
	"Every Keelstone is a sailor's grave that chose to keep working. Lean close and you can hear it taking bets.",
	"The Deep doesn't want your death, Kael — it wants your debts. Everything down here runs on what you're owed.",
	"The Orator's choir once sang Aldric's coronation hymn. Now it rehearses his funeral dirge and never finishes the last verse.",
	"Mahzan owes the Bone King a debt older than the throne — and a debt that old, both of them swear, can never be allowed to close.",
	"When the Veil runs thin, the drowned can see the living shore — and every one of them remembers wanting to walk on it.",
	"The Glass Compass was ground from a drowned navigator's lens. Mahzan swears it still points the way the tide went out.",
	"Barbed Lines were fished from the last crew's hold — the hooks still hunger for whatever escapes the deck.",
	"The Pilot Fish never leaves a sinking ship — it simply finds a slower one. Keep it close and dying gets harder.",
	"When the tide draws out, even the King's court wades slower — the shallows remember everyone who drowned in them.",
	"Cartographers in the deep don't draw rooms — they draw debts. Every charted hall is a promise the floor means to keep.",
	"The Quartermaster kept the crew armed even after they drowned — a good steward never abandons inventory.",
	"Saltghasts are blown out of sailors' last breaths — every one still trying to signal a shore that sank.",
	"A Guthook isn't a weapon so much as an argument — every fifth swing settles it.",
	"The Feral don't love their pack, Kael — they love what the pack leaves behind when it falls.",
	"The Siren's Conch never repeats a song. Mahzan says the sea only charges once per verse.",
	"The fathomless owe the most — the deeper the lesson, the steeper the bill.",
	"The quartermaster keeps two ledgers — one of rope and powder, one of debts no coin repays.",
	"The wisps are not souls, Kael — they are receipts. Every one marks a debt the sea paid in full.",
	"The Bilge Witches sang in the choirs once — the water took their voices and gave back cold.",
	"A gauntlet floor is the King's way of counting how badly he wants you — answer accordingly.",
	"The Rust Jaws were smiths once — the dungeon keeps their trade but not their memory.",
	"When the water kneels, Kael, do not thank it. The sea only bows before it pulls.",
	"The Heralds were criers once — the salt still announces them, whether they wish it or not.",
	"The Bell Ringers toll for a congregation that drowned a hundred years back — they still expect the pews to fill.",
	"A Salt Ward drawn true is older than the King's crown — the sea remembers every circle.",
	"Mahzan counts his bargains in ledgers no hand wrote — the page is always fuller than he left it.",
	"The Undertow Blade doesn't cut the dead, Kael — it reminds them which way is down.",
	"Skill comes back like the tide, Kael — the trick is to be standing when it does.",
	"The gales test rigging and sailor alike — in this dungeon, Kael, you are both.",
	"Salt preserves what it touches. Ask the Salted ones what it preserved of them — then ask what spilled.",
	"The Hull Widows wove the King's fleet into one great snare. He drowned them for the compliment.",
	"Mercy is a tide that comes rarely, Kael — and always at the hour you stopped expecting it.",
	"The Widow's webs outlast her — clear them or they will outlast you.",
	"A slow clock still strikes, Kael — it only asks that you be patient enough to hear it.",
	"The Gunners were the King's own powder crews — he drowned them mid-salute, and they are still firing.",
	"Every tide that favors you, Kael, the sea writes down twice: once as a gift, once as a debt.",
	"Powder crews fired in pairs by tradition — one barrel for the foe, one for luck.",
	"A loose ship still floats, Kael — she just reminds you how thin the hull is.",
	"A lantern in a dead hand still counts as a lantern, Kael. Douse it kindly.",
	"The sea does not count in years down here — she counts in tides owed.",
	"The Reef Caller never learned a war song, Kael — it only ever learned yours.",
	"A wormwood charm tastes bitter so the venom forgets where your heart is.",
	"The salt remembers every sailor — it keeps their names in the tide.",
	"He built the dungeon to hold one prisoner, and got a thousand heroes instead.",
	"Kael — the bride's song and the cantor's call were his wedding music once.",
	"The Deck Brood carries its young inside the ribs — cracking it only wakes the hunger.",
	"They say the King's tithe is still being collected — every soul you spend pays down his ledger.",
	"The oathbound never break — they only run out of things to mend.",
	"The slippery ones wear the sea like oil — the fourth blow always finds empty water.",
	"Where the smoke drifts, the powder dries slow — but the hands that loaded it never rested.",
	"Mahzan pays for secrets in souls — and buys them back cheaper than you'd think.",
	"Water-logged mirrors show the deck as it was — bright, crowded, unaware.",
	"Every bargain Mahzan writes has two prices: the one you see, and the one you'll find out.",
	"The sprite-maw at the bilge keeps its own ledger — a soul per touch, no exceptions.",

	"The Oracle's stone was carved from the same quarry as the throne — the King keeps his counselors close, and closer still.",
	"Vane's vow was to guard the door, not the crown. He still can't say which one he failed.",
	"The drowned court never adjourned — they just stopped hearing appeals.",
	"The bell wardens rang tide-changes once. Now they toll for the dead who stopped counting.",
	"A hookfin's harpoon never misses twice — the sea teaches each predator one perfect trick.",
	"The Bone King does not chase. He knows the stairs only go down, and they all end at his feet.",
	"Somewhere below the salt line the drowned keep their own court — the King tolerates it, as one tolerates a debt owed to the sea.",
	"The Bell Warden tolls for every soul that sinks past the lantern line — he stopped counting whose long ago.",
	"Gutter chaplains preach to the drowned. The drowned, being dead, find his sermons considerably shorter.",
"The drowned keep ledgers too — every debt they owed arrives at the surface unpaid.",
"Below the wrecks the water is patient. It has already won every argument it ever started.",
"The Saltcaller was a chapel bell once — it rings for whoever is still breathing.",
"Pelican Bone keeps its pockets full of drowned coins — the sea's smallest miser.",
"The Salt Gibbet was a scaffold once. The noose it wore is now the barb it throws.",
"The Lantern Jaw walked the wrecks with a wick for a tongue — it still lights the hunt for every corpse behind it.",]

var dungeon_tex: Texture2D
var skeleton_tex: Texture2D

var room: Node3D = null
var info := {}
var biome := {}
var _biomes_seen := {}
var _biomes_run := {}
var player = null
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var joystick
var ui := {}
var trauma := 0.0
var run_state := "playing"
var seed_val := 7
var autotest := false
var rng := RandomNumberGenerator.new()
var pending_drafts := 0
var draft_choices: Array = []
var draft_rerolls := 1
var low_quality := false
var blood_moon := false
var soul_rush := false
var fading_light := false
var echoing := false
var omen_done := false
var omen_done2 := false # pakta kedua di lantai 11
var omen_hp_mult := 1.0
var omen_name := ""
var fatehand := false
var nemesis_bounty := false
var candle_tax := false
var pilot_dead := false
var fathom_tax := false
var hull_rot := false
var still_water := false
var gold_hull := false
var salt_ration := false
var hard_tack := false
var leaden_purse := false
var widows_ledger := false
var flotsam_kin := false
var scurvy := false
var draft_hole := false
var keel_hauled := false
var bilge_sworn := false
var salt_forfeit := false
var dead_reckoner := false
var pale_dock := false
var fathom_pact := false
var bosuns_debt := false
var crews_share := false
var palm_tar := false
var oar_tax := false
var rust_bounty := false
var deep_charter := false
var salty_wages := false
var gunnel_tide := false
var dead_wages := false
var riggers_due := false
var tides_favor := false
var barnacle_oath := false
var black_tide := false
var grave_knot := false
var salt_dowry := false
var sv_doubt := false
var grim_wager := false
var combo_rate_bonus := 0.0
var solitary := false
var pawn_discount := false
var trap_wrapped := 0
var perfect_dodges := 0
var golden_fate := false
var _warned := {}
var champ_room := -1 # sarang sang juara: elite terjamin + drop lebih baik
var ambush_room := -1 # ruangan "kosong" yang ternyata penyergapan
var ambushed_room := -1 # ruangan yang ambush-nya sudah meletus
var chest_opened := false
var gilded_chest := false
var cursed_chest := false
var storm_cellar := false
var gilded_tides := false
var soul_drift := false
var grave_hunger := false
var giant_hall := false
var shrouded := false
var ossuary := false
var mirror_hall := false
var ashfall := false
var hungry_walls := false
var candlelit := false
var verdant := false
var bone_chorus := false
var wolfsbane := false
var sunken_tide := false
var low_tide := false
var glass_sea := false
var abyssal_hymn := false
var dead_calm := false
var thin_veil := false
var low_water := false
var drift_tide := false
var soul_swarm := false
var gauntlet := false
var brisk := false
var shoal_tide := false
var salvage_tide := false
var gale_tide := false
var mercy_tide := false
var eel_tide := false
var swell_tide := false
var kelp_bed := false
var barnacle_bloom := false
var sodden := false
var bile_tide := false
var mire_hollow := false
var dark_lantern := false
var halfwreck := false
var merchant_tide := false
var hungry_urns := false
var bilge_run := false
var pale_squall := false
var soul_flush := false
var kings_tithe := false
var tar_smear := false
var black_calm := false
var gun_smoke := false
var fog_song_t := 0.0
var bilge_iron := false
var chorus_cut := false
var greedy_tide := false
var drift_wreck := false
var long_watch := false
var fog_lantern_d := false
var crowns_rest := false
var salted_deck := false
var crows_tide := false
var long_night := false
var halfway_dead := false
var rich_vein := false
var wraiths_due := false
var pale_lantern_ev := false
var saltgrave_ev := false
var leeward_ev := false
var brine_smoke := false
var crowns_ransom := false
var bilge_strike := false
var full_draught := false
var salt_front := false
var cold_snap := false
var full_moon := false
var gunners_luck := false
var shallow_graves := false
var wailing_wind := false
var balmy_sea := false
var rust_storm := false
var ember_wake := false
var saltsick := false
var gallows_tide := false
var pilot_light := false
var widdershins := false
var slack_water := false
var salvage_breeze := false
var deep_salve := false
var keel_spirit := false
var lantern_wake := false
var fog_bank := false
var tide_clock := false
var deep_well := false
var bilge_still := false
var keel_groan := false
var saltwind := false
var bone_lantern := false
var dead_reckoning := false
var gloom_tide := false
var pale_wake := false
var murk_lift := false
var siren_hum := false
var grim_calm := false
var keel_haul := false
var weeping_tide := false
var deep_draught := false
var thick_tide := false
var slack_line := false
var low_lantern := false
var mirage_sea := false
var bilge_lull := false
var wet_wool := false
var ballast_beads := false
var dowser_knot := false
var crowns_vigil := false
var vigils_gage := false
var crowns_hush := false
var vassals_claim := false
var deck_manifest := false
var dirge_note := false
var line_splice := false
var salt_rosary := false
var moonwater := false
var tar_knots := false
var salt_sheath := false
var brine_hymn := false
var keelmans_toll := false
var knotwork := false
var low_verse := false
var salt_scrip := false
var brine_graft := false
var marlin_spike := false
var fathomsong := false
var pearl_graft := false
var oyster_toll := false
var silt_press := false
var watch_bell := false
var hull_pitch := false
var knot_refuge := false
var grommets_due := false
var sheave_toll := false
var bilge_bond := false
var rigging_rites := false
var mudlarks_due := false
var kelp_tithe := false
var bosuns_chit := false
var deck_psalm := false
var rope_tackle := false
var murk_purse := false
var soul_ledger := false
var courts_tally := false
var royal_overlook := false
var crowns_reprieve := false
var crowns_hand := false
var splice_line := false
var rigging_rest := false
var hull_count := false
var capstan_oil := false
var sheet_bend := false
var crews_grog := false
var bosuns_ration := false
var second_verse := false
var chorus_deep := false
var harbor_verse := false
var wake_verse := false
var requiem_note := false
var dirge_half := false
var leech_bond := false
var keelwind := false
var murk_vision := false
var silt_draught := false
var drowned_mercy := false
var rivers_tithe := false
var boatswain_call := false
var court_fool := false
var bilge_ballad := false
var salt_lullaby := false
var coil_chit := false
var rope_allowance := false
var regal_favor := false
var drift_verse := false
var pearl_octave := false
var undertow_aria := false
var wake_chant := false
var salt_aria := false
var pilgrims_purse := false
var crows_toll := false
var crowns_decree := false
var melody_ledger := false
var pale_scrip := false
var rat_ration := false
var powder_toll := false
var shoal_spd := false
var dead_weight := false
var hymn_delta := 0.0
var thick_delta := 0.0
var slack_delta := 0.0
var ll_delta := 0.0
var rotgut_drunk := false
var drift_line := false
var pale_drunk := false
var deep_current := false
var dread_tide := false
var starved_deep := false
var choir := false
var shell_game := false
var legion_omen := false
var wolf_omen := false
var ashborn := false
var lonecrown := false
var lc_delta := 0.0
var tf_delta := 0.0
var wolf_n := 0
var omen_count := 0
var wellread := false
var tide_lends := false
var pearl_fever := false
var muckraker := false
var abyssal_patience := false
var bone_market := false
var waxpale := false
var vessel := false
var skeleton_crew := false
var rolling_fog := false
var deep_pockets_oath := false
var oarsworn := false
var dark_water := false
var umbral_tide := false
var moonwrit := false
var barnacle_sense := false
var brine_callus := false
var bosun_ledger := false
var urnsworn := false
var full_chart := false
var long_wake := false
var dead_lantern := false
var hull_song := false
var salt_ledger := false
var wide_satchel := false
var slow_clock := false
var deck_alms := false
var loose_ballast := false
var black_sails := false
var grim_charter := false
var martyrs_oath := false
var slim_pickings := false
var whale_lung := false
var sworn_hull := false
var old_salt := false
var full_sails := false
var long_oars := false
var deep_draft := false
var high_water := false
var ballast_oath := false
var thin_hull := false
var cold_toll := false
var oarlocks := false
var omen_cd_add := 0.0
var final_verse := false
var cradle_deep := false
var undertow := false
var storm_lull := false
var sea_burial := false
var deep_breath := false
var dash_fuel := false
var powder_keg := 0
var bloodtide_t := 0.0
var iron_gullet := false
var murk_fed := false
var crew_oath := false
var lantern_oil := false
var bloodwarm := false
var salt_shear := false
var song_rust := false
var gangway := false
var splice_kills := 0
var timber_shiver := false
var hull_bonus := false
var court_summons := false
var kneel_not := false
var deadweight := false
var undertow_grip := false
var lookout := false
var bosun_mark := false
var callus_on := false
var salt_purse := false
var sirensong_deal := false
var salt_tithe := false
var keel_prayer := false
var crown_oath := false
var pinch_n := 0
var abyss_n := 0
var lore_run := 0
var disarm_run := 0
var thrall_n := 0
var disarm_floor := 0
var events_run := {}
var riptide_n := 0
var steps_done_run := 0
var urns_run := 0
var urns_floor := 0
var clams_run := 0
var rooms_floor := 0
var still_t := 0.0
var _rope_active := false
var _pilot_on := false
var rope_kills := 0
var harpoon_n := 0
var net_n := 0
var ledger_n := 0
var moonpool_run := 0
var shellshield_used := false
var tithe_armor := 0.0
var tide_kills := 0
var floor_kills := 0
var knot_n := 0
var reliquary_wisps := 0
var omen_refusals := 0
var bargainer := false
var bargain_used := false
var shrine_kind := 0
var bounty_ref: Enemy = null
var bounty_epic := false
var ferry_skip := false
var ferry_extra := 0
var _ferry_used := false
var lanterns: Array = []
var lantern_healed := 0.0
var lantern_touched := false
var gravetide := false
var mudlark := false
var crows_share := false
var penny_floor := false
var netgain_n := 0
var blood_drawn := false
var skill_used_floor := false
var skills_floor := {}
var rooms_cleared := 0
var flawless_run := 0
var well_rolls := 0
var well_rolls_run := 0
var storm_t := 0.0
var nemesis_spawned := false # musuh yang membunuhmu run lalu — kembali lebih kuat
var nemesis_warned := false # nemesis story beat — 1だけ
var toast_tween: Tween = null

# polish r2: pause, ringkasan run, transisi fade, juice vfx
var paused_ui := false
var kills_run := 0
var revives_run := 0
var run_souls_start := 0
var last_stand_kills := 0
var vials := 1
var run_time := 0.0
var floor_t := 0.0
var combo_max := 0
var fade_rect: ColorRect = null
var pause_panel: PanelContainer = null
var vign: TextureRect = null
var vign_tween: Tween = null
var prev_hp := -1.0
var floor_hurt := false
var trial_atk_t := 0.0

# prestasi lintas run (definisi di stats.gd: ACH_DEF) + varian bos per 5 lantai
const BOSS_TIERS := [
	{"name": "BONE KING", "tint": Color(1.05, 1.05, 1.05),
		"warn": "Careful — the Bone King lurks at the end of this corridor. If the ground shakes red, GET OUT.",
		"taunt": "YOU AGAIN, LITTLE FRAGRANT ONE. I'll add your bones to my throne.",
		"banter": ["RATTLE ME HARDER, WORM.", "THE THRONE... TREMBLES?", "I WILL NOT FALL TO A WORM!"],
		"death": "...impossible... my throne... cracking..."},
	{"name": "EMBER KING", "tint": Color(1.4, 0.65, 0.4),
		"warn": "He rose from his own ashes — the Ember King burns through this floor.",
		"taunt": "YOU AGAIN? I'LL BURN THE FLESH OFF YOUR BONES THIS TIME.",
		"banter": ["YOUR FLESH SMELLS DONE ALREADY.", "ASHES... I NEED NO FLESH TO KILL YOU.", "BURN... EVERYTHING MUST BURN!"],
		"death": "...embers... dying... again..."},
	{"name": "FROST KING", "tint": Color(0.55, 0.85, 1.45),
		"warn": "His bones turned to ice — the Frost King chills the air itself.",
		"taunt": "BONES DON'T SHIVER. YOURS WILL, WHEN I FREEZE THEM SOLID.",
		"banter": ["FEEL YOUR BLOOD TURN TO ICE?", "COLD... I AM THE COLD ITSELF!", "THE FROST... TAKES US BOTH!"],
		"death": "...cold... so cold... the throne... melts..."},
	{"name": "FERAL KING", "tint": Color(0.65, 1.35, 0.55),
		"warn": "Last warning — the Feral King has lost all patience. And all mercy.",
		"taunt": "THE THRONE IS MINE FOREVER. I'LL WEAR YOUR SKULL AS A CROWN.",
		"banter": ["RAAAGH! HOLD STILL, PREY!", "NO — NO PREY BITES THE KING!", "GRRRAAAH — DIE WITH ME THEN!"],
		"death": "...no... I was... ETERNAL..."},
]
var boss_name := "BONE KING"
var atk_held := false
var atk_hold_t := 0.0
var atk_charged := false
var tip_l: Label = null

const BESTIARY := {
	"chaser": ["Skeleton Chaser", "The King's runts — countless, tireless, hungry."],
	"rogue": ["Shadow Rogue", "They learned to dash before they learned to die."],
	"mage": ["Bone Mage", "Spells older than the kingdom, hurled from the dark."],
	"brute": ["Bone Brute", "Built like a siege engine — hits like one too."],
	"bomber": ["Boom Bones", "A walking funeral pyre. Don't let it reach you."],
	"archer": ["Skeletal Archer", "Fast fingers, faster arrows — from three tiles away."],
	"necromancer": ["The Necromancer", "Death is a door he keeps propping open. Kill him first."],
	"crawler": ["Crypt Crawler", "Small, quick, and never alone."],
	"gaoler": ["The Gaoler", "A faceless warden. His blows cage you where you stand — dash out of them."],
	"sentinel": ["Bone Sentinel", "A war-archer fused to the floor — it never moves, it only kills."],
	"shade": ["The Shade", "A knight's ghost that refused the grave — it blinks to your blind spot."],
	"hexer": ["The Hex Priest", "A curse-gnawed choirboy — his bolt seals your skills for a breath."],
	"spiker": ["Spiked Cadaver", "Wrapped in grave-iron thorns — every cut you land cuts you back."],
	"lurker": ["The Dweller", "It waits in the dark wearing invisibility — you will only ever see its lunge."],
	"golem": ["The Bone Golem", "A wall of fused dead — its fists shake the floor itself."],
	"maiden": ["The Wailing Maiden", "Kill her and her scream wakes every sleeper in the room."],
	"revenant": ["The Revenant", "His tombstone must be shattered, or he rises again — once."],
	"shieldbearer": ["The Shieldbearer", "His gate-bone shield turns your steel aside — strike from behind."],
	"herald": ["The Herald", "His war-cry hardens every gravemate in the room — silence him first."],
	"batterer": ["The Batterer", "His maul-arm throws you into walls — watch the wind-up, sidestep the swing."],
	"duelist": ["The Pale Duelist", "A ghost-blade that honors the old fencing forms — it lunges first, always."],
	"hound": ["The Bone Hound", "All ribs and hunger — it hunts the marrow it lost."],
	"moth": ["The Soul Moth", "A lantern that learned to fly — it carries a soul to whoever kills it."],
	"orator": ["The Grave Orator", "It sings the dead awake — every chant makes the room hit harder."],
	"crowned": ["The Crowned", "A fallen paladin — foes near it shrug off a quarter of your blows."],
	"tither": ["The Tithing", "A soul-collector — its strikes skim the souls from your purse."],
	"drowned": ["The Drowned One", "A reliquary corpse — souls leak from it as it walks, and pours out when it dies."],
	"keelhound": ["The Keelhound", "A drowned hunting dog — faster than its graveyard kin, and it bites the purse, not the arm."],
	"maw": ["The Barnacle Maw", "A clam grown monstrous on drowned souls — it can't chase, but it spits pearl-shrapnel across the room."],
	"siren": ["The Void Siren", "A singer of the black — her note hooks your bones and drags you to her mouth."],
	"gargoyle": ["The Pearl Gargoyle", "A temple guardian fused to a giant clam — slow, patient, and hits like a falling gate."],
	"digger": ["The Gravedigger", "It digs where the dead should lie — and where you now stand."],
	"bilge_witch": ["The Bilge Witch", "A drowned crone whose bolts carry the cold of the deep — her touch numbs."],
	"keelbeak": ["The Keelbeak", "A gull-bone thing that stabs and hops clear — it never stays where it strikes."],
	"rust_jaw": ["The Rust Jaw", "A corrosion-mouthed corpse — every bite pits your steel and dulls your edge."],
	"salt_herald": ["The Salt Herald", "A swollen mound of brine-bone — cut it down and the salt spawns its get."],
	"hull_widow": ["The Hull Widow", "She weaves the deck into a snare — her bite roots your feet where you stand."],
	"deck_gunner": ["The Deck Gunner", "A powder-skeleton with twin-loaded sinews — two shots come, never one."],
	"chum_gnawer": ["The Chum Gnawer", "It chews what it catches — every bite knits its own wounds. Cut it down fast or it never bleeds out."],
	"reef_caller": ["The Reef Caller", "A singing lump of living coral — each pulse makes the dead hit harder. Silence it first."],
	"rotting_bride": ["The Rotting Bride", "She reels off a widowed wedding song — every verse makes the dead dance faster. Kill her first."],
	"salt_cantor": ["The Salt Cantor", "Its call wakes every sleeper in the room at once — silence it before the chorus answers."],
	"kelter_husk": ["The Kelter Husk", "Its barnacle shell swallows the first blow whole — crack it, then kill what's inside."],
	"deck_brood": ["The Deck Brood", "Kill it and the brood inside spills out — two moths, still hungry."],
	"rust_fanatic": ["The Rust Fanatic", "Its filings pit your steel — each blow dulls your edge for a while."],
	"chimehead": ["The Chimehead", "Its bell tolls the room awake — silence it before the whole floor hears."],
	"bilge_sprite": ["The Bilge Sprite", "Fast, greedy fingers — every touch skims a soul from your purse."],
	"salt_leech": ["The Salt Leech", "It drinks what it cuts — every wound it deals mends its own."],
	"gutter_chaplain": ["The Gutter Chaplain", "He reads the drowned liturgy — stay close and his words take the edge off your arm."],
	"bell_warden": ["The Bell Warden", "He keeps the drowned bells — every toll chills the blood in your legs."],
	"hookfin": ["The Hookfin", "A spear-fisher of the flooded decks — his barb drags you onto his friends' blades."],
	"wrack_eel": ["The Wrack Eel", "A lash of cold muscle — it strikes across the room in a blink."],
	"rust_saw": ["The Rust Saw", "A blade gone to rot and tetanus — its wounds fester long after the cut."],
	"bell_ringer": ["The Bell Ringer", "His bell knits the dead back together — silence the tolling first."],
	"moorling": ["The Moorling", "A sodden thing of the moor — it lobs what the water gave it."],
	"keel_mastiff": ["The Keel Mastiff", "A hound of splinters and rope — it lunges when the pack bays."],
	"bilge_fury": ["Bilge Fury", "A crew-hand who raged one breath too long — the madder it bleeds, the faster it swings."],
	"bilge_cantor": ["Bilge Cantor", "It hums the ship's old tempo — and every drowned thing around it keeps double time."],
	"tide_bailiff": ["Tide Bailiff", "It collects the sea's arrears — every blow seizes a soul."],
	"salt_skimmer": ["Salt Skimmer", "It planes across the foam faster than a thrown blade."],
	"brine_monk": ["Brine Monk", "Its open-palm rite saps the strength from your arm."],
	"deck_rigger": ["Deck Rigger", "Its hooked line reaches farther than your blade — step inside the swing."],
	"gunnel_fiend": ["Gunnel Fiend", "It claws along the rail faster than it walks — when it coils, it's already midair."],
	"pale_lantern": ["Pale Lantern", "A wick of drowned light walking a dead sailor's frame — snuff it and every shadow in the room flinches."],
	"siren_thrall": ["Siren Thrall", "A sailor the song kept — freed of it only by the blade, and what's left rises as a wisp."],
	"salt_lich": ["The Salt Lich", "A cleric of the drowned church — it reads your shape from afar and posts it a soul."],
	"deck_brute": ["The Deck Brute", "A wall of dead muscle and splinters; it does not hurry, and it does not stop."],
	"salt_eel": ["The Salt Eel", "It knots itself out of the black water and strikes before the coil shows."],
	"quarter_ghost": ["The Quarter Ghost", "A crewman's shade still collecting his share — he takes it from your veins."],
	"fathom_crab": ["The Fathom Crab", "It shelled itself in anchors and anchors' bones — slow, sour, hard to crack."],
	"powder_monkey": ["The Powder Monkey", "It carries a horn of powder and one bad idea — don't be near the fuse."],
	"bilge_rat": ["The Bilge Rat", "It ate the crew that fed it — and kept the teeth."],
	"gunnel_wight": ["The Gunnel Wight", "It pinned the rail to its own spine — every swing carries the ship's weight."],
	"foam_herald": ["The Foam Herald", "It arrives before the wave — a white rush and a rusty edge."],
	"salt_sprite": ["The Salt Sprite", "A crystallized giggle — it skips and spits and is never where you swing."],
	"bilge_smith": ["The Bilge Smith", "Hammer and needle — it mends what the sea broke."],
	"keel_wretch": ["The Keel Wretch", "What was hauled under too many times — barnacled fists, borrowed breath."],
	"foam_wright": ["The Foam Wright", "It plate-welded its bones in sea-spume — slow, stubborn, hard to shove."],
	"deck_wight": ["The Deck Wight", "It crewed the heavy oar too long — now it only knows the swing."],
	"salt_skiff": ["The Salt Skiff", "A skiff that grew legs — it runs the shallows faster than any oar."],
	"lantern_jaw": ["The Lantern Jaw", "A drowned lampman — its jaw still burns for the hunt."],
	"keel_ghost": ["The Keel Ghost", "It walks the keel's line — your blows slide through it like water."],
	"salt_gibbet": ["The Salt Gibbet", "It hangs barbs from its ribs and throws them like a man who ran out of patience."],
	"foamcutter": ["The Foamcutter", "A wake with teeth — it slides sideways through your guard."],
	"gallows_rev": ["The Gallows Revenant", "Hanged twice and walked away from both. It does not hurry — it does not need to."],
	"kelter_fiend": ["The Kelter Fiend", "Salt-blooded and furious — it dashes through your blows and shrugs off every shove."],
	"salvage_rat": ["The Salvage Rat", "A purse on legs — quick, yellow, and gone if you blink. Catch it for the souls."],
	"mireling": ["The Mireling", "A marsh rat grown fat on drowned men's boots — its nip chills the blood."],
	"saltghast": ["The Saltghast", "A ghost blown through with sea-salt — it blinks to your blind side and pours a soul out when felled."],
	"waver": ["The Waver", "A bloated tide-priest — its bolt numbs your arm and your swing goes soft."],
	"weeper": ["The Weeper", "A wailing priest who knits his flock's bones back together. Silence him first."],
	"bone_king": ["The Kings", "One throne, many forms. Every five floors he waits."],
}
const VANE_BIOME := {
	"Catacombs": "I marched these halls a captain, boy. Now I rattle in them.",
	"Ember Crypt": "I burned once. Trust me — the bones complain.",
	"Frozen Deep": "Aldric left me to freeze once. I prefer the sword.",
	"Verdant Ruin": "The Oracle's gardens... she wept the day we walled them in.",
	"The Abyss": "Down here even my chains feel heavier. Stay close.",
	"Marrow Marsh": "A swamp of bone-meal. My company marched past worse.",
	"Sunken Reliquary": "Gold for the taking, boy — the dead don't haggle. But they watch.",
}
const KILLER_NAMES := {
	"chaser": "a Skeleton Chaser", "rogue": "a Shadow Rogue", "mage": "a Bone Mage",
	"brute": "a Bone Brute", "bomber": "a Boom Bones", "archer": "a Skeletal Archer",
	"necromancer": "the Necromancer", "crawler": "a Crypt Crawler", "gaoler": "the Gaoler", "weeper": "the Weeper", "sentinel": "a Bone Sentinel", "shade": "the Shade", "hexer": "the Hex Priest", "spiker": "a Spiked Cadaver", "lurker": "the Dweller", "golem": "the Bone Golem", "maiden": "the Wailing Maiden", "revenant": "the Revenant", "shieldbearer": "the Shieldbearer", "herald": "the Herald", "batterer": "the Batterer", "duelist": "the Pale Duelist", "hound": "a Bone Hound", "moth": "a Soul Moth", "orator": "the Grave Orator", "crowned": "the Crowned", "tither": "the Tithing", "digger": "the Gravedigger", "drowned": "the Drowned One", "keelhound": "a Keelhound", "maw": "a Barnacle Maw", "siren": "the Void Siren", "gargoyle": "a Pearl Gargoyle", "mireling": "a Mireling", "saltghast": "a Saltghast", "waver": "a Waver", "keelbeak": "a Keelbeak", "bilge_witch": "a Bilge Witch", "rust_jaw": "a Rust Jaw", "salt_herald": "a Salt Herald", "hull_widow": "a Hull Widow", "deck_gunner": "a Deck Gunner", "reef_caller": "a Reef Caller", "chum_gnawer": "a Chum Gnawer", "rotting_bride": "a Rotting Bride", "salt_cantor": "a Salt Cantor", "kelter_husk": "a Kelter Husk", "deck_brood": "a Deck Brood", "rust_fanatic": "a Rust Fanatic", "chimehead": "a Chimehead", "bilge_sprite": "a Bilge Sprite", "salt_leech": "a Salt Leech", "gutter_chaplain": "a Gutter Chaplain", "bell_warden": "a Bell Warden", "hookfin": "a Hookfin", "wrack_eel": "a Wrack Eel", "rust_saw": "a Rust Saw",
	"bell_ringer": "a Bell Ringer",
	"moorling": "a Moorling",
	"keel_mastiff": "a Keel Mastiff",
	"salt_lich": "a Salt Lich", "bilge_fury": "a Bilge Fury", "siren_thrall": "a Siren Thrall", "pale_lantern": "a Pale Lantern", "gunnel_fiend": "a Gunnel Fiend", "bilge_cantor": "a Bilge Cantor", "tide_bailiff": "a Tide Bailiff", "salt_skimmer": "a Salt Skimmer", "brine_monk": "a Brine Monk", "deck_rigger": "a Deck Rigger",
	"deck_brute": "a Deck Brute",
	"salt_eel": "a Salt Eel",
	"quarter_ghost": "a Quarter Ghost",
	"fathom_crab": "a Fathom Crab",
	"powder_monkey": "a Powder Monkey",
	"bilge_rat": "a Bilge Rat",
	"gunnel_wight": "a Gunnel Wight",
	"foam_herald": "a Foam Herald",
	"salt_sprite": "a Salt Sprite",
	"bilge_smith": "a Bilge Smith",
	"keel_wretch": "a Keel Wretch",
	"foam_wright": "a Foam Wright",
	"deck_wight": "a Deck Wight",
	"salt_skiff": "a Salt Skiff",
	"lantern_jaw": "a Lantern Jaw",
	"keel_ghost": "a Keel Ghost",
	"salt_gibbet": "a Salt Gibbet",
	"foamcutter": "a Foamcutter",
	"gallows_rev": "a Gallows Revenant",
	"kelter_fiend": "a Kelter Fiend",
	"salvage_rat": "a Salvage Rat",
	"bone_king": "the King himself", "trap": "a hidden trap", "": "the dungeon itself"}
const KILLER_TIPS := {
	"chaser": "Tip: chasers are slow — kite them into a corner and cleave.",
	"rogue": "Tip: rogues dash — dash THROUGH their lunge for a perfect counter.",
	"mage": "Tip: bone mages flinch when hit — rush them before their cast lands.",
	"brute": "Tip: brutes wind up heavy — watch the red flash, then dash away.",
	"bomber": "Tip: bombers detonate on contact — keep moving, let them chase.",
	"archer": "Tip: archers fire from afar — break line-of-sight and flank.",
	"necromancer": "Tip: kill the Necromancer first — his minions never stop rising.",
	"crawler": "Tip: crawlers swarm — a HEAVY attack clears the whole pack.",
	"gaoler": "Tip: the Gaoler's swing roots you — dash THROUGH him instead.",
	"weeper": "Tip: the Weeper heals his flock every few seconds — always cut him down first.",
	"sentinel": "Tip: sentinels never move — bait the bolt, then dash in.",
	"shade": "Tip: the Shade blinks to your flank — keep turning, strike the moment it lands.",
	"hexer": "Tip: the Hex Priest's bolt silences your skills — dodge it or cut him down first.",
	"spiker": "Tip: the Spiked Cadaver's thorns bite back in melee — use skills to kill it from afar.",
	"lurker": "Tip: the Dweller only shows itself at arm's length — clear rooms edge-first.",
	"golem": "Tip: the Bone Golem can't be staggered — never stand in front of its fists.",
	"maiden": "Tip: kill the Wailing Maiden last — her death-scream wakes the whole room.",
	"revenant": "Tip: the Revenant leaves a tombstone — smash it in three seconds or he rises.",
	"shieldbearer": "Tip: the Shieldbearer blocks frontal blows — dash behind him or use skills.",
	"herald": "Tip: kill the Herald before his cry — he sharpens every gravemate in the room.",
	"batterer": "Tip: the Batterer's wind-up is slow — dodge the swing or get thrown into walls.",
	"duelist": "Tip: the Pale Duelist lunges in a straight line — sidestep, then punish the recovery.",
	"hound": "Tip: Bone Hounds dart in quick — thin them early, they are fragile.",
	"moth": "Tip: Soul Moths are harmless lanterns — swat them for the wisp inside.",
	"orator": "Tip: Kill the Orator first — each chant sharpens every blade in the room.",
	"crowned": "Tip: Cut the Crowned down first — while it stands, its allies resist your steel.",
	"tither": "Tip: The Tithing steals souls with every hit — kill it before it robs you.",
	"digger": "Tip: Gravediggers seed the floor with void sigils — move before you commit.",
	"drowned": "Tip: Drowned Ones always cough up a wisp — pop them for free souls.",
	"keelhound": "Tip: Keelhounds snatch a soul every time they bite — put them down first.",
	"maw": "Tip: the Barnacle Maw spits in bursts — dash between volleys and gut it up close.",
	"siren": "Tip: when the Void Siren sings, plant your feet or dash sideways — she reels in what she hooks.",
	"gargoyle": "Tip: the Pearl Gargoyle telegraphs its slam — circle behind, never stand in front.",
	"bilge_witch": "Tip: Bilge Witch bolts chill your blood — dodge them or lose your speed.",
	"keelbeak": "Tip: Keelbeaks hop back after every peck — strike where they land.",
	"rust_jaw": "Tip: Rust Jaw bites corrode your blade — your strikes land softer for a breath. Space them.",
	"deck_gunner": "Tip: the Gunner fires twice in a breath — sidestep the second shot, not just the first.",
	"chum_gnawer": "Tip: the Chum Gnawer heals on every bite — break it in one long flurry.",
	"reef_caller": "Tip: each Reef Caller's song sharpens every blade in the room — silence it before the chorus swells.",
	"rotting_bride": "Tip: the Rotting Bride's reel quickens every dead thing in the room — silence her first.",
	"salt_cantor": "Tip: the Salt Cantor's call wakes the whole room at once — kill it before its chorus answers.",
	"kelter_husk": "Tip: the Kelter Husk's shell eats your first strike — lead with a skill, or swing twice.",
	"deck_brood": "Tip: the Deck Brood bursts into moths on death — kill it at range, or swing through.",
	"rust_fanatic": "Tip: the Rust Fanatic's blows dull your blade — kill it before the pitting sets in.",
	"chimehead": "Tip: the Chimehead's toll wakes every sleeper in earshot — kill it first, quietly.",
	"bilge_sprite": "Tip: the Bilge Sprite skims souls on contact — swat it before it reaches you.",
	"salt_leech": "Tip: the Salt Leech heals off every cut it lands — never trade blows with it.",
	"gutter_chaplain": "Tip: the Gutter Chaplain weakens your arm while his litany reaches you — silence him early.",
	"bell_warden": "Tip: the Bell Warden's toll chills your legs at range — close fast or keep your distance.",
	"hookfin": "Tip: the Hookfin's harpoon hauls you into the melee — sidestep the barb.",
	"wrack_eel": "Tip: the Wrack Eel coils then lunges across the deck — keep circling, never back-pedal.",
	"rust_saw": "Tip: the Rust Saw's blade leaves rot in the wound — end the fight fast or bleed rust.",
	"bell_ringer": "Tip: the Bell Ringer mends his flock with every toll — cut him down first.",
	"moorling": "Tip: the Moorling throws slow, heavy sludge — strafe the lob, don't backpedal.",
	"keel_mastiff": "Tip: the Keel Mastiff lunges — sidestep the leap, don't retreat in a line.",
	"bilge_fury": "Tip: a Bilge Fury swings faster the more you hurt it — kill it quickly or kite the frenzy.",
	"siren_thrall": "Tip: a Siren Thrall dies easy — and leaves a soul wisp where it stood. Free them all.",
	"pale_lantern": "Tip: snuff the Pale Lantern first — its dying flash stuns every foe around you.",
	"gunnel_fiend": "Tip: the Gunnel Fiend coils before it lunges — step sideways and let it sail past.",
	"bilge_cantor": "Tip: the Bilge Cantor quickens every windup near it — silence it before the room turns fast.",
	"tide_bailiff": "Tip: the Tide Bailiff takes a soul with every landed blow — kill it before the purse runs dry.",
	"salt_skimmer": "Tip: the Salt Skimmer skims in fast — swing early, it can't take a hit.",
	"brine_monk": "Tip: the Brine Monk's palm rite weakens your arm — break its litany or trade blows fast.",
	"deck_rigger": "Tip: the Deck Rigger's reach outlasts your guard — close inside its hook or stay clear entirely.",
	"salt_lich": "Tip: Salt Liches telegraph a long windup — close the gap fast or weave between bolts.",
	"deck_brute": "Tip: Deck Brutes barely feel knockback — break their windup with a stun, or never be there when it lands.",
	"salt_eel": "Tip: Salt Eels lunge in a straight bite — sidestep and the coil overshoots.",
	"quarter_ghost": "Tip: the Quarter Ghost drinks your blows — burn him down before he refills.",
	"fathom_crab": "Tip: the Fathom Crab shrugs off shoves — outpace it or crack the shell.",
	"powder_monkey": "Tip: Powder Monkeys burst on death — finish them from a step away.",
	"bilge_rat": "Tip: Bilge Rats come in packs — one good sweep feeds the purse.",
	"gunnel_wight": "Tip: the Gunnel Wight swings slow but ends fights — respect the windup.",
	"foam_herald": "Tip: the Foam Herald lunges past you — turn, don't chase.",
	"salt_sprite": "Tip: the Salt Sprite is brittle but quick — dash INTO it, don't chase it.",
	"bilge_smith": "Tip: the Bilge Smith stitches its pack back together — kill it first.",
	"keel_wretch": "Tip: the Keel Wretch barely staggers — don't brawl, dance around it.",
	"foam_wright": "Tip: the Foam Wright shrugs off shoves — kite it, don't try to push through.",
	"deck_wight": "Tip: the Deck Wight hits like a falling mast — let the swing pass, then answer.",
	"salt_skiff": "Tip: the Salt Skiff is fast but fragile — meet it with wide swings, not chasing feet.",
	"lantern_jaw": "Tip: the Lantern Jaw sees you from far off — expect it early, or cut the lamp out first.",
	"keel_ghost": "Tip: the Keel Ghost cannot be knocked back — space it or burn it down.",
	"salt_gibbet": "Tip: the Salt Gibbet keeps its distance and pelts you — rush it or break its line of sight.",
	"foamcutter": "Tip: the Foamcutter slips your flank mid-swing — let it come to you, then cut the wake.",
	"gallows_rev": "Tip: the Gallows Revenant won't be moved and won't be hurried — circle it, never trade.",
	"kelter_fiend": "Tip: the Kelter Fiend barely feels your knockback — pin it with a stun or cut its charge short.",
	"salvage_rat": "Tip: the Salvage Rat bolts the moment it smells you — corner it or dash, the purse is worth the chase.",
	"hull_widow": "Tip: the Widow's webs root your feet — dash the moment she spits, or cut her down at range.",
	"salt_herald": "Tip: Salt Heralds split when slain — keep a swing ready for the mirelings inside.",
	"mireling": "Tip: Mirelings are quick — dash through them, don't fence them.",
	"saltghast": "Tip: the Saltghast blinks when you close — swing where it lands, not where it was.",
	"waver": "Tip: the Waver's amber bolt numbs your arm — sidestep it or your blade goes dull.",
	"bone_king": "Tip: his slams telegraph red — dash through the shockwave.",
	"trap": "Tip: traps pulse on a rhythm — cross on the off-beat.",
	"": "Tip: blessings, relics and Sir Vane can still turn a doomed run.",
}

const TIPS := [
	"Crimson-glowing elites grant double XP.",
	"Red-eyed chests are mimics — beware.",
	"Dash grants a moment of invincibility.",
	"Dash THROUGH an attack at the last instant — a perfect dodge stuns and counters.",
	"Pausing breaks your combo — keep slashing.",
	"Spirit altars: pick a blessing that fits your build.",
	"Snap Clams hold pearls — disarm them while they sleep for souls.",
	"Floor spikes have a rhythm — learn it before crossing.",
	"An enraged King summons minions — keep your distance.",
	"The Soul Risen relic revives you once.",
	"Hold ATK to slash — release after the button glows for a HEAVY hit.",
	"SIPHON-tagged elites drain your whole combo on hit — kill them first.",
	"VOLATILE elites detonate when they die — finish them from a step away.",
	"When the moon turns red, the dead hunger — and drop more XP.",
	"A chest that gleams brighter is gilded — relics hide inside.",
	"Clear a floor in under 90 seconds for a Sweep Bonus.",
	"Violet sigils snare your feet — dash before the trap bites.",
	"Near death, fury answers — Last Stand adds +25% ATK.",
	"Soul Vials drop from the dead — hold two, drink when it counts.",
	"MOTHER-tagged elites split in two when slain — brace for the brood.",
	"WARDEN-tagged elites root your feet — dash the moment they swing.",
	"FROSTBITE-tagged elites chill your blood — keep your distance until it fades.",
	"Take no damage on a floor for an Untouched tithe of souls.",
	"When the mist turns violet, the dead weep gems — reap them while it lasts.",
	"When the torches die, the dead run faster — finish the floor for the tithe.",
	"A green-gold sigil mends one wound — step on its pulse.",
	"Sleeping traps can be defused by a brave touch — walk over them on the off-beat.",
	"Dread obelisks bleed the living — smash them before they drink you.",
	"A forge that still burns takes souls — feed it and it feeds your blade.",
	"Spiked cadavers bite back — skills and storms kill thorns at range.",
	"THORNED-tagged elites bleed your blade's wielder — strike from range.",
]


func _biome_track() -> String:
	match String(biome["name"]):
		"Ember Crypt":
			return "ember"
		"Frozen Deep":
			return "frozen"
		"Verdant Ruin":
			return "verdant"
		"Marrow Marsh":
			return "marsh"
		"Sunken Reliquary":
			return "reliquary"
		"The Abyss":
			return "frozen"
	return "dungeon"


func _boss_tier() -> Dictionary:
	# final run: lantai 25 = wujud sejati Bone King
	if Stats.floor_num >= 25:
		return {"name": "THE UNDYING KING", "tint": Color(1.5, 0.3, 0.7),
			"warn": "This is his deepest hall — the throne beneath all thrones. End this, Kael.",
			"taunt": "I HAVE WORN A THOUSAND CROWNS. YOURS WILL BE THE FINEST.",
			"banter": ["I HAVE DIED A THOUSAND DEATHS. YOURS IS NEXT.", "THE CROWN... WILL NOT... FALL!", "DEATH ITSELF WILL DRAG YOU DOWN!"],
			"death": "...the throne... is yours now... Kael..."}
	return BOSS_TIERS[(Stats.floor_num / 5 - 1) % BOSS_TIERS.size()]


func _ach(id: String) -> void:
	if Stats.ach.get(id, false):
		return
	Stats.ach[id] = true
	Stats.save_game()
	_lvl_banner("◆ ACHIEVEMENT — " + String(Stats.ACH_DEF[id]))
	Sfx.play("quest")

# v5: boss + quest + kombo + altar + peti mimic + dialog + minimap
var boss_ref = null
var quest_steps: Array = []
var quest_idx := 0
var quest_counts := {}
var combo := 0
var combo_t := 0.0
var rampage_n := 0
var rampage_t := -9.0
var mimic_pending := false
var shrine_used := false
var shrine_count := 0
var blessings_run := 0
var deals_run := 0
var _quest_refresh_once := false
var dice_wins := 0
var urn_count := 0
var salvage_ct := 0
var keelh_floor := 0
var lucky_net := false
var deeproot := false
var still_waters := false
var bone_veil := false
var veil_used := false
var _souls_seen := 0
var _souls_net := 0
var dlg: DialogueUI = null
var dlg_pending_choice := -1
var oracle_bargained := false # Oracle's Bargain: sekali per run
var mahzan_met := 0 # kunjungan Mahzan dalam run ini — dialognya berevolusi
var map_dots: Array = []
var map_room_rects: Dictionary = {}
var discovered: Dictionary = {}
var map_t := 0.0

# gerbang / ruangan
var gates := {}
var current_room := -1

# skill
var skill_cd := {"dash": 0.0, "whirl": 0.0, "thunder": 0.0, "warcry": 0.0, "nova": 0.0, "judge": 0.0, "sunder": 0.0, "chains": 0.0, "storm": 0.0, "mend": 0.0, "rites": 0.0, "seismic": 0.0, "kingsfall": 0.0, "lance": 0.0, "gravestep": 0.0, "tidecall": 0.0, "snapjaw": 0.0, "graveseal": 0.0, "riptide": 0.0, "soultithe": 0.0, "anchordrop": 0.0, "soulfall": 0.0, "keelsplit": 0.0, "bloodtide": 0.0, "sealegs": 0.0, "deadreckon": 0.0, "becalm": 0.0, "irontide": 0.0, "dragline": 0.0, "deadlight": 0.0, "broadside": 0.0, "fogsong": 0.0, "saltbomb": 0.0, "deadweight": 0.0, "keelram": 0.0, "hullsplinter": 0.0, "crowsdive": 0.0, "salvagehook": 0.0, "riptidesnare": 0.0, "saltward": 0.0, "bilgesnare": 0.0, "warpaint": 0.0, "brinelash": 0.0, "ghostnet": 0.0, "saltmaw": 0.0, "keelsplitter": 0.0, "deckrupture": 0.0, "deathknell": 0.0, "tidesnatch": 0.0, "kingstoll": 0.0, "chumtoss": 0.0, "netcast": 0.0, "brinevolley": 0.0, "saltwake": 0.0, "choruscall": 0.0, "deckwash": 0.0, "hullkneel": 0.0}
var skill_ui := {}

# tutorial
var tut_active := false
var tut_step := 0
var moved_accum := 0.0
var tut_last_pos := Vector3.ZERO
var quest_moved := 0.0
var quest_last_p := Vector3.ZERO
var shrine_ref = null


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
		elif a.begins_with("--seed="):
			seed_val = int(a.trim_prefix("--seed="))
	rng.seed = seed_val * 7919 + 13
	dungeon_tex = load(DUNGEON + "dungeon_texture.png")
	skeleton_tex = load(CHARS + "skeleton_texture.png")
	Sfx.set_volume(Stats.volume)
	_setup_world()
	_apply_quality()
	_build_ui()
	if Stats.pending_restore and Stats.restore_run():
		print("LANJUTKAN run lantai=", Stats.floor_num)
	else:
		Stats.reset_run()
		_reset_run_state()
		kills_run = 0
		var purse_n: int = int(Stats.meta.get("purse", 0))
		if purse_n > 0:
			Stats.souls += purse_n * 3
		run_souls_start = Stats.souls
		last_stand_kills = 0
		vials = 1
		run_time = 0.0
		combo_max = 0
		mahzan_met = 0
		vane_floors = 0
	Stats.pending_restore = false
	Stats.runs += 1
	for v in Stats.meta.values():
		if int(v) > 0:
			_ach("soul1")
			break
	Stats.save_game()
	Stats.xp_changed.connect(_update_xp)
	Stats.leveled_up.connect(_on_leveled_up)
	Stats.relics_changed.connect(_rebuild_chips)
	_new_run(seed_val)
	_fade_to(0.0, 0.6)
	if autotest:
		_run_autotest()


# ---------------- world ----------------

func _setup_world() -> void:
	sun = DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.shadow_enabled = true

	var we := WorldEnvironment.new()
	env = Environment.new()
	we.environment = env
	add_child(we)
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.1
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.07

	cam = Camera3D.new()
	add_child(cam)
	cam.fov = 42.0
	cam.current = true
	cam.position = Vector3(6, 12, 10)


func _apply_quality() -> void:
	var q := Stats.quality
	if q == -1:
		q = 0 if OS.has_feature("android") else 1
	low_quality = q == 0
	sun.shadow_enabled = not low_quality
	env.glow_enabled = not low_quality
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low_quality else Viewport.MSAA_2X
	get_viewport().scaling_3d_scale = 0.85 if low_quality else 1.0
	print("KUALITAS=", "hemat" if low_quality else "indah")


func _apply_biome() -> void:
	env.background_color = biome["bg"]
	env.fog_density = biome["fog_d"]
	env.fog_light_color = biome["fog"]
	env.ambient_light_color = biome["ambient"]
	sun.light_color = biome["sun"]
	sun.light_energy = 0.9
	if blood_moon:
		env.background_color = Color(0.07, 0.004, 0.008)
		env.fog_density = float(biome["fog_d"]) * 1.3
		env.fog_light_color = Color(0.2, 0.015, 0.025)
		env.ambient_light_color = Color(0.5, 0.09, 0.11)
		sun.light_color = Color(1.0, 0.32, 0.25)
		sun.light_energy = 1.0
	elif soul_rush:
		env.background_color = Color(0.05, 0.03, 0.1)
		env.fog_density = float(biome["fog_d"]) * 1.2
		env.fog_light_color = Color(0.14, 0.08, 0.3)
		env.ambient_light_color = Color(0.5, 0.3, 0.85)
		sun.light_color = Color(0.75, 0.5, 1.0)
		sun.light_energy = 1.0
	elif fading_light:
		env.background_color = Color(0.02, 0.02, 0.05)
		env.fog_density = float(biome["fog_d"]) * 1.5
		env.fog_light_color = Color(0.03, 0.04, 0.08)
		env.ambient_light_color = Color(0.25, 0.28, 0.4)
		sun.light_color = Color(0.5, 0.55, 0.8)
		sun.light_energy = 0.55
	elif echoing:
		env.fog_light_color = Color(0.1, 0.16, 0.22)
		env.ambient_light_color = Color(0.4, 0.55, 0.7)
		sun.light_color = Color(0.55, 0.8, 1.0)
		sun.light_energy = 1.1
	elif storm_cellar:
		env.fog_light_color = Color(0.08, 0.07, 0.18)
		env.ambient_light_color = Color(0.3, 0.28, 0.6)
		sun.light_color = Color(0.6, 0.55, 1.15)
		sun.light_energy = 1.05
	elif gilded_tides:
		env.fog_light_color = Color(0.16, 0.12, 0.05)
		env.ambient_light_color = Color(0.65, 0.5, 0.22)
		sun.light_color = Color(1.2, 0.95, 0.55)
		sun.light_energy = 1.15
	elif soul_drift:
		env.fog_light_color = Color(0.05, 0.14, 0.12)
		env.ambient_light_color = Color(0.25, 0.6, 0.5)
		sun.light_color = Color(0.5, 1.0, 0.85)
		sun.light_energy = 1.0
	elif grave_hunger:
		env.fog_light_color = Color(0.1, 0.09, 0.14)
		env.ambient_light_color = Color(0.45, 0.4, 0.65)
	elif giant_hall:
		env.fog_light_color = Color(0.14, 0.11, 0.08)
		env.ambient_light_color = Color(0.6, 0.45, 0.3)
	elif shrouded:
		env.fog_density = float(biome["fog_d"]) * 1.5
		env.fog_light_color = Color(0.1, 0.11, 0.13)
		env.ambient_light_color = Color(0.3, 0.33, 0.42)
		sun.light_energy = 0.6
		sun.light_color = Color(0.7, 0.6, 1.05)
	elif ossuary:
		env.fog_light_color = Color(0.13, 0.12, 0.09)
		env.ambient_light_color = Color(0.5, 0.46, 0.35)
	elif mirror_hall:
		env.fog_light_color = Color(0.12, 0.14, 0.22)
		env.ambient_light_color = Color(0.4, 0.46, 0.62)
	elif ashfall:
		env.fog_light_color = Color(0.16, 0.14, 0.12)
		env.ambient_light_color = Color(0.55, 0.5, 0.44)
		sun.light_color = Color(0.95, 0.85, 0.6)
		sun.light_energy = 1.05
	elif hungry_walls:
		env.fog_light_color = Color(0.2, 0.1, 0.08)
		env.ambient_light_color = Color(0.5, 0.38, 0.3)
		sun.light_color = Color(0.9, 0.6, 0.45)
		sun.light_energy = 1.0
	elif candlelit:
		env.fog_light_color = Color(0.3, 0.22, 0.12)
		env.ambient_light_color = Color(0.7, 0.6, 0.42)
		sun.light_color = Color(1.0, 0.85, 0.55)
		sun.light_energy = 1.3
	elif verdant:
		env.fog_light_color = Color(0.1, 0.2, 0.1)
		env.ambient_light_color = Color(0.4, 0.6, 0.4)
		sun.light_color = Color(0.75, 1.0, 0.7)
		sun.light_energy = 1.1
	elif bone_chorus:
		env.fog_light_color = Color(0.2, 0.12, 0.22)
		env.ambient_light_color = Color(0.55, 0.4, 0.55)
		sun.light_color = Color(0.9, 0.7, 0.95)
		sun.light_energy = 1.0
	elif wolfsbane:
		env.fog_light_color = Color(0.12, 0.1, 0.16)
		env.ambient_light_color = Color(0.4, 0.4, 0.55)
		sun.light_color = Color(0.7, 0.75, 0.95)
		sun.light_energy = 0.85
	elif thin_veil:
		env.fog_light_color = Color(0.15, 0.05, 0.2)
		env.ambient_light_color = Color(0.55, 0.3, 0.65)
		sun.light_color = Color(0.9, 0.55, 1.1)
		sun.light_energy = 1.0
	elif low_water:
		env.fog_light_color = Color(0.05, 0.18, 0.2)
		env.ambient_light_color = Color(0.35, 0.6, 0.65)
		sun.light_color = Color(0.4, 0.8, 0.85)
		sun.light_energy = 0.9
	elif drift_tide:
		env.fog_light_color = Color(0.03, 0.14, 0.22)
		env.ambient_light_color = Color(0.25, 0.5, 0.75)
		sun.light_color = Color(0.3, 0.65, 0.95)
		sun.light_energy = 0.85
	elif soul_swarm:
		env.fog_light_color = Color(0.06, 0.1, 0.16)
		env.ambient_light_color = Color(0.45, 0.55, 0.9)
		sun.light_color = Color(0.55, 0.65, 1.0)
		sun.light_energy = 0.9
	elif gauntlet:
		env.fog_light_color = Color(0.14, 0.08, 0.1)
		env.ambient_light_color = Color(0.75, 0.5, 0.4)
		sun.light_color = Color(0.95, 0.6, 0.45)
		sun.light_energy = 0.9
	elif brisk:
		env.fog_light_color = Color(0.08, 0.12, 0.1)
		env.ambient_light_color = Color(0.5, 0.85, 0.65)
		sun.light_color = Color(0.55, 0.95, 0.7)
		sun.light_energy = 0.95
	elif shoal_tide:
		env.fog_light_color = Color(0.1, 0.12, 0.14)
		env.ambient_light_color = Color(0.6, 0.75, 0.9)
		sun.light_color = Color(0.65, 0.8, 0.98)
		sun.light_energy = 0.9
	elif salvage_tide:
		env.fog_light_color = Color(0.09, 0.1, 0.12)
		env.ambient_light_color = Color(0.85, 0.75, 0.5)
		sun.light_color = Color(0.95, 0.85, 0.6)
		sun.light_energy = 0.9
	elif gale_tide:
		env.fog_light_color = Color(0.12, 0.14, 0.15)
		env.ambient_light_color = Color(0.75, 0.8, 0.75)
		sun.light_color = Color(0.8, 0.9, 0.85)
		sun.light_energy = 1.05
	elif mercy_tide:
		env.fog_light_color = Color(0.55, 0.78, 0.8)
		env.ambient_light_color = Color(0.6, 0.75, 0.8)
		sun.light_energy = 0.95
	elif eel_tide:
		env.fog_light_color = Color(0.35, 0.6, 0.5)
		env.ambient_light_color = Color(0.4, 0.65, 0.55)
		sun.light_energy = 0.9
	elif swell_tide:
		env.fog_light_color = Color(0.3, 0.4, 0.6)
		env.ambient_light_color = Color(0.35, 0.45, 0.65)
		sun.light_energy = 0.9
	elif kelp_bed:
		env.fog_light_color = Color(0.25, 0.5, 0.3)
		env.ambient_light_color = Color(0.3, 0.55, 0.35)
		sun.light_energy = 0.95
	elif barnacle_bloom:
		env.fog_light_color = Color(0.5, 0.55, 0.4)
		env.ambient_light_color = Color(0.55, 0.6, 0.45)
		sun.light_energy = 0.95
	elif sodden:
		env.fog_light_color = Color(0.35, 0.4, 0.5)
		env.ambient_light_color = Color(0.4, 0.45, 0.55)
		sun.light_energy = 0.85
	elif bile_tide:
		env.fog_light_color = Color(0.4, 0.5, 0.3)
		env.ambient_light_color = Color(0.45, 0.55, 0.35)
		sun.light_energy = 0.9
	elif mire_hollow:
		env.fog_light_color = Color(0.45, 0.4, 0.3)
		env.ambient_light_color = Color(0.5, 0.45, 0.35)
		sun.light_energy = 0.8
	elif dark_lantern:
		env.fog_light_color = Color(0.25, 0.25, 0.35)
		env.ambient_light_color = Color(0.3, 0.3, 0.4)
		sun.light_energy = 0.6
	elif halfwreck:
		env.fog_light_color = Color(0.5, 0.45, 0.35)
		env.ambient_light_color = Color(0.55, 0.5, 0.4)
		sun.light_energy = 0.95
	elif merchant_tide:
		env.fog_light_color = Color(0.45, 0.55, 0.45)
		env.ambient_light_color = Color(0.5, 0.6, 0.5)
		sun.light_energy = 1.0
	elif hungry_urns:
		env.fog_light_color = Color(0.6, 0.5, 0.3)
		env.ambient_light_color = Color(0.65, 0.55, 0.35)
		sun.light_energy = 0.9
	elif bilge_run:
		env.fog_light_color = Color(0.35, 0.3, 0.25)
		env.ambient_light_color = Color(0.4, 0.35, 0.3)
		sun.light_energy = 0.75
	elif pale_squall:
		env.fog_light_color = Color(0.6, 0.65, 0.75)
		env.ambient_light_color = Color(0.65, 0.7, 0.8)
		sun.light_energy = 1.05
	elif soul_flush:
		env.fog_light_color = Color(0.5, 0.7, 0.6)
		env.ambient_light_color = Color(0.55, 0.75, 0.65)
		sun.light_energy = 0.95
	elif black_calm:
		env.fog_light_color = Color(0.2, 0.25, 0.35)
		env.ambient_light_color = Color(0.3, 0.35, 0.5)
		sun.light_energy = 0.7
	elif gun_smoke:
		env.fog_light_color = Color(0.45, 0.4, 0.35)
		env.ambient_light_color = Color(0.5, 0.45, 0.4)
		sun.light_energy = 0.9
	elif greedy_tide:
		env.fog_light_color = Color(0.6, 0.55, 0.3)
		env.ambient_light_color = Color(0.65, 0.6, 0.35)
		sun.light_energy = 1.0
	elif drift_wreck:
		env.fog_light_color = Color(0.45, 0.4, 0.3)
		env.ambient_light_color = Color(0.5, 0.45, 0.35)
		sun.light_energy = 0.9
	elif long_watch:
		env.fog_light_color = Color(0.3, 0.4, 0.45)
		env.ambient_light_color = Color(0.35, 0.45, 0.5)
		sun.light_energy = 0.85
	elif salted_deck:
		env.fog_light_color = Color(0.5, 0.5, 0.55)
		env.ambient_light_color = Color(0.55, 0.55, 0.6)
		sun.light_energy = 0.95
	elif crows_tide:
		env.fog_light_color = Color(0.4, 0.7, 0.5)
		env.ambient_light_color = Color(0.45, 0.75, 0.55)
		sun.light_energy = 0.9
	elif long_night:
		env.fog_light_color = Color(0.15, 0.2, 0.3)
		env.ambient_light_color = Color(0.2, 0.25, 0.35)
		sun.light_energy = 0.5
	elif halfway_dead:
		env.fog_light_color = Color(0.55, 0.5, 0.4)
	elif rich_vein:
		env.fog_light_color = Color(0.7, 0.6, 0.3)
		env.ambient_light_color = Color(0.75, 0.65, 0.4)
		sun.light_energy = 1.0
	elif wraiths_due:
		env.fog_light_color = Color(0.5, 0.62, 0.78)
		env.ambient_light_color = Color(0.55, 0.7, 0.85)
	elif pale_lantern_ev:
		env.fog_light_color = Color(0.65, 0.75, 0.5)
		env.ambient_light_color = Color(0.7, 0.8, 0.55)
	elif saltgrave_ev:
		env.fog_light_color = Color(0.75, 0.7, 0.55)
		env.ambient_light_color = Color(0.8, 0.75, 0.6)
	elif leeward_ev:
		env.fog_light_color = Color(0.55, 0.7, 0.7)
		env.ambient_light_color = Color(0.6, 0.8, 0.8)
	elif brine_smoke:
		env.fog_light_color = Color(0.45, 0.5, 0.5)
		env.ambient_light_color = Color(0.5, 0.6, 0.6)
	elif crowns_ransom:
		env.fog_light_color = Color(0.6, 0.5, 0.7)
		env.ambient_light_color = Color(0.65, 0.55, 0.8)
	elif bilge_strike:
		env.fog_light_color = Color(0.6, 0.45, 0.35)
		env.ambient_light_color = Color(0.7, 0.5, 0.4)
	elif full_draught:
		env.fog_light_color = Color(0.35, 0.55, 0.5)
		env.ambient_light_color = Color(0.4, 0.65, 0.6)
	elif salt_front:
		env.fog_light_color = Color(0.55, 0.5, 0.45)
		env.ambient_light_color = Color(0.6, 0.55, 0.5)
	elif cold_snap:
		env.fog_light_color = Color(0.5, 0.65, 0.85)
		env.ambient_light_color = Color(0.55, 0.7, 0.9)
	elif full_moon:
		env.fog_light_color = Color(0.75, 0.75, 0.9)
		env.ambient_light_color = Color(0.8, 0.8, 0.95)
	elif gunners_luck:
		env.fog_light_color = Color(0.6, 0.55, 0.4)
		env.ambient_light_color = Color(0.65, 0.6, 0.45)
	elif shallow_graves:
		env.fog_light_color = Color(0.5, 0.45, 0.4)
		env.ambient_light_color = Color(0.55, 0.5, 0.45)
	elif wailing_wind:
		env.fog_light_color = Color(0.65, 0.7, 0.75)
		env.ambient_light_color = Color(0.7, 0.75, 0.8)
	elif balmy_sea:
		env.fog_light_color = Color(0.75, 0.72, 0.55)
		env.ambient_light_color = Color(0.8, 0.77, 0.6)
	elif rust_storm:
		env.fog_light_color = Color(0.8, 0.45, 0.3)
		env.ambient_light_color = Color(0.85, 0.5, 0.35)
	elif ember_wake:
		env.fog_light_color = Color(0.9, 0.5, 0.25)
		env.ambient_light_color = Color(0.95, 0.55, 0.3)
	elif saltsick:
		env.fog_light_color = Color(0.55, 0.6, 0.5)
		env.ambient_light_color = Color(0.6, 0.65, 0.55)
	elif gallows_tide:
		env.fog_light_color = Color(0.5, 0.42, 0.3)
		env.ambient_light_color = Color(0.55, 0.45, 0.32)
	elif pilot_light:
		env.fog_light_color = Color(0.35, 0.55, 0.8)
		env.ambient_light_color = Color(0.45, 0.65, 0.9)
	elif widdershins:
		env.fog_light_color = Color(0.6, 0.5, 0.7)
		env.ambient_light_color = Color(0.65, 0.55, 0.75)
	elif slack_water:
		env.fog_light_color = Color(0.4, 0.5, 0.55)
		env.ambient_light_color = Color(0.5, 0.6, 0.65)
	elif salvage_breeze:
		env.fog_light_color = Color(0.5, 0.65, 0.55)
		env.ambient_light_color = Color(0.55, 0.7, 0.6)
	elif deep_salve:
		env.fog_light_color = Color(0.45, 0.6, 0.75)
		env.ambient_light_color = Color(0.5, 0.65, 0.8)
	elif keel_spirit:
		env.fog_light_color = Color(0.6, 0.7, 0.55)
		env.ambient_light_color = Color(0.65, 0.75, 0.6)
	elif lantern_wake:
		env.fog_light_color = Color(0.75, 0.65, 0.35)
		env.ambient_light_color = Color(0.8, 0.7, 0.4)
	elif fog_bank:
		env.fog_light_color = Color(0.55, 0.6, 0.62)
		env.ambient_light_color = Color(0.6, 0.65, 0.68)
	elif tide_clock:
		env.fog_light_color = Color(0.5, 0.55, 0.7)
		env.ambient_light_color = Color(0.55, 0.6, 0.75)
	elif deep_well:
		env.fog_light_color = Color(0.25, 0.3, 0.5)
		env.ambient_light_color = Color(0.3, 0.35, 0.55)
	elif bilge_still:
		env.fog_light_color = Color(0.4, 0.45, 0.42)
		env.ambient_light_color = Color(0.45, 0.5, 0.48)
	elif keel_groan:
		env.fog_light_color = Color(0.4, 0.32, 0.28)
		env.ambient_light_color = Color(0.45, 0.38, 0.32)
	elif saltwind:
		env.fog_light_color = Color(0.45, 0.5, 0.55)
		env.ambient_light_color = Color(0.5, 0.55, 0.6)
	elif bone_lantern:
		env.fog_light_color = Color(0.55, 0.48, 0.3)
		env.ambient_light_color = Color(0.6, 0.52, 0.35)
	elif dead_reckoning:
		env.fog_light_color = Color(0.4, 0.35, 0.5)
		env.ambient_light_color = Color(0.45, 0.4, 0.55)
	elif gloom_tide:
		env.fog_light_color = Color(0.25, 0.28, 0.4)
		env.ambient_light_color = Color(0.3, 0.33, 0.45)
	elif pale_wake:
		env.fog_light_color = Color(0.5, 0.55, 0.65)
		env.ambient_light_color = Color(0.5, 0.55, 0.7)
	elif murk_lift:
		env.fog_light_color = Color(0.35, 0.45, 0.5)
		env.ambient_light_color = Color(0.4, 0.5, 0.55)
	elif siren_hum:
		env.fog_light_color = Color(0.45, 0.35, 0.55)
		env.ambient_light_color = Color(0.5, 0.4, 0.6)
	elif grim_calm:
		env.fog_light_color = Color(0.25, 0.3, 0.35)
		env.ambient_light_color = Color(0.3, 0.35, 0.42)
	elif keel_haul:
		env.fog_light_color = Color(0.5, 0.45, 0.3)
		env.ambient_light_color = Color(0.55, 0.5, 0.35)
	elif weeping_tide:
		env.fog_light_color = Color(0.3, 0.4, 0.5)
		env.ambient_light_color = Color(0.35, 0.45, 0.55)
	elif deep_draught:
		env.fog_light_color = Color(0.2, 0.35, 0.4)
		env.ambient_light_color = Color(0.25, 0.4, 0.45)
	elif thick_tide:
		env.fog_light_color = Color(0.35, 0.3, 0.4)
		env.ambient_light_color = Color(0.4, 0.35, 0.45)
	elif slack_line:
		env.fog_light_color = Color(0.3, 0.45, 0.35)
		env.ambient_light_color = Color(0.35, 0.5, 0.4)
	elif low_lantern:
		env.fog_light_color = Color(0.5, 0.4, 0.2)
		env.ambient_light_color = Color(0.55, 0.45, 0.25)
	elif mirage_sea:
		env.fog_light_color = Color(0.5, 0.55, 0.5)
		env.ambient_light_color = Color(0.55, 0.6, 0.55)
	elif bilge_lull:
		env.fog_light_color = Color(0.25, 0.3, 0.45)
		env.ambient_light_color = Color(0.3, 0.35, 0.5)
		env.ambient_light_color = Color(0.6, 0.55, 0.45)
		sun.light_energy = 0.9
		env.ambient_light_color = Color(0.45, 0.75, 0.55)
		sun.light_energy = 0.9
		env.ambient_light_color = Color(0.55, 0.55, 0.6)
		sun.light_energy = 0.95
		env.ambient_light_color = Color(0.35, 0.45, 0.5)
		sun.light_energy = 0.85
		env.ambient_light_color = Color(0.5, 0.45, 0.35)
		sun.light_energy = 0.9
		env.ambient_light_color = Color(0.65, 0.6, 0.35)
		sun.light_energy = 1.0
		env.ambient_light_color = Color(0.5, 0.45, 0.4)
		sun.light_energy = 0.9
		env.ambient_light_color = Color(0.3, 0.35, 0.5)
		sun.light_energy = 0.7
	elif kings_tithe:
		env.fog_light_color = Color(0.55, 0.4, 0.25)
		env.ambient_light_color = Color(0.6, 0.45, 0.3)
		sun.light_energy = 0.85
	elif sunken_tide:
		env.fog_light_color = Color(0.06, 0.16, 0.15)
		env.ambient_light_color = Color(0.25, 0.5, 0.45)
		sun.light_color = Color(0.5, 0.9, 0.8)
		sun.light_energy = 0.9
	elif low_tide:
		env.fog_light_color = Color(0.08, 0.14, 0.1)
		env.ambient_light_color = Color(0.3, 0.45, 0.3)
		sun.light_color = Color(0.7, 0.95, 0.6)
	elif glass_sea:
		env.fog_light_color = Color(0.05, 0.18, 0.2)
		env.ambient_light_color = Color(0.35, 0.6, 0.65)
		sun.light_color = Color(0.75, 0.98, 1.0)
		sun.light_energy = 1.1
	elif deep_current:
		env.fog_light_color = Color(0.03, 0.1, 0.18)
		env.ambient_light_color = Color(0.2, 0.4, 0.55)
		sun.light_color = Color(0.4, 0.7, 1.0)
	elif dread_tide:
		env.fog_light_color = Color(0.12, 0.04, 0.14)
		env.ambient_light_color = Color(0.4, 0.2, 0.45)
		sun.light_color = Color(0.8, 0.4, 0.9)
	elif starved_deep:
		env.fog_light_color = Color(0.02, 0.02, 0.08)
		env.ambient_light_color = Color(0.15, 0.15, 0.3)
		sun.light_color = Color(0.3, 0.35, 0.7)
	elif choir:
		env.fog_light_color = Color(0.1, 0.06, 0.2)
		env.ambient_light_color = Color(0.35, 0.25, 0.5)
		sun.light_color = Color(0.6, 0.45, 0.9)
		sun.light_energy = 0.95


func _style_room() -> void:
	var floor_mat := M.toon(dungeon_tex, biome["floor"], 0.15)
	var wall_mat := M.toon(dungeon_tex, biome["wall"], 0.2)
	var prop_mat := M.toon(dungeon_tex, biome["prop"], 0.2)
	var gold_mat := M.toon(dungeon_tex, Color(1.1, 1.0, 0.75), 0.4)
	for n in info.floors:
		M.paint(n, floor_mat)
	for n in info.walls:
		M.paint(n, wall_mat)
	for n in info.props:
		M.paint(n, prop_mat)
	if info.chest != null:
		M.paint(info.chest, gold_mat)
	for t in info.torches:
		M.paint(t, prop_mat)
		var omni := OmniLight3D.new()
		room.add_child(omni)
		omni.global_position = t.global_position + Vector3(0.0, 0.4, 0.4)
		omni.light_color = biome["torch"]
		omni.light_energy = biome.get("torch_e", 1.4)
		omni.omni_range = biome.get("torch_r", 7.0)
		omni.omni_attenuation = 1.3


# ---------------- run lifecycle ----------------

func _reset_run_state() -> void:
	omen_done = false
	omen_done2 = false
	omen_name = ""
	omen_hp_mult = 1.0
	fatehand = false
	nemesis_bounty = false
	candle_tax = false
	pilot_dead = false
	fathom_tax = false
	hull_rot = false
	still_water = false
	gold_hull = false
	salt_ration = false
	hard_tack = false
	leaden_purse = false
	widows_ledger = false
	flotsam_kin = false
	scurvy = false
	draft_hole = false
	keel_hauled = false
	bilge_sworn = false
	salt_forfeit = false
	dead_reckoner = false
	pale_dock = false
	fathom_pact = false
	bosuns_debt = false
	crews_share = false
	palm_tar = false
	oar_tax = false
	rust_bounty = false
	deep_charter = false
	salty_wages = false
	gunnel_tide = false
	dead_wages = false
	riggers_due = false
	tides_favor = false
	barnacle_oath = false
	black_tide = false
	grave_knot = false
	combo_rate_bonus = 0.0
	solitary = false
	pawn_discount = false
	golden_fate = false
	trap_wrapped = 0
	veil_used = false
	crown_oath = false
	pinch_n = 0
	abyss_n = 0
	lore_run = 0
	disarm_run = 0
	thrall_n = 0
	salt_tithe = false
	keel_prayer = false
	events_run = {}
	riptide_n = 0
	steps_done_run = 0
	urns_run = 0
	moonpool_run = 0
	shellshield_used = false
	perfect_dodges = 0
	leech_charge = 0
	legion_omen = false
	wolf_omen = false
	wolf_n = 0
	shrine_count = 0
	blessings_run = 0
	deals_run = 0
	dice_wins = 0
	urn_count = 0
	_biomes_run = {}
	salvage_ct = 0
	lucky_net = false
	deeproot = false
	still_waters = false
	bone_veil = false
	_souls_seen = Stats.souls
	_souls_net = 0
	ashborn = false
	lonecrown = false
	lc_delta = 0.0
	tf_delta = 0.0
	hymn_delta = 0.0
	thick_delta = 0.0
	slack_delta = 0.0
	ll_delta = 0.0
	omen_count = 0
	omen_refusals = 0
	bargainer = false
	bargain_used = false
	nemesis_warned = false
	ferry_extra = 0
	_ferry_used = false
	gravetide = false
	mudlark = false
	crows_share = false
	netgain_n = 0
	_rope_active = false
	rope_kills = 0
	harpoon_n = 0
	net_n = 0
	wellread = false
	tide_lends = false
	pearl_fever = false
	muckraker = false
	abyssal_patience = false
	bone_market = false
	waxpale = false
	vessel = false
	skeleton_crew = false
	rolling_fog = false
	deep_pockets_oath = false
	oarsworn = false
	dark_water = false
	umbral_tide = false
	moonwrit = false
	barnacle_sense = false
	brine_callus = false
	bosun_ledger = false
	urnsworn = false
	full_chart = false
	long_wake = false
	dead_lantern = false
	hull_song = false
	salt_ledger = false
	wide_satchel = false
	slow_clock = false
	deck_alms = false
	loose_ballast = false
	black_sails = false
	grim_charter = false
	martyrs_oath = false
	final_verse = false
	cradle_deep = false
	undertow = false
	storm_lull = false
	deep_breath = false
	dash_fuel = false
	powder_keg = 0
	bloodtide_t = 0.0
	iron_gullet = false
	murk_fed = false
	crew_oath = false
	lantern_oil = false
	bloodwarm = false
	deadweight = false
	undertow_grip = false
	lookout = false
	bosun_mark = false
	omen_cd_add = 0.0
	crows_toll = false
	moonwater = false
	pilgrims_purse = false
	if callus_on:
		Stats.buff_armor -= 2
		callus_on = false
	if _pilot_on:
		Stats.buff_speed_pct -= 0.08
		_pilot_on = false
	tide_kills = 0
	floor_kills = 0
	knot_n = 0
	reliquary_wisps = 0
	flawless_run = 0
	well_rolls = 0
	well_rolls_run = 0
	if trial_atk_t > 0.0:
		Stats.buff_atk_pct -= 0.15
		trial_atk_t = 0.0


func _new_run(new_seed: int) -> void:
	seed_val = new_seed
	run_state = "playing"
	chest_opened = false
	current_room = -1
	discovered = {0: true}
	for id in skill_cd:
		skill_cd[id] = 0.0
	biome = BIO.for_floor(Stats.floor_num)
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = Node3D.new()
	room.name = "Room"
	add_child(room)
	info = RG.build_floor(room, seed_val, Stats.floor_num)
	for ci in range(mini(int(Stats.meta.get("carto", 0)), info.ranges.size() - 1)):
		discovered[ci + 1] = true
	if full_chart:
		for ri_fc in range(info.ranges.size()):
			discovered[ri_fc] = true
	if int(Stats.meta.get("carto", 0)) > 0 or full_chart:
		_update_minimap()
	stain_count = 0
	stain_positions.clear()
	pool_positions.clear()
	pool_healed = 0.0
	keelh_floor = 0
	salt_purse = false
	disarm_floor = 0
	urns_floor = 0
	rooms_floor = 0
	clams_run = 0
	sirensong_deal = false
	pool_touched = false
	shellshield_used = false
	if rotgut_drunk:
		Stats.buff_maxhp_pct -= 0.15
		rotgut_drunk = false
	if blood_drawn:
		Stats.buff_atk_pct -= 0.2
		blood_drawn = false
	if pale_drunk:
		Stats.buff_speed_pct -= 0.08
		pale_drunk = false
	if tar_knots:
		tar_knots = false
	if salt_sheath:
		Stats.buff_crit -= 0.08
		salt_sheath = false
	if brine_hymn:
		Stats.event_soul_bonus -= 1
		brine_hymn = false
	keelmans_toll = false
	if knotwork:
		Stats.dodge -= 0.05
		knotwork = false
	low_verse = false
	if salt_scrip:
		Stats.buff_xp_pct -= 0.1
		salt_scrip = false
	if brine_graft:
		Stats.buff_armor -= 1
		brine_graft = false
	if marlin_spike:
		Stats.buff_speed_pct -= 0.1
		marlin_spike = false
	fathomsong = false
	watch_bell = false
	if hull_pitch:
		Stats.buff_armor -= 1
		hull_pitch = false
	if knot_refuge:
		Stats.dodge -= 0.1
		knot_refuge = false
	if grommets_due:
		Stats.buff_atk_pct -= 0.08
		grommets_due = false
	if sheave_toll:
		Stats.buff_xp_pct -= 0.1
		sheave_toll = false
	bilge_bond = false
	if mudlarks_due:
		Stats.dodge -= 0.08
		mudlarks_due = false
	if rigging_rites:
		Stats.buff_aspd -= 0.08
		rigging_rites = false
	if bosuns_chit:
		Stats.buff_atk_pct -= 0.1
		bosuns_chit = false
	deck_psalm = false
	rope_tackle = false
	murk_purse = false
	if soul_ledger:
		Stats.soul_gain_pct -= 0.2
		soul_ledger = false
	if courts_tally:
		Stats.soul_gain_pct -= 0.12
		courts_tally = false
	if salt_dowry:
		Stats.soul_gain_pct -= 0.12
		salt_dowry = false
	if grim_wager:
		Stats.buff_atk_pct -= 0.12
		Stats.buff_crit -= 0.08
		grim_wager = false
	if sv_doubt:
		Stats.buff_atk_pct -= 0.15
		Stats.buff_maxhp_pct += 0.05
		sv_doubt = false
	royal_overlook = false
	if crowns_reprieve:
		Stats.cd_reduction -= 0.12
		crowns_reprieve = false
	if crowns_hand:
		Stats.buff_atk_pct -= 0.06
		crowns_hand = false
	if splice_line:
		Stats.buff_speed_pct -= 0.06
		splice_line = false
	if rigging_rest:
		Stats.cd_reduction -= 0.15
		rigging_rest = false
	if hull_count:
		Stats.buff_maxhp_pct -= 0.1
		hull_count = false
	if capstan_oil:
		Stats.buff_aspd -= 0.1
		capstan_oil = false
	if sheet_bend:
		Stats.dodge -= 0.08
		sheet_bend = false
	if crews_grog:
		Stats.buff_xp_pct -= 0.10
		crews_grog = false
	if bosuns_ration:
		Stats.buff_atk_pct -= 0.08
		bosuns_ration = false
	if second_verse:
		Stats.buff_aspd -= 0.15
		second_verse = false
	if chorus_deep:
		Stats.soul_gain_pct -= 0.1
		chorus_deep = false
	if harbor_verse:
		Stats.buff_atk_pct -= 0.08
		harbor_verse = false
	if wake_verse:
		Stats.buff_speed_pct -= 0.08
		wake_verse = false
	if requiem_note:
		Stats.dodge -= 0.08
		requiem_note = false
	if dirge_half:
		dirge_half = false
	if leech_bond:
		Stats.buff_lifesteal -= 0.08
		leech_bond = false
	if keelwind:
		Stats.buff_speed_pct -= 0.1
		keelwind = false
	murk_vision = false
	if silt_draught:
		Stats.buff_armor -= 1
		silt_draught = false
	drowned_mercy = false
	if rivers_tithe:
		Stats.soul_gain_pct -= 0.12
		rivers_tithe = false
	if boatswain_call:
		Stats.dodge -= 0.12
		boatswain_call = false
	court_fool = false
	if bilge_ballad:
		Stats.buff_xp_pct -= 0.12
		bilge_ballad = false
	salt_lullaby = false
	if coil_chit:
		Stats.dodge -= 0.08
		coil_chit = false
	if rope_allowance:
		Stats.buff_speed_pct -= 0.08
		rope_allowance = false
	if regal_favor:
		Stats.buff_xp_pct -= 0.15
		regal_favor = false
	kelp_tithe = false
	if vigils_gage:
		Stats.dodge -= 0.1
		vigils_gage = false
	crowns_hush = false
	vassals_claim = false
	if drift_verse:
		Stats.dodge -= 0.08
		drift_verse = false
	pearl_octave = false
	undertow_aria = false
	if wake_chant:
		Stats.buff_speed_pct -= 0.12
		wake_chant = false
	if salt_aria:
		Stats.soul_gain_pct -= 0.12
		salt_aria = false
	if pearl_graft:
		Stats.buff_atk_pct -= 0.15
		pearl_graft = false
	if oyster_toll:
		Stats.buff_xp_pct -= 0.15
		oyster_toll = false
	if silt_press:
		Stats.soul_gain_pct -= 0.15
		silt_press = false
	if deck_manifest:
		Stats.soul_gain_pct -= 0.15
		deck_manifest = false
	if saltgrave_ev:
		Stats.soul_gain_pct -= 0.2
		omen_hp_mult /= 1.1
		saltgrave_ev = false
	if leeward_ev:
		Stats.buff_speed_pct -= 0.15
		leeward_ev = false
	brine_smoke = false
	crowns_ransom = false
	bilge_strike = false
	full_draught = false
	salt_front = false
	cold_snap = false
	if full_moon:
		Stats.soul_gain_pct -= 0.5
		full_moon = false
	if gunners_luck:
		Stats.event_soul_bonus -= 1
		gunners_luck = false
	if shallow_graves:
		omen_hp_mult /= 0.85
		shallow_graves = false
	if wailing_wind:
		Stats.buff_xp_pct -= 0.1
		wailing_wind = false
	balmy_sea = false
	rust_storm = false
	if ember_wake:
		Stats.buff_atk_pct -= 0.1
		ember_wake = false
	saltsick = false
	if gallows_tide:
		Stats.soul_gain_pct -= 0.15
		gallows_tide = false
	if pilot_light:
		Stats.soul_gain_pct -= 0.1
		pilot_light = false
	if widdershins:
		Stats.dodge -= 0.08
		widdershins = false
	if slack_water:
		Stats.buff_atk_pct += 0.08
		slack_water = false
	if salvage_breeze:
		Stats.buff_speed_pct -= 0.05
		salvage_breeze = false
	deep_salve = false
	keel_spirit = false
	if lantern_wake:
		Stats.soul_gain_pct -= 0.15
		lantern_wake = false
	if fog_bank:
		Stats.buff_xp_pct += 0.1
		fog_bank = false
	if tide_clock:
		Stats.soul_gain_pct += 0.05
		tide_clock = false
	if bilge_still:
		Stats.buff_xp_pct += 0.08
		bilge_still = false
	if keel_groan:
		Stats.buff_xp_pct -= 0.1
		keel_groan = false
	saltwind = false
	bone_lantern = false
	if dead_reckoning:
		Stats.buff_xp_pct -= 0.15
		dead_reckoning = false
	if gloom_tide:
		Stats.buff_xp_pct -= 0.08
		gloom_tide = false
	pale_wake = false
	if murk_lift:
		Stats.buff_xp_pct -= 0.1
		murk_lift = false
	siren_hum = false
	grim_calm = false
	keel_haul = false
	weeping_tide = false
	deep_draught = false
	thick_tide = false
	slack_line = false
	low_lantern = false
	mirage_sea = false
	bilge_lull = false
	deep_well = false
	pale_scrip = false
	song_rust = false
	undertow = false
	splice_kills = 0
	timber_shiver = false
	hull_bonus = false
	court_summons = false
	kneel_not = false
	gangway = false
	penny_floor = false
	if drift_line:
		Stats.buff_atk_pct -= 0.1
		drift_line = false
	if shoal_spd:
		Stats.buff_speed_pct -= 0.08
		shoal_spd = false
	Stats.buff_armor -= tithe_armor
	tithe_armor = 0.0
	pray_t = 0.0
	prayed = false
	umbral_seen = false
	var boss_floor: bool = QDB.is_boss_floor(Stats.floor_num)
	Stats.buff_atk_pct -= lc_delta
	lc_delta = (0.2 if boss_floor else -0.05) if lonecrown else 0.0
	Stats.buff_atk_pct += lc_delta
	Stats.buff_speed_pct -= tf_delta
	tf_delta = 0.12 if (Stats.relics.has("trenchfoot") and Stats.floor_num >= 11) else 0.0
	Stats.buff_speed_pct += tf_delta
	Stats.buff_speed_pct -= hymn_delta
	hymn_delta = -0.15 if abyssal_hymn else 0.0
	Stats.buff_speed_pct += hymn_delta
	Stats.buff_speed_pct -= thick_delta
	thick_delta = -0.08 if thick_tide else 0.0
	Stats.buff_speed_pct += thick_delta
	Stats.cd_reduction -= slack_delta
	slack_delta = -0.20 if slack_line else 0.0
	Stats.cd_reduction += slack_delta
	Stats.dodge -= ll_delta
	ll_delta = 0.10 if low_lantern else 0.0
	Stats.dodge += ll_delta
	if player != null and is_instance_valid(player):
		player.refresh_stats()
	# event langka: blood moon — langit merah, musuh lebih keras, XP lebih kaya
	blood_moon = Stats.floor_num >= 3 and not boss_floor and rng.randf() < 0.07
	# event langka #2: soul rush — kabut ungu, permata XP berlimpah, tithe jiwa saat clear
	soul_rush = not blood_moon and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.07
	# event langka #3: fading light — obor padam, musuh lebih ganas, tithe jiwa saat clear
	fading_light = not blood_moon and not soul_rush and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.06
	# event langka #4: echoing halls — lorong bergema, skill recharge 25% lebih cepat
	echoing = not blood_moon and not soul_rush and not fading_light and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.06
	storm_cellar = not blood_moon and not soul_rush and not fading_light and not echoing and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.05
	Stats.event_soul_bonus = 0
	skill_used_floor = false
	skills_floor = {}
	rooms_cleared = 0
	well_rolls = 0
	# event langka #6: gilded tides — timbunan muncul ke permukaan (lantai 12+): peti gilded + jiwa +1/kill
	gilded_tides = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and Stats.floor_num >= 12 and not boss_floor and rng.randf() < 0.05
	if gilded_tides:
		Stats.event_soul_bonus = 1
	# event langka #8: soul drift — nafas orang mati mengembara (lantai 13+): kunang berlimpah
	soul_drift = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and Stats.floor_num >= 13 and not boss_floor and rng.randf() < 0.05
	grave_hunger = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and Stats.floor_num >= 15 and not boss_floor and rng.randf() < 0.05
	giant_hall = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and Stats.floor_num >= 16 and not boss_floor and rng.randf() < 0.04
	shrouded = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.06
	ossuary = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and Stats.floor_num >= 17 and not boss_floor and rng.randf() < 0.05
	# event langka #12: mirror hall — bayangan memantulkan jiwa-jiwa (lantai 9+): musuh ganda, XP berlimpah
	mirror_hall = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and Stats.floor_num >= 9 and not boss_floor and rng.randf() < 0.05
	# event langka #13: ashfall — hujan abu kremasi turun (lantai 10+): jiwa +1 per kill
	ashfall = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.05
	if ashborn and Stats.floor_num >= 10 and not boss_floor and not ashfall:
		ashfall = true
		Stats.event_soul_bonus = 1
	if ashfall:
		Stats.event_soul_bonus = 1
	# event langka #14: hungry walls — lorong-lorong melahirkan musuh (lantai 12+): +45% musuh ekstra
	hungry_walls = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and Stats.floor_num >= 12 and not boss_floor and rng.randf() < 0.05
	if hungry_walls:
		Stats.event_soul_bonus = 1
	# event langka #15: candlelit — seribu api menerangi lorong (lantai 11+): musuh lemah, jiwa melimpah
	candlelit = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and Stats.floor_num >= 11 and not boss_floor and rng.randf() < 0.05
	if candlelit:
		Stats.event_soul_bonus = 1
	# event langka #16: verdant bloom — rerumputan menelan lorong (lantai 14+): musuh lambat, jiwa melimpah
	verdant = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and Stats.floor_num >= 14 and not boss_floor and rng.randf() < 0.05
	if verdant:
		Stats.event_soul_bonus = 1
	# event langka #17: bone chorus — paduan suara kematian (lantai 15+): orator di tiap ruangan
	bone_chorus = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and Stats.floor_num >= 15 and not boss_floor and rng.randf() < 0.05
	if bone_chorus:
		Stats.event_soul_bonus = 1
	# event langka #18: wolfsbane — kawanan pemburu (lantai 12+): semua musuh adalah hound
	wolfsbane = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and Stats.floor_num >= 12 and Stats.floor_num <= 24 and not boss_floor and rng.randf() < 0.05
	if wolfsbane:
		Stats.event_soul_bonus = 1
	# event langka #19: thin veil — batas hidup-mati menipis (lantai 18+)
	thin_veil = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and Stats.floor_num >= 18 and not boss_floor and rng.randf() < 0.05
	if thin_veil:
		Stats.event_soul_bonus = 2
	low_water = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and Stats.floor_num >= 12 and not boss_floor and rng.randf() < 0.05
	if low_water:
		Stats.event_soul_bonus = 2
	drift_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and Stats.floor_num >= 15 and not boss_floor and rng.randf() < 0.05
	if drift_tide:
		Stats.event_soul_bonus = 3
	soul_swarm = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and Stats.floor_num >= 16 and not boss_floor and rng.randf() < 0.05
	if soul_swarm:
		Stats.event_soul_bonus = 2
	gauntlet = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and Stats.floor_num >= 17 and not boss_floor and rng.randf() < 0.05
	if gauntlet:
		Stats.event_soul_bonus = 2
		Stats.curse_xp += 0.15
	brisk = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and Stats.floor_num >= 18 and not boss_floor and rng.randf() < 0.05
	if brisk:
		Stats.event_soul_bonus = 2
	shoal_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and Stats.floor_num >= 19 and not boss_floor and rng.randf() < 0.05
	if shoal_tide:
		Stats.event_soul_bonus = 2
		Stats.buff_speed_pct += 0.08
		shoal_spd = true
	salvage_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and Stats.floor_num >= 20 and not boss_floor and rng.randf() < 0.05
	if salvage_tide:
		Stats.event_soul_bonus = 2
	gale_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and Stats.floor_num >= 21 and not boss_floor and rng.randf() < 0.05
	if gale_tide:
		Stats.event_soul_bonus = 2
		Stats.cd_reduction += 0.15
	mercy_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.04
	if mercy_tide:
		Stats.event_soul_bonus = 1
	eel_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.035
	if eel_tide:
		Stats.event_soul_bonus = 1
	swell_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.035
	if swell_tide:
		Stats.event_soul_bonus = 1
	kelp_bed = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.035
	if kelp_bed:
		Stats.event_soul_bonus = 1
	barnacle_bloom = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and Stats.floor_num >= 9 and not boss_floor and rng.randf() < 0.03
	if barnacle_bloom:
		Stats.event_soul_bonus = 1
	rich_vein = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and Stats.floor_num >= 9 and not boss_floor and rng.randf() < 0.03
	if rich_vein:
		Stats.event_soul_bonus = 2
	wraiths_due = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	if wraiths_due:
		Stats.event_soul_bonus = 1
	pale_lantern_ev = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if pale_lantern_ev:
		Stats.event_soul_bonus = 1
	saltgrave_ev = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	if saltgrave_ev:
		Stats.soul_gain_pct += 0.2
		omen_hp_mult *= 1.1
	leeward_ev = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if leeward_ev:
		Stats.buff_speed_pct += 0.15
	pilot_light = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	widdershins = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.03
	if widdershins:
		Stats.dodge += 0.08
	slack_water = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if slack_water:
		Stats.buff_atk_pct -= 0.08
	salvage_breeze = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if salvage_breeze:
		Stats.buff_speed_pct += 0.05
	deep_salve = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	keel_spirit = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.03
	lantern_wake = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if lantern_wake:
		Stats.soul_gain_pct += 0.15
	fog_bank = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	if fog_bank:
		Stats.buff_xp_pct -= 0.1
	tide_clock = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.03
	if tide_clock:
		Stats.soul_gain_pct -= 0.05
	bilge_still = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if bilge_still:
		Stats.buff_xp_pct -= 0.08
	keel_groan = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if keel_groan:
		Stats.buff_xp_pct += 0.1
	saltwind = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	bone_lantern = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	dead_reckoning = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if dead_reckoning:
		Stats.buff_xp_pct += 0.15
	gloom_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if gloom_tide:
		Stats.buff_xp_pct += 0.08
	pale_wake = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	murk_lift = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	siren_hum = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	grim_calm = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	keel_haul = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	weeping_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	deep_draught = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and not weeping_tide and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	thick_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and not weeping_tide and not keel_haul and not weeping_tide and not deep_draught and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	slack_line = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and not weeping_tide and not keel_haul and not weeping_tide and not deep_draught and not thick_tide and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	low_lantern = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and not weeping_tide and not keel_haul and not weeping_tide and not deep_draught and not thick_tide and not slack_line and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	mirage_sea = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and not weeping_tide and not keel_haul and not weeping_tide and not deep_draught and not thick_tide and not slack_line and not low_lantern and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	bilge_lull = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and not deep_well and not bilge_still and not keel_groan and not saltwind and not bone_lantern and not dead_reckoning and not gloom_tide and not pale_wake and not murk_lift and not siren_hum and not grim_calm and not keel_haul and not weeping_tide and not keel_haul and not weeping_tide and not deep_draught and not thick_tide and not slack_line and not low_lantern and not mirage_sea and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	if murk_lift:
		Stats.buff_xp_pct += 0.1
	deep_well = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and not gallows_tide and not pilot_light and not widdershins and not slack_water and not salvage_breeze and not deep_salve and not keel_spirit and not lantern_wake and not fog_bank and not tide_clock and Stats.floor_num >= 9 and not boss_floor and rng.randf() < 0.03
	if pilot_light:
		Stats.soul_gain_pct += 0.1
	gallows_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and not saltsick and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if gallows_tide:
		Stats.soul_gain_pct += 0.15
	saltsick = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and not ember_wake and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	ember_wake = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and not rust_storm and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	rust_storm = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and not balmy_sea and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	balmy_sea = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and not wailing_wind and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	wailing_wind = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and not shallow_graves and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	shallow_graves = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and not gunners_luck and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	gunners_luck = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and not full_moon and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.03
	full_moon = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and not cold_snap and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	cold_snap = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and not salt_front and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	salt_front = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and not full_draught and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	full_draught = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and not bilge_strike and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.03
	bilge_strike = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and not crowns_ransom and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	crowns_ransom = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and not brine_smoke and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	brine_smoke = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and not halfway_dead and not rich_vein and not wraiths_due and not pale_lantern_ev and not saltgrave_ev and not leeward_ev and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	halfway_dead = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and not long_night and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.03
	if halfway_dead:
		Stats.event_soul_bonus = 1
	long_night = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not crows_tide and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.03
	if long_night:
		Stats.event_soul_bonus = 2
	crows_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not salted_deck and not long_night and not halfway_dead and not rich_vein and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.03
	if crows_tide:
		Stats.event_soul_bonus = 1
	salted_deck = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not long_watch and not crows_tide and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.03
	if salted_deck:
		Stats.event_soul_bonus = 1
	long_watch = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not drift_wreck and not salted_deck and Stats.floor_num >= 9 and not boss_floor and rng.randf() < 0.03
	if long_watch:
		Stats.event_soul_bonus = 2
		Stats.buff_speed_pct += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
	drift_wreck = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not greedy_tide and not long_watch and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if drift_wreck:
		Stats.event_soul_bonus = 1
	greedy_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and not gun_smoke and not drift_wreck and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.03
	if greedy_tide:
		Stats.event_soul_bonus = 1
	gun_smoke = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not black_calm and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.03
	if gun_smoke:
		Stats.event_soul_bonus = 2
		Stats.buff_aspd += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
	black_calm = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not kings_tithe and not gun_smoke and not greedy_tide and Stats.floor_num >= 12 and not boss_floor and rng.randf() < 0.03
	if black_calm:
		Stats.event_soul_bonus = 2
	kings_tithe = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not soul_flush and not black_calm and Stats.floor_num >= 15 and not boss_floor and rng.randf() < 0.03
	if kings_tithe:
		Stats.event_soul_bonus = 3
	soul_flush = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not pale_squall and not kings_tithe and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.03
	if soul_flush:
		Stats.event_soul_bonus = 1
	pale_squall = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not bilge_run and not soul_flush and not kings_tithe and Stats.floor_num >= 11 and not boss_floor and rng.randf() < 0.03
	if pale_squall:
		Stats.event_soul_bonus = 1
	bilge_run = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not hungry_urns and not pale_squall and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.03
	if bilge_run:
		Stats.event_soul_bonus = 1
	hungry_urns = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not merchant_tide and not bilge_run and Stats.floor_num >= 9 and not boss_floor and rng.randf() < 0.03
	if hungry_urns:
		Stats.event_soul_bonus = 1
	merchant_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not halfwreck and not hungry_urns and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if merchant_tide:
		Stats.event_soul_bonus = 1
	halfwreck = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not dark_lantern and not merchant_tide and Stats.floor_num >= 8 and not boss_floor and rng.randf() < 0.03
	if halfwreck:
		Stats.event_soul_bonus = 1
	dark_lantern = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not mire_hollow and not halfwreck and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.03
	if dark_lantern:
		Stats.event_soul_bonus = 1
	mire_hollow = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and not bile_tide and not dark_lantern and Stats.floor_num >= 7 and not boss_floor and rng.randf() < 0.03
	if mire_hollow:
		Stats.event_soul_bonus = 1
	bile_tide = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and not sodden and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if bile_tide:
		Stats.event_soul_bonus = 1
	sodden = not blood_moon and not soul_rush and not fading_light and not bile_tide and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not bone_chorus and not wolfsbane and not thin_veil and not low_water and not drift_tide and not soul_swarm and not gauntlet and not brisk and not shoal_tide and not salvage_tide and not gale_tide and not mercy_tide and not eel_tide and not swell_tide and not kelp_bed and not barnacle_bloom and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.03
	if sodden:
		Stats.event_soul_bonus = 1
	storm_t = 4.0
	nemesis_spawned = false
	_ferry_used = false
	if Stats.relics.has("sea_biscuit") and vials == 0:
		vials = 1
		_vial_btn()
		toast("SEA BISCUIT — the crumbed vial found its way back")
	if Stats.relics.has("murk_pearl") and Stats.event_soul_bonus > 0 and not murk_fed:
		murk_fed = true
		Stats.buff_xp_pct += 0.15
		toast("MURK PEARL — the storm feeds your lessons (+15% XP)")
	_apply_biome()
	_style_room()
	_build_gates()
	_spawn_player(info.player_pos)
	boss_ref = null
	shrine_ref = null
	shrine_used = false
	chest_opened = false
	mimic_pending = Stats.floor_num >= 2 and rng.randf() < 0.35
	# peti berlapis emas (12%, lantai 4+, bukan mimic): berisi relic langka+
	gilded_chest = golden_fate or (not mimic_pending and Stats.floor_num >= 4 and rng.randf() < 0.12) or (not mimic_pending and Stats.floor_num >= 11 and Stats.floor_num <= 12) or (not mimic_pending and Stats.floor_num >= 2 and Stats.relics.has("kunci_osuarium")) or (not mimic_pending and Stats.floor_num >= 8 and Stats.relics.size() < 3)
	if gilded_chest and info.get("chest") != null:
		M.paint(info.chest, M.toon(dungeon_tex, Color(1.35, 1.15, 0.55), 0.55))
	# peti terkutuk (10%, lantai 6+, bukan mimic/gilded): penyergapan demi relic epic
	if gilded_tides:
		mimic_pending = false
		gilded_chest = info.get("chest") != null
	cursed_chest = not mimic_pending and not gilded_chest and Stats.floor_num >= 6 and rng.randf() < 0.10
	if cursed_chest and info.get("chest") != null:
		M.paint(info.chest, M.toon(dungeon_tex, Color(0.5, 0.3, 0.75), 0.5))
	var last_room: int = int(info.get("room_count", 1)) - 1
	var elite_chance: float = minf(0.08 + 0.02 * Stats.floor_num + 0.1 * maxi(0, Stats.ng_plus - 2) + (0.15 if halfwreck else 0.0), 0.55)
	if skeleton_crew:
		elite_chance = minf(elite_chance * 1.5, 0.5)
	if grim_charter:
		elite_chance = minf(elite_chance + 0.1, 0.55)
	if crowns_ransom:
		elite_chance = minf(elite_chance + 0.2, 0.55)
	var table: Array = biome["enemies"]
	# penyergapan (lantai 5+, non-bos): satu ruangan tampak kosong — tulang bangkit saat kau masuk
	ambush_room = -1
	ambushed_room = -1
	floor_t = 0.0
	floor_hurt = false
	if not boss_floor and Stats.floor_num >= 5 and int(info.get("room_count", 1)) >= 4 and rng.randf() < 0.35:
		ambush_room = rng.randi_range(1, last_room - 1)
	for sp in info.enemy_spawns:
		# di lantai boss, ruangan terakhir hanya untuk Raja Tulang
		if boss_floor and int(sp.get("room", 0)) == last_room:
			continue
		# ruangan ambush sengaja dikosongkan — kejutan saat masuk
		if int(sp.get("room", 0)) == ambush_room:
			continue
		# Skeleton Crew: ruangan menyusut awaknya
		if skeleton_crew and rng.randf() < 0.33:
			continue
		var is_elite := rng.randf() < elite_chance
		var arch_id := "hound" if wolfsbane else String(table[rng.randi_range(0, table.size() - 1)])
		var gchance := 0.1 if String(biome.get("name", "")) == "Sunken Reliquary" else 0.05
		_spawn_enemy(sp, arch_id, is_elite, not is_elite and rng.randf() < gchance)
		if (mirror_hall or legion_omen) and not is_elite:
			var mpos: Vector3 = sp["pos"] + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)) * info.tile * 0.5
			_spawn_enemy({"pos": mpos, "room": int(sp.get("room", 0))}, arch_id, false)
		elif crows_tide and (arch_id == "bilge_sprite" or arch_id == "chimehead") and not is_elite:
			var cpos: Vector3 = sp["pos"] + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)) * info.tile * 0.5
			_spawn_enemy({"pos": cpos, "room": int(sp.get("room", 0))}, arch_id, false)
		elif hungry_walls and not is_elite and rng.randf() < 0.45:
			var hpos: Vector3 = sp["pos"] + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)) * info.tile * 0.5
			_spawn_enemy({"pos": hpos, "room": int(sp.get("room", 0))}, arch_id, false)
	if String(biome.get("name", "")) == "Sunken Reliquary" and not boss_floor and info.ranges.size() > 1:
		# KING'S EMISSARY — penjaga gudang mahkota selalu berdiri di ruang terakhir
		var er: Dictionary = info.ranges[last_room]
		var epp := Vector3((er["x0"] + er["x1"]) * 0.5 * info.tile, 0.0, (er["z0"] + er["z1"]) * 0.5 * info.tile)
		_spawn_enemy({"pos": epp, "room": last_room}, "crowned", true)
	if bone_chorus:
		# satu orator per ruangan — paduan suara penggugah perang
		for bci in range(info.ranges.size()):
			if bci == last_room and boss_floor:
				continue
			var bcr: Dictionary = info.ranges[bci]
			var bcp := Vector3((bcr["x0"] + bcr["x1"]) * 0.5 * info.tile, 0.0, (bcr["z0"] + bcr["z1"]) * 0.5 * info.tile)
			_spawn_enemy({"pos": bcp, "room": bci}, "orator", false)
	sunken_tide = not wolfsbane and not boss_floor and Stats.floor_num >= 11 and Stats.floor_num <= 12 and rng.randf() < 0.18
	low_tide = not wolfsbane and not sunken_tide and not boss_floor and Stats.floor_num >= 11 and Stats.floor_num <= 12 and rng.randf() < 0.15
	if glass_sea:
		Stats.buff_atk_pct -= 0.10
	glass_sea = not wolfsbane and not sunken_tide and not low_tide and not boss_floor and Stats.floor_num >= 11 and Stats.floor_num <= 12 and rng.randf() < 0.15
	deep_current = not wolfsbane and not sunken_tide and not low_tide and not glass_sea and not boss_floor and Stats.floor_num >= 11 and Stats.floor_num <= 12 and rng.randf() < 0.15
	dread_tide = not boss_floor and Stats.floor_num >= 13 and rng.randf() < 0.14
	starved_deep = not dread_tide and not boss_floor and Stats.floor_num >= 13 and rng.randf() < 0.13
	choir = not dread_tide and not starved_deep and not boss_floor and Stats.floor_num >= 13 and rng.randf() < 0.12
	abyssal_hymn = not choir and not dread_tide and not starved_deep and not boss_floor and Stats.floor_num >= 13 and rng.randf() < 0.08
	dead_calm = not choir and not dread_tide and not starved_deep and not abyssal_hymn and not boss_floor and Stats.floor_num >= 13 and rng.randf() < 0.07
	if dead_calm:
		Stats.event_soul_bonus = 1
	if abyssal_hymn:
		Stats.event_soul_bonus = 1
	dead_weight = not choir and not dread_tide and not starved_deep and not abyssal_hymn and not dead_calm and not boss_floor and Stats.floor_num >= 14 and rng.randf() < 0.08
	Stats.dead_weight = dead_weight
	shell_game = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and not grave_hunger and not giant_hall and not shrouded and not ossuary and not mirror_hall and not ashfall and not hungry_walls and not candlelit and not verdant and not umbral_tide and not abyssal_patience and not choir and Stats.floor_num >= 11 and Stats.floor_num <= 12 and rng.randf() < 0.15
	for evf in ["blood_moon", "soul_rush", "fading_light", "echoing", "storm_cellar", "gilded_tides", "soul_drift", "grave_hunger", "giant_hall", "shrouded", "ossuary", "mirror_hall", "ashfall", "hungry_walls", "candlelit", "verdant", "bone_chorus", "wolfsbane", "sunken_tide", "low_tide", "glass_sea", "deep_current", "dread_tide", "starved_deep", "choir", "shell_game", "abyssal_hymn", "dead_calm", "dead_weight", "thin_veil", "low_water", "drift_tide", "soul_swarm", "gauntlet", "brisk", "shoal_tide", "salvage_tide", "gale_tide", "mercy_tide", "eel_tide", "swell_tide", "kelp_bed", "barnacle_bloom", "sodden", "bile_tide", "mire_hollow", "dark_lantern", "halfwreck", "merchant_tide", "hungry_urns", "bilge_run", "pale_squall", "soul_flush", "kings_tithe", "tar_smear", "black_calm", "bilge_iron", "gun_smoke", "greedy_tide", "drift_wreck", "chorus_cut", "long_watch", "fog_lantern_d", "crowns_rest", "salted_deck", "pale_scrip", "rat_ration", "crows_tide", "powder_toll", "wet_wool", "melody_ledger", "long_night", "ballast_beads", "dowser_knot", "crowns_vigil", "halfway_dead", "deck_manifest", "dirge_note", "line_splice", "salt_rosary", "crowns_decree", "rich_vein", "wraiths_due", "pale_lantern_ev", "saltgrave_ev", "leeward_ev", "brine_smoke", "crowns_ransom", "bilge_strike", "full_draught", "salt_front", "cold_snap", "full_moon", "gunners_luck", "shallow_graves", "wailing_wind", "balmy_sea", "rust_storm", "ember_wake", "saltsick", "gallows_tide", "pilot_light", "widdershins", "slack_water", "salvage_breeze", "deep_salve", "keel_spirit", "lantern_wake", "fog_bank", "tide_clock", "deep_well", "bilge_still", "keel_groan", "saltwind", "bone_lantern", "dead_reckoning", "gloom_tide", "pale_wake", "murk_lift", "siren_hum", "grim_calm", "keel_haul", "weeping_tide", "deep_draught", "thick_tide", "slack_line", "low_lantern", "mirage_sea", "bilge_lull"]:
		if get(evf):
			events_run[evf] = true
			break
	if events_run.size() > 0 and Stats.relics.has("tide_lock"):
		Stats.earn_souls(1)
		_souls_l()
	if events_run.size() >= 3:
		_ach("bilge_dancer")
	if events_run.size() >= 5:
		_ach("stormwatcher")
	if powder_toll:
		Stats.buff_atk_pct -= 0.15
		powder_toll = false
	if bilge_lull:
		Stats.soul_gain_pct += 0.05
	if glass_sea:
		Stats.buff_atk_pct += 0.10
	if wolfsbane:
		# PACK ALPHA — kawanan dipimpin induk raksasa di ruangan terakhir
		var ar: Dictionary = info.ranges[last_room]
		var apos := Vector3((ar["x0"] + ar["x1"]) * 0.5 * info.tile, 0.0, (ar["z0"] + ar["z1"]) * 0.5 * info.tile)
		var alp := _spawn_enemy({"pos": apos, "room": last_room}, "hound", true)
		if alp != null:
			alp.scale *= 1.5
			alp._base_scale = alp.scale
			alp.champion = true
	if Stats.floor_num >= 20 and not boss_floor:
		# sang pembawa pesan Raja — satu elite herald berpatroli di lantai-lantai terdalam
		var hr: Dictionary = info.ranges[rng.randi_range(1, last_room)]
		var hpos2 := Vector3((hr["x0"] + hr["x1"]) * 0.5 * info.tile, 0.0, (hr["z0"] + hr["z1"]) * 0.5 * info.tile)
		var her := _spawn_enemy({"pos": hpos2, "room": int(info.ranges.find(hr))}, "bone_king", false)
		if her != null:
			her.scale *= 0.62
			her._base_scale = her.scale
			her.hp *= 0.35
			her.hp_max = her.hp
			her.speed *= 1.25
			her.xp_val = int(her.xp_val * 1.6)
			her.champion = true
			her.activated = true
	if boss_floor:
		var lr: Dictionary = info.ranges[last_room]
		_spawn_enemy({"pos": Vector3((lr["x0"] + lr["x1"]) * 0.5, 0.0, lr["z1"] + 1.6 * info.tile), "room": last_room}, "bone_king", false)
		# CROWN GUARD: lantai takhta mengawal rajanya dengan dua elite
		if Stats.floor_num >= 25:
			var gtab: Array = biome["enemies"]
			for gi2 in range(2):
				var garch := String(gtab[rng.randi_range(0, gtab.size() - 1)])
				var gpos := Vector3((lr["x0"] + lr["x1"]) * 0.5 + (gi2 - 0.5) * 1.4 * info.tile, 0.0, lr["z1"] + 0.8 * info.tile)
				var ge := _spawn_enemy({"pos": gpos, "room": last_room}, garch, true)
				if ge != null:
					ge.activated = true
	else:
		# sarang sang juara (lantai 6+): satu ruangan berisi elite bergaransi
		champ_room = -1
		if Stats.floor_num >= 6 and last_room >= 2:
			champ_room = rng.randi_range(1, last_room - 1)
			if champ_room == ambush_room:
				champ_room = last_room - 1 if ambush_room != last_room - 1 else 1
			var cr: Dictionary = info.ranges[champ_room]
			var cpos := Vector3((cr["x0"] + cr["x1"]) * 0.5, 0.0, (cr["z0"] + cr["z1"]) * 0.5)
			var champ_arch := "bone_king" if ashfall else String(table[rng.randi_range(0, table.size() - 1)])
			var ch := _spawn_enemy({"pos": cpos, "room": champ_room}, champ_arch, champ_arch != "bone_king")
			var cnd := get_tree().get_nodes_in_group("enemies")[get_tree().get_nodes_in_group("enemies").size() - 1]
			cnd.champion = true
			if champ_arch == "bone_king" and ch != null:
				ch.scale *= 0.72
				ch._base_scale = ch.scale
				ch.hp *= 0.45
				ch.hp_max = ch.hp
				ch.xp_val = int(ch.xp_val * 1.5)
		_spawn_traps(last_room)
		_spawn_urns(last_room)
		_spawn_shrine(last_room)
		_spawn_lore_stone(last_room)
		if not solitary:
			_spawn_cage(last_room)
		_spawn_wisps(last_room)
		_spawn_obelisks(last_room)
		_spawn_lanterns(last_room)
		_spawn_motes()
		if String(biome.get("name", "")) == "Sunken Reliquary":
			_spawn_tidepools()
		if Stats.relics.has("tulang_kesatria") and not solitary:
			_spawn_squire()
	# Sir Vane yang terbebaskan bertempur di setiap lantai hingga run berakhir
	if vane_freed_n > 0 and not solitary:
		_spawn_knight()
	else:
		vane_floors = 0
	_start_quests(boss_floor, int(info.get("room_count", 1)))
	_build_minimap()
	Sfx.play_music("boss" if boss_floor else _biome_track())
	ui.floor_label.text = "Floor %d • %s%s" % [Stats.floor_num, biome["name"], " (NG+%d)" % Stats.ng_plus if Stats.ng_plus > 0 else ""]
	if Stats.floor_num >= 20 and Stats.ng_plus >= 1:
		_ach("ngdeep")
	_souls_l()
	_update_hp(Stats.current_hp)
	_update_xp(Stats.xp, Stats.xp_need(), Stats.level)
	_rebuild_chips()
	_hide_banner()
	_cam_snap()
	tut_active = not Stats.tutorial_done and Stats.floor_num == 1 and not autotest
	tut_step = 0
	moved_accum = 0.0
	quest_moved = 0.0
	quest_last_p = info.player_pos
	if tut_active:
		_tut_show("Slide your thumb on the left side of the screen to move")
		tut_last_pos = player.global_position
	else:
		_tut_hide()
	if Stats.floor_num > 1:
		Sfx.play("door")
	_boss_bar_hide()
	_combo_set(0)
	print("ROOM seed=%d floor=%d biome=%s rooms=%d enemies=%d gates=%d boss=%s" % [seed_val, Stats.floor_num, biome["name"], info.get("room_count", 1), info.enemy_spawns.size(), gates.size(), str(QDB.is_boss_floor(Stats.floor_num))])
	_floor_intro_lines(boss_floor)
	if blood_moon:
		_lvl_banner("☽ BLOOD MOON — THE DEAD HUNGER")
		toast("Enemies +25% HP • +50% XP")
		Sfx.play("roar")
	elif soul_rush:
		_lvl_banner("✦ SOUL RUSH — THE DEAD WEEP GEMS")
		toast("XP gems +60% • +3 souls on clear")
		Sfx.play("quest")
	elif fading_light:
		_lvl_banner("◈ FADING LIGHT — THE TORCHES DIE")
		toast("Enemies +12% speed • +4 souls on clear")
		Sfx.play("thunder")
	elif echoing:
		_lvl_banner("◈ ECHOING HALLS — THE DEEPS REPEAT YOU")
		toast("Skills recharge +25% • +3 souls on clear")
		Sfx.play("shrine")
	elif storm_cellar:
		_lvl_banner("⚡ STORM CELLAR — THE DEEPS TURN ON THEIR OWN")
		toast("Lightning aids you • +2 souls on clear")
		Sfx.play("thunder")
	elif gilded_tides:
		_lvl_banner("★ GILDED TIDES — THE HOARD SURFACES")
		toast("Every chest gilded • +1 soul per kill")
		Sfx.play("quest")
	elif soul_drift:
		_lvl_banner("☆ SOUL DRIFT — THE DEAD'S BREATH WANDERS")
		toast("Wisps abound • +3 souls on clear")
		Sfx.play("xp")
	elif grave_hunger:
		_lvl_banner("☠ GRAVE HUNGER — THE DEAD LOOSE THEIR SOULS")
		toast("Kills may release wisps • +2 souls on clear")
		Sfx.play("roar")
	elif giant_hall:
		_lvl_banner("▲ GIANT'S HALL — THE DEAD GROW TALL")
		toast("Foes tower larger • double XP • +3 souls on clear")
		Sfx.play("roar")
	elif shrouded:
		_lvl_banner("◈ SHROUDED HALLS — THE MAP DIES IN YOUR HANDS")
		toast("No map in the mist • +2 souls on clear")
		Sfx.play("whisper")
	elif ossuary:
		_lvl_banner("☠ OSSUARY NIGHT — THE BONES RISE")
		toast("Crawlers everywhere • double XP • +3 souls on clear")
	elif mirror_hall:
		_lvl_banner("◈ MIRROR HALL — EVERY SOUL REFLECTED")
		toast("Twice the dead • richer gems • +3 souls on clear")
	elif ashfall:
		_lvl_banner("▲ ASHFALL — THE BURNED RAIN DOWN")
		toast("Ash drifts gray • +1 soul per kill • +2 souls on clear")
		Sfx.play("roar")
	elif hungry_walls:
		_lvl_banner("▲ HUNGRY WALLS — THE DEEP BREEDS")
		toast("The corridors teem • +40% foes • +1 soul per kill")
		Sfx.play("roar")
	elif candlelit:
		_lvl_banner("☆ CANDLELIT — A THOUSAND FLAMES")
		toast("The dark retreats • foes −15% HP • +1 soul per kill")
		Sfx.play("shrine")
	elif verdant:
		_lvl_banner("☆ VERDANT BLOOM — LIFE RECLAIMS")
		toast("Roots and moss slow the dead • foes −18% speed • +1 soul per kill")
		Sfx.play("shrine")
	elif bone_chorus:
		_lvl_banner("◆ BONE CHORUS — THE DEEP SINGS")
		toast("An Orator chants in every hall • silence them first • +1 soul per kill")
		Sfx.play("roar")
	elif sunken_tide:
		_lvl_banner("≈ SUNKEN TIDE — THE DROWNED RISE")
	elif low_tide:
		_lvl_banner("≈ LOW TIDE — THE VAULTS LIE BARE")
	elif glass_sea:
		_lvl_banner("≈ GLASS SEA — CALM AND CRUEL")
	elif deep_current:
		_lvl_banner("≈ DEEP CURRENT — THE WATER SEEKS YOU")
	elif dread_tide:
		_lvl_banner("◆ DREAD TIDE — THE ABYSS SWELLS")
	elif starved_deep:
		_lvl_banner("☆ STARVED DEEP — THE DARK IS HUNGRY")
		toast("Souls ferment in the black • wisps pay double • foes +10% HP")
		Sfx.play("souls")
	elif choir:
		_lvl_banner("☗ CHOIR BELOW — TEN THOUSAND VOICES")
	elif shell_game:
		_lvl_banner("▲ SHELL GAME — THE CLAMS CLAMP SHUT")
		toast("Every clam sleeps half again as long • but pearls pay double")
		toast("The drowned choir rehearses • enemy shots fly 40% faster")
		Sfx.play("souls")
		if Stats.relics.has("choir_alms"):
			Stats.earn_souls(3)
			_souls_l()
			toast("CHOIR ALMS — the drowned pay the singer's toll: +3 souls")
		toast("The dark pays out • +1 soul per kill • foes strike +10% harder")
		Sfx.play("roar")
		toast("The dead smell you from across the halls • +50% sight • +1 soul per kill")
		Sfx.play("roar")
		toast("The water is still — the dead move faster • +10% ATK this floor")
		Sfx.play("souls")
	elif wolfsbane:
		_lvl_banner("☽ WOLFSBANE — THE PACK HUNTS")
		toast("Nothing but hounds this floor — keep your back to a wall • +1 soul per kill")
		Sfx.play("roar")
	elif thin_veil:
		_lvl_banner("◈ THIN VEIL — THE DEAD SHINE THROUGH")
		toast("The dead are +15% harder to fell — but the floor tithes +2 souls")
		Sfx.play("souls")
	elif low_water:
		_lvl_banner("≈ LOW WATER — THE TIDE RETREATS")
		toast("The dead wade slower through the shallows • the floor tithes +2 souls")
		Sfx.play("souls")
	elif drift_tide:
		_lvl_banner("≋ DRIFT TIDE — THE SOULS DRIFT DEEP")
		toast("The dead are +10% hardier • the floor tithes +3 souls")
		Sfx.play("souls")
	elif soul_swarm:
		_lvl_banner("◈ SOUL SWARM — WISPS RIDE THE DEAD")
		toast("Every foe carries a wisp • the floor tithes +2 souls")
		Sfx.play("souls")
	elif gauntlet:
		_lvl_banner("⚔ GAUNTLET — THE DEAD FIGHT HARDER")
		toast("Their blows +15% • your lessons +15% XP • the floor tithes +2 souls")
		Sfx.play("souls")
	elif brisk:
		_lvl_banner("≈ BRISK TIDE — THE WATER RUNS QUICK")
		toast("Your dash recharges 30% faster • the floor tithes +2 souls")
		Sfx.play("souls")
	elif shoal_tide:
		_lvl_banner("≋ SHOAL TIDE — THE WATER KNEELS")
		toast("Foes drag in the shallows • your step +8% • the floor tithes +2 souls")
		Sfx.play("souls")
	elif salvage_tide:
		_lvl_banner("◈ SALVAGE TIDE — THE WRECKS GIVE UP THEIR GOLD")
		toast("Kills may spill loose souls • the floor tithes +2 souls")
		Sfx.play("souls")
	elif gale_tide:
		_lvl_banner("≈ GALE TIDE — THE WIND RUNS WILD")
		toast("The dead run +10% quicker • your skills recharge +15% • the floor tithes +2 souls")
		Sfx.play("souls")
	elif mercy_tide:
		_lvl_banner("≋ MERCY TIDE — THE WATER IS KIND TONIGHT")
		toast("The dead wade 8% slower • the floor tithes +1 soul")
		Sfx.play("souls")
	elif eel_tide:
		_lvl_banner("≋ EEL TIDE — THE DEAD WRITHE WITH SPARK")
		toast("Your kills may shake loose soul vials • the floor tithes +1 soul")
		Sfx.play("souls")
	elif swell_tide:
		_lvl_banner("≋ SWELL TIDE — THE SEA RISES TO MEET YOU")
		toast("The dead swell +20% tougher • but pay +25% XP • the floor tithes +1 soul")
		Sfx.play("souls")
	elif kelp_bed:
		_lvl_banner("≋ KELP BED — THE FLOOR GOES GREEN AND SLOW")
		toast("The dead wade kelp-tangled −10% speed • but −10% sturdier • the floor tithes +1 soul")
		Sfx.play("souls")
	elif barnacle_bloom:
		_lvl_banner("≋ BARNACLE BLOOM — THE DEAD GROW THICK SHELLS")
		toast("The dead arrive barnacle-plated +15% HP • but their shells spill souls • the floor tithes +1")
		Sfx.play("souls")
	elif sodden:
		_lvl_banner("≋ SODDEN HALLS — EVERYTHING DRIPS AND DRAGS")
		toast("The dead slog −12% speed • but your skills recharge +15% slower • the floor tithes +1")
		Sfx.play("souls")
	elif bile_tide:
		_lvl_banner("≋ BILE TIDE — THE WATER ITSELF IS SICK")
		toast("Every blow they land poisons your veins a breath • the floor tithes +1")
		Sfx.play("souls")
	elif mire_hollow:
		_lvl_banner("≋ MIRE HOLLOW — THE FLOOR SWALLOWS YOUR STEP")
		toast("You sink −12% speed • the dead feed on the hollow +10% HP • the floor tithes +1")
		Sfx.play("souls")
	elif dark_lantern:
		_lvl_banner("≋ DARK LANTERN — THE LIGHTS GO THIN DOWN HERE")
		toast("The dead move +10% faster in the gloom • but the dark teaches +15% XP • the floor tithes +1")
		Sfx.play("souls")
	elif halfwreck:
		_lvl_banner("≋ HALFWRECK — THE SHIP SPLIT, SO DID THE CREW")
		toast("Elites rise +15% more often • but each wreck-blessed pays +30% XP • the floor tithes +1")
		Sfx.play("souls")
	elif merchant_tide:
		_lvl_banner("≋ MERCHANT TIDE — EVERY SHOP STALL FLOATS PAST")
		toast("Every price on this floor cuts −20% • the floor tithes +1")
		Sfx.play("souls")
	elif hungry_urns:
		_lvl_banner("≋ HUNGRY URNS — THE POTS HAVE TEETH")
	elif bilge_run:
		_lvl_banner("≋ BILGE RUN — EVERY SNARE IS LOADED")
	elif pale_squall:
		_lvl_banner("≋ PALE SQUALL — THE RAIN OUTRUNS THE DEAD")
	elif soul_flush:
		_lvl_banner("≋ SOUL FLUSH — THE DEAD SEEP VIALS")
	elif kings_tithe:
		_lvl_banner("≋ KING'S TITHE — HE WANTS HIS SHARE")
	elif black_calm:
		_lvl_banner("≋ BLACK CALM — THE DEAD DRIFT SLOW")
	elif gun_smoke:
		_lvl_banner("≋ GUN SMOKE — THE AIR SMELLS OF POWDER")
	elif greedy_tide:
		_lvl_banner("≋ GREEDY TIDE — EVERY PRICE SOFTENS")
	elif drift_wreck:
		_lvl_banner("≋ DRIFT WRECK — THE SEA GIVES BACK")
	elif long_watch:
		_lvl_banner("≋ LONG WATCH — THE DEAD SEE FAR")
	elif salted_deck:
		_lvl_banner("≋ SALTED DECK — THE BOARDS BITE")
	elif crows_tide:
		_lvl_banner("≋ CROW'S TIDE — SPRITES AND BELLS")
	elif long_night:
		_lvl_banner("≋ LONG NIGHT — NO DAWN DOWN HERE")
	elif halfway_dead:
		_lvl_banner("≋ HALFWAY DEAD — THE TIDE CULLED THEM FIRST")
	elif rich_vein:
		_lvl_banner("≋ RICH VEIN — THE DEAD COME DOWN HEAVY")
		toast("Every corpse is heavier with souls • kills pay +1 • the floor tithes +2")
		Sfx.play("souls")
	elif wraiths_due:
		_lvl_banner("≋ WRAITHS' DUE — THE DEAD CLAIM THEIR CUT")
		toast("Pale light on the waterline • every kill spills +1 soul • the floor tithes +1")
		Sfx.play("souls")
	elif pale_lantern_ev:
		_lvl_banner("≋ PALE LANTERN — THE LOST LIGHT THE WAY")
	elif saltgrave_ev:
		_lvl_banner("≋ SALTGRAVE — THE DEAD SIT THICK ON THE BONES")
	elif leeward_ev:
		_lvl_banner("≋ LEEWARD — A FAIR WIND FOR LIVING AND DEAD")
	elif brine_smoke:
		_lvl_banner("≋ BRINE SMOKE — THE DEAD CAN'T SMELL YOU HERE")
	elif crowns_ransom:
		_lvl_banner("≋ CROWN'S RANSOM — THE KING PAYS FOR ROYAL BLOOD")
	elif bilge_strike:
		_lvl_banner("≋ BILGE STRIKE — THEY HIT HARD, THEY BLEED SWEET")
	elif full_draught:
		_lvl_banner("≋ FULL DRAUGHT — THE WRECK OFFERS UP ITS DREGS")
	elif salt_front:
		_lvl_banner("≋ SALT FRONT — THE DEAD WADE SLOW AND SOFT")
	elif cold_snap:
		_lvl_banner("≋ COLD SNAP — ICE IN THE RIGGING")
		toast("The dead freeze stiff −15% speed... but cold fingers charge your skills +15% slower")
		Sfx.play("roar")
	elif full_moon:
		_lvl_banner("≋ FULL MOON — THE DEAD WEIGH HEAVY WITH SOULS")
		toast("Every soul this floor pays +50%")
		Stats.soul_gain_pct += 0.5
		Sfx.play("quest")
	elif gunners_luck:
		_lvl_banner("≋ GUNNER'S LUCK — LOOSE POWDER, LOOSE COINS")
		toast("Every kill this floor spills +1 soul")
		Stats.event_soul_bonus += 1
		Sfx.play("quest")
	elif shallow_graves:
		_lvl_banner("≋ SHALLOW GRAVES — THEY RISE HALF-BURIED ALREADY")
	elif wailing_wind:
		_lvl_banner("≋ WAILING WIND — THE AIR ITSELF CRIES OUT")
	elif balmy_sea:
		_lvl_banner("≋ BALMY SEA — THE WATER ALMOST FORGIVES")
	elif rust_storm:
		_lvl_banner("≋ RUST STORM — IRON RAIN EATS EVERYTHING")
	elif ember_wake:
		_lvl_banner("≋ EMBER WAKE — THE CURRENT BURNS BEHIND YOU")
	elif saltsick:
		_lvl_banner("≋ SALTSICK — THE BRINE RUNS IN YOUR VEINS")
	elif gallows_tide:
		_lvl_banner("≋ GALLOWS TIDE — THE HANGED WATCH THEIR OWN")
	elif pilot_light:
		_lvl_banner("≋ PILOT LIGHT — THE BLUE LAMP BURNS FOR YOU")
	elif widdershins:
		_lvl_banner("≋ WIDDERSHINS — THE TURN RUNS BACKWARD")
		toast("The floor spins against the sun — foes quicken +10%, but you slip easier +8% dodge")
		Sfx.play("quest")
	elif slack_water:
		_lvl_banner("≋ SLACK WATER — THE TIDE FORGETS TO MOVE")
		toast("The water holds even the dead — foes −12% speed, but your arm tires −8% ATK")
		Sfx.play("quest")
	elif salvage_breeze:
		_lvl_banner("≋ SALVAGE BREEZE — A LUCKY WIND")
		toast("The wind smells of salvage — foes teach +10% XP and your step lightens +5% speed")
		Sfx.play("quest")
	elif deep_salve:
		_lvl_banner("≋ DEEP SALVE — THE WATER REMEMBERS MENDING")
		toast("The tide carries a healer's touch — orbs mend +40%, but the dead study −15% XP")
		Sfx.play("quest")
	elif keel_spirit:
		_lvl_banner("≋ KEEL SPIRIT — THE HULL'S OWN GHOST WALKS")
		toast("The ship's ghost guards her own — foes swing −10% softer, but the lessons thin −8% XP")
		Sfx.play("quest")
	elif lantern_wake:
		_lvl_banner("≋ LANTERN WAKE — THE DEAD FOLLOW THE LIGHT")
		toast("Your wake draws them glowing — foes +10% speed, but the purse pays +15% souls")
		Sfx.play("quest")
	elif fog_bank:
		_lvl_banner("≋ FOG BANK — THE DEAD LOSE YOUR SCENT")
		toast("The fog swallows your trail — foes notice you later, but the lessons thin −10% XP")
		Sfx.play("quest")
	elif tide_clock:
		_lvl_banner("≋ TIDE CLOCK — THE WATER RUNS SLOW")
		toast("The sea moves like syrup — foes −10% speed, but the purse pays −5% souls")
		Sfx.play("quest")
	elif deep_well:
		_lvl_banner("≋ DEEP WELL — THE DARKNESS POOLS HERE")
		toast("The well feeds the dead — foes +15% damage, but the orbs mend ×1.5")
		Sfx.play("quest")
	elif bilge_still:
		_lvl_banner("≋ BILGE STILL — THE WATER FORGETS TO MOVE")
		toast("Even the dead drowse — foes −12% speed, but the lessons thin −8% XP")
		Sfx.play("quest")
	elif keel_groan:
		_lvl_banner("≋ KEEL GROAN — THE OLD SHIP SOUNDS HER DEPTH")
		toast("The timbers swell the dead +10% HP — but the groaning teaches +10% XP")
		Sfx.play("quest")
	elif saltwind:
		_lvl_banner("≋ SALTWIND — THE GALE CARRIES THE DEAD")
		toast("The wind rides the dead +10% speed — but it pays well: +3 souls on clear")
		Sfx.play("quest")
	elif bone_lantern:
		_lvl_banner("≋ BONE LANTERN — THE DEAD BURN BRIGHT TONIGHT")
		toast("The lantern feeds their fists +10% damage — but every kill spills +1 soul")
		Sfx.play("quest")
	elif dead_reckoning:
		_lvl_banner("≋ DEAD RECKONING — THE SEA COUNT YOU HER DEBTOR")
		toast("The dead come fiercer +8% speed & damage — but the reckoning teaches +15% XP")
		Sfx.play("quest")
	elif gloom_tide:
		_lvl_banner("≋ GLOOM TIDE — THE LIGHT GOES OUT SLOW")
		toast("The deep dims — foes drift −8% speed, and the stillness teaches +8% XP")
		Sfx.play("quest")
	elif pale_wake:
		_lvl_banner("≋ PALE WAKE — THE DEAD LEAVE THEIR LANTERNS LIT")
		toast("Every slain thing may shed a soul wisp — harvest them all")
		Sfx.play("quest")
	elif murk_lift:
		_lvl_banner("≋ MURK LIFT — THE BOTTOM COMES UP SLOW")
		toast("The silt rises under them — foes wade −10% speed, lessons +10% XP")
		Sfx.play("quest")
	elif siren_hum:
		_lvl_banner("≋ SIREN HUM — A SONG THE DEAD CAN'T REFUSE")
		toast("The hum slows their blood −12% speed — but they fight mad +8% damage")
		Sfx.play("quest")
	elif grim_calm:
		_lvl_banner("≋ GRIM CALM — THE SEA HOLDS ITS BREATH")
		toast("The still waters bare their teeth +10% damage — but the deep pays +10% souls")
		Sfx.play("quest")
	elif keel_haul:
		_lvl_banner("≋ KEEL HAUL — THE SHIP DRAGS HER CATCH")
		toast("The haul drives them fast +12% speed — but the take is rich +12% XP")
		Sfx.play("quest")
	elif weeping_tide:
		_lvl_banner("≋ WEEPING TIDE — THE WRECK MOURNS HER OWN")
		toast("Their grief wears thin −8% HP — but grief hardens +8% damage")
		Sfx.play("quest")
	elif deep_draught:
		_lvl_banner("≋ DEEP DRAUGHT — THE KEEL RUNS LOW")
		toast("The water sits heavy +10% HP on them — but they wade slow −10% speed")
		Sfx.play("quest")
	elif thick_tide:
		_lvl_banner("≋ THICK TIDE — THE WATER CLOGS EVERY STRIDE")
		toast("Everything wades slower −8% speed — thick water teaches +10% XP")
		Sfx.play("quest")
	elif slack_line:
		_lvl_banner("≋ SLACK LINE — THE RIGGING RUNS LOOSE")
		toast("Your skills drag +20% recharge — the crew wades −10% speed")
		Sfx.play("quest")
	elif bilge_lull:
		_lvl_banner("≋ BILGE LULL — THE DEAD DOZE IN THE BILGE")
		toast("The wreck sleeps lightly — foes notice −20% later, and the calm pays +5% souls")
		Sfx.play("quest")
	elif mirage_sea:
		_lvl_banner("≋ MIRAGE SEA — THE HORIZON LIES")
		toast("The dead look thicker than they are — foes +12% HP, but the haze pays +12% XP")
		Sfx.play("quest")
	elif low_lantern:
		_lvl_banner("≋ LOW LANTERN — THE LIGHT RUNS THIN")
		toast("The dark helps you slip +10% dodge — the dead notice −15% later")
		Sfx.play("quest")
		toast("The lamp's glare misleads them — foes notice you −15% later, and the light pays +10% souls")
		Sfx.play("quest")
		toast("The noose-men are stubborn — foes +12% HP, but the hanged pay +15% souls")
		Sfx.play("quest")
		toast("Your hands tremble with salt — skills charge +20% slower, but the fevered dead teach +15% XP")
		Sfx.play("quest")
		toast("Your blade drinks the heat — +10% ATK, but the dead ride the surge +10% faster")
		Stats.buff_atk_pct += 0.1
		Sfx.play("quest")
		toast("The storm sharpens every edge — the dead swing +1 harder but flake −15% vigor")
		Sfx.play("quest")
		toast("A kind tide — orbs mend +50%, and the dead swing −10% softer")
		Sfx.play("quest")
		toast("The wail carries your scent — foes scent you 20% farther, but the wind teaches (+10% XP)")
		Stats.buff_xp_pct += 0.1
		Sfx.play("quest")
		toast("The dead rise thin — −15% vigor")
		omen_hp_mult *= 0.85
		Sfx.play("quest")
		toast("A brined wind slackens every blow −10%")
		Sfx.play("quest")
		toast("Every orb this floor mends double")
		Sfx.play("quest")
		toast("The dead swing +10% harder... but every wound they take bleeds orbs +50%")
		Sfx.play("roar")
		toast("His elites stalk this floor +20% more often... each pays a soul more")
		Sfx.play("roar")
		toast("Thick brume — the dead notice you −15% slower • the floor tithes +1")
		Sfx.play("souls")
		toast("The current runs your way +15% speed... but it carries the dead +10% faster too")
		Sfx.play("whirl")
		toast("The salt keeps them standing +10% longer... but every soul pays +20%")
		Sfx.play("souls")
		toast("Wisps gather thick tonight • every kill spills +1 soul • the floor tithes +1")
		Sfx.play("souls")
		toast("The dead arrive already dying • the floor tithes +1")
		Sfx.play("souls")
		toast("The dark comes early and stays • the floor tithes +2")
		Sfx.play("souls")
		toast("The sprite-packs run thick (×2) • the floor tithes +1")
		Sfx.play("souls")
		toast("Traps bite +1 harder • defusing pays +1 soul extra • the floor tithes +1")
		Sfx.play("souls")
		toast("The dead spot you sooner (+40% aggro) • your feet answer +10% faster • the floor tithes +2")
		Sfx.play("souls")
		toast("The wreck scatters its cargo — urns abound • the floor tithes +1")
		Sfx.play("souls")
		toast("All soul prices −20% this floor • the floor tithes +1")
		Sfx.play("souls")
		toast("Ranged foes fire +30% faster through the smoke • your hands answer +10% faster • the floor tithes +2")
		Sfx.play("souls")
		toast("The dead drift −15% slower... but their blows carry the dark (+15% dmg) • the floor tithes +2")
		Sfx.play("souls")
		toast("The dead strike +20% harder for the crown • but souls pay +50% • the floor tithes +3")
		Sfx.play("souls")
		toast("Soul vials drop +25% more often • the floor tithes +1")
		Sfx.play("souls")
		toast("The dead rush +15% faster • but the squall rots them −10% HP • the floor tithes +1")
		Sfx.play("souls")
		toast("Traps bite for 2 damage • but each defuse pays +2 souls • the floor tithes +1")
		Sfx.play("souls")
		toast("Every urn spills +1 soul • but each one bites for 1 damage • the floor tithes +1")
		Sfx.play("souls")
	elif sunken_tide:
		toast("The drowned shuffle slower • +1 soul per kill")
		Sfx.play("souls")
	elif low_tide:
		toast("Wisps and urns pay double souls this floor")
		Sfx.play("souls")
	elif Stats.floor_num > 1:
		_lvl_banner("FLOOR %d — %s" % [Stats.floor_num, String(biome["name"]).to_upper()])


func _build_gates() -> void:
	gates.clear()
	for d in info.get("doors", []):
		var g = GATE.new()
		room.add_child(g)
		g.position = d["pos"]
		g.setup(info.tile, info.wall_h)
		gates[int(d["room"])] = g


func _room_at(z: float) -> int:
	# margin sisi selatan (arah pintu masuk): pemain harus benar-benar masuk
	# ruangan sebelum dianggap pindah, supaya gerbang tidak menutup di badannya
	var margin: float = 0.3 * float(info.get("tile", 4.0))
	var rs: Array = info.get("ranges", [])
	for i in range(rs.size()):
		var r: Dictionary = rs[i]
		if z <= r["z0"] - margin and z > r["z1"]:
			return i
	return -1


func _room_alive(ri: int) -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.room_idx == ri:
			n += 1
	return n


func _set_room_gates(ri: int, open: bool) -> void:
	for gi in [ri - 1, ri]:
		if gates.has(gi):
			var g = gates[gi]
			if g.open != open:
				g.set_open(open)
				_update_minimap()
				if open:
					Sfx.play("door")
				else:
					Sfx.play("gate")
					_burst(g.global_position + Vector3(0, 0.2, 0), Color(0.7, 0.65, 0.6))


const WHISPERS := [
	"He knows your name, Kael. He has always known.",
	"The bones here once served a kinder crown.",
	"Don't linger — the dark takes interest.",
	"Somewhere below, his throne is listening.",
	"Spirits mark you, warrior. Even Mahzan noticed.",
	"You bleed and they remember — every drop.",
	"A hero once died at that very spot.",
	"His patience thins with every room you clear.",
	"The deeper you descend, the louder his ledger turns.",
	"Every cage you break, the crown counts twice.",
	"Salt is just water that learned to keep score.",
	"The widows spin even here — their webs hold more than bones.",
	"He counts powder kegs like prayers, Kael. Mind the sparks.",
]

# bisikan sekali-per-run saat arketipe pertama kali muncul
const FIRST_SEEN := {
	"brute": "A Brute holds the way — patient swings break patient bone.",
	"bomber": "That one burns to touch — let it chase, never stand still.",
	"crawler": "Crawlers — small, quick, and never alone.",
	"archer": "Arrows from the dark — flank the archers, Kael.",
	"necromancer": "The Necromancer props death's door open — shut it.",
	"gaoler": "A Gaoler — the crown's own brother. Mind his chains.",
	"weeper": "A Weeper chants ahead — cut his song short.",
	"sentinel": "A Bone Sentinel — it cannot chase. Only kill.",
	"shade": "A Shade walks these halls — it wears dead men's shortcuts.",
	"hexer": "A Hex Priest croaks his curses — his bolt seals your skills.",
	"spiker": "A Spiked Cadaver shambles up — its thorns punish every melee hit.",
	"lurker": "Something waits unseen in these rooms, Kael — walk their edges first.",
	"golem": "A Bone Golem blocks the way — its slams swallow whole rooms.",
	"maiden": "A pale mourner drifts ahead — kill her last, or her cry raises the room.",
	"revenant": "A Revenant stands guard — shatter his tombstone before he climbs out.",
	"shieldbearer": "A Shieldbearer holds the lane — his shield drinks frontal steel; flank him.",
	"herald": "A Herald strides ahead — his cry will harden the room; silence him first.",
	"batterer": "A Batterer lumbers ahead — one swing throws you across the room.",
	"duelist": "A Pale Duelist salutes you — it will lunge first; greet it sideways.",
	"hound": "Bone Hounds circle — pack hunters. Break the circle before it closes.",
	"moth": "A Soul Moth flutters free — catch its lantern before it drifts off.",
	"orator": "A Grave Orator begins to sing — silence it before the whole room sharpens.",
	"crowned": "A fallen paladin still wears its crown — the dead rally behind it.",
	"tither": "A Tithing comes to collect — the King's tax, paid in souls.",
	"digger": "A Gravedigger wakes — it buried something where you're standing.",
	"drowned": "A Drowned One surfaces — the tide gave it back, and it brought treasure.",
	"keelhound": "A Keelhound shakes the salt off — it smells the souls in your purse.",
	"maw": "A Barnacle Maw parts its shell — something old and hungry looks back.",
	"siren": "The Void Siren hums — and suddenly you're walking toward her.",
	"gargoyle": "A Pearl Gargoyle unglues itself from the wall — the temple still has guardians.",
	"bilge_witch": "A Bilge Witch croons — her bolts carry the deep's own chill.",
	"rust_jaw": "A Rust Jaw grins — its bite corrodes the finest steel.",
	"salt_herald": "A Salt Herald lumbers close — the salt within is never truly one.",
	"hull_widow": "A Hull Widow descends — her webs root fast; keep your distance.",
	"deck_gunner": "A Deck Gunner racks a double load — two shots come, not one.",
	"keelbeak": "A Keelbeak wheels — it pecks, then hops clear of your blade.",
	"mireling": "A Mireling skitters — its bite carries the marsh's cold.",
	"saltghast": "A Saltghast shimmers in — strike where it settles, and pocket the soul it carries.",
	"waver": "A Waver sways into sight — its bolt steals the strength from your arm; close fast.",
	"tide_bailiff": "A Tide Bailiff strides in — every blow it lands seizes a soul.",
	"brine_monk": "A Brine Monk bows its head — its open palm saps the strength from your arm.",
	"deck_rigger": "A Deck Rigger unfurls its line — its hook bites from farther than you think.",
	"salt_skimmer": "A Salt Skimmer shears across the water — it comes at you fast."
}


func _ambush(ri: int) -> void:
	ambushed_room = ri
	Sfx.play("roar")
	_lvl_banner("AMBUSH!")
	var r: Dictionary = info.ranges[ri]
	var table: Array = biome["enemies"]
	var n := 3 + (1 if Stats.floor_num >= 10 else 0)
	for i in range(n):
		var p := Vector3(rng.randf_range(r["x0"], r["x1"]), 0.0, rng.randf_range(r["z0"], r["z1"]))
		_spawn_enemy({"pos": p, "room": ri}, table[rng.randi_range(0, table.size() - 1)], rng.randf() < 0.2)


func _on_room_enter(ri: int) -> void:
	# penyergapan meletus — spawn dulu supaya loop aktivasi di bawah menyalakan mereka
	if ri == ambush_room:
		ambush_room = -1
		_ambush(ri)
	for e in get_tree().get_nodes_in_group("enemies"):
		e.activated = e.room_idx == ri
		if e.activated and not umbral_seen and bool(e.get("elite")) and String(e.get("affix")) == "umbral":
			umbral_seen = true
			Sfx.play("whisper")
			_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "UMBRAL — it was never really there", Color(0.6, 0.5, 1.1), true)
	_quest_event("reach_room", ri)
	if ui.has("kills_label"):
		ui.kills_label.text = "☠ %d  ·  FOES %d" % [kills_run, _room_alive(ri)]
	# bisikan Oracle: atmosfer ambient di ruangan yang hidup (bukan lantai bos)
	if Stats.floor_num >= 2 and not QDB.is_boss_floor(Stats.floor_num) and ri > 0 and _room_alive(ri) > 0 and rng.randf() < 0.14 and player != null:
		Sfx.play("page")
		var wline: String = WHISPERS[rng.randi_range(0, WHISPERS.size() - 1)]
		if Stats.nemesis != "" and rng.randf() < 0.5:
			wline = "The one that ended you walks these halls again, Kael. End it back."
		_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), wline, Color(0.55, 1.0, 0.75), true)
	if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.activated:
		Sfx.play("roar")
		Sfx.play_music("boss")
	if _room_alive(ri) > 0:
		_set_room_gates(ri, false)
		if ri > 0:
			if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.room_idx == ri:
				toast(boss_name + " BLOCKS YOUR PATH — slay him!")
			elif ri == champ_room:
				Sfx.play("roar")
				toast("A CHAMPION holds this room — best him for better spoils!")
			elif ri == ambushed_room:
				toast("AMBUSH! The bones rise — hold your ground!")
			else:
				toast("Room locked — slay all skeletons!")
		print("RUANGAN %d TERKUNCI (musuh=%d)" % [ri, _room_alive(ri)])


func _spawn_player(pos: Vector3) -> void:
	player = preload("res://player.gd").new()
	var model: Node3D = load(CHARS + "Skeleton_Warrior.glb").instantiate()
	player.add_child(model)
	player.setup(M.toon(skeleton_tex, Color(1, 1, 1), 0.4, true), info.tile, info)
	player.position = pos
	room.add_child(player)
	player.hp_changed.connect(_on_player_hp)
	player.died.connect(_on_player_died)
	player.hit_landed.connect(_on_hit_landed)
	player.attacked.connect(_on_player_attacked)
	player.stepped.connect(_step_dust)
	player.revived.connect(_on_player_revived)


func _on_player_hp(hp: float) -> void:
	Stats.current_hp = hp
	_update_hp(hp)


func _on_player_revived() -> void:
	revives_run += 1
	_lvl_banner("SOUL RISEN!")
	_burst(player.global_position, Color(1.0, 0.9, 0.5))
	_souls(player.global_position, 16, Color(0.6, 1.0, 0.75))
	toast("Soul Risen saved you — half HP restored")
	if knight_ref != null and is_instance_valid(knight_ref):
		var vbark: Array = ["Not today, swordsman. Not while I still march beside you.", "Death refused you once. Do not make a habit of it.", "On your feet, Kael — the dead do not get to keep you."]
		_damage_number(knight_ref.global_position + Vector3(0, 0.9 * info.tile, 0), vbark[rng.randi() % vbark.size()], Color(0.7, 0.9, 1.1), false)


func _on_player_attacked() -> void:
	if tut_active and tut_step == 1:
		tut_step = 2
		_tut_show("Slay all skeletons on this floor!")
	_slash_vfx()


func _slash_vfx() -> void:
	if player == null or not is_instance_valid(player):
		return
	var q := PlaneMesh.new()
	q.size = Vector2(1.1 * info.tile, 0.42 * info.tile)
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color(0.75, 0.9, 1.0, 0.85)
	mt.emission_enabled = true
	mt.emission = Color(0.6, 0.85, 1.0)
	mt.emission_energy_multiplier = 2.5
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = mt
	var m := MeshInstance3D.new()
	m.mesh = q
	add_child(m)
	var dir := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	m.global_position = player.global_position + dir * 0.55 * info.tile + Vector3(0, 0.45 * info.tile, 0)
	m.rotation.y = player.rotation.y
	m.rotation.x = -1.15
	m.scale = Vector3(0.3, 1, 1)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale:x", 1.25, 0.14).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.16)
	tw.set_parallel(false)
	tw.tween_callback(m.queue_free)


func _souls(pos: Vector3, n := 7, col := Color(0.6, 0.85, 1.0)) -> void:
	var p := CPUParticles3D.new()
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12 * info.tile
	p.direction = Vector3(0, 1, 0)
	p.spread = 35.0
	p.gravity = Vector3(0, 0.9 * info.tile, 0)
	p.initial_velocity_min = 0.6 * info.tile
	p.initial_velocity_max = 1.3 * info.tile
	p.damping_min = 0.4 * info.tile
	p.damping_max = 1.0 * info.tile
	p.scale_amount_min = 0.04 * info.tile
	p.scale_amount_max = 0.08 * info.tile
	p.color = col
	add_child(p)
	p.global_position = pos + Vector3(0, 0.35 * info.tile, 0)
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(p.queue_free)


func _step_dust(pos: Vector3) -> void:
	var q := PlaneMesh.new()
	q.size = Vector2(0.22 * info.tile, 0.22 * info.tile)
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# jejak langkah ikut membara saat kombo tinggi
	mt.albedo_color = Color(0.65, 0.58, 0.5, 0.3)
	if combo >= 15:
		mt.albedo_color = Color(1.0, 0.6, 0.25, 0.45)
		mt.emission_enabled = true
		mt.emission = Color(1.0, 0.5, 0.15)
		mt.emission_energy_multiplier = 1.6
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = mt
	var m := MeshInstance3D.new()
	m.mesh = q
	add_child(m)
	m.global_position = pos + Vector3(randf_range(-0.05, 0.05), 0.03 * info.tile, randf_range(-0.05, 0.05))
	m.rotation.x = -PI / 2
	m.scale = Vector3(0.5, 0.5, 1)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1.5, 1.5, 1), 0.45)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.45)
	tw.set_parallel(false)
	tw.tween_callback(m.queue_free)


func _spawn_enemy(sp: Dictionary, arch_id: String, elite: bool, golden := false) -> Enemy:
	var a: Dictionary = EDB.get_arch(arch_id)
	var e = preload("res://enemy.gd").new()
	var model: Node3D = load(CHARS + a["glb"]).instantiate()
	e.add_child(model)
	var tint: Color = a["tint"]
	if elite:
		tint = EDB.ELITE["tint"]
	elif golden:
		tint = Color(1.35, 1.12, 0.45)
	e.setup(M.toon(skeleton_tex, tint, 0.35, true), info.tile, info, arch_id, elite, Stats.floor_num)
	if golden:
		e.golden = true
		e.xp_val *= 3
	if crows_toll and e.elite:
		e.xp_val = int(ceilf(e.xp_val * 1.5))
	if blood_moon and not e.is_boss:
		e.hp *= 1.25
		e.hp_max = e.hp
		e.xp_val = int(ceilf(e.xp_val * 1.5))
		e.speed *= 1.08
	if fading_light and not e.is_boss:
		e.speed *= 1.12
	if flotsam_kin and not e.is_boss:
		e.speed *= 1.08
	if leeward_ev and not e.is_boss:
		e.speed *= 1.1
	if keelmans_toll and not e.is_boss:
		e.speed *= 0.92
	if candlelit and not e.is_boss:
		e.hp *= 0.85
		e.hp_max = e.hp
	if verdant and not e.is_boss:
		e.speed *= 0.82
	if sunken_tide and not e.is_boss:
		e.speed *= 0.85
		e.xp_val = int(ceilf(e.xp_val * 1.2))
	if glass_sea and not e.is_boss:
		e.speed *= 1.15
		e.hp = e.hp * 0.85
		e.hp_max = e.hp
	if deep_current and not e.is_boss:
		e.aggro_range *= 1.5
	if dread_tide and not e.is_boss:
		e.dmg += 1
	if starved_deep and not e.is_boss:
		e.hp = e.hp * 1.1
		e.hp_max = e.hp
	if choir and not e.is_boss and e.proj_speed > 0.0:
		e.proj_speed *= 1.4
	if umbral_tide and not e.is_boss:
		e.speed *= 1.2
	if giant_hall and not e.is_boss:
		e.scale *= 1.3
		e._base_scale = e.scale
		e.hp *= 1.3
		e.hp_max = e.hp
		e.xp_val = int(e.xp_val * 2)
	if omen_hp_mult > 1.0 and not e.is_boss:
		e.hp *= omen_hp_mult
		e.hp_max = e.hp
	if dead_lantern and bool(e.get("elite")):
		e.hp *= 1.15
		e.hp_max = e.hp
	if hull_song:
		e.speed *= 1.05
		M.paint(e, M.toon(skeleton_tex, tint.lerp(Color(0.85, 0.08, 0.08), 0.4), 0.35, true))
	# nemesis: arketipe yang membunuhmu run lalu — kembali lebih keras sampai dibunuh
	if Stats.nemesis != "" and arch_id == Stats.nemesis and not e.is_boss and not nemesis_spawned:
		nemesis_spawned = true
		e.nemesis = true
		e.hp *= 1.6
		if nemesis_bounty:
			e.hp *= 1.25
		e.hp_max = e.hp
		e.speed *= 1.12
		e.dmg += 1
		e.xp_val = int(ceilf(e.xp_val * 1.5))
		M.paint(e, M.toon(skeleton_tex, Color(0.75, 0.12, 0.18), 0.35, true))
		call_deferred("_nemesis_mark", e)
	e.position = sp["pos"]
	e.room_idx = int(sp.get("room", 0))
	# spawn lantai: -1 -> inaktif sampai pemain masuk; summon/split di ruangan aktif langsung hidup
	e.activated = int(sp.get("room", 0)) == current_room
	if rolling_fog:
		e.slow_t = 6.0 if Stats.relics.has("fog_lantern") else 3.0
		e.hp *= 1.08
		e.hp_max = e.hp
	if thin_veil:
		e.hp *= 1.15
		e.hp_max = e.hp
	if low_water:
		e.speed *= 0.88
	if drift_tide:
		e.hp *= 1.1
		e.hp_max = e.hp
	if soul_swarm:
		e.wisp_drop = true
	if gauntlet:
		e.dmg = int(ceil(e.dmg * 1.15))
	if brisk:
		e.speed *= 1.08
	if shoal_tide:
		e.speed *= 0.92
	if song_rust:
		e.speed *= 0.9
	if undertow:
		e.windup_t *= 1.12
	if storm_lull:
		e.windup_t *= 1.15
	if still_water and not e.is_boss:
		e.windup_t *= 1.15
		e.dmg = int(ceil(e.dmg * 1.15))
	if hard_tack and not e.is_boss:
		e.dmg = int(ceil(e.dmg * 1.15))
	if leaden_purse and not e.is_boss:
		e.speed *= 0.9
	if bilge_strike and not e.is_boss:
		e.dmg = int(ceil(e.dmg * 1.1))
	if salt_front and not e.is_boss:
		e.dmg = maxi(1, int(e.dmg * 0.9))
		e.speed *= 0.9
	if cold_snap and not e.is_boss:
		e.speed *= 0.85
	if dirge_half and not e.is_boss:
		e.speed *= 0.9
	if drowned_mercy and not e.is_boss:
		e.dmg = int(e.dmg * 0.92)
	if court_fool and not e.is_boss:
		e.speed *= 0.92
	if low_verse and not e.is_boss:
		e.windup_t *= 1.1
	if fathomsong and not e.is_boss:
		e.aggro_range = float(e.aggro_range) * 0.85
	if wailing_wind and not e.is_boss:
		e.aggro_range = float(e.aggro_range) * 1.2
	if undertow_aria and not e.is_boss:
		e.hp = float(e.hp) * 0.92
		e.hp_max = e.hp
	if balmy_sea and not e.is_boss:
		e.dmg = max(1, int(e.dmg * 0.9))
	if rust_storm and not e.is_boss:
		e.dmg += 1
		e.hp *= 0.85
		e.hp_max = e.hp
	if ember_wake and not e.is_boss:
		e.speed *= 1.1
	if saltsick and not e.is_boss:
		e.xp_val = int(ceilf(e.xp_val * 1.15))
	if draft_hole and not e.is_boss:
		e.speed *= 1.1
	if crowns_hush and not e.is_boss:
		e.aggro_range *= 0.8
	if vassals_claim and not e.is_boss:
		e.hp *= 0.9
		e.hp_max = e.hp
	if bilge_sworn and not e.is_boss:
		e.speed *= 0.92
	if dead_reckoner and not e.is_boss:
		e.aggro_range *= 1.2
	if fathom_pact and not e.is_boss:
		e.dmg = int(ceilf(float(e.dmg) * 1.12))
	if gallows_tide and not e.is_boss:
		e.hp *= 1.12
		e.hp_max = e.hp
		e.xp_val = int(ceilf(e.xp_val * 1.15))
	if pilot_light and not e.is_boss:
		e.aggro_range *= 0.85
	if widdershins and not e.is_boss:
		e.speed *= 1.1
	if slack_water and not e.is_boss:
		e.speed *= 0.88
	if salvage_breeze and not e.is_boss:
		e.xp_val = int(ceilf(e.xp_val * 1.1))
	if deep_salve and not e.is_boss:
		e.xp_val = int(ceilf(e.xp_val * 0.85))
	if deck_psalm and not e.is_boss:
		e.dmg = int(maxi(1, floorf(float(e.dmg) * 0.88)))
	if royal_overlook and not e.is_boss:
		e.dmg = int(maxi(1, floorf(float(e.dmg) * 0.9)))
	if murk_vision and not e.is_boss:
		e.aggro_range *= 0.85
	if bilge_still and not e.is_boss:
		e.speed *= 0.88
	if keel_groan and not e.is_boss:
		e.hp *= 1.1
		e.hp_max = e.hp
	if saltwind and not e.is_boss:
		e.speed *= 1.1
	if bone_lantern and not e.is_boss:
		e.dmg = int(maxi(1, floorf(float(e.dmg) * 1.1)))
	if dead_reckoning and not e.is_boss:
		e.speed *= 1.08
		e.dmg = int(maxi(1, floorf(float(e.dmg) * 1.08)))
	if gloom_tide and not e.is_boss:
		e.speed *= 0.92
	if murk_lift and not e.is_boss:
		e.speed *= 0.9
	if siren_hum and not e.is_boss:
		e.speed *= 0.88
		e.dmg = int(ceilf(float(e.dmg) * 1.08))
	if grim_calm and not e.is_boss:
		e.dmg = int(ceilf(float(e.dmg) * 1.1))
	if keel_haul and not e.is_boss:
		e.speed *= 1.12
	if weeping_tide and not e.is_boss:
		e.hp *= 0.92
		e.hp_max = e.hp
		e.dmg = int(ceilf(float(e.dmg) * 1.08))
	if deep_draught and not e.is_boss:
		e.hp *= 1.1
		e.hp_max = e.hp
		e.speed *= 0.9
	if thick_tide and not e.is_boss:
		e.speed *= 0.92
		e.xp_val = int(ceilf(float(e.xp_val) * 1.1))
	if slack_line and not e.is_boss:
		e.speed *= 0.9
	if low_lantern and not e.is_boss:
		e.aggro_range = float(e.aggro_range) * 0.85
	if mirage_sea and not e.is_boss:
		e.hp *= 1.12
		e.hp_max = e.hp
		e.xp_val = int(ceilf(float(e.xp_val) * 1.12))
	if bilge_lull and not e.is_boss:
		e.aggro_range = float(e.aggro_range) * 0.8
		e.xp_val = int(ceilf(float(e.xp_val) * 1.05))
	if deep_well and not e.is_boss:
		e.dmg = int(ceilf(float(e.dmg) * 1.15))
	if tide_clock and not e.is_boss:
		e.speed *= 0.9
	if fog_bank and not e.is_boss:
		e.aggro_range *= 0.9
	if salt_lullaby and not e.is_boss:
		e.windup_t = float(e.windup_t) * 1.15
	if lantern_wake and not e.is_boss:
		e.speed *= 1.1
	if keel_spirit and not e.is_boss:
		e.dmg = int(maxi(1, floorf(float(e.dmg) * 0.9)))
		e.xp_val = int(maxi(1, floorf(float(e.xp_val) * 0.92)))
	if watch_bell and not e.is_boss:
		e.windup_t = float(e.windup_t) * 1.15
	if timber_shiver and not e.is_boss:
		e.hp *= 0.9
		e.hp_max = e.hp
	if sworn_hull and not e.is_boss:
		e.speed *= 1.1
	if full_sails and not e.is_boss:
		e.speed *= 1.15
	if long_oars and not e.is_boss:
		e.speed *= 0.8
	if kneel_not:
		e.kb_resist *= 0.5
	if pale_squall and not e.is_boss:
		e.speed *= 1.15
		e.hp *= 0.9
		e.hp_max = e.hp
	if tar_smear and not e.is_boss:
		e.speed *= 0.9
	# bilge_iron: +2 armor via Stats.buff_armor
	if ballast_beads:
		e.aggro_range = float(e.aggro_range) * 0.8
	if line_splice:
		player.kb_in = 0.5
	if halfway_dead:
		e.hp = float(e.get("hp_max")) * 0.9
	if rich_vein:
		e.hp *= 1.1
		e.hp_max *= 1.1
	if wraiths_due:
		e.aggro_range = float(e.aggro_range) * 1.15
	if pilot_dead:
		e.aggro_range = float(e.aggro_range) * 1.2
	if long_watch:
		e.aggro_range = float(e.aggro_range) * 1.4
	if brine_smoke:
		e.aggro_range = float(e.aggro_range) * 0.85
	if crowns_rest and not e.is_boss:
		e.speed *= 0.9
	if gun_smoke and not e.is_boss and bool(e.get("ranged")):
		e.windup_t = float(e.windup_t) * 0.7
	if black_calm and not e.is_boss:
		e.speed *= 0.85
		e.dmg += maxi(1, int(ceilf(e.dmg * 0.15)))
	if kings_tithe:
		e.dmg += maxi(1, int(ceilf(e.dmg * 0.2)))
		e.xp_val = int(e.xp_val * 1.1)
	if mire_hollow and not e.is_boss:
		e.hp *= 1.1
		e.hp_max = e.hp
	if dark_lantern and not e.is_boss:
		e.speed *= 1.1
		e.xp_val = int(e.xp_val * 1.15)
	if halfwreck and e.elite:
		e.xp_val = int(e.xp_val * 1.3)
	if court_summons and not e.is_boss:
		e.xp_val = int(e.xp_val * 1.15)
	if gale_tide:
		e.speed *= 1.1
	if mercy_tide:
		e.speed *= 0.92
	if swell_tide:
		e.hp *= 1.2
		e.hp_max = e.hp
		e.xp_val = int(ceilf(e.xp_val * 1.25))
	if kelp_bed:
		e.hp *= 1.1
		e.hp_max = e.hp
		e.speed *= 0.9
	if barnacle_bloom:
		e.hp *= 1.15
		e.hp_max = e.hp
	if sodden:
		e.speed *= 0.88
	if slow_clock:
		e.speed *= 0.92
	if deck_alms:
		e.speed *= 1.1
	if loose_ballast:
		e.speed *= 0.9
	if black_sails:
		e.speed *= 1.15
	if cradle_deep:
		e.hp *= 0.92
		e.hp_max = e.hp
	if crowns_ransom and e.elite:
		e.speed *= 1.05
	if grim_charter and e.elite:
		e.xp_val = int(ceilf(e.xp_val * 1.5))
	if final_verse:
		e.dmg *= 0.85
	if deep_breath:
		e.speed *= 0.95
	if gangway and not e.is_boss:
		e.xp_val = int(ceilf(e.xp_val * 1.15))
	if Stats.relics.has("brine_whistle"):
		e.slow_t = 2.5
	if Stats.relics.has("gunners_badge") and e.proj_speed > 0.0:
		e.proj_speed *= 0.85
	if long_wake:
		e.aggro_range *= 1.4
	room.add_child(e)
	# spawn-in: muncul pop supaya tidak hard-cut
	var esc: Vector3 = e.scale
	e.scale = Vector3(0.01, 0.01, 0.01)
	var stw := e.create_tween()
	stw.tween_property(e, "scale", esc, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	e.died.connect(_on_enemy_died)
	if not elite and not e.is_boss and not _warned.has(arch_id) and FIRST_SEEN.has(arch_id) and player != null:
		_warned[arch_id] = 1
		if lookout:
			Stats.earn_souls(1)
			_souls_l()
		Sfx.play("page")
		var wtxt := String(FIRST_SEEN[arch_id])
		if Stats.ng_plus > 0:
			wtxt = "Umbral " + wtxt
		_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), wtxt, Color(0.55, 1.0, 0.75), true)
	if elite and not _warned.has("affix_" + String(e.affix)) and {"venomed": "Its bite seeps venom — kill it before it closes.", "tidal": "It sings the tide into its allies' wounds — cut it first.", "riptide": "Its blows carry the undertow — guard your footing.", "brinebound": "Salt-crusted — its death spills the souls it hoarded.", "barnacled": "Barnacle-armored — it shrugs your steel, but drags its feet.", "feral": "It feeds on the falling — thin its pack last, or it quickens.", "miser": "Its claws close on your purse — its death skims your souls.", "tideworn": "Rusted solid — it wades slow, but its hide is thick.", "keelbound": "Anchored fast — your blows cannot push it back.", "corroded": "Corrosion-mouthed — its blows pit your steel. Clean it quick.", "salted": "Salt-swollen — its fall spills souls. Worth the hunt.", "webbed": "Silk-blooded — its blows root fast. Don't trade blows up close.", "grim": "Grim-faced — its blows soften your arm. Break it before it wears you down.", "doomsayer": "Doom-croaking — its blows land like anchors. Pray it misses.", "drowning": "Drowned deep — its blows drag you under. Warm steel ends it fastest.", "parched": "Bone-dry — its blows sip your souls. Kill it before the purse runs dry.", "wrack": "Wrack-fisted — its blows spoil your skill charge. Keep out of reach.", "crushing": "Anchor-fisted — its blows throw you like deck cargo. Stay light.", "oathbound": "Oathbound — its pact mends its pack. Kill the oath first.", "slippery": "Slippery — eel-blooded; every fourth blow slides off. Time your swings.", "mirrorhide": "Mirrorhide — its skin throws your blows back at you. Wound it slowly.", "keelmark": "Keelmark — it carries ship's iron. Its death drops a blade.", "tidebound": "Tidebound — bound to its own current; it cannot be slowed.", "charged": "Charged — the more it bleeds, the faster it comes for you.", "bloated": "Bloated — a walking feast of rot; soak hits, hide the corpses.", "tarred": "Tarred — every blow drags tar across your feet. Keep moving.", "seafaring": "Seafaring — born to the swells; it cannot be slowed.", "feytouched": "Feytouched — it slides through the wreck half-here. Watch the blink.", "knotted": "Knotted — rope-thick muscle; it takes a hundred cuts. Save it for last.", "belltoll": "Belltoll — its death silences the pack. Kill it to still the swarm.", "soulfed": "Soulfed — every corpse near it feeds it. Deny it the fallen.", "gutted": "Gutted — split open and sloshing; its death spills healing. Take it down.", "beacon": "Beacon — a lantern strapped to its skull; it sees you long before you see it.", "spry": "Spry — quick-jointed and twitching; it comes at you faster than a corpse should.", "keenedged": "Keen-edged — its blade arm is all edge and no guard; it hits like a headsman.", "tidewrought": "Tidewrought — wrought thick by pressure; slow, and hard to put down.", "lurker": "Lurker — it waits at the edge of the torchlight, then comes all at once.", "hoarfrost": "Hoarfrost — rime-crusted knuckles; its touch slows your blood.", "reefbound": "Reefbound — barnacle-bonded; every blow it lands feeds the reef.", "flotsam": "Flotsam — it drifted in with the dead's loose souls; its fall pays +1 soul.", "brinetouched": "Brinetouched — salt-soaked fists; its blows numb your legs.", "bilged": "Bilged — sloshing with the ship's own water; its fall spills mending.", "gilded": "Gilded — crusted with coin it stole; its fall pays back +1 soul.", "saltbitten": "Saltbitten — its cuts carry brine that blunts your arm.", "leeched": "Leeched — its blows drink the wound open and sew it closed. Burst it down.", "windlashed": "Windlashed — the gale rides its fists; its blows throw you across the deck. Anchor your stance.", "halfshell": "Halfshell — plated in wreckage; your first blow only cracks the shell.", "soulwrought": "Soulwrought — a wisp rides in its ribcage; its death sets the wisp free.", "leaden": "Leaden — sunk slow and swung heavy; its blows land like falling anchors.", "grasping": "Grasping — its fingers are rigging; every blow hauls you closer. Keep your distance.", "hungry": "Hungry — every wound whets it; each hit makes it faster. End it early.", "numbing": "Numbing — its touch is brine-cold; each hit delays your next swing.", "soulbound": "Soulbound — chained too deep to stagger; stuns pass through it.", "saltkin": "Saltkin — caked thin and brittle; it cracks easy and spills souls.", "powderkeg": "Powderkeg — a fuse in its gut; its death blasts the pack, not you.", "hollow": "Hollow — no weight to it; it comes fast but breaks easy.", "tarbound": "Tarbound — tar-caked fists; its blows clog your stride.", "lagged": "Lagged — barnacled with time; its windup drags long. Read it and slip the blow."}.has(String(e.affix)) and player != null:
		_warned["affix_" + String(e.affix)] = 1
		_damage_number(player.global_position + Vector3(0, 1.1 * info.tile, 0), String({"venomed": "Its bite seeps venom — kill it before it closes.", "tidal": "It sings the tide into its allies' wounds — cut it first.", "riptide": "Its blows carry the undertow — guard your footing.", "brinebound": "Salt-crusted — its death spills the souls it hoarded.", "barnacled": "Barnacle-armored — it shrugs your steel, but drags its feet.", "feral": "It feeds on the falling — thin its pack last, or it quickens.", "miser": "Its claws close on your purse — its death skims your souls.", "tideworn": "Rusted solid — it wades slow, but its hide is thick.", "keelbound": "Anchored fast — your blows cannot push it back.", "corroded": "Corrosion-mouthed — its blows pit your steel. Clean it quick.", "salted": "Salt-swollen — its fall spills souls. Worth the hunt.", "webbed": "Silk-blooded — its blows root fast. Don't trade blows up close.", "grim": "Grim-faced — its blows soften your arm. Break it before it wears you down.", "doomsayer": "Doom-croaking — its blows land like anchors. Pray it misses.", "drowning": "Drowned deep — its blows drag you under. Warm steel ends it fastest.", "parched": "Bone-dry — its blows sip your souls. Kill it before the purse runs dry.", "wrack": "Wrack-fisted — its blows spoil your skill charge. Keep out of reach.", "crushing": "Anchor-fisted — its blows throw you like deck cargo. Stay light.", "oathbound": "Oathbound — its pact mends its pack. Kill the oath first.", "slippery": "Slippery — eel-blooded; every fourth blow slides off. Time your swings.", "mirrorhide": "Mirrorhide — its skin throws your blows back at you. Wound it slowly.", "keelmark": "Keelmark — it carries ship's iron. Its death drops a blade.", "tidebound": "Tidebound — bound to its own current; it cannot be slowed.", "charged": "Charged — the more it bleeds, the faster it comes for you.", "bloated": "Bloated — a walking feast of rot; soak hits, hide the corpses.", "tarred": "Tarred — every blow drags tar across your feet. Keep moving.", "seafaring": "Seafaring — born to the swells; it cannot be slowed.", "feytouched": "Feytouched — it slides through the wreck half-here. Watch the blink.", "knotted": "Knotted — rope-thick muscle; it takes a hundred cuts. Save it for last.", "belltoll": "Belltoll — its death silences the pack. Kill it to still the swarm.", "soulfed": "Soulfed — every corpse near it feeds it. Deny it the fallen.", "gutted": "Gutted — split open and sloshing; its death spills healing. Take it down.", "beacon": "Beacon — a lantern strapped to its skull; it sees you long before you see it.", "spry": "Spry — quick-jointed and twitching; it comes at you faster than a corpse should.", "keenedged": "Keen-edged — its blade arm is all edge and no guard; it hits like a headsman.", "tidewrought": "Tidewrought — wrought thick by pressure; slow, and hard to put down.", "lurker": "Lurker — it waits at the edge of the torchlight, then comes all at once.", "hoarfrost": "Hoarfrost — rime-crusted knuckles; its touch slows your blood.", "reefbound": "Reefbound — barnacle-bonded; every blow it lands feeds the reef.", "flotsam": "Flotsam — it drifted in with the dead's loose souls; its fall pays +1 soul.", "brinetouched": "Brinetouched — salt-soaked fists; its blows numb your legs.", "bilged": "Bilged — sloshing with the ship's own water; its fall spills mending.", "gilded": "Gilded — crusted with coin it stole; its fall pays back +1 soul.", "saltbitten": "Saltbitten — its cuts carry brine that blunts your arm.", "leeched": "Leeched — its blows drink the wound open and sew it closed. Burst it down.", "windlashed": "Windlashed — the gale rides its fists; its blows throw you across the deck. Anchor your stance.", "halfshell": "Halfshell — plated in wreckage; your first blow only cracks the shell.", "soulwrought": "Soulwrought — a wisp rides in its ribcage; its death sets the wisp free.", "leaden": "Leaden — sunk slow and swung heavy; its blows land like falling anchors.", "grasping": "Grasping — its fingers are rigging; every blow hauls you closer. Keep your distance.", "hungry": "Hungry — every wound whets it; each hit makes it faster. End it early.", "numbing": "Numbing — its touch is brine-cold; each hit delays your next swing.", "soulbound": "Soulbound — chained too deep to stagger; stuns pass through it.", "saltkin": "Saltkin — caked thin and brittle; it cracks easy and spills souls.", "powderkeg": "Powderkeg — a fuse in its gut; its death blasts the pack, not you.", "hollow": "Hollow — no weight to it; it comes fast but breaks easy.", "tarbound": "Tarbound — tar-caked fists; its blows clog your stride.", "lagged": "Lagged — barnacled with time; its windup drags long. Read it and slip the blow."}[e.affix]), Color(0.6, 0.95, 0.7), true)
	if e.is_boss:
		boss_ref = e
		var tier := _boss_tier()
		boss_name = String(tier["name"])
		e.tier_idx = 4 if Stats.floor_num >= 25 else (Stats.floor_num / 5 - 1) % 4
		M.paint(e, M.toon(skeleton_tex, tier["tint"], 0.35, true))
		if ui.has("boss_name"):
			ui.boss_name.text = "☠ " + boss_name
		e.summon_requested.connect(_on_boss_summon)
	elif e.is_summoner:
		e.summon_requested.connect(_on_necro_summon)
	return e


func _nemesis_mark(e) -> void:
	if e != null and is_instance_valid(e) and e.get("state") != "dead":
		Sfx.play("roar")
		_damage_number(e.global_position + Vector3(0, 1.0 * info.tile, 0), "NEMESIS — the one that ended you", Color(1.0, 0.2, 0.3), true)
		if knight_ref != null and is_instance_valid(knight_ref):
			_damage_number(knight_ref.global_position + Vector3(0, 0.9 * info.tile, 0), "That's the one, boy — take its skull.", Color(0.7, 0.9, 1.1), false)


# necromancer membangkitkan 1 antek; dibatasi supaya ruangan tidak banjir
func _on_necro_summon(n) -> void:
	if _room_alive(n.room_idx) >= 6:
		return
	Sfx.play("thunder")
	toast("A necromancer raises the dead!")
	_burst(n.global_position + Vector3(0, 0.5, 0), Color(0.8, 0.4, 1.0))
	var arch := "crawler" if rng.randf() < 0.35 else "chaser"
	_spawn_enemy({"pos": n.global_position + Vector3(0, 0, 0.6 * info.tile), "room": n.room_idx}, arch, false)


# boss memanggil 2 antek; dibatasi supaya ruangan tidak banjir
func _on_boss_summon(boss) -> void:
	var alive := _room_alive(boss.room_idx)
	if alive >= 7:
		return
	Sfx.play("roar")
	toast(boss_name + " summons his minions!")
	for k in range(2):
		var off := Vector3((k - 0.5) * 0.8 * info.tile, 0, 0.5 * info.tile)
		_spawn_enemy({"pos": boss.global_position + off, "room": boss.room_idx}, "chaser", false)


# jebakan duri di ruang-ruang tengah (tidak di ruang spawn / ruang boss)
func _dig_trap(pos: Vector3) -> void:
	var tr2 = TRAP.new()
	room.add_child(tr2)
	tr2.global_position = pos
	tr2.setup(info.tile, 0.0, 3)
	toast("The Gravedigger plants a void sigil!")


func _spawn_traps(last_room: int) -> void:
	if dead_calm:
		return
	var count: int = mini(maxi(Stats.floor_num - 1, 0), 3) + (2 if muckraker else 0)
	for i in range(count):
		var ri: int = rng.randi_range(1, last_room)
		var r: Dictionary = info.ranges[ri]
		var pos := Vector3.ZERO
		var ok := false
		for t in range(14):
			pos = Vector3(rng.randf_range(r["x0"] + 0.6 * info.tile, r["x1"] - 0.6 * info.tile), 0.0, rng.randf_range(r["z1"] + 0.9 * info.tile, r["z0"] - 0.9 * info.tile))
			ok = true
			for pr in info.props:
				if pr.global_position.distance_to(pos) < 0.8 * info.tile:
					ok = false
					break
			if ok:
				break
		if not ok:
			continue
		var tr = TRAP.new()
		room.add_child(tr)
		tr.global_position = pos
		var rk := rng.randf()
		var clam := String(biome.get("name", "")) == "Sunken Reliquary"
		var tkind: int = 8 if (Stats.floor_num >= 15 and rk < 0.05) else (7 if (Stats.floor_num >= 13 and rk < 0.14) else (4 if rk < 0.18 else (5 if rk < 0.28 else ((6 if clam else 3) if rk < 0.42 else (2 if rk < 0.56 else (1 if rk < 0.72 else 0))))))
		tr.setup(info.tile, rng.randf_range(0.0, 1.9), tkind)
		if tkind == 7 and not _warned.has("pincher"):
			_warned["pincher"] = true
			toast("Something under the sand is breathing... stay clear of the pinchers.")
		elif tkind == 8 and not _warned.has("siphon"):
			_warned["siphon"] = true
			toast("Soul Siphons drink the purse right off your belt — disarm them while they doze.")


func _spawn_urns(last_room: int) -> void:
	# guci tulang: 1-3 per lantai, dipecahkan untuk permata jiwa
	for i in range(rng.randi_range(2, 4) + (4 if drift_wreck else 0)):
		var ri: int = rng.randi_range(0, last_room)
		var r: Dictionary = info.ranges[ri]
		var pos := Vector3(rng.randf_range(r["x0"] + 0.5 * info.tile, r["x1"] - 0.5 * info.tile), 0.0, rng.randf_range(r["z1"] + 1.0 * info.tile, r["z0"] - 1.0 * info.tile))
		var ok := true
		for pr in info.props:
			if pr.global_position.distance_to(pos) < 0.8 * info.tile:
				ok = false
				break
		if not ok:
			continue
		var u = URN.new()
		room.add_child(u)
		u.global_position = pos
		u.setup(info.tile, i == 0 and String(biome.get("name", "")) == "Sunken Reliquary" and rng.randf() < 0.3, i == 0 and Stats.floor_num >= 13 and rng.randf() < 0.25)


# altar arwah di ruangan terakhir — 45% kesempatan, sekali pakai
func _spawn_shrine(last_room: int) -> void:
	if rng.randf() >= 0.45:
		return
	var r: Dictionary = info.ranges[last_room]
	var pos := Vector3((r["x0"] + r["x1"]) * 0.5, 0.0, r["z0"] - 1.1 * info.tile)
	for pr in info.props:
		if pr.global_position.distance_to(pos) < 1.0 * info.tile:
			return
	var s = SHRINE.new()
	room.add_child(s)
	s.global_position = pos
	# lantai 3+: 30% Mahzan; lantai 2+: 22% obelisk terkutuk; sisanya altar berkat
	var skind := 0
	if Stats.floor_num == 24:
		skind = 1 # Mahzan selalu menjual sebelum takhta terakhir
	elif Stats.floor_num >= 11 and Stats.floor_num <= 12 and rng.randf() < 0.6:
		skind = 11 # Drowned Altar — relikui tenggelam menjual kehendak laut
	elif Stats.floor_num == 12:
		skind = 12 # Keelstone — batu sauh: selalu hadir di lantai 12
	elif Stats.floor_num >= 7 and Stats.floor_num % 7 == 0:
		skind = 5 # lantai quest Bounty Hunter — batu kontrak terjamin
	elif Stats.floor_num >= 10 and Stats.floor_num % 8 == 4:
		skind = 6 # lantai quest Grave Robber — vault terjamin
	elif Stats.floor_num >= 13 and Stats.floor_num <= 19 and Stats.floor_num % 7 == 1:
		skind = 7 # lantai quest Commuter — ferryman terjamin
	elif Stats.floor_num >= 11 and Stats.floor_num % 9 == 5:
		skind = 8 # Gambler's Well terjamin di lantai %9==5
	elif Stats.floor_num >= 13 and Stats.floor_num % 11 == 7:
		skind = 9 # Scavenger's Cache terjamin di lantai %11==7
	elif Stats.floor_num >= 16 and Stats.floor_num % 12 == 8:
		skind = 10 # Soul Fountain terjamin di lantai %12==8
	elif Stats.floor_num >= 13 and Stats.floor_num % 10 == 8:
		skind = 13 # Throne's Offering — the King buys tribute in the deep
	elif Stats.floor_num >= 8 and Stats.floor_num % 6 == 3:
		skind = 15 # Quartermaster's Post — armory terjamin di lantai %6==3
	elif Stats.floor_num >= 7 and rng.randf() < 0.07:
		skind = 15 # Quartermaster's Post acak
	elif Stats.floor_num >= 10 and Stats.floor_num % 8 == 2:
		skind = 16 # Siren's Conch — kerang bernyanyi terjamin di lantai %8==2
	elif Stats.floor_num >= 9 and rng.randf() < 0.06:
		skind = 16 # Siren's Conch acak
	elif Stats.floor_num >= 14 and rng.randf() < 0.10:
		skind = 14 # Moonpool — kolam cahaya bulan di kedalaman
	elif Stats.floor_num >= 5 and Stats.floor_num % 5 == 1:
		skind = 3 # lantai quest Forge-Fed — soul forge terjamin
	elif Stats.floor_num >= 10 and rng.randf() < 0.08:
		skind = 8
	elif Stats.floor_num >= 12 and rng.randf() < 0.07:
		skind = 9
	elif Stats.floor_num >= 14 and rng.randf() < 0.06:
		skind = 10
	elif Stats.floor_num >= 9 and rng.randf() < 0.1:
		skind = 6
	elif Stats.floor_num >= 7 and rng.randf() < 0.1:
		skind = 5
	elif Stats.floor_num >= 6 and rng.randf() < 0.12:
		skind = 4
	elif Stats.floor_num >= 4 and rng.randf() < 0.18:
		skind = 3
	elif Stats.floor_num >= 3 and rng.randf() < 0.3:
		skind = 1
	elif Stats.floor_num >= 2 and rng.randf() < 0.22:
		skind = 2
	s.setup(info.tile, skind)
	shrine_ref = s
	shrine_kind = skind
	if ossuary:
		for oc in range(mini(4, info.ranges.size() - 1)):
			var oi: int = rng.randi_range(1, info.ranges.size() - 1)
			var rr3: Dictionary = info.ranges[oi]
			var opos := Vector3(((rr3["x0"] + rr3["x1"]) * 0.5 + randf_range(-0.7, 0.7)) * info.tile, 0, ((rr3["z0"] + rr3["z1"]) * 0.5 + randf_range(-0.7, 0.7)) * info.tile)
			_spawn_enemy({"pos": opos, "room": oi}, "crawler", false)
	match skind:
		1:
			s.invoked.connect(_on_mahzan_invoked)
		2:
			s.invoked.connect(_on_curse_invoked)
		3:
			s.invoked.connect(_on_forge_invoked)
		4:
			s.invoked.connect(_on_mirror_invoked)
		5:
			s.invoked.connect(_on_bounty_invoked)
		6:
			s.invoked.connect(_on_vault_invoked)
		7:
			s.invoked.connect(_on_ferry_invoked)
		8:
			s.invoked.connect(_on_well_invoked)
		9:
			s.invoked.connect(_on_cache_invoked)
		10:
			s.invoked.connect(_on_fountain_invoked)
		11:
			s.invoked.connect(_on_drowned_invoked)
		12:
			s.invoked.connect(_on_keel_invoked)
		13:
			s.invoked.connect(_on_throne_invoked)
		14:
			s.invoked.connect(_on_moonpool_invoked)
		15:
			s.invoked.connect(_on_qm_invoked)
		16:
			s.invoked.connect(_on_siren_invoked)
		_:
			s.invoked.connect(_on_shrine_invoked)


var lore_ref = null
var motes_ref: GPUParticles3D = null
var stain_count := 0
var stain_positions: Array = []
var pool_positions: Array = []
var pool_healed := 0.0
var pool_touched := false
var pray_t := 0.0
var prayed := false
var umbral_seen := false
var leech_charge := 0
var squire_ref: Node3D = null
var knight_ref: Node3D = null


func _spawn_cage(last_room: int) -> void:
	# penjara spektral: 20% di lantai 4+, di ruangan awal/tengah (bukan bos)
	if Stats.floor_num < 4 or rng.randf() >= 0.2:
		return
	var r: Dictionary = info.ranges[rng.randi_range(0, last_room - 1)]
	var pos := Vector3((r["x0"] + r["x1"]) * 0.5 + rng.randf_range(-0.6, 0.6) * info.tile, 0.0, (r["z0"] + r["z1"]) * 0.5)
	for pr in info.props:
		if pr.global_position.distance_to(pos) < 1.1 * info.tile:
			return
	var s = CAGE.new()
	room.add_child(s)
	s.global_position = pos
	s.setup(info.tile)
	s.freed.connect(_on_cage_freed)


var vane_freed_n := 0
var vane_floors := 0 # lantai yang Sir Vane lalui bersamamu — ia makin kuat


func _spawn_knight() -> void:
	if knight_ref != null and is_instance_valid(knight_ref):
		return
	if player == null or not is_instance_valid(player):
		return
	knight_ref = SQUIRE.new()
	room.add_child(knight_ref)
	knight_ref.global_position = player.global_position + Vector3(-0.4 * info.tile, 0, 0.3 * info.tile)
	vane_floors += 1
	var vane_mult := 0.55 + minf(0.45, 0.04 * vane_floors)
	knight_ref.setup(info.tile, maxf(1.0, Stats.get_stat("atk") * vane_mult), Color(0.62, 0.85, 1.0), Color(0.7, 0.95, 1.0))
	knight_ref.set("is_vane", true)
	if bosun_mark:
		knight_ref.set("dmg", float(knight_ref.get("dmg")) * 1.2)
	if vane_floors == 4 or vane_floors == 8 or vane_floors == 12:
		toast("⚔ Sir Vane remembers his captain's forms (+%d%% ATK)" % int(vane_mult * 100.0))


func _on_cage_freed(s) -> void:
	Sfx.play("gate")
	_spawn_knight()
	knight_ref.global_position = s.global_position
	vane_freed_n += 1
	if vane_freed_n >= 3:
		_say([
			{"who": "knight", "text": "These bars keep FINDING me, warrior. Somewhere a gaoler laughs."},
			{"who": "kael", "text": "Then keep breaking them, Sir Vane. It suits you."},
			{"who": "knight", "text": "Until the King's own cell, friend. My blade remembers the way."},
		])
	elif vane_freed_n == 2:
		_say([
			{"who": "knight", "text": "You AGAIN? Do they build these prisons around me?"},
			{"who": "kael", "text": "Or you keep wandering into them."},
			{"who": "knight", "text": "Bah. Blade, then — one more floor."},
		])
	else:
		var vlines := [
			{"who": "knight", "text": "A thousand years in these bars... and you walk right up?"},
			{"who": "kael", "text": "Can you still swing a blade, old ghost?"},
			{"who": "knight", "text": "Watch me. Until this floor ends — my sword is yours."},
		]
		if Stats.ng_plus > 0:
			vlines = [
				{"who": "knight", "text": "You carry the throne's shadow now, boy — I can smell the crown-bone on you."},
				{"who": "kael", "text": "It broke once, Sir Vane. It'll break again."},
				{"who": "knight", "text": "Then break it a hundred times. A king that won't stay dead needs a knight that won't stay caged."},
			]
		if Stats.nemesis != "":
			vlines.append({"who": "knight", "text": "And I hear %s prowls these halls — the thing that felled you last. Point me at it, boy." % Stats.nemesis_name})
		_say(vlines)
	_ach("knight1")


func _spawn_lore_stone(last_room: int) -> void:
	# batu pengetahuan: 35% acak — dijamin muncul tiap lantai kelipatan-4 ≥12 (quest Dead Letters)
	if rng.randf() >= 0.35 and not (Stats.floor_num >= 12 and Stats.floor_num % 4 == 0):
		return
	var r: Dictionary = info.ranges[rng.randi_range(0, last_room)]
	var pos := Vector3((r["x0"] + r["x1"]) * 0.5 + rng.randf_range(-0.5, 0.5) * info.tile, 0.0, (r["z0"] + r["z1"]) * 0.5)
	for pr in info.props:
		if pr.global_position.distance_to(pos) < 1.2 * info.tile:
			return
	var s = LSTONE.new()
	room.add_child(s)
	s.global_position = pos
	s.setup(info.tile)
	lore_ref = s
	s.invoked.connect(_on_lore_stone)


const MOTE_COLS := {
	"Catacombs": Color(0.7, 0.8, 1.0, 0.45),
	"Ember Crypt": Color(1.0, 0.55, 0.2, 0.65),
	"Frozen Deep": Color(0.85, 0.95, 1.0, 0.55),
	"Verdant Ruin": Color(0.6, 1.0, 0.55, 0.5),
	"The Abyss": Color(0.75, 0.5, 1.0, 0.55),
	"Sunken Reliquary": Color(0.5, 0.95, 0.85, 0.5),
}


func _spawn_motes() -> void:
	# partikel ambient mengambang di sekitar pemain — ember/salju/spora/mote per biome
	var mname := String(biome.get("name", ""))
	var col: Color = MOTE_COLS.get(mname, Color(0.7, 0.8, 1.0, 0.45))
	var up := mname == "Ember Crypt" or mname == "The Abyss"
	var p := GPUParticles3D.new()
	room.add_child(p)
	motes_ref = p
	p.amount = 24 if low_quality else 44
	p.lifetime = 4.5
	p.visibility_aabb = AABB(Vector3(-12, -5, -12), Vector3(24, 10, 24))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(5.0, 1.2, 5.0)
	pm.direction = Vector3(0, 1 if up else -1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.12
	pm.initial_velocity_max = 0.38
	pm.gravity = Vector3(0, 0.22 if up else -0.15, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	pm.color = col
	p.process_material = pm
	var dot := SphereMesh.new()
	dot.radius = 0.03
	dot.height = 0.05
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = col
	dm.emission_enabled = true
	dm.emission = col
	dm.emission_energy_multiplier = 1.6
	dot.material = dm
	p.draw_pass_1 = dot


func _spawn_lanterns(last_room: int) -> void:
	# lentera jiwa: aura penyembuh kecil di satu ruangan (lantai 8+, 40%)
	lanterns = []
	lantern_healed = 0.0
	lantern_touched = false
	if Stats.floor_num < 8 or rng.randf() > 0.4:
		return
	var ri: int = rng.randi_range(1, last_room)
	var r: Dictionary = info.ranges[ri]
	var pos := Vector3((r["x0"] + r["x1"]) * 0.5 * info.tile, 0.0, (r["z0"] + r["z1"]) * 0.5 * info.tile)
	for pr2 in info.props:
		if pr2.global_position.distance_to(pos) < 1.2 * info.tile:
			return
	var ln := Node3D.new()
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04 * info.tile
	cm.bottom_radius = 0.06 * info.tile
	cm.height = 0.9 * info.tile
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.25, 0.22, 0.3)
	pole.mesh = cm
	pole.material = pmat
	pole.position.y = 0.45 * info.tile
	ln.add_child(pole)
	var gl := MeshInstance3D.new()
	var gs := SphereMesh.new()
	gs.radius = 0.14 * info.tile
	gs.height = 0.26 * info.tile
	var gmat := StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.albedo_color = Color(0.5, 0.9, 0.75)
	gmat.emission_enabled = true
	gmat.emission = Color(0.45, 0.95, 0.7)
	gmat.emission_energy_multiplier = 2.2
	gl.mesh = gs
	gl.material = gmat
	gl.position.y = 0.95 * info.tile
	ln.add_child(gl)
	var om := OmniLight3D.new()
	om.light_color = Color(0.45, 0.95, 0.7)
	om.light_energy = 0.7
	om.omni_range = 4.0 * info.tile
	om.position.y = 1.0 * info.tile
	ln.add_child(om)
	room.add_child(ln)
	ln.global_position = pos
	lanterns.append(ln)


func _spawn_squire() -> void:
	if squire_ref != null and is_instance_valid(squire_ref):
		return
	if player == null or not is_instance_valid(player):
		return
	squire_ref = SQUIRE.new()
	room.add_child(squire_ref)
	squire_ref.global_position = player.global_position + Vector3(0.4 * info.tile, 0, 0.3 * info.tile)
	squire_ref.setup(info.tile, maxf(1.0, Stats.get_stat("atk") * 0.35))
	if bosun_mark:
		squire_ref.dmg *= 1.2
	toast("Your squire kneels... then rises to fight")


func _on_lore_stone(s) -> void:
	Sfx.play("page")
	s.consume()
	lore_ref = null
	Stats.add_xp(1)
	_quest_event("page")
	if String(biome.get("name", "")) == "Sunken Reliquary":
		_quest_event("tidepage")
	var line: String = LORE_LINES[rng.randi_range(0, LORE_LINES.size() - 1)]
	lore_run += 1
	if lore_run >= 5:
		_ach("wellread")
	if not Stats.lore_seen.has(line):
		Stats.lore_seen.append(line)
		Stats.save_game()
		if Stats.lore_seen.size() >= LORE_LINES.size():
			_ach("lore32")
		elif Stats.lore_seen.size() >= 60:
			_ach("lore60")
		elif Stats.lore_seen.size() >= 30:
			_ach("lore30")
		elif Stats.lore_seen.size() >= 10:
			_ach("lore10")
	if wellread:
		Stats.earn_souls(1)
		_souls_l()
	_say([{"who": "oracle", "text": line}])


func spawn_weapon_drop(pos: Vector3, wid: String) -> Node3D:
	var pk = WPICK.new()
	room.add_child(pk)
	pk.global_position = pos
	pk.setup(wid, skeleton_tex, info.tile)
	return pk


func _spawn_health_orb(pos: Vector3) -> void:
	var orb = HORB.new()
	room.add_child(orb)
	orb.global_position = pos + Vector3(0, 0.5, 0)
	orb.setup((2.0 if bloodwarm or full_draught else (1.5 if pearl_octave or balmy_sea else 1.0)) * (1.3 if kelp_tithe else 1.0) * (0.7 if pale_dock else 1.0) * (1.4 if deep_salve else 1.0) * (1.5 if deep_well else 1.0), info.tile)


func _spawn_obelisks(last_room: int) -> void:
	# dread obelisk: menara perusak jiwa — 60% satu di lantai 7+, 25% dua
	var oquest := Stats.floor_num >= 7 and Stats.floor_num % 5 == 2
	# NG+2+: kedalaman menaruh obelisk di tiap lantai — takhta mengawasi
	var ng_obel := Stats.ng_plus >= 2 and Stats.floor_num >= 4
	if Stats.floor_num < 7 and not ng_obel:
		return
	if not oquest and not ng_obel and rng.randf() > 0.6:
		return
	var ocount := 2 if rng.randf() < 0.42 else 1
	for _oi in range(ocount):
		var ri: int = rng.randi_range(1, last_room)
		var r: Dictionary = info.ranges[ri]
		var pos := Vector3(rng.randf_range(r["x0"] + 0.6 * info.tile, r["x1"] - 0.6 * info.tile), 0.0, rng.randf_range(r["z1"] + 1.0 * info.tile, r["z0"] - 1.0 * info.tile))
		var ok := true
		for pr in info.props:
			if pr.global_position.distance_to(pos) < 0.9 * info.tile:
				ok = false
				break
		if not ok:
			continue
		var ob := OBEL.new()
		room.add_child(ob)
		ob.global_position = pos
		ob.setup(info.tile)


func _spawn_wisps(last_room: int) -> void:
	# kunang jiwa pengembara: 55% satu, 20% dua — +1 soul kalau disentuh
	var guaranteed := (Stats.floor_num >= 6 and Stats.floor_num % 4 == 0) or soul_drift or blood_moon
	if not guaranteed and rng.randf() > 0.55:
		return
	var wcount := 4 if soul_drift else (3 if blood_moon else (2 if (guaranteed or rng.randf() < 0.36) else 1))
	if String(biome.get("name", "")) == "Sunken Reliquary":
		wcount += 1
	for _wi in range(wcount):
		var ri := rng.randi_range(1, last_room)
		var rr: Dictionary = info.ranges[ri]
		_spawn_wisp_at(Vector3((rr["x0"] + rr["x1"]) * 0.5 + randf_range(-0.8, 0.8) * info.tile, 0.0, (rr["z0"] + rr["z1"]) * 0.5 + randf_range(-0.8, 0.8) * info.tile))


func _spawn_wisp_at(pos: Vector3) -> void:
	var w := WISP.new()
	w.setup(info.tile)
	room.add_child(w)
	w.global_position = pos


func _spawn_tomb(pos: Vector3, p_arch: String, p_room: int) -> void:
	var tb := TOMB.new()
	tb.setup(info.tile, p_arch, p_room)
	room.add_child(tb)
	tb.global_position = pos
	tb.release.connect(_on_tomb_release)


func _on_tomb_release(tb) -> void:
	if not is_instance_valid(tb):
		return
	var e2: Enemy = _spawn_enemy({"pos": tb.global_position, "room": tb.room_i}, tb.arch, false)
	if e2 != null:
		e2.hp = e2.hp_max * 0.6
		e2.activated = true
		_damage_number(tb.global_position + Vector3(0, 0.8 * info.tile, 0), "RISEN!", Color(0.7, 0.4, 1.0), true)
		Sfx.play("roar")


func _spawn_vial(pos: Vector3) -> void:
	var v = VIAL.new()
	room.add_child(v)
	v.global_position = pos + Vector3(0, 0.5, 0)
	v.setup(info.tile)


func _add_vial() -> void:
	_quest_event("vial")
	if vials >= (3 if wide_satchel else 2):
		# satchel penuh — langsung diminum di tempat
		if player != null and is_instance_valid(player):
			var mh := Stats.get_stat("max_hp")
			player.hp = minf(mh, player.hp + mh * 0.2)
			player.hp_changed.emit(player.hp)
		toast("Satchel full — drank it on the spot (+20% HP)")
	else:
		vials += 1
		toast("+1 ⚗ SOUL VIAL (tap VIAL to drink)")
		if vials >= 3:
			_ach("satchel3")
	_vial_btn()


func _use_vial() -> void:
	if run_state != "playing" or player == null or not is_instance_valid(player) or player.dead:
		return
	if vials <= 0:
		Sfx.play("deny")
		toast("No vials left — they drop from the dead")
		return
	var mh := Stats.get_stat("max_hp")
	if player.hp >= mh - 0.01:
		Sfx.play("deny")
		toast("HP already full")
		return
	vials -= 1
	var vfrac := 0.45 if iron_gullet else 0.3
	if Stats.relics.has("brine_ration"):
		vfrac += 0.1
	var healed := minf(mh - player.hp, mh * vfrac)
	player.hp = minf(mh, player.hp + mh * vfrac)
	player.hp_changed.emit(player.hp)
	_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "+%d" % int(ceil(healed)), Color(0.4, 1.0, 0.6), true)
	Sfx.play("shrine")
	_burst(player.global_position + Vector3(0, 0.8, 0), Color(0.3, 0.95, 0.8))
	if Stats.relics.has("purifiers_salt"):
		for deb8 in ["weak_t", "chill_t", "root_t", "venom_t", "silence_t", "rust_t"]:
			player.set(deb8, 0.0)
	toast("⚗ Soul Vial — +30% HP" + (" — curses scoured" if Stats.relics.has("purifiers_salt") else ""))
	_vial_btn()


func _vial_btn() -> void:
	if vials >= 3:
		_ach("full_satchel")
	if vials >= 5:
		_ach("medic")
	if ui.has("vial_btn"):
		ui.vial_btn.text = "⚗ x%d" % vials
		ui.vial_btn.modulate = Color(1, 1, 1, 1) if vials > 0 else Color(1, 1, 1, 0.4)


func _spawn_gems(pos: Vector3, total: int) -> void:
	var n := mini(maxi(total, 1), 4)
	var per := int(total / n)
	for i in range(n):
		var v := per
		if i == n - 1:
			v = total - per * (n - 1)
		if v <= 0:
			continue
		var gem = GEM.new()
		room.add_child(gem)
		gem.global_position = pos + Vector3(0, 0.5, 0)
		gem.setup(v, info.tile)


func _blood_stain(pos: Vector3) -> void:
	# noda darah persisten di lantai — batas 28 per lantai
	if room == null or not is_instance_valid(room) or stain_count >= 28:
		return
	stain_count += 1
	stain_positions.append(pos)
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var sz: float = randf_range(0.35, 0.8) * info.tile
	pm.size = Vector2(sz, sz * randf_range(0.6, 1.0))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.16, 0.03, 0.05, randf_range(0.5, 0.8))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.material = mat
	m.mesh = pm
	m.rotation.y = randf() * TAU
	room.add_child(m)
	m.global_position = pos + Vector3(randf_range(-0.08, 0.08) * info.tile, 0.02 * info.tile, randf_range(-0.08, 0.08) * info.tile)
	m.scale = Vector3(0.4, 1.0, 0.4)
	var bstw: Tween = m.create_tween()
	bstw.tween_property(m, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_tidepools() -> void:
	# kolam pasang di lantai relikui — cakram air dangkal berpendar
	for tp_i in range(mini(4 + int(rng.randf() * 3), info.ranges.size())):
		var tr2: Dictionary = info.ranges[tp_i]
		var tpos := Vector3((tr2["x0"] + tr2["x1"]) * 0.5 * info.tile + randf_range(-0.6, 0.6) * info.tile, 0.015 * info.tile, (tr2["z0"] + tr2["z1"]) * 0.5 * info.tile + randf_range(-0.6, 0.6) * info.tile)
		var tm := MeshInstance3D.new()
		var tpm := PlaneMesh.new()
		var tsz: float = randf_range(0.5, 1.1) * info.tile
		pool_positions.append({"pos": tpos, "r": tsz * 0.5})
		tpm.size = Vector2(tsz, tsz * randf_range(0.6, 0.9))
		var tmat := StandardMaterial3D.new()
		tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tmat.albedo_color = Color(0.25, 0.75, 0.7, 0.22)
		tmat.emission_enabled = true
		tmat.emission = Color(0.15, 0.5, 0.45)
		tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tpm.material = tmat
		tm.mesh = tpm
		tm.rotation.y = randf() * TAU
		room.add_child(tm)
		tm.global_position = tpos


func _souls_l() -> void:
	if Stats.souls >= 50:
		_ach("deepvault")
	if Stats.souls >= 100:
		_ach("accountant")
	if Stats.souls >= 150:
		_ach("fullpurse")
	if Stats.souls >= 200:
		_ach("deepcoffers")
	if Stats.souls_run >= 150:
		_ach("salt_merchant")
	if lucky_net and Stats.souls > _souls_seen:
		_souls_net += Stats.souls - _souls_seen
		while _souls_net >= 10:
			_souls_net -= 10
			Stats.earn_souls(1)
			toast("LUCKY NET — +1 soul")
	_souls_seen = Stats.souls
	if ui.has("souls_label"):
		var t2: String = "◈ %d souls" % Stats.souls if Stats.souls > 0 else ""
		if t2 != ui.souls_label.text and Stats.souls > 0:
			ui.souls_label.pivot_offset = ui.souls_label.size * 0.5
			ui.souls_label.scale = Vector2(1.3, 1.3)
			ui.souls_label.modulate = Color(1.0, 0.9, 0.4)
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(ui.souls_label, "scale", Vector2.ONE, 0.25)
			tw.tween_property(ui.souls_label, "modulate", Color(1, 1, 1), 0.4)
		ui.souls_label.text = t2


func _on_enemy_died(e) -> void:
	print("ENEMY DIED arch=%s elite=%s xp=%d" % [e.arch_id, e.elite, e.xp_val])
	trauma = 0.7
	_blood_stain(e.global_position)
	_burst(e.global_position)
	_souls(e.global_position, 22 if e.is_boss else 7, Color(1.0, 0.5, 0.3) if e.is_boss else Color(0.6, 0.85, 1.0))
	if e.is_boss:
		for wi in range(4):
			var woff: Vector3 = Vector3(cos(wi * PI * 0.5), 0.4, sin(wi * PI * 0.5)) * info.tile * 0.7
			_spawn_wisp_at(e.global_position + woff)
	elif pale_wake and not e.is_boss and rng.randf() < 0.2:
		_spawn_wisp_at(e.global_position + Vector3(0, 0.4, 0))
	Sfx.play("death")
	kills_run += 1
	if kills_run >= 30:
		_quest_event("swab30")
	floor_kills += 1
	if floor_kills == 30:
		_ach("toothdeck")
	Stats.arch_kills[String(e.arch_id)] = int(Stats.arch_kills.get(String(e.arch_id), 0)) + 1
	if kills_run == 1:
		# FIRST BLOOD — kill pertama tiap run langsung menghangatkan kombo
		_combo_set(maxi(combo, 2 + int(Stats.meta.get("veteran", 0)) * 2))
		_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "FIRST BLOOD", Color(1.0, 0.4, 0.3), false)
	if sunken_tide and not e.is_boss:
		Stats.earn_souls(1)
		_souls_l()
		tide_kills += 1
	if bone_lantern and not e.is_boss:
		Stats.earn_souls(1)
		_souls_l()
	if deep_current and not e.is_boss:
		Stats.earn_souls(1)
		_souls_l()
	if netgain_n > 0 and not e.is_boss:
		netgain_n -= 1
		Stats.earn_souls(2)
		_souls_l()
	if _rope_active:
		rope_kills += 1
		if rope_kills >= 15:
			_ach("standingorders")
	if dread_tide and not e.is_boss:
		Stats.earn_souls(1)
		_souls_l()
	if bosun_ledger and floor_kills % 5 == 0:
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.8 * info.tile, 0), "LEDGER +1", Color(0.9, 0.7, 0.3), false)
	if Stats.relics.has("dead_knot") and floor_kills % 8 == 0:
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.8 * info.tile, 0), "KNOT +1", Color(0.9, 0.7, 0.3), false)
		knot_n += 1
		if knot_n >= 8:
			_ach("knotmaster")
	if String(e.arch_id) == "drowned":
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.8 * info.tile, 0), "DRAINED +1", Color(0.4, 0.9, 0.9), false)
		if tide_kills >= 20:
			_ach("drowned20")
	if wolf_omen and wolf_n < 20:
		wolf_n += 1
		Stats.buff_speed_pct += 0.01
		if player != null and is_instance_valid(player):
			player.refresh_stats()
	if Stats.relics.has("leech_seed") and player != null and player.hp >= Stats.get_stat("max_hp") - 0.01:
		leech_charge += 1
		if leech_charge >= 6:
			leech_charge = 0
			Stats.earn_souls(1)
			_souls_l()
			_damage_number(player.global_position + Vector3(0, 0.8, 0), "LEECH SEED RIPENS — +1 soul", Color(0.6, 1.0, 0.6), true)
	if ui.has("kills_label"):
		ui.kills_label.text = "☠ %d  ·  FOES %d" % [kills_run, _room_alive(current_room)]
	# Sir Vane: celoteh perang tiap ~15 kill bersama
	if kills_run >= 100:
		_ach("centurion")
	if kills_run >= 150:
		_ach("slayer150")
	if kills_run >= 250:
		_ach("slayer250")
	if kills_run % 50 == 0:
		_damage_number(player.global_position + Vector3(0, 1.1 * info.tile, 0), "☠ %d KILLS" % kills_run, Color(1.0, 0.8, 0.3), true)
	if kills_run % 15 == 0 and knight_ref != null and is_instance_valid(knight_ref):
		var vbarks := [
			"FOR THE OLD KINGDOM!",
			"A fine mess of bones we're making.",
			"That one had a brother. Send him over.",
			"Ha! Still got it, boy.",
			"The King hears you rattling, wretch!",
		]
		_damage_number(knight_ref.global_position + Vector3(0, 0.9 * info.tile, 0), vbarks[int(kills_run / 15) % vbarks.size()], Color(0.7, 0.9, 1.1), false)
		_quest_event("vane_bark")
	if player != null and is_instance_valid(player) and player.hp <= player.max_hp * 0.2:
		last_stand_kills += 1
		if last_stand_kills >= 5:
			_ach("st5")
	Stats.count_kill()
	Stats.bestiary[e.arch_id] = int(Stats.bestiary.get(e.arch_id, 0)) + 1
	if Stats.bestiary.size() >= BESTIARY.size():
		_ach("scholar")
	if rng.randf() < 0.05 + 0.02 * float(Stats.meta.get("netmend", 0)) + (0.25 if soul_flush else 0.0):
		_spawn_vial(e.global_position)
	if bool(e.get("nemesis")):
		Stats.nemesis = ""
		Stats.nemesis_name = ""
		Stats.earn_souls(10)
		_souls_l()
		Stats.save_game()
		Sfx.play("victory")
		_burst(e.global_position, Color(0.9, 0.15, 0.25))
		_lvl_banner("◆ NEMESIS SLAIN — +10 souls")
		_say([{"who": "oracle", "text": "The ledger crosses a name tonight, Kael. Yours is still being written."}])
		_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "YOUR DEBT IS PAID", Color(1.0, 0.85, 0.35), true)
		_ach("nem1")
		if nemesis_bounty:
			nemesis_bounty = false
			var npool: Array = []
			for rid7 in ITEMS.DB:
				if int(ITEMS.DB[rid7]["rarity"]) >= 2 and not Stats.relics.has(rid7):
					npool.append(rid7)
			if not npool.is_empty():
				var rid8: String = npool[rng.randi_range(0, npool.size() - 1)]
				Stats.add_relic(rid8)
				toast("BLOOD DEBT COLLECTED — epic relic: " + String(ITEMS.DB[rid8]["name"]))
	# weapon mastery: 25 kill dengan senjata yang sama -> +1 ATK permanen
	var wid := Stats.weapon_id
	var wk_old: int = int(Stats.weapon_kills.get(wid, 0))
	Stats.weapon_kills[wid] = wk_old + 1
	_souls_l()
	if wk_old < Stats.MASTERY_N and wk_old + 1 >= Stats.MASTERY_N and not bool(Stats.mastered.get(wid, false)):
		Stats.mastered[wid] = 1
		if Stats.mastered.size() >= 5:
			_ach("smiths_pride")
		Stats.save_game()
		_lvl_banner("◆ WEAPON MASTERY — " + String(WDB.get_w(wid)["name"]) + " mastered")
		Sfx.play("levelup")
		_ach("master1")
		if player != null and is_instance_valid(player):
			player.refresh_stats()
	if Stats.total_kills >= 1:
		_ach("kill1")
	if Stats.total_kills >= 50:
		_ach("k50")
	if Stats.total_kills >= 200:
		_ach("k200")
	_quest_event("kill")
	_quest_event("kill_" + Stats.weapon_id)
	if chorus_cut:
		var ck_ := ""
		var ckmax := -1.0
		for ckk in skill_cd.keys():
			if float(skill_cd[ckk]) > ckmax:
				ckmax = float(skill_cd[ckk])
				ck_ = ckk
		if ck_ != "":
			skill_cd[ck_] = maxf(0.0, float(skill_cd[ck_]) - 0.5)
	if Stats.weapon_id == "storm_petrel":
		skill_cd["dash"] = maxf(0.0, float(skill_cd.get("dash", 0.0)) - 0.4 * float(SkillsDb.get_s("dash").get("cd", 1.0)))
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "PETREL", Color(0.7, 0.85, 1.0), false)
	if not events_run.is_empty():
		_quest_event("eventkill")
	if salvage_tide and rng.randf() < 0.1:
		Stats.earn_souls(1)
		_souls_l()
	if Stats.relics.has("wet_fuse") and Stats.event_soul_bonus > 0:
		Stats.earn_souls(1)
		_souls_l()
	if wid == "moonshell":
		_quest_event("moonkill")
	if wid == "moonshell" and rng.randf() < 0.15:
		var sq = SQUIRE.new()
		room.add_child(sq)
		sq.global_position = e.global_position
		sq.setup(info.tile, Stats.get_stat("atk") * 0.35, Color(0.6, 0.75, 1.1), Color(0.6, 0.8, 1.1))
		sq.life_t = 4.0
		_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "THRALL", Color(0.6, 0.8, 1.1), false)
		_quest_event("thrall")
	if wid == "tidebrand" and bool(e.get("was_low")):
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 1.0 * info.tile, 0), "SALVAGE +1", Color(0.85, 0.75, 0.35), false)
	if wid == "kingfisher":
		skill_cd["dash"] = maxf(0.0, skill_cd["dash"] - 0.5)
	if wid == "conchhorn":
		var near_e = null
		var near_d: float = 2.5 * info.tile
		for fe in get_tree().get_nodes_in_group("enemies"):
			if fe == e or fe.get("state") == "dead" or not bool(fe.get("activated")):
				continue
			var dd: float = fe.global_position.distance_to(e.global_position)
			if dd < near_d:
				near_d = dd
				near_e = fe
		if near_e != null:
			near_e.take_hit(e.global_position, Stats.get_stat("atk") * 0.5)
			_damage_number(near_e.global_position + Vector3(0, 0.7 * info.tile, 0), "ECHO", Color(0.75, 0.55, 1.0), false)
	if e.arch_id == "gaoler":
		_quest_event("gaoler_kill")
	if e.arch_id == "keelhound":
		_quest_event("keelhound_kill")
		keelh_floor += 1
		if keelh_floor >= 3:
			_quest_event("keelh3")
		if Stats.relics.has("keelhook"):
			_souls(e.global_position, 2)
		if int(Stats.arch_kills.get("keelhound", 0)) >= 10:
			_ach("saltdog")
		if int(Stats.arch_kills.get("bomber", 0)) >= 8:
			_ach("powdermonkey")
	if e.arch_id == "maw":
		_quest_event("maw_kill")
	if e.arch_id == "gargoyle":
		_quest_event("garg_kill")
	if e.arch_id == "siren":
		_quest_event("siren_kill")
		if Stats.relics.has("siren_farewell"):
			Stats.earn_souls(2)
			_souls_l()
		if Stats.relics.has("choir_hush"):
			for hf in get_tree().get_nodes_in_group("enemies"):
				if hf == e or hf.get("state") == "dead" or bool(hf.get("is_boss")):
					continue
				if hf.has_method("stun"):
					hf.stun(1.0)
			_damage_number(e.global_position + Vector3(0, 1.1 * info.tile, 0), "HUSH", Color(0.6, 0.5, 1.0), true)
	if e.arch_id == "sentinel":
		_quest_event("sentinel_kill")
	if e.arch_id == "shade":
		_quest_event("shade_kill")
	if e.arch_id == "hexer":
		_quest_event("hexer_kill")
	if e.arch_id == "spiker":
		_quest_event("spiker_kill")
	if e.arch_id == "lurker":
		_quest_event("lurker_kill")
	if e.arch_id == "maiden":
		_quest_event("maiden_kill")
	if e.arch_id == "revenant":
		_quest_event("revenant_kill")
	if e.arch_id == "shieldbearer":
		_quest_event("shield_kill")
	if e.arch_id == "duelist":
		_quest_event("duelist_kill")
	if e.arch_id == "orator":
		_quest_event("orator_kill")
	if e.arch_id == "crowned":
		_quest_event("crowned_kill")
	if e.arch_id == "tither":
		_quest_event("tither_kill")
	if String(e.get("affix")) == "miser":
		var stolen: int = mini(Stats.souls, 2)
		Stats.souls -= stolen
		_souls_l()
		if stolen > 0:
			_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "MISER -%d" % stolen, Color(0.85, 0.7, 0.2), true)
		_quest_event("miser_loss", stolen)
	if rich_vein:
		Stats.earn_souls(1)
		_souls_l()
	if dirge_note:
		for dn_ in get_tree().get_nodes_in_group("enemies"):
			if dn_ == e or dn_.get("state") == "dead":
				continue
			if dn_.global_position.distance_to(e.global_position) < 2.5 * info.tile:
				dn_.set("slow_t", maxf(float(dn_.get("slow_t")), 1.0))
	if melody_ledger:
		ledger_n += 1
		if ledger_n >= 5:
			ledger_n = 0
			Stats.earn_souls(2)
			_damage_number(e.global_position + Vector3(0, 1.6 * info.tile, 0), "NOTE +2", Color(0.7, 0.9, 0.5), false)
	if Stats.relics.has("crow_claw") and combo >= 5:
		Stats.earn_souls(1)
		_damage_number(e.global_position + Vector3(0, 1.4 * info.tile, 0), "CLAW +1", Color(0.5, 0.8, 0.6), false)
	if e.affix == "keelmark":
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
	elif crowns_decree and e.elite and rng.randf() < 0.5:
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
	for f2 in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(f2) and f2 != e and bool(f2.get("elite")) and String(f2.get("affix")) == "feral" and String(f2.get("state")) != "dead":
			f2.speed *= 1.1
			f2.dmg += 1 if f2.dmg < 3 else 0
			_damage_number(f2.global_position + Vector3(0, 0.9 * info.tile, 0), "FRENZIES", Color(1.0, 0.45, 0.3), true)
	if e.arch_id == "waver":
		_quest_event("waver_kill")
	if e.arch_id == "saltghast":
		_quest_event("saltghast_kill")
		if int(Stats.arch_kills.get("saltghast", 0)) >= 10:
			_ach("saltsown")
	if e.arch_id == "bilge_witch":
		_quest_event("witch_kill")
		if int(Stats.arch_kills.get("bilge_witch", 0)) >= 12:
			_ach("thawed")
	if e.arch_id == "keelbeak":
		_quest_event("keelbeak_kill")
		if int(Stats.arch_kills.get("keelbeak", 0)) >= 12:
			_ach("birdkeeper")
	if e.arch_id == "salt_herald":
		_quest_event("herald_kill")
	if e.arch_id == "hull_widow":
		_quest_event("widow_kill")
		if float(Stats.arch_kills.get("hull_widow", 0)) >= 10:
			_ach("websurgeon")
	if e.arch_id == "deck_gunner":
		_quest_event("gunner_kill")
	if e.arch_id == "lantern_jack":
		_quest_event("jack_kill")
	if e.arch_id == "reef_caller":
		_quest_event("caller_kill")
	if e.arch_id == "rotting_bride":
		_quest_event("bride_kill")
	if e.arch_id == "salt_cantor":
		_quest_event("cantor_kill")
	if e.arch_id == "kelter_husk":
		_quest_event("husk_kill")
	if bool(e.get("brood")):
		for bi_ in range(2):
			var mpos: Vector3 = e.global_position + Vector3((rng.randf() - 0.5) * info.tile, 0, (rng.randf() - 0.5) * info.tile)
			_spawn_enemy({"pos": mpos, "room": int(e.get("room_idx"))}, "moth", false)
		_damage_number(e.global_position + Vector3(0, 0.8 * info.tile, 0), "BROOD SPILLS!", Color(0.5, 0.9, 0.5), true)
	if e.arch_id == "deck_brood":
		_quest_event("brood_kill")
	if e.arch_id == "rust_fanatic":
		_quest_event("fanatic_kill")
	if e.arch_id == "chimehead":
		_quest_event("chime_kill")
	if e.arch_id == "bilge_sprite":
		_quest_event("sprite_kill")
	if e.arch_id == "salt_leech":
		_quest_event("leech_kill")
	if e.arch_id == "gutter_chaplain":
		_quest_event("chaplain_kill")
	if e.arch_id == "bell_warden":
		_quest_event("bellwarden_kill")
	if e.arch_id == "hookfin":
		_quest_event("hookfin_kill")
	if e.arch_id == "wrack_eel":
		_quest_event("eel_kill")
	if e.arch_id == "rust_saw":
		_quest_event("saw_kill")
	if e.arch_id == "bell_ringer":
		_quest_event("ringer_kill")
		if int(Stats.arch_kills.get("bell_ringer", 0)) >= 10:
			_ach("ringer10")
	if Stats.weapon_id == "brineaxe" and player != null:
		var mx2 := float(Stats.get_stat("max_hp"))
		player.hp = minf(mx2, player.hp + mx2 * 0.02)
		player.hp_changed.emit(player.hp)
		Stats.current_hp = player.hp
	for sf_ in get_tree().get_nodes_in_group("enemies"):
		if sf_ != e and sf_.get("affix") == "soulfed" and sf_.get("state") != "dead" and sf_.global_position.distance_to(e.global_position) < 4.0 * info.tile:
			sf_.hp = minf(float(sf_.hp_max), float(sf_.hp) + float(sf_.hp_max) * 0.1)
	if player != null and is_instance_valid(player) and float(player.get("slip_t")) > 0.0:
		_quest_event("swift_kill")
	if e.arch_id == "salt_eel":
		_quest_event("salteel_kill")
	if e.arch_id == "deck_brute":
		_quest_event("brute_kill")
	if e.arch_id == "bilge_fury":
		_quest_event("fury_kill")
	if e.arch_id == "siren_thrall":
		_quest_event("thrall_kill")
	if e.arch_id == "pale_lantern":
		_quest_event("lantern_kill")
	if e.arch_id == "gunnel_fiend":
		_quest_event("gunnel_kill")
	if e.arch_id == "bilge_cantor":
		_quest_event("bice_kill")
	if e.arch_id == "tide_bailiff":
		_quest_event("bailiff_kill")
	if e.arch_id == "salt_skimmer":
		_quest_event("skimmer_kill")
	if e.arch_id == "brine_monk":
		_quest_event("monk_kill")
	if e.arch_id == "deck_rigger":
		_quest_event("rigger_kill")
	if e.arch_id == "salt_lich":
		_quest_event("lich_kill")
	if e.arch_id == "quarter_ghost":
		_quest_event("ghost_kill")
	if e.arch_id == "fathom_crab":
		_quest_event("crab_kill")
	if e.arch_id == "powder_monkey":
		_quest_event("monkey_kill")
	if e.arch_id == "bilge_rat":
		_quest_event("rat_kill")
		if rng.randf() < 0.15:
			Stats.earn_souls(1)
			_souls_l()
	if e.arch_id == "gunnel_wight":
		_quest_event("wight_kill")
	if e.arch_id == "foam_herald":
		_quest_event("herald_kill")
	if e.arch_id == "salt_sprite":
		_quest_event("sprite_kill")
	if e.arch_id == "bilge_smith":
		_quest_event("smith_kill")
	if e.arch_id == "keel_wretch":
		_quest_event("wretch_kill")
	if e.arch_id == "moorling":
		_quest_event("moor_kill")
	if e.arch_id == "keel_mastiff":
		_quest_event("mastiff_kill")
	if e.arch_id == "foam_wright":
		_quest_event("wright_kill")
	if e.arch_id == "deck_wight":
		_quest_event("wight_kill")
	if e.arch_id == "salt_skiff":
		_quest_event("skiff_kill")
	if e.arch_id == "lantern_jaw":
		_quest_event("lamp_kill")
	if e.arch_id == "keel_ghost":
		_quest_event("keel_kill")
	if e.arch_id == "salt_gibbet":
		_quest_event("gibbet_kill")
	if e.arch_id == "foamcutter":
		_quest_event("foam_kill")
	if e.arch_id == "gallows_rev":
		_quest_event("revenant_kill")
	if e.arch_id == "kelter_fiend":
		_quest_event("fiend_kill")
	if e.arch_id == "salvage_rat":
		Stats.earn_souls(4)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.8 * info.tile, 0), "SALVAGED +4", Color(1.0, 0.85, 0.4), true)
		_quest_event("rat_catch")
	if e.arch_id == "chum_gnawer":
		_quest_event("gnawer_kill")
	if e.arch_id == "salt_herald":
		var sri := int(e.get("room_idx"))
		for sp_off in [Vector3(0.4, 0, 0), Vector3(-0.4, 0, 0)]:
			var mpos: Vector3 = e.global_position + sp_off * info.tile * 0.5
			_spawn_enemy({"pos": mpos, "room": sri}, "mireling", false)
		toast("The Herald splits — the salt keeps its spawn")
	if e.arch_id == "rust_jaw":
		_quest_event("rustjaw_kill")
		if int(Stats.arch_kills.get("rust_jaw", 0)) >= 12:
			_ach("rustproof")
	if e.arch_id == "mireling":
		_quest_event("mireling_kill")
		if int(Stats.arch_kills.get("mireling", 0)) >= 15:
			_ach("ratlord")
	if e.arch_id == "hound" and wolfsbane:
		_quest_event("pack_hound")
	if bool(e.get("elite")) and String(e.get("affix")) == "umbral":
		_quest_event("umbral_kill")
	if String(e.affix) == "shattered":
		for sc in range(2):
			var off4 := Vector3((sc - 0.5) * 0.7 * info.tile, 0, 0.3 * info.tile)
			var se := _spawn_enemy({"pos": e.global_position + off4, "room": int(e.room_idx)}, "crawler", false)
			if se != null:
				se.activated = true
		_damage_number(e.global_position + Vector3(0, 1.0 * info.tile, 0), "SHATTERED!", Color(0.6, 0.9, 0.6), true)
		_spawn_tomb(e.global_position, "revenant", int(e.room_idx))
	if bool(e.get("pack_bounty")) or (bounty_ref != null and e == bounty_ref):
		if e == bounty_ref:
			bounty_ref = null
		var was_epic := bounty_epic
		bounty_epic = false
		var bpool: Array = []
		for rid5 in ITEMS.DB:
			if int(ITEMS.DB[rid5]["rarity"]) >= (2 if was_epic else 1) and not Stats.relics.has(rid5):
				bpool.append(rid5)
		if not bpool.is_empty():
			var rid6: String = bpool[rng.randi_range(0, bpool.size() - 1)]
			Stats.add_relic(rid6)
			toast("Bounty collected — " + String(ITEMS.DB[rid6]["name"]))
			_ach("bounty1")
		_quest_event("bounty")
	if Stats.spiteful:
		var nbe: Node3D = null
		var nbd: float = 4.0 * info.tile
		for f9 in get_tree().get_nodes_in_group("enemies"):
			if f9 != e and int(f9.room_idx) == int(e.room_idx) and String(f9.get("state")) != "dead":
				var dd9: float = f9.global_position.distance_to(e.global_position)
				if dd9 < nbd:
					nbd = dd9
					nbe = f9
		if nbe != null:
			nbe.take_hit(e.global_position, 1.0)
			_damage_number(nbe.global_position + Vector3(0, 0.9 * info.tile, 0), "SPITE", Color(0.85, 0.3, 0.9), false)
	_combo_set(combo + 1)
	# RAMPAGE: 3+ kill beruntun dalam 2.5 detik -> sorakan + banner
	var now_s := Time.get_ticks_msec() / 1000.0
	rampage_n = rampage_n + 1 if now_s - rampage_t <= 2.5 else 1
	rampage_t = now_s
	if rampage_n >= 3 and rampage_n % 3 == 0:
		_lvl_banner("RAMPAGE ×%d!" % rampage_n)
		Sfx.play("roar")
		_quest_event("rampage")
	# MOTHER affix: elite ini pecah jadi 2 crawler saat mati
	if e.get("affix") == "mother":
		for _mi in range(2):
			_spawn_enemy({"pos": e.global_position + Vector3(randf_range(-0.4, 0.4) * info.tile, 0, randf_range(-0.4, 0.4) * info.tile), "room": e.room_idx}, "crawler", false)
		_damage_number(e.global_position, "SPLITS!", Color(0.7, 1.0, 0.5), true)
	# HOARDED affix: elite menelan senjata — dijatuhkan saat mati
	if e.get("affix") == "hoarded":
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "HOARDED!", Color(1.0, 0.85, 0.35), true)
	if e.get("affix") == "tideworn":
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "TIDE TITHE +1", Color(0.5, 0.8, 0.7), false)
	if bloodtide_t > 0:
		Stats.earn_souls(1)
	if splice_kills > 0:
		splice_kills -= 1
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.6 * info.tile, 0), "SPLICE +1", Color(0.9, 0.8, 0.4), false)
	if martyrs_oath and player != null and is_instance_valid(player) and not player.dead:
		player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.01)
		player.hp_changed.emit(player.hp)
		_souls_l()
	if powder_keg > 0 and not e.is_boss:
		powder_keg -= 1
		for pk in get_tree().get_nodes_in_group("enemies"):
			if pk == e or pk.get("state") == "dead":
				continue
			var pd: Vector3 = pk.global_position - e.global_position
			if pd.length() < 1.6 * info.tile and pk.has_method("take_hit"):
				pk.take_hit(player.global_position, Stats.get_stat("atk") * 0.8)
		_burst(e.global_position + Vector3(0, 0.5 * info.tile, 0), Color(1.0, 0.6, 0.2))
		trauma = 0.4
	if eel_tide and rng.randf() < 0.07 and not e.is_boss:
		_spawn_vial(e.global_position)
	if barnacle_bloom and rng.randf() < 0.08 and not e.is_boss:
		Stats.earn_souls(1)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "+1 soul", Color(0.7, 0.75, 0.4), false)
	if Stats.relics.has("lucky_lantern") and rng.randf() < 0.04:
		_spawn_wisp_at(e.global_position)
	if e.get("affix") == "salted":
		Stats.earn_souls(2)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "SALT TITHE +2", Color(0.6, 0.9, 0.75), false)
	if e.get("affix") == "brinebound":
		Stats.earn_souls(2)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "BRINE PAY +2", Color(0.45, 0.8, 0.9), true)
	if e.get("affix") == "regal":
		_spawn_gems(e.global_position, int(e.xp_val * 1.5))
		_damage_number(e.global_position + Vector3(0, 0.7 * info.tile, 0), "REGAL SPOILS!", Color(1.0, 0.9, 0.3), true)
	if grave_hunger and not e.get("is_boss") and rng.randf() < 0.12:
		_spawn_wisp_at(e.global_position + Vector3(0, 0.3, 0))
	if bool(e.get("wisp_drop")):
		_spawn_wisp_at(e.global_position + Vector3(0, 0.5, 0))
		_damage_number(e.global_position + Vector3(0, 0.6 * info.tile, 0), "WISP FREED!", Color(0.6, 0.7, 1.0), true)
	# WAILING MAIDEN: tangis kematian membangunkan semua musuh di ruangan yang sama
	if bool(e.get("wailer")):
		var woken := 0
		for f in get_tree().get_nodes_in_group("enemies"):
			if f == e or f.get("state") == "dead" or bool(f.get("activated")):
				continue
			if int(f.get("room_idx")) == int(e.room_idx):
				f.activated = true
				woken += 1
		if woken > 0:
			Sfx.play("roar")
			_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "WAILING! ×%d" % woken, Color(0.9, 0.9, 1.1), true)
	# NIGHTMARE affix: elite bangkit sekali pada 40% HP setelah 1.6 detik
	if e.get("affix") == "nightmare":
		var npos: Vector3 = e.global_position
		var nroom: int = e.room_idx
		var narch: String = e.arch_id
		get_tree().create_timer(1.6).timeout.connect(func():
			var e2: Enemy = _spawn_enemy({"pos": npos, "room": nroom}, narch, false)
			if e2 != null:
				e2.hp = e2.hp_max * 0.4
				e2.activated = true
				_damage_number(npos + Vector3(0, 0.8 * info.tile, 0), "IT RISES!", Color(0.55, 0.35, 0.9), true)
				Sfx.play("roar"))
	# ONSLAUGHT: kombo ≥30 -> slow-mo pulsa + penanda besar tiap 10 kombo
	if combo >= 30 and combo % 10 == 0:
		_lvl_banner("☄ ONSLAUGHT ×%d!" % combo)
		Sfx.play("roar")
		if player != null and is_instance_valid(player):
			_burst(player.global_position, Color(1.0, 0.5, 0.2))
	# COMBO RIPPLE: kombo ≥20 -> tiap kill melepas gelombang 1 dmg ke tetangga
	if combo >= 20:
		var rip := 0
		for f in get_tree().get_nodes_in_group("enemies"):
			if f != e and f.get("state") != "dead" and f.global_position.distance_to(e.global_position) < 1.4 * info.tile:
				f.take_hit(e.global_position, 1.0)
				rip += 1
		if rip > 0:
			_shock_ring(e.global_position)
	if e.is_boss:
		_on_boss_died(e)
	if e.elite and (bool(e.get("champion")) or rng.randf() < 0.6):
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
	if bool(e.get("champion")):
		Stats.earn_souls(2)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 1.0 * info.tile, 0), "CHAMPION FELLED — +2 souls", Color(0.95, 0.8, 0.3), true)
	if e.arch_id == "tither":
		Stats.earn_souls(3)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "◈ ITS HOARD — +3 souls", Color(0.5, 0.95, 0.6), false)
	if e.arch_id == "crowned" and rng.randf() < 0.25:
		# CROWN JEWEL: paladin gugur menjaga relik di dalam armor mereka
		var rpool: Array = []
		for rid9 in ITEMS.DB:
			if not Stats.relics.has(rid9):
				rpool.append(rid9)
		if not rpool.is_empty():
			var rc: String = String(rpool[rng.randi() % rpool.size()])
			Stats.add_relic(rc)
			_lvl_banner("♛ CROWN JEWEL — " + String(ITEMS.DB[rc]["name"]))
			Sfx.play("shrine")
	elif e.arch_id == "brute" and rng.randf() < 0.25:
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
	elif e.arch_id == "gaoler" and Stats.weapon_id != "gaoler_brand" and rng.randf() < 0.35:
		spawn_weapon_drop(e.global_position, "gaoler_brand")
	# drop kesehatan: sumber sustain utama mid-run
	if e.is_boss:
		for _i in range(2):
			_spawn_health_orb(e.global_position + Vector3(randf_range(-0.5, 0.5) * info.tile, 0, randf_range(-0.5, 0.5) * info.tile))
	elif e.elite and rng.randf() < 0.25:
		_spawn_health_orb(e.global_position)
	elif rng.randf() < 0.06 * (1.5 if bilge_strike else 1.0):
		_spawn_health_orb(e.global_position)
	if String(e.affix) == "gutted":
		_spawn_health_orb(e.global_position)
	var tw := create_tween()
	tw.tween_property(e, "scale", Vector3(0.01, 0.01, 0.01), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(e.queue_free)
	await get_tree().process_frame
	await get_tree().process_frame
	while Stats.draft_open:
		await get_tree().process_frame
	if run_state == "playing":
		if _room_alive(e.room_idx) == 0:
			rooms_cleared += 1
			if Stats.relics.has("dead_reckoner"):
				Stats.earn_souls(1)
				_souls_l()
			if pale_scrip:
				Stats.earn_souls(1)
				_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "SCRIP +1", Color(0.8, 0.85, 0.6), false)
			_quest_event("room_clear")
			_quest_event("clear_floor")
			_set_room_gates(e.room_idx, true)
			if not get_tree().get_nodes_in_group("enemies").is_empty():
				toast("Room clear — gates open!")
		if get_tree().get_nodes_in_group("enemies").is_empty():
			if Stats.floor_num >= 25:
				_run_victory()
				return
			run_state = "cleared"
			if Stats.relics.has("deadmans_toll"):
				Stats.earn_souls(1)
				_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "TOLL +1", Color(0.8, 0.7, 0.3), true)
			if blood_moon:
				Stats.earn_souls(5)
				_souls_l()
				Stats.save_game()
				toast("☽ BLOOD MOON TITHE — +5 souls")
			elif soul_rush:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("✦ SOUL RUSH TITHE — +3 souls")
			elif fading_light:
				Stats.earn_souls(4)
				_souls_l()
				Stats.save_game()
				toast("◈ GLOOM TITHE — +4 souls")
			elif echoing:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("◈ ECHO TITHE — +3 souls")
			elif gilded_tides:
				Stats.earn_souls(4)
				_souls_l()
				Stats.save_game()
				toast("★ HOARD TITHE — +4 souls")
			elif storm_cellar:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("⚡ STORM TITHE — +2 souls")
			elif soul_drift:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("☆ DRIFT TITHE — +3 souls")
			elif grave_hunger:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ HUNGER TITHE — +2 souls")
			elif giant_hall:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("▲ GIANT TITHE — +3 souls")
			elif shrouded:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("◈ SHROUD TITHE — +2 souls")
			elif ossuary:
				Stats.earn_souls(3)
				_souls_l()
			elif mirror_hall:
				Stats.earn_souls(3)
				_souls_l()
			elif ashfall:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ OSSUARY TITHE — +3 souls")
			elif hungry_walls:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ OSSUARY TITHE — +3 souls")
			elif candlelit:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ OSSUARY TITHE — +3 souls")
			elif verdant:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ OSSUARY TITHE — +3 souls")
			elif bone_chorus:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ OSSUARY TITHE — +3 souls")
			elif wolfsbane:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("☠ OSSUARY TITHE — +3 souls")
			elif thin_veil:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("◈ THIN VEIL TITHE — +2 souls")
			elif low_water:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≈ LOW WATER TITHE — +2 souls")
			elif drift_tide:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("≋ DRIFT TIDE TITHE — +3 souls")
			elif soul_swarm:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("◈ SOUL SWARM TITHE — +2 souls")
			elif gauntlet:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("⚔ GAUNTLET TITHE — +2 souls")
			elif brisk:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≈ BRISK TIDE TITHE — +2 souls")
			elif shoal_tide:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≋ SHOAL TIDE TITHE — +2 souls")
			elif salvage_tide:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("◈ SALVAGE TIDE TITHE — +2 souls")
			elif gale_tide:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≈ GALE TIDE TITHE — +2 souls")
			elif mercy_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ MERCY TIDE TITHE — +1 soul")
			elif eel_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ EEL TIDE TITHE — +1 soul")
			elif swell_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ SWELL TIDE TITHE — +1 soul")
			elif kelp_bed:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ KELP BED TITHE — +1 soul")
			elif barnacle_bloom:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ BARNACLE BLOOM TITHE — +1 soul")
			elif sodden:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ SODDEN HALLS TITHE — +1 soul")
			elif bile_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ BILE TIDE TITHE — +1 soul")
			elif mire_hollow:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ MIRE HOLLOW TITHE — +1 soul")
			elif dark_lantern:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ DARK LANTERN TITHE — +1 soul")
			elif halfwreck:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ HALFWRECK TITHE — +1 soul")
			elif merchant_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ MERCHANT TITHE — +1 soul")
			elif hungry_urns:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ URN TITHE — +1 soul")
			elif bilge_run:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ BILGE TITHE — +1 soul")
			elif pale_squall:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ SQUALL TITHE — +1 soul")
			elif soul_flush:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ FLUSH TITHE — +1 soul")
			elif kings_tithe:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("≋ CROWN TITHE — +3 souls")
			elif black_calm:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≋ CALM TITHE — +2 souls")
			elif gun_smoke:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≋ POWDER TITHE — +2 souls")
			elif greedy_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ TIDE TITHE — +1 soul")
			elif drift_wreck:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ WRECK TITHE — +1 soul")
			elif long_watch:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≋ WATCH TITHE — +2 souls")
			elif salted_deck:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ SALT TITHE — +1 soul")
			elif crows_tide:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ CROW TITHE — +1 soul")
			elif long_night:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≋ NIGHT TITHE — +2 souls")
			elif halfway_dead:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ CULL TITHE — +1 soul")
			elif rich_vein:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
			elif wraiths_due:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif pale_lantern_ev:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif saltgrave_ev:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif leeward_ev:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif brine_smoke:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif crowns_ransom:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif bilge_strike:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif full_draught:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif salt_front:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif cold_snap:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif full_moon:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif gunners_luck:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
			elif shallow_graves:
				Stats.earn_souls(1)
			elif wailing_wind:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("≋ WIND TITHE — +1 soul")
			elif balmy_sea:
				Stats.earn_souls(2)
			elif rust_storm:
				Stats.earn_souls(2)
			elif ember_wake:
				Stats.earn_souls(2)
			elif saltsick:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("≋ SALT TITHE — +2 souls")
			elif gallows_tide:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("≋ GALLOWS TITHE — +3 souls")
			elif pilot_light:
				Stats.earn_souls(2)
				_souls_l()
			elif pilot_light:
				Stats.earn_souls(2)
				_souls_l()
			elif widdershins:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ TURNED TITHE — +2 souls")
			elif slack_water:
				Stats.earn_souls(1)
				_souls_l()
				toast("≋ SLACK TITHE — +1 soul")
			elif salvage_breeze:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ BREEZE TITHE — +2 souls")
			elif deep_salve:
				Stats.earn_souls(1)
				_souls_l()
				toast("≋ SALVE TITHE — +1 soul")
			elif keel_spirit:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ SPIRIT TITHE — +2 souls")
			elif lantern_wake:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ WAKE TITHE — +2 souls")
			elif fog_bank:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ FOG TITHE — +2 souls")
			elif tide_clock:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ CLOCK TITHE — +2 souls")
			elif deep_well:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ WELL TITHE — +3 souls")
			elif bilge_still:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ STILL TITHE — +2 souls")
			elif keel_groan:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ GROAN TITHE — +2 souls")
			elif saltwind:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ WIND TITHE — +3 souls")
			elif bone_lantern:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ LANTERN TITHE — +3 souls")
			elif dead_reckoning:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ RECKONING TITHE — +3 souls")
			elif gloom_tide:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ GLOOM TITHE — +2 souls")
			elif pale_wake:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ WAKE TITHE — +3 souls")
			elif murk_lift:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ MURK TITHE — +2 souls")
			elif siren_hum:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ HUM TITHE — +3 souls")
			elif grim_calm:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ CALM TITHE —� +2 souls")
			elif keel_haul:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ HAUL TITHE — +3 souls")
			elif weeping_tide:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ TEAR TITHE — +2 souls")
			elif deep_draught:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ DRAUGHT TITHE — +3 souls")
			elif thick_tide:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ THICK TITHE — +2 souls")
			elif slack_line:
				Stats.earn_souls(3)
				_souls_l()
				toast("≋ SLACK TITHE — +3 souls")
			elif low_lantern:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ LANTERN TITHE — +2 souls")
			elif mirage_sea:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ MIRAGE TITHE — +2 souls")
			elif bilge_lull:
				Stats.earn_souls(2)
				_souls_l()
				toast("≋ LULL TITHE — +2 souls")
				Stats.save_game()
				toast("≋ PILOT TITHE — +2 souls")
				_souls_l()
				Stats.save_game()
				toast("≋ EMBER TITHE — +2 souls")
				_souls_l()
				Stats.save_game()
				toast("≋ RUST TITHE — +2 souls")
				_souls_l()
				Stats.save_game()
				toast("≋ KIND TITHE — +2 souls")
			elif low_tide:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("≈ EBB TITHE — +3 souls")
			elif sunken_tide:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				toast("≈ DROWNED TITHE — +3 souls")
			elif String(biome.get("name", "")) == "Sunken Reliquary":
				Stats.earn_souls(3 + 2 * int(Stats.meta.get("diver", 0)))
				_souls_l()
				Stats.save_game()
				toast("♛ COURT TITHE — +%d souls" % (3 + 2 * int(Stats.meta.get("diver", 0))))
			if dark_water:
				Stats.earn_souls(1)
				_souls_l()
				Stats.save_game()
				toast("☽ DARK WATER TITHE — +1 soul")
			# bonus sapuan kilat: lantai bersih di bawah 90 detik
			if floor_t < 90.0 and Stats.floor_num > 1:
				Stats.earn_souls(2)
				_souls_l()
				Stats.save_game()
				toast("⚡ SWEEP BONUS — cleared in %ds (+2 souls)" % int(floor_t))
			if not floor_hurt and Stats.floor_num > 1:
				Stats.earn_souls(3)
				_souls_l()
				Stats.save_game()
				flawless_run += 1
				if flawless_run >= 3:
					_ach("untouch")
				toast("★ UNTOUCHED — flawless floor (+3 souls)")
			if not skill_used_floor and Stats.floor_num >= 3 and Stats.floor_num % 5 != 0:
				_ach("pacifist")
			if Stats.floor_num == 12:
				_ach("tidebearer")
			if knight_ref != null and is_instance_valid(knight_ref) and player != null and is_instance_valid(player):
				var vheal: float = Stats.get_stat("max_hp") * 0.08
				if player.hp < Stats.get_stat("max_hp"):
					player.hp = minf(player.hp + vheal, Stats.get_stat("max_hp"))
					player.hp_changed.emit(player.hp)
					toast("♛ Sir Vane's salute — +8% HP")
			if gravetide:
				Stats.earn_souls(2)
			if mudlark:
				Stats.earn_souls(1)
			if crows_share:
				Stats.earn_souls(1)
			if salt_ledger:
				Stats.earn_souls(3)
				_souls_l()
			if Stats.souls >= 40:
				_quest_event("fatpurse")
			if Stats.souls >= 60:
				_quest_event("soulrich")
			if not shrine_used:
				_quest_event("fasting")
				_souls_l()
			if Stats.floor_num >= 13 and not QDB.is_boss_floor(Stats.floor_num):
				abyss_n += 1
				if abyss_n >= 3:
					_ach("abyss3")
			var rk: int = int(Stats.meta.get("reckon", 0))
			if rk > 0:
				Stats.earn_souls(rk)
				_souls_l()
			var kc: int = int(Stats.meta.get("keelcap", 0))
			if shrine_used and Stats.relics.has("pilgrim_wage"):
				Stats.earn_souls(1)
				_souls_l()
				_damage_number(player.global_position + Vector3(0, 1.2 * info.tile, 0), "PILGRIM'S WAGE +1", Color(0.85, 0.75, 0.4), false)
			if kc > 0 and Stats.floor_num >= 13:
				Stats.earn_souls(kc * 2)
				_souls_l()
				_damage_number(player.global_position + Vector3(0, 1.2 * info.tile, 0), "KEEL TOLL +%d" % (kc * 2), Color(0.4, 0.9, 0.85), false)
			if ashfall:
				_ach("ashfall")
			if bone_chorus:
				_ach("chorus")
			if wolfsbane:
				_ach("wolfsbane")
			if thin_veil:
				_ach("veilwalker")
				_quest_event("veilwalk")
			if low_water:
				_ach("shoalwalker")
				_quest_event("lowwalk")
			if drift_tide:
				_quest_event("driftwalk")
			if soul_swarm:
				_quest_event("swarmwalk")
			if gauntlet:
				_quest_event("gauntletwalk")
			if brisk:
				_quest_event("briskwalk")
			if shoal_tide:
				_quest_event("shoalwalk")
			if salvage_tide:
				_quest_event("salvagewalk")
			if gale_tide:
				_quest_event("galewalk")
			if mercy_tide:
				_quest_event("mercywalk")
			if eel_tide:
				_quest_event("eelwalk")
			if swell_tide:
				_quest_event("swellwalk")
			if kelp_bed:
				_quest_event("kelpwalk")
			if barnacle_bloom:
				_quest_event("bloomwalk")
			if sodden:
				_quest_event("soddenwalk")
			if bile_tide:
				_quest_event("bilewalk")
			if mire_hollow:
				_quest_event("mirewalk")
			if dark_lantern:
				_quest_event("lampwalk")
			if halfwreck:
				_quest_event("wreckwalk")
			if merchant_tide:
				_quest_event("martwalk")
			if hungry_urns:
				_quest_event("urnmarch")
			if bilge_run:
				_quest_event("bilgewalk")
			if pale_squall:
				_quest_event("squallwalk")
			if soul_flush:
				_quest_event("flushwalk")
			if kings_tithe:
				_quest_event("tithewalk")
			if black_calm:
				_quest_event("calmwalk")
			if gun_smoke:
				_quest_event("smokewalk")
				_ach("smokedout")
			if greedy_tide:
				_quest_event("greedywalk")
			if drift_wreck:
				_quest_event("wreckwalk2")
			if long_watch:
				_quest_event("watchwalk")
			if salted_deck:
				_quest_event("saltwalk")
			if crows_tide:
				_quest_event("crowwalk")
			if long_night:
				_quest_event("nightwalk")
			if halfway_dead:
				_quest_event("cullwalk")
			if rich_vein:
				_quest_event("veinwalk")
			if wraiths_due:
				_quest_event("wraithed")
			if pale_lantern_ev:
				_quest_event("lanternwalk")
			if saltgrave_ev:
				_quest_event("saltgrave_walk")
			if leeward_ev:
				_quest_event("leeward_walk")
			if brine_smoke:
				_quest_event("smokewalk")
			if crowns_ransom:
				_quest_event("ransomwalk")
			if bilge_strike:
				_quest_event("strikewalk")
			if full_draught:
				_quest_event("draughtwalk")
			if salt_front:
				_quest_event("frontwalk")
			if cold_snap:
				_quest_event("snapwalk")
			if full_moon:
				_quest_event("moonwalk")
			if gunners_luck:
				_quest_event("luckwalk")
			if shallow_graves:
				_quest_event("gravewalk")
			if wailing_wind:
				_quest_event("wailwalk")
				_ach("saltwalker")
			if balmy_sea:
				_quest_event("balmywalk")
			if rust_storm:
				_quest_event("rustwalk")
			if ember_wake:
				_quest_event("emberwalk")
			if saltsick:
				_quest_event("saltwalk")
			if gallows_tide:
				_quest_event("gallowswalk")
			if pilot_light:
				_quest_event("pilotwalk")
			if pilot_light:
				_quest_event("pilotwalk")
			if widdershins:
				_quest_event("widderwalk")
			if slack_water:
				_quest_event("slackwalk")
			if salvage_breeze:
				_quest_event("breezewalk")
			if deep_salve:
				_quest_event("salvewalk")
			if keel_spirit:
				_quest_event("spiritwalk")
			if lantern_wake:
				_quest_event("wakewalk")
			if fog_bank:
				_quest_event("fogwalk")
			if tide_clock:
				_quest_event("clockwalk")
			if deep_well:
				_quest_event("wellwalk")
			if bilge_still:
				_quest_event("stillwalk")
			if keel_groan:
				_quest_event("groanwalk")
			if saltwind:
				_quest_event("windwalk")
			if bone_lantern:
				_quest_event("lanternwalk2")
			if dead_reckoning:
				_quest_event("reckonwalk")
			if gloom_tide:
				_quest_event("gloomwalk")
			if pale_wake:
				_quest_event("wakewalk")
			if murk_lift:
				_quest_event("murkwalk")
			if siren_hum:
				_quest_event("humwalk")
			if grim_calm:
				_quest_event("grimwalk")
			if keel_haul:
				_quest_event("haulwalk")
			if weeping_tide:
				_quest_event("tearwalk")
			if deep_draught:
				_quest_event("keelwalk")
			if thick_tide:
				_quest_event("thickwalk")
			if slack_line:
				_quest_event("linewalk")
			if low_lantern:
				_quest_event("wickwalk")
			if mirage_sea:
				_quest_event("miragewalk")
			if bilge_lull:
				_quest_event("lullwalk")
			if dark_water:
				_quest_event("darkwalk")
			if glass_sea:
				_quest_event("glasswalk")
			if dread_tide:
				_quest_event("dreadtide")
			if starved_deep:
				_quest_event("starved")
			if choir:
				_quest_event("choirfloor")
			if abyssal_hymn:
				_quest_event("hymnfloor")
				Stats.dread_survived += 1
				if Stats.dread_survived >= 3:
					_ach("dreadlord")
			Stats.note_floor()
			Stats.save_run()
			for gi in gates:
				gates[gi].set_open(true)
				_quest_event("gate_open")
			if skeleton_crew:
				_quest_event("crewfloor")
			if rolling_fog:
				_ach("fogwalker")
				_quest_event("fogfloor")
			if tut_active and tut_step >= 2:
				tut_active = false
				Stats.tutorial_done = true
				Stats.save_game()
				_tut_hide()
			if knight_ref != null and is_instance_valid(knight_ref):
				var vbark2 := ["Onward, boy — the dark is thick below.", "That's the floor, lad. One less between you and the crown.", "Good cleaving. My old company would've sung."]
				_damage_number(knight_ref.global_position + Vector3(0, 1.0 * info.tile, 0), vbark2[rng.randi_range(0, vbark2.size() - 1)], Color(0.7, 0.9, 1.1), false)
			if Stats.relics.has("second_wind") and player != null and is_instance_valid(player):
				var wind_heal: float = Stats.get_stat("max_hp") * 0.2
				player.hp = minf(player.max_hp, player.hp + wind_heal)
				player.hp_changed.emit(player.hp)
				_damage_number(player.global_position + Vector3(0, 0.8, 0), "SECOND WIND +%d" % int(ceil(wind_heal)), Color(0.5, 1.0, 0.7), true)
				Sfx.play("heal")
			_show_banner("FLOOR %d CLEARED" % Stats.floor_num, "%d kills this run • best combo ×%d • %d:%02d — tap to descend to Floor %d" % [kills_run, combo_max, int(run_time) / 60, int(run_time) % 60, Stats.floor_num + 1])
			if player != null and is_instance_valid(player):
				_burst(player.global_position, Color(1.0, 0.85, 0.3))
				_souls(player.global_position, 12, Color(1.0, 0.8, 0.35))
				Sfx.play("victory")
	# permata XP terakhir, supaya logika gerbang di atas tidak keganggu bila gem gagal
	if e.golden:
		_damage_number(e.global_position, "LUCKY ×3", Color(1.0, 0.85, 0.3), true)
	if e.elite and String(biome.get("name", "")) == "Sunken Reliquary":
		Stats.earn_souls(4)
		_souls_l()
		_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "COURT'S HOARD — +4 souls", Color(0.5, 0.95, 0.85), true)
	if e.elite:
		_quest_event("elite_kill", 1)
		_quest_event("affix_" + String(e.get("affix")), 1)
		if String(e.get("affix")) == "powderkeg":
			_quest_event("keg_kill", 1)
		if String(e.arch_id) == "crowned" and String(biome.get("name", "")) == "Sunken Reliquary":
			_quest_event("emissary_kill", 1)
		if Stats.relics.has("kings_ledger"):
			Stats.earn_souls(2)
			_souls_l()
			_damage_number(e.global_position + Vector3(0, 1.1 * info.tile, 0), "LEDGER +2", Color(0.5, 0.95, 0.85), false)
		if e.get("keel_marked") == true:
			Stats.earn_souls(1)
			_souls_l()
		if crowns_vigil:
			Stats.earn_souls(3)
			_souls_l()
			_damage_number(e.global_position + Vector3(0, 1.4 * info.tile, 0), "VIGIL +3", Color(0.9, 0.7, 0.2), false)
		if fog_lantern_d:
			Stats.earn_souls(1)
			_souls_l()
			_damage_number(e.global_position + Vector3(0, 1.0 * info.tile, 0), "LANTERN +1", Color(0.9, 0.85, 0.5), false)
		if hull_bonus:
			Stats.earn_souls(1)
			_souls_l()
			_damage_number(e.global_position + Vector3(0, 1.2 * info.tile, 0), "HULL BONUS +1", Color(0.9, 0.8, 0.4), false)
		if choir:
			_quest_event("choirkill")
		if sirensong_deal:
			Stats.earn_souls(4)
			_souls_l()
			_damage_number(e.global_position + Vector3(0, 1.5 * info.tile, 0), "SIREN PAID — +4", Color(0.7, 0.5, 1.15), false)
		if crown_oath:
			crown_oath = false
			Stats.earn_souls(8)
			_souls_l()
			_damage_number(e.global_position + Vector3(0, 1.3 * info.tile, 0), "CROWN PAID — +8 souls", Color(1.0, 0.8, 0.3), true)
		if not e.is_boss:
			Engine.time_scale = 0.45
			get_tree().create_timer(0.18, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	# bonus XP dari kombo aktif: +5% per streak (maks +50%)
	var xp_bonus := 1.0 + minf(float(combo), 10.0) * 0.05
	if soul_rush:
		xp_bonus *= 1.6
	if dead_weight:
		xp_bonus *= 1.15
	if ossuary:
		xp_bonus *= 2.0
	if mirror_hall:
		xp_bonus *= 1.4
	_spawn_gems(e.global_position, int(e.xp_val * xp_bonus))


func _on_boss_died(_e) -> void:
	# slow-mo saat raja tumbang
	Engine.time_scale = 0.25
	get_tree().create_timer(0.7, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	boss_ref = null
	Stats.boss_kills += 1
	Stats.earn_souls(15 + 5 * mini(Stats.ng_plus, 5))
	if Stats.nemesis == "bone_king":
		Stats.nemesis = ""
		Stats.nemesis_name = ""
		Stats.earn_souls(10)
		_lvl_banner("◆ NEMESIS SLAIN — the King's debt is paid (+10 souls)")
		_ach("nem1")
	_souls_l()
	Stats.save_game()
	Sfx.play("victory")
	Sfx.play_music(_biome_track())
	_quest_event("boss_kill")
	if Stats.boss_kills >= 1:
		_ach("b1")
	if Stats.boss_kills >= 3:
		_ach("b3")
	_boss_bar_hide()
	toast(boss_name + " falls! +15 XP, +15 souls")
	# epilog singkat setelah bos tumbang (kecuali pemain buru-buru turun)
	var fl := Stats.floor_num
	get_tree().create_timer(1.4).timeout.connect(func() -> void:
		if Stats.floor_num != fl or Stats.draft_open or (dlg != null and dlg.active):
			return
		if Stats.floor_num >= 25:
			if Stats.ng_plus > 0:
				_say([
					{"who": "raja", "text": "AGAIN?! How many crowns must I lose, slicer?"},
					{"who": "oracle", "text": "The throne falls a second time — and the dark below stirs, deeper still."},
					{"who": "mahzan", "text": "Twice a conqueror! My ledgers salute you, friend."},
					{"who": "kael", "text": "Then keep the torches lit. This isn't over until the dark runs out of floors."},
				])
			else:
				_say([
					{"who": "raja", "text": String(_boss_tier()["death"])},
					{"who": "oracle", "text": "The throne is ash, Kael. The kingdom below... finally sleeps."},
					{"who": "mahzan", "text": "A customer turned conqueror. I'll miss our little trades."},
					{"who": "kael", "text": "Tell the surface to light the torches. I'm coming home."},
				])
		else:
			_say([
				{"who": "raja", "text": String(_boss_tier()["death"])},
				{"who": "oracle", "text": "He will rise again five floors deeper — stronger. Keep descending, Kael."},
			])
	)
	_damage_number(_e.global_position, "BOSS DOWN", Color(1.0, 0.5, 0.2), true)


func _boss_banter(idx: int) -> void:
	var lines: Array = _boss_tier().get("banter", ["..."])
	var txt: String = String(lines[mini(idx, lines.size() - 1)])
	var l: Label = ui.get("boss_banter")
	if l == null:
		return
	l.text = boss_name + ": " + txt
	l.modulate = Color(1.0, 0.5, 0.4, 1.0)
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)


func _boss_enraged() -> void:
	toast(boss_name + " RAGES!")
	trauma = 0.9
	# bar membara saat enrage
	if ui.has("boss_fill"):
		var fb := StyleBoxFlat.new()
		fb.bg_color = Color(1.0, 0.45, 0.1)
		fb.set_corner_radius_all(4)
		ui.boss_fill.add_theme_stylebox_override("fill", fb)
	if ui.has("boss_name"):
		ui.boss_name.modulate = Color(1.0, 0.4, 0.2)
		ui.boss_name.text = "☠ " + boss_name + " — ENRAGED"
		# nameplate membara denyut selama enrage
		var etw: Tween = ui.boss_name.create_tween()
		etw.set_loops(20)
		etw.tween_property(ui.boss_name, "modulate", Color(1.4, 0.7, 0.4), 0.3)
		etw.tween_property(ui.boss_name, "modulate", Color(1, 1, 1), 0.3)


func _on_player_died() -> void:
	print("PLAYER DIED floor=%d" % Stats.floor_num)
	if not oracle_bargained and Stats.souls >= (8 if sea_burial else 15):
		oracle_bargained = true
		_offer_oracle_bargain()
		return
	run_state = "dead"
	Engine.time_scale = 0.3
	get_tree().create_timer(0.55, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	var new_record := Stats.floor_num >= Stats.best_floor
	Stats.note_floor()
	Stats.clear_run()
	Stats.runs += 1
	if Stats.runs >= 25:
		_ach("persistent")
	Stats.save_game()
	_tut_hide()
	Input.vibrate_handheld(280)
	if player != null and is_instance_valid(player):
		_souls(player.global_position, 18, Color(0.85, 0.9, 1.0))
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	var rec := "\nNEW RECORD!" if new_record and Stats.floor_num > 1 else ""
	var killer: String = "the dungeon itself"
	if player != null and is_instance_valid(player):
		killer = String(KILLER_NAMES.get(player.last_killer, player.last_killer))
		if String(player.last_killer) == Stats.nemesis:
			killer += " AGAIN — it knows your scent now"
		Stats.nemesis = String(player.last_killer)
		Stats.nemesis_name = String(KILLER_NAMES.get(player.last_killer, player.last_killer)).capitalize()
		nemesis_warned = false
	var ktip: String = ""
	var epit: String = "\n'" + EPITAPHS[rng.randi_range(0, EPITAPHS.size() - 1)] + "'"
	if player != null and is_instance_valid(player):
		ktip = "\n" + String(KILLER_TIPS.get(player.last_killer, ""))
	_show_banner("YOU DIED", "Floor %d • %s — slain by %s\n%d kills • Lv %d • %d relics • best combo ×%d • %d:%02d\n+%d souls banked • Best: Floor %d — tap to retry%s%s" % [Stats.floor_num, biome["name"], killer, kills_run, Stats.level, Stats.relics.size(), combo_max, mins, secs, Stats.souls - run_souls_start, Stats.best_floor, rec, ktip, epit], Color(1.0, 0.32, 0.28))


func _offer_oracle_bargain() -> void:
	run_state = "dead"
	Engine.time_scale = 0.15
	get_tree().create_timer(0.5, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	_tut_hide()
	Input.vibrate_handheld(160)
	dlg_pending_choice = 4
	_say(
		[{"who": "oracle", "text": "Your thread frays, Kael — but I can knot it back. Fifteen souls, and you rise where you fell."}],
		[{"text": "RISE AGAIN — pay %d souls (◈ %d held)" % [(8 if sea_burial else 15), Stats.souls]},
		 {"text": "Let the dark take me"}])


func _oracle_deal(idx: int) -> void:
	if idx != 0 or Stats.souls < _soul_cost(8 if sea_burial else 15) or player == null or not is_instance_valid(player):
		_finalize_death()
		return
	Stats.souls -= _soul_cost(8 if sea_burial else 15)
	_count_deal()
	Stats.save_game()
	_souls_l()
	run_state = "playing"
	player.dead = false
	if player.body_cs != null:
		player.body_cs.set_deferred("disabled", false)
	player.hp = float(maxi(1.0, player.max_hp * 0.5))
	player.invuln = 3.0
	player.hp_changed.emit(player.hp)
	_ach("reborn")
	_shock_ring(player.global_position)
	_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.55, 1.0, 0.75))
	_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "RESURRECTED", Color(0.55, 1.0, 0.75), true)
	Sfx.play("victory")
	Sfx.play("shrine")


func _finalize_death() -> void:
	run_state = "dead"
	Engine.time_scale = 0.3
	get_tree().create_timer(0.55, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	var new_record := Stats.floor_num >= Stats.best_floor
	Stats.note_floor()
	Stats.clear_run()
	Stats.runs += 1
	if Stats.runs >= 25:
		_ach("persistent")
	Stats.save_game()
	_tut_hide()
	Input.vibrate_handheld(280)
	if player != null and is_instance_valid(player):
		_souls(player.global_position, 18, Color(0.85, 0.9, 1.0))
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	var rec := "\nNEW RECORD!" if new_record and Stats.floor_num > 1 else ""
	var killer: String = "the dungeon itself"
	if player != null and is_instance_valid(player):
		killer = String(KILLER_NAMES.get(player.last_killer, player.last_killer))
		if String(player.last_killer) == Stats.nemesis:
			killer += " AGAIN — it knows your scent now"
		Stats.nemesis = String(player.last_killer)
		Stats.nemesis_name = String(KILLER_NAMES.get(player.last_killer, player.last_killer)).capitalize()
		nemesis_warned = false
	var ktip: String = ""
	var epit: String = "\n'" + EPITAPHS[rng.randi_range(0, EPITAPHS.size() - 1)] + "'"
	if player != null and is_instance_valid(player):
		ktip = "\n" + String(KILLER_TIPS.get(player.last_killer, ""))
	_show_banner("YOU DIED", "Floor %d • %s — slain by %s\n%d kills • Lv %d • %d relics • best combo ×%d • %d:%02d\n+%d souls banked • Best: Floor %d — tap to retry%s%s" % [Stats.floor_num, biome["name"], killer, kills_run, Stats.level, Stats.relics.size(), combo_max, mins, secs, Stats.souls - run_souls_start, Stats.best_floor, rec, ktip, epit], Color(1.0, 0.32, 0.28))


func _run_victory() -> void:
	run_state = "won"
	Stats.note_floor()
	Stats.clear_run()
	Stats.runs += 1
	Stats.ng_plus += 1
	if Stats.ng_plus >= 2:
		_ach("ng2")
	if Stats.ng_plus >= 4:
		_ach("ng4")
	if Stats.ng_plus >= 7:
		_ach("ng7")
	Stats.earn_souls(25)
	_souls_l()
	Stats.save_game()
	_ach("s25")
	if Stats.kaels_wager:
		_ach("onedrop")
	_tut_hide()
	if player != null and is_instance_valid(player):
		_burst(player.global_position, Color(0.6, 1.0, 0.75))
		_souls(player.global_position, 20, Color(0.6, 1.0, 0.75))
	Sfx.play("victory")
	Input.vibrate_handheld(400)
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	var win_line := "The Bone King's crown shatters."
	if Stats.ng_plus >= 2:
		win_line = "The crown shatters AGAIN — somewhere deeper, it is already being reforged."
	var wname := String(WDB.get_w(Stats.weapon_id)["name"])
	var relic_names: Array = []
	for rid9 in Stats.relics:
		relic_names.append(String(ITEMS.DB[rid9]["name"]))
	var arsenal := "✦ %s%s" % [wname, ("\n◆ " + " • ".join(relic_names.slice(0, 4))) if relic_names.size() > 0 else ""]
	if omen_name != "":
		arsenal += "\n☗ " + omen_name
	_show_banner("THE THRONE FALLS", "%s\n%s\n%d kills • Lv %d • %d relics • best combo ×%d • %d:%02d\nNG+%d unlocked — the depths grow crueler\nTap to return to the surface" % [win_line, arsenal, kills_run, Stats.level, Stats.relics.size(), combo_max, mins, secs, Stats.ng_plus], Color(0.55, 1.0, 0.72))


func _on_banner_tap() -> void:
	if run_state == "won":
		await _fade_to(1.0, 0.4)
		get_tree().change_scene_to_file("res://app/menu.tscn")
	elif run_state == "cleared":
		_quest_event("descend")
		if ferry_skip:
			ferry_skip = false
			Stats.floor_num += 1 + ferry_extra
			ferry_extra = 0
			toast("The Ferryman rows you past a floor")
		Stats.floor_num += 1
		if pilgrims_purse:
			Stats.earn_souls(2)
		Stats.note_floor()
		if Stats.floor_num >= 5:
			_ach("f5")
		if Stats.floor_num >= 10:
			_ach("f10")
		if Stats.floor_num >= 15:
			_ach("f15")
		if Stats.floor_num >= 20:
			_ach("f20")
		if Stats.floor_num >= 24:
			_ach("f24")
		var q_heal := Stats.get_stat("max_hp") * 0.05 * int(Stats.meta.get("quarter", 0))
		if q_heal > 0.0 and player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + q_heal)
			player.hp_changed.emit(player.hp)
			toast("QUARTERMASTER — your wounds were dressed on the way down")
		await _fade_to(1.0, 0.3)
		_new_run(rng.randi())
		_fade_to(0.0, 0.45)
	elif run_state == "dead":
		Stats.reset_run()
		_reset_run_state()
		kills_run = 0
		var purse_n: int = int(Stats.meta.get("purse", 0))
		if purse_n > 0:
			Stats.souls += purse_n * 3
		run_souls_start = Stats.souls
		last_stand_kills = 0
		vials = 1
		run_time = 0.0
		combo_max = 0
		mahzan_met = 0
		vane_floors = 0
		var q_heal := Stats.get_stat("max_hp") * 0.05 * int(Stats.meta.get("quarter", 0))
		if q_heal > 0.0 and player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + q_heal)
			player.hp_changed.emit(player.hp)
			toast("QUARTERMASTER — your wounds were dressed on the way down")
		await _fade_to(1.0, 0.3)
		_new_run(rng.randi())
		_fade_to(0.0, 0.45)


# ---------------- tutorial ----------------

func _tut_show(txt: String) -> void:
	ui.tut_label.text = txt
	ui.tut.visible = true


func _tut_hide() -> void:
	ui.tut.visible = false


# ---------------- draft (level up) ----------------

func _on_leveled_up(lv: int) -> void:
	Sfx.play("levelup")
	if player != null and is_instance_valid(player):
		player.hp = minf(Stats.get_stat("max_hp"), player.hp + 2.0)
		_burst(player.global_position + Vector3(0, 0.4, 0), Color(1.0, 0.85, 0.3))
		_shock_ring(player.global_position)
		player.hp_changed.emit(player.hp)
	_lvl_banner("LEVEL UP — Lv %d" % lv)
	if lv >= 30:
		_ach("seasoned")
	if lv >= 50:
		_ach("grizzled")
	for id in SK.ORDER:
		if int(SK.DB[id]["unlock"]) == lv:
			toast("Skill unlocked: %s!" % SK.DB[id]["name"])
	var mx_unlock := 1
	for id2 in SK.ORDER:
		mx_unlock = maxi(mx_unlock, int(SK.DB[id2]["unlock"]))
	if lv >= mx_unlock:
		_ach("arsenal_full")
	if squire_ref != null and is_instance_valid(squire_ref):
		squire_ref.dmg = maxf(1.0, Stats.get_stat("atk") * 0.35)
		_souls(squire_ref.global_position, 4, Color(0.9, 0.85, 0.5))
	pending_drafts += 1
	_try_open_draft()


func _try_open_draft() -> void:
	if Stats.draft_open or pending_drafts <= 0 or run_state == "dead" or run_state == "won":
		return
	Stats.draft_open = true
	pending_drafts -= 1
	draft_rerolls = 1 + Stats.reroll_extra
	if ui.has("draft_reroll"):
		ui.draft_reroll.visible = true
	draft_choices = ITEMS.roll_choices(Stats.relics, rng, 4 if fatehand else 3)
	_build_draft_cards()
	ui.draft.visible = true
	ui.dim.visible = true
	ui.draft.pivot_offset = ui.draft.size * 0.5
	ui.draft.scale = Vector2(0.9, 0.9)
	ui.draft.modulate.a = 0.0
	var dtw: Tween = ui.draft.create_tween()
	dtw.set_parallel(true)
	dtw.tween_property(ui.draft, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dtw.tween_property(ui.draft, "modulate:a", 1.0, 0.15)
	ui.dim.modulate.a = 0.0
	var ddim: Tween = ui.dim.create_tween()
	ddim.tween_property(ui.dim, "modulate:a", 1.0, 0.2)
	get_tree().paused = true
	print("DRAFT terbuka: %s (Lv %d)" % [str(draft_choices), Stats.level])


func _draft_reroll() -> void:
	if not Stats.draft_open or draft_rerolls <= 0:
		return
	draft_rerolls -= 1
	ui.draft_reroll.visible = draft_rerolls > 0
	Sfx.play("click")
	draft_choices = ITEMS.roll_choices(Stats.relics, rng, 4 if fatehand else 3)
	_build_draft_cards()
	print("DRAFT reroll: %s" % str(draft_choices))


func _build_draft_cards() -> void:
	for c in ui.draft_cards.get_children():
		c.queue_free()
	for i in range(draft_choices.size()):
		var it: Dictionary = ITEMS.DB[draft_choices[i]]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(148, 190)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.13, 0.2, 1.0)
		sb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(10)
		sb.shadow_color = Color(0, 0, 0, 0.65)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
		card.add_theme_stylebox_override("panel", sb)
		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 8)
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip := Label.new()
		chip.text = String(it["chip"])
		chip.add_theme_font_size_override("font_size", 30)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var nl := Label.new()
		nl.text = String(it["name"])
		nl.modulate = ITEMS.RARITY_COLORS[int(it["rarity"])].lightened(0.35)
		nl.add_theme_font_size_override("font_size", 18)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var dl := Label.new()
		dl.text = String(it["desc"])
		dl.add_theme_font_size_override("font_size", 15)
		dl.modulate = Color(1, 1, 1, 0.72)
		var rid_card: String = draft_choices[i]
		if Stats.relics.count(rid_card) > 0:
			dl.text += "
— owned ×%d —" % Stats.relics.count(rid_card)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for cc in [chip, nl, dl]:
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cvb.add_child(cc)
		card.add_child(cvb)
		var idx := i
		card.mouse_entered.connect(func() -> void:
			card.pivot_offset = card.size * 0.5
			var htw: Tween = card.create_tween()
			htw.set_parallel(true)
			htw.tween_property(card, "scale", Vector2(1.05, 1.05), 0.12)
			htw.tween_property(sb, "bg_color", Color(0.2, 0.18, 0.3, 1.0), 0.12))
		card.mouse_exited.connect(func() -> void:
			var xtw: Tween = card.create_tween()
			xtw.set_parallel(true)
			xtw.tween_property(card, "scale", Vector2.ONE, 0.12)
			xtw.tween_property(sb, "bg_color", Color(0.14, 0.13, 0.2, 1.0), 0.12))
		card.gui_input.connect(func(e: InputEvent) -> void:
			if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
				Sfx.play("click")
				var ptw: Tween = card.create_tween()
				ptw.tween_property(card, "scale", Vector2(0.88, 0.88), 0.05)
				ptw.tween_property(card, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_pick_relic(idx)
		)
		ui.draft_cards.add_child(card)
		# masuk berjenjang: pop satu-satu biar berasa mewah
		card.pivot_offset = card.custom_minimum_size * 0.5
		card.scale = Vector2(0.1, 0.1)
		var ctw := card.create_tween()
		ctw.tween_interval(0.06 * i)
		ctw.tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pick_relic(i: int) -> void:
	if not Stats.draft_open or i >= draft_choices.size():
		return
	var id: String = draft_choices[i]
	var before := Stats.get_stat("max_hp")
	Stats.add_relic(id)
	var rr: int = int(ITEMS.DB[id].get("rarity", 0))
	var rcol: Color = Color(0.55, 0.85, 1.0) if rr == 0 else (Color(0.65, 0.95, 0.55) if rr == 1 else (Color(0.75, 0.5, 1.0) if rr == 2 else Color(1.0, 0.8, 0.25)))
	toast("◆ %s — %s" % [String(ITEMS.DB[id]["name"]), String(ITEMS.DB[id]["desc"])])
	if player != null and is_instance_valid(player):
		_souls(player.global_position, 8 + rr * 4, rcol)
	if Stats.relics.size() >= 10:
		_ach("col10")
	if id == "tulang_kesatria":
		_spawn_squire()
	var after := Stats.get_stat("max_hp")
	if player != null and is_instance_valid(player):
		if after > before:
			player.hp += after - before
		player.hp = minf(player.hp, Stats.get_stat("max_hp"))
		player.refresh_stats()
		player.hp_changed.emit(player.hp)
	Stats.draft_open = false
	ui.draft.visible = false
	if run_state == "playing":
		ui.dim.visible = false
	get_tree().paused = false
	print("RELIK DIPILIH: %s | ATK=%.1f SPD=%.2f HPmax=%.0f CRIT=%.2f" % [id, Stats.get_stat("atk"), Stats.get_stat("speed"), Stats.get_stat("max_hp"), Stats.get_stat("crit")])
	_try_open_draft()


# ---------------- skill ----------------

var casts_run := 0

func _cast_skill(id: String) -> void:
	if player == null or not is_instance_valid(player) or player.dead or Stats.draft_open or run_state != "playing":
		return
	if float(player.get("silence_t")) > 0.0:
		Sfx.play("deny")
		toast("SILENCED — the Hex Priest seals your skills")
		return
	if not SK.is_unlocked(id, Stats.level):
		Sfx.play("deny")
		toast("%s unlocks at Lv %d" % [SK.DB[id]["name"], int(SK.DB[id]["unlock"])])
		return
	if skill_cd[id] > 0.0:
		Sfx.play("deny")
		return
	_quest_event("skill")
	# cast flash: model bersinar sesaat — respons skill terasa
	if player.get("mat") != null:
		player.mat.set_shader_parameter("flash", 0.7)
		var ctw: Tween = player.create_tween()
		ctw.tween_property(player.mat, "shader_parameter/flash", 0.0, 0.3)
	_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.7, 1.0))
	if skill_ui.has(id):
		var sbtn: Node = skill_ui[id]["btn"]
		sbtn.pivot_offset = sbtn.size * 0.5
		sbtn.scale = Vector2(0.85, 0.85)
		var sbt: Tween = sbtn.create_tween()
		sbt.tween_property(sbtn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	match id:
		"dash":
			var dir := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			if player.move_input.length() > 0.1:
				dir = Vector3(player.move_input.x, 0, player.move_input.y).normalized()
			player.dash_burst(dir)
			Sfx.play("dash")
			_burst(player.global_position + Vector3(0, 0.4, 0), Color(0.5, 0.9, 1.0))
		"whirl":
			if Stats.relics.has("signal_fire"):
				for ri_sig in range(info.ranges.size()):
					discovered[ri_sig] = true
				_update_minimap()
			player.anim_lock = M.play_action(player.ap, ["spin", "1h_melee_attack"], 1.6)
			Sfx.play("whirl")
			_shock_ring(player.global_position)
			var dmg := Stats.get_stat("atk") * 2.0
			var hit := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.global_position.distance_to(player.global_position) < 0.95 * info.tile:
					f.take_hit(player.global_position, dmg)
					hit += 1
			trauma = 0.6
			print("SKILL whirl hit=%d dmg=%.1f" % [hit, dmg])
		"thunder":
			var foes := get_tree().get_nodes_in_group("enemies")
			var pp: Vector3 = player.global_position
			foes.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(pp) < b.global_position.distance_squared_to(pp))
			var struck := 0
			for f in foes:
				if struck >= 3:
					break
				if f.global_position.distance_to(pp) > 2.5 * info.tile:
					break
				_lightning(f.global_position)
				f.take_hit(f.global_position, Stats.get_stat("atk") * 3.0)
				f.stun(1.4)
				struck += 1
			if struck == 0:
				Sfx.play("deny")
				toast("No enemies within thunder's reach")
				return
			Sfx.play("thunder")
			trauma = 0.9
			print("SKILL thunder struck=%d" % struck)
		"warcry":
			player.anim_lock = M.play_action(player.ap, ["spellcast", "idle_combat", "idle"], 1.1)
			Sfx.play("roar")
			Stats.warcry_t = 5.0
			_shock_ring(player.global_position)
			var kd := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				var wdv: Vector3 = f.global_position - player.global_position
				wdv.y = 0
				if wdv.length() < 1.6 * info.tile:
					f.kb += wdv.normalized() * info.tile * 2.5 * (1.0 - f.kb_resist)
					kd += 1
			toast("WAR CRY! +50% ATK for 5s")
			trauma = 0.5
			print("SKILL warcry knocked=%d" % kd)
		"nova":
			player.anim_lock = M.play_action(player.ap, ["spellcast", "1h_melee_attack"], 1.4)
			Sfx.play("thunder")
			_shock_ring(player.global_position)
			_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 1.0, 0.8))
			var ndmg := Stats.get_stat("atk") * 2.0
			var kills0 := kills_run
			var nhit := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.global_position.distance_to(player.global_position) < 1.8 * info.tile:
					f.take_hit(player.global_position, ndmg)
					nhit += 1
			var healed: int = kills_run - kills0
			if healed > 0:
				player.hp = minf(player.max_hp, player.hp + float(healed))
				player.hp_changed.emit(player.hp)
				toast("SOUL NOVA — %d soul%s mended you" % [healed, "s" if healed > 1 else ""])
			trauma = 0.8
			print("SKILL nova hit=%d heals=%d" % [nhit, healed])
		"judge":
			player.anim_lock = M.play_action(player.ap, ["1h_melee_attack", "slash"], 1.3)
			Sfx.play("thunder")
			var jt: Node3D = null
			var jd: float = 2.2 * info.tile
			for f in get_tree().get_nodes_in_group("enemies"):
				var jdd: float = f.global_position.distance_to(player.global_position)
				if jdd < jd:
					jd = jdd
					jt = f
			if jt != null:
				var jmiss: float = 1.0 - clampf(float(jt.hp) / maxf(1.0, float(jt.hp_max)), 0.0, 1.0)
				var jdmg: float = Stats.get_stat("atk") * (3.0 + 2.0 * jmiss)
				var jk0 := kills_run
				jt.take_hit(player.global_position, jdmg)
				_damage_number(jt.global_position + Vector3(0, 0.6 * info.tile, 0), "JUDGED", Color(1.0, 0.95, 0.5), true)
				_burst(jt.global_position + Vector3(0, 0.4 * info.tile, 0), Color(1.0, 0.9, 0.4))
				if kills_run > jk0:
					Stats.earn_souls(2)
					_souls_l()
					toast("JUDGMENT PASSED — +2 souls")
			else:
				toast("No foe in reach")
			trauma = 0.55
		"sunder":
			player.anim_lock = M.play_action(player.ap, ["1h_melee_attack", "slash"], 1.3)
			var st: Node3D = null
			var sd: float = 2.4 * info.tile
			for f in get_tree().get_nodes_in_group("enemies"):
				var sdd: float = f.global_position.distance_to(player.global_position)
				if sdd < sd:
					sd = sdd
					st = f
			if st != null:
				st.sunder_t = 4.0
				st.take_hit(player.global_position, Stats.get_stat("atk") * 2.5)
				_damage_number(st.global_position + Vector3(0, 0.7 * info.tile, 0), "SUNDERED", Color(0.55, 0.85, 1.0), true)
				_shock_ring(st.global_position)
				Sfx.play("thunder")
			else:
				Sfx.play("deny")
				toast("No foe in reach")
				return
			trauma = 0.6
			print("SKILL sunder")
		"chains":
			Sfx.play("gate")
			var dmgc := Stats.get_stat("atk") * 0.8
			var bound := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.global_position.distance_to(player.global_position) < 1.6 * info.tile:
					f.stun(2.2)
					f.take_hit(player.global_position, dmgc)
					bound += 1
			_burst(player.global_position + Vector3(0, 0.4, 0), Color(0.6, 0.45, 1.0))
			trauma = 0.5
			print("SKILL chains bound=%d" % bound)
		"storm":
			Sfx.play("thunder")
			var dmgs := Stats.get_stat("atk") * 1.5
			var struck := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") != "dead" and bool(f.get("activated")):
					f.take_hit(f.global_position + Vector3(0, 2.0, 0), dmgs)
					_burst(f.global_position + Vector3(0, 0.6, 0), Color(0.6, 0.55, 1.15))
					struck += 1
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "SOUL STORM ×%d" % struck, Color(0.6, 0.55, 1.15), true)
			trauma = 1.0
			_quest_event("storm")
			print("SKILL storm struck=%d" % struck)
		"mend":
			if player.hp >= player.max_hp and player.chill_t <= 0.0 and player.root_t <= 0.0:
				Sfx.play("deny")
				toast("Nothing to mend")
				return
			player.chill_t = 0.0
			player.root_t = 0.0
			player.hp = minf(player.max_hp, player.hp + 2.0)
			player.hp_changed.emit(player.hp)
			Sfx.play("pickup")
			_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.55, 1.0, 0.75))
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "MENDED", Color(0.55, 1.0, 0.75), true)
			print("SKILL mend")
		"seismic":
			Sfx.play("roar")
			var dmgs := Stats.get_stat("atk") * 1.8
			var hit := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") == "dead" or not bool(f.get("activated")):
					continue
				if f.global_position.distance_to(player.global_position) < 1.6 * info.tile:
					f.take_hit(player.global_position, dmgs)
					if f.has_method("stun"):
						f.stun(1.4)
					hit += 1
			_shock_ring(player.global_position)
			trauma = 0.9
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "SEISMIC! ×%d" % hit, Color(1.0, 0.7, 0.3), true)
			_quest_event("seismic")
			print("SKILL seismic hit=%d" % hit)
		"lance":
			Sfx.play("thunder")
			var dmgl := Stats.get_stat("atk") * 1.4
			var fwd: Vector3 = -player.global_transform.basis.z
			fwd.y = 0
			var hitl := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") == "dead" or not bool(f.get("activated")):
					continue
				var tof: Vector3 = f.global_position - player.global_position
				tof.y = 0
				var along: float = tof.normalized().dot(fwd.normalized()) * tof.length()
				var lateral: float = (tof - fwd.normalized() * along).length()
				if along > 0.0 and along < 3.2 * info.tile and lateral < 0.55 * info.tile:
					f.take_hit(player.global_position, dmgl)
					_burst(f.global_position + Vector3(0, 0.5 * info.tile, 0), Color(0.65, 0.8, 1.2))
					hitl += 1
			trauma = 0.8
			_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "SOUL LANCE! ×%d" % hitl, Color(0.7, 0.85, 1.25), true)
			_quest_event("lance")
			print("SKILL lance hit=%d" % hitl)
		"gravestep":
			Sfx.play("dash")
			var gfw: Vector3 = -player.global_transform.basis.z
			gfw.y = 0
			var gtarget: Vector3 = player.global_position + gfw.normalized() * 1.3 * info.tile
			gtarget.x = clampf(gtarget.x, info.get("min_x", -100.0) + 0.4, info.get("max_x", 100.0) - 0.4)
			gtarget.z = clampf(gtarget.z, info.get("min_z", -100.0) + 0.4, info.get("max_z", 100.0) - 0.4)
			player.global_position = gtarget
			var gdmg := Stats.get_stat("atk") * 1.2
			var ghits := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") == "dead" or not bool(f.get("activated")):
					continue
				if f.global_position.distance_to(gtarget) < 1.1 * info.tile:
					f.take_hit(gtarget, gdmg)
					ghits += 1
			_burst(gtarget, Color(0.6, 0.5, 1.1))
			trauma = 0.5
			_damage_number(gtarget + Vector3(0, 0.8 * info.tile, 0), "GRAVESTEP! ×%d" % ghits, Color(0.65, 0.6, 1.2), true)
			print("SKILL gravestep hit=%d" % ghits)
			_quest_event("gravestep")
		"kingsfall":
			Sfx.play("thunder")
			var dmgk := Stats.get_stat("atk") * 3.0
			var hits := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") == "dead" or not bool(f.get("activated")):
					continue
				var d := dmgk
				if bool(f.get("is_boss")):
					d *= 1.5
				f.take_hit(player.global_position, d)
				_burst(f.global_position + Vector3(0, 0.5 * info.tile, 0), Color(1.0, 0.85, 0.4))
				hits += 1
			_shock_ring(player.global_position)
			_shock_ring(player.global_position + Vector3(0, 0.3 * info.tile, 0))
			trauma = 1.0
			_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "KINGSFALL! ×%d" % hits, Color(1.0, 0.85, 0.35), true)
			_quest_event("kingsfall")
			print("SKILL kingsfall hits=%d" % hits)
		"rites":
			Sfx.play("roar")
			var dmgr := Stats.get_stat("atk")
			var culled := 0
			var grazed := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") != "dead" and bool(f.get("activated")):
					if float(f.get("hp")) <= 0.25 * float(f.get("hp_max")):
						f.take_hit(f.global_position + Vector3(0, 2.0, 0), 9999.0)
						_burst(f.global_position + Vector3(0, 0.5, 0), Color(0.9, 0.35, 0.9))
						culled += 1
					else:
						f.take_hit(player.global_position, dmgr)
						grazed += 1
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "REAPER'S TOLL ×%d" % culled, Color(0.9, 0.35, 0.9), true)
			trauma = 1.0
			_quest_event("rites")
			print("SKILL rites culled=%d grazed=%d" % [culled, grazed])
		"tidecall":
			Sfx.play("souls")
			var dmgt := Stats.get_stat("atk") * 1.5
			var thits := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") == "dead" or not bool(f.get("activated")):
					continue
				if f.global_position.distance_to(player.global_position) < 1.6 * info.tile:
					f.take_hit(player.global_position, dmgt)
					f.set("speed", float(f.get("speed")) * 0.45)
					var tp: Vector3 = f.global_position - player.global_position
					tp.y = 0
					f.global_position += tp.normalized() * 0.35 * info.tile
					thits += 1
			_burst(player.global_position, Color(0.4, 0.85, 1.0))
			_souls(player.global_position, 8, Color(0.4, 0.85, 1.0))
			trauma = 0.7
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "TIDE CALL! ×%d" % thits, Color(0.45, 0.9, 1.1), true)
			_quest_event("tidecall")
			print("SKILL tidecall hits=%d" % thits)
		"snapjaw":
			Sfx.play("hit")
			var dmgs := Stats.get_stat("atk") * 1.2
			var shits := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.get("state") == "dead" or not bool(f.get("activated")):
					continue
				if f.global_position.distance_to(player.global_position) < 1.7 * info.tile:
					f.take_hit(player.global_position, dmgs)
					if f.has_method("stun"):
						f.stun(1.5)
					shits += 1
			_burst(player.global_position, Color(0.95, 0.95, 0.9))
			trauma = 0.5
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "SNAPJAW! ×%d" % shits, Color(0.95, 0.95, 0.9), true)
			if shits >= 3:
				_quest_event("snapjaw3")
			print("SKILL snapjaw hits=%d" % shits)
		"graveseal":
			Sfx.play("shrine")
			var gseal := 0
			for f2 in get_tree().get_nodes_in_group("enemies"):
				if f2.get("state") == "dead" or not bool(f2.get("activated")):
					continue
				if f2.has_method("stun"):
					f2.stun(2.5)
					gseal += 1
			_burst(player.global_position, Color(0.85, 0.55, 1.0))
			trauma = 0.4
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "GRAVE SEAL! ×%d" % gseal, Color(0.85, 0.55, 1.0), true)
			if gseal >= 5:
				_quest_event("seal5")
			print("SKILL graveseal sealed=%d" % gseal)
		"riptide":
			Sfx.play("bigslash")
			var rhits := 0
			for f3 in get_tree().get_nodes_in_group("enemies"):
				if f3.get("state") == "dead" or not bool(f3.get("activated")) or bool(f3.get("is_boss")):
					continue
				var rd: float = f3.global_position.distance_to(player.global_position)
				var rreach: float = 3.0 * info.tile * (1.5 if undertow_grip else 1.0)
				if rd < rreach and rd > 1.0 * info.tile:
					var rdir: Vector3 = player.global_position - f3.global_position
					rdir.y = 0
					f3.global_position += rdir.normalized() * (rd - 0.9 * info.tile)
					if f3.has_method("take_hit"):
						f3.take_hit(player.global_position, Stats.get_stat("atk") * 0.6)
					if f3.has_method("stun"):
						f3.stun(0.7)
					rhits += 1
			_burst(player.global_position, Color(0.3, 0.8, 1.0))
			trauma = 0.45
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "RIPTIDE! ×%d" % rhits, Color(0.3, 0.8, 1.0), true)
			if rhits >= 4:
				_quest_event("riptide4")
			riptide_n += 1
			if riptide_n >= 5:
				_ach("tideturner")
			print("SKILL riptide hits=%d" % rhits)
		"soultithe":
			if Stats.souls < 3:
				Sfx.play("deny")
				toast("SOUL TITHE needs 3 souls — your purse runs dry")
				skill_cd[id] = 0.0
				return
			Stats.souls -= 3
			_souls_l()
			Sfx.play("bigslash")
			var thits := 0
			var tkills_pre: int = Stats.kills
			for f4 in get_tree().get_nodes_in_group("enemies"):
				if f4.get("state") == "dead" or not bool(f4.get("activated")):
					continue
				if f4.has_method("take_hit"):
					f4.take_hit(player.global_position, Stats.get_stat("atk") * 2.0)
					thits += 1
			var trefund: int = Stats.kills - tkills_pre
			if trefund > 0:
				Stats.souls += trefund
				_souls_l()
				_quest_event("tithe", trefund)
			_burst(player.global_position, Color(0.9, 0.8, 0.3))
			trauma = 0.4
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "SOUL TITHE! ×%d" % thits, Color(0.9, 0.8, 0.3), true)
			print("SKILL soultithe hits=%d refund=%d" % [thits, trefund])
		"anchordrop":
			Sfx.play("thunder")
			var admg := Stats.get_stat("atk") * 1.6
			var ahits := 0
			for f5 in get_tree().get_nodes_in_group("enemies"):
				if f5.get("state") == "dead" or not bool(f5.get("activated")):
					continue
				if f5.global_position.distance_to(player.global_position) < 2.0 * info.tile:
					if f5.has_method("take_hit"):
						f5.take_hit(player.global_position, admg)
					f5.stun_t = 2.0
					_burst(f5.global_position + Vector3(0, 0.4 * info.tile, 0), Color(0.4, 0.7, 1.0))
					ahits += 1
			_shock_ring(player.global_position)
			trauma = 0.6
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "ANCHOR DROP! ×%d" % ahits, Color(0.4, 0.7, 1.0), true)
			print("SKILL anchordrop hits=%d" % ahits)
		"soulfall":
			var cost: float = float(player.hp) * 0.15
			if player.hp - cost < 1.0:
				toast("Too weak to pay the Soulfall")
				Sfx.play("deny")
				return
			player.hp -= cost
			player.hp_changed.emit(player.hp)
			Sfx.play("thunder")
			var fdmg: float = cost * 2.0
			var fhits := 0
			for f6 in get_tree().get_nodes_in_group("enemies"):
				if f6.get("state") == "dead" or not bool(f6.get("activated")):
					continue
				if f6.global_position.distance_to(player.global_position) < 2.2 * info.tile:
					if f6.has_method("take_hit"):
						f6.take_hit(player.global_position, fdmg)
					_burst(f6.global_position + Vector3(0, 0.4 * info.tile, 0), Color(0.9, 0.2, 0.35))
					fhits += 1
			_shock_ring(player.global_position)
			trauma = 0.6
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "SOULFALL! ×%d" % fhits, Color(0.9, 0.3, 0.4), true)
			print("SKILL soulfall cost=%d dmg=%d hits=%d" % [cost, fdmg, fhits])
		"keelsplit":
			Sfx.play("thunder")
			var kdir := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			var kdmg := Stats.get_stat("atk") * 1.4
			var khits := 0
			for f7 in get_tree().get_nodes_in_group("enemies"):
				if f7.get("state") == "dead" or not bool(f7.get("activated")):
					continue
				var kto: Vector3 = f7.global_position - player.global_position
				kto.y = 0
				var klen := kto.length()
				if klen < 3.0 * info.tile and klen > 0.01 and kdir.dot(kto.normalized()) > 0.88:
					if f7.has_method("take_hit"):
						f7.take_hit(player.global_position, kdmg)
					f7.slow_t = 2.0
					_burst(f7.global_position + Vector3(0, 0.4 * info.tile, 0), Color(0.55, 0.8, 1.0))
					khits += 1
			_shock_ring(player.global_position)
			trauma = 0.5
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "KEEL SPLIT! ×%d" % khits, Color(0.55, 0.8, 1.0), true)
			print("SKILL keelsplit hits=%d" % khits)
		"bloodtide":
			bloodtide_t = 5.0
			Sfx.play("shrine")
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "BLOODTIDE — kills pay +1 soul", Color(0.9, 0.3, 0.4), true)
			print("SKILL bloodtide t=5.0")
		"sealegs":
			for deb7 in ["weak_t", "chill_t", "root_t", "venom_t", "silence_t", "rust_t"]:
				player.set(deb7, 0.0)
			player.set("slip_t", 2.5)
			Sfx.play("shrine")
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "SEA LEGS — you stand clean", Color(0.45, 0.7, 0.9), true)
			print("SKILL sealegs purge")
		"deadreckon":
			var rkn := 0
			for rf in get_tree().get_nodes_in_group("enemies"):
				if rf.get("state") != "dead" and not bool(rf.get("is_boss")) and int(rf.get("room_idx")) == current_room:
					rf.set("hex_t", 6.0)
					rf.set("slow_t", 1.0)
					rkn += 1
			Sfx.play("shrine")
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "DEAD RECKONING — %d marked" % rkn, Color(0.75, 0.6, 1.0), true)
			print("SKILL deadreckon marked=%d" % rkn)
		"keelsplitter":
			var kn_: Object = null
			var kd_ := INF
			for kf_ in get_tree().get_nodes_in_group("enemies"):
				if kf_.get("state") != "dead":
					var kdd_: float = kf_.global_position.distance_squared_to(player.global_position)
					if kdd_ < kd_:
						kd_ = kdd_
						kn_ = kf_
			if kn_ != null:
				kn_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 3.0)
				_shock_ring(kn_.global_position)
				_damage_number(kn_.global_position + Vector3(0, 0.9 * info.tile, 0), "KEEL SPLIT", Color(0.9, 0.5, 0.3), true)
			Sfx.play("roar")
		"kingstoll":
			for kt_ in get_tree().get_nodes_in_group("enemies"):
				if kt_.get("state") != "dead" and kt_.global_position.distance_to(player.global_position) < 4.0:
					kt_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 2.5)
					kt_.velocity += (kt_.global_position - player.global_position).normalized() * 16.0
			_shock_ring(player.global_position)
			Sfx.play("roar")
		"tidesnatch":
			var tsnears: Array = []
			for tf in get_tree().get_nodes_in_group("enemies"):
				if tf.get("state") != "dead":
					tsnears.append(tf)
			tsnears.sort_custom(func(ta: Object, tb: Object) -> bool: return ta.global_position.distance_squared_to(player.global_position) < tb.global_position.distance_squared_to(player.global_position))
			for ti in range(mini(3, tsnears.size())):
				tsnears[ti].velocity += (player.global_position - tsnears[ti].global_position).normalized() * 14.0
				tsnears[ti].set("slow_t", 3.0)
			if tsnears.size() > 0:
				_shock_ring(player.global_position)
			Sfx.play("roar")
		"netcast":
			Sfx.play("swing")
			var nroot := 0
			for nrt_ in get_tree().get_nodes_in_group("enemies"):
				if nrt_.get("state") == "dead":
					continue
				if nrt_.global_position.distance_to(player.global_position) < 3.5 * info.tile:
					nrt_.stun(3.0)
					nrt_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 0.5)
					nroot += 1
			_shock_ring(player.global_position)
			if nroot > 0:
				_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "NETTED ×%d" % nroot, Color(0.6, 0.9, 0.95), true)
			else:
				toast("The net falls on empty water")
		"choruscall":
			for ccf in get_tree().get_nodes_in_group("enemies"):
				if ccf.get("state") != "dead":
					ccf.set("slow_t", 5.0)
			Sfx.play("whirl")
			toast("CHORUS CALL — the verse drags them under")
			_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.5, 0.95))
		"hullkneel":
			for hkf in get_tree().get_nodes_in_group("enemies"):
				if hkf.get("state") != "dead":
					hkf.set("slow_t", 6.0)
			Sfx.play("whirl")
			toast("HULL KNEEL — the deck bows beneath them")
			_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.5, 0.9))
		"deckwash":
			for dwf in get_tree().get_nodes_in_group("enemies"):
				if dwf.get("state") != "dead":
					var dwd: Vector3 = dwf.global_position - player.global_position
					dwd.y = 0.0
					if dwd.length() > 0.01:
						dwf.velocity += dwd.normalized() * 8.0
					dwf.stun(0.4)
			Sfx.play("whirl")
			toast("DECKWASH — the sea comes aboard")
			_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.4, 0.7, 0.9))
		"saltwake":
			var sw_foes: Array = []
			for sw_ in get_tree().get_nodes_in_group("enemies"):
				if sw_.get("state") != "dead":
					sw_foes.append(sw_)
			sw_foes.sort_custom(func(a, b): return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position))
			for swi in range(mini(3, sw_foes.size())):
				var swf = sw_foes[swi]
				swf.stun(1.2)
				swf.set("slow_t", 3.0)
				_damage_number(swf.global_position + Vector3(0, 1.0, 0), "WAKE!", Color(0.5, 0.8, 0.9), false)
			if sw_foes.size() > 0:
				Sfx.play("dash")
			else:
				Sfx.play("deny")
		"brinevolley":
			Sfx.play("swing")
			var bv_foes: Array = []
			for bv_ in get_tree().get_nodes_in_group("enemies"):
				if bv_.get("state") != "dead":
					bv_foes.append(bv_)
			bv_foes.sort_custom(func(a, b): return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position))
			for bvi in range(mini(3, bv_foes.size())):
				var bvf = bv_foes[bvi]
				bvf.take_hit(player.global_position, float(Stats.get_stat("atk")) * 1.1)
				bvf.set("slow_t", 2.0)
				_damage_number(bvf.global_position + Vector3(0, 1.0, 0), "VOLLEY!", Color(0.55, 0.85, 0.95), false)
		"chumtoss":
			Sfx.play("swing")
			var cdir: Vector3 = player.get("last_dir") if player != null and player.get("last_dir") != null else Vector3.FORWARD
			for ct_ in get_tree().get_nodes_in_group("enemies"):
				if ct_.get("state") == "dead":
					continue
				var crel: Vector3 = ct_.global_position - player.global_position
				if crel.length() <= 3.0 * info.tile and crel.length() > 0.01:
					var clat: float = absf(crel.normalized().cross(cdir.normalized()).y)
					if clat < 0.35:
						ct_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 1.2)
						ct_.set("slow_t", 2.0)
			_damage_number(player.global_position + cdir.normalized() * 2.0, "CHUM!", Color(0.7, 0.95, 0.6), true)
		"deathknell":
			for dn_ in get_tree().get_nodes_in_group("enemies"):
				if dn_.get("state") != "dead" and dn_.global_position.distance_to(player.global_position) < 3.0:
					dn_.take_hit(player.global_position, float(Stats.get_stat("atk")))
					dn_.stun(2.5)
			_shock_ring(player.global_position)
			Sfx.play("roar")
		"deckrupture":
			for dr_ in get_tree().get_nodes_in_group("enemies"):
				if dr_.get("state") != "dead" and dr_.global_position.distance_to(player.global_position) < 2.0:
					dr_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 2.0)
					dr_.stun(1.5)
			_shock_ring(player.global_position)
			Sfx.play("roar")
		"saltmaw":
			for mf_ in get_tree().get_nodes_in_group("enemies"):
				if mf_.get("state") != "dead" and mf_.global_position.distance_to(player.global_position) < 2.0 * info.tile:
					mf_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 1.4)
					mf_.slow_t = 2.0
			_shock_ring(player.global_position)
			Sfx.play("roar")
			_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "SALT MAW", Color(0.3, 0.7, 0.85), true)
		"ghostnet":
			for gf_ in get_tree().get_nodes_in_group("enemies"):
				if gf_.get("state") != "dead" and gf_.global_position.distance_to(player.global_position) < 3.0 * info.tile:
					gf_.slow_t = 4.0
			_shock_ring(player.global_position)
			Sfx.play("shrine")
			_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "GHOST NET", Color(0.5, 0.9, 0.85), true)
		"brinelash":
			var bf_ := []
			for lf_ in get_tree().get_nodes_in_group("enemies"):
				if lf_.get("state") != "dead":
					bf_.append(lf_)
			bf_.sort_custom(func(a_, b_): return a_.global_position.distance_squared_to(player.global_position) < b_.global_position.distance_squared_to(player.global_position))
			var bn_ := 0
			for lf2_ in bf_:
				if bn_ >= 3 or lf2_.global_position.distance_to(player.global_position) > 5.0 * info.tile:
					break
				bn_ += 1
				lf2_.take_hit(player.global_position, float(Stats.get_stat("atk")) * 1.2)
				lf2_.velocity += (lf2_.global_position - player.global_position).normalized() * 6.0
			_shock_ring(player.global_position)
			Sfx.play("whirl")
		"warpaint":
			Stats.warpaint_t = 5.0
			_shock_ring(player.global_position)
			Sfx.play("roar")
			_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "WARPAINT", Color(0.95, 0.4, 0.25), true)
		"bilgesnare":
			var tgt_: Object = null
			var td_: float = 9999.0
			for bs_ in get_tree().get_nodes_in_group("enemies"):
				if bs_.get("state") == "dead":
					continue
				var bd_: float = bs_.global_position.distance_to(player.global_position)
				if bd_ < td_ and bd_ < 6.0 * info.tile:
					td_ = bd_
					tgt_ = bs_
			if tgt_ != null:
				if tgt_.has_method("stun"):
					tgt_.stun(2.0)
				if tgt_.has_method("take_hit"):
					tgt_.take_hit(player.global_position, 2.0)
				_damage_number(tgt_.global_position + Vector3(0, 0.9 * info.tile, 0), "SNARED", Color(0.5, 0.7, 0.3), false)
		"saltward":
			var swn := 0
			for sw_ in get_tree().get_nodes_in_group("enemies"):
				if sw_.get("state") == "dead":
					continue
				if sw_.global_position.distance_to(player.global_position) < 3.0 * info.tile:
					sw_.set("slow_t", 3.0)
					swn += 1
			if swn > 0:
				_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "WARDED x%d" % swn, Color(0.9, 0.8, 0.4), false)
		"riptidesnare":
			var rtn := 0
			for rt_ in get_tree().get_nodes_in_group("enemies"):
				if rt_.get("state") == "dead":
					continue
				if rt_.global_position.distance_to(player.global_position) < 2.8 * info.tile:
					if rt_.has_method("stun"):
						rt_.stun(2.5)
					rtn += 1
			if rtn > 0:
				_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "SNARED x%d" % rtn, Color(0.4, 0.75, 0.9), false)
			Sfx.play("whirl")
		"salvagehook":
			var sh_tg = null
			var sh_d := 999.0
			for sh_ in get_tree().get_nodes_in_group("enemies"):
				if sh_.get("state") == "dead":
					continue
				var sh_dd: float = sh_.global_position.distance_to(player.global_position)
				if sh_dd < sh_d:
					sh_d = sh_dd
					sh_tg = sh_
			if sh_tg != null and sh_d < 5.0 * info.tile:
				var sh_pull: Vector3 = (player.global_position - sh_tg.global_position)
				sh_pull.y = 0
				sh_tg.set("kb", sh_pull.normalized() * sh_d * 0.7)
				if sh_tg.has_method("stun"):
					sh_tg.stun(1.0)
				_damage_number(sh_tg.global_position + Vector3(0, 1.0 * info.tile, 0), "HOOKED!", Color(0.5, 0.8, 1.0), false)
				Sfx.play("whirl")
			else:
				toast("Nothing close enough to hook")
		"crowsdive":
			var cdn := 0
			for cd_ in get_tree().get_nodes_in_group("enemies"):
				if cd_.get("state") == "dead":
					continue
				if cd_.global_position.distance_to(player.global_position) < 2.5 * info.tile:
					if cd_.has_method("stun"):
						cd_.stun(1.2)
					cdn += 1
			player.set("slip_t", 2.5)
			if cdn > 0:
				_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "DOVE x%d" % cdn, Color(0.6, 0.85, 1.0), false)
			Sfx.play("quest")
		"hullsplinter":
			var nhs_ := 0
			for hs_ in get_tree().get_nodes_in_group("enemies"):
				if hs_.get("state") == "dead":
					continue
				var hd_ = hs_.global_position.distance_to(player.global_position)
				if hd_ < 3.0 * info.tile and hs_.has_method("take_hit"):
					var hdm_ = Stats.get_stat("atk") * (1.0 - hd_ / (4.0 * info.tile))
					hs_.take_hit(player.global_position, maxf(1.0, hdm_))
					nhs_ += 1
			if nhs_ > 0:
				_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "SPLINTERED x%d" % nhs_, Color(0.8, 0.6, 0.4), false)
			Sfx.play("whirl")
		"keelram":
			Sfx.play("whirl")
			var kr_ := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			var krz := 0
			for kr2 in get_tree().get_nodes_in_group("enemies"):
				if kr2.get("state") == "dead" or not bool(kr2.get("activated")):
					continue
				var rel: Vector3 = kr2.global_position - player.global_position
				var along := rel.dot(kr_)
				if along > -0.3 * info.tile and along < 2.5 * info.tile and abs(rel.x * kr_.z - rel.z * kr_.x) < 0.9 * info.tile:
					if kr2.has_method("take_hit"):
						kr2.take_hit(player.global_position, Stats.get_stat("atk") * 1.5)
					kr2.kb += kr_ * 3.0 * info.tile
					krz += 1
			player.kb += kr_ * 1.6 * info.tile
			trauma = 0.45
			_damage_number(player.global_position + kr_ * 1.2 * info.tile + Vector3(0, 0.9 * info.tile, 0), "KEEL RAM ×%d" % krz, Color(0.7, 0.85, 0.95), true)
			if krz == 0:
				toast("KEEL RAM — open water")
		"deadweight":
			Sfx.play("souls")
			var dwn := 0
			for dw2 in get_tree().get_nodes_in_group("enemies"):
				if dw2.get("state") == "dead" or not bool(dw2.get("activated")):
					continue
				dw2.stun(1.5)
				dwn += 1
			trauma = 0.5
			_damage_number(player.global_position + Vector3(0, 1.2 * info.tile, 0), "DEADWEIGHT ×%d" % dwn, Color(0.5, 0.8, 0.9), true)
		"saltbomb":
			Sfx.play("whirl")
			var sb_ := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			var sc_: Vector3 = player.global_position + sb_ * 1.5 * info.tile
			var sbn := 0
			for sb2 in get_tree().get_nodes_in_group("enemies"):
				if sb2.get("state") == "dead" or not bool(sb2.get("activated")):
					continue
				if sb2.global_position.distance_to(sc_) < 2.0 * info.tile:
					if sb2.has_method("take_hit"):
						sb2.take_hit(player.global_position, Stats.get_stat("atk") * 0.8)
					sb2.set("slow_t", 3.0)
					sb2.set("hex_t", 3.0)
					sbn += 1
			_burst(sc_ + Vector3(0, 0.5 * info.tile, 0), Color(0.95, 0.9, 0.7))
			trauma = 0.35
			_damage_number(sc_ + Vector3(0, 0.9 * info.tile, 0), "SALT BOMB ×%d" % sbn, Color(0.95, 0.9, 0.6), true)
			if sbn == 0:
				toast("SALT BOMB — nothing but spray")
		"fogsong":
			Sfx.play("whirl")
			for fg_ in get_tree().get_nodes_in_group("enemies"):
				if fg_.get("state") != "dead" and bool(fg_.get("activated")):
					fg_.set("activated", false)
					fg_.set("state", "idle")
			fog_song_t = 4.0
			Stats.buff_speed_pct += 0.2
			if player != null and is_instance_valid(player):
				player.refresh_stats()
			_damage_number(player.global_position + Vector3(0, 1.1 * info.tile, 0), "FOG SONG", Color(0.7, 0.8, 0.9), true)
			toast("FOG SONG — the sea forgets your name")
		"broadside":
			player.anim_lock = M.play_action(player.ap, ["1h_melee_attack", "spellcast"], 0.8)
			Sfx.play("thunder")
			var bf_ := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			var bhit := 0
			for bf2 in get_tree().get_nodes_in_group("enemies"):
				if bf2.get("state") == "dead" or not bool(bf2.get("activated")):
					continue
				var bto: Vector3 = bf2.global_position - player.global_position
				bto.y = 0
				var bl := bto.length()
				if bl < 3.5 * info.tile and (bl < 0.01 or bto.normalized().dot(bf_) > 0.3):
					if bf2.has_method("take_hit"):
						bf2.take_hit(player.global_position, Stats.get_stat("atk") * 1.0)
					bf2.kb += bto.normalized() * info.tile * 2.5
					bhit += 1
			_shock_ring(player.global_position)
			trauma = 0.5
			_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "BROADSIDE ×%d" % bhit, Color(1.0, 0.7, 0.4), true)
			if bhit == 0:
				toast("BROADSIDE — fired into open water")
		"deadlight":
			var dl_ := 0
			for dlf in get_tree().get_nodes_in_group("enemies"):
				if dlf.get("state") != "dead" and bool(dlf.get("activated")):
					dlf.stun(2.5)
					dlf.take_hit(player.global_position, Stats.get_stat("atk") * 0.4)
					dl_ += 1
			trauma = 0.4
			Sfx.play("thunder")
			_damage_number(player.global_position + Vector3(0, 1.2 * info.tile, 0), "DEADLIGHT ×%d" % dl_, Color(1.0, 0.95, 0.5), true)
			toast("DEADLIGHT — the blinded sea staggers")
		"dragline":
			player.anim_lock = M.play_action(player.ap, ["1h_melee_attack", "spellcast"], 0.9)
			Sfx.play("dash")
			var dn_: Node3D = null
			var dd_ := 999.0
			for f3 in get_tree().get_nodes_in_group("enemies"):
				if f3.get("state") == "dead" or not is_instance_valid(f3):
					continue
				var d3: float = player.global_position.distance_to(f3.global_position)
				if d3 < dd_ and d3 < 5.0 * info.tile:
					dd_ = d3
					dn_ = f3
			if dn_ != null:
				var dir3: Vector3 = dn_.global_position - player.global_position
				dir3.y = 0
				dn_.global_position = player.global_position + dir3.normalized() * 0.8 * info.tile
				dn_.take_hit(player.global_position, Stats.get_stat("atk") * 1.2)
				_damage_number(dn_.global_position + Vector3(0, 0.9 * info.tile, 0), "DRAGGED!", Color(0.6, 0.9, 0.7), true)
				trauma = 0.35
			else:
				toast("Nothing in hook range")
		"irontide":
			player.anim_lock = M.play_action(player.ap, ["spellcast", "idle_combat", "idle"], 1.1)
			Sfx.play("roar")
			Stats.irontide_t = 5.0
			Stats.thorns += 0.5
			_shock_ring(player.global_position)
			toast("IRON TIDE! strikes bounce off your hull for 5s")
			trauma = 0.4
		"becalm":
			var bcl := 0
			for bf in get_tree().get_nodes_in_group("enemies"):
				if bf.get("state") != "dead" and not bool(bf.get("is_boss")) and int(bf.get("room_idx")) == current_room:
					bf.set("slow_t", 6.0)
					bcl += 1
			Sfx.play("shrine")
			_damage_number(player.global_position + Vector3(0, 0.8 * info.tile, 0), "BECALMED — %d becalmed" % bcl, Color(0.4, 0.7, 0.9), true)
			print("SKILL becalm slowed=%d" % bcl)
	skill_used_floor = true
	skills_floor[id] = true
	_quest_event("skill_" + id)
	if skills_floor.size() >= 3:
		_quest_event("witching")
	skill_cd[id] = float(SK.DB[id]["cd"]) * (1.0 - 0.08 * float(Stats.meta.get("arcane", 0))) * (1.0 - Stats.cd_reduction) * (0.75 if echoing else 1.0) * (0.6 if id == "dash" and umbral_tide else 1.0) * (0.7 if id == "dash" and brisk else 1.0) * (0.6 if id == "dash" and dash_fuel else 1.0) * (0.75 if oarsworn else 1.0) * (1.0 - 0.03 * float(Stats.meta.get("powdermonk", 0))) * (1.15 if sodden else 1.0) * (1.1 if slim_pickings else 1.0) * (0.92 if Stats.relics.has("bosun_whistle") else 1.0) * (1.15 if cold_snap or saltsick else 1.0) * (0.85 if bilge_bond else 1.0) * (1.1 if bosuns_debt else 1.0) * (0.8 if id == "dash" and rope_tackle else 1.0) * (0.95 if Stats.relics.has("signal_flag") else 1.0) * (0.75 if id == "dash" and whale_lung else 1.0) * (1.0 - 0.03 * float(Stats.meta.get("belaypin", 0)) if id == "dash" else 1.0) + omen_cd_add
	casts_run += 1
	if casts_run >= 40:
		_ach("fortyknells")


func _heavy_attack() -> void:
	if player == null or not is_instance_valid(player) or player.dead or run_state != "playing":
		return
	player.anim_lock = M.play_action(player.ap, ["1h_melee_attack"], 1.2)
	Sfx.play("whirl")
	_shock_ring(player.global_position)
	var dmg := Stats.get_stat("atk") * 2.5
	for f in get_tree().get_nodes_in_group("enemies"):
		if f.global_position.distance_to(player.global_position) < 1.0 * info.tile:
			f.take_hit(player.global_position, dmg)
			if deadweight and f.has_method("stun"):
				f.stun(0.6)
	if deadweight:
		_burst(player.global_position, Color(0.4, 0.6, 1.0))
	trauma = 0.7
	Engine.time_scale = 0.3
	var htw: Tween = create_tween()
	htw.set_ignore_time_scale(true)
	htw.tween_property(Engine, "time_scale", 1.0, 0.12)
	_damage_number(player.global_position, "HEAVY!", Color(1.0, 0.85, 0.3), true)
	_quest_event("heavy")


func _shock_ring(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	mi.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.5, 0.95, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.9, 1.0)
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	room.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.3, 0)
	mi.scale = Vector3.ONE * 0.15 * info.tile
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.1 * info.tile, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mi.queue_free)


func _lightning(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1 * info.tile, 7.0, 0.1 * info.tile)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.95, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.4)
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	room.add_child(mi)
	mi.global_position = pos + Vector3(0, 3.5, 0)
	_burst(pos, Color(1.0, 0.9, 0.4))
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3(1.8, 1.0, 1.8), 0.1)
	tw.tween_property(mi, "scale", Vector3(0.05, 1.0, 0.05), 0.22)
	tw.tween_callback(mi.queue_free)


func _build_skill_buttons(layer: CanvasLayer) -> void:
	for i in range(SK.ORDER.size()):
		var id: String = SK.ORDER[i]
		var b := Button.new()
		b.text = String(SK.DB[id]["short"])
		b.add_theme_font_size_override("font_size", 14)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.16, 0.24, 0.88)
		sb.border_color = Color(0.45, 0.75, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(12)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 5
		sb.shadow_offset = Vector2(0, 3)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		b.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.1, 0.9))
		b.add_theme_constant_override("outline_size", 4)
		var sbp := sb.duplicate() as StyleBoxFlat
		sbp.bg_color = Color(0.25, 0.4, 0.55, 0.95)
		b.add_theme_stylebox_override("pressed", sbp)
		b.pivot_offset = Vector2(39, 39)
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
		var ncol: int = 2 if SK.ORDER.size() > 10 else 1
		var col: int = i / maxi(1, int(ceilf(SK.ORDER.size() / float(ncol))))
		var crow: int = i - col * int(ceilf(SK.ORDER.size() / float(ncol)))
		var coln: int = int(ceilf(SK.ORDER.size() / float(ncol)))
		b.offset_left = -118 - col * 80
		b.offset_right = -40 - col * 80
		b.offset_top = -318 - (coln - 1 - crow) * 88
		b.offset_bottom = -240 - (coln - 1 - crow) * 88
		var cd := Label.new()
		cd.set_anchors_preset(Control.PRESET_TOP_WIDE)
		cd.offset_top = 2.0
		cd.offset_bottom = 42.0
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd.add_theme_font_size_override("font_size", 22)
		cd.modulate = Color(1.0, 0.95, 0.6)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cd)
		var shade := ColorRect.new()
		shade.color = Color(0.02, 0.05, 0.1, 0.55)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.visible = false
		b.add_child(shade)
		b.move_child(shade, 0)
		var sid := id
		b.pressed.connect(func() -> void:
			var stw: Tween = b.create_tween()
			stw.tween_property(b, "scale", Vector2(0.86, 0.86), 0.06)
			stw.tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_cast_skill(sid))
		layer.add_child(b)
		skill_ui[id] = {"btn": b, "cd": cd, "shade": shade, "name": String(SK.DB[id]["name"])}


func _tick_skill_ui(delta: float) -> void:
	for id in SK.ORDER:
		if not skill_ui.has(id):
			continue
		skill_cd[id] = maxf(0.0, skill_cd[id] - delta)
		var rec: Dictionary = skill_ui[id]
		var b: Button = rec["btn"]
		var lab: Label = rec["cd"]
		if not SK.is_unlocked(id, Stats.level):
			b.modulate = Color(1, 1, 1, 0.3)
			b.text = "Lv%d" % int(SK.DB[id]["unlock"])
			lab.text = ""
		elif skill_cd[id] > 0.0:
			b.modulate = Color(1, 1, 1, 0.45)
			b.text = ""
			lab.text = str(int(ceil(skill_cd[id])))
			rec["was_cd"] = true
			var sh: ColorRect = rec.get("shade")
			if sh != null:
				var frac: float = skill_cd[id] / maxf(0.01, float(SK.DB[id]["cd"]))
				sh.visible = true
				sh.anchor_top = 1.0 - frac
				sh.offset_top = 0.0
		else:
			b.modulate = Color(1, 1, 1, 1)
			b.text = String(SK.DB[id]["short"])
			lab.text = ""
			var sh2: ColorRect = rec.get("shade")
			if sh2 != null:
				sh2.visible = false
			if bool(rec.get("was_cd", false)):
				rec["was_cd"] = false
				var ptw := b.create_tween()
				ptw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.08)
				ptw.tween_property(b, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
				Sfx.play("xp")


# ---------------- layar hero ----------------

func _find_slot(node: Node) -> Node3D:
	var nm: String = node.name.to_lower().replace(".", "").replace("_", "")
	if nm == "handslotr":
		return node as Node3D
	for c in node.get_children():
		var r := _find_slot(c)
		if r != null:
			return r
	return null


func _toggle_hero(open: bool) -> void:
	if open:
		_refresh_hero()
		ui.hero.visible = true
		ui.dim.visible = true
		Stats.draft_open = true
		get_tree().paused = true
		Sfx.play("click")
		ui.hero.pivot_offset = ui.hero.size * 0.5
		ui.hero.scale = Vector2(0.9, 0.9)
		ui.hero.modulate.a = 0.0
		var htw: Tween = ui.hero.create_tween()
		htw.set_parallel(true)
		htw.tween_property(ui.hero, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		htw.tween_property(ui.hero, "modulate:a", 1.0, 0.15)
	else:
		ui.hero.visible = false
		Stats.draft_open = false
		get_tree().paused = false
		if run_state == "playing":
			ui.dim.visible = false
		Sfx.play("click")


func _swap_weapon() -> void:
	if Stats.owned_weapons.size() < 2:
		Sfx.play("deny")
		toast("Only one blade owned — find drops to swap")
		return
	if run_state != "playing" or Stats.draft_open:
		return
	var idx: int = Stats.owned_weapons.find(Stats.weapon_id)
	var nxt: String = String(Stats.owned_weapons[(idx + 1) % Stats.owned_weapons.size()])
	_hero_equip(nxt)
	_quest_event("swap")
	toast("Swapped to " + String(WDB.get_w(nxt)["name"]))


func _hero_equip(wid: String) -> void:
	if player != null and is_instance_valid(player):
		player.equip_weapon(wid)
	else:
		Stats.equip_weapon(wid)
		_refresh_hud_weapon()
	Sfx.play("pickup")
	if Stats.owned_weapons.size() >= 15:
		_ach("arsenal")
	if Stats.owned_weapons.size() >= 5:
		_ach("w5")
	if Stats.owned_weapons.size() >= 8:
		_ach("w8")
	_refresh_hero()


func _refresh_hero() -> void:
	# senjata di tangan model preview
	var slot := _find_slot(ui.hero_model)
	if slot != null:
		for c in slot.get_children():
			c.queue_free()
		var w: Dictionary = WDB.get_w(Stats.weapon_id)
		var wm: Node3D = load(WDB.DIR + w["gltf"]).instantiate()
		M.paint(wm, M.toon(skeleton_tex, w["tint"], 0.35))
		slot.add_child(wm)
	# kolom kanan
	var vb: VBoxContainer = ui.hero_right
	for c in vb.get_children():
		c.queue_free()

	var t := Label.new()
	t.text = "HERO"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var rows := [
		["Level", str(Stats.level)],
		["XP", "%d / %d" % [Stats.xp, Stats.xp_need()]],
		["ATK", "%.0f" % Stats.get_stat("atk")],
		["Max HP", "%.0f" % Stats.get_stat("max_hp")],
		["Speed", "%.0f%%" % (Stats.get_stat("speed") * 100.0)],
		["Crit", "%.0f%%" % (Stats.get_stat("crit") * 100.0)],
		["Lifesteal", "%.0f%%" % (Stats.get_stat("lifesteal") * 100.0)],
		["Armor", "%d" % int(Stats.get_stat("armor"))],
		["Attack Speed", "%.0f%%" % (Stats.get_stat("atk_speed") * 100.0)],
		["Dodge", "%.0f%%" % (Stats.dodge * 100.0)],
		["Pickup Range", "+%.0f%%" % (Stats.magnet * 100.0)],
		["Omens", omen_name if omen_name != "" else "—"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	for r in rows:
		var k := Label.new()
		k.text = r[0]
		k.modulate = Color(1, 1, 1, 0.6)
		k.add_theme_font_size_override("font_size", 17)
		grid.add_child(k)
		var v := Label.new()
		v.text = r[1]
		v.add_theme_font_size_override("font_size", 17)
		grid.add_child(v)
	vb.add_child(grid)

	var wl := Label.new()
	wl.text = "WEAPONS (tap to switch)"
	wl.add_theme_font_size_override("font_size", 15)
	wl.modulate = Color(1.0, 0.85, 0.4)
	vb.add_child(wl)
	for wid in Stats.owned_weapons:
		var wd: Dictionary = WDB.get_w(wid)
		var wb := Button.new()
		var cur: bool = wid == Stats.weapon_id
		var wlv: int = int(Stats.weapon_lv.get(wid, 1))
		var wms := " ★" if int(Stats.mastered.get(wid, 0)) > 0 else ""
		var wpr := " (%d/%d mastery)" % [mini(int(Stats.weapon_kills.get(wid, 0)), Stats.MASTERY_N), Stats.MASTERY_N] if wms == "" else ""
		wb.text = ("• " if cur else "") + wd["name"] + wms + ("  Lv%d" % wlv if wlv > 1 else "") + wpr + "\n" + wd["desc"]
		wb.add_theme_font_size_override("font_size", 14)
		wb.custom_minimum_size = Vector2(0, 54)
		var wsb := StyleBoxFlat.new()
		wsb.bg_color = Color(0.2, 0.17, 0.1, 0.95) if cur else Color(0.13, 0.12, 0.18, 0.95)
		wsb.border_color = Color(0.9, 0.75, 0.3) if cur else Color(0.35, 0.32, 0.4)
		wsb.set_border_width_all(2)
		wsb.set_corner_radius_all(8)
		wb.add_theme_stylebox_override("normal", wsb)
		var swid: String = wid
		wb.pressed.connect(func() -> void: _hero_equip(swid))
		vb.add_child(wb)

	var rl := Label.new()
	rl.text = "RELIC (%d)" % Stats.relics.size()
	rl.add_theme_font_size_override("font_size", 15)
	rl.modulate = Color(1.0, 0.85, 0.4)
	vb.add_child(rl)
	var rgrid := GridContainer.new()
	rgrid.columns = 6
	rgrid.add_theme_constant_override("h_separation", 6)
	rgrid.add_theme_constant_override("v_separation", 6)
	for rid in Stats.relics:
		var it: Dictionary = ITEMS.DB[rid]
		var p := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.1, 0.1, 0.16, 0.9)
		psb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(6)
		psb.set_content_margin_all(6)
		p.add_theme_stylebox_override("panel", psb)
		var l := Label.new()
		l.text = it["chip"]
		l.add_theme_font_size_override("font_size", 14)
		l.tooltip_text = it["name"] + " — " + it["desc"]
		p.add_child(l)
		rgrid.add_child(p)
	if Stats.relics.is_empty():
		var none := Label.new()
		none.text = "(no relics yet)"
		none.modulate = Color(1, 1, 1, 0.4)
		none.add_theme_font_size_override("font_size", 14)
		rgrid.add_child(none)
	vb.add_child(rgrid)

	var sl := Label.new()
	sl.text = "SKILL"
	sl.add_theme_font_size_override("font_size", 15)
	sl.modulate = Color(1.0, 0.85, 0.4)
	vb.add_child(sl)
	for id in SK.ORDER:
		var sd: Dictionary = SK.DB[id]
		var unlocked := SK.is_unlocked(id, Stats.level)
		var sl2 := Label.new()
		sl2.text = "%s — %s%s" % [sd["name"], sd["desc"], "" if unlocked else " (locked: Lv %d)" % int(sd["unlock"])]
		sl2.add_theme_font_size_override("font_size", 14)
		sl2.modulate = Color(1, 1, 1, 0.85) if unlocked else Color(1, 1, 1, 0.35)
		sl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(sl2)

	var hclose := _pause_btn("CLOSE")
	hclose.pressed.connect(func() -> void: _toggle_hero(false))
	vb.add_child(hclose)


# ---------------- combat juice ----------------

func _on_hit_landed(pos: Vector3, dmg: float, crit: bool) -> void:
	trauma = 0.65 if crit else 0.5
	_hit_spark(pos, crit)
	Input.vibrate_handheld(45 if crit else 25)
	_damage_number(pos, str(int(round(dmg))), Color(1.0, 0.5, 0.15) if crit else Color(1.0, 0.85, 0.3), crit)
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.09 if crit else 0.05, true, false, true).timeout
	Engine.time_scale = 1.0


func _hit_spark(pos: Vector3, crit: bool) -> void:
	var sm := SphereMesh.new()
	sm.radial_segments = 6
	sm.rings = 4
	sm.radius = 0.12 * info.tile * (1.6 if crit else 1.0)
	sm.height = sm.radius * 2.0
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color(1.0, 0.65, 0.2, 0.9) if crit else Color(1.0, 0.95, 0.7, 0.8)
	mt.emission_enabled = true
	mt.emission = mt.albedo_color
	mt.emission_energy_multiplier = 3.0
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var m := MeshInstance3D.new()
	m.mesh = sm
	m.material_override = mt
	add_child(m)
	m.global_position = pos + Vector3(0, 0.5 * info.tile, 0)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1.7, 1.7, 1.7), 0.12)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.14)
	tw.set_parallel(false)
	tw.tween_callback(m.queue_free)


func _damage_number(pos: Vector3, txt: String, col: Color, big := false) -> void:
	var l := Label3D.new()
	room.add_child(l)
	l.text = txt
	l.font_size = 140 if big else 96
	l.pixel_size = 0.012
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = col
	l.outline_size = 22
	l.outline_modulate = Color(0.08, 0.02, 0.0, 0.9)
	l.no_depth_test = true
	l.global_position = pos + Vector3(rng.randf_range(-0.35, 0.35), 1.3, rng.randf_range(-0.35, 0.35))
	if big:
		l.scale = Vector3(1.8, 1.8, 1.8)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.2, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if big:
		tw.tween_property(l, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position:x", l.global_position.x + rng.randf_range(-0.5, 0.5), 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)


func _burst(pos: Vector3, col := Color(0.95, 0.95, 1.0)) -> void:
	var p := GPUParticles3D.new()
	room.add_child(p)
	p.global_position = pos + Vector3(0, 0.8, 0)
	p.amount = 12 if low_quality else 22
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.7
	p.visibility_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	pm.color = col
	p.process_material = pm
	var dot := SphereMesh.new()
	dot.radius = 0.035
	dot.height = 0.07
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = col
	dm.emission_enabled = true
	dm.emission = col
	dm.emission_energy_multiplier = 2.0
	dot.material = dm
	p.draw_pass_1 = dot
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


var _toast_queue: Array = []
func toast(txt: String) -> void:
	if ui.toast_panel.visible and ui.toast_panel.modulate.a > 0.3 and ui.toast.text != txt:
		if _toast_queue.size() < 3:
			_toast_queue.append(txt)
		return
	ui.toast.text = txt
	ui.toast_panel.visible = true
	ui.toast_panel.modulate.a = 1.0
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	ui.toast_panel.pivot_offset = ui.toast_panel.size * 0.5
	ui.toast_panel.scale = Vector2(0.85, 0.85)
	var etw: Tween = ui.toast_panel.create_tween()
	etw.tween_property(ui.toast_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(ui.toast_panel, "modulate:a", 0.0, 0.4)
	toast_tween.tween_callback(func() -> void:
		ui.toast_panel.visible = false
		if not _toast_queue.is_empty():
			var nt: String = _toast_queue.pop_front()
			ui.toast_panel.modulate.a = 0.0
			toast(nt))


func _lvl_banner(txt: String) -> void:
	if not ui.has("lvl_banner"):
		return
	var l: Label = ui.lvl_banner
	l.text = txt
	l.add_theme_font_size_override("font_size", 44 if txt.length() <= 16 else (32 if txt.length() <= 26 else 26))
	l.visible = true
	l.modulate.a = 1.0
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: l.visible = false)


# ---------------- quest berurutan ----------------

func _start_quests(boss_floor: bool, room_count: int) -> void:
	quest_counts = {}
	var n_elites := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.elite:
			n_elites += 1
	if rat_ration and player != null and is_instance_valid(player):
		player.hp = Stats.get_stat("max_hp")
		player.hp_changed.emit(player.hp)
		toast("RAT RATION — the mold did most of the eating")
	quest_steps = QDB.for_floor(Stats.floor_num, room_count, n_elites)
	_refresh_hud_weapon()
	for st in quest_steps:
		st["done"] = 0
	quest_idx = 0
	_quest_render()


func _quest_event(kind: String, num: int = 1) -> void:
	if kind == "thrall_kill":
		thrall_n += 1
		if thrall_n >= 15:
			_ach("liberator")
	# total per-kind dihitung apa pun langkah aktifnya — langkah berurutan
	# tidak boleh kehilangan progres yang terjadi sebelum gilirannya
	if kind == "trap_disarm":
		if Stats.relics.has("bilge_rat"):
			_spawn_wisp_at(player.global_position + Vector3(0.5 * info.tile, 0, 0))
		disarm_run += 1
		disarm_floor += 1
		if disarm_floor >= 4:
			_ach("wax_floor")
		if disarm_run >= 5:
			_ach("bombsquad")
		if Stats.relics.has("bone_tithe"):
			tithe_armor += 1.0
			Stats.buff_armor += 1
			if player != null and is_instance_valid(player):
				player.refresh_stats()
			toast("BONE TITHE — +1 Armor till the floor falls")
		Stats.traps_defused += num
		if Stats.traps_defused >= 5:
			_ach("trap5")
	if kind == "wisp":
		Stats.wisps_caught += num
		if Stats.relics.has("netminder") and Stats.wisps_caught % 5 == 0:
			Stats.earn_souls(1)
			_souls_l()
		if Stats.wisps_caught >= 8:
			_ach("wisp8")
		if Stats.wisps_caught >= 20:
			_ach("wisp20")
	if kind == "pinch":
		pinch_n += num
		if pinch_n >= 3:
			_ach("pinch3")
	if kind != "reach_room":
		quest_counts[kind] = int(quest_counts.get(kind, 0)) + num
	if quest_idx >= quest_steps.size():
		return
	var st: Dictionary = quest_steps[quest_idx]
	if String(st["kind"]) != kind:
		return
	if kind == "reach_room":
		# reach_room selesai saat pemain sampai ruangan ke-"need"
		if num < int(st["need"]):
			return
		st["done"] = int(st["need"])
	else:
		st["done"] = int(quest_counts[kind])
	if int(st["done"]) >= int(st["need"]):
		quest_idx += 1
		Sfx.play("quest")
	elif ui.has("quest_d"):
		var qf: Label = ui.quest_d
		qf.modulate = Color(1.0, 0.9, 0.45)
		var pftw := qf.create_tween()
		pftw.tween_property(qf, "modulate", Color(1, 1, 1, 0.72), 0.4)
		Stats.earn_souls(2)
		_souls_l()
		toast("QUEST STEP DONE — +2 souls")
		steps_done_run += 1
		var cap_n := int(Stats.meta.get("captain", 0))
		if cap_n > 0:
			Stats.earn_souls(cap_n)
			_souls_l()
		if steps_done_run >= 6:
			_ach("completionist")
		if steps_done_run >= 12:
			_ach("manifest")
		if player != null and is_instance_valid(player):
			_souls(player.global_position + Vector3(0, 0.8, 0), 4, Color(0.6, 0.85, 1.0))
		if ui.has("quest_box"):
			var qb: Control = ui.quest_box
			qb.pivot_offset = qb.size * 0.5
			var qtw := qb.create_tween()
			qtw.tween_property(qb, "scale", Vector2(1.1, 1.1), 0.09)
			qtw.tween_property(qb, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	# langkah baru bisa langsung selesai bila progresnya terjadi sebelum aktif
	while quest_idx < quest_steps.size():
		var nxt: Dictionary = quest_steps[quest_idx]
		var nk := String(nxt["kind"])
		if nk == "reach_room":
			break
		var cd := int(quest_counts.get(nk, 0))
		nxt["done"] = cd
		if cd < int(nxt["need"]):
			break
		quest_idx += 1
		Sfx.play("quest")
	_quest_render()


func _quest_render() -> void:
	if not ui.has("quest_l"):
		return
	if quest_idx >= quest_steps.size():
		ui.quest_box.visible = false
		return
	var st: Dictionary = quest_steps[quest_idx]
	ui.quest_box.visible = true
	ui.quest_l.text = "◆ %d/%d %s" % [quest_idx + 1, quest_steps.size(), String(st["title"])]
	var desc := String(st["desc"])
	if int(st["need"]) > 1:
		desc += "  (%d/%d)" % [int(st["done"]), int(st["need"])]
	ui.quest_d.text = desc
	if not _quest_refresh_once:
		_quest_refresh_once = true
		return
	ui.quest_box.pivot_offset = ui.quest_box.size * 0.5
	ui.quest_box.scale = Vector2(1.06, 1.06)
	var qtw: Tween = ui.quest_box.create_tween()
	qtw.tween_property(ui.quest_box, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------- kombo kill ----------------

func _combo_set(n: int) -> void:
	combo = n
	combo_max = maxi(combo_max, n)
	combo_t = 4.0 * (1.45 if Stats.relics.has("relik_tempo") else 1.0) * (1.0 + combo_rate_bonus)
	# tier buff nyata: streak tinggi = tambah kuat (hilang saat streak putus)
	if combo == 8:
		_quest_event("combo")
	if combo == 40:
		_quest_event("combo40")
	if combo >= 50:
		_ach("unstoppable")
	if combo >= 40:
		Stats.combo_atk = 0.4
		Stats.combo_aspd = 0.35
	elif combo >= 25:
		Stats.combo_atk = 0.3
		Stats.combo_aspd = 0.25
	elif combo >= 15:
		Stats.combo_atk = 0.2
		Stats.combo_aspd = 0.15
	elif combo >= 8:
		Stats.combo_atk = 0.1
		Stats.combo_aspd = 0.0
	else:
		Stats.combo_atk = 0.0
		Stats.combo_aspd = 0.0
	if not ui.has("combo_l"):
		return
	if combo >= 3:
		ui.combo_l.visible = true
		ui.combo_l.text = "COMBO ×%d" % combo
		if combo >= 40:
			ui.combo_l.modulate = Color(1.0, 0.3, 0.6)
		elif combo >= 25:
			ui.combo_l.modulate = Color(1.0, 0.4, 0.2)
		elif combo >= 15:
			ui.combo_l.modulate = Color(1.0, 0.55, 0.1)
		elif combo >= 8:
			ui.combo_l.modulate = Color(1.0, 0.65, 0.15)
		else:
			ui.combo_l.modulate = Color(1.0, 0.7, 0.25)
		ui.combo_l.pivot_offset = ui.combo_l.size * 0.5
		ui.combo_l.scale = Vector2(1.35, 1.35)
		var tw := create_tween()
		tw.tween_property(ui.combo_l, "scale", Vector2.ONE, 0.18)
		if combo >= 5:
			Sfx.play("combo")
		if combo == 8:
			_lvl_banner("RAMPAGE! +10% ATK")
		elif combo == 15:
			_lvl_banner("MASSACRE! +20% ATK +15% HASTE")
		elif combo == 25:
			_lvl_banner("UNSTOPPABLE! +30% ATK +25% HASTE")
		elif combo == 40:
			_lvl_banner("★ GODLIKE! +40% ATK +35% HASTE")
			if player != null and is_instance_valid(player):
				player.hp = minf(player.max_hp, player.hp + 1.0)
				player.hp_changed.emit(player.hp)
				_damage_number(player.global_position + Vector3(0, 1.1 * info.tile, 0), "+1 HP", Color(0.4, 1.0, 0.55), true)
	else:
		if ui.combo_l.visible and ui.combo_l.modulate.a > 0.5:
			var dtw: Tween = ui.combo_l.create_tween()
			dtw.tween_property(ui.combo_l, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			dtw.tween_callback(func() -> void:
				ui.combo_l.visible = false
				ui.combo_l.modulate.a = 1.0)
		else:
			ui.combo_l.visible = false
		if ui.has("combo_bar"):
			ui.combo_bar.visible = false


# ---------------- bar HP boss ----------------

func _boss_bar_show() -> void:
	ui.boss_bar.visible = true
	ui.boss_bar.modulate.a = 0.0
	ui.boss_bar.pivot_offset = ui.boss_bar.size * 0.5
	ui.boss_bar.scale = Vector2(1.25, 1.25)
	var bbtw: Tween = ui.boss_bar.create_tween()
	bbtw.set_parallel(true)
	bbtw.tween_property(ui.boss_bar, "modulate:a", 1.0, 0.35)
	bbtw.tween_property(ui.boss_bar, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# warnai bar per varian Raja: ember/frost/feral/undying
	var tc: Color = Color(_boss_tier().get("tint", Color(1.0, 0.3, 0.25)))
	var sb: StyleBox = ui.boss_bar.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		sb.border_color = tc
	ui.boss_name.modulate = tc.lightened(0.3)


func _boss_bar_hide() -> void:
	if ui.has("boss_bar"):
		ui.boss_bar.visible = false


# ---------------- dialog + altar ----------------

func _say(lines: Array, choices: Array = []) -> void:
	if dlg == null or lines.is_empty() or dlg.active:
		return
	Stats.draft_open = true
	get_tree().paused = true
	ui.dim.visible = true
	if choices.is_empty():
		dlg.play(lines)
	else:
		dlg.play_choices(lines, choices)
	if autotest:
		# bukti visual: dialog benar-benar tergambar sebelum dilewati
		for _w in range(3):
			await get_tree().process_frame
		_shot("res://out_v5_dlg.png")
		# autotest: lewati semua dialog otomatis supaya alur tak pernah diam
		for _i in range(80):
			if not dlg.active or dlg._choice_box.visible:
				break
			dlg._advance()
			await get_tree().process_frame
		if dlg.active and dlg._choice_box.visible:
			dlg.choose(0)
			await get_tree().process_frame


func _on_dlg_end() -> void:
	get_tree().paused = false
	Stats.draft_open = false
	if run_state == "playing":
		ui.dim.visible = false
	_try_open_draft()
	# OMEN: pact run pertama — ditawar Oracle begitu dialog intro lantai 1 selesai
	if run_state == "playing" and Stats.floor_num == 1 and not omen_done:
		omen_done = true
		_offer_omens()
	elif run_state == "playing" and Stats.floor_num == 11 and not omen_done2:
		omen_done2 = true
		_offer_omens()


func _on_dlg_choice(idx: int) -> void:
	if dlg_pending_choice == 1:
		dlg_pending_choice = -1
		_mahzan_deal(idx)
		return
	elif dlg_pending_choice == 2:
		dlg_pending_choice = -1
		_curse_deal(idx)
		return
	elif dlg_pending_choice == 3:
		dlg_pending_choice = -1
		_defiance_deal(idx)
		return
	elif dlg_pending_choice == 4:
		dlg_pending_choice = -1
		_oracle_deal(idx)
		return
	elif dlg_pending_choice == 5:
		dlg_pending_choice = -1
		_omen_deal(idx)
		return
	elif dlg_pending_choice == 6:
		dlg_pending_choice = -1
		_forge_deal(idx)
		return
	elif dlg_pending_choice == 7:
		dlg_pending_choice = -1
		_mirror_deal(idx)
		return
	elif dlg_pending_choice == 8:
		dlg_pending_choice = -1
		_bounty_deal(idx)
		return
	elif dlg_pending_choice == 9:
		dlg_pending_choice = -1
		_vault_deal(idx)
		return
	elif dlg_pending_choice == 10:
		dlg_pending_choice = -1
		_ferry_deal(idx)
		return
	elif dlg_pending_choice == 11:
		dlg_pending_choice = -1
		_well_deal(idx)
		return
	elif dlg_pending_choice == 12:
		dlg_pending_choice = -1
		_cache_deal(idx)
		return
	elif dlg_pending_choice == 13:
		dlg_pending_choice = -1
		_fountain_deal(idx)
		return
	elif dlg_pending_choice == 14:
		dlg_pending_choice = -1
		_drowned_deal(idx)
		return
	elif dlg_pending_choice == 16:
		_throne_deal(idx)
	elif dlg_pending_choice == 17:
		dlg_pending_choice = -1
		_qm_deal(idx)
		return
	elif dlg_pending_choice == 15:
		dlg_pending_choice = -1
		_keel_deal(idx)
		return
	elif dlg_pending_choice == 18:
		dlg_pending_choice = -1
		_siren_deal(idx)
		return
	match idx:
		0:
			Stats.buff_atk_pct += 0.15
			toast("War Blessing: +15% ATK")
		1:
			Stats.buff_armor += 1
			toast("Iron Blessing: +1 Armor")
		2:
			if player != null and is_instance_valid(player):
				player.heal_to_full()
			toast("Blood Blessing: HP fully restored")
		3:
			Stats.earn_souls(12)
			Stats.save_game()
			_souls_l()
			toast("Soul Blessing: +12 souls")
		4:
			Stats.buff_speed_pct += 0.12
			toast("Gale Blessing: +12% Speed")
		5:
			Stats.buff_lifesteal += 0.08
			toast("Vampiric Blessing: +8% Lifesteal")
		6:
			Stats.buff_aspd += 0.10
			toast("Fury Blessing: +10% Attack Speed")
		7:
			Stats.buff_maxhp_pct += 0.2
			toast("Titan's Blessing: +20% Max HP")
		8:
			Stats.buff_crit += 0.12
			toast("Eagle's Eye: +12% Crit")
		9:
			Stats.cd_reduction += 0.2
			toast("Tempest Blessing: +20% Skill Recharge")
		10:
			Stats.soul_bonus += 1
			toast("Grave Tithe: +1 soul per kill")
		11:
			combo_rate_bonus = 0.4
			toast("Tempo's Grace: combos linger 40% longer")
		12:
			trap_wrapped += 1
			toast("Bone Wrap: first trap hit is nothing")
		13:
			lucky_net = true
			_quest_event("lucky_net")
			toast("Lucky Net: every tenth soul snags a bonus")
		14:
			deeproot = true
			toast("Deeproot: urns spill +1 soul")
		15:
			still_waters = true
			toast("Still Waters: traps doze 40% longer")
		16:
			bone_veil = true
			toast("Bone Veil: the first hit each floor is nothing")
		17:
			Stats.soul_gain_pct += 0.2
			toast("Tide's Toll: every soul pays a fifth more")
		18:
			moonwrit = true
			toast("Moonwrit: the wisps pay you an extra soul")
		19:
			barnacle_sense = true
			toast("Barnacle Sense: disarm reach half again as far")
		20:
			brine_callus = true
			toast("Brine Callus: +2 Armor while under half health")
		21:
			deadweight = true
			toast("Deadweight: your heavy hits slow foes")
		22:
			undertow_grip = true
			toast("Undertow Grip: your pulls reach half again as far")
		23:
			lookout = true
			toast("Lookout: spotting a new foe kind pays +1 soul")
		24:
			Stats.buff_armor += 1
			Stats.buff_speed_pct -= 0.05
			toast("Ironwood Hull: +1 Armor, but the keel drags (−5% speed)")
		25:
			bosun_mark = true
			if squire_ref != null and is_instance_valid(squire_ref):
				squire_ref.dmg *= 1.2
			toast("Bosun's Mark: your crew swings a fifth harder")
		26:
			Stats.buff_xp_pct += 0.15
			toast("Wake Runner: the deep fills your lungs — +15% XP")
		27:
			bosun_ledger = true
			toast("Bosun's Ledger: every fifth kill each floor pays +1 soul")
		28:
			Stats.cd_reduction += 0.08
			toast("Quarterdeck: a firm deck under your skills — +8% recharge")
		29:
			Stats.buff_crit += 0.08
			toast("Crow's Nest: a sharper eye for soft spots — +8% crit this run")
		30:
			urnsworn = true
			toast("Urnsworn: the pots know you — every urn spills +1 soul")
		31:
			iron_gullet = true
			toast("Iron Gullet: the vials go down easier — they mend half your HP")
		32:
			Stats.soul_gain_pct += 0.1
			toast("Spirit Share: the dead leave a tithe for you — +10% souls")
		33:
			Stats.buff_xp_pct += 0.1
			toast("Deep Water: the dead teach — +10% XP this run")
		34:
			crew_oath = true
			toast("Crew's Oath: your squire fights like a boatswain — +50% bite")
		35:
			Stats.buff_lifesteal += 0.08
			toast("Leech Line: the dead bleed for you — +8% lifesteal this run")
		36:
			Stats.buff_crit += 0.05
			Stats.buff_xp_pct += 0.05
			toast("Sea Wisdom: old heads strike true — +5% crit and +5% XP")
		37:
			bloodwarm = true
			toast("Bloodwarm: the red orbs burn — they mend double")
		38:
			Stats.buff_armor += 2
			toast("Deck Bones: the old planking holds — +2 Armor this run")
		39:
			salt_shear = true
			toast("Salt Shear: the slowed bleed deeper — +25% damage this run")
		40:
			Stats.soul_gain_pct += 0.05
			toast("Crow's Tithe: the small gods take less — +5% souls this run")
		41:
			Stats.buff_speed_pct += 0.08
			toast("Trade Wind: the floor itself hurries you on — +8% speed this run")
		42:
			wide_satchel = true
			toast("Wide Satchel: the satchel stretches — carry +1 soul vial this run")
		43:
			Stats.buff_armor += 1
			Stats.buff_maxhp_pct += 0.05
			toast("Salt Hide: the brine cures your skin — +1 Armor, +5% Max HP this run")
		44:
			Stats.buff_aspd += 0.12
			Stats.buff_speed_pct += 0.08
			toast("Storm-eye: the gale moves through you — +12% attack speed, +8% speed this run")
		45:
			Stats.buff_maxhp_pct += 0.1
			Stats.buff_speed_pct -= 0.05
			toast("Waxen Hull: caulked thick against the deep — +10% Max HP, −5% speed this run")
		46:
			Stats.buff_crit += 0.08
			Stats.buff_lifesteal += 0.03
			toast("Leech's Tithe: the old blood answers — +8% crit, +3% lifesteal this run")
		47:
			Stats.buff_armor += 1
			Stats.buff_speed_pct += 0.1
			toast("Iron Prow: the prow cuts and the bow splits — +1 Armor, +10% speed this run")
		48:
			Stats.buff_crit += 0.1
			Stats.buff_armor += 1
			toast("Sharp Hull: barnacle blades in the prow — +10% crit, +1 Armor this run")
		51:
			Stats.buff_xp_pct += 0.15
			toast("Fathom Eye: the deep teaches what the dark won't — +15% XP this run")
		52:
			Stats.buff_armor += 1
			Stats.buff_aspd -= 0.05
			toast("Bulkhead: iron plates bolt to your ribs — +1 Armor, −5% attack speed this run")
		53:
			Stats.cd_reduction += 0.1
			toast("Overhang: the rigging hums — skills recharge +10% sooner this run")
		54:
			Stats.buff_speed_pct += 0.08
			Stats.buff_aspd += 0.05
			toast("Deckmaster: you own this deck — +8% speed, +5% attack speed this run")
		55:
			Stats.buff_maxhp_pct += 0.2
			toast("Full Hull: every plank sealed — +20% Max HP this run")
		56:
			Stats.buff_crit += 0.05
			toast("Bosun's Fist: the old knuckle-trick — +5% crit this run")
		57:
			Stats.soul_gain_pct += 0.15
			toast("Salt Lamp: souls shine brighter in the dark — +15% souls this run")
		58:
			crows_toll = true
			toast("Crow's Toll: the titled dead pay richer lessons — elites yield +50% XP this run")
		59:
			pilgrims_purse = true
			toast("Pilgrim's Purse: +2 souls at each floor's start")
		60:
			Stats.buff_armor += 1
			Stats.buff_atk_pct += 0.08
			toast("Powder Ballast: shot and powder in the pockets — +1 Armor, +8% ATK this run")
		61:
			Stats.dodge += 0.08
			toast("Slick Wake: you slide through the swell — +8% dodge this run")
		62:
			Stats.buff_armor += 2
			Stats.buff_speed_pct -= 0.1
			toast("Salt Crust: barnacled ribs — +2 Armor, −10% speed this run")
		63:
			omen_cd_add -= 1.0
			Stats.buff_maxhp_pct -= 0.1
			toast("Shanty Lung: your skills come a breath quicker — but your hull sits lighter")
		64:
			Stats.soul_gain_pct += 0.25
			Stats.buff_xp_pct -= 0.1
			toast("Bilge Ledger: every kill pays a quarter more souls — but the dead teach less")
		65:
			Stats.buff_crit += 0.12
			Stats.dodge -= 0.05
			toast("Crow's Gambit: +12% crit — but you weave a touch slower")
		66:
			Stats.buff_lifesteal += 0.08
			toast("Salt Veins: the brine runs in you — +8% lifesteal this run")
		67:
			Stats.buff_xp_pct += 0.15
			Stats.buff_speed_pct -= 0.05
			toast("Dead Wake: the deep teaches every stroke — +15% XP, −5% speed")
		68:
			Stats.dodge += 0.05
			Stats.buff_speed_pct += 0.05
			toast("Spare Oar: lean into the lean water — +5% dodge, +5% speed")
		69:
			Stats.buff_speed_pct += 0.1
			Stats.buff_xp_pct += 0.1
			toast("Wake Prayer: the water reads your steps — +10% speed, +10% XP")
		70:
			Stats.cd_reduction += 0.08
			toast("Fathom Rope: the cord runs smooth — skills recharge 8% faster")
		71:
			Stats.dodge += 0.05
			Stats.buff_xp_pct += 0.05
			toast("Gullwing: light bones over dark water — +5% dodge, +5% XP")
		72:
			Stats.soul_gain_pct += 0.12
			Stats.dodge -= 0.05
			toast("Salt Tow: the purse drags — +12% souls, −5% dodge")
		73:
			Stats.buff_crit += 0.06
			Stats.buff_atk_pct += 0.06
			toast("Deadlights: lamps over drowned water — +6% crit, +6% ATK")
		74:
			Stats.dodge += 0.1
			Stats.buff_atk_pct -= 0.05
			toast("Coil Keeper: you keep the rope's give in your step — +10% dodge, −5% ATK")
		75:
			Stats.buff_armor += 1
			Stats.buff_speed_pct -= 0.05
			toast("Bilge Boarding: nailed planks over your ribs — +1 Armor, −5% speed")
		76:
			Stats.buff_armor += 1
			Stats.soul_gain_pct += 0.05
			toast("Foam Crown: a crest the sea lent you — +1 Armor, +5% souls")
		77:
			Stats.soul_gain_pct += 0.2
			Stats.buff_maxhp_pct -= 0.1
			toast("Brine Dividend: the purse swells, the pulse thins — +20% souls, −10% Max HP")
		78:
			Stats.buff_aspd += 0.15
			Stats.buff_crit -= 0.05
			toast("Rope Burn: raw palms, fast hands — +15% attack speed, −5% crit")
		79:
			Stats.buff_speed_pct += 0.1
			Stats.dodge += 0.1
			Stats.soul_gain_pct -= 0.1
			toast("Hanging Tide: you move like slack water — +10% speed, +10% dodge, −10% souls")
		80:
			Stats.buff_aspd += 0.15
			Stats.buff_speed_pct -= 0.08
			toast("Capstan Chant: the heavy verses set your arms turning — +15% attack speed, −8% speed")
		81:
			Stats.buff_speed_pct += 0.12
			Stats.dodge -= 0.05
			toast("Rope Soles: tar-and-twine underfoot — +12% speed, −5% dodge")
		82:
			Stats.soul_gain_pct += 0.2
			Stats.dodge -= 0.1
			toast("Salt Scribe: every death tallied in your favor — +20% souls, −10% dodge")
		83:
			Stats.buff_aspd += 0.15
			Stats.buff_crit -= 0.08
			toast("Kedge Whistle: the boatswain's tempo — +15% attack speed, −8% crit")
		84:
			Stats.buff_armor += 2
			Stats.buff_speed_pct -= 0.1
			toast("Keel Ballast: stone in the hold — +2 Armor, −10% speed")
		85:
			Stats.soul_gain_pct += 0.15
			Stats.cd_reduction -= 0.05
			toast("Salt Tithing: the purse fills, the hands slow — +15% souls, skills +5% recharge")
		86:
			Stats.buff_maxhp_pct += 0.15
			Stats.dodge -= 0.1
			toast("Hull Tithe: ironwood ribs for a price — +15% Max HP, −10% dodge")
		87:
			Stats.dodge += 0.08
			Stats.buff_speed_pct -= 0.05
			toast("Keel Net: you slip like a fish through the net — +8% dodge, −5% speed")
		88:
			Stats.buff_xp_pct += 0.1
			Stats.soul_gain_pct -= 0.05
			toast("Galley Spice: the pot's seasoning clings to you — +10% XP, −5% souls")
		89:
			Stats.dodge += 0.06
			Stats.buff_aspd += 0.06
			Stats.soul_gain_pct -= 0.05
			toast("Slip Knot: you slide through the rope's bite — +6% dodge, +6% haste, −5% souls")
		90:
			Stats.soul_gain_pct += 0.1
			Stats.buff_xp_pct -= 0.05
			toast("Bosun's Purse: the whistle pays out — +10% souls, −5% XP")
		91:
			Stats.buff_crit += 0.1
			Stats.soul_gain_pct -= 0.05
			toast("Deckman's Eye: the perch lends its sight — +10% crit, −5% souls")
		92:
			Stats.buff_speed_pct += 0.08
			Stats.dodge += 0.04
			toast("Mizzen Step: the aft wind at your heels — +8% speed, +4% dodge")
		93:
			Stats.buff_xp_pct += 0.1
			Stats.soul_gain_pct -= 0.05
			toast("Bilge Wake: the hull's lessons wash over you — +10% XP, −5% souls")
		94:
			Stats.dodge += 0.06
			Stats.buff_speed_pct += 0.04
			toast("Galley Nets: the trawl's slack is yours — +6% dodge, +4% speed")
		95:
			Stats.buff_lifesteal += 0.05
			Stats.buff_maxhp_pct -= 0.05
			toast("Leech Bond: the eels lend their hunger — +5% lifesteal, −5% Max HP")
		96:
			Stats.buff_armor += 1
			Stats.buff_atk_pct += 0.04
			toast("Tar Grip: your palms stick to the haft — +1 Armor, +4% ATK")
		97:
			Stats.buff_speed_pct += 0.08
			toast("Foam Step: the deck barely touches your heels — +8% speed")
		98:
			Stats.soul_gain_pct += 0.10
			toast("Salt Pension: the drowned pay their arrears — +10% souls")
		99:
			Stats.buff_xp_pct += 0.12
			toast("Keel Hymn: the hull sings your lessons back — +12% XP")
		100:
			Stats.buff_crit += 0.08
			toast("Rigger's Eye: you see the seams in every knot — +8% crit")
		101:
			Stats.soul_gain_pct += 0.08
			Stats.buff_xp_pct += 0.06
			toast("Bilge Sense: you learn what sinks and what floats — +8% souls, +6% XP")
		102:
			Stats.buff_armor += 1
			Stats.buff_xp_pct += 0.05
			toast("Hull Wisdom: you read the planks under your feet — +1 Armor, +5% XP")
		103:
			Stats.soul_gain_pct += 0.08
			Stats.dodge += 0.04
			toast("Deck Psalm: the verse fills your purse — +8% souls, +4% dodge")
		104:
			Stats.buff_atk_pct += 0.08
			Stats.buff_armor -= 1
			toast("Iron Verse: the hymn sharpens your hand — +8% ATK, −1 Armor")
		50:
			Stats.buff_aspd += 0.15
			Stats.buff_speed_pct -= 0.05
			toast("Gunnel Grip: white-knuckled on the rail — +15% attack speed, −5% speed this run")
		49:
			whale_lung = true
			toast("Whale Lung: a deeper breath than any sailor's — dash recharges 25% faster this run")
	blessings_run += 1
	if blessings_run >= 5:
		_ach("bless5")
	if blessings_run >= 8:
		_ach("choral")
	if blessings_run >= 12:
		_ach("votive")
	if player != null and is_instance_valid(player):
		player.refresh_stats()
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.4))


func _offer_omens() -> void:
	dlg_pending_choice = 5
	var oline := "Before you bleed for him, choose the omen you carry — every path has a price."
	if Stats.floor_num >= 11:
		oline = "Halfway to his throne, Kael. The deeps offer a second pact — stack it on your first, or refuse."
	_say(
		[{"who": "oracle", "text": oline}],
		[
			{"text": "WARPATH — +30% ATK, -1 Armor"},
			{"text": "FEATHER STEP — +15% Speed, -25% ATK"},
			{"text": "RICH SOIL — +35% XP, foes +10% HP"},
			{"text": "LEECHING VEIN — +15% Lifesteal, -30% Max HP"},
			{"text": "ECLIPSE — return from death once, -15% ATK"},
			{"text": "IRONSIDE — +2 Armor, -15% Speed"},
			{"text": "STORMGLASS — +20% Skill Recharge, -15% Max HP"},
			{"text": "OATH OF SILENCE — +30% ATK, skills recharge 35% slower"},
			{"text": "FATEHAND — drafts show a 4th relic, -1 Armor"},
			{"text": "SOLITARY — +35% XP, allies will not answer this run"},
			{"text": "PAWNBREAKER — all soul prices drop 1, -15% Max HP"},
			{"text": "HEIRLOOM — carry a random trinket into the run, -1 Armor"},
			{"text": "GOLDEN FATE — every chest is gilded, -2 Max HP"},
			{"text": "LEGION — the halls swarm with an extra foe in every room; +15% XP"},
			{"text": "LASTBORN — start the run wounded (-35% Max HP) but carry two extra soul vials"},
			{"text": "HEAVYHAND — +20% ATK, but swings come 20% slower"},
			{"text": "WOLF OF THE HALLS — each kill quickens you +1% (up to +20%)"},
			{"text": "ASHBORN — the ash rain follows you; every floor 10+ is ashfall, -10% Max HP"},
			{"text": "LONE CROWN — +20% ATK on boss floors, -5% ATK on all others"},
			{"text": "REAPER'S TITHE — +1 soul per kill, but every 10th kill pays nothing"},
			{"text": "DEATHWISH — +40% ATK, but every blow you take hits 30% harder"},
			{"text": "BARGAINER — your first Mahzan deal this run comes with 6 free souls"},
			{"text": "HOLLOW CROWN — +40% ATK, but every relic melts into +3 souls"},
			{"text": "SPITEFUL — each of your kills wounds a nearby foe for 1 HP"},
			{"text": "KAEL'S WAGER — every soul is doubled... but you live on a single drop of blood"},
			{"text": "GRAVETIDE — +2 souls at every floor's end, but the dead grow +10% tougher"},
			{"text": "MARROW PACT — fortify: +2 armor... but your blood thins (−20% Max HP)"},
			{"text": "WELLREAD — every lore stone also pays 1 soul... but the Oracle's voice grows faint"},
			{"text": "THE TIDE LENDS — every gilded chest pays +3 souls... but the King's notice hardens the dead (+8% HP)"},
			{"text": "PEARL FEVER — every urn spills +1 soul... but the salt eats your armor (−1 Armor)"},
			{"text": "MUCKRAKER — defusing traps pays +1 soul... but the floors breed +2 more traps"},
			{"text": "ABYSSAL PATIENCE — every chest pays +4 souls... but urns run dry"},
			{"text": "UMBRAL TIDE — your dash recharges 40% faster... but the dead swim 20% quicker"},
			{"text": "BONE MARKET — chests pay double souls... but every lid bites 5% of your Max HP"},
			{"text": "WAXPALE — the wisps pay double... but the dead grow 10% harder"},
			{"text": "VESSEL — the urns pay double... but the dead grow 10% harder"},
			{"text": "SKELETON CREW — one fewer foe in every room... but the survivors are twice as likely to be elite"},
			{"text": "ROLLING FOG — the dead rise dazed for 3 heartbeats... but +8% hardier"},
			{"text": "DEEP POCKETS — every bargain costs a fifth less... but the dead grow +12% harder"},
			{"text": "OARSWORN — your skills recharge a quarter faster... but the dead grow +10% harder"},
			{"text": "DARK WATER — every floor's end tithes +1 soul... but the dead grow +10% harder"},
			{"text": "FATHOMLESS — +30% XP... but the dead grow +15% harder"},
			{"text": "FULL CHART — every floor lies fully charted... but the dead grow +10% harder"},
			{"text": "WET POWDER — your strikes hit +15% harder... but the skills recharge 20% slower"},
			{"text": "LONG WAKE — the dead scent you from further... but +20% XP"},
			{"text": "SALT FEVER — every soul pays +25%... but the dead grow +10% harder"},
			{"text": "DEAD LANTERN — elites burn +15% brighter... but the urns pay +1 soul"},
			{"text": "HULL SONG — skills recharge +15% faster... but the dead row +5% quicker"},
			{"text": "SALT LEDGER — every price climbs +1 soul... but each floor's end pays +3"},
			{"text": "DEEP TOLL — the dead endure +15% longer... but every lesson pays +30% XP"},
			{"text": "SLOW CLOCK — your skills recharge a fifth slower... but the dead wade −8% slower too"},
			{"text": "DECK ALMS — every price drops −1 soul... but the dead run +10% quicker"},
			{"text": "LOOSE BALLAST — you take +15% damage... but the dead wade −10% slower"},
			{"text": "BLACK SAILS — the dead come +15% faster... but every soul pays +20% more"},
			{"text": "GRIM CHARTER — elites stalk you +10% more often... but each pays +50% XP"},
			{"text": "MARTYR'S OATH — you take +10% damage... but every kill mends 1% HP"},
			{"text": "SLIM PICKINGS — your skills recharge +10% slower... but souls pay +25% more"},
			{"text": "SWORN HULL — the dead hunt +10% faster... but +1 Armor wraps your bones"},
			{"text": "OLD SALT — souls pay −20% less... but your arm swings +10% harder"},
			{"text": "FULL SAILS — the dead fly +15% faster... but souls pay +30% more"},
			{"text": "LONG OARS — you row −10% slower... but the dead row −20% slower"},
			{"text": "DEEP DRAFT — your hull sits −15% lower... but souls pay +25% more"},
			{"text": "HIGH WATER — the dead stand +10% taller and hit +10%... but every lesson pays +30% XP"},
			{"text": "BALLAST OATH — iron in your boots (−10% speed)... but stone in your ribs (+2 Armor)"},
			{"text": "THIN HULL — your planks run one plank short (−1 Armor)... but your edge sings (+15% ATK)"},
			{"text": "COLD TOLL — the sea takes its warmth (−5% speed)... but the cold teaches (＋10% XP)"},
			{"text": "OARLOCKS — iron rowlocks bite your hands (skills charge +1s)... but your ribs are stout (+1 Armor)"},
			{"text": "CANDLE TAX — every seller trims a soul off the price (all deals −1 soul)... but your kills pay −20% souls"},
			{"text": "PILOT DEAD — the dead scent you a mile off (aggro +20%)... but their souls pay +15%"},
		{"text": "FATHOM TAX — the dead stand +15% taller... but every soul pays +20% more"},
		{"text": "HULL ROT — your planks go soft (−1 Armor)... but the rot teaches (+20% XP)"},
		{"text": "STILL WATER — the dead swing +15% slower to aim... but land +15% harder"},
		{"text": "GOLD HULL — gilded planks (−1 Armor)... but every soul pays +15%"},
		{"text": "SALT RATION — rations cut thin (−10% skill cooldowns)... the crew fights leaner (+10% foe vigor)"},
		{"text": "HARD TACK — chew iron bread (+15% XP)... the dead hit like it too (+15% dmg)"},
		{"text": "LEADEN PURSE — coin weighs your belt (−15% souls)... and their boots (−10% foe speed)"},
		{"text": "WIDOW'S LEDGER — her purse pays +15% souls... the dead pay +8% vigor"},
		{"text": "FLOTSAM KIN — the wreck-schools quicken +8%... their drift teaches +15% XP"},
		{"text": "SCURVY — gums bleed, ribs show (−10% Max HP)... but starvation teaches (+15% XP)"},
		{"text": "DRAFT HOLE — the current pulls at your hands (skills −15% charge)... and theirs too (+10% foe speed)"},
		{"text": "KEEL HAULED — barnacles plate your hull (+1 Armor)... but drag (−8% speed)"},
		{"text": "BILGE SWORN — the bilge slows them all (−8% foe speed)... but the purse pays (−10% souls)"},
		{"text": "SALT FORFEIT — pay your vigor up front (−10% Max HP)... and the dead pay interest (+15% XP)"},
		{"text": "DEAD RECKONER — the chart draws them nearer (+20% foe aggro)... but the purse knows (+15% souls)"},
		{"text": "PALE DOCK — the berths run dry (orbs mend −30%)... but the toll pays (+15% souls)"},
		{"text": "FATHOM PACT — the deep steadies your footing (+10% dodge)... but its pupils strike +12% harder"},
		{"text": "BOSUN'S DEBT — the whistle calls, your hands answer slow (+10% skill recharge)... but the crew learns (+15% XP)"},
		{"text": "CREW'S SHARE — every pocket pays the purser (+15% souls)... but the lessons thin (−8% XP)"},
		{"text": "PALM TAR — tarred palms never let go (+8% lifesteal)... but your boots drag (−10% speed)"},
		{"text": "OAR TAX — the oars lend you their pull (+12% speed)... but the hull pays thin (−1 Armor)"},
		{"text": "RUST BOUNTY — the wreck sharpens your edge (+15% crit)... but it eats your plate (−10% Max HP)"},
		{"text": "DEEP CHARTER — the black water teaches fast (+20% XP)... but skims your purse (−10% souls)"},
		{"text": "SALTY WAGES — the ship pays out in souls (+15% souls)... but the lessons run thin (−10% XP)"},
		{"text": "GUNNEL TIDE — the rail sings your arm faster (+10% attack speed)... but the hull runs thin (−1 Armor)"},
		{"text": "DEAD MAN'S WAGES — the crew's unspent pay hardens your hand (+15% ATK)... but the purse leaks (−10% souls)"},
		{"text": "RIGGER'S DUE — the rigging pays its keeper in souls (+10% souls)... but the ropes bite (−1 Armor)"},
		{"text": "TIDE'S FAVOR — the current carries your lessons (+10% XP)... but the hull runs thin (−1 Armor)"},
		{"text": "BARNACLE OATH — the hull pays its clingy tenants (+8% souls)... but they weigh your stride (−6% speed)"},
		{"text": "BLACK TIDE — the dark water lends your arm its pull (+12% attack speed)... but it pulls at your seams (−8% Max HP)"},
		{"text": "GRAVE KNOT — the knot holds what the sea could not (+8% ATK)... but it binds your step (−6% dodge)"},
		{"text": "SALT TITHE — the purse rings louder (+10% souls)... but the lessons run short (−5% XP)"},
		{"text": "KEELSWORN — iron in your seams (+2 Armor)... but the swing drags (−10% attack speed)"},
		{"text": "FOG RUNNER — the haze lends your stride (+12% speed)... but the purse runs thin (−10% souls)"},
		] + ([{"text": "BLOOD DEBT — your nemesis +25% HP; its skull pays an epic relic"}] if Stats.nemesis != "" else []) + [{"text": "Walk alone — swear nothing"}]
	)


func _soul_cost(n: int) -> int:
	var disc := 0
	if pawn_discount:
		disc += 1
	if candle_tax:
		disc += 1
	if mahzan_met >= 4:
		disc += 1
	if deep_pockets_oath:
		return maxi(1, int(ceilf(float(n) * 0.8)))
	if Stats.relics.has("pact_broker"):
		disc += 1
	disc += int(Stats.meta.get("haggler", 0))
	if Stats.relics.has("rusted_penny") and not penny_floor:
		disc += 1
		penny_floor = true
	if salt_ledger:
		disc -= 1
	if deck_alms:
		disc += 1
	var nn := n - disc
	if merchant_tide:
		nn = int(ceilf(float(nn) * 0.8))
	if greedy_tide:
		nn = int(ceilf(float(nn) * 0.8))
	return maxi(1, nn)


func _forge_cost(n: int) -> int:
	var disc := 0
	if pawn_discount:
		disc += 1
	if Stats.relics.has("soulsmith"):
		disc += 2
	disc += int(Stats.meta.get("foundry", 0))
	return maxi(1, n - disc)


func _pdodged() -> void:
	perfect_dodges += 1
	_quest_event("pdodge")
	_quest_event("pdodge_run")
	if perfect_dodges == 5:
		_ach("shadowstep")
	if perfect_dodges == 3:
		_ach("untouchable")
		_lvl_banner("◈ UNTOUCHABLE — three perfect dodges")


func _omen_deal(idx: int) -> void:
	var osize := 104 if Stats.nemesis != "" else 103
	if idx >= osize:
		omen_refusals += 1
		if omen_refusals >= 2:
			toast("Twice refused. The old woman says nothing — that's rare.")
		else:
			toast("You walk alone — the Oracle nods")
		return
	var oname := ""
	match idx:
		0:
			Stats.buff_atk_pct += 0.3
			Stats.buff_armor -= 1
			oname = "WARPATH"
		1:
			Stats.buff_speed_pct += 0.15
			Stats.buff_atk_pct -= 0.25
			oname = "FEATHER"
		2:
			Stats.buff_xp_pct += 0.35
			omen_hp_mult = 1.1
			oname = "RICH SOIL"
		3:
			Stats.buff_lifesteal += 0.15
			Stats.buff_maxhp_pct -= 0.3
			oname = "LEECHING"
		4:
			Stats.revive_left += 1
			Stats.buff_atk_pct -= 0.15
			oname = "ECLIPSE"
		5:
			Stats.buff_armor += 2
			Stats.buff_speed_pct -= 0.15
			oname = "IRONSIDE"
		6:
			Stats.cd_reduction += 0.2
			Stats.buff_maxhp_pct -= 0.15
			oname = "STORMGLASS"
		7:
			Stats.cd_reduction -= 0.35
			Stats.buff_atk_pct += 0.3
			oname = "SILENCE"
		8:
			fatehand = true
			Stats.buff_armor -= 1
			oname = "FATEHAND"
		9:
			solitary = true
			if squire_ref != null and is_instance_valid(squire_ref):
				squire_ref.queue_free()
				squire_ref = null
			oname = "SOLITARY"
		10:
			pawn_discount = true
			Stats.buff_maxhp_pct -= 0.15
			oname = "PAWNBREAKER"
		11:
			var hpool: Array = []
			for rid13 in ITEMS.DB:
				if int(ITEMS.DB[rid13]["rarity"]) <= 0 and not Stats.relics.has(rid13):
					hpool.append(rid13)
			if not hpool.is_empty():
				var rid14: String = String(hpool[rng.randi() % hpool.size()])
				Stats.add_relic(rid14)
				toast("Heirloom: " + String(ITEMS.DB[rid14]["name"]))
			Stats.buff_armor -= 1
			oname = "HEIRLOOM"
		12:
			golden_fate = true
			Stats.buff_maxhp_pct -= 0.1
			oname = "GOLDEN FATE"
		13:
			legion_omen = true
			Stats.buff_xp_pct += 0.15
			oname = "LEGION"
		14:
			Stats.buff_maxhp_pct -= 0.35
			vials += 2
			oname = "LASTBORN"
		15:
			Stats.buff_atk_pct += 0.2
			Stats.buff_aspd -= 0.2
			oname = "HEAVYHAND"
		16:
			wolf_omen = true
			oname = "WOLF"
		17:
			ashborn = true
			Stats.buff_maxhp_pct -= 0.1
			oname = "ASHBORN"
		18:
			lonecrown = true
			oname = "LONE CROWN"
		19:
			Stats.soul_bonus += 1
			Stats.reaper_tithe = true
			oname = "REAPER'S TITHE"
		20:
			Stats.buff_atk_pct += 0.4
			Stats.deathwish = true
			oname = "DEATHWISH"
		21:
			bargainer = true
			oname = "BARGAINER"
		22:
			Stats.hollow_crown = true
			Stats.buff_atk_pct += 0.4
			oname = "HOLLOW CROWN"
		23:
			Stats.spiteful = true
			oname = "SPITEFUL"
		24:
			Stats.kaels_wager = true
			Stats.buff_maxhp_pct = -0.99
			if player != null and is_instance_valid(player):
				player.refresh_stats()
				player.hp = minf(player.hp, Stats.get_stat("max_hp"))
				player.hp_changed.emit(player.hp)
			oname = "KAEL'S WAGER"
		25:
			gravetide = true
			omen_hp_mult += 0.1
			oname = "GRAVETIDE"
		26:
			Stats.buff_armor += 2
			Stats.buff_maxhp_pct -= 0.2
			oname = "MARROW PACT"
		27:
			wellread = true
			oname = "WELLREAD"
		28:
			tide_lends = true
			omen_hp_mult += 0.08
			oname = "THE TIDE LENDS"
		29:
			pearl_fever = true
			Stats.buff_armor -= 1
			oname = "PEARL FEVER"
		30:
			muckraker = true
			oname = "MUCKRAKER"
		31:
			abyssal_patience = true
			oname = "ABYSSAL PATIENCE"
		32:
			umbral_tide = true
			oname = "UMBRAL TIDE"
		33:
			bone_market = true
			oname = "BONE MARKET"
		34:
			waxpale = true
			omen_hp_mult += 0.1
			oname = "WAXPALE"
		35:
			vessel = true
			omen_hp_mult += 0.1
			oname = "VESSEL"
		36:
			skeleton_crew = true
			oname = "SKELETON CREW"
		37:
			rolling_fog = true
			oname = "ROLLING FOG"
		38:
			deep_pockets_oath = true
			omen_hp_mult += 0.12
			oname = "DEEP POCKETS"
		39:
			oarsworn = true
			omen_hp_mult += 0.1
			oname = "OARSWORN"
		40:
			dark_water = true
			omen_hp_mult += 0.1
			oname = "DARK WATER"
		41:
			Stats.buff_xp_pct += 0.3
			omen_hp_mult += 0.15
			oname = "FATHOMLESS"
		42:
			full_chart = true
			omen_hp_mult += 0.1
			oname = "FULL CHART"
		43:
			Stats.buff_atk_pct += 0.15
			Stats.cd_reduction -= 0.2
			oname = "WET POWDER"
		44:
			long_wake = true
			Stats.curse_xp += 0.2
			oname = "LONG WAKE"
		45:
			Stats.soul_gain_pct += 0.25
			omen_hp_mult += 0.1
			oname = "SALT FEVER"
		46:
			dead_lantern = true
			oname = "DEAD LANTERN"
		47:
			hull_song = true
			Stats.cd_reduction += 0.15
			oname = "HULL SONG"
		48:
			salt_ledger = true
			oname = "SALT LEDGER"
		49:
			omen_hp_mult += 0.15
			Stats.curse_xp += 0.3
			oname = "DEEP TOLL"
		50:
			slow_clock = true
			Stats.cd_reduction -= 0.2
			oname = "SLOW CLOCK"
		51:
			deck_alms = true
			oname = "DECK ALMS"
		52:
			loose_ballast = true
			Stats.curse_dmg += 0.15
			oname = "LOOSE BALLAST"
		53:
			black_sails = true
			Stats.soul_gain_pct += 0.2
			oname = "BLACK SAILS"
		54:
			grim_charter = true
			oname = "GRIM CHARTER"
		55:
			martyrs_oath = true
			Stats.curse_dmg += 0.1
			oname = "MARTYR'S OATH"
		56:
			slim_pickings = true
			Stats.soul_gain_pct += 0.25
			oname = "SLIM PICKINGS"
		57:
			sworn_hull = true
			Stats.buff_armor += 1
			oname = "SWORN HULL"
		58:
			old_salt = true
			Stats.buff_atk_pct += 0.1
			Stats.soul_gain_pct -= 0.2
			oname = "OLD SALT"
		59:
			full_sails = true
			Stats.soul_gain_pct += 0.3
			oname = "FULL SAILS"
		60:
			long_oars = true
			Stats.buff_speed_pct -= 0.1
			oname = "LONG OARS"
		61:
			deep_draft = true
			Stats.buff_maxhp_pct -= 0.15
			Stats.soul_gain_pct += 0.25
			oname = "DEEP DRAFT"
		62:
			high_water = true
			omen_hp_mult += 0.1
			Stats.curse_dmg += 0.1
			Stats.curse_xp += 0.3
			oname = "HIGH WATER"
		63:
			ballast_oath = true
			Stats.buff_speed_pct -= 0.1
			Stats.buff_armor += 2
			oname = "BALLAST OATH"
		64:
			thin_hull = true
			Stats.buff_armor -= 1
			Stats.buff_atk_pct += 0.15
			oname = "THIN HULL"
		65:
			cold_toll = true
			Stats.buff_speed_pct -= 0.05
			Stats.buff_xp_pct += 0.10
			oname = "COLD TOLL"
		66:
			oarlocks = true
			Stats.buff_armor += 1
			omen_cd_add = 1.0
			oname = "OARLOCKS"
		67:
			pilot_dead = true
			Stats.soul_gain_pct += 0.15
			oname = "PILOT DEAD"
		68:
			candle_tax = true
			Stats.soul_gain_pct -= 0.2
			oname = "CANDLE TAX"
		69:
			fathom_tax = true
			omen_hp_mult *= 1.15
			Stats.soul_gain_pct += 0.2
			oname = "FATHOM TAX"
		70:
			hull_rot = true
			Stats.buff_armor -= 1
			Stats.buff_xp_pct += 0.2
			oname = "HULL ROT"
		71:
			still_water = true
			oname = "STILL WATER"
		72:
			gold_hull = true
			Stats.soul_gain_pct += 0.15
			Stats.buff_armor -= 1
			oname = "GOLD HULL"
		73:
			salt_ration = true
			Stats.cd_reduction += 0.1
			omen_hp_mult *= 1.1
			oname = "SALT RATION"
		74:
			hard_tack = true
			Stats.buff_xp_pct += 0.15
			oname = "HARD TACK"
		75:
			leaden_purse = true
			Stats.soul_gain_pct -= 0.15
			oname = "LEADEN PURSE"
		76:
			widows_ledger = true
			Stats.soul_gain_pct += 0.15
			omen_hp_mult *= 1.08
			oname = "WIDOW'S LEDGER"
		77:
			flotsam_kin = true
			Stats.buff_xp_pct += 0.15
			oname = "FLOTSAM KIN"
		78:
			scurvy = true
			Stats.buff_maxhp_pct -= 0.1
			Stats.buff_xp_pct += 0.15
			oname = "SCURVY"
		79:
			draft_hole = true
			omen_cd_add -= 1.0
			oname = "DRAFT HOLE"
		80:
			keel_hauled = true
			Stats.buff_armor += 1
			Stats.buff_speed_pct -= 0.08
			oname = "KEEL HAULED"
		81:
			bilge_sworn = true
			Stats.soul_gain_pct -= 0.1
			oname = "BILGE SWORN"
		82:
			salt_forfeit = true
			Stats.buff_maxhp_pct -= 0.1
			Stats.buff_xp_pct += 0.15
			oname = "SALT FORFEIT"
		83:
			dead_reckoner = true
			Stats.soul_gain_pct += 0.15
			oname = "DEAD RECKONER"
		84:
			pale_dock = true
			Stats.soul_gain_pct += 0.15
			oname = "PALE DOCK"
		85:
			fathom_pact = true
			Stats.dodge += 0.1
			oname = "FATHOM PACT"
		86:
			bosuns_debt = true
			Stats.buff_xp_pct += 0.15
			oname = "BOSUN'S DEBT"
		87:
			crews_share = true
			Stats.soul_gain_pct += 0.15
			Stats.buff_xp_pct -= 0.08
			oname = "CREW'S SHARE"
		88:
			Stats.buff_lifesteal += 0.08
			Stats.buff_speed_pct -= 0.1
			palm_tar = true
			oname = "PALM TAR"
		89:
			oar_tax = true
			Stats.buff_speed_pct += 0.12
			Stats.buff_armor -= 1
			oname = "OAR TAX"
		90:
			rust_bounty = true
			Stats.buff_crit += 0.15
			Stats.buff_maxhp_pct -= 0.1
			oname = "RUST BOUNTY"
		91:
			deep_charter = true
			Stats.buff_xp_pct += 0.2
			Stats.soul_gain_pct -= 0.1
			oname = "DEEP CHARTER"
		92:
			salty_wages = true
			Stats.soul_gain_pct += 0.15
			Stats.buff_xp_pct -= 0.1
			oname = "SALTY WAGES"
		93:
			gunnel_tide = true
			Stats.buff_aspd += 0.1
			Stats.buff_armor -= 1
			oname = "GUNNEL TIDE"
		94:
			dead_wages = true
			Stats.buff_atk_pct += 0.15
			Stats.soul_gain_pct -= 0.1
			oname = "DEAD MAN'S WAGES"
		95:
			riggers_due = true
			Stats.soul_gain_pct += 0.1
			Stats.buff_armor -= 1
			oname = "RIGGER'S DUE"
		96:
			tides_favor = true
			Stats.buff_xp_pct += 0.1
			Stats.buff_armor -= 1
			oname = "TIDE'S FAVOR"
		97:
			barnacle_oath = true
			Stats.soul_gain_pct += 0.08
			Stats.buff_speed_pct -= 0.06
			oname = "BARNACLE OATH"
		98:
			black_tide = true
			Stats.buff_aspd += 0.12
			Stats.buff_maxhp_pct -= 0.08
			oname = "BLACK TIDE"
		99:
			grave_knot = true
			Stats.buff_atk_pct += 0.08
			Stats.dodge -= 0.06
			oname = "GRAVE KNOT"
		100:
			Stats.soul_gain_pct += 0.10
			Stats.buff_xp_pct -= 0.05
			oname = "SALT TITHE"
		101:
			Stats.buff_armor += 2
			Stats.buff_aspd -= 0.10
			oname = "KEELSWORN"
		102:
			Stats.buff_speed_pct += 0.12
			Stats.soul_gain_pct -= 0.10
			oname = "FOG RUNNER"
		103:
			nemesis_bounty = true
			oname = "BLOOD DEBT"
	omen_name = oname if omen_name == "" else omen_name + "+" + oname
	if not Stats.oaths_seen.has(oname):
		Stats.oaths_seen.append(oname)
	if Stats.oaths_seen.size() >= 12:
		_ach("oathbound")
	if Stats.oaths_seen.size() >= 20:
		_ach("manyoaths")
		Stats.save_game()
	omen_count += 1
	Stats.oaths_sworn += 1
	if Stats.oaths_sworn >= 5:
		_ach("fatebound")
	if Stats.oaths_sworn >= 60:
		_ach("sixtypacts")
	if Stats.oaths_sworn >= 70:
		_ach("seventypacts")
	if Stats.oaths_sworn >= 80:
		_ach("eightypacts")
	_ach("omen1")
	if omen_count >= 2:
		_ach("doubloath")
	if omen_count >= 8:
		_ach("oathkeeper")
	if Stats.oaths_sworn >= 25:
		_ach("quarteroath")
	if Stats.oaths_sworn >= 10:
		_ach("tenthoath")
	Sfx.play("shrine")
	if player != null and is_instance_valid(player):
		player.refresh_stats()
	_refresh_buffs()
	if omen_count >= 3:
		toast("Three oaths. The Oracle whispers: 'Your soul is a ledger of pacts, Kael.'")
	else:
		toast("Omen sworn: " + omen_name)
	var reacts := {
		"WARPATH": "All edge, no hilt. Swing like you mean to be feared.",
		"LEGION": "More dead to cut. The deeps oblige your hunger.",
		"LASTBORN": "Born fragile, armed thrice. Drink deep when it matters.",
		"HEAVYHAND": "Slow hands, heavy graves. Make each cut count.",
		"WOLF": "The pack runs faster after every feed.",
		"ASHBORN": "Carry the fire's memory. The rain will find you.",
		"LONE CROWN": "Save your sharpest edge for thrones.",
		"REAPER'S TITHE": "The reaper skims every tenth soul. Still worth it.",
		"DEATHWISH": "Glass edge, glass skull. Beautiful and doomed.",
		"BARGAINER": "He likes a customer who swears early.",
		"FEATHER": "A lighter coffin, then. Sensible.",
		"RICH SOIL": "The dungeon will feed you well — keep chewing.",
		"LEECHING": "Your blood will not stay yours, but at least it circles back.",
		"ECLIPSE": "One sunrise bought. Do not spend it cheaply.",
		"IRONSIDE": "Heavy steps, stubborn heart — a knight's own bargain.",
		"STORMGLASS": "Faster storms, thinner skin. Fair trade.",
		"OATH OF SILENCE": "Silent hands, louder blade. I approve.",
		"FATEHAND": "More doors for fate to walk through — watch which one you open.",
		"SOLITARY": "Alone, then. Even ghosts respect a debt they didn't choose.",
		"PAWNBREAKER": "His prices will sting less. He'll hate that.",
		"FATHOMLESS": "Deep lessons, deep bruises. The sea teaches both.",
		"FULL CHART": "No corner unmapped, Kael — the deep cannot hide from you now, nor you from it.",
		"WET POWDER": "Wet powder, dry blade, Kael — the sword remembers, the tricks forget.",
		"LONG WAKE": "They smell the living on you, Kael — good, let them come. Lessons arrive faster that way.",
		"SALT FEVER": "Greed salts the water, Kael — richer souls, meaner dead.",
		"DEAD LANTERN": "Hang the lantern high, Kael — the urns will pay for what the elites will cost.",
		"HULL SONG": "The ship sings through you, Kael — your arms answer quicker. So do theirs.",
		"SALT LEDGER": "The sea keeps books, Kael — she'll overcharge the dealers and pay you interest on the back.",
		"DEEP TOLL": "The deep taxes endurance, Kael — the dead last longer and so do their lessons.",
		"SLOW CLOCK": "Time runs thick down here, Kael — for your arts and for their feet alike.",
		"DECK ALMS": "The keel blesses the generous, Kael — the dealers soften, and the dead hurry to collect.",
		"LOOSE BALLAST": "A loose hull rolls hard, Kael — you'll feel every blow, but they'll feel the drag too.",
		"BLACK SAILS": "Fast sails mean fast foes, Kael — but their pockets run heavier for the chase.",
		"GRIM CHARTER": "The charter calls the captains out, Kael — heavier crowns, richer spoils.",
		"FULL SAILS": "Speed for souls — the sea's oldest wager.",
		"LONG OARS": "Slow and steady — the steady part is what the dead hate.",
		"DEEP DRAFT": "Loaded low and heavy — wealth weighs more than wounds.",
		"HIGH WATER": "The flood lifts every anchor — theirs and yours alike.",
		"BALLAST OATH": "Heavy feet, steady hull — let them bounce off you.",
		"THIN HULL": "Lose the plank, keep the edge — everything's a trade at sea.",
		"COLD TOLL": "Cold fingers, sharp mind — you'll learn faster shivering.",
		"OARLOCKS": "Sore hands, sound hull — nobody rows for free.",
		"CANDLE TAX": "Every lantern takes its tithe — cheaper passage, dimmer pay.",
		"FATHOM TAX": "The deep charges for every fathom — pay in dead men's coin.",
		"HULL ROT": "Soft planks, hard lessons — the rot teaches what the armor couldn't.",
		"STILL WATER": "Still water runs deepest — slow hands, heavy fists.",
		"GOLD HULL": "Gilded ships sink finest — the coin was never worth the planks.",
		"SALT RATION": "Thin rations, sharp blades — hungry crews fight like the starving do.",
	"WIDOW'S LEDGER": "She keeps the books for every drowned sailor — and her interest compounds in marrow.",
	"FLOTSAM KIN": "Sworn to the drift — everything loose in the water belongs to it.",
	"SCURVY": "The oldest pact on any ship — suffer now, learn faster.",
	"DRAFT HOLE": "Sailors pray for a fair wind; the deep lends a faster current to whoever asks.",
	"KEEL HAULED": "Scraped hulls sail true — but a clean hull is a dead sailor's vanity.",
	"BILGE SWORN": "Sworn to the lowest deck — everything down there moves slower, even the dying.",
	"SALT FORFEIT": "Blood first, glory later — the sea always collects its collateral.",
	"DEAD RECKONER": "Plot the course and the dead plot back — fair trade for a fuller purse.",
	"PALE DOCK": "Every berth taken is a berth you cannot have — the purse compensates.",
	"FATHOM PACT": "Stand steady and let them come — the deep likes a duel.",
	"BOSUN'S DEBT": "The boatswain lends you tempo — and collects it back, with interest.",
	"CREW'S SHARE": "The crew eats first, the hero last — that's the law of the ship.",
	"PALM TAR": "Once the tar takes hold it never truly lets you go.",
	"OAR TAX": "Every stroke the oars lend you, they collect back in planks.",
	"RUST BOUNTY": "What rust takes from the hull it lends to the hand.",
	"DEEP CHARTER": "The dark water sells its lessons cheap — only the price is in souls.",
	"SALTY WAGES": "The wages of the drowned are paid in what they stole.",
	"GUNNEL TIDE": "Hold the rail and the sea moves your arm for you.",
	"DEAD MAN'S WAGES": "Unclaimed coin spends fastest on the living.",
	"RIGGER'S DUE": "The lines remember who climbs them.",
	"TIDE'S FAVOR": "The water pushes where it wills.",
	"BARNACLE OATH": "Everything that sticks to the hull pays rent.",
	"BLACK TIDE": "The darkest water pulls the hardest.",
	"GRAVE KNOT": "Tied to the plot you were always going to.",
	"SALT TITHE": "The sea knows what you're worth, to the last soul.",
	"KEELSWORN": "Iron holds what salt water takes.",
	"FOG RUNNER": "The haze never outran anyone.",
		"HARD TACK": "Iron bread for iron nerves — what doesn't break your teeth breaks the foe.",
		"LEADEN PURSE": "Heavy purses slow every ship — yours and theirs alike.",
		"PILOT DEAD": "They smell the living on you — lean in, the pay's better anyway.",
		"OLD SALT": "Lighter purse, heavier arm — the old hands swear by it.",
		"SWORN HULL": "The hull thickens and the chase quickens — even trade.",
		"SLIM PICKINGS": "The lean tide still pays, Kael — slower hands, heavier purse.",
		"MARTYR'S OATH": "Bleed for them and they feed you, Kael — the martyrs' ledger is fair.",
		"HEIRLOOM": "Someone carried that before you. They are still carrying it, in a way.",
		"GOLDEN FATE": "Every lock will gleam. Mind the teeth on some.",
		"HOLLOW CROWN": "Crown of nothing. The Oracle admires your appetite anyway.",
		"SPITEFUL": "Your hate is contagious, Kael. The dead will share it.",
		"KAEL'S WAGER": "A king's ransom on a single heartbeat. Even the Oracle holds her breath.",
		"GRAVETIDE": "The tide comes in for you, Kael — and everything it carries is hungry.",
		"MARROW PACT": "Bone will have to do what blood cannot. The King respects a thrifty heart.",
		"BLOOD DEBT": "Signed in red and paid in full — show him what you became.",
		"WELLREAD": "The stones remember you now, Kael — read them all, and grow rich on grief.",
		"THE TIDE LENDS": "The vaults open for you, swordsman — but the King counts every coin you lift.",
		"DARK WATER": "The black water pays its tolls gladly, Kael — it only asks that you carry more of it.",
		"PEARL FEVER": "Crack every shell you find, Kael — just mind the salt between the seams.",
		"MUCKRAKER": "The deep pays its scavengers well — if they can keep their fingers.",
		"ABYSSAL PATIENCE": "Patience, fisher — let the heavy chests fill your purse; leave the pots for the crabs.",
		"UMBRAL TIDE": "Step light, Kael — the black water is thick tonight, and everything in it is coming for you.",
		"BONE MARKET": "Everything here has a price on its lid. Try not to lose a finger haggling.",
		"WAXPALE": "Pale as tallow, hungry as the tide — the little lights will feed you well tonight.",
		"VESSEL": "Crack every pot you find, Kael — the dead stored their wages in clay.",
		"SKELETON CREW": "A short crew on a long grave, Kael — the few who remain will wear crowns.",
		"ROLLING FOG": "The fog buys you three breaths, Kael — spend them cutting.",
		"DEEP POCKETS": "Deep pockets for a shallow grave, Kael — haggle while you can.",
		"OARSWORN": "Pull, pull — the tide does the rowing for those who swear.",
	}
	var rline: String = String(reacts.get(oname, "An oath is an oath."))
	_say([{"who": "oracle", "text": rline}])


func _on_mahzan_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 1
	mahzan_met += 1
	var mlines := [
		"Ah — living blood in my halls. Rare merchandise... rarer currency. Pick a deal.",
		"The Bone King pays me in bones. You'd pay in something warmer. Choose.",
		"A customer! It's been a century since the last. Don't make me regret it, Kael.",
	]
	if Stats.nemesis != "":
		mlines = [
			"You stink of old death, Kael — something down here owns your blood and knows it. Pay me, and let's pretend it's only business.",
			"A marked man walks in. The Debt has a name, and it is not kind. Buy something — you'll need it.",
		]
	elif mahzan_met == 2:
		mlines = [
			"Back already? You spend souls like water, Kael. I approve.",
			"Twice in one descent. The crown must be worried about you.",
		]
	elif mahzan_met == 3:
		mlines = [
			"My most faithful customer. When you take the throne, remember who stocked your satchel.",
			"Kael. Again. I'd offer you credit, but the dead don't have wallets.",
		]
	elif mahzan_met >= 4:
		mlines = [
			"Royal patronage! Kael, you're the best thing to happen to this ledger in centuries. Take a tip — three souls, on the house.",
			"Fourth visit? Fifth? I've stopped counting. You're practically family now — family pays a little less.",
		]
		Stats.earn_souls(3)
		_souls_l()
		toast("FAMILY RATES — all soul prices -1")
	_say(
		[{"who": "mahzan", "text": mlines[rng.randi_range(0, mlines.size() - 1)]}],
		[
			{"text": "Leech's Bargain — lose 2 Max HP, gain a rare relic"},
			{"text": "Blood Tithe — lose 1 HP now, +20% ATK this run"},
			{"text": "Mahzan's Gamble — a free relic... but he chooses it"},
			{"text": "Relic Pawn — sell a random relic for 10 souls"},
			{"text": "Vial Merchant — pay 5 souls for a full satchel"},
			{"text": "Debt Settlement — pay 15 souls to lift your −%d Max HP debt" % int(Stats.mahzan_debt)},
			{"text": "Curse Eater — pay 8 souls to shed one Blood Pact"},
			{"text": "Kismet Thread — pay 8 souls: +1 reroll on every draft"},
			{"text": "Pale Pawn — pay 6 souls: +30% XP this run"},
			{"text": "Bone Lottery — pay 5 souls: a random blade from the hoard"},
			{"text": "Fool's Trove — pay 3 souls: a trinket, fair or foul"},
			{"text": "Witness — pay 2 souls: Mahzan tells you a secret"},
			{"text": "Blood Velvet — pay 9 souls: +10% Max HP this run"},
			{"text": "Last Rites — pay 12 souls: one resurrection, on credit"},
			{"text": "Pearl Insurance — pay 4 souls: your next 2 trap hits do nothing"},
			{"text": "Abyssal Jar — pay 8 souls: a trinket dredged from the deep"},
			{"text": "Sirensong — pay 4 souls: this floor's elites pay +4 souls"},
			{"text": "Rotgut Brew — pay 3 souls: +15% Max HP till the floor falls"},
			{"text": "Pale Ale — pay 2 souls: +8% speed till the floor falls"},
			{"text": "Mystery Meat — pay 4 souls: a random blessing, sight unseen"},
			{"text": "Mudlark — pay 3 souls: every floor's end pays +1 soul for the run"},
			{"text": "Bilge Wine — pay 3 souls: drink deep — 30% HP and a headful of XP"},
			{"text": "Glass Compass — pay 5 souls: he shows you the whole floor, every room"},
			{"text": "Sea Shanty — pay 4 souls: his song speeds your skills (+10% recharge this run)"},
			{"text": "Deck Prayer — pay 4 souls: +12% ATK this run"},
			{"text": "Lantern Oil — pay 3 souls: hearts and lanterns mend half again this run"},
			{"text": "Crow's Share — pay 5 souls: every floor you clear pays +1 soul this run"},
			{"text": "Grave Meal — pay 4 souls: the dead feed you (mend 40% Max HP)"},
			{"text": "Crow's Feast — pay 4 souls: +20% souls for the rest of this run"},
			{"text": "Bone Dice — stake 5 souls: even or odd, the dice decide (+12 or lose the stake)"},
			{"text": "Debt Scribe — pay 3 souls: he writes one page of your quest forward"},
			{"text": "Grave Cheer — pay 4 souls: a vial and a long pull (+1 vial, mend 15% HP)"},
			{"text": "Tar Rum — pay 3 souls: thick and black — +5% ATK this run"},
			{"text": "Galley Scraps — pay 3 souls: peel off silence, roots and weakness"},
			{"text": "Rat Ration — pay 2 souls: stale but hearty — full mend when the next floor begins"},
			{"text": "Gilded Provisions — pay 4 souls: the officer's mess — vial topped, 30% mended"},
			{"text": "Gilded Map — pay 4 souls: every room of this floor sketched in bone-ink"},
			{"text": "Salt Wager — stake 6 souls: the tide doubles it or drinks it"},
			{"text": "Keelman's Toll — pay 3 souls: the dead wade −8% slower this floor"},
			{"text": "Salt Bond — pay 5 souls: a knot in the cord — your skills charge −1s this run"},
			{"text": "Salt Haven — pay 8 souls: the ghost draws you a clean berth — mend to full now"},
			{"text": "Iron Purse — pay 12 souls: heavy coin, heavier hide — +2 Armor this run"},
			{"text": "Bone Scrip — pay 4 souls: the tally scratched in marrow — +10% XP this run"},
			{"text": "Grave Bond — pay 14 souls: a mortgage on your marrow — +3 Armor this run"},
			{"text": "Toll of Marrow — pay 8 souls: price paid in red — +12% crit this run"},
			{"text": "Haste Ledger — pay 8 souls: quickened accounts — +15% attack speed this run"},
			{"text": "Grave Annuity — pay 7 souls: the dead pay dividends — +15% XP this run"},
			{"text": "Soul Ledger — pay 8 souls: the ledger remembers every soul — +20% souls this floor"},
			{"text": "Grave Silk — pay 8 souls: funeral cloth for the nimble — +12% dodge this run"},
			{"text": "Salt Dowry — pay 5 souls: a bride-price from the drowned — +12% souls this floor"},
			{"text": "Sovereign's Doubt — pay 6 souls: doubt sharpens a blade — +15% ATK, −5% Max HP this floor"},
			{"text": "Grim Wager — pay 7 souls: Mahzan backs your blade — +12% ATK, +8% crit this floor"},
		]
	)


func _on_forge_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 6
	_say([{"who": "oracle", "text": "A smith's altar, cold these hundred years — but its flame remembers blades, Kael."}],
		[{"text": "Quench the Blade — pay 6 souls: +1 weapon level"},
		{"text": "Sharpen Fully — pay 10 souls: +2 weapon levels"},
		{"text": "Temper the Wielder — pay 4 souls: the forge's heat seals your wounds"},
		{"text": "Bind Two Souls — sacrifice two common relics for a greater one"},
		{"text": "Leave the cold anvil"}])


func _forge_deal(idx: int) -> void:
	var wid: String = Stats.weapon_id
	var wname: String = String(WDB.get_w(wid)["name"])
	var wlv: int = int(Stats.weapon_lv.get(wid, 1))
	if idx == 0:
		if wlv >= 6:
			toast("The blade is perfect — it can go no further")
			return
		elif Stats.souls < _forge_cost(6):
			toast("Not enough souls (need 6)")
			return
		Stats.souls -= _forge_cost(6)
		Stats.weapon_lv[wid] = wlv + 1
	elif idx == 1:
		if wlv >= 5:
			toast("The blade nears perfection — one quench at a time")
			return
		elif Stats.souls < _forge_cost(10):
			toast("Not enough souls (need 10)")
			return
		Stats.souls -= _forge_cost(10)
		Stats.weapon_lv[wid] = wlv + 2
	elif idx == 2:
		if Stats.souls < _forge_cost(4):
			toast("Not enough souls (need 4)")
			return
		Stats.souls -= _forge_cost(4)
		player.hp = Stats.get_stat("max_hp")
		_souls_l()
		Stats.save_game()
		Sfx.play("heal")
		toast("TEMPERED — wounds sealed in forge-heat")
		_quest_event("forge")
		if player != null and is_instance_valid(player):
			player.hp_changed.emit(player.hp)
			_burst(player.global_position + Vector3(0, 0.6, 0), Color(1.0, 0.6, 0.25))
		return
	elif idx == 3:
		var commons: Array = []
		for ridc in Stats.relics:
			if ITEMS.DB.has(ridc) and int(ITEMS.DB[ridc]["rarity"]) == 0:
				commons.append(ridc)
		if commons.size() < 2:
			toast("The binding needs two common relics")
			return
		Stats.relics.erase(commons[0])
		Stats.relics.erase(commons[1])
		Stats.relics_changed.emit()
		var bpool: Array = []
		for ridb in ITEMS.DB:
			if int(ITEMS.DB[ridb]["rarity"]) >= 1 and not Stats.relics.has(ridb):
				bpool.append(ridb)
		if bpool.is_empty():
			toast("No relic left to bind — the souls return")
			Stats.relics.append(commons[0])
			Stats.relics.append(commons[1])
			Stats.relics_changed.emit()
			return
		var bound: String = bpool[rng.randi_range(0, bpool.size() - 1)]
		Stats.add_relic(bound)
		Sfx.play("levelup")
		toast("BOUND SOUL — relic forged: " + String(ITEMS.DB[bound]["name"]))
		_quest_event("forge")
		_refresh_buffs()
		return
	else:
		return
	_souls_l()
	Stats.forges_used += 1
	Stats.save_game()
	Sfx.play("levelup")
	toast("%s forged to +%d" % [wname, int(Stats.weapon_lv[wid]) - 1])
	_refresh_hud_weapon()
	_quest_event("forge")
	if Stats.forges_used >= 3:
		_ach("smith3")
	if int(Stats.weapon_lv[wid]) >= 6:
		_ach("forge5")
	_refresh_buffs()
	if player != null and is_instance_valid(player):
		player.refresh_stats()
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.15))


func _on_mirror_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 7
	var wname := String(WDB.get_w(Stats.weapon_id)["name"])
	_say([{"who": "oracle", "text": "The mirror shows not your face, Kael — but another warrior's blade. Feed it and it will trade yours."}],
		[{"text": "Gaze — pay 4 souls: swap %s for a stranger's blade" % wname},
		{"text": "Look away"},
		{"text": "Peer Deeper — pay 6 souls: the mirror grants a relic of equal worth"},
		{"text": "Smash it — +8 souls, but the mirror's shards wake three horrors"}])


func _mirror_deal(idx: int) -> void:
	if idx == 3:
		Stats.earn_souls(8)
		_souls_l()
		Stats.save_game()
		Sfx.play("chest")
		toast("MIRROR SHATTERED — +8 souls")
		var table3: Array = biome["enemies"]
		for mk3 in range(3):
			var off3 := Vector3((mk3 - 1) * 0.9 * info.tile, 0, -0.4 * info.tile)
			_spawn_enemy({"pos": shrine_ref.global_position + off3, "room": current_room}, String(table3[rng.randi_range(0, table3.size() - 1)]), mk3 == 0)
		if player != null and is_instance_valid(player):
			_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.75, 1.0))
		return
	if idx == 2:
		if Stats.souls < _soul_cost(6):
			toast("Not enough souls (need 6)")
			return
		if Stats.relics.is_empty():
			toast("The mirror needs a relic to reflect")
			return
		var proto: String = Stats.relics[rng.randi_range(0, Stats.relics.size() - 1)]
		var prar := int(ITEMS.DB[proto]["rarity"]) if ITEMS.DB.has(proto) else 0
		var ppool: Array = []
		for ridm in ITEMS.DB:
			if int(ITEMS.DB[ridm]["rarity"]) == prar and not Stats.relics.has(ridm):
				ppool.append(ridm)
		if ppool.is_empty():
			toast("The mirror finds nothing of equal worth")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		var mirrored: String = ppool[rng.randi_range(0, ppool.size() - 1)]
		Stats.add_relic(mirrored)
		Sfx.play("levelup")
		toast("REFLECTION — the mirror grants " + String(ITEMS.DB[mirrored]["name"]))
		_refresh_buffs()
		return
	if idx != 0:
		return
	if Stats.souls < _soul_cost(4):
		toast("Not enough souls (need 4)")
		return
	var opts: Array = []
	for wid in WDB.POOL:
		if wid != Stats.weapon_id:
			opts.append(wid)
	if opts.is_empty():
		toast("The mirror finds nothing worth trading")
		return
	Stats.souls -= _soul_cost(4)
	_count_deal()
	_souls_l()
	var nid: String = String(opts[rng.randi() % opts.size()])
	player.equip_weapon(nid)
	_refresh_hud_weapon()
	Stats.save_game()
	Sfx.play("levelup")
	toast("The mirror trades — %s drawn" % String(WDB.get_w(nid)["name"]))
	_ach("mirror1")
	if player != null and is_instance_valid(player):
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.7, 1.0))


func _on_bounty_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 8
	_say([{"who": "oracle", "text": "A bounty stone — the dungeon's own bounty board. Summon a marked foe; its skull pays a relic."}],
		[{"text": "Call the Marked — summon a bounty elite (drops a rare relic)"},
		{"text": "Deadman's Fee — pay 4 souls: the Marked drops an epic relic"},
		{"text": "Sic the Pack — summon TWO marked elites (each drops a rare relic)"},
		{"text": "Walk on"}])


func _bounty_deal(idx: int) -> void:
	if idx == 2:
		var table2: Array = biome["enemies"]
		for bp in range(2):
			var barch := String(table2[rng.randi_range(0, table2.size() - 1)])
			var bpos: Vector3 = shrine_ref.global_position + Vector3((0.7 + bp * 0.8) * info.tile, 0, (0.3 + bp * 0.4) * info.tile)
			var be := _spawn_enemy({"pos": bpos, "room": current_room}, barch, true)
			if be != null:
				be.pack_bounty = true
				be.hp *= 1.2
				be.hp_max = be.hp
				be.activated = true
				_damage_number(be.global_position + Vector3(0, 1.0 * info.tile, 0), "PACK MARKED!", Color(1.0, 0.6, 0.25), true)
		Sfx.play("roar")
		toast("THE PACK ANSWERS — two marks walk")
		return
	if idx > 1:
		return
	if idx == 1:
		if Stats.souls < _soul_cost(4):
			toast("Four souls to sweeten the contract — the stone is patient")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		bounty_epic = true
	var table: Array = biome["enemies"]
	var arch := String(table[rng.randi_range(0, table.size() - 1)])
	bounty_ref = _spawn_enemy({"pos": shrine_ref.global_position + Vector3(0.8 * info.tile, 0, 0.4 * info.tile), "room": current_room}, arch, true)
	if bounty_ref != null:
		bounty_ref.hp *= 1.4
		bounty_ref.hp_max = bounty_ref.hp
		bounty_ref.activated = true
		Sfx.play("roar")
		_damage_number(bounty_ref.global_position + Vector3(0, 1.0 * info.tile, 0), "BOUNTY MARKED!", Color(1.0, 0.75, 0.3), true)


func _on_ferry_invoked(s) -> void:
	if _ferry_used:
		toast("The ferry has already sailed — its lantern is dark")
		return
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 10
	_say([{"who": "mahzan", "text": "The Ferryman rows the dark between floors. Six souls buys passage past one."}],
		[{"text": "Pay 6 souls — skip the next floor"},
		{"text": "Charon's Tithe — pay HALF your souls: skip the floor and arrive mended"},
		{"text": "Down the Long Dark — pay 10 souls: skip TWO floors"},
		{"text": "Refuse — walk the whole way down"}])


func _ferry_deal(idx: int) -> void:
	if idx == 2:
		var fare := _soul_cost(10)
		if Stats.relics.has("drowned_oar"):
			fare = maxi(fare - 3, 1)
		if Stats.souls < fare:
			toast("Ten souls for the long route — the Ferryman waits")
			return
		Stats.souls -= fare
		_souls_l()
		_ferry_used = true
		ferry_skip = true
		ferry_extra = 1
		Sfx.play("soul")
		_quest_event("ferry")
		toast("THE LONG DARK — two floors will pass under the keel")
		return
	if idx == 1:
		var tithe := int(ceil(Stats.souls * 0.5))
		if Stats.souls < 2:
			toast("The Ferryman spits — you have nothing worth half")
			return
		Stats.souls -= tithe
		_souls_l()
		_ferry_used = true
		ferry_skip = true
		if player != null and is_instance_valid(player):
			player.hp = player.max_hp
			player.hp_changed.emit(player.hp)
		Sfx.play("soul")
		_quest_event("ferry")
		toast("CHARON'S TITHE — %d souls paid; you arrive whole" % tithe)
		return
	if idx != 0:
		toast("The Ferryman's lantern fades without you")
		return
	var fare6 := _soul_cost(6)
	if Stats.relics.has("ferry_token"):
		fare6 = 3
	if Stats.relics.has("drowned_oar"):
		fare6 = maxi(fare6 - 3, 1)
	if Stats.souls < fare6:
		toast("Six souls — the Ferryman doesn't haggle")
		return
	Stats.souls -= fare6
	_souls_l()
	_ferry_used = true
	ferry_skip = true
	Sfx.play("soul")
	_quest_event("ferry")
	toast("CARRIED — the Ferryman will bear you past the next floor")


func _on_well_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 11
	_say([{"who": "mahzan", "text": "A Gambler's Well, Kael — the dungeon's own dice-cup. Toss a soul in, see what the deep tosses back."}],
		[{"text": "Toss 5 souls — gamble for a relic (65% rare, 10% epic... or nothing)"},
		{"text": "Walk on — luck is for the living"}])


func _well_deal(idx: int) -> void:
	if idx != 0:
		toast("The well's green water stills")
		return
	if Stats.souls < _soul_cost(5):
		toast("Five souls — the well only takes real coin")
		return
	Stats.souls -= _soul_cost(5)
	_count_deal()
	_souls_l()
	Sfx.play("soul")
	var roll := rng.randf()
	if roll < 0.10:
		var epool: Array = []
		for ridx in ITEMS.DB:
			if int(ITEMS.DB[ridx]["rarity"]) >= 2 and not Stats.relics.has(ridx):
				epool.append(ridx)
		if not epool.is_empty():
			var ridw: String = epool[rng.randi_range(0, epool.size() - 1)]
			Stats.add_relic(ridw)
			toast("JACKPOT — epic relic: " + String(ITEMS.DB[ridw]["name"]))
			Sfx.play("levelup")
		else:
			Stats.earn_souls(5)
			_souls_l()
			toast("The well is spent — your souls bounce back")
	elif roll < 0.75:
		var rpool: Array = []
		for ridx in ITEMS.DB:
			if int(ITEMS.DB[ridx]["rarity"]) == 1 and not Stats.relics.has(ridx):
				rpool.append(ridx)
		if not rpool.is_empty():
			var ridw2: String = rpool[rng.randi_range(0, rpool.size() - 1)]
			Stats.add_relic(ridw2)
			toast("THE WELL PAYS — rare relic: " + String(ITEMS.DB[ridw2]["name"]))
		else:
			Stats.earn_souls(5)
			_souls_l()
			toast("The well is spent — your souls bounce back")
	else:
		toast("The well drinks deep... and gives nothing back")
		Sfx.play("hurt")
	_quest_event("well")
	# Deep Pockets: tiga lemparan dalam satu lantai memuaskan questnya
	well_rolls += 1
	well_rolls_run += 1
	if well_rolls_run >= 5:
		_ach("loaded_dice")
	if well_rolls >= 3:
		_quest_event("deep_pockets")


func _on_cache_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 12
	_say([{"who": "mahzan", "text": "A scavenger's cache — the dead leave their steel behind, Kael. Take what they no longer need."}],
		[{"text": "Take the steel — a random blade from the hoard (free)"},
		{"text": "Leave it — your blade is oath enough"}])


func _cache_deal(idx: int) -> void:
	if idx != 0:
		toast("The cache's lid settles shut")
		return
	var pool: Array = []
	for wid in WDB.POOL:
		if wid != Stats.weapon_id:
			pool.append(wid)
	if pool.is_empty():
		toast("The hoard holds only what you already carry")
		return
	var wid2: String = String(pool[rng.randi() % pool.size()])
	Stats.equip_weapon(wid2)
	_refresh_hud_weapon()
	Sfx.play("shrine")
	toast("SCAVENGED — " + String(WDB.get_w(wid2)["name"]))
	_quest_event("cache")


func _on_fountain_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 13
	_say([{"who": "oracle", "text": "A Soul Fountain, Kael — old magic pooled into stone. Its water remembers being alive."},
		{"who": "mahzan", "text": "Free healing, if you can believe it. The dungeon must be feeling generous. Drink deep."}],
		[{"text": "Drink — mend half your wounds (free)"},
		{"text": "Pour an offering — pay 4 souls: heal fully + wash away curses"},
		{"text": "Leave it still"}])


func _fountain_deal(idx: int) -> void:
	if idx == 2:
		toast("The fountain's surface settles")
		return
	if idx == 1:
		if Stats.souls < _soul_cost(4):
			toast("Four souls for a full cup — the fountain doesn't beg")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = Stats.get_stat("max_hp")
			player.hex_t = 0.0
			player.chilled_t = 0.0
			player.sunder_t = 0.0
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("The water runs silver — fully mended, curses lifted")
		_quest_event("fountain")
	elif idx == 0:
		if player != null and is_instance_valid(player):
			player.hp = minf(player.hp + Stats.get_stat("max_hp") * 0.5, Stats.get_stat("max_hp"))
			player.hp_changed.emit(player.hp)
			_souls(player.global_position, 5, Color(0.35, 0.95, 0.85))
		Sfx.play("shrine")
		toast("Cold light settles into your wounds — +50% HP")
		_quest_event("fountain")
	if player != null and is_instance_valid(player):
		_burst(player.global_position + Vector3(0, 0.4, 0), Color(0.35, 0.95, 0.85))


func _on_drowned_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 15
	_say([{"who": "oracle", "text": "A drowned altar, Kael — the sea still hears prayers down here. The tide always collects, but it also gives."}],
		[{"text": "Tide Baptism — pay 4 souls: full HP +10% speed this run"},
		{"text": "Drowned Tithe — take +8 souls, but the water takes −10% Max HP"},
		{"text": "Sea-Glass Ward — pay 5 souls: the floor's foes lose 15% HP"},
		{"text": "Sea Legs — pay 6 souls: all skills recharge instantly"},
		{"text": "Salt Purse — pay 3 souls: this floor's urns each spill +1 soul"},
		{"text": "Salt Tithe — pay 2 souls: every urn this RUN spills +1 soul"},
		{"text": "Brine Wash — pay 2 souls: cleanse venom, chill, root and silence"},
		{"text": "Net Gain — pay 5 souls: your next five kills pay double souls"},
		{"text": "Undertow Cache — pay 4 souls: the sea drags a relic to the surface"},
		{"text": "Salt Stitch — pay 3 souls: the brine knits your wounds (+8% lifesteal this run)"},
		{"text": "Drift Line — pay 3 souls: +10% ATK till the floor falls"},
		{"text": "Full Scrub — pay 3 souls: cleanse every ailment, rust and weakness included"},
		{"text": "Deep Breath — pay 4 souls: the dead wade −5% slower for the rest of this run"},
		{"text": "Deep Draw — pay 3 souls: fill your vial satchel"},
		{"text": "Undertow — pay 4 souls: this floor's dead telegraph slower (+12% windup)"},
		{"text": "Sea Burial — pay 4 souls: the Oracle's Bargain drops to 8 souls this run"},
		{"text": "Salt Rinse — pay 2 souls: scrub venom & rust, mend 15% HP"},
		{"text": "Kelp Wine — pay 3 souls: −1s on every skill charge, +5% speed this floor"},
		{"text": "Brine Graft — pay 4 souls: salt in the wounds — +10% Max HP this floor"},
		{"text": "Mist Ration — pay 3 souls: bottle the morning fog — +10% XP this floor"},
		{"text": "Fog Lantern — pay 3 souls: the light marks the strong — elites pay +1 soul"},
		{"text": "Pale Scrip — pay 2 souls: every room you clear this floor pays +1 soul"},
		{"text": "Wet Wool — pay 3 souls: padding in the boots — traps bite −1 less"},
		{"text": "Dowser's Knot — pay 2 souls: a thread that trembles near treasure — chests and shrines glint on your map"},
		{"text": "Salt Rosary — pay 3 souls: blessed knots — venom, chill, root and silence fade twice as fast this run"},
		{"text": "Moonwater — pay 4 souls: a skin of the still tide — your wounds knit +0.3 HP/s this run"},
		{"text": "Bilge Baptism — pay 4 souls: washed in the foul water — the dead strike 10% softer this run"},
		{"text": "Pearl Snuff — pay 5 souls: powdered pearl in the nose — the drowned teach +10% XP this run"},
		{"text": "Tide Pearl — pay 5 souls: held to the chest, it hardens — +1 Armor this run"},
		{"text": "Salt Splice — pay 4 souls: salt stitched under the skin — +1 Armor this floor"},
		{"text": "Pearl Graft — pay 6 souls: nacre under the blade-hand — +15% ATK this floor"},
		{"text": "Oyster Toll — pay 8 souls: the shell's lesson — +15% XP this floor"},
		{"text": "Silt Press — pay 6 souls: squeeze the bottom mud — +15% souls this floor"},
		{"text": "Bilge Bond — pay 4 souls: the muck hums your rhythm — skill charges −15% this floor"},
		{"text": "Mudlark's Due — pay 3 souls: the silt teaches slipping — +8% dodge this floor"},
		{"text": "Kelp Tithe — pay 3 souls: the wrack feeds you — orbs mend +30% this floor"},
		{"text": "Leech Bond — pay 5 souls: the mud's hunger lends you its teeth — +8% lifesteal this floor"},
		{"text": "Murk Purse — pay 3 souls: the depths spill their change — every urn pays +1 soul this floor"},
		{"text": "Tide Sponge — pay 3 souls: the wrack wrings its water over your wounds — heal 30%"},
		{"text": "Keelwind — pay 4 souls: the drowned wind fills your stride — +10% speed this floor"},
		{"text": "Murk Vision — pay 3 souls: the silt clouds their dead eyes — foes notice you −15% later this floor"},
		{"text": "Silt Draught — pay 5 souls: the mud settles into your skin — +1 Armor this floor"},
		{"text": "Undertow Nap — pay 4 souls: the current rocks you a moment — mend 20%"},
		{"text": "Drowned Mercy — pay 5 souls: the river stays its hand — foes −8% damage this floor"},
		{"text": "River's Tithe — pay 4 souls: the current pays its tolls — +12% souls this floor"},
		{"text": "Walk away"}])


func _drowned_deal(idx: int) -> void:
	if idx == 45:
		toast("The water settles back into the stone")
		return
	if idx == 44:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the tithe isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		rivers_tithe = true
		Stats.soul_gain_pct += 0.12
		_quest_event("rivertithe")
		Sfx.play("shrine")
		toast("RIVER'S TITHE — the current pays its tolls")
		return
		toast("The water settles back into the stone")
		return
	if idx == 43:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the river's mercy isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		drowned_mercy = true
		for dm in get_tree().get_nodes_in_group("enemies"):
			if not dm.is_boss:
				dm.dmg = int(dm.dmg * 0.92)
		Sfx.play("shrine")
		toast("DROWNED MERCY — the river stays its hand")
		return
	if idx == 42:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the nap isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.2)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("UNDERTOW NAP — the current rocks you")
		return
	if idx == 41:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the draught isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		silt_draught = true
		Stats.buff_armor += 1
		Sfx.play("shrine")
		toast("SILT DRAUGHT — the mud settles into your skin")
		return
	if idx == 40:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the murk isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		murk_vision = true
		Sfx.play("shrine")
		toast("MURK VISION — the silt clouds their eyes")
		for f in get_tree().get_nodes_in_group("enemies"):
			f.aggro_range *= 0.85
		return
	if idx == 39:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the wind isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		keelwind = true
		Stats.buff_speed_pct += 0.1
		Sfx.play("shrine")
		toast("KEELWIND — the drowned wind fills your stride")
		return
	if idx == 38:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the sponge isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.3)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("TIDE SPONGE — the wrack's water mends")
		return
	if idx == 37:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the purse isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		murk_purse = true
		Sfx.play("shrine")
		toast("MURK PURSE — the urns spill change")
		return
	if idx == 36:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the bond isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		leech_bond = true
		Stats.buff_lifesteal += 0.08
		Sfx.play("shrine")
		toast("LEECH BOND — the mud's teeth, lent")
		return
	if idx == 35:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the wrack isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		kelp_tithe = true
		Sfx.play("shrine")
		toast("KELP TITHE — the wrack feeds you")
		return
	if idx == 34:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the silt isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		mudlarks_due = true
		Stats.dodge += 0.08
		Sfx.play("shrine")
		toast("MUDLARK'S DUE — you slide through their fingers")
		return
	if idx == 33:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the bond isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		bilge_bond = true
		Sfx.play("shrine")
		toast("BILGE BOND — your charges run with the tide")
		return
	if idx == 32:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the mud's price")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		silt_press = true
		Stats.soul_gain_pct += 0.15
		Sfx.play("shrine")
		toast("SILT PRESS — the bottom mud pays out")
		return
	if idx == 31:
		if Stats.souls < _soul_cost(8):
			toast("Eight souls — the oyster's price")
			return
		Stats.souls -= _soul_cost(8)
		_count_deal()
		_souls_l()
		oyster_toll = true
		Stats.buff_xp_pct += 0.15
		Sfx.play("shrine")
		toast("OYSTER TOLL — the shell teaches what the tide charges")
		return
	if idx == 30:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the nacre isn't free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		pearl_graft = true
		Stats.buff_atk_pct += 0.15
		Sfx.play("shrine")
		toast("PEARL GRAFT — the nacre sets into your hand")
		return
	if idx == 29:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the graft isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		brine_graft = true
		Stats.buff_armor += 1
		Sfx.play("shrine")
		toast("SALT SPLICE — the salt knits under your skin")
		return
	if idx == 12:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the breath isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		deep_breath = true
		Sfx.play("shrine")
		toast("DEEP BREATH — the water takes the edge off their step")
	if idx == 13:
		if Stats.souls < _soul_cost(3):
			toast("Three souls to fill the satchel")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		vials = (3 if wide_satchel else 2)
		Sfx.play("shrine")
		toast("DEEP DRAW — the tide fills every vial")
	if idx == 15:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the sea buries none cheaply")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		sea_burial = true
		Sfx.play("shrine")
		toast("SEA BURIAL — the Oracle's thread costs half as much")
		return
	if idx == 14:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the undertow isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		undertow = true
		_quest_event("drowned")
		Sfx.play("shrine")
		toast("UNDERTOW — the floor's dead strike on a slow tide")
		return
	if idx == 11:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the scrub isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			for deb in ["weak_t", "chill_t", "root_t", "venom_t", "silence_t", "rust_t"]:
				player.set(deb, 0.0)
		Sfx.play("shrine")
		toast("FULL SCRUB — every stain on your blade and bones is gone")
		return
	if idx == 10:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the line isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_atk_pct += 0.1
		drift_line = true
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("DRIFT LINE — the current leans on your blade (+10% ATK this floor)")
		return
	if idx == 9:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the salt isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_lifesteal += 0.08
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("SALT STITCH — your wounds knit themselves")
		return
	if idx == 7:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the net isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		netgain_n = 5
		Sfx.play("shrine")
		toast("NET GAIN — the next five kills pay double souls")
		return
	if idx == 6:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the brine isn't free")
			return
		Stats.souls -= _soul_cost(2)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.set("venom_t", 0.0)
			player.set("chill_t", 0.0)
			player.set("root_t", 0.0)
			player.set("silence_t", 0.0)
		Sfx.play("shrine")
		toast("BRINE WASH — the salt strips every clinging curse")
	if idx == 2:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the ward isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		for f in get_tree().get_nodes_in_group("enemies"):
			if f.get("state") != "dead" and not bool(f.get("is_boss")):
				f.hp *= 0.85
				f.hp_max = f.hp
		Sfx.play("shrine")
		toast("SEA-GLASS WARD — the drowned rot faster")
	elif idx == 3:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the sea doesn't lend for free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		for sk in skill_cd:
			skill_cd[sk] = 0.0
		Sfx.play("shrine")
		toast("SEA LEGS — your skills flow again")
	elif idx == 4:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the salt isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		salt_purse = true
		Sfx.play("shrine")
		toast("SALT PURSE — every urn this floor pays +1 soul")
	elif idx == 5:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the tide tithes the poor too")
		else:
			Stats.souls -= _soul_cost(2)
			_count_deal()
			_souls_l()
			salt_tithe = true
			Sfx.play("shrine")
			toast("SALT TITHE — every urn this run spills +1 soul")
	if idx == 8:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the undertow only drags for coin")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		var cpool: Array = []
		for rid_c in ITEMS.DB:
			if int(ITEMS.DB[rid_c]["rarity"]) <= 1 and not Stats.relics.has(rid_c):
				cpool.append(rid_c)
		if cpool.is_empty():
			Stats.earn_souls(4)
			_souls_l()
			toast("The undertow drags back nothing — your souls return")
			return
		var crid: String = String(cpool[rng.randi() % cpool.size()])
		Stats.add_relic(crid)
		Sfx.play("shrine")
		toast("UNDERTOW CACHE — the sea surfaces: " + String(ITEMS.DB[crid]["name"]))
		_ach("tideprovides")
		return
	if idx == 0:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the tide won't lift an empty purse")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = Stats.get_stat("max_hp")
			player.hp_changed.emit(player.hp)
		Stats.buff_speed_pct += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("TIDE BAPTISM — whole again, and swifter for it")
	elif idx == 1:
		Stats.earn_souls(8)
		_souls_l()
		Stats.buff_maxhp_pct -= 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
			player.hp = minf(player.hp, Stats.get_stat("max_hp"))
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		_ach("seaworthy")
		toast("DROWNED TITHE — +8 souls, −10% Max HP")
	if idx == 28:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the pearl isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("TIDE PEARL — your hull sets like mother-of-pearl")
		return
	if idx == 27:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the powder isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		Stats.buff_xp_pct += 0.1
		Sfx.play("shrine")
		toast("PEARL SNUFF — the drowned speak faster now")
		return
	if idx == 26:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the font isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.curse_dmg -= 0.1
		Sfx.play("shrine")
		toast("BILGE BAPTISM — the foul water takes the edge off their spite")
		return
	if idx == 25:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the moon doesn't pour free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		moonwater = true
		Sfx.play("shrine")
		toast("MOONWATER — the tide remembers your shape")
		return
	if idx == 24:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the rosary isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		salt_rosary = true
		Sfx.play("shrine")
		toast("SALT ROSARY — each knot a small ward")
		return
	if idx == 23:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the knot isn't free")
			return
		Stats.souls -= _soul_cost(2)
		_count_deal()
		_souls_l()
		dowser_knot = true
		Sfx.play("shrine")
		toast("DOWSER'S KNOT — the thread pulls toward what glints")
		return
	if idx == 22:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the wool's still dripping")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		wet_wool = true
		Sfx.play("shrine")
		toast("WET WOOL — soft steps on salted boards")
		return
	if idx == 21:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the scrip's not free")
			return
		Stats.souls -= _soul_cost(2)
		_count_deal()
		_souls_l()
		pale_scrip = true
		Sfx.play("shrine")
		toast("PALE SCRIP — the drowned keep accounts")
		return
	if idx == 20:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the lantern's oil isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		fog_lantern_d = true
		Sfx.play("shrine")
		toast("FOG LANTERN — the strong shine in its light")
		return
	if idx == 19:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the mist's not free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_xp_pct += 0.1
		Sfx.play("shrine")
		toast("MIST RATION — the fog teaches in whispers")
		return
	if idx == 18:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the graft's not free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_maxhp_pct += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("BRINE GRAFT — the salt closes what the sea opened")
		return
	if idx == 17:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the wine's not free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		for skk in skill_cd.keys():
			skill_cd[skk] = maxf(0.0, float(skill_cd[skk]) - 1.0)
		Stats.buff_speed_pct += 0.05
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("KELP WINE — green, cold, quickening")
		return
	if idx == 16:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the rinse isn't free")
			return
		Stats.souls -= _soul_cost(2)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.set("venom_t", 0.0)
			player.set("rust_t", 0.0)
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.15)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("SALT RINSE — the brine scours your veins")
	if player != null and is_instance_valid(player):
		_burst(player.global_position + Vector3(0, 0.4, 0), Color(0.35, 0.95, 0.85))
	Stats.drowned_deals += 1
	if Stats.drowned_deals >= 5:
		_ach("river_purse")
	if Stats.drowned_deals >= 8:
		_ach("deepdisciple")
	_quest_event("drowned")


func _on_vault_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 9
	_say([{"who": "oracle", "text": "A soul-sealed vault, Kael — the dungeon locks treasure behind the very coin it mints."}],
		[{"text": "Unlock — pay 5 souls: a rare relic inside"},
		{"text": "Crack the seal — free: either 10 souls spill out... or the vault's guards wake"},
		{"text": "Leave it sealed"}])


func _vault_deal(idx: int) -> void:
	if idx == 1:
		if rng.randf() < 0.5:
			Stats.earn_souls(10)
			_souls_l()
			Sfx.play("soul")
			_souls(player.global_position, 10, Color(0.6, 0.85, 1.0))
			toast("The seal cracks — +10 souls")
		else:
			Sfx.play("roar")
			toast("THE VAULT WAKES — its guards rise!")
			var table4: Array = biome["enemies"]
			for va in range(3):
				var vo: Vector3 = Vector3(cos(va * TAU / 3.0), 0, sin(va * TAU / 3.0)) * info.tile * 0.9
				var ve := _spawn_enemy({"pos": shrine_ref.global_position + vo, "room": current_room}, String(table4[rng.randi_range(0, table4.size() - 1)]), va == 0)
				if ve != null:
					ve.activated = true
		_quest_event("vault")
		return
	if idx != 0:
		return
	if Stats.souls < _soul_cost(5):
		toast("The lock demands five souls")
		return
	var vpool: Array = []
	for rid11 in ITEMS.DB:
		if int(ITEMS.DB[rid11]["rarity"]) >= 1 and not Stats.relics.has(rid11):
			vpool.append(rid11)
	if vpool.is_empty():
		toast("The vault is already empty")
		return
	Stats.souls -= _soul_cost(5)
	_count_deal()
	_souls_l()
	var rid12: String = String(vpool[rng.randi() % vpool.size()])
	Stats.add_relic(rid12)
	Stats.save_game()
	Sfx.play("chest")
	_quest_event("vault")
	toast("VAULT OPENED — " + String(ITEMS.DB[rid12]["name"]))


func _on_curse_invoked(s) -> void:
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 2
	_say([{"who": "oracle", "text": "A cursed obelisk... it hums with hungry promises, Kael."}],
		[{"text": "Blood Pact — foes hit 30% harder, souls pay +50% XP"},
		{"text": "Blood Offering — bleed 2 HP now, gain +50% XP"},
		{"text": "Blood Price — kills stop paying souls this run, but +40% ATK"},
		{"text": "Pyre Sacrament — burn a random common relic for +8 souls"},
		{"text": "Refuse — leave the whispering stone"}])


func _defiance_deal(idx: int) -> void:
	if idx != 0:
		return
	_ach("defiant")
	Stats.buff_atk_pct += 0.25
	if boss_ref != null and is_instance_valid(boss_ref):
		boss_ref.enraged = true
		boss_ref.speed *= 1.4
		boss_ref.windup_t *= 0.7
		boss_ref.hp_max *= 1.15
		boss_ref.hp = boss_ref.hp_max
		if boss_ref.mat != null:
			boss_ref.mat.set_shader_parameter("tint", Color(1.35, 0.35, 0.3))
		toast("The King heard you — he is already FURIOUS (+25% ATK)")
		_boss_enraged()


func _curse_deal(idx: int) -> void:
	if idx == 0:
		Stats.curse_dmg += 0.3
		Stats.curse_xp += 0.5
		toast("BLOOD PACT — the dark bites deeper, souls run richer")
		_ach("pact1")
		_burst(player.global_position, Color(0.8, 0.05, 0.1))
		Sfx.play("roar")
		Input.vibrate_handheld(220)
		_refresh_buffs()
	elif idx == 1:
		if player != null and is_instance_valid(player):
			player.hp = maxf(1.0, player.hp - 2.0)
			player.hp_changed.emit(player.hp)
		Stats.curse_xp += 0.5
		toast("BLOOD OFFERING — the stone drinks your pulse, XP +50%")
		_burst(player.global_position, Color(0.8, 0.05, 0.1))
		Sfx.play("hurt")
		_refresh_buffs()
	elif idx == 3:
		var commons2: Array = []
		for ridp in Stats.relics:
			if ITEMS.DB.has(ridp) and int(ITEMS.DB[ridp]["rarity"]) == 0:
				commons2.append(ridp)
		if commons2.is_empty():
			toast("The obelisk finds no common relic to burn")
			return
		var burnt: String = commons2[rng.randi_range(0, commons2.size() - 1)]
		Stats.remove_relic(burnt)
		Stats.earn_souls(8)
		_souls_l()
		Sfx.play("fire")
		toast("PYRE SACRAMENT — %s burned for +8 souls" % String(ITEMS.DB[burnt]["name"]))
		_refresh_buffs()
		if player != null and is_instance_valid(player):
			_burst(player.global_position, Color(1.0, 0.4, 0.1))
	elif idx == 2:
		Stats.soul_sealed = true
		Stats.buff_atk_pct += 0.4
		toast("BLOOD PRICE — the living stops paying, the blade gets heavier")
		_burst(player.global_position, Color(0.9, 0.1, 0.15))
		Sfx.play("roar")
		_refresh_buffs()


func _count_deal() -> void:
	deals_run += 1
	if deals_run >= 15:
		_ach("spender")

func _mahzan_deal(idx: int) -> void:
	if bargainer and not bargain_used:
		bargain_used = true
		Stats.earn_souls(6)
		_souls_l()
		toast("BARGAINER — Mahzan fronts you 6 souls")
	_quest_event("mahzan")
	match idx:
		0:
			Stats.mahzan_debt += 2.0
			var pool: Array = []
			for id in ITEMS.DB:
				var it: Dictionary = ITEMS.DB[id]
				if int(it["rarity"]) == 1 and not Stats.relics.has(id):
					pool.append(id)
			var rid: String = pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else "berkat_pandai_besi"
			Stats.add_relic(rid)
			toast("Leech's Bargain: -2 Max HP, gained " + String(ITEMS.DB[rid]["name"]))
		1:
			if player != null and is_instance_valid(player):
				player.hp = maxf(1.0, player.hp - 1.0)
				player.hp_changed.emit(player.hp)
			Stats.buff_atk_pct += 0.2
			toast("Blood Tithe: +20% ATK this run")
		2:
			var rid2: String = ITEMS.roll_choices(Stats.relics, rng, 1)[0]
			Stats.add_relic(rid2)
			toast("Mahzan's Gamble: " + String(ITEMS.DB[rid2]["name"]))
		3:
			if Stats.relics.is_empty():
				toast("You have nothing to pawn, warrior")
			else:
				var rid3: String = Stats.relics[rng.randi_range(0, Stats.relics.size() - 1)]
				Stats.remove_relic(rid3)
				Stats.earn_souls(10)
				_souls_l()
				_ach("pawn1")
				toast("Pawned %s for +10 souls" % String(ITEMS.DB[rid3]["name"]))
				if rid3 == "tulang_kesatria" and squire_ref != null and is_instance_valid(squire_ref):
					_souls(squire_ref.global_position, 8, Color(0.9, 0.85, 0.5))
					squire_ref.queue_free()
					squire_ref = null
		4:
			if Stats.souls < _soul_cost(5):
				toast("Not enough souls (need 5)")
			else:
				Stats.souls -= _soul_cost(5)
				_count_deal()
				_souls_l()
				vials = 2
				_vial_btn()
				toast("Satchel filled — 2 ⚗ vials")
		5:
			if Stats.mahzan_debt <= 0.0:
				toast("Your ledger is clean, warrior")
			elif Stats.souls < _soul_cost(15):
				toast("Not enough souls (need 15)")
			else:
				Stats.souls -= _soul_cost(15)
				_count_deal()
				_souls_l()
				Stats.mahzan_debt = 0.0
				_ach("clear_ledger")
				toast("Debt settled — Max HP restored")
		6:
			if Stats.curse_dmg <= 0.0:
				toast("You carry no pacts to shed, warrior")
			elif Stats.souls < _soul_cost(8):
				toast("Not enough souls (need 8)")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				Stats.curse_dmg = maxf(0.0, Stats.curse_dmg - 0.3)
				Stats.curse_xp = maxf(0.0, Stats.curse_xp - 0.5)
				toast("Curse eaten — the obelisk's hold weakens")
		7:
			if Stats.souls < _soul_cost(8):
				toast("Not enough souls (need 8)")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				Stats.reroll_extra += 1
				toast("Kismet Thread — every draft gains a second reroll")
		8:
			if Stats.souls < _soul_cost(6):
				toast("Not enough souls (need 6)")
			else:
				Stats.souls -= _soul_cost(6)
				_count_deal()
				_souls_l()
				Stats.buff_xp_pct += 0.3
				toast("Pale Pawn — +30% XP this run")
		9:
			if Stats.souls < _soul_cost(5):
				toast("Not enough souls (need 5)")
			else:
				var opts: Array = []
				for wid in WDB.POOL:
					if wid != Stats.weapon_id:
						opts.append(wid)
				if opts.is_empty():
					toast("Mahzan has no blade worth your souls")
				else:
					Stats.souls -= _soul_cost(5)
					_count_deal()
					_souls_l()
					var nid: String = String(opts[rng.randi() % opts.size()])
					player.equip_weapon(nid)
					_refresh_hud_weapon()
					Stats.save_game()
					Sfx.play("levelup")
					toast("Bone Lottery pays out — %s" % String(WDB.get_w(nid)["name"]))
		10:
			if Stats.souls < _soul_cost(3):
				toast("Mahzan demands three souls — you lack the coin")
			else:
				var tpool: Array = []
				for rid9 in ITEMS.DB:
					if int(ITEMS.DB[rid9]["rarity"]) <= 1 and not Stats.relics.has(rid9):
						tpool.append(rid9)
				if tpool.is_empty():
					toast("His trove is picked clean — your souls return")
				else:
					Stats.souls -= _soul_cost(3)
					_count_deal()
					_souls_l()
					var rid10: String = String(tpool[rng.randi() % tpool.size()])
					Stats.add_relic(rid10)
					Stats.save_game()
					Sfx.play("shrine")
					toast("Fool's Trove — " + String(ITEMS.DB[rid10]["name"]))
		11:
			if Stats.souls < _soul_cost(2):
				toast("Mahzan's secrets are not free")
			else:
				var unseen: Array = []
				for l2 in LORE_LINES:
					if not Stats.lore_seen.has(l2):
						unseen.append(l2)
				if unseen.is_empty():
					toast("He has no more secrets to sell")
				else:
					Stats.souls -= _soul_cost(2)
					_count_deal()
					_souls_l()
					var sl: String = String(unseen[rng.randi() % unseen.size()])
					Stats.lore_seen.append(sl)
					Stats.save_game()
					toast("Mahzan whispers: '" + sl + "'")
		12:
			if Stats.souls < _soul_cost(9):
				toast("Mahzan demands nine — not a drop less")
			else:
				Stats.souls -= _soul_cost(9)
				_count_deal()
				_souls_l()
				Stats.buff_maxhp_pct += 0.1
				player.hp += Stats.get_stat("max_hp") - Stats.get_stat("max_hp") / 1.1
				Sfx.play("shrine")
				toast("BLOOD VELVET — +10% Max HP")
		13:
			if Stats.souls < _soul_cost(12):
				toast("Twelve souls for a spare life — death isn't cheap, Kael")
			else:
				Stats.souls -= _soul_cost(12)
				_count_deal()
				_souls_l()
				Stats.revive_left += 1
				Sfx.play("shrine")
				toast("LAST RITES — the Ferryman will look the other way once")
		14:
			if Stats.souls < _soul_cost(4):
				toast("Four souls, Kael — insurance isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				trap_wrapped += 2
				Sfx.play("shrine")
				toast("PEARL INSURANCE — your next two trap hits do nothing")
		15:
			if Stats.souls < _soul_cost(8):
				toast("Eight souls — the deep doesn't dredge cheap")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				var jpool := ["clamheart", "pressure_suit", "tidebound_anklet", "keelhook", "deaf_cap", "soul_creel", "drowned_oar", "kings_ledger"]
				var open_j: Array = jpool.filter(func(j): return not Stats.relics.has(j))
				var jrid := String(open_j[rng.randi() % open_j.size()]) if not open_j.is_empty() else "berkat_pandai_besi"
				Stats.add_relic(jrid)
				Sfx.play("shrine")
				toast("ABYSSAL JAR — dredged up " + String(ITEMS.DB[jrid]["name"]))
		16:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the song isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				sirensong_deal = true
				Sfx.play("shrine")
				toast("SIRENSONG — this floor's elites sing a richer tune")
		17:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the rotgut's not cheap")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				Stats.buff_maxhp_pct += 0.15
				rotgut_drunk = true
				if player != null and is_instance_valid(player):
					player.refresh_stats()
				Sfx.play("shrine")
				toast("ROTGUT — the room spins. +15% Max HP this floor")
		18:
			if Stats.souls < _soul_cost(2):
				toast("Two souls — the ale's not free")
			else:
				Stats.souls -= _soul_cost(2)
				_count_deal()
				_souls_l()
				Stats.buff_speed_pct += 0.08
				pale_drunk = true
				if player != null and is_instance_valid(player):
					player.refresh_stats()
				Sfx.play("shrine")
				toast("PALE ALE — your feet forget the floor. +8% speed")
		19:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — even mystery meat costs")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				var meat := rng.randi() % 4
				if meat == 0:
					Stats.buff_atk_pct += 0.15
					toast("MYSTERY MEAT — it was war flesh: +15% ATK")
				elif meat == 1:
					Stats.buff_maxhp_pct += 0.15
					rotgut_drunk = true
					toast("MYSTERY MEAT — it was grave fat: +15% Max HP this floor")
				elif meat == 2:
					Stats.buff_speed_pct += 0.08
					pale_drunk = true
					toast("MYSTERY MEAT — it was eel: +8% speed this floor")
				else:
					Stats.buff_armor += 2
					tithe_armor += 2.0
					toast("MYSTERY MEAT — it was shell: +2 Armor this floor")
				if player != null and is_instance_valid(player):
					player.refresh_stats()
				Sfx.play("shrine")
		20:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the lark doesn't sing free")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				mudlark = true
				Sfx.play("shrine")
				toast("MUDLARK — every floor's end pays +1 soul for the run")
		21:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the bilge isn't free")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				if player != null and is_instance_valid(player):
					player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.3)
					player.hp_changed.emit(player.hp)
				Stats.add_xp(10)
				Sfx.play("shrine")
				toast("BILGE WINE — it burns. It works.")
		22:
			if Stats.souls < _soul_cost(5):
				toast("Five souls — the compass points where it likes")
			else:
				Stats.souls -= _soul_cost(5)
				_count_deal()
				_souls_l()
				for ri_c in range(info.ranges.size()):
					discovered[ri_c] = true
				_update_minimap()
				Sfx.play("shrine")
				toast("GLASS COMPASS — the floor lies bare before you")
		23:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the shanty doesn't sing for free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				Stats.cd_reduction += 0.1
				Sfx.play("shrine")
				toast("SEA SHANTY — your skills flow with the tide")
		24:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the prayer isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				Stats.buff_atk_pct += 0.12
				if player != null:
					player.refresh_stats()
					Sfx.play("shrine")
				toast("DECK PRAYER — the deck itself leans into your swing")
		25:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the oil isn't free")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				lantern_oil = true
				Sfx.play("shrine")
				toast("LANTERN OIL — the wicks burn brighter (+50% mending)")
		26:
			if Stats.souls < _soul_cost(5):
				toast("Five souls — the crow takes no credit")
			else:
				Stats.souls -= _soul_cost(5)
				_count_deal()
				_souls_l()
				crows_share = true
				Sfx.play("shrine")
				toast("CROW'S SHARE — every floor you clear pays the crow and the crow pays you")
		27:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the table isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				var mh_gm: float = Stats.get_stat("max_hp")
				player.hp = minf(mh_gm, player.hp + mh_gm * 0.4)
				player.hp_changed.emit(player.hp)
				Sfx.play("shrine")
				toast("GRAVE MEAL — the dead set your table")
		28:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the crow eats first")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				Stats.soul_gain_pct += 0.2
				Sfx.play("shrine")
				toast("CROW'S FEAST — every scrap is yours now (+20% souls)")
		29:
			if Stats.souls < _soul_cost(5):
				toast("Five souls — the dice only roll for paying customers")
			else:
				Stats.souls -= _soul_cost(5)
				_count_deal()
				if rng.randf() < 0.5:
					Stats.earn_souls(12)
					_souls_l()
					Sfx.play("souls")
					toast("EVEN — the dice pay out +12 souls")
					dice_wins += 1
					if dice_wins >= 3:
						_ach("dice3")
				else:
					_souls_l()
					Sfx.play("deny")
					toast("ODD — the dice keep your stake")
		30:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the ledger doesn't open free")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				if quest_idx < quest_steps.size():
					var stq: Dictionary = quest_steps[quest_idx]
					_quest_event(String(stq["kind"]), 1)
					Sfx.play("souls")
					toast("DEBT SCRIBE — Mahzan inks a line forward")
				else:
					toast("No line to ink")
		31:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the cheer isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				vials += 1
				_vial_btn()
				if player != null and is_instance_valid(player):
					player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.15)
					player.hp_changed.emit(player.hp)
				Sfx.play("heal")
				toast("GRAVE CHEER — bottom's up, buyer")
		32:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the rum's not free")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				Stats.buff_atk_pct += 0.05
				if player != null and is_instance_valid(player):
					player.refresh_stats()
				Sfx.play("shrine")
				toast("TAR RUM — it burns going down and coming out swinging")
		33:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the galley doesn't do charity")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				if player != null and is_instance_valid(player):
					player.silence_t = 0.0
					player.root_t = 0.0
					player.weak_t = 0.0
					player.hp = minf(Stats.get_stat("max_hp"), player.hp + 1.0)
					player.hp_changed.emit(player.hp)
				Sfx.play("shrine")
				toast("GALLEY SCRAPS — grease, salt, freedom")
		35:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the gilt isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				vials = mini(vials + 1, 3 if wide_satchel else 2)
				player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.3)
				Sfx.play("shrine")
				toast("GILDED PROVISIONS — you eat like an admiral tonight")
		39:
			if Stats.souls < _soul_cost(5):
				toast("Five souls — the knot isn't free")
			else:
				Stats.souls -= _soul_cost(5)
				_count_deal()
				_souls_l()
				omen_cd_add -= 1.0
				Sfx.play("shrine")
				toast("SALT BOND — the cord pulls your skills along")
		45:
			if Stats.souls < _soul_cost(8):
				toast("Eight souls — the ledger isn't free")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				Stats.buff_aspd += 0.15
				Sfx.play("shrine")
				toast("HASTE LEDGER — the books close fast tonight")
		47:
			if Stats.souls < _soul_cost(8):
				toast("Eight souls — the ledger isn't free")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				soul_ledger = true
				Stats.soul_gain_pct += 0.2
				Sfx.play("shrine")
				toast("SOUL LEDGER — every soul counts double-ish")
		51:
			if Stats.souls < _soul_cost(7):
				toast("Seven souls — the wager isn't free")
			else:
				Stats.souls -= _soul_cost(7)
				_count_deal()
				_souls_l()
				grim_wager = true
				Stats.buff_atk_pct += 0.12
				Stats.buff_crit += 0.08
				Sfx.play("shrine")
				toast("GRIM WAGER — Mahzan backs your blade")
		50:
			if Stats.souls < _soul_cost(6):
				toast("Six souls — the doubt isn't free")
			else:
				Stats.souls -= _soul_cost(6)
				_count_deal()
				_souls_l()
				sv_doubt = true
				Stats.buff_atk_pct += 0.15
				Stats.buff_maxhp_pct -= 0.05
				Sfx.play("shrine")
				toast("SOVEREIGN'S DOUBT — doubt sharpens the blade")
		49:
			if Stats.souls < _soul_cost(5):
				toast("Five souls — the dowry isn't free")
			else:
				Stats.souls -= _soul_cost(5)
				_count_deal()
				_souls_l()
				salt_dowry = true
				Stats.soul_gain_pct += 0.12
				Sfx.play("shrine")
				toast("SALT DOWRY — the drowned pay their bride-price")
		48:
			if Stats.souls < _soul_cost(8):
				toast("Eight souls — the silk isn't free")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				Stats.dodge += 0.12
				Sfx.play("shrine")
				toast("GRAVE SILK — funeral cloth for the nimble")
		46:
			if Stats.souls < _soul_cost(7):
				toast("Seven souls — the annuity isn't free")
			else:
				Stats.souls -= _soul_cost(7)
				_count_deal()
				_souls_l()
				Stats.buff_xp_pct += 0.15
				Sfx.play("shrine")
				toast("GRAVE ANNUITY — the dead pay dividends")
		44:
			if Stats.souls < _soul_cost(8):
				toast("Eight souls — the toll isn't free")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				Stats.buff_crit += 0.12
				Sfx.play("shrine")
				toast("TOLL OF MARROW — paid in red, repaid in red")
		43:
			if Stats.souls < _soul_cost(14):
				toast("Fourteen souls — bonds aren't cheap")
			else:
				Stats.souls -= _soul_cost(14)
				_count_deal()
				_souls_l()
				Stats.buff_armor += 3
				Sfx.play("shrine")
				toast("GRAVE BOND — your marrow, mortgaged and plated")
		42:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the scrip isn't free")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				Stats.buff_xp_pct += 0.1
				Sfx.play("shrine")
				toast("BONE SCRIP — your lessons paid in marrow")
		41:
			if Stats.souls < _soul_cost(12):
				toast("Twelve souls — heavy coin for heavy hide")
			else:
				Stats.souls -= _soul_cost(12)
				_count_deal()
				_souls_l()
				Stats.buff_armor += 2
				Sfx.play("shrine")
				toast("IRON PURSE — your purse clanks like plate")
		40:
			if Stats.souls < _soul_cost(8):
				toast("Eight souls for a clean berth")
			else:
				Stats.souls -= _soul_cost(8)
				_count_deal()
				_souls_l()
				var mh_ := Stats.get_stat("max_hp")
				player.hp = mh_
				player.hp_changed.emit(mh_)
				Stats.current_hp = mh_
				Sfx.play("quest")
				toast("SALT HAVEN — mended to the gunwales")
		38:
			if Stats.souls < _soul_cost(3):
				toast("Three souls — the toll isn't free")
			else:
				Stats.souls -= _soul_cost(3)
				_count_deal()
				_souls_l()
				keelmans_toll = true
				for f in get_tree().get_nodes_in_group("enemies"):
					if f.get("state") != "dead" and not bool(f.get("is_boss")):
						f.speed *= 0.92
				Sfx.play("shrine")
				toast("KEELMAN'S TOLL — the tide drags their feet")
		37:
			if Stats.souls < _soul_cost(6):
				toast("Six souls — the tide won't bet on credit")
			else:
				Stats.souls -= _soul_cost(6)
				_count_deal()
				if rng.randf() < 0.5:
					Stats.earn_souls(12)
					toast("SALT WAGER — the tide pays double")
				else:
					toast("SALT WAGER — the tide drinks your stake")
				_souls_l()
				Sfx.play("souls")
		36:
			if Stats.souls < _soul_cost(4):
				toast("Four souls — the ink is worth more")
			else:
				Stats.souls -= _soul_cost(4)
				_count_deal()
				_souls_l()
				for ri_c in range(info.ranges.size()):
					discovered[ri_c] = true
				_update_minimap()
				Sfx.play("shrine")
				toast("GILDED MAP — the floor drawn in dead men's ink")
		34:
			if Stats.souls < _soul_cost(2):
				toast("Two souls — even rats cost something")
			else:
				Stats.souls -= _soul_cost(2)
				_count_deal()
				_souls_l()
				rat_ration = true
				Sfx.play("shrine")
				toast("RAT RATION — wrapped in wax, mostly rat")

	if player != null and is_instance_valid(player):
		player.hp = minf(player.hp, Stats.get_stat("max_hp"))
		player.refresh_stats()
		player.hp_changed.emit(player.hp)
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.7, 1.0))


func _on_keel_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 15
	_say([{"who": "mahzan", "text": "A Keelstone, buyer — sailors swore on these before the deep took them. The stone still honors the trade."}],
		[{"text": "Drop Anchor — pay 4 souls: the floor's foes lose 15% speed"},
		{"text": "Raise Sail — pay 4 souls: +10% speed for you this run"},
		{"text": "Scuttle Loot — pay 3 souls: +25% XP this run"},
		{"text": "Keelhaul — pay 5 souls: drag every foe within 3 tiles to your feet"},
		{"text": "Keel Prayer — pay 2 souls: the first trap that catches you MENDS you"},
		{"text": "Hull Net — pay 4 souls: +30% XP for the rest of this run"},
		{"text": "Rigging Plates — pay 3 souls: +1 Armor this run"},
		{"text": "Fair Wind — pay 3 souls: +15% souls for the rest of this run"},
		{"text": "Gangway Toll — pay 3 souls: this floor's dead are worth +15% XP"},
		{"text": "Deck Fuel — pay 4 souls: your dash recharges 40% faster"},
		{"text": "Tar Seal — pay 4 souls: mend 25% HP and scrub chill, root, rust"},
		{"text": "Timber Shiver — pay 3 souls: this floor's dead lose −10% HP"},
		{"text": "Hull Bonus — pay 3 souls: every elite this floor pays +1 soul extra"},
		{"text": "Bilge Iron — pay 4 souls: iron strakes for your hull — +2 Armor this floor"},
		{"text": "Rope Ladder — pay 3 souls: climb the rigging — −1s on every skill charge"},
		{"text": "Powder Toll — pay 4 souls: your blade hums with gunpowder — +15% ATK this floor"},
		{"text": "Ballast Beads — pay 4 souls: +1 Armor and the dead notice you −20% later"},
		{"text": "Line Splice — pay 3 souls: rigged steady — the dead's throws push you half as far"},
		{"text": "Hull Wick — pay 4 souls: tarred hemp in your grip — +15% attack speed this run"},
		{"text": "Tar Knots — pay 3 souls: ropework lessons — your blows shove them 30% further this floor"},
		{"text": "Salt Sheath — pay 3 souls: the blade remembers its salt — +8% crit this floor"},
		{"text": "Knotwork — pay 3 souls: laced hand-wrapping — +5% dodge this floor"},
		{"text": "Marlin Spike — pay 3 souls: a sailor's point between the ribs — +10% speed this floor"},
		{"text": "Watch Bell — pay 4 souls: the bell rings their approach — foes telegraph +15% slower this floor"},
		{"text": "Hull Pitch — pay 6 souls: hot tar on your planks — +1 Armor this floor"},
		{"text": "Knot of Refuge — pay 5 souls: a slipknot in your step — +10% dodge this floor"},
		{"text": "Grommet's Due — pay 3 souls: the ring bites the rope — +8% ATK this floor"},
		{"text": "Sheave Toll — pay 4 souls: the pulley's lesson — +10% XP this floor"},
		{"text": "Rigging Rites — pay 3 souls: every line tuned tight — +8% attack speed this floor"},
		{"text": "Deck Psalm — pay 5 souls: the hull's hymn calms the dead — foes −12% damage this floor"},
		{"text": "Rope Tackle — pay 4 souls: oiled blocks, faster feet — dash recharges 20% faster this floor"},
		{"text": "Splice Line — pay 3 souls: the line feeds you its slack — +6% speed this floor"},
		{"text": "Rigging Rest — pay 4 souls: the lines slacken in your favor — mend 15%, skills recharge 15% faster this floor"},
		{"text": "Hull Count — pay 4 souls: the carpenter counts you among the planks — +10% Max HP this floor"},
		{"text": "Capstan Oil — pay 4 souls: greased drum, fast hands — +10% attack speed this floor"},
		{"text": "Sheet Bend — pay 3 souls: the line gives where you lean — +8% dodge this floor"},
		{"text": "Crew's Grog — pay 4 souls: the barrel waters the whole watch — +10% XP this floor"},
		{"text": "Bosun's Ration — pay 3 souls: salted hardtack for the watch — +8% ATK this floor"},
		{"text": "Walk away"}])


func _keel_deal(idx: int) -> void:
	if idx == 37:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ration isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		bosuns_ration = true
		Stats.buff_atk_pct += 0.08
		Sfx.play("shrine")
		toast("BOSUN'S RATION — salt beef and spite")
		return
	if idx == 38:
		toast("The stone settles — the sea keeps its bargains")
		return
	if idx == 36:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the grog isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_xp_pct += 0.10
		crews_grog = true
		Sfx.play("shrine")
		toast("CREW'S GROG — the barrel waters the watch")
		return
	if idx == 35:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the bend isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		sheet_bend = true
		Stats.dodge += 0.08
		Sfx.play("shrine")
		toast("SHEET BEND — the line gives where you lean")
		return
	if idx == 34:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the oil isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		capstan_oil = true
		Stats.buff_aspd += 0.1
		Sfx.play("shrine")
		toast("CAPSTAN OIL — greased drum, fast hands")
		return
	if idx == 33:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the count isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		hull_count = true
		Stats.buff_maxhp_pct += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("HULL COUNT — the planks hold you")
		return
	if idx == 32:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the rigging isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		rigging_rest = true
		Stats.cd_reduction += 0.15
		if player != null and is_instance_valid(player):
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.15)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("RIGGING REST — the lines slacken in your favor")
		return
	if idx == 31:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the splice isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		splice_line = true
		Stats.buff_speed_pct += 0.06
		Sfx.play("shrine")
		toast("SPLICE LINE — the cord carries you")
		return
	if idx == 30:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the tackle isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		rope_tackle = true
		for sid3 in skill_cd.keys():
			skill_cd[sid3] = float(skill_cd[sid3]) * (0.8 if sid3 == "dash" else 1.0)
		Sfx.play("shrine")
		toast("ROPE TACKLE — the blocks run free")
		return
	if idx == 29:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the psalm isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		deck_psalm = true
		for pf in get_tree().get_nodes_in_group("enemies"):
			if pf.get("state") != "dead" and not pf.get("is_boss"):
				pf.dmg = int(maxi(1, floorf(float(pf.dmg) * 0.88)))
		Sfx.play("shrine")
		toast("DECK PSALM — the hymn settles over the hull")
		return
	if idx == 28:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the rites aren't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		rigging_rites = true
		Stats.buff_aspd += 0.08
		Sfx.play("shrine")
		toast("RIGGING RITES — every line tuned tight")
		return
	if idx == 28:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the throne's touch isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		Stats.buff_atk_pct += 0.06
		crowns_hand = true
		Sfx.play("shrine")
		toast("CROWN'S HAND — the throne blesses your blade")
		return
	if idx == 27:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the pulley isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		sheave_toll = true
		Stats.buff_xp_pct += 0.1
		Sfx.play("shrine")
		toast("SHEAVE TOLL — the rigging teaches its trade")
		return
	if idx == 26:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ring isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		grommets_due = true
		Stats.buff_atk_pct += 0.08
		Sfx.play("shrine")
		toast("GROMMET'S DUE — the rigging lends its bite")
		return
	if idx == 25:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the knot isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		knot_refuge = true
		Stats.dodge += 0.1
		Sfx.play("shrine")
		toast("KNOT OF REFUGE — your step slips the hook")
		return
	if idx == 24:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the tar pot isn't free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		hull_pitch = true
		Stats.buff_armor += 1
		Sfx.play("shrine")
		toast("HULL PITCH — hot tar on your planks")
		return
	if idx == 23:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the bell isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		watch_bell = true
		for f in get_tree().get_nodes_in_group("enemies"):
			if not f.get("is_boss"):
				f.windup_t = float(f.windup_t) * 1.15
		Sfx.play("shrine")
		toast("WATCH BELL — you hear every blow coming")
		return
	if idx == 22:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the spike isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		marlin_spike = true
		Stats.buff_speed_pct += 0.1
		Sfx.play("shrine")
		toast("MARLIN SPIKE — quick feet on a slick deck")
		return
	if idx == 21:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the knots aren't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.dodge += 0.05
		knotwork = true
		Sfx.play("shrine")
		toast("KNOTWORK — your hands learn to slip the blows")
		return
	if idx == 20:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the sheath isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		salt_sheath = true
		Stats.buff_crit += 0.08
		Sfx.play("shrine")
		toast("SALT SHEATH — the edge hums with old brine")
		return
	if idx == 19:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the knots aren't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		tar_knots = true
		Sfx.play("shrine")
		toast("TAR KNOTS — every strike lands like a boom-swing")
		return
	if idx == 18:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the wick isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_aspd += 0.15
		Sfx.play("shrine")
		toast("HULL WICK — your arm moves like a lit fuse")
		return
	if idx == 17:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the splice isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		line_splice = true
		if player != null and is_instance_valid(player):
			player.kb_in = 0.5
		Sfx.play("shrine")
		toast("LINE SPLICE — you stand like the mast")
		return
	if idx == 16:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the beads aren't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		ballast_beads = true
		Stats.buff_armor += 1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("BALLAST BEADS — heavy pockets, light footfall")
		return
	if idx == 15:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the powder's not free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		powder_toll = true
		Stats.buff_atk_pct += 0.15
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("POWDER TOLL — your edge smells of fire")
		return
	if idx == 14:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ropes aren't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		for rk_ in skill_cd.keys():
			skill_cd[rk_] = maxf(0.0, float(skill_cd[rk_]) - 1.0)
		Sfx.play("shrine")
		toast("ROPE LADDER — up the rigging you go")
		return
	if idx == 13:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the iron's priced by the keel")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 2
		Sfx.play("shrine")
		toast("BILGE IRON — the ship lends you its strakes")
		return
	if idx == 9:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the fuel isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		dash_fuel = true
		Sfx.play("shrine")
		toast("DECK FUEL — your feet won't stop now (dash −40% recharge)")
		return
	if idx == 11:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the timbers aren't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		timber_shiver = true
		Sfx.play("shrine")
		toast("TIMBER SHIVER — the floor's dead creak a little lighter")
		return
	if idx == 12:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the bonus isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		hull_bonus = true
		Sfx.play("shrine")
		toast("HULL BONUS — this floor's elites pay a dividend")
		return
	if idx == 10:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the tar isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.25)
			for deb9 in ["chill_t", "root_t", "rust_t"]:
				player.set(deb9, 0.0)
			player.hp_changed.emit(player.hp)
		_quest_event("keelstone")
		Sfx.play("shrine")
		toast("TAR SEAL — hot pitch knits your hull")
		return
	if idx == 8:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the toll isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		gangway = true
		Sfx.play("shrine")
		toast("GANGWAY TOLL — the floor's dead carry fatter lessons")
		return
	if idx == 7:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the wind isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.soul_gain_pct += 0.15
		Sfx.play("shrine")
		toast("FAIR WIND — the deep pays a fifteenth better")
		return
	if idx == 6:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the rigging isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("RIGGING PLATES — +1 Armor, lashed to your hull")
		return
	if idx == 0:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the anchor isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		for f in get_tree().get_nodes_in_group("enemies"):
			if f.get("state") != "dead" and not bool(f.get("is_boss")):
				f.speed *= 0.85
		Sfx.play("shrine")
		toast("ANCHOR DROPPED — the dead drag their feet")
	elif idx == 1:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the sail isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_speed_pct += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("SAILS RAISED — swifter on the tide")
	elif idx == 2:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the loot isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_xp_pct += 0.25
		Sfx.play("shrine")
		toast("LOOT SCUTTLED — +25% XP this run")
	elif idx == 3:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the keel doesn't haul free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		var hauled := 0
		for fh in get_tree().get_nodes_in_group("enemies"):
			if fh.get("state") == "dead" or bool(fh.get("is_boss")):
				continue
			var hd: float = fh.global_position.distance_to(player.global_position)
			var reach: float = 3.0 * info.tile * (1.5 if undertow_grip else 1.0)
			if hd < reach and hd > 1.0 * info.tile:
				var hdir: Vector3 = player.global_position - fh.global_position
				hdir.y = 0
				fh.global_position += hdir.normalized() * (hd - 0.9 * info.tile)
				if Stats.relics.has("keel_mark"):
					fh.set("keel_marked", true)
				if Stats.relics.has("galley_whip"):
					fh.set("tender_t", 2.0)
				_quest_event("haul")
				hauled += 1
		if hauled >= 5:
			_ach("keelhaul5")
		Sfx.play("shrine")
		toast("KEELHAULED — %d foes dragged under the keel" % hauled)
	elif idx == 4:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the keel doesn't pray for free")
			return
		Stats.souls -= _soul_cost(2)
		_count_deal()
		_souls_l()
		keel_prayer = true
		Sfx.play("shrine")
		toast("KEEL PRAYER — the first trap will mend you")
	elif idx == 5:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the net isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_xp_pct += 0.3
		Sfx.play("shrine")
		toast("HULL NET — +30% XP this run")
	_quest_event("keelstone")


func _on_moonpool_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	if player != null and is_instance_valid(player):
		player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.3)
		player.hp_changed.emit(player.hp)
	for wi in range(2):
		_spawn_wisp_at(s.global_position + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.6, 0.6)) * info.tile)
	Stats.earn_souls(2)
	_souls_l()
	_quest_event("moonpool")
	moonpool_run += 1
	if moonpool_run >= 3:
		_ach("moondisciple")
	toast("MOONPOOL — cold light closes your wounds; freed wisps scatter")
	_damage_number(player.global_position + Vector3(0, 1.0 * info.tile, 0), "+30% HP • wisps freed", Color(0.7, 0.85, 1.1), true)


func _on_qm_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 17
	_say([{"who": "mahzan", "text": "A Quartermaster's Post, buyer — dead sailors' arms, all of it still sharp. Name your steel."}],
		[{"text": "Arm Me — pay 8 souls: a weapon drops from the hold"},
		{"text": "Hone the Crew — pay 4 souls: +10% ATK this run"},
		{"text": "Provisions — pay 3 souls: mend 25% HP"},
		{"text": "Rope Ration — pay 3 souls: +1 soul vial for the road"},
		{"text": "Chipped Compass — pay 4 souls: the post charts this floor for you"},
		{"text": "Powder Keg — pay 4 souls: your next 3 kills detonate on their neighbors"},
		{"text": "Splice Bonus — pay 3 souls: your next 5 kills this floor pay +1 soul each"},
		{"text": "Rope & Rum — pay 3 souls: +10% Speed and mend 20% HP"},
		{"text": "Tar Smear — pay 4 souls: +1 Armor, the tar slows the dead −10% this floor"},
		{"text": "Salt Pork — pay 3 souls: brined meat for the voyage — +15% Max HP this floor"},
		{"text": "Whistle Code — pay 4 souls: the crew calls the maneuvers — −2s on every skill charge"},
		{"text": "Deck Manifest — pay 3 souls: the crew logs every catch — +15% souls this floor"},
		{"text": "Powder Ward — pay 3 souls: powder-burned hands are steady hands — +10% ATK this run"},
		{"text": "Deck Rite — pay 4 souls: the bosun's blessing read over the hold — +1 Armor this run"},
		{"text": "Salt Scrip — pay 3 souls: the crew logs the lessons — +10% XP this floor"},
		{"text": "Grog Ration — pay 3 souls: a mug pulled from the bilge — mend 30%"},
		{"text": "Salt Chits — pay 4 souls: the crew's IOU honors the deep — +10% souls this run"},
		{"text": "Quarter's Stash — pay 5 souls: a tin from the post's own locker — +1 ⚗ vial, mend 15% HP"},
		{"text": "Bosun's Chit — pay 4 souls: the whistle buys fury — +10% ATK this floor"},
		{"text": "Ballast Check — pay 2 souls: the steward patches and pours — heal 20%, and a vial besides"},
		{"text": "Coil & Chit — pay 3 souls: the rope ledger teaches you to slip — +8% dodge this floor"},
		{"text": "Rope Allowance — pay 3 souls: the quartermaster lets out your line — +8% speed this floor"},
		{"text": "Watchman's Ration — pay 4 souls: hot grog from the crow's nest — mend 25%"},
		{"text": "Boatswain's Call — pay 3 souls: the whistle cuts the fog — +12% dodge this floor"},
		{"text": "Walk away"}])


func _qm_deal(idx: int) -> void:
	if idx == 24:
		toast("The post shutters its stores")
		return
	if idx == 23:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the whistle isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		boatswain_call = true
		Stats.dodge += 0.12
		Sfx.play("shrine")
		toast("BOATSWAIN'S CALL — the whistle cuts the fog")
		return
		toast("The post shutters its stores")
		return
	if idx == 22:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the ration isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.25)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("WATCHMAN'S RATION — hot grog from the crow's nest")
		return
	if idx == 21:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the line isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		rope_allowance = true
		Stats.buff_speed_pct += 0.08
		Sfx.play("shrine")
		toast("ROPE ALLOWANCE — your line runs long")
		return
	if idx == 20:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ledger isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		coil_chit = true
		Stats.dodge += 0.08
		Sfx.play("shrine")
		toast("COIL & CHIT — the rope teaches you to slip")
		return
	if idx == 19:
		if Stats.souls < _soul_cost(2):
			toast("Two souls — the stores aren't free")
			return
		Stats.souls -= _soul_cost(2)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.2)
			player.hp_changed.emit(player.hp)
		vials += 1
		_vial_btn()
		Sfx.play("shrine")
		toast("BALLAST CHECK — patched, and a vial for the road")
		return
	if idx == 18:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the chit isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		bosuns_chit = true
		Stats.buff_atk_pct += 0.1
		Sfx.play("shrine")
		toast("BOSUN'S CHIT — the whistle buys fury")
		return
	if idx == 17:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the stash isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		vials += 1
		_vial_btn()
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.15)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("QUARTER'S STASH — a tin for the road")
		return
	if idx == 16:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the chits aren't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.soul_gain_pct += 0.1
		Sfx.play("shrine")
		toast("SALT CHITS — the crew's paper is good coin down here")
		return
	if idx == 15:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ration isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		var mh2_ := Stats.get_stat("max_hp")
		player.hp = minf(mh2_, player.hp + mh2_ * 0.3)
		player.hp_changed.emit(player.hp)
		Stats.current_hp = player.hp
		Sfx.play("souls")
		toast("GROG RATION — bilge-fresh and burning")
		return
	if idx == 14:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the scrip isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		salt_scrip = true
		Stats.buff_xp_pct += 0.1
		Sfx.play("shrine")
		toast("SALT SCRIP — every lesson logged in salt")
		return
	if idx == 13:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the rite isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("DECK RITE — the hold answers the bosun's words")
		return
	if idx == 5:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the powder isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		powder_keg = 3
		Sfx.play("shrine")
		toast("POWDER KEG — your next three kills go off like a deck fire")
		return
	if idx == 6:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the splice isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		splice_kills = 5
		_quest_event("qm")
		Sfx.play("shrine")
		toast("SPLICE BONUS — the next five kills pay a splice share")
		return
	if idx == 12:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ward isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_atk_pct += 0.1
		Sfx.play("shrine")
		toast("POWDER WARD — the burns make you bolder")
		return
	if idx == 11:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the manifest isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		deck_manifest = true
		Stats.soul_gain_pct += 0.15
		Sfx.play("shrine")
		toast("DECK MANIFEST — everything gets counted")
		return
	if idx == 10:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the code isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		for wc_ in skill_cd.keys():
			skill_cd[wc_] = maxf(0.0, float(skill_cd[wc_]) - 2.0)
		Sfx.play("shrine")
		toast("WHISTLE CODE — orders you half remember")
		return
	if idx == 9:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the pork's not free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_maxhp_pct += 0.15
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.15)
			player.hp_changed.emit(player.hp)
			player.refresh_stats()
		Sfx.play("shrine")
		toast("SALT PORK — brine in the belly")
		return
	if idx == 8:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the tar pot isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 1
		tar_smear = true
		Sfx.play("shrine")
		toast("TAR SMEAR — the deck drinks their speed")
		return
	if idx == 7:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the rum's rationed")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.buff_speed_pct += 0.1
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.2)
			player.hp_changed.emit(player.hp)
			player.refresh_stats()
		Sfx.play("shrine")
		toast("ROPE & RUM — faster feet, fuller chest")
		return
	if idx == 4:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the compass isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		for ri_c in range(info.ranges.size()):
			discovered[ri_c] = true
		_update_minimap()
		Sfx.play("shrine")
		toast("CHIPPED COMPASS — the floor lies charted")
		return
	if idx == 3:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ration isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		vials += 1
		_vial_btn()
		Sfx.play("shrine")
		toast("ROPE RATION — +1 ⚗ vial tucked for the road")
		return
	if idx == 0:
		if Stats.souls < _soul_cost(8):
			toast("Eight souls — the quartermaster doesn't loan")
			return
		Stats.souls -= _soul_cost(8)
		_count_deal()
		_souls_l()
		spawn_weapon_drop(player.global_position + Vector3(0, 0, -0.6 * info.tile), WDB.roll_drop(rng, Stats.weapon_id))
		Sfx.play("shrine")
		toast("ARMED — steel from the hold")
	elif idx == 1:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the whetstone isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_atk_pct += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("HONED — +10% ATK this run")
	elif idx == 2:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the biscuit isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.25)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("PROVISIONS — the crew eats")
	_quest_event("qm")


func _on_siren_invoked(sh) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	sh.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 18
	_say([{"who": "mahzan", "text": "A Siren's Conch — put it to your ear and the sea sings back. Her songs all cost souls; the sea keeps accounts."}],
		[{"text": "Sea Chant — pay 5 souls: +12% Speed and +10% ATK this run"},
		{"text": "Dirge of the Drowned — pay 4 souls: +1 Armor, but your HP bleeds 15% now"},
		{"text": "Lullaby for Kael — pay 4 souls: mend 35% HP"},
		{"text": "Chorus Line — pay 3 souls: reset every skill cooldown"},
		{"text": "Shanty of Depths — pay 4 souls: +15% XP this run"},
		{"text": "Song of Rust — pay 3 souls: this floor's foes wade -10% speed"},
		{"text": "Final Verse — pay 5 souls: the dead strike 15% softer for the rest of this run"},
		{"text": "Cradle Deep — pay 5 souls: the dead sleep-walk —8% HP for the rest of this run"},
		{"text": "Storm Lull — pay 5 souls: the dead's strikes slow —15% windup this run"},
		{"text": "Encore Echo — pay 4 souls: +10% crit for the rest of this run"},
		{"text": "Echo Verse — pay 5 souls: your skills hum back 15% sooner this run"},
		{"text": "Chorus Cut — pay 4 souls: every kill this floor hums −0.5s off your longest charge"},
		{"text": "Final Overture — pay 5 souls: every charge rings full and ready, right now"},
		{"text": "Melody Ledger — pay 3 souls: every fifth note pays — each 5th kill +2 souls"},
		{"text": "Dirge Note — pay 3 souls: each kill's echo staggers the rest — near foes slowed 1s"},
		{"text": "Requiem Rest — pay 4 souls: the last verse mends what the sea broke — full mend, all ailments washed"},
		{"text": "Wake Whistle — pay 4 souls: a shanty whistled fast — +10% attack speed this run"},
		{"text": "Brine Hymn — pay 3 souls: the verse sticks to every kill — +1 soul per kill this floor"},
		{"text": "Low Verse — pay 4 souls: the bass note drags their arms — foes telegraph +10% slower this floor"},
		{"text": "Fathomsong — pay 3 souls: the depths hum you quieter — the dead notice you −15% later this floor"},
		{"text": "Drift Verse — pay 4 souls: a verse of floating steps — +8% dodge this floor"},
		{"text": "Pearl Octave — pay 5 souls: nacre rings in your wounds — orbs mend +50% this floor"},
		{"text": "Undertow Aria — pay 4 souls: the bass thins their bones — foes −8% HP this floor"},
		{"text": "Wake Chant — pay 5 souls: the water carries your step — +12% speed this floor"},
		{"text": "Salt Aria — pay 4 souls: the verse rings your pockets — +12% souls this floor"},
		{"text": "Salt Lullaby — pay 5 souls: her hush slows the dead's hands — foe windups +15% longer this floor"},
		{"text": "Second Verse — pay 6 souls: her refrain quickens your arm — +15% attack speed this floor"},
		{"text": "Chorus Deep — pay 4 souls: the deep verse pays its singers — +10% souls this floor"},
		{"text": "Harbor Verse — pay 4 souls: the song steadies your arm — +8% ATK this floor"},
		{"text": "Wake Verse — pay 3 souls: the chorus quickens your step — +8% speed this floor"},
		{"text": "Requiem Note — pay 4 souls: a note for the gone — +8% dodge this floor"},
		{"text": "Dirge Half — pay 3 souls: the low half-note drags the dead's stride — foes −10% speed this floor"},
		{"text": "Ballad of the Bilge — pay 4 souls: the chorus sings your lessons — +12% XP this floor"},
		{"text": "Walk away"}])


func _siren_deal(idx: int) -> void:
	if idx == 33:
		Stats.earn_souls(2)
		_souls_l()
		_quest_event("siren")
		Sfx.play("soul")
		toast("UNSUNG — you walk, and the conch pays +2 souls for your silence")
		return
	if idx == 32:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the ballad isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		bilge_ballad = true
		Stats.buff_xp_pct += 0.12
		Sfx.play("shrine")
		toast("BALLAD OF THE BILGE — the chorus sings your lessons")
		return
	if idx == 31:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the half-note isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		dirge_half = true
		Sfx.play("shrine")
		toast("DIRGE HALF — the dead's stride drags")
		return
	if idx == 30:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the note isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.dodge += 0.08
		requiem_note = true
		Sfx.play("shrine")
		toast("REQUIEM NOTE — a note for the gone")
		return
	if idx == 29:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the verse isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		wake_verse = true
		Stats.buff_speed_pct += 0.08
		Sfx.play("shrine")
		toast("WAKE VERSE — the chorus quickens your step")
		return
	if idx == 28:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the verse isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		harbor_verse = true
		Stats.buff_atk_pct += 0.08
		Sfx.play("shrine")
		toast("HARBOR VERSE — the song steadies your arm")
		return
	if idx == 27:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the chorus isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		chorus_deep = true
		Stats.soul_gain_pct += 0.1
		Sfx.play("shrine")
		toast("CHORUS DEEP — the verse pays its singers")
		return
	if idx == 26:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the verse isn't free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		second_verse = true
		Stats.buff_aspd += 0.15
		Sfx.play("shrine")
		toast("SECOND VERSE — her refrain quickens")
		return
	if idx == 25:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the hush isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		salt_lullaby = true
		for lf in get_tree().get_nodes_in_group("enemies"):
			if lf.get("state") != "dead" and not lf.get("is_boss"):
				lf.windup_t = float(lf.windup_t) * 1.15
		Sfx.play("shrine")
		toast("SALT LULLABY — the dead's hands slow")
		return
	if idx == 24:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the aria isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		salt_aria = true
		Stats.soul_gain_pct += 0.12
		Sfx.play("shrine")
		toast("SALT ARIA — the verse rings your pockets")
		return
	if idx == 23:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the chant isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		wake_chant = true
		Stats.buff_speed_pct += 0.12
		Sfx.play("shrine")
		toast("WAKE CHANT — the water carries your step")
		return
	if idx == 22:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the aria isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		undertow_aria = true
		for f2 in get_tree().get_nodes_in_group("enemies"):
			if not f2.get("is_boss"):
				f2.hp = float(f2.hp) * 0.92
				f2.hp_max = f2.hp
		Sfx.play("shrine")
		toast("UNDERTOW ARIA — the floor itself thins them")
		return
	if idx == 21:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the octave isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		pearl_octave = true
		Sfx.play("shrine")
		toast("PEARL OCTAVE — nacre rings in your wounds")
		return
	if idx == 20:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the verse isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		drift_verse = true
		Stats.dodge += 0.08
		Sfx.play("shrine")
		toast("DRIFT VERSE — you float where the blows aren't")
		return
	if idx == 19:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the depths don't hum for free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		fathomsong = true
		for f in get_tree().get_nodes_in_group("enemies"):
			if not f.get("is_boss"):
				f.aggro_range = float(f.aggro_range) * 0.85
		Sfx.play("shrine")
		toast("FATHOMSONG — the depths hum you quieter")
		return
	if idx == 18:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the verse isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		low_verse = true
		for f in get_tree().get_nodes_in_group("enemies"):
			if f.get("state") != "dead" and not bool(f.get("is_boss")):
				f.set("windup_t", float(f.get("windup_t")) * 1.1)
		Sfx.play("souls")
		toast("LOW VERSE — the undertow pulls their elbows")
		return
	if idx == 17:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the hymn isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		Stats.event_soul_bonus += 1
		brine_hymn = true
		Sfx.play("souls")
		toast("BRINE HYMN — every death this floor pays a soul")
		return
	if idx == 16:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the whistle isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_aspd += 0.1
		Sfx.play("shrine")
		toast("WAKE WHISTLE — the shanty runs double-time")
		return
	if idx == 15:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the rest isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = player.max_hp
			for ra_ in ["weak_t", "chill_t", "root_t", "venom_t", "silence_t", "rust_t"]:
				player.set(ra_, 0.0)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("REQUIEM REST — the deep lets you sleep a moment")
		return
	if idx == 14:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the dirge isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		dirge_note = true
		Sfx.play("shrine")
		toast("DIRGE NOTE — every death hums through the floor")
		return
	if idx == 13:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the ledger's ink isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		melody_ledger = true
		Sfx.play("shrine")
		toast("MELODY LEDGER — the fifth note always lands")
		return
	if idx == 12:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the overture isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		for fs_ in skill_cd.keys():
			skill_cd[fs_] = 0.0
		Sfx.play("shrine")
		toast("FINAL OVERTURE — every song at once")
		return
	if idx == 11:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the chorus wants its cut")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		chorus_cut = true
		Sfx.play("shrine")
		toast("CHORUS CUT — the song works while you kill")
		return
	if idx == 10:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the verse wants its fee")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		Stats.cd_reduction += 0.15
		Sfx.play("shrine")
		toast("ECHO VERSE — the song's refrain quickens your hands")
		return
	if idx == 9:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the echo isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_crit += 0.1
		if player != null and is_instance_valid(player):
			player.refresh_stats()
		Sfx.play("shrine")
		toast("ENCORE ECHO — the last note sharpens your blade")
		return
	if idx == 6:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the last verse isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		final_verse = true
		_quest_event("siren")
		Sfx.play("shrine")
		toast("FINAL VERSE — the dead sing softer now")
		return
	if idx == 8:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the lull isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		storm_lull = true
		Sfx.play("shrine")
		toast("STORM LULL — every strike you'll see coming, this whole run")
		return
	if idx == 7:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the cradle isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		cradle_deep = true
		_quest_event("siren")
		Sfx.play("shrine")
		toast("CRADLE DEEP — the dead walk half-asleep now")
		return
	if idx == 5:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the rust song isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		song_rust = true
		Sfx.play("shrine")
		toast("SONG OF RUST — the floor's dead drag their feet")
		return
	if idx == 4:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the shanty isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_xp_pct += 0.15
		Sfx.play("shrine")
		toast("SHANTY OF DEPTHS — +15% XP this run")
		return
	if idx == 0:
		var c0 := _soul_cost(5)
		if Stats.souls < c0:
			toast("Five souls — the sea's choir charges for the verse")
			return
		Stats.souls -= c0
		_souls_l()
		Stats.buff_speed_pct += 0.12
		Stats.buff_atk_pct += 0.1
		if player != null:
			player.refresh_stats()
		Sfx.play("shrine")
		toast("SEA CHANT — the rhythm of the tide is in your feet")
	elif idx == 1:
		var c1 := _soul_cost(4)
		if Stats.souls < c1:
			toast("Four souls — the dirge asks its own")
			return
		Stats.souls -= c1
		_souls_l()
		Stats.buff_armor += 1
		if player != null and is_instance_valid(player):
			player.hp = maxf(1.0, player.hp - Stats.get_stat("max_hp") * 0.15)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("DIRGE — iron in your ribs, salt in your blood")
	elif idx == 2:
		var c2 := _soul_cost(4)
		if Stats.souls < c2:
			toast("Four souls — lullabies are bought, not given")
			return
		Stats.souls -= c2
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.35)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("LULLABY — the sea rocks you to a kinder sleep")
	elif idx == 3:
		var c3 := _soul_cost(3)
		if Stats.souls < c3:
			toast("Three souls — the chorus still has a cover charge")
			return
		Stats.souls -= c3
		_souls_l()
		for sid in skill_cd:
			skill_cd[sid] = 0.0
		Sfx.play("shrine")
		toast("CHORUS — every song in you starts fresh")
	if idx == 8:
		var c8 := _soul_cost(4)
		if Stats.souls < c8:
			toast("Four souls — the encore isn't free")
			return
		Stats.souls -= c8
		_souls_l()
		Stats.buff_xp_pct += 0.1
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.2)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("ENCORE — the sea sings you back toward the light")
	_quest_event("siren")
	if int(quest_counts.get("siren", 0)) >= 4:
		_ach("choralist")


func _on_throne_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 16
	_say([{"who": "mahzan", "text": "A Throne's Offering, buyer — even drowned kings take tribute. Pay up; the crown is generous to its debtors."}],
		[{"text": "Tithe the Deep — pay 6 souls: +15% Max HP this run"},
		{"text": "Swear the Crown — pay 5 souls: your next elite kill pays +8 souls"},
		{"text": "Beg a Boon — pay 3 souls: a random common relic"},
		{"text": "Draw Blood — pay 3 souls: bleed for +20% ATK this floor"},
		{"text": "Court Physician — pay 4 souls: cleanse every curse and mend 30% HP"},
		{"text": "King's Pardon — pay 8 souls: your nemesis is forgiven and stops hunting you"},
		{"text": "Pawn's Ransom — pay 5 souls: every debuff is lifted and +1 vial"},
		{"text": "Sovereign's Toll — pay 4 souls: the crown underwrites your blade (+10% ATK this run)"},
		{"text": "Knight's Vigil — pay 4 souls: +1 Armor this run"},
		{"text": "Crown's Insight — pay 3 souls: the throne names this floor's omen"},
		{"text": "Court Summons — pay 4 souls: +15% XP this floor"},
		{"text": "Kneel Not — pay 5 souls: this floor's dead lose half their footing (kb resist)"},
		{"text": "Crown's Mercy — pay 6 souls: purge venom, chill, rust & roots — 3s untouchable"},
		{"text": "Royal Writ — pay 5 souls: the crown presses one page of your quest forward"},
		{"text": "Crown's Rest — pay 4 souls: mend 40% HP and the dead dawdle −10% this floor"},
		{"text": "Crown's Vigil — pay 5 souls: the King counts his stolen subjects — elites & bosses pay +3 souls this run"},
		{"text": "Crown's Decree — pay 6 souls: the court honors its debtors — elites drop a blade this run"},
		{"text": "Court Surgeon — pay 5 souls: royal medicine — mend half, and every ailment washed away"},
		{"text": "King's Hour — pay 5 souls: the court grants a moment — all skills recharge now"},
		{"text": "Royal Muster — pay 9 souls: plate and pride — +2 Armor this run"},
		{"text": "Vigil's Gage — pay 7 souls: the crown's shadow covers your step — +10% dodge this floor"},
		{"text": "Crown's Hush — pay 6 souls: the court's hush falls over you — foes notice you −20% later this floor"},
		{"text": "Vassal's Claim — pay 5 souls: the crown taxes its own — foes −10% HP this floor"},
		{"text": "Regal Favor — pay 6 souls: the court notices your deeds — +15% XP this floor"},
		{"text": "Court's Tally — pay 5 souls: the scribes weight your purse — +12% souls this floor"},
		{"text": "Royal Overlook — pay 5 souls: the court looks away — foes −10% damage this floor"},
		{"text": "Sovereign's Rest — pay 6 souls: the crown's own physician attends — mend 40%"},
		{"text": "Crown's Reprieve — pay 4 souls: a royal breath between strikes — skills recharge 12% faster this floor"},
		{"text": "Crown's Hand — pay 5 souls: the throne lays a finger on your blade — +6% ATK this floor"},
		{"text": "Court Fool — pay 3 souls: the jester mocks your enemies — foes −8% speed this floor"},
		{"text": "Walk away"}])


func _throne_deal(idx: int) -> void:
	if idx == 30:
		Stats.earn_souls(4)
		_souls_l()
		_quest_event("throne")
		Sfx.play("soul")
		toast("CLEAN HANDS — the crown pays +4 souls to the incorruptible")
		return
	if idx == 29:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the jester isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		court_fool = true
		_ach("fools_gold")
		for cf in get_tree().get_nodes_in_group("enemies"):
			if not cf.is_boss:
				cf.speed *= 0.92
		Sfx.play("shrine")
		toast("COURT FOOL — the jester mocks your enemies")
		return
	if idx == 27:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the court isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		crowns_reprieve = true
		Stats.cd_reduction += 0.12
		Sfx.play("shrine")
		toast("CROWN'S REPRIEVE — a royal breath")
		return
	if idx == 26:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the physician isn't free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.4)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("SOVEREIGN'S REST — the crown's physician attends")
		return
	if idx == 25:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the court isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		royal_overlook = true
		Sfx.play("shrine")
		toast("ROYAL OVERLOOK — the court looks away")
		for f in get_tree().get_nodes_in_group("enemies"):
			f.dmg = int(maxf(1.0, float(f.dmg) * 0.9))
		return
	if idx == 24:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the tally isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		courts_tally = true
		Stats.soul_gain_pct += 0.12
		Sfx.play("shrine")
		toast("COURT'S TALLY — the scribes weigh heavy")
		return
	if idx == 23:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the court's regard isn't free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		regal_favor = true
		Stats.buff_xp_pct += 0.15
		Sfx.play("shrine")
		toast("REGAL FAVOR — the court notes your name")
		return
	if idx == 22:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the crown's tax isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		vassals_claim = true
		for vf in get_tree().get_nodes_in_group("enemies"):
			if vf.get("state") != "dead" and not vf.get("is_boss"):
				vf.hp *= 0.9
				vf.hp_max = vf.hp
		Sfx.play("shrine")
		toast("VASSAL'S CLAIM — the court's own are taxed")
		return
	if idx == 21:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the hush isn't free")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		crowns_hush = true
		for f2 in get_tree().get_nodes_in_group("enemies"):
			if not f2.get("is_boss"):
				f2.aggro_range *= 0.8
		Sfx.play("shrine")
		toast("CROWN'S HUSH — the court looks the other way")
		return
	if idx == 20:
		if Stats.souls < _soul_cost(7):
			toast("Seven souls — the gage isn't free")
			return
		Stats.souls -= _soul_cost(7)
		_count_deal()
		_souls_l()
		vigils_gage = true
		Stats.dodge += 0.1
		Sfx.play("shrine")
		toast("VIGIL'S GAGE — you walk where the spears don't look")
		return
	if idx == 19:
		if Stats.souls < _soul_cost(9):
			toast("Nine souls — the muster isn't free")
			return
		Stats.souls -= _soul_cost(9)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 2
		Sfx.play("shrine")
		toast("ROYAL MUSTER — the court outfits its champion")
		return
	if idx == 18:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the King's time isn't cheap")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		for sk in skill_cd:
			skill_cd[sk] = 0.0
		Sfx.play("shrine")
		toast("KING'S HOUR — the court's timepiece is yours")
		return
	if idx == 17:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the surgeon doesn't work for thanks")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.5)
			for cs_ in ["weak_t", "chill_t", "root_t", "venom_t", "silence_t", "rust_t"]:
				player.set(cs_, 0.0)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("COURT SURGEON — stitched like royalty")
		return
	if idx == 16:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — decrees don't come cheap")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		crowns_decree = true
		Sfx.play("shrine")
		toast("CROWN'S DECREE — the dead deliver their iron")
		return
	if idx == 15:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the vigil isn't cheap")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		crowns_vigil = true
		Sfx.play("shrine")
		toast("CROWN'S VIGIL — every title falls to your ledger")
		return
	if idx == 14:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the crown's cushions aren't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.4)
			player.hp_changed.emit(player.hp)
		crowns_rest = true
		Sfx.play("shrine")
		toast("CROWN'S REST — the throne grants a moment's peace")
		return
	if idx == 13:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the writ's ink isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		if quest_idx < quest_steps.size():
			var rw: Dictionary = quest_steps[quest_idx]
			_quest_event(String(rw["kind"]), 1)
		Sfx.play("quest")
		toast("ROYAL WRIT — one errand advances under the crown's seal")
		return
	if idx == 12:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the crown's mercy is dear")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.venom_t = 0.0
			player.chill_t = 0.0
			player.rust_t = 0.0
			player.silence_t = 0.0
			player.root_t = 0.0
			player.invuln = 3.0
		Sfx.play("shrine")
		toast("CROWN'S MERCY — the sea forgives, briefly")
		return
	if idx == 11:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the crown doesn't shove cheap")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		kneel_not = true
		Sfx.play("shrine")
		toast("KNEEL NOT — every shove lands twice as hard this floor")
		return
	if idx == 10:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the summons isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		court_summons = true
		Sfx.play("shrine")
		toast("COURT SUMMONS — the dead owe you more schooling this floor")
		return
	if idx == 7:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the crown doesn't lend cheap")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_atk_pct += 0.1
		Sfx.play("shrine")
		_quest_event("throne")
		toast("SOVEREIGN'S TOLL — the crown stamps your blade")
	if idx == 8:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the vigil isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		Stats.buff_armor += 1
		Sfx.play("shrine")
		_quest_event("throne")
		toast("KNIGHT'S VIGIL — the crown's plate weighs your shoulders")
		return
	if idx == 6:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — the ransom isn't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			for deb in ["weak_t", "chill_t", "root_t", "venom_t", "silence_t"]:
				player.set(deb, 0.0)
		vials += 1
		_vial_btn()
		Sfx.play("shrine")
		toast("PAWN'S RANSOM — clean blood, fresh vial")
		return
	if idx == 5:
		if Stats.souls < _soul_cost(8):
			toast("Eight souls — royal pardons don't come cheap")
			return
		if Stats.nemesis == "":
			toast("You bear no grudge — the crown is amused")
			return
		Stats.souls -= _soul_cost(8)
		_count_deal()
		_souls_l()
		Stats.nemesis = ""
		Sfx.play("shrine")
		toast("KING'S PARDON — the hunt is called off")
		return
	if idx == 4:
		if Stats.souls < _soul_cost(4):
			toast("Four souls — the court's leech isn't free")
			return
		Stats.souls -= _soul_cost(4)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.set("venom_t", 0.0)
			player.set("chill_t", 0.0)
			player.set("root_t", 0.0)
			player.set("silence_t", 0.0)
			player.hp = minf(Stats.get_stat("max_hp"), player.hp + Stats.get_stat("max_hp") * 0.3)
			player.hp_changed.emit(player.hp)
		Sfx.play("shrine")
		toast("COURT PHYSICIAN — bled clean and mended")
		return
	if idx == 0:
		if Stats.souls < _soul_cost(6):
			toast("Six souls — the crown's tithe isn't negotiable")
			return
		Stats.souls -= _soul_cost(6)
		_count_deal()
		_souls_l()
		Stats.buff_maxhp_pct += 0.15
		Sfx.play("shrine")
		toast("TITHE PAID — +15% Max HP this run")
	elif idx == 1:
		if Stats.souls < _soul_cost(5):
			toast("Five souls — oaths aren't free")
			return
		Stats.souls -= _soul_cost(5)
		_count_deal()
		_souls_l()
		crown_oath = true
		Sfx.play("shrine")
		toast("CROWN SWORN — your next elite kill pays +8 souls")
	elif idx == 2:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the crown doesn't beg")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		var bpool: Array = []
		for ridb in ITEMS.DB:
			if int(ITEMS.DB[ridb]["rarity"]) == 0 and not Stats.relics.has(ridb):
				bpool.append(ridb)
		var brid := String(bpool[rng.randi() % bpool.size()]) if not bpool.is_empty() else "berkat_pandai_besi"
		Stats.add_relic(brid)
		Sfx.play("shrine")
		toast("ROYAL BOON — the crown grants " + String(ITEMS.DB[brid]["name"]))
	elif idx == 3:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the crown's blade isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		if player != null and is_instance_valid(player):
			player.hp = maxf(1.0, player.hp * 0.75)
			player.hp_changed.emit(player.hp)
		Stats.buff_atk_pct += 0.2
		blood_drawn = true
		Sfx.play("shrine")
		toast("BLOOD DRAWN — +20% ATK until you descend")
	if idx == 9:
		if Stats.souls < _soul_cost(3):
			toast("Three souls — the crown's eye isn't free")
			return
		Stats.souls -= _soul_cost(3)
		_count_deal()
		_souls_l()
		var evname := "CLEAR WATER — no omen stirs this floor"
		for ename in ["blood_moon", "soul_rush", "fading_light", "echoing", "storm_cellar", "gilded_tides", "soul_drift", "grave_hunger", "giant_hall", "shrouded", "ossuary", "mirror_hall", "ashfall", "hungry_walls", "candlelit", "verdant", "bone_chorus", "wolfsbane", "sunken_tide", "low_tide", "glass_sea", "deep_current", "dread_tide", "starved_deep", "choir", "shell_game", "abyssal_hymn", "dead_calm", "dead_weight", "thin_veil", "low_water", "drift_tide", "soul_swarm", "gauntlet", "brisk", "shoal_tide", "salvage_tide", "gale_tide", "mercy_tide", "eel_tide", "swell_tide", "kelp_bed", "barnacle_bloom", "sodden", "bile_tide"]:
			if get(ename) == true:
				evname = ename.replace("_", " ").to_upper()
		Sfx.play("shrine")
		toast("CROWN'S INSIGHT — the floor wears: " + evname)
	_quest_event("throne")


func _on_shrine_invoked(s) -> void:
	shrine_used = true
	shrine_count += 1
	if shrine_count >= 10:
		_ach("pilgrim")
	if shrine_count >= 20:
		_ach("lantern_lit")
	s.consume()
	Sfx.play("shrine")
	var mlines := [
		"The old spirits still honor brave bones. Choose one blessing — no greed.",
		"Back so soon, warrior? The spirits remember a kindred soul. Choose.",
		"Every floor you survive, the Bone King's patience thins. Take a blessing.",
		"I was a king once too, you know. A kinder one. Choose your boon.",
	]
	_say(
		[{"who": "mahzan", "text": mlines[rng.randi_range(0, mlines.size() - 1)]}],
		[
			{"text": "War Blessing — +15% ATK this run"},
			{"text": "Iron Blessing — +1 Armor this run"},
			{"text": "Blood Blessing — fully heal HP"},
			{"text": "Soul Blessing — +12 souls for the Hall"},
			{"text": "Gale Blessing — +12% Speed this run"},
			{"text": "Vampiric Blessing — +8% Lifesteal this run"},
			{"text": "Fury Blessing — +10% Attack Speed this run"},
			{"text": "Titan's Blessing — +20% Max HP this run"},
			{"text": "Eagle's Eye — +12% Crit this run"},
			{"text": "Tempest Blessing — +20% Skill Recharge this run"},
			{"text": "Grave Tithe — +1 soul per kill this run"},
			{"text": "Tempo's Grace — combos linger 40% longer this run"},
			{"text": "Bone Wrap — the next trap hit does nothing (stacks)"},
			{"text": "Lucky Net — every tenth soul you earn pays +1"},
			{"text": "Deeproot — every urn spills +1 soul"},
			{"text": "Still Waters — traps doze 40% longer"},
			{"text": "Bone Veil — the first hit each floor does nothing"},
			{"text": "Tide's Toll — all soul gains +20%"},
			{"text": "Moonwrit — wisps you net pay +1 soul each"},
			{"text": "Barnacle Sense — disarm sleeping traps from half again as far"},
			{"text": "Brine Callus — +2 Armor while you're under half health"},
			{"text": "Deadweight — your HEAVY hits drag foes to half speed for 2s"},
			{"text": "Undertow Grip — your pulls reach half again as far"},
			{"text": "Lookout — the first sight of each foe kind pays +1 soul"},
			{"text": "Ironwood Hull — +1 Armor, −5% speed"},
			{"text": "Bosun's Mark — your crew swings a fifth harder"},
			{"text": "Wake Runner — +15% XP this run"},
			{"text": "Bosun's Ledger — every fifth kill each floor pays +1 soul"},
			{"text": "Quarterdeck — +8% skill recharge this run"},
			{"text": "Crow's Nest — +8% crit chance this run"},
			{"text": "Urnsworn — every urn spills +1 soul this run"},
			{"text": "Iron Gullet — soul vials mend 45% HP"},
			{"text": "Spirit Share — +10% souls from every source this run"},
			{"text": "Deep Water — +10% XP from every source this run"},
			{"text": "Crew's Oath — your squire bites +50% harder this run"},
			{"text": "Leech Line — strikes drink deep: +8% lifesteal this run"},
			{"text": "Sea Wisdom — +5% crit and +5% XP this run"},
			{"text": "Bloodwarm — the red orbs mend double this run"},
			{"text": "Deck Bones — the planking remembers: +2 Armor this run"},
			{"text": "Salt Shear — the slowed bleed deeper: +25% damage to them this run"},
			{"text": "Crow's Tithe — the small gods take less: +5% souls this run"},
			{"text": "Trade Wind — the floor hurries you on: +8% speed this run"},
			{"text": "Wide Satchel — the satchel stretches: carry +1 soul vial this run"},
			{"text": "Salt Hide — the brine cures your skin: +1 Armor, +5% Max HP this run"},
			{"text": "Storm-eye — the gale moves through you: +12% attack speed, +8% speed this run"},
			{"text": "Waxen Hull — caulked thick against the deep: +10% Max HP, −5% speed this run"},
			{"text": "Leech's Tithe — the old blood answers: +8% crit, +3% lifesteal this run"},
			{"text": "Iron Prow — the bow splits the sea: +1 Armor, +10% speed this run"},
			{"text": "Sharp Hull — barnacle blades in the prow: +10% crit, +1 Armor this run"},
			{"text": "Whale Lung — a deep-sea breath: dash recharges 25% faster this run"},
			{"text": "Gunnel Grip — white-knuckled on the rail: +15% attack speed, −5% speed this run"},
			{"text": "Fathom Eye — the deep teaches what the dark won't: +15% XP this run"},
			{"text": "Bulkhead — iron plates bolt to your ribs: +1 Armor, −5% attack speed this run"},
			{"text": "Overhang — the rigging hums overhead: skills recharge +10% sooner this run"},
			{"text": "Deckmaster — you own this deck: +8% speed, +5% attack speed this run"},
			{"text": "Full Hull — every plank sealed tight: +20% Max HP this run"},
			{"text": "Bosun's Fist — the old knuckle-trick: +5% crit this run"},
			{"text": "Salt Lamp — souls shine brighter in the dark: +15% souls this run"},
			{"text": "Crow's Toll — elites yield +50% XP this run"},
			{"text": "Pilgrim's Purse — the alms-bowl travels with you: +2 souls at each floor's start"},
			{"text": "Powder Ballast — shot and powder in the pockets: +1 Armor, +8% ATK this run"},
			{"text": "Slick Wake — you slide through the swell: +8% dodge this run"},
			{"text": "Salt Crust — barnacled ribs: +2 Armor, −10% speed this run"},
			{"text": "Shanty Lung — your skills charge −1s... but your Max HP −10%"},
			{"text": "Bilge Ledger — every kill pays +25% souls... but −10% XP"},
			{"text": "Crow's Gambit — +12% crit... but −5% dodge"},
			{"text": "Salt Veins — the brine runs in you: +8% lifesteal this run"},
			{"text": "Dead Wake — the deep teaches every stroke: +15% XP, −5% speed"},
			{"text": "Spare Oar — lean into the lean water: +5% dodge, +5% speed"},
			{"text": "Wake Prayer — the water reads your steps: +10% speed, +10% XP"},
			{"text": "Fathom Rope — the cord runs smooth: skills recharge 8% faster"},
			{"text": "Gullwing — light bones over dark water: +5% dodge, +5% XP"},
			{"text": "Salt Tow — the purse drags: +12% souls, −5% dodge"},
			{"text": "Deadlights — lamps over drowned water: +6% crit, +6% ATK"},
			{"text": "Coil Keeper — the rope's give is yours: +10% dodge, −5% ATK"},
			{"text": "Bilge Boarding — planks over your ribs: +1 Armor, −5% speed"},
			{"text": "Foam Crown — the sea lends a crest: +1 Armor, +5% souls"},
			{"text": "Brine Dividend — the purse swells thin: +20% souls, −10% Max HP"},
			{"text": "Rope Burn — raw palms, fast hands: +15% attack speed, −5% crit"},
			{"text": "Hanging Tide — slack-water step: +10% speed, +10% dodge, −10% souls"},
			{"text": "Capstan Chant — heavy verses turn the arms: +15% attack speed, −8% speed"},
			{"text": "Rope Soles — tar-and-twine underfoot: +12% speed, −5% dodge"},
			{"text": "Salt Scribe — every death tallied in your favor: +20% souls, −10% dodge"},
			{"text": "Kedge Whistle — the boatswain's tempo: +15% attack speed, −8% crit"},
			{"text": "Keel Ballast — stone in the hold: +2 Armor, −10% speed"},
			{"text": "Salt Tithing — the purse fills, the hands slow: +15% souls, skills +5% recharge"},
			{"text": "Hull Tithe — ironwood ribs for a price: +15% Max HP, −10% dodge"},
			{"text": "Keel Net — the trawl gathers what spills: +8% dodge, −5% speed"},
			{"text": "Galley Spice — hot meals, warm bones: +10% XP, −5% souls"},
			{"text": "Slip Knot — the knot gives, then bites: +6% dodge, +6% attack speed, −5% souls"},
			{"text": "Bosun's Purse — the whistle pays out: +10% souls, −5% XP"},
			{"text": "Deckman's Eye — the crow's perch lends its sight: +10% crit, −5% souls"},
			{"text": "Mizzen Step — the aft wind at your heels: +8% speed, +4% dodge"},
			{"text": "Bilge Wake — the hull's lessons wash over you: +10% XP, −5% souls"},
			{"text": "Galley Nets — the trawl's slack is yours: +6% dodge, +4% speed"},
			{"text": "Leech Bond — the eels lend their hunger: +5% lifesteal, −5% Max HP"},
			{"text": "Tar Grip — your palms stick to the haft: +1 Armor, +4% ATK"},
			{"text": "Foam Step — the deck barely touches your heels: +8% speed"},
			{"text": "Salt Pension — the drowned pay their arrears: +10% souls"},
			{"text": "Keel Hymn — the hull sings your lessons back: +12% XP"},
			{"text": "Rigger's Eye — you see the seams in every knot: +8% crit"},
			{"text": "Bilge Sense — you learn what sinks and what floats: +8% souls, +6% XP"},
			{"text": "Hull Wisdom — you read the planks under your feet: +1 Armor, +5% XP"},
			{"text": "Deck Psalm — the verse fills your purse: +8% souls, +4% dodge"},
			{"text": "Iron Verse — the hymn sharpens your hand: +8% ATK, −1 Armor"},
		]
	)


func _floor_intro_lines(boss_floor: bool) -> void:
	var lines: Array = []
	if Stats.floor_num == 1 and Stats.ng_plus > 0:
		lines = [
			{"who": "oracle", "text": "Kael — you came back. The torches were barely lit when you turned around."},
			{"who": "kael", "text": "I saw it blink, Oracle. The dark is deeper than one crown."},
			{"who": "mahzan", "text": "My best customer returns! The bones are sharper this time, friend — spend your blessings wisely."},
			{"who": "oracle", "text": "NG+%d — the depths remember you, and they are angrier." % Stats.ng_plus},
		]
	elif Stats.floor_num == 1:
		lines = [
			{"who": "oracle", "text": "Kael... you're awake. These depths belong to the Bone King now."},
			{"who": "kael", "text": "I didn't come down here to die, Oracle. Show me the way."},
			{"who": "oracle", "text": "Every five floors he waits on his throne. The spirit statues in the halls still listen — touch them and ask for a blessing."},
		]
	elif boss_floor:
		var tier := _boss_tier()
		var tline: String = String(tier["taunt"])
		if Stats.nemesis == "bone_king":
			tline = "I'VE ALREADY SPLIT YOUR SKULL ONCE, LITTLE THING. The throne remembers."
		lines = [
			{"who": "oracle", "text": String(tier["warn"])},
			{"who": "kael", "text": "Then he's dying again."},
			{"who": "raja", "text": tline},
		]
		if knight_ref != null and is_instance_valid(knight_ref):
			lines.append({"who": "knight", "text": "That crown has my name's dust on it, boy. Let me help you shake it loose."})
	elif Stats.floor_num == 2:
		lines = [
			{"who": "oracle", "text": "You breathe hard already, Kael. The first floor is only the dungeon's handshake."},
			{"who": "kael", "text": "Let it shake harder. I came for a throne, not a tour."},
			{"who": "oracle", "text": "Then learn this early: the dead here remember the living they once were. Pity them — and strike."},
		]
	elif Stats.floor_num == 3:
		lines = [
			{"who": "kael", "text": "Oracle... how do you know these halls so well?"},
			{"who": "oracle", "text": "I walked them when they were bright, Kael — long before the bone took the throne."},
		]
	elif Stats.floor_num == 20:
		lines = [
			{"who": "knight", "text": "The light dies differently past twenty floors — it burns slower, meaner."},
			{"who": "oracle", "text": "You're in the King's old hunting grounds now. Everything here remembers being prey."},
			{"who": "kael", "text": "Then let it remember being prey to me."},
		]
	elif Stats.floor_num == 16:
		lines = [
			{"who": "mahzan", "text": "Sixteen floors of dents and debt, buyer — you're my finest investment."},
			{"who": "kael", "text": "Investments sink too, Mahzan. Keep your rope loose."},
			{"who": "oracle", "text": "The merchant jokes because the alternative is listening — the wrecks are singing his name."},
		]
	elif Stats.floor_num == 8:
		lines = [
			{"who": "knight", "text": "Two wrecks down, and the water's learning your name, sir."},
			{"who": "kael", "text": "Let it learn it angry, Vane. I've no patience for polite seas."},
			{"who": "oracle", "text": "Anger floats, Kael — but it also sinks the careless."},
		]
	elif Stats.floor_num == 4:
		lines = [
			{"who": "mahzan", "text": "Buyer! You descend nicely. The drowned say the fourth floor is where the sea first tastes stone."},
			{"who": "kael", "text": "And what does the sea want with stone, Mahzan?"},
			{"who": "mahzan", "text": "What it wants with everything, friend — to wear it down until only debts remain."},
		]
	elif Stats.floor_num == 5:
		lines = [
			{"who": "oracle", "text": "The first crown waits ahead — a Bone King, forged from the dead who knelt last."},
			{"who": "kael", "text": "Then I kneel to nothing. Let him try me."},
			{"who": "oracle", "text": "Careful, Kael. His court remembers how you fought the first four floors."},
		]
	elif Stats.floor_num == 6 and Stats.ng_plus >= 1:
		lines = [
			{"who": "vane", "text": "Back again, knight? The first court remembers how you broke it."},
			{"who": "kael", "text": "Tell it to keep the throne warm, Aldric. The crown's still mine to crack."},
			{"who": "oracle", "text": "Both of you walk circles the King can see — but cannot yet close."},
		]
	elif Stats.floor_num == 6:
		lines = [
			{"who": "vane", "text": "Faster now, knight — the King grows nervous when a challenger outlives the first court."},
			{"who": "kael", "text": "You're with me the rest of the way down, then?"},
			{"who": "vane", "text": "Until the last stone falls, Aldric's debt follows the one who carries it."},
		]
	elif Stats.floor_num == 7:
		lines = [
			{"who": "oracle", "text": "One throne shattered. He rebuilds it deeper, out of angrier bones."},
			{"who": "kael", "text": "Then I keep swinging until there are no thrones left."},
		]
	elif Stats.floor_num == 8:
		lines = [
			{"who": "oracle", "text": "Do you hear it? Two courts deep now — his heralds mark your footfalls and count."},
			{"who": "kael", "text": "Let them count. I'll give them a number worth fearing."},
		]
	elif Stats.floor_num == 9:
		lines = [
			{"who": "oracle", "text": "The walls stop pretending to be a crypt down here. This is the Abyss — the dungeon's own grave."},
			{"who": "kael", "text": "Then it's fitting. I brought a shovel."},
		]
	elif Stats.floor_num == 10:
		lines = [
			{"who": "mahzan", "text": "A second court, buyer! The Ember King's hall — mind the floor, it remembers fire."},
			{"who": "kael", "text": "I've bled on worse. Open the way."},
			{"who": "mahzan", "text": "Spoken like a man who's already paid his entry. Good — my ledger loves a regular."},
		]
	elif Stats.floor_num == 11:
		lines = [
			{"who": "kael", "text": "The air down here tastes like old coins, Oracle."},
			{"who": "oracle", "text": "That's the Queen's treasury floor, Kael — Aldric drowned it in gold before he buried it."},
			{"who": "mahzan", "text": "Coin for the dead, steel for the living. I approve of this arrangement."},
		]
	elif Stats.floor_num == 12:
		lines = [
			{"who": "oracle", "text": "Mahzan whispers that you fight beautifully. He roots for you — he's bored of skeletons."},
			{"who": "kael", "text": "Tell him to keep the blessings coming, then."},
		]
	elif Stats.floor_num == 17:
		lines = [
			{"who": "mahzan", "text": "Seventeen floors, little customer. Most heroes are in jars by now."},
			{"who": "kael", "text": "Most heroes didn't have your prices to keep them honest."},
			{"who": "oracle", "text": "Careful, Kael — the deep listens when you joke."},
		]
	elif Stats.floor_num == 13:
		lines = [
			{"who": "oracle", "text": "You climbed out of the drowned vaults richer, Kael — but the Abyss below the vaults is not so easily paid."},
			{"who": "kael", "text": "Then I'll keep climbing. Debt collectors never stop halfway."},
			{"who": "mahzan", "text": "The Abyss doesn't sell, buyer — it only lends, and the interest is legs."},
		]
	elif Stats.floor_num == 14:
		lines = [
			{"who": "kael", "text": "Oracle — the halls whisper back down here. Are they yours?"},
			{"who": "oracle", "text": "Not all of them, Kael. Some of them are his."},
		]
	elif Stats.floor_num == 15 and Stats.ng_plus >= 2:
		lines = [
			{"who": "oracle", "text": "Your third descent, Kael — the halls rearrange themselves around your name now."},
			{"who": "mahzan", "text": "And business triples! Repeat customers are the backbone of every shop."},
			{"who": "kael", "text": "Let them rearrange. I know the way by heart now."},
		]
		if vane_floors > 0:
			lines.append({"who": "knight", "text": "A heart that knows the way is a compass, boy. Mine still points at the throne."})
	elif Stats.floor_num == 15:
		lines = [
			{"who": "raja", "text": "FIFTEEN STEPS, LITTLE SLICER. The throne grows restless — I can feel your blade through the stone."},
			{"who": "oracle", "text": "He's watching you now, Kael. Not through eyes — through the weight of every crown his dead still wear."},
			{"who": "kael", "text": "Then give him a good show."},
		]
		if vane_floors > 0:
			lines.append({"who": "knight", "text": "Let the old bones watch, boy. We'll give them a war worth remembering."})
	elif Stats.floor_num == 16:
		lines = [
			{"who": "oracle", "text": "Halfway to his deepest hall. The air itself is starting to hate you."},
			{"who": "kael", "text": "Good. Let it try to stop me."},
		]
	elif Stats.floor_num == 19:
		lines = [
			{"who": "mahzan", "text": "Psst — buyer. The King keeps a ledger of every soul that falls here. Your name has its own page now."},
			{"who": "kael", "text": "Good. When I take his crown, the ledger closes."},
			{"who": "oracle", "text": "Careful, swordsman. The dead below read that ledger too — and they are starting to learn your name."},
		]
		if vane_floors > 0:
			lines.append({"who": "knight", "text": "Let them learn it, then. It will be the last word they ever speak."})
	elif Stats.floor_num == 18:
		lines = [
			{"who": "knight", "text": "I died on a floor like this, Kael. The dark does not forgive — it only waits."},
			{"who": "kael", "text": "Then we'll make it keep waiting."},
			{"who": "oracle", "text": "The Abyss does not end, Kael — it only agrees to be walked."},
		]
	elif Stats.floor_num == 22:
		lines = [
			{"who": "mahzan", "text": "Twenty-two floors, Kael. I have watched a hundred climb this far — and I collected debts from every one of them."},
			{"who": "kael", "text": "Then collect mine too. I'll pay it in the King's own coin."},
			{"who": "raja", "text": "BOLD WORDS, LITTLE SLICER. FIVE STEPS MORE AND WE SETTLE THE LEDGER."},
		]
	elif Stats.floor_num == 21:
		lines = [
			{"who": "oracle", "text": "Even I don't know what waits below the twenty-fifth. No soul has returned to tell it."},
			{"who": "kael", "text": "Then I'll be the first to come back and tell you."},
		]
	elif Stats.floor_num == 23 and Stats.ng_plus >= 1:
		lines = [
			{"who": "kael", "text": "Oracle — you never said how you ended up in that stone."},
			{"who": "oracle", "text": "...I was his court's last honest voice, Kael. The King buried me where my counsel couldn't reach his crown."},
			{"who": "oracle", "text": "Every floor you clear digs me a little closer to free. That is all I will say of it."},
			{"who": "kael", "text": "Then hold on. I'm two floors from his throne."},
		]
	elif Stats.floor_num == 23:
		lines = [
			{"who": "raja", "text": "KAEL. THE HALL BELOW IS MINE — THE LAST DOOR BEFORE THE THRONE."},
			{"who": "kael", "text": "Then polish the crown, Aldric. I'm coming for it."},
			{"who": "oracle", "text": "Careful — he's never needed to speak until now. That he answers means he is watching."},
		]
	elif Stats.floor_num == 20 and Stats.ng_plus >= 1:
		lines = [
			{"who": "oracle", "text": "His Heralds ride with you now, Kael — every floor they announce your title to the dead."},
			{"who": "kael", "text": "Let them. The dead already know my name."},
			{"who": "mahzan", "text": "A returning customer AND an entourage! Business is booming."},
		]
	elif Stats.floor_num == 24:
		lines = [
			{"who": "oracle", "text": "One floor below waits the throne beneath all thrones. He knows you're coming, Kael."},
			{"who": "kael", "text": "Tell him to keep the crown warm."},
			{"who": "mahzan", "text": "Twenty-four floors of carnage. Even I feel... almost... sentimental."},
		]
		if vane_floors > 0:
			lines.append({"who": "knight", "text": "Whatever waits below, Kael — it will remember the night it met us."})
	elif Stats.floor_num == 27 and Stats.ng_plus >= 1:
		lines = [
			{"who": "kael", "text": "The crown's mine, Oracle. So why does the water keep rising?"},
			{"who": "oracle", "text": "Because the dungeon doesn't end at the throne, Kael — the throne is only where it stopped being honest."},
			{"who": "raja", "text": "MY WRECK HAS NO BOTTOM, KAEL. NEITHER DOES YOUR DEBT."},
			{"who": "kael", "text": "Then I'll keep paying in bones."},
		]
	elif Stats.floor_num == 28:
		lines = [
			{"who": "knight", "text": "Twenty-eight floors, Kael. I lost count of my debts around the tenth."},
			{"who": "kael", "text": "You stopped owing me floors ago, Vane. You stay because you choose to."},
			{"who": "knight", "text": "...Aye. First choice I've made in three hundred years."},
			{"who": "oracle", "text": "Then make it count, both of you — the King's reach grows long down here."},
		]
	elif Stats.floor_num == 29 and Stats.ng_plus >= 2:
		lines = [
			{"who": "mahzan", "text": "Third descent, little sailor? Your ledger is longer than the King's now. Perhaps I should be charging HIM."},
			{"who": "kael", "text": "Keep the ink wet, Mahzan. I'm not done spending."},
			{"who": "oracle", "text": "The dungeon rewrites itself for you now, Kael — even the walls have started to watch."},
			{"who": "raja", "text": "TWICE BENEATH ME AND STILL HE CRAWLS. THE SEA LEARNS SLOWLY, KAEL — BUT IT LEARNS."},
		]
	elif Stats.floor_num == 4:
		lines = [
			{"who": "oracle", "text": "The omens sharpen here, Kael — every pact you swear tilts the whole descent."},
			{"who": "kael", "text": "Then I'll swear the ones that cut deepest going the other way."},
			{"who": "mahzan", "text": "An oath is just a deal you haven't read the fine print of yet, buyer."},
		]
	elif Stats.floor_num == 26:
		lines = [
			{"who": "oracle", "text": "The throne is close now, Kael — the water itself kneels here."},
			{"who": "kael", "text": "Good. Let it kneel a while longer — I'm not finished with it."},
			{"who": "mahzan", "text": "Twenty-six floors of receipts, buyer — you'd be amazed what your account's worth now."},
		]
	elif Stats.floor_num == 30 and Stats.ng_plus >= 1:
		lines = [
			{"who": "oracle", "text": "Thirty floors. Below the charts, below the hymns — even my sight thins here."},
			{"who": "kael", "text": "Then walk blind with me, Oracle. I've gotten good at it."},
			{"who": "knight", "text": "Blind he says, and walks straighter than any knight I served."},
			{"who": "raja", "text": "COME, KAEL. THE LAST PAGE WAS ALWAYS MINE TO WRITE — BUT YOU MAY HOLD THE PEN A MOMENT LONGER."},
		]
	elif Stats.nemesis != "" and not nemesis_warned:
		nemesis_warned = true
		lines = [
			{"who": "oracle", "text": "Kael — %s walks these halls again. The one that ended you last descent." % Stats.nemesis_name},
			{"who": "kael", "text": "Then the ledger and I both have a page to close."},
		]
	_biomes_run[String(biome.get("name", ""))] = true
	if _biomes_run.size() >= 6:
		_ach("cart6")
	elif not _biomes_seen.get(String(biome.get("name", "")), false):
		_biomes_seen[String(biome.get("name", ""))] = true
		match String(biome.get("name", "")):
			"Catacombs":
				lines = [
					{"who": "oracle", "text": "The Catacombs go deeper every year — as if the earth is making room."},
					{"who": "kael", "text": "Then it can make room for one more king. Me."},
				]
			"Ember Crypt":
				lines = [
					{"who": "oracle", "text": "The Ember Crypt — they burned the dead here, before the dead refused to stay burned."},
					{"who": "kael", "text": "Then I'll give them a second cremation."},
				]
			"Frozen Deep":
				lines = [
					{"who": "oracle", "text": "The Frozen Deep. Aldric's soldiers marched in and never thawed."},
					{"who": "kael", "text": "Cold doesn't scare me, Oracle. Crowns do."},
				]
			"Verdant Ruin":
				lines = [
					{"who": "oracle", "text": "The Verdant Ruin — my old gardens. Even dead, they keep growing."},
					{"who": "kael", "text": "Then something in this place still remembers you."},
				]
			"Marrow Marsh":
				lines = [
					{"who": "oracle", "text": "The Marrow Marsh — the court's refuse pit. Bones dissolve here into something that still remembers being people."},
					{"who": "kael", "text": "Keep your wits, Oracle. A marsh is still just a floor."},
					{"who": "mahzan", "text": "Watch the ground, buyer — the Marsh collects walkers for next century's walls."},
				]
			"Sunken Reliquary":
				lines = [
					{"who": "oracle", "text": "The Sunken Reliquary — the drowned treasury. Every gold piece down here is a soul the King never paid."},
					{"who": "mahzan", "text": "Ah, the old vaults. Half my inventory washes up down here, buyer."},
					{"who": "kael", "text": "Then I'll collect what's owed — coin by coin."},
				]
			"The Abyss":
				lines = [
					{"who": "oracle", "text": "The Abyss isn't a place, Kael. It's the hole the kingdom fell through."},
					{"who": "kael", "text": "Then watch me climb back out of it."},
				]
		if knight_ref != null and is_instance_valid(knight_ref) and not lines.is_empty() and VANE_BIOME.has(String(biome.get("name", ""))):
			lines.append({"who": "knight", "text": String(VANE_BIOME[String(biome.get("name", ""))])})
	elif Stats.floor_num > 1 and rng.randf() < 0.35:
		var tips := [
			"Those floor spikes are alive — learn their rhythm before stepping.",
			"Not all chests are chests. The fanged ones are mimics — and they're hungry.",
			"Elites glow crimson. Don't let them surround you.",
			"An unbroken kill streak — a combo. Music to the Bone King's ears.",
			"This kingdom was mine once, Kael. Before the dark took the throne.",
			"Red orbs mend flesh — the dead still owe you a few favors.",
			"Mahzan trades blessings for attention. He misses being worshipped.",
			"The deeper you go, the stronger his throne grows. So must you.",
			"A Quartermaster's Post still sells steel — the dead keep their inventory honest.",
			"The Siren's Conch sings for souls, not coin. Choose a verse you can afford.",
			"Saltghasts blink, Kael. Swing at where they land, never where they were.",
			"A Guthook bites slow but bites deep — its fifth swing pays you back in blood.",
			"Feral things feed on the falling. Kill them before their pack thins, or after it is gone.",
			"When the drift tide runs, the purses sink deeper. Walk heavier; collect more.",
			"Mahzan's songs cost souls — his silences cost more. Walk away when the price is wrong.",
			"Anchors, Kael — the sea's own argument for staying in one place.",
			"A fathomless purse buys fathomless bruises — I keep both ledgers, boy.",
			"The rusted ones wade slow. Do not waste your hurry on them.",
			"Keelbound things cannot be pushed. Plant your feet and trade, or walk around.",
			"The beaked ones never linger, Kael — wait for the hop, then answer.",
			"A rusted blade heals with oil — the corrosive bites do not last forever.",
			"Souls gather faster in wrecked waters. When the tide gives, take it all.",
		]
		lines = [{"who": "oracle", "text": tips[rng.randi_range(0, tips.size() - 1)]}]
	if lines.is_empty():
		return
	if boss_floor:
		dlg_pending_choice = 3
		_say(lines, [
			{"text": "Defy the King — +25% ATK, but he rises ENRAGED"},
			{"text": "Approach in silence — fight him on your terms"},
		])
	else:
		if lines.is_empty():
			var evline := ""
			if blood_moon:
				evline = "Blood moons make them bolder — and richer prey, Kael."
			elif soul_rush:
				evline = "The dead exhale. Catch what they leave behind."
			elif fading_light:
				evline = "The lanterns are dying down here — strike faster than the dark."
			elif echoing:
				evline = "The walls repeat your magic. Use it."
			elif storm_cellar:
				evline = "Something above is furious — keep your feet light."
			elif gilded_tides:
				evline = "Even death flushes gold tonight. Open everything."
			elif soul_drift:
				evline = "Souls drift loose tonight — gather them like fireflies."
			elif grave_hunger:
				evline = "The graves are hungrier than usual. Watch for wisps."
			elif giant_hall:
				evline = "The dead remember being giants. Mind the reach."
			elif shrouded:
				evline = "The map dies here, Kael. Trust your feet instead."
			elif ossuary:
				evline = "Ossuary night — even the walls are made of the fallen."
			elif mirror_hall:
				evline = "A mirror hall, Kael. Every soul is followed by its reflection."
			elif ashfall:
				evline = "Ash falls from a fire that never stops burning. Every kill pays in full."
			elif hungry_walls:
				evline = "The walls breed the dead tonight, Kael. Feed them, or join them."
			elif candlelit:
				evline = "Someone lit every wick in the deep. The dead shrink from the light — cut quickly."
			elif verdant:
				evline = "Green creeps over the bones, Kael. Even the dungeon forgets to be dead sometimes."
			elif bone_chorus:
				evline = "Hear it? The dead are singing war-songs. Find the choir-masters before the chorus swells."
			elif low_tide:
				evline = "The tide's pulled back, swordsman — every drowned purse is lying open. Gather fast; the water never stays gone."
			elif glass_sea:
				evline = "Calm water, sharp blades, Kael. The sea forgives nothing tonight — don't you either."
			elif deep_current:
				evline = "The current runs toward you, swordsman — everything in these halls knows your name now."
			elif dread_tide:
				evline = "The Abyss is breathing, Kael — it exhales souls tonight, and its children are eager."
			elif starved_deep:
				evline = "The dark down here is starving, swordsman — its wisps grow fat while its dead grow bold."
			elif choir:
				evline = "Hear it, swordsman — the choir below rehearses your funeral song. Their aim is... inspired."
			elif abyssal_hymn:
				evline = "One voice beneath the rest, Kael — a hymn that turns your legs to lead. But the dead pay in full tonight."
			elif dead_calm:
				evline = "Flat water, Kael — even the traps have fallen asleep. Walk soft; it's a mercy that won't last."
			elif dead_weight:
				evline = "The drowned cling to your purse tonight, Kael — every soul comes light, but the killing pays rich."
			elif sunken_tide:
				evline = "The water is rising through the graves, Kael — the drowned will come slow, but they come rich."
			elif wolfsbane:
				evline = "All claws, Kael — the pack has claimed this floor. Watch the flanks; hounds die easy but arrive together."
			elif thin_veil:
				evline = "The veil is threadbare tonight, Kael — you can almost see their old lives on them. They strike truer too."
			elif low_water:
				evline = "The tide has drawn back, Kael — the dead drag through the shallows, slow and sorry. Harvest them gently."
			elif drift_tide:
				evline = "Souls drift deep tonight, Kael — the drowned sink lower, but their purses swell on the way down."
			elif soul_swarm:
				evline = "The wisps ride the dead tonight, Kael — every blade you lay frees one. Harvest them kindly."
			elif gauntlet:
				evline = "They mean to make a proving of you tonight, Kael — the dead fight harder and teach more. Earn both."
			elif brisk:
				evline = "The tide runs brisk tonight, Kael — even the dead feel it in their bones. Your step will answer."
			elif shoal_tide:
				evline = "The water kneels to you tonight, Kael — the dead must wade while you walk light. Use their shallows."
			elif salvage_tide:
				evline = "The wrecks give up their gold tonight, Kael — what the sea hoarded, she scatters. Scavenge well."
			elif gale_tide:
				evline = "A gale rides the tide tonight, Kael — everything quickens, dead and living alike. Keep your footing."
			if evline != "":
				lines = [{"who": "oracle", "text": evline}]
		_say(lines)


# ---------------- minimap ----------------

func _map_pos(wp: Vector3, sc: float) -> Vector2:
	return Vector2((wp.x - info["min_x"]) * sc - 3.0, (wp.z - info["min_z"]) * sc - 3.0)


func _build_minimap() -> void:
	if not ui.has("map_view"):
		return
	var mv: Control = ui.map_view
	for c in mv.get_children():
		c.queue_free()
	map_dots.clear()
	var xs: float = info["max_x"] - info["min_x"]
	var zs: float = info["max_z"] - info["min_z"]
	if xs < 0.1 or zs < 0.1:
		ui.map.visible = false
		return
	ui.map.visible = not shrouded
	var sc: float = minf(130.0 / xs, 178.0 / zs)
	map_room_rects.clear()
	for ri7 in info.ranges.size():
		var r: Dictionary = info.ranges[ri7]
		var rc := ColorRect.new()
		rc.color = Color(0.32, 0.3, 0.42, 0.9) if discovered.has(ri7) else Color(0.10, 0.09, 0.13, 0.5)
		rc.position = Vector2((r["x0"] - info["min_x"]) * sc, (r["z1"] - info["min_z"]) * sc)
		rc.size = Vector2(maxf((r["x1"] - r["x0"]) * sc, 4.0), maxf((r["z0"] - r["z1"]) * sc, 4.0))
		mv.add_child(rc)
		map_room_rects[ri7] = rc
	if info.get("chest") != null:
		var cd := ColorRect.new()
		cd.color = Color(1.0, 0.8, 0.2)
		cd.size = Vector2(5, 5)
		cd.position = _map_pos(info.chest.global_position, sc)
		mv.add_child(cd)
	# penanda altar (cyan), batu lore (ungu), dan tujuan akhir lantai (emas besar)
	if shrine_ref != null and is_instance_valid(shrine_ref):
		var sd := ColorRect.new()
		sd.color = [Color(1.0, 0.8, 0.3), Color(0.45, 0.65, 1.0), Color(1.0, 0.2, 0.15), Color(1.0, 0.55, 0.15), Color(0.55, 0.75, 1.0), Color(1.0, 0.5, 0.1), Color(0.95, 0.85, 0.3), Color(0.4, 0.55, 1.0), Color(0.7, 0.95, 0.25), Color(0.85, 0.6, 0.3), Color(0.35, 0.95, 0.85), Color(0.4, 0.85, 1.0), Color(0.5, 0.7, 1.05), Color(0.65, 0.25, 0.95), Color(0.75, 0.85, 1.05), Color(0.6, 0.9, 0.45), Color(0.85, 0.45, 0.9)][shrine_kind]
		sd.size = Vector2(5, 5)
		sd.position = _map_pos(shrine_ref.global_position, sc)
		mv.add_child(sd)
	if lore_ref != null and is_instance_valid(lore_ref):
		var ld := ColorRect.new()
		ld.color = Color(0.75, 0.55, 1.0)
		ld.size = Vector2(4, 4)
		ld.position = _map_pos(lore_ref.global_position, sc)
		mv.add_child(ld)
	var lr2: Dictionary = info.ranges[info.ranges.size() - 1]
	var xd := ColorRect.new()
	xd.color = Color(1.0, 0.85, 0.35)
	xd.size = Vector2(7, 7)
	xd.position = _map_pos(Vector3((lr2["x0"] + lr2["x1"]) * 0.5, 0, lr2["z1"] + 0.8 * info.tile), sc)
	mv.add_child(xd)
	var pd := ColorRect.new()
	pd.color = Color(1.0, 1.0, 1.0)
	pd.size = Vector2(6, 6)
	mv.add_child(pd)
	ui["map_pdot"] = pd
	pd.pivot_offset = Vector2(3, 3)
	var pdtw: Tween = pd.create_tween()
	pdtw.set_loops()
	pdtw.tween_property(pd, "scale", Vector2(1.7, 1.7), 0.7).set_trans(Tween.TRANS_SINE)
	pdtw.tween_property(pd, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	ui["map_scale"] = sc
	_update_minimap()


func _refresh_hud_weapon() -> void:
	if not ui.has("weapon_l"):
		return
	var wid := Stats.weapon_id
	if wid == "" or not WDB.DB.has(wid):
		ui.weapon_l.text = ""
		return
	var wlv: int = int(Stats.weapon_lv.get(wid, 1))
	var wname := String(WDB.DB[wid]["name"])
	ui.weapon_l.text = ("%s +%d" % [wname, wlv - 1]) if wlv > 1 else wname


func _update_minimap() -> void:
	if not ui.has("map_view") or not ui.map.visible or player == null or not is_instance_valid(player):
		return
	var sc: float = ui["map_scale"]
	ui.map_pdot.position = _map_pos(player.global_position, sc)
	for d in map_dots:
		if is_instance_valid(d):
			d.queue_free()
	map_dots.clear()
	for rid5 in discovered:
		var rr5: ColorRect = map_room_rects.get(int(rid5), null)
		if rr5 != null and is_instance_valid(rr5):
			rr5.color = Color(0.32, 0.3, 0.42, 0.9)
	for f in get_tree().get_nodes_in_group("enemies"):
		if not discovered.get(int(f.get("room_idx")), false) and int(f.get("room_idx")) >= 0:
			continue
		var d := ColorRect.new()
		if bool(f.get("nemesis")):
			d.color = Color(1.0, 0.15, 0.55)
			d.size = Vector2(6, 6)
			d.position = _map_pos(f.global_position, sc)
		else:
			d.color = Color(1.0, 0.3, 0.3)
			d.size = Vector2(4, 4)
			d.position = _map_pos(f.global_position, sc) + Vector2(1, 1)
		ui.map_view.add_child(d)
		map_dots.append(d)
	# titik gerbang: hijau = terbuka, merah gelap = terkunci
	for g in gates.values():
		if not is_instance_valid(g):
			continue
		var gd := ColorRect.new()
		gd.color = Color(0.35, 0.95, 0.5) if g.open else Color(0.6, 0.2, 0.22)
		gd.size = Vector2(4, 4)
		gd.position = _map_pos(g.global_position, sc)
		ui.map_view.add_child(gd)
		map_dots.append(gd)
	if dowser_knot:
		for dw_ in get_tree().get_nodes_in_group("glints"):
			if not is_instance_valid(dw_):
				continue
			var dri3: int = int(dw_.get("room_idx")) if dw_.get("room_idx") is int else -1
			if dri3 >= 0 and not discovered.get(dri3, false):
				continue
			var dwd := ColorRect.new()
			dwd.color = Color(0.95, 0.85, 0.3)
			dwd.size = Vector2(4, 4)
			dwd.position = _map_pos(dw_.global_position, sc)
			ui.map_view.add_child(dwd)
			map_dots.append(dwd)


# ---------------- UI ----------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	joystick = preload("res://joystick.gd").new()
	layer.add_child(joystick)

	var atk := Button.new()
	atk.text = "ATK"
	atk.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.5, 0.12, 0.14, 0.85)
	sb.border_color = Color(1.0, 0.78, 0.4, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	atk.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = Color(0.8, 0.24, 0.22, 0.95)
	sb2.border_color = Color(1.0, 0.9, 0.6)
	atk.add_theme_stylebox_override("pressed", sb2)
	atk.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	atk.add_theme_color_override("font_outline_color", Color(0.15, 0.02, 0.02, 1.0))
	atk.add_theme_constant_override("outline_size", 6)
	atk.anchor_left = 1.0
	atk.anchor_top = 1.0
	atk.anchor_right = 1.0
	atk.anchor_bottom = 1.0
	atk.offset_left = -200
	atk.offset_top = -220
	atk.offset_right = -40
	atk.offset_bottom = -60
	atk.pivot_offset = Vector2(80, 80)
	atk.button_down.connect(func() -> void:
		atk_held = true
		var twd := atk.create_tween()
		twd.tween_property(atk, "scale", Vector2(0.9, 0.9), 0.05)
	)
	ui["atk_btn"] = atk
	var wl := Label.new()
	wl.anchor_left = 1.0
	wl.anchor_right = 1.0
	wl.offset_left = -220
	wl.offset_right = -40
	wl.offset_top = -252
	wl.offset_bottom = -226
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wl.add_theme_font_size_override("font_size", 13)
	wl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45, 0.9))
	wl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	wl.add_theme_constant_override("outline_size", 4)
	wl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(wl)
	ui["weapon_l"] = wl
	atk.button_up.connect(func() -> void:
		atk_held = false
		var twu := atk.create_tween()
		twu.tween_property(atk, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
	)
	atk.pressed.connect(func() -> void:
		if player != null and is_instance_valid(player):
			player.attack()
	)
	layer.add_child(atk)

	_build_skill_buttons(layer)

	var hpwrap := PanelContainer.new()
	hpwrap.position = Vector2(10, 10)
	hpwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hwsb := StyleBoxFlat.new()
	hwsb.bg_color = Color(0.05, 0.05, 0.1, 0.55)
	hwsb.border_color = Color(0.9, 0.75, 0.3, 0.35)
	hwsb.set_border_width_all(1)
	hwsb.set_corner_radius_all(8)
	hwsb.set_content_margin_all(6)
	hpwrap.add_theme_stylebox_override("panel", hwsb)
	layer.add_child(hpwrap)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hpwrap.add_child(hb)
	ui["hp_box"] = hb
	ui["hp_cells"] = []

	var xpb := ProgressBar.new()
	xpb.position = Vector2(16, 50)
	xpb.custom_minimum_size = Vector2(260, 18)
	xpb.show_percentage = false
	var xpfill := StyleBoxFlat.new()
	xpfill.bg_color = Color(0.95, 0.8, 0.25)
	xpfill.set_corner_radius_all(6)
	xpb.add_theme_stylebox_override("fill", xpfill)
	var xpbg := StyleBoxFlat.new()
	xpbg.bg_color = Color(0.1, 0.1, 0.14, 0.9)
	xpbg.set_corner_radius_all(6)
	xpb.add_theme_stylebox_override("background", xpbg)
	layer.add_child(xpb)
	ui["xp_bar"] = xpb

	var lvl := Label.new()
	lvl.position = Vector2(16, 72)
	lvl.add_theme_font_size_override("font_size", 22)
	lvl.modulate = Color(1.0, 0.9, 0.5)
	lvl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lvl.add_theme_constant_override("outline_size", 5)
	layer.add_child(lvl)
	ui["lv_label"] = lvl

	var buffs := HBoxContainer.new()
	buffs.position = Vector2(74, 72)
	buffs.custom_minimum_size = Vector2(0, 26)
	buffs.add_theme_constant_override("separation", 4)
	buffs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(buffs)
	ui["buffs"] = buffs

	var fl := Label.new()
	fl.add_theme_font_size_override("font_size", 18)
	fl.modulate = Color(1, 1, 1, 0.6)
	fl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	fl.add_theme_constant_override("outline_size", 3)
	fl.anchor_left = 1.0
	fl.anchor_right = 1.0
	fl.offset_left = -280
	fl.offset_top = 14
	fl.offset_right = -12
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(fl)
	ui["floor_label"] = fl

	var sul := Label.new()
	sul.add_theme_font_size_override("font_size", 17)
	sul.modulate = Color(0.75, 0.55, 1.0)
	sul.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	sul.add_theme_constant_override("outline_size", 3)
	sul.anchor_left = 1.0
	sul.anchor_right = 1.0
	sul.offset_left = -280
	sul.offset_top = 38
	sul.offset_right = -140
	sul.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(sul)
	ui["souls_label"] = sul
	_souls_l()

	var kl := Label.new()
	kl.add_theme_font_size_override("font_size", 17)
	kl.modulate = Color(1.0, 0.5, 0.45)
	kl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	kl.add_theme_constant_override("outline_size", 3)
	kl.anchor_left = 1.0
	kl.anchor_right = 1.0
	kl.offset_left = -280
	kl.offset_top = 60
	kl.offset_right = -140
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(kl)
	ui["kills_label"] = kl
	kl.text = ""
	var tl2 := Label.new()
	tl2.add_theme_font_size_override("font_size", 16)
	tl2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.75))
	tl2.add_theme_constant_override("outline_size", 3)
	tl2.anchor_left = 1.0
	tl2.anchor_right = 1.0
	tl2.offset_left = -280
	tl2.offset_top = 82
	tl2.offset_right = -140
	tl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(tl2)
	ui["time_label"] = tl2
	tl2.text = ""

	var earr := Label.new()
	earr.text = "▲"
	earr.add_theme_font_size_override("font_size", 30)
	earr.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15))
	earr.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0, 0.9))
	earr.add_theme_constant_override("outline_size", 4)
	earr.visible = false
	earr.z_index = 20
	layer.add_child(earr)
	ui["elite_arrow"] = earr

	var hero_btn := Button.new()
	hero_btn.text = "HERO"
	hero_btn.add_theme_font_size_override("font_size", 20)
	hero_btn.anchor_left = 1.0
	hero_btn.anchor_right = 1.0
	hero_btn.offset_left = -132
	hero_btn.offset_top = 44
	hero_btn.offset_right = -12
	hero_btn.offset_bottom = 88
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.16, 0.15, 0.24, 0.85)
	hsb.border_color = Color(0.9, 0.75, 0.3, 0.5)
	hsb.set_border_width_all(2)
	hsb.set_corner_radius_all(10)
	hero_btn.add_theme_stylebox_override("normal", hsb)
	hero_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	hero_btn.pressed.connect(func() -> void: _toggle_hero(true))
	layer.add_child(hero_btn)

	# tombol jeda di kiri HERO
	var pbtn := Button.new()
	pbtn.text = "II"
	pbtn.add_theme_font_size_override("font_size", 17)
	pbtn.anchor_left = 1.0
	pbtn.anchor_right = 1.0
	pbtn.offset_left = -184
	pbtn.offset_right = -140
	pbtn.offset_top = 44
	pbtn.offset_bottom = 88
	var psbb := StyleBoxFlat.new()
	psbb.bg_color = Color(0.07, 0.07, 0.14, 0.75)
	psbb.border_color = Color(0.9, 0.75, 0.3, 0.5)
	psbb.set_border_width_all(2)
	psbb.set_corner_radius_all(9)
	pbtn.add_theme_stylebox_override("normal", psbb)
	pbtn.pressed.connect(_toggle_pause)
	layer.add_child(pbtn)

	# tombol SWAP: ganti senjata cepat tanpa buka panel HERO
	var swb := Button.new()
	swb.text = "SWAP"
	swb.add_theme_font_size_override("font_size", 15)
	swb.anchor_left = 1.0
	swb.anchor_right = 1.0
	swb.offset_left = -132
	swb.offset_top = 94
	swb.offset_right = -12
	swb.offset_bottom = 132
	var swsb := hsb.duplicate() as StyleBoxFlat
	swb.add_theme_stylebox_override("normal", swsb)
	swb.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	swb.pressed.connect(_swap_weapon)
	layer.add_child(swb)

	# tombol VIAL: minum botol jiwa simpanan
	var vbtn := Button.new()
	vbtn.text = "⚗ x1"
	vbtn.add_theme_font_size_override("font_size", 17)
	vbtn.anchor_left = 1.0
	vbtn.anchor_top = 1.0
	vbtn.anchor_right = 1.0
	vbtn.anchor_bottom = 1.0
	vbtn.offset_left = -300
	vbtn.offset_right = -212
	vbtn.offset_top = -150
	vbtn.offset_bottom = -84
	vbtn.pivot_offset = Vector2(44, 33)
	var vsb := StyleBoxFlat.new()
	vsb.bg_color = Color(0.05, 0.22, 0.18, 0.85)
	vsb.border_color = Color(0.3, 0.95, 0.75, 0.9)
	vsb.set_border_width_all(2)
	vsb.set_corner_radius_all(12)
	vsb.shadow_color = Color(0, 0, 0, 0.5)
	vsb.shadow_size = 6
	vsb.shadow_offset = Vector2(0, 3)
	vbtn.add_theme_stylebox_override("normal", vsb)
	var vsb2 := vsb.duplicate() as StyleBoxFlat
	vsb2.bg_color = Color(0.15, 0.4, 0.32, 0.95)
	vbtn.add_theme_stylebox_override("pressed", vsb2)
	vbtn.add_theme_color_override("font_color", Color(0.75, 1.0, 0.9))
	vbtn.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.08, 1))
	vbtn.add_theme_constant_override("outline_size", 5)
	vbtn.pressed.connect(func() -> void:
		_use_vial()
		var twv := vbtn.create_tween()
		twv.tween_property(vbtn, "scale", Vector2(0.88, 0.88), 0.05)
		twv.tween_property(vbtn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
	)
	layer.add_child(vbtn)
	ui["vial_btn"] = vbtn

	var chips := HBoxContainer.new()
	chips.anchor_top = 1.0
	chips.anchor_bottom = 1.0
	chips.offset_left = 16
	chips.offset_top = -60
	chips.offset_bottom = -16
	chips.add_theme_constant_override("separation", 6)
	layer.add_child(chips)
	ui["chips"] = chips

	# angka HP di samping sel
	var ht := Label.new()
	ht.add_theme_font_size_override("font_size", 18)
	ht.modulate = Color(1.0, 0.85, 0.8)
	ht.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	ht.add_theme_constant_override("outline_size", 3)
	hb.add_child(ht)
	ui["hp_text"] = ht

	# kotak quest kiri atas
	var qb := PanelContainer.new()
	qb.position = Vector2(16, 96)
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(0.06, 0.06, 0.11, 0.72)
	qsb.border_color = Color(0.9, 0.75, 0.3, 0.55)
	qsb.border_width_left = 4
	qsb.border_width_top = 1
	qsb.border_width_right = 1
	qsb.border_width_bottom = 1
	qsb.set_corner_radius_all(10)
	qsb.set_content_margin_all(9)
	qb.add_theme_stylebox_override("panel", qsb)
	var qvb := VBoxContainer.new()
	qvb.add_theme_constant_override("separation", 2)
	var ql := Label.new()
	ql.add_theme_font_size_override("font_size", 17)
	ql.modulate = Color(1.0, 0.85, 0.4)
	var qd := Label.new()
	qd.add_theme_font_size_override("font_size", 13)
	qd.modulate = Color(1, 1, 1, 0.72)
	qd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qvb.add_child(ql)
	qvb.add_child(qd)
	qb.add_child(qvb)
	layer.add_child(qb)
	ui["quest_box"] = qb
	ui["quest_l"] = ql
	ui["quest_d"] = qd

	# bar HP boss di atas tengah
	var bb := PanelContainer.new()
	bb.anchor_left = 0.5
	bb.anchor_right = 0.5
	bb.offset_left = -200
	bb.offset_right = 200
	bb.offset_top = 150
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.07, 0.04, 0.05, 0.85)
	bsb.border_color = Color(1.0, 0.3, 0.25)
	bsb.set_border_width_all(2)
	bsb.set_corner_radius_all(10)
	bsb.set_content_margin_all(8)
	bb.add_theme_stylebox_override("panel", bsb)
	var bvb := VBoxContainer.new()
	var bn := Label.new()
	bn.text = "☠ BONE KING"
	ui["boss_name"] = bn
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bn.add_theme_font_size_override("font_size", 16)
	bn.modulate = Color(1.0, 0.55, 0.45)
	bn.add_theme_color_override("font_outline_color", Color(0.15, 0.02, 0.0, 0.9))
	bn.add_theme_constant_override("outline_size", 4)
	var bf := ProgressBar.new()
	bf.max_value = 100
	bf.value = 100
	bf.custom_minimum_size = Vector2(0, 16)
	bf.show_percentage = false
	var bff := StyleBoxFlat.new()
	bff.bg_color = Color(0.85, 0.2, 0.15)
	bff.set_corner_radius_all(4)
	bf.add_theme_stylebox_override("fill", bff)
	var bfb := StyleBoxFlat.new()
	bfb.bg_color = Color(0.15, 0.08, 0.08)
	bfb.set_corner_radius_all(4)
	bf.add_theme_stylebox_override("background", bfb)
	bvb.add_child(bn)
	bvb.add_child(bf)
	bb.add_child(bvb)
	bb.visible = false
	layer.add_child(bb)
	ui["boss_bar"] = bb
	ui["boss_fill"] = bf

	# banter bos melayang di bawah bar (tanpa pause)
	var btl := Label.new()
	btl.anchor_left = 0.5
	btl.anchor_right = 0.5
	btl.offset_left = -260
	btl.offset_right = 260
	btl.offset_top = 232
	btl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btl.add_theme_font_size_override("font_size", 24)
	btl.modulate = Color(1.0, 0.5, 0.4, 0.0)
	btl.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 0.95))
	btl.add_theme_constant_override("outline_size", 6)
	layer.add_child(btl)
	ui["boss_banter"] = btl

	# label kombo
	var cl := Label.new()
	cl.anchor_left = 0.5
	cl.anchor_right = 0.5
	cl.anchor_top = 1.0
	cl.anchor_bottom = 1.0
	cl.offset_left = -160
	cl.offset_right = 160
	cl.offset_top = -370
	cl.offset_bottom = -326
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.add_theme_font_size_override("font_size", 30)
	cl.modulate = Color(1.0, 0.7, 0.25)
	cl.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.0, 1.0))
	cl.add_theme_constant_override("outline_size", 6)
	cl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	cl.add_theme_constant_override("shadow_offset_x", 2)
	cl.add_theme_constant_override("shadow_offset_y", 2)
	cl.visible = false
	layer.add_child(cl)
	ui["combo_l"] = cl
	# bar drain tipis di bawah label kombo
	var cbar := ColorRect.new()
	cbar.anchor_left = 0.5
	cbar.anchor_right = 0.5
	cbar.anchor_top = 1.0
	cbar.anchor_bottom = 1.0
	cbar.offset_left = -140
	cbar.offset_right = 140
	cbar.offset_top = -322
	cbar.offset_bottom = -318
	cbar.color = Color(1.0, 0.65, 0.2, 0.85)
	cbar.visible = false
	layer.add_child(cbar)
	ui["combo_bar"] = cbar

	# minimap kanan atas
	var mp := PanelContainer.new()
	mp.anchor_left = 1.0
	mp.anchor_right = 1.0
	mp.offset_left = -162
	mp.offset_right = -12
	mp.offset_top = 100
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.05, 0.05, 0.09, 0.6)
	msb.border_color = Color(0.9, 0.75, 0.3, 0.4)
	msb.set_border_width_all(1)
	msb.set_corner_radius_all(8)
	msb.set_content_margin_all(6)
	mp.add_theme_stylebox_override("panel", msb)
	var mv := Control.new()
	mv.custom_minimum_size = Vector2(140, 190)
	mp.add_child(mv)
	layer.add_child(mp)
	ui["map"] = mp
	ui["map_view"] = mv

	# kartu tutorial
	var tut := PanelContainer.new()
	tut.anchor_left = 0.0
	tut.anchor_right = 0.0
	tut.offset_left = 16
	tut.offset_right = 330
	tut.offset_top = 190
	tut.offset_bottom = 250
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.08, 0.08, 0.14, 0.9)
	tsb.border_color = Color(0.9, 0.75, 0.3)
	tsb.set_border_width_all(2)
	tsb.set_corner_radius_all(10)
	tsb.set_content_margin_all(10)
	tut.add_theme_stylebox_override("panel", tsb)
	var tl := Label.new()
	tl.add_theme_font_size_override("font_size", 20)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut.add_child(tl)
	tut.visible = false
	layer.add_child(tut)
	ui["tut"] = tut
	ui["tut_label"] = tl

	# toast pil: panel gelap + teks emas di tengah bawah
	var tstp := PanelContainer.new()
	tstp.anchor_left = 0.5
	tstp.anchor_right = 0.5
	tstp.anchor_top = 1.0
	tstp.anchor_bottom = 1.0
	tstp.offset_left = -270
	tstp.offset_right = 270
	tstp.offset_top = -316
	tstp.offset_bottom = -262
	tstp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tstsb := StyleBoxFlat.new()
	tstsb.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	tstsb.border_color = Color(0.9, 0.75, 0.3, 0.7)
	tstsb.set_border_width_all(2)
	tstsb.set_corner_radius_all(16)
	tstsb.set_content_margin_all(10)
	tstsb.shadow_color = Color(0, 0, 0, 0.6)
	tstsb.shadow_size = 6
	tstsb.shadow_offset = Vector2(0, 3)
	tstp.add_theme_stylebox_override("panel", tstsb)
	tstp.visible = false
	layer.add_child(tstp)
	var tst := Label.new()
	tst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tst.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tst.add_theme_font_size_override("font_size", 22)
	tst.modulate = Color(1.0, 0.9, 0.5, 1.0)
	tst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tst.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tstp.add_child(tst)
	ui["toast_panel"] = tstp
	ui["toast"] = tst

	# banner naik level (non-blokir)
	var lb := Label.new()
	lb.anchor_left = 0.5
	lb.anchor_right = 0.5
	lb.anchor_top = 0.5
	lb.anchor_bottom = 0.5
	lb.offset_left = -260
	lb.offset_right = 260
	lb.offset_top = -260
	lb.offset_bottom = -210
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.add_theme_font_size_override("font_size", 44)
	lb.modulate = Color(1.0, 0.88, 0.38)
	lb.add_theme_color_override("font_outline_color", Color(0.22, 0.1, 0.0, 1.0))
	lb.add_theme_constant_override("outline_size", 8)
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lb.add_theme_constant_override("shadow_offset_x", 3)
	lb.add_theme_constant_override("shadow_offset_y", 3)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.visible = false
	layer.add_child(lb)
	ui["lvl_banner"] = lb

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.visible = false
	layer.add_child(dim)
	ui["dim"] = dim

	# dialog karakter: ditambahkan SETELAH dim supaya tergambar & tersentuh di atasnya
	dlg = DLG.new()
	layer.add_child(dlg)
	dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg.finished.connect(_on_dlg_end)
	dlg.choice_made.connect(_on_dlg_choice)

	var bc := CenterContainer.new()
	bc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bc.mouse_filter = Control.MOUSE_FILTER_STOP
	bc.visible = false
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := Label.new()
	t.add_theme_font_size_override("font_size", 64)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0, 1.0))
	t.add_theme_constant_override("outline_size", 10)
	var sub := Label.new()
	sub.add_theme_font_size_override("font_size", 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	sub.add_theme_constant_override("outline_size", 4)
	for ll in [t, sub]:
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(ll)
	bc.add_child(vb)
	bc.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_on_banner_tap()
		elif e is InputEventScreenTouch and e.pressed:
			_on_banner_tap()
	)
	layer.add_child(bc)
	ui["banner"] = bc
	ui["banner_t"] = t
	ui["banner_sub"] = sub

	var dr := CenterContainer.new()
	dr.set_anchors_preset(Control.PRESET_FULL_RECT)
	dr.visible = false
	dr.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.08, 0.07, 0.12, 0.97)
	psb.border_color = Color(0.9, 0.75, 0.3, 0.7)
	psb.set_border_width_all(3)
	psb.set_corner_radius_all(18)
	psb.set_content_margin_all(22)
	psb.shadow_color = Color(0, 0, 0, 0.7)
	psb.shadow_size = 14
	psb.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", psb)
	var dvb := VBoxContainer.new()
	dvb.add_theme_constant_override("separation", 18)
	var dt := Label.new()
	dt.text = "LEVEL UP — pick one"
	dt.add_theme_font_size_override("font_size", 34)
	dt.modulate = Color(1.0, 0.88, 0.45)
	dt.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.0, 1.0))
	dt.add_theme_constant_override("outline_size", 6)
	dt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dvb.add_child(dt)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	dvb.add_child(cards)
	var reroll := Button.new()
	reroll.text = "REROLL"
	reroll.custom_minimum_size = Vector2(0, 44)
	reroll.add_theme_font_size_override("font_size", 18)
	reroll.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	reroll.add_theme_constant_override("outline_size", 5)
	var rrsb := StyleBoxFlat.new()
	rrsb.bg_color = Color(0.2, 0.16, 0.1, 1.0)
	rrsb.border_color = Color(0.9, 0.75, 0.3, 0.8)
	rrsb.set_border_width_all(2)
	rrsb.set_corner_radius_all(10)
	reroll.add_theme_stylebox_override("normal", rrsb)
	var rrsb2: StyleBoxFlat = rrsb.duplicate()
	rrsb2.bg_color = Color(0.32, 0.25, 0.14, 1.0)
	reroll.add_theme_stylebox_override("hover", rrsb2)
	reroll.process_mode = Node.PROCESS_MODE_ALWAYS
	reroll.pressed.connect(_draft_reroll)
	dvb.add_child(reroll)
	ui["draft_reroll"] = reroll
	panel.add_child(dvb)
	dr.add_child(panel)
	layer.add_child(dr)
	ui["draft"] = dr
	ui["draft_cards"] = cards

	# layar hero: kiri = model 3D muter, kanan = stat + senjata + relic + skill
	var hr := Control.new()
	hr.set_anchors_preset(Control.PRESET_FULL_RECT)
	hr.visible = false
	hr.process_mode = Node.PROCESS_MODE_ALWAYS
	var hbg := ColorRect.new()
	hbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbg.color = Color(0.03, 0.03, 0.06, 0.96)
	hr.add_child(hbg)
	var hcc := CenterContainer.new()
	hcc.set_anchors_preset(Control.PRESET_FULL_RECT)
	hr.add_child(hcc)
	var hhb := HBoxContainer.new()
	hhb.add_theme_constant_override("separation", 14)
	hcc.add_child(hhb)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(210, 560)
	svc.process_mode = Node.PROCESS_MODE_ALWAYS
	hhb.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.size = Vector2i(420, 1120)
	sv.process_mode = Node.PROCESS_MODE_ALWAYS
	svc.add_child(sv)
	var stage := Node3D.new()
	sv.add_child(stage)
	var sc := Camera3D.new()
	stage.add_child(sc)
	sc.fov = 38.0
	sc.look_at_from_position(Vector3(0.0, 1.55, 4.1), Vector3(0, 0.95, 0))
	sc.current = true
	var sl := DirectionalLight3D.new()
	stage.add_child(sl)
	sl.rotation_degrees = Vector3(-45, -30, 0)
	sl.light_energy = 1.4
	var senv_n := WorldEnvironment.new()
	var senv := Environment.new()
	senv.background_mode = Environment.BG_COLOR
	senv.background_color = Color(0.05, 0.05, 0.09, 0.0)
	senv.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	senv.ambient_light_color = Color(0.5, 0.52, 0.6)
	senv.ambient_light_energy = 0.7
	senv_n.environment = senv
	stage.add_child(senv_n)
	var hero_model: Node3D = load(CHARS + "Skeleton_Warrior.glb").instantiate()
	stage.add_child(hero_model)
	M.paint(hero_model, M.toon(skeleton_tex, Color(1, 1, 1), 0.4))
	var hap: AnimationPlayer = M.anim_player(hero_model)
	hap.process_mode = Node.PROCESS_MODE_ALWAYS
	M.play_fuzzy(hap, ["idle"])
	# turntable: muter pelan walau game sedang pause
	var stw := svc.create_tween()
	stw.set_loops()
	stw.tween_property(hero_model, "rotation:y", TAU, 7.0).from(0.0)
	ui["hero_stage"] = stage
	ui["hero_model"] = hero_model
	ui["hero_svc"] = svc

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.add_theme_constant_override("separation", 8)
	right.process_mode = Node.PROCESS_MODE_ALWAYS
	hhb.add_child(right)
	ui["hero_right"] = right

	layer.add_child(hr)
	ui["hero"] = hr

	# vignette HP rendah: tepi merah berdenyut
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.55, 1.0])
	vg.colors = PackedColorArray([Color(0.6, 0.02, 0.05, 0.0), Color(0.6, 0.02, 0.05, 0.55)])
	var gt := GradientTexture2D.new()
	gt.gradient = vg
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 540
	gt.height = 1200
	vign = TextureRect.new()
	vign.texture = gt
	vign.set_anchors_preset(Control.PRESET_FULL_RECT)
	vign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vign.stretch_mode = TextureRect.STRETCH_SCALE
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vign.modulate.a = 0.0
	vign.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(vign)

	# panel JEDA (resume / restart lantai / volume / keluar ke menu)
	var pp := PanelContainer.new()
	pp.anchor_left = 0.5
	pp.anchor_right = 0.5
	pp.anchor_top = 0.5
	pp.anchor_bottom = 0.5
	pp.offset_left = -200
	pp.offset_right = 200
	pp.offset_top = -280
	pp.offset_bottom = 280
	pp.process_mode = Node.PROCESS_MODE_ALWAYS
	var ppsb := StyleBoxFlat.new()
	ppsb.bg_color = Color(0.05, 0.05, 0.1, 0.96)
	ppsb.border_color = Color(0.9, 0.75, 0.3, 0.7)
	ppsb.set_border_width_all(2)
	ppsb.set_corner_radius_all(14)
	ppsb.set_content_margin_all(20)
	pp.add_theme_stylebox_override("panel", ppsb)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 12)
	pvb.process_mode = Node.PROCESS_MODE_ALWAYS
	pp.add_child(pvb)
	var pt := Label.new()
	pt.text = "PAUSED"
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pt.add_theme_font_size_override("font_size", 30)
	pt.modulate = Color(1.0, 0.85, 0.4)
	pt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	pt.add_theme_constant_override("outline_size", 5)
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pvb.add_child(pt)
	var pstats := Label.new()
	pstats.name = "pause_stats"
	pstats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pstats.add_theme_font_size_override("font_size", 14)
	pstats.modulate = Color(1, 1, 1, 0.6)
	pstats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pvb.add_child(pstats)
	ui["pause_stats"] = pstats
	_pause_vol_row(pvb, "Music", Stats.mus_vol(), func(v: float) -> void:
		Stats.music_volume = v
		Sfx.set_music_volume(v)
		Stats.save_game())
	_pause_vol_row(pvb, "Sound FX", Stats.sfx_vol(), func(v: float) -> void:
		Stats.sfx_volume = v
		Stats.save_game())
	var b_lore := _pause_btn("LORE (%d/%d)" % [Stats.lore_seen.size(), LORE_LINES.size()])
	b_lore.pressed.connect(func() -> void:
		Sfx.play("page")
		_toggle_lore())
	pvb.add_child(b_lore)
	var b_best := _pause_btn("BESTIARY (%d/%d)" % [mini(Stats.bestiary.size(), BESTIARY.size()), BESTIARY.size()])
	b_best.pressed.connect(func() -> void:
		Sfx.play("page")
		_toggle_bestiary())
	pvb.add_child(b_best)
	var b_qual := _pause_btn("QUALITY: " + ("LOW" if low_quality else "HIGH"))
	b_qual.pressed.connect(func() -> void:
		Stats.quality = 0 if not low_quality else 1
		_apply_quality()
		b_qual.text = "QUALITY: " + ("LOW" if low_quality else "HIGH")
		Stats.save_game()
		Sfx.play("click"))
	pvb.add_child(b_qual)
	var b_resume := _pause_btn("RESUME")
	b_resume.pressed.connect(_toggle_pause)
	pvb.add_child(b_resume)
	var b_floor := _pause_btn("RESTART FLOOR")
	b_floor.pressed.connect(func() -> void:
		if paused_ui:
			_toggle_pause()
		_new_run(rng.randi()))
	pvb.add_child(b_floor)
	var b_menu := _pause_btn("QUIT TO MENU")
	b_menu.pressed.connect(_quit_to_menu)
	pvb.add_child(b_menu)
	pp.visible = false
	layer.add_child(pp)
	pause_panel = pp
	ui["pause_panel"] = pp
	_build_lore_panel(layer)
	_build_bestiary_panel(layer)

	# rect fade transisi (paling atas di layer UI)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0)
	fade_rect.modulate.a = 1.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	# tips loading saat layar gelap antar lantai
	tip_l = Label.new()
	tip_l.visible = false
	tip_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_l.process_mode = Node.PROCESS_MODE_ALWAYS
	tip_l.set_anchors_preset(Control.PRESET_CENTER)
	tip_l.anchor_left = 0.1
	tip_l.anchor_right = 0.9
	tip_l.offset_top = 360
	tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	tip_l.add_theme_font_size_override("font_size", 15)
	tip_l.modulate = Color(0.9, 0.82, 0.62, 0.9)
	tip_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	tip_l.add_theme_constant_override("shadow_offset_x", 1)
	tip_l.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(tip_l)


func _pause_vol_row(vb: VBoxContainer, label: String, cur: float, on_change: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(150, 0)
	l.add_theme_font_size_override("font_size", 17)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = cur
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 32)
	_style_slider(s)
	s.value_changed.connect(on_change)
	hb.add_child(l)
	hb.add_child(s)
	vb.add_child(hb)


func _style_slider(s: HSlider) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.16, 0.9)
	sb.set_corner_radius_all(4)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", sb)
	var hi := StyleBoxFlat.new()
	hi.bg_color = Color(0.9, 0.75, 0.3)
	hi.set_corner_radius_all(4)
	hi.content_margin_top = 4
	hi.content_margin_bottom = 4
	s.add_theme_stylebox_override("grabber_area", hi)
	s.add_theme_stylebox_override("grabber_area_highlight", hi)
	s.add_theme_icon_override("grabber", _make_grabber())
	s.add_theme_icon_override("grabber_highlight", _make_grabber())


func _make_grabber() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d <= 7.5:
				img.set_pixel(x, y, Color(1.0, 0.9, 0.6) if d <= 6.0 else Color(0.6, 0.45, 0.2))
	return ImageTexture.create_from_image(img)


func _pause_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.09, 0.16, 0.95)
	sb.border_color = Color(0.9, 0.75, 0.3, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 4
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.18, 0.15, 0.24, 0.98)
	sbh.border_color = Color(1.0, 0.88, 0.5, 0.9)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.3, 0.24, 0.12, 1.0)
	b.add_theme_stylebox_override("pressed", sbp)
	b.pressed.connect(func() -> void:
		b.pivot_offset = b.size * 0.5
		var ptw: Tween = b.create_tween()
		b.scale = Vector2(0.94, 0.94)
		ptw.tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	b.mouse_entered.connect(func() -> void:
		b.pivot_offset = b.size * 0.5
		var htw: Tween = b.create_tween()
		htw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.1))
	b.mouse_exited.connect(func() -> void:
		var xtw: Tween = b.create_tween()
		xtw.tween_property(b, "scale", Vector2.ONE, 0.1))
	return b


var lore_panel: PanelContainer = null

func _build_lore_panel(layer: CanvasLayer) -> void:
	var lp := PanelContainer.new()
	lp.anchor_left = 0.5
	lp.anchor_right = 0.5
	lp.anchor_top = 0.5
	lp.anchor_bottom = 0.5
	lp.offset_left = -220
	lp.offset_right = 220
	lp.offset_top = -330
	lp.offset_bottom = 330
	lp.process_mode = Node.PROCESS_MODE_ALWAYS
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(0.04, 0.04, 0.09, 0.97)
	lsb.border_color = Color(0.75, 0.55, 1.0, 0.6)
	lsb.set_border_width_all(2)
	lsb.set_corner_radius_all(14)
	lsb.set_content_margin_all(18)
	lp.add_theme_stylebox_override("panel", lsb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.process_mode = Node.PROCESS_MODE_ALWAYS
	lp.add_child(vb)
	var lt := Label.new()
	lt.text = "CODEX — WHISPERS OF THE DEEP"
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lt.add_theme_font_size_override("font_size", 20)
	lt.modulate = Color(0.85, 0.7, 1.0)
	vb.add_child(lt)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 470)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 8)
	sc.add_child(lv)
	ui["lore_list"] = lv
	var bb := _pause_btn("BACK")
	bb.pressed.connect(func() -> void:
		Sfx.play("click")
		lore_panel.visible = false)
	vb.add_child(bb)
	lp.visible = false
	layer.add_child(lp)
	lore_panel = lp
	ui["lore_panel"] = lp


var bestiary_panel: PanelContainer = null

func _build_bestiary_panel(layer: CanvasLayer) -> void:
	var lp := PanelContainer.new()
	lp.anchor_left = 0.5
	lp.anchor_right = 0.5
	lp.anchor_top = 0.5
	lp.anchor_bottom = 0.5
	lp.offset_left = -220
	lp.offset_right = 220
	lp.offset_top = -330
	lp.offset_bottom = 330
	lp.process_mode = Node.PROCESS_MODE_ALWAYS
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(0.07, 0.04, 0.05, 0.97)
	lsb.border_color = Color(1.0, 0.55, 0.4, 0.6)
	lsb.set_border_width_all(2)
	lsb.set_corner_radius_all(14)
	lsb.set_content_margin_all(18)
	lp.add_theme_stylebox_override("panel", lsb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.process_mode = Node.PROCESS_MODE_ALWAYS
	lp.add_child(vb)
	var lt := Label.new()
	lt.text = "BESTIARY — DENIZENS OF THE DEEP"
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lt.add_theme_font_size_override("font_size", 20)
	lt.modulate = Color(1.0, 0.7, 0.55)
	vb.add_child(lt)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 470)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 12)
	sc.add_child(lv)
	ui["bestiary_list"] = lv
	var bb := _pause_btn("BACK")
	bb.pressed.connect(func() -> void:
		Sfx.play("click")
		bestiary_panel.visible = false)
	vb.add_child(bb)
	lp.visible = false
	layer.add_child(lp)
	bestiary_panel = lp
	ui["bestiary_panel"] = lp


func _toggle_bestiary() -> void:
	if bestiary_panel == null:
		return
	for c in ui.bestiary_list.get_children():
		c.queue_free()
	for arch in BESTIARY.keys():
		var b: Array = BESTIARY[arch]
		var n: int = int(Stats.bestiary.get(arch, 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = String(b[0]) if n > 0 else "???"
		nm.modulate = Color(1.0, 0.9, 0.75, 0.95) if n > 0 else Color(1, 1, 1, 0.3)
		nm.add_theme_font_size_override("font_size", 17)
		info.add_child(nm)
		var ds := Label.new()
		ds.text = String(b[1]) if n > 0 else "Yet unmet — the deep still hides it."
		ds.modulate = Color(1, 1, 1, 0.55) if n > 0 else Color(1, 1, 1, 0.25)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.add_theme_font_size_override("font_size", 13)
		info.add_child(ds)
		row.add_child(info)
		var kl := Label.new()
		kl.text = "×%d" % n if n > 0 else ""
		kl.modulate = Color(1.0, 0.6, 0.4, 0.9)
		kl.add_theme_font_size_override("font_size", 17)
		row.add_child(kl)
		ui.bestiary_list.add_child(row)
	bestiary_panel.visible = true


func _toggle_lore() -> void:
	if lore_panel == null:
		return
	for c in ui.lore_list.get_children():
		c.queue_free()
	if Stats.lore_seen.is_empty():
		var e := Label.new()
		e.text = "No whispers yet — find the glowing lore stones."
		e.modulate = Color(1, 1, 1, 0.55)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.add_theme_font_size_override("font_size", 15)
		ui.lore_list.add_child(e)
	else:
		var i := 0
		for line in Stats.lore_seen:
			i += 1
			var l := Label.new()
			l.text = "%02d — %s" % [i, line]
			l.modulate = Color(0.9, 0.82, 1.0, 0.95)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 15)
			ui.lore_list.add_child(l)
	lore_panel.visible = true


func _toggle_pause() -> void:
	if run_state == "dead" or Stats.draft_open or (dlg != null and dlg.active):
		return
	paused_ui = not paused_ui
	get_tree().paused = paused_ui
	ui.dim.visible = paused_ui or Stats.draft_open
	pause_panel.visible = paused_ui
	if paused_ui:
		pause_panel.pivot_offset = pause_panel.size * 0.5
		pause_panel.scale = Vector2(0.88, 0.88)
		var pptw: Tween = pause_panel.create_tween()
		pptw.tween_property(pause_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ui.dim.modulate.a = 0.0
		var pdim: Tween = ui.dim.create_tween()
		pdim.tween_property(ui.dim, "modulate:a", 1.0, 0.2)
	if not paused_ui and lore_panel != null:
		lore_panel.visible = false
	if not paused_ui and bestiary_panel != null:
		bestiary_panel.visible = false
	if paused_ui and ui.has("pause_stats"):
		var pm := int(run_time) / 60
		var ps := int(run_time) % 60
		var wname: String = String(WDB.DB[Stats.weapon_id]["name"]) if WDB.DB.has(Stats.weapon_id) else Stats.weapon_id
		var omen_line := "" if omen_name == "" else "  •  ☗ " + omen_name
		ui.pause_stats.text = "Floor %d  •  %d kills  •  best combo ×%d  •  %d:%02d  •  %+d souls  •  ☠ %d
%s  •  %d relics%s" % [Stats.floor_num, kills_run, combo_max, pm, ps, Stats.souls - run_souls_start, revives_run, wname, Stats.relics.size(), omen_line]
	Sfx.play("click")


func _quit_to_menu() -> void:
	Stats.save_run()
	get_tree().paused = false
	paused_ui = false
	Sfx.play("click")
	await _fade_to(1.0, 0.3)
	get_tree().change_scene_to_file("res://app/menu.tscn")


func _fade_to(a: float, dur: float) -> void:
	if fade_rect == null:
		return
	if a > 0.5 and tip_l != null:
		tip_l.text = "◆ " + TIPS[rng.randi() % TIPS.size()]
		tip_l.visible = true
	var tw := fade_rect.create_tween()
	tw.tween_property(fade_rect, "modulate:a", a, dur)
	await tw.finished
	if a <= 0.05 and tip_l != null:
		get_tree().create_timer(1.1).timeout.connect(func() -> void: tip_l.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ui.hero.visible:
			_toggle_hero(false)
		elif pause_panel.visible:
			_toggle_pause()
		elif run_state == "playing" and not Stats.draft_open and not (dlg != null and dlg.active):
			_toggle_pause()
		get_viewport().set_input_as_handled()


func _update_hp(hp: float) -> void:
	var maxh := int(ceil(Stats.get_stat("max_hp")))
	var cells: Array = ui.get("hp_cells", [])
	var hb: HBoxContainer = ui.get("hp_box")
	if cells.size() != maxh:
		for c in cells:
			c.queue_free()
		cells.clear()
		var cw := 26.0 if maxh <= 10 else 16.0
		for i in range(maxh):
			var r := ColorRect.new()
			r.color = Color(0.28, 0.12, 0.14)
			r.custom_minimum_size = Vector2(cw, 26)
			hb.add_child(r)
			cells.append(r)
		hb.move_child(ui.hp_text, hb.get_child_count() - 1)
	var full := int(ceil(hp))
	for i in range(cells.size()):
		var was_full: bool = cells[i].color.r > 0.5
		if was_full and i >= full:
			cells[i].color = Color(1, 1, 1)
			var ctw: Tween = cells[i].create_tween()
			ctw.tween_property(cells[i], "color", Color(0.28, 0.12, 0.14), 0.4)
		elif i < full:
			if i >= int(ceil(prev_hp)) and prev_hp >= 0.0:
				cells[i].color = Color(0.5, 1.0, 0.6)
				var gtw: Tween = cells[i].create_tween()
				gtw.tween_property(cells[i], "color", Color(0.9, 0.16, 0.22), 0.45)
			else:
				cells[i].color = Color(0.9, 0.16, 0.22)
	if ui.has("hp_text"):
		ui.hp_text.text = "%d/%d" % [maxi(int(ceil(hp)), 0), maxh]
	if prev_hp >= 0.0 and hp < prev_hp - 0.001:
		trauma = maxf(trauma, clampf(0.4 + (prev_hp - hp) / maxf(1.0, float(maxh)) * 1.6, 0.4, 0.9))
		_vign_flash()
		floor_hurt = true
	prev_hp = hp
	_set_low_hp(hp <= 1.0 and hp > 0.0)


func _vign_flash() -> void:
	# kilat merah sekali saat terluka; kalau denyut HP-kritis sedang jalan, biarkan
	if vign == null or (vign_tween != null and vign_tween.is_valid()):
		return
	vign.modulate.a = 0.45
	var tw := vign.create_tween()
	tw.tween_property(vign, "modulate:a", 0.0, 0.5)


func _set_low_hp(on: bool) -> void:
	if vign == null:
		return
	if on:
		if vign_tween == null or not vign_tween.is_valid():
			vign_tween = vign.create_tween()
			vign_tween.set_loops()
			vign_tween.tween_property(vign, "modulate:a", 0.75, 0.55)
			vign_tween.tween_property(vign, "modulate:a", 0.3, 0.55)
			vign_tween.tween_callback(func() -> void: Sfx.play("hit"))
	else:
		if vign_tween != null and vign_tween.is_valid():
			vign_tween.kill()
		vign_tween = null
		if vign.modulate.a > 0.01:
			var tw := vign.create_tween()
			tw.tween_property(vign, "modulate:a", 0.0, 0.4)


func _update_xp(cur: int, need: int, lv: int) -> void:
	ui.xp_bar.max_value = need
	var xtw := create_tween()
	xtw.tween_property(ui.xp_bar, "value", float(cur), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# pulsa singkat di penuh-bar saat XP mengalir masuk
	var xftw: Tween = create_tween()
	xftw.tween_property(ui.xp_bar, "modulate", Color(1.35, 1.35, 1.6), 0.08)
	xftw.tween_property(ui.xp_bar, "modulate", Color(1, 1, 1), 0.25)
	ui.lv_label.text = "Lv %d" % lv
	ui.lv_label.pivot_offset = ui.lv_label.size * 0.5
	var ltw: Tween = ui.lv_label.create_tween()
	ui.lv_label.scale = Vector2(1.15, 1.15)
	ltw.tween_property(ui.lv_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


# indikator buff/debuff aktif di bawah bar XP — rebuild cuma kalau set berubah
var _buff_sig := ""

func _refresh_buffs() -> void:
	if player == null or not is_instance_valid(player):
		return
	var list: Array = []
	if blood_moon:
		list.append(["☽ BLOOD MOON", Color(0.9, 0.15, 0.2)])
	elif soul_rush:
		list.append(["✦ SOUL RUSH", Color(0.7, 0.45, 1.0)])
	elif fading_light:
		list.append(["◈ FADING LIGHT", Color(0.55, 0.6, 0.85)])
	elif echoing:
		list.append(["◈ ECHOING", Color(0.55, 0.8, 1.0)])
	elif storm_cellar:
		list.append(["⚡ STORM", Color(0.6, 0.55, 1.15)])
	elif gilded_tides:
		list.append(["★ GILDED", Color(1.0, 0.8, 0.3)])
	elif soul_drift:
		list.append(["☆ DRIFT", Color(0.5, 0.95, 0.85)])
	elif grave_hunger:
		list.append(["☠ HUNGER", Color(0.75, 0.65, 1.0)])
	elif giant_hall:
		list.append(["▲ GIANT", Color(1.0, 0.7, 0.4)])
	elif shrouded:
		list.append(["◈ SHROUD", Color(0.55, 0.6, 0.7)])
	elif ossuary:
		list.append(["☠ OSSUARY", Color(0.95, 0.85, 0.5)])
	elif mirror_hall:
		list.append(["◈ MIRROR", Color(0.6, 0.7, 1.0)])
	elif ashfall:
		list.append(["▲ ASHFALL", Color(0.85, 0.75, 0.6)])
	elif hungry_walls:
		list.append(["▲ HUNGRY", Color(0.95, 0.6, 0.4)])
	elif candlelit:
		list.append(["☆ CANDLELIT", Color(1.0, 0.85, 0.5)])
	elif verdant:
		list.append(["☆ VERDANT", Color(0.55, 0.95, 0.55)])
	elif bone_chorus:
		list.append(["◆ CHORUS", Color(0.85, 0.55, 0.95)])
	elif sunken_tide:
		list.append(["≈ TIDE", Color(0.4, 0.9, 0.8)])
	elif low_tide:
		list.append(["≈ EBB", Color(0.5, 0.95, 0.6)])
	elif glass_sea:
		list.append(["≈ GLASS", Color(0.75, 0.98, 1.0)])
	elif deep_current:
		list.append(["≈ DRIFT", Color(0.4, 0.7, 1.0)])
	elif dread_tide:
		list.append(["◆ DREAD", Color(0.8, 0.4, 0.9)])
	elif starved_deep:
		list.append(["☆ STARVED", Color(0.35, 0.4, 0.85)])
	elif choir:
		list.append(["☗ CHOIR", Color(0.6, 0.45, 0.9)])
	elif abyssal_hymn:
		list.append(["☗ HYMN", Color(0.5, 0.7, 1.0)])
	elif dead_calm:
		list.append(["≈ CALM", Color(0.55, 0.85, 0.9)])
	elif dead_weight:
		list.append(["≈ WEIGHT", Color(0.5, 0.55, 0.75)])
	elif wolfsbane:
		list.append(["☽ PACK", Color(0.65, 0.7, 0.95)])
	elif thin_veil:
		list.append(["◈ VEIL", Color(0.8, 0.5, 1.0)])
	elif low_water:
		list.append(["≈ LOW", Color(0.4, 0.85, 0.9)])
	elif drift_tide:
		list.append(["≋ DRIFT", Color(0.35, 0.7, 1.0)])
	elif soul_swarm:
		list.append(["◈ SWARM", Color(0.5, 0.6, 1.0)])
	elif gauntlet:
		list.append(["⚔ GAUNTLET", Color(0.95, 0.6, 0.4)])
	elif brisk:
		list.append(["≈ BRISK", Color(0.5, 0.95, 0.7)])
	elif shoal_tide:
		list.append(["≋ SHOAL", Color(0.65, 0.8, 0.98)])
	elif salvage_tide:
		list.append(["◈ SALVAGE", Color(0.95, 0.85, 0.6)])
	elif gale_tide:
		list.append(["≈ GALE", Color(0.8, 0.9, 0.85)])
	elif mercy_tide:
		list.append(["≋ MERCY", Color(0.55, 0.78, 0.8)])
	elif eel_tide:
		list.append(["≋ EEL", Color(0.35, 0.65, 0.5)])
	elif swell_tide:
		list.append(["≋ SWELL", Color(0.35, 0.45, 0.7)])
	elif kelp_bed:
		list.append(["≋ KELP", Color(0.3, 0.6, 0.35)])
	elif barnacle_bloom:
		list.append(["≋ BLOOM", Color(0.6, 0.65, 0.4)])
	elif sodden:
		list.append(["≋ SODDEN", Color(0.4, 0.5, 0.65)])
	elif bile_tide:
		list.append(["≋ BILE", Color(0.5, 0.6, 0.3)])
	elif mire_hollow:
		list.append(["≋ MIRE", Color(0.55, 0.45, 0.3)])
	elif dark_lantern:
		list.append(["≋ DARK", Color(0.35, 0.35, 0.55)])
	elif halfwreck:
		list.append(["≋ WRECK", Color(0.6, 0.5, 0.35)])
	elif merchant_tide:
		list.append(["≋ MART", Color(0.5, 0.75, 0.5)])
	elif hungry_urns:
		list.append(["≋ URNS", Color(0.75, 0.6, 0.35)])
	elif bilge_run:
		list.append(["≋ BILGE", Color(0.45, 0.4, 0.35)])
	elif pale_squall:
		list.append(["≋ SQALL", Color(0.65, 0.7, 0.85)])
	elif soul_flush:
		list.append(["≋ FLUSH", Color(0.55, 0.8, 0.65)])
	elif kings_tithe:
		list.append(["≋ TITHE", Color(0.7, 0.5, 0.3)])
	elif black_calm:
		list.append(["≋ CALM", Color(0.4, 0.5, 0.7)])
	elif gun_smoke:
		list.append(["≋ SMOKE", Color(0.6, 0.5, 0.4)])
	elif greedy_tide:
		list.append(["≋ GREEDY", Color(0.75, 0.7, 0.4)])
	elif drift_wreck:
		list.append(["≋ WRECK", Color(0.6, 0.55, 0.45)])
	elif long_watch:
		list.append(["≋ WATCH", Color(0.5, 0.6, 0.7)])
	elif salted_deck:
		list.append(["≋ SALT", Color(0.65, 0.65, 0.7)])
	elif crows_tide:
		list.append(["≋ CROW", Color(0.5, 0.75, 0.55)])
	elif long_night:
		list.append(["≋ NIGHT", Color(0.35, 0.45, 0.65)])
	elif halfway_dead:
		list.append(["≋ CULL", Color(0.6, 0.55, 0.4)])
	elif rich_vein:
		list.append(["≋ VEIN", Color(0.85, 0.7, 0.3)])
	elif wraiths_due:
		list.append(["≋ DUE", Color(0.55, 0.7, 0.9)])
	elif pale_lantern_ev:
		list.append(["≋ PALE", Color(0.7, 0.8, 0.5)])
	elif saltgrave_ev:
		list.append(["≋ GRAVE", Color(0.8, 0.75, 0.55)])
	elif leeward_ev:
		list.append(["≋ LEE", Color(0.55, 0.75, 0.75)])
	elif brine_smoke:
		list.append(["≋ SMOKE", Color(0.5, 0.55, 0.55)])
	elif crowns_ransom:
		list.append(["≋ RANSOM", Color(0.7, 0.55, 0.85)])
	elif bilge_strike:
		list.append(["≋ STRIKE", Color(0.75, 0.5, 0.4)])
	elif full_draught:
		list.append(["≋ DRAUGHT", Color(0.45, 0.7, 0.65)])
	elif salt_front:
		list.append(["≋ FRONT", Color(0.6, 0.55, 0.5)])
	elif cold_snap:
		list.append(["≋ SNAP", Color(0.55, 0.7, 0.9)])
	elif full_moon:
		list.append(["≋ MOON", Color(0.8, 0.8, 0.95)])
	elif gunners_luck:
		list.append(["≋ LUCK", Color(0.7, 0.65, 0.45)])
	elif shallow_graves:
		list.append(["≋ GRAVES", Color(0.55, 0.5, 0.45)])
	elif wailing_wind:
		list.append(["≋ WAIL", Color(0.7, 0.75, 0.8)])
	elif balmy_sea:
		list.append(["≋ BALMY", Color(0.85, 0.8, 0.55)])
	elif rust_storm:
		list.append(["≋ RUST", Color(0.85, 0.5, 0.3)])
	elif ember_wake:
		list.append(["≋ EMBER", Color(0.95, 0.55, 0.3)])
	elif saltsick:
		list.append(["≋ SICK", Color(0.6, 0.65, 0.55)])
	elif gallows_tide:
		list.append(["≋ GALLOW", Color(0.55, 0.45, 0.32)])
	elif pilot_light:
		list.append(["≋ PILOT", Color(0.45, 0.65, 0.9)])
	elif widdershins:
		list.append(["≋ WIDDER", Color(0.65, 0.55, 0.75)])
	elif slack_water:
		list.append(["≋ SLACK", Color(0.5, 0.6, 0.65)])
	elif salvage_breeze:
		list.append(["≋ BREEZE", Color(0.55, 0.7, 0.6)])
	elif deep_salve:
		list.append(["≋ SALVE", Color(0.5, 0.65, 0.8)])
	elif keel_spirit:
		list.append(["≋ SPIRIT", Color(0.65, 0.75, 0.6)])
	elif lantern_wake:
		list.append(["≋ WAKE", Color(0.8, 0.7, 0.4)])
	elif fog_bank:
		list.append(["≋ FOG", Color(0.6, 0.65, 0.68)])
	elif tide_clock:
		list.append(["≋ CLOCK", Color(0.55, 0.6, 0.75)])
	elif deep_well:
		list.append(["≋ WELL", Color(0.3, 0.35, 0.55)])
	elif bilge_still:
		list.append(["≋ STILL", Color(0.45, 0.5, 0.48)])
	elif keel_groan:
		list.append(["≋ GROAN", Color(0.55, 0.42, 0.3)])
	elif saltwind:
		list.append(["≋ WIND", Color(0.5, 0.6, 0.65)])
	elif bone_lantern:
		list.append(["≋ LANTERN", Color(0.85, 0.7, 0.35)])
	elif dead_reckoning:
		list.append(["≋ RECKON", Color(0.5, 0.45, 0.7)])
	elif gloom_tide:
		list.append(["≋ GLOOM", Color(0.4, 0.45, 0.6)])
	elif pale_wake:
		list.append(["≋ WAKE", Color(0.6, 0.65, 0.85)])
	elif murk_lift:
		list.append(["≋ MURK", Color(0.4, 0.55, 0.6)])
	elif siren_hum:
		list.append(["≋ HUM", Color(0.55, 0.4, 0.7)])
	elif grim_calm:
		list.append(["≋ CALM", Color(0.35, 0.45, 0.55)])
	elif keel_haul:
		list.append(["≋ HAUL", Color(0.6, 0.55, 0.35)])
	elif weeping_tide:
		list.append(["≋ TEARS", Color(0.4, 0.55, 0.65)])
	elif deep_draught:
		list.append(["≋ DRAUGHT", Color(0.3, 0.5, 0.55)])
	elif thick_tide:
		list.append(["≋ THICK", Color(0.45, 0.4, 0.55)])
	elif slack_line:
		list.append(["≋ SLACK", Color(0.4, 0.6, 0.5)])
	elif low_lantern:
		list.append(["≋ LANTERN", Color(0.6, 0.5, 0.3)])
	elif mirage_sea:
		list.append(["≋ MIRAGE", Color(0.55, 0.6, 0.55)])
	elif bilge_lull:
		list.append(["≋ LULL", Color(0.3, 0.35, 0.55)])
	if Stats.soul_sealed:
		list.append(["PRICE", Color(0.9, 0.2, 0.25)])
	if Stats.curse_dmg > 0.0:
		list.append(["PACT +%d%%" % int(Stats.curse_dmg * 100.0), Color(0.95, 0.25, 0.2)])
	if Stats.curse_xp > 0.0:
		list.append(["+%d%% XP" % int(Stats.curse_xp * 100.0), Color(0.8, 0.55, 1.0)])
	if omen_name != "":
		var otxt := "☗ %d oaths" % omen_count if omen_count >= 3 else "☗ " + omen_name
		list.append([otxt, Color(0.9, 0.7, 1.0)])
	if player.get("root_t") != null and player.root_t > 0.0:
		list.append(["CAGED", Color(0.6, 0.4, 1.0)])
	if combo >= 8:
		list.append(["CMB x%d" % combo, Color(1.0, 0.55, 0.15)])
	if Stats.warcry_t > 0.0:
		list.append(["WAR +50% ATK", Color(1.0, 0.3, 0.2)])
	if Stats.berserk > 0.0 and player.hp < player.max_hp * 0.35:
		list.append(["BSK +%d%% ATK" % int(Stats.berserk * 100.0), Color(0.9, 0.15, 0.3)])
	if Stats.mahzan_debt > 0.0:
		list.append(["DEBT -%d HP" % int(Stats.mahzan_debt), Color(0.6, 0.4, 0.9)])
	if player.get("chill_t") != null and player.chill_t > 0.0:
		list.append(["CHILLED", Color(0.5, 0.8, 1.0)])
	if player.get("silence_t") != null and player.silence_t > 0.0:
		list.append(["✦ SILENCED", Color(1.0, 0.3, 0.45)])
	if player.get("weak_t") != null and player.weak_t > 0.0:
		list.append(["WEAKENED", Color(0.95, 0.65, 0.3)])
	if player.get("rust_t") != null and player.rust_t > 0.0:
		list.append(["RUSTED", Color(0.75, 0.55, 0.35)])
	if player.get("slip_t") != null and player.slip_t > 0.0:
		list.append(["SLIP", Color(0.45, 0.7, 0.9)])
	if player.hp <= player.max_hp * 0.2 and not player.dead:
		list.append(["⚑ LAST STAND +25% ATK", Color(1.0, 0.35, 0.25)])
	if vials > 1:
		list.append(["⚗ VIALS x%d" % vials, Color(0.5, 0.9, 0.75)])
	var sig := ""
	for b in list:
		sig += String(b[0]) + "|"
	if sig == _buff_sig:
		return
	_buff_sig = sig
	for c in ui.buffs.get_children():
		c.queue_free()
	for b in list:
		var p := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.05, 0.05, 0.1, 0.85)
		psb.border_color = Color(b[1])
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(5)
		psb.set_content_margin_all(4)
		p.add_theme_stylebox_override("panel", psb)
		var l := Label.new()
		l.text = String(b[0])
		l.modulate = Color(b[1])
		l.add_theme_font_size_override("font_size", 15)
		p.add_child(l)
		ui.buffs.add_child(p)


func _rebuild_chips() -> void:
	for c in ui.chips.get_children():
		c.queue_free()
	for id in Stats.relics:
		var it: Dictionary = ITEMS.DB[id]
		var p := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.1, 0.1, 0.16, 0.9)
		psb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(6)
		psb.set_content_margin_all(6)
		p.add_theme_stylebox_override("panel", psb)
		var l := Label.new()
		l.text = it["chip"]
		l.add_theme_font_size_override("font_size", 16)
		p.add_child(l)
		ui.chips.add_child(p)
		p.pivot_offset = p.size * 0.5
		p.scale = Vector2(0.6, 0.6)
		var cptw: Tween = p.create_tween()
		cptw.tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if Stats.relics.size() >= 5:
		_ach("r5")


func _show_banner(title: String, sub: String, col: Color = Color(1.0, 0.85, 0.4)) -> void:
	ui.banner_t.text = title
	ui.banner_t.modulate = col
	# judul panjang mengecil biar tak pernah kepotong tepi 540px
	var tl := title.length()
	ui.banner_t.add_theme_font_size_override("font_size", 64 if tl <= 12 else (52 if tl <= 17 else 40))
	ui.banner_sub.text = sub
	ui.banner.visible = true
	ui.dim.visible = true
	ui.banner_t.pivot_offset = ui.banner_t.size * 0.5
	ui.banner_t.scale = Vector2(0.7, 0.7)
	ui.banner_t.modulate.a = 0.0
	var btw: Tween = ui.banner_t.create_tween()
	btw.set_parallel(true)
	btw.tween_property(ui.banner_t, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	btw.tween_property(ui.banner_t, "modulate:a", 1.0, 0.25)
	ui.banner_sub.modulate.a = 0.0
	ui.banner_sub.position.y += 14
	var bstw: Tween = ui.banner_sub.create_tween()
	bstw.set_parallel(true)
	bstw.tween_interval(0.15)
	bstw.chain().tween_property(ui.banner_sub, "modulate:a", 1.0, 0.3)
	var bsy: float = ui.banner_sub.position.y - 14
	bstw.parallel().tween_property(ui.banner_sub, "position:y", bsy, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_banner() -> void:
	ui.banner.visible = false
	if not Stats.draft_open:
		ui.dim.visible = false


# ---------------- per-frame ----------------

func _process(delta: float) -> void:
	if player != null and is_instance_valid(player) and run_state == "playing":
		run_time += delta
		floor_t += delta
		if trial_atk_t > 0.0:
			trial_atk_t -= delta
			if trial_atk_t <= 0.0:
				Stats.buff_atk_pct -= 0.15
				player.refresh_stats()
				toast("The new blade cools — trial over")
		if ui.has("time_label"):
			ui.time_label.text = "%d:%02d" % [int(run_time) / 60, int(run_time) % 60]
		if brine_callus:
			var under_half: bool = player.hp < Stats.get_stat("max_hp") * 0.5
			if under_half and not callus_on:
				callus_on = true
				Stats.buff_armor += 2
				player.refresh_stats()
			elif not under_half and callus_on:
				callus_on = false
				Stats.buff_armor -= 2
				player.refresh_stats()
		if Stats.relics.has("pilot_fish"):
			var wounded: bool = player.hp < Stats.get_stat("max_hp") * 0.5
			if wounded and not _pilot_on:
				_pilot_on = true
				Stats.buff_speed_pct += 0.08
				player.refresh_stats()
			elif not wounded and _pilot_on:
				_pilot_on = false
				Stats.buff_speed_pct -= 0.08
				player.refresh_stats()
		still_t = still_t + delta if player.move_input == Vector2.ZERO else 0.0
		var rope_on := Stats.relics.has("steady_rope") and still_t >= 1.0
		if rope_on != _rope_active:
			_rope_active = rope_on
			Stats.buff_atk_pct += 0.08 if rope_on else -0.08
		if not pool_positions.is_empty() and pool_healed < 4.0 and player.hp < Stats.get_stat("max_hp"):
			for pp in pool_positions:
				if player.global_position.distance_to(pp["pos"]) < float(pp["r"]) + 0.3 * info.tile:
					player.hp = minf(Stats.get_stat("max_hp"), player.hp + delta * 0.45)
					player.hp_changed.emit(player.hp)
					pool_healed += delta * 0.45
					if not pool_touched:
						pool_touched = true
						_quest_event("pool")
					break
		for ln2 in lanterns:
			if is_instance_valid(ln2) and player.global_position.distance_to(ln2.global_position) < 3.0 * info.tile:
				if player.hp < Stats.get_stat("max_hp"):
					var lh: float = Stats.get_stat("max_hp") * 0.02 * delta * (1.0 + 0.5 * int(Stats.meta.get("lampwage", 0))) * (1.5 if lantern_oil else 1.0)
					player.hp = minf(player.hp + lh, Stats.get_stat("max_hp"))
					player.hp_changed.emit(player.hp)
					lantern_healed += lh
					if not lantern_touched:
						lantern_touched = true
						_quest_event("lantern")
					if lantern_healed >= Stats.get_stat("max_hp") * 0.3:
						lantern_healed = -9999.0
						_quest_event("lantern")
				if not bool(ln2.get_meta("seen", false)):
					ln2.set_meta("seen", true)
					toast("☆ SOUL LANTERN — its light mends you")
		# STORM CELLAR: petir menyambar musuh acak tiap ~4.5 detik
		if storm_cellar:
			storm_t -= delta
			if storm_t <= 0.0:
				storm_t = 4.5
				var pool_s: Array = []
				for e2 in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e2) and e2.state != "dead" and e2.activated:
						pool_s.append(e2)
				if not pool_s.is_empty():
					var t2: Node3D = pool_s[rng.randi_range(0, pool_s.size() - 1)]
					Sfx.play("thunder")
					_burst(t2.global_position + Vector3(0, 0.6 * info.tile, 0), Color(0.7, 0.7, 1.2))
					_damage_number(t2.global_position + Vector3(0, 0.8 * info.tile, 0), "STRUCK", Color(0.75, 0.75, 1.3), false)
					t2.take_hit(t2.global_position + Vector3(0, 2.0, 0), 1.5)
		var k := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			k.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			k.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			k.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			k.x += 1.0
		if k != Vector2.ZERO:
			player.move_input = k.normalized()
		else:
			player.move_input = joystick.get_value()
		var attacking: bool = Input.is_key_pressed(KEY_SPACE) or atk_held
		if attacking:
			atk_hold_t += delta
			player.attack()
			var heavy_threshold := 0.4 if Stats.relics.has("pendulum") else 0.6
			if atk_hold_t >= heavy_threshold and not atk_charged:
				atk_charged = true
				Input.vibrate_handheld(60)
				ui.atk_btn.modulate = Color(1.35, 1.15, 0.6)
				var ctw: Tween = ui.atk_btn.create_tween()
				ctw.tween_property(ui.atk_btn, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			if atk_hold_t >= (0.4 if Stats.relics.has("pendulum") else 0.6):
				_heavy_attack()
			atk_hold_t = 0.0
			atk_charged = false
			ui.atk_btn.modulate = Color.WHITE
			ui.atk_btn.scale = Vector2.ONE
		if Input.is_key_pressed(KEY_H):
			_toggle_hero(true)

		_tick_skill_ui(delta)
		_refresh_buffs()

		# pelacakan ruangan -> kunci arena
		var ri := _room_at(player.global_position.z)
		if ri >= 0 and ri != current_room:
			current_room = ri
			if not discovered.has(ri):
				discovered[ri] = true
				rooms_floor += 1
				if rooms_floor == 10:
					_quest_event("roomfloor")
				if Stats.relics.has("sextant") and ri + 1 < info.ranges.size():
					discovered[ri + 1] = true
				_update_minimap()
			_on_room_enter(ri)

		# preview hero ikut muter walau game pause? tidak perlu, layar hero punya sendiri
		# tutorial langkah 0: gerak
		if tut_active and tut_step == 0:
			moved_accum += player.global_position.distance_to(tut_last_pos)
			tut_last_pos = player.global_position
			if moved_accum > 1.2 * info.tile:
				tut_step = 1
				_tut_show("Tap the red ATK button to slash")
				_quest_event("moved")

		# motes ambient mengikuti pemain
		if motes_ref != null and is_instance_valid(motes_ref):
			motes_ref.global_position = player.global_position + Vector3(0, 1.1, -1.0 * info.tile)

		# quest "moved": akumulasi gerak pemain
		if quest_idx < quest_steps.size() and String(quest_steps[quest_idx].get("kind", "")) == "moved":
			quest_moved += player.global_position.distance_to(quest_last_p)
			quest_last_p = player.global_position
			if quest_moved > 1.2 * info.tile:
				_quest_event("moved")

		# kombo kill: decay + label
		if bloodtide_t > 0.0:
			bloodtide_t = maxf(0.0, bloodtide_t - delta)
			if fog_song_t > 0.0:
				fog_song_t = maxf(0.0, fog_song_t - delta)
				if fog_song_t == 0.0:
					Stats.buff_speed_pct -= 0.2
					if player != null and is_instance_valid(player):
						player.refresh_stats()
		if combo_t > 0.0:
			combo_t -= delta
			if ui.has("combo_bar"):
				var cbf: ColorRect = ui.combo_bar
				var f2: float = clampf(combo_t / (5.8 if Stats.relics.has("relik_tempo") else 4.0), 0.0, 1.0)
				cbf.offset_right = -140 + 280.0 * f2
				cbf.offset_left = -140
				cbf.visible = combo >= 3
			if combo_t <= 0.0:
				_combo_set(0)

		# bar HP boss mengikuti sisa nyawa
		if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.activated:
			_boss_bar_show()
			var frac: float = clampf(boss_ref.hp / boss_ref.hp_max, 0.0, 1.0)
			var target := frac * 100.0
			if absf(ui.boss_fill.value - target) > 0.4:
				var bftw: Tween = create_tween()
				bftw.tween_property(ui.boss_fill, "value", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				ui.boss_fill.value = target
		else:
			_boss_bar_hide()

		# titik musuh di minimap
		map_t -= delta
		if map_t <= 0.0:
			map_t = 0.25
			_update_minimap()

		# peti harta — atau peti PALSU (mimic): 35% mulai lantai 2
		if not chest_opened and info.get("chest") != null and is_instance_valid(info.chest):
			if player.global_position.distance_to(info.chest.global_position) < 0.6 * info.tile:
				chest_opened = true
				_quest_event("open_chest")
				if mimic_pending:
					mimic_pending = false
					Sfx.play("mimic")
					trauma = 0.8
					_burst(info.chest.global_position, Color(1.0, 0.35, 0.2))
					toast("MIMIC! It's alive!")
					for mk in range(2):
						var off := Vector3((mk - 0.5) * 0.9 * info.tile, 0, 0.7 * info.tile)
						_spawn_enemy({"pos": info.chest.global_position + off, "room": int(info.get("room_count", 1)) - 1}, "chaser", false)
					if Stats.weapon_id != "mimic_fang" and rng.randf() < 0.2:
						spawn_weapon_drop(info.chest.global_position + Vector3(0, 0, 0.45 * info.tile), "mimic_fang")
				elif cursed_chest:
					cursed_chest = false
					_quest_event("cursed_chest")
					_ach("hex1")
					Sfx.play("roar")
					trauma = 0.9
					_lvl_banner("☠ CURSED HOARD — THE DEAD OBJECT")
					var table2: Array = biome["enemies"]
					var last_r2: int = int(info.get("room_count", 1)) - 1
					for mk2 in range(3):
						var off2 := Vector3((mk2 - 1) * 0.9 * info.tile, 0, (0.4 + mk2 * 0.3) * info.tile)
						_spawn_enemy({"pos": info.chest.global_position + off2, "room": last_r2}, String(table2[rng.randi_range(0, table2.size() - 1)]), mk2 == 0)
					var pool2: Array = []
					for rid3 in ITEMS.DB:
						if int(ITEMS.DB[rid3]["rarity"]) >= 2 and not Stats.relics.has(rid3):
							pool2.append(rid3)
					if not pool2.is_empty():
						var rid4: String = pool2[rng.randi_range(0, pool2.size() - 1)]
						Stats.add_relic(rid4)
						Stats.save_run()
						toast("Cursed spoils — epic relic: " + String(ITEMS.DB[rid4]["name"]))
					M.paint(info.chest, M.toon(dungeon_tex, Color(0.45, 0.4, 0.32), 0.1))
				else:
					player.hp = Stats.get_stat("max_hp")
					player.hp_changed.emit(player.hp)
					Stats.add_xp(3)
					var chest_pay: int = 8 + (4 if abyssal_patience else 0) + (8 if bone_market else 0)
					Stats.earn_souls(chest_pay)
					if bone_market:
						player.hp = maxf(1.0, player.hp - Stats.get_stat("max_hp") * 0.05)
						player.hp_changed.emit(player.hp)
						_damage_number(info.chest.global_position + Vector3(0, 1.1 * info.tile, 0), "LID BITE — −5%", Color(1.0, 0.4, 0.4), true)
					if abyssal_patience:
						_quest_event("patient")
					_souls_l()
					_quest_event("chest_open")
					Sfx.play("chest")
					_burst(info.chest.global_position, Color(1.0, 0.85, 0.3))
					_souls(info.chest.global_position, 8, Color(1.0, 0.8, 0.35))
					M.paint(info.chest, M.toon(dungeon_tex, Color(0.45, 0.4, 0.32), 0.1))
					if QDB.is_boss_floor(Stats.floor_num):
						spawn_weapon_drop(info.chest.global_position + Vector3(0.7 * info.tile, 0, 0.3 * info.tile), WDB.roll_drop(rng, Stats.weapon_id))
						toast("King's spoils: HP restored, +3 XP — a weapon rests beside the chest")
					else:
						toast("Treasure Chest: HP restored, +3 XP")
					if gilded_chest:
						gilded_chest = false
						_quest_event("gilded_chest")
						var pool: Array = []
						for rid in ITEMS.DB:
							if int(ITEMS.DB[rid]["rarity"]) >= 1:
								pool.append(rid)
						var rid2: String = pool[rng.randi_range(0, pool.size() - 1)]
						Stats.add_relic(rid2)
						Stats.save_run()
						_souls(info.chest.global_position, 14, Color(1.0, 0.85, 0.3))
						_lvl_banner("☆ GILDED SPOILS")
						if tide_lends:
							Stats.earn_souls(3)
							_souls_l()
							toast("THE TIDE LENDS — +3 souls")
						if Stats.relics.has("gilded_keel"):
							Stats.earn_souls(2)
							_souls_l()
							toast("GILDED KEEL — +2 souls")
						toast("Gilded chest — relic inside: " + String(ITEMS.DB[rid2]["name"]) + "!")

	if player != null and is_instance_valid(player) and cam != null:
		var s: float = info.get("tile", 4.0)
		var target: Vector3 = player.global_position + Vector3(0.0, 3.0 * s, 2.6 * s)
		cam.global_position = cam.global_position.lerp(target, 1.0 - pow(0.0001, delta))
		if trauma > 0.0:
			trauma = max(0.0, trauma - delta * 1.8)
			cam.global_position += Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)) * trauma * 0.18
		cam.look_at(player.global_position + Vector3(0, 0, -0.9 * s))
	# Prayer of the Fallen: berdiri di atas noda darah 2s -> +1 jiwa (sekali per lantai)
	if not prayed and player != null and is_instance_valid(player) and not stain_positions.is_empty():
		var near_stain := false
		for sp5 in stain_positions:
			if player.global_position.distance_to(sp5) < 0.6 * info.tile:
				near_stain = true
				break
		if near_stain:
			pray_t += delta
			if pray_t >= 2.0:
				prayed = true
				Stats.earn_souls(1)
				_souls_l()
				Sfx.play("whisper")
				_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), "A PRAYER FOR THE FALLEN — +1 soul", Color(0.6, 0.85, 1.0), true)
				_quest_event("pray")
				Stats.prays += 1
				if Stats.prays >= 5:
					_ach("pious")
				if Stats.prays >= 15:
					_ach("devout")
		else:
			pray_t = 0.0
	# panah elite off-screen: arahkan ke elite teraktivasi terdekat
	if ui.has("elite_arrow"):
		var earr2: Label = ui["elite_arrow"]
		var be: Node3D = null
		var bd2 := INF
		for f in get_tree().get_nodes_in_group("enemies"):
			if f.get("elite") == true and String(f.get("state")) != "dead" and bool(f.get("activated")):
				var dd: float = f.global_position.distance_to(player.global_position)
				if dd < bd2:
					bd2 = dd
					be = f
		if be == null:
			for f3 in get_tree().get_nodes_in_group("enemies"):
				if String(f3.get("state")) == "dead" or not bool(f3.get("activated")):
					continue
				if not ["orator", "necromancer", "hexer"].has(String(f3.get("arch_id"))):
					continue
				var dd3: float = f3.global_position.distance_to(player.global_position)
				if dd3 < bd2:
					bd2 = dd3
					be = f3
		var shown := false
		if be != null:
			var sp2: Vector2 = cam.unproject_position(be.global_position + Vector3(0, 0.8 * info.get("tile", 4.0), 0))
			var vp2: Vector2 = get_viewport().get_visible_rect().size
			if sp2.x < -10.0 or sp2.x > vp2.x + 10.0 or sp2.y < -10.0 or sp2.y > vp2.y + 10.0:
				var c2: Vector2 = vp2 * 0.5
				var d2v: Vector2 = (sp2 - c2).normalized()
				var marg := 46.0
				var tx: float = (vp2.x * 0.5 - marg) / maxf(0.001, absf(d2v.x))
				var ty: float = (vp2.y * 0.5 - marg) / maxf(0.001, absf(d2v.y))
				var t2: float = minf(tx, ty)
				earr2.position = c2 + d2v * t2
				earr2.rotation = atan2(d2v.y, d2v.x) + PI * 0.5
				earr2.pivot_offset = earr2.size * 0.5
				earr2.scale = Vector2.ONE * (1.0 + 0.18 * sin(float(Time.get_ticks_msec()) * 0.012))
				shown = true
		earr2.visible = shown


func _cam_snap() -> void:
	var s: float = info.get("tile", 4.0)
	if player != null and cam != null:
		cam.global_position = player.global_position + Vector3(0.0, 3.0 * s, 2.6 * s)
		cam.look_at(player.global_position + Vector3(0, 0, -0.9 * s))


# ---------------- autotest v4 ----------------

func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SAVED ", ProjectSettings.globalize_path(path))


func _nearest_foe() -> Node3D:
	var foes := get_tree().get_nodes_in_group("enemies")
	var best: Node3D = null
	var bd := 1e9
	for f in foes:
		var d: float = player.global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	return best


func _run_autotest() -> void:
	for i in range(20):
		await get_tree().process_frame
	_shot("res://out_v4_1_spawn.png")

	# bukti audio benar-benar berbunyi (bank .wav termuat)
	Sfx.play("click")
	await get_tree().process_frame
	print("SFX playing=%s last=%s" % [str(Sfx.any_playing()), Sfx.last_played])

	# bukti tabrakan: jalan ke barat, harus terhenti tembok
	var x0: float = player.global_position.x
	joystick.fake = Vector2(-1, 0)
	await get_tree().create_timer(1.6).timeout
	joystick.fake = Vector2.ZERO
	var dx: float = player.global_position.x - x0
	print("COLLISION dx=%.2f tile=%.2f (terhenti tembok bila |dx| < 3 tile)" % [dx, info.tile])
	await get_tree().create_timer(0.3).timeout

	# bukti serangan + senjata terpasang
	player.attack()
	await get_tree().create_timer(0.22).timeout
	print("ATK_ANIM=", player.ap.current_animation, " WEAPON=", Stats.weapon_id)
	_shot("res://out_v4_2_attack.png")
	await get_tree().create_timer(0.5).timeout

	# bukti GERBANG: ruangan 0 terkunci selama musuh hidup
	var g0 = gates.get(0)
	if g0 != null:
		print("GATE0 open=%s (harus false saat musuh hidup)" % str(g0.open))
		player.global_position = g0.global_position + Vector3(0, 0, 0.8 * info.tile)
		await get_tree().create_timer(0.2).timeout
		joystick.fake = Vector2(0, -1)
		await get_tree().create_timer(1.2).timeout
		joystick.fake = Vector2.ZERO
		var passed: bool = player.global_position.z < g0.global_position.z - 0.2 * info.tile
		print("GATE BLOCK passed=%s (harus false) pz=%.1f gate_z=%.1f" % [str(passed), player.global_position.z, g0.global_position.z])
		player.global_position = info.player_pos
		await get_tree().create_timer(0.2).timeout

	# bukti pickup senjata -> masuk inventaris
	var pk := spawn_weapon_drop(player.global_position + Vector3(0.6 * info.tile, 0, 0), "bone_axe")
	var tw := 0.0
	while is_instance_valid(pk) and tw < 3.0:
		var to: Vector3 = pk.global_position - player.global_position
		joystick.fake = Vector2(to.x, to.z).normalized()
		tw += 0.12
		await get_tree().create_timer(0.12).timeout
	joystick.fake = Vector2.ZERO
	print("PICKUP weapon=%s ATK=%.1f owned=%s" % [Stats.weapon_id, Stats.get_stat("atk"), str(Stats.owned_weapons)])
	_shot("res://out_v4_3_weapon.png")

	# bersihkan seluruh lantai (multi-ruangan + gerbang) dengan anti-mentok
	player.hp = Stats.get_stat("max_hp")
	player.hp_changed.emit(player.hp)
	var xp_mark := Stats.level * 1000 + Stats.xp
	var draft_shot := false
	var elapsed := 0.0
	var last_p: Vector3 = player.global_position
	var stuck := 0.0
	var strafe := 1.0
	while run_state == "playing" and elapsed < 150.0:
		while Stats.draft_open:
			if not draft_shot:
				await get_tree().process_frame
				await get_tree().process_frame
				_shot("res://out_v4_4_draft.png")
				draft_shot = true
			_pick_relic(0)
			await get_tree().create_timer(0.1).timeout
		var foe := _nearest_foe()
		if foe == null:
			break
		# waypoint: kalau musuh di ruangan lain, bidik pintu gerbangnya dulu
		var target: Vector3 = foe.global_position
		var ri_now := _room_at(player.global_position.z)
		if ri_now >= 0 and foe.room_idx != ri_now:
			var gi: int = ri_now if foe.room_idx > ri_now else foe.room_idx
			if gates.has(gi):
				target = gates[gi].global_position
				if player.global_position.distance_to(target) < 0.45 * info.tile:
					target = foe.global_position
		var d: float = player.global_position.distance_to(target)
		if foe.room_idx == ri_now and d <= info.tile * 0.7:
			joystick.fake = Vector2.ZERO
			player.move_input = Vector2.ZERO
			player.attack()
		elif d > info.tile * 0.25:
			var to2: Vector3 = target - player.global_position
			var mv := Vector2(to2.x, to2.z).normalized()
			if player.global_position.distance_to(last_p) < 0.04 * info.tile:
				stuck += 0.22
			else:
				stuck = 0.0
			if stuck > 0.66:
				strafe = -strafe
				stuck = 0.0
			if stuck > 0.3:
				mv = mv.rotated(1.2 * strafe)
			joystick.fake = mv
		else:
			joystick.fake = Vector2.ZERO
			player.move_input = Vector2.ZERO
			player.attack()
		if player.hp < 2.0:
			player.hp = Stats.get_stat("max_hp")
			player.hp_changed.emit(player.hp)
		last_p = player.global_position
		await get_tree().create_timer(0.22).timeout
		elapsed += 0.22
	joystick.fake = Vector2.ZERO
	player.move_input = Vector2.ZERO

	await get_tree().create_timer(1.2).timeout
	var all_open := true
	for gi in gates:
		if not gates[gi].open:
			all_open = false
	print("GATES all_open=%s (harus true setelah bersih)" % str(all_open))
	print("GEMS xp_mark=%d -> %d (naik = permata XP jalan)" % [xp_mark, Stats.level * 1000 + Stats.xp])
	_shot("res://out_v4_5_cleared.png")
	print("FASE1 state=%s kills=%d level=%d rooms=%d" % [run_state, Stats.kills, Stats.level, info.get("room_count", 1)])

	# turun lantai
	_on_banner_tap()
	for i in range(12):
		await get_tree().process_frame
	print("FLOOR2 enemies=%d biome=%s rooms=%d" % [get_tree().get_nodes_in_group("enemies").size(), biome["name"], info.get("room_count", 1)])

	# SKILL: paksa level supaya semua terbuka
	Stats.level = maxi(Stats.level, 6)
	var p0: Vector3 = player.global_position
	player.move_input = Vector2(0, -1)
	_cast_skill("dash")
	print("DBG dash_t=%.2f dir=%s speed=%.1f paused=%s state=%s" % [player.dash_t, str(player.dash_dir), player.speed, str(get_tree().paused), run_state])
	await get_tree().create_timer(0.45).timeout
	player.move_input = Vector2.ZERO
	print("SKILL dash dist=%.2f cd=%.1f (harus > 1.5)" % [player.global_position.distance_to(p0), skill_cd["dash"]])

	# dekati musuh untuk whirl + thunder
	var foe2 := _nearest_foe()
	var wt := 0.0
	while foe2 != null and wt < 10.0:
		foe2 = _nearest_foe()
		if foe2 == null:
			break
		var d2: float = player.global_position.distance_to(foe2.global_position)
		if d2 < info.tile * 0.8:
			break
		var to3: Vector3 = foe2.global_position - player.global_position
		joystick.fake = Vector2(to3.x, to3.z).normalized()
		wt += 0.2
		await get_tree().create_timer(0.2).timeout
	joystick.fake = Vector2.ZERO
	if foe2 != null:
		var hp0: float = foe2.hp
		_cast_skill("whirl")
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(foe2):
			print("SKILL whirl dmg=%.1f (harus > 0)" % (hp0 - foe2.hp))
		else:
			print("SKILL whirl membunuh musuh (dmg >= sisa hp)")
		foe2 = _nearest_foe()
		if foe2 != null:
			# teleport dekat supaya petir pasti kena (jangkauan 2.5 tile)
			player.global_position = foe2.global_position + Vector3(0.6 * info.tile, 0, 0)
			await get_tree().create_timer(0.1).timeout
			var hp1: float = foe2.hp
			_cast_skill("thunder")
			await get_tree().create_timer(0.18).timeout
			_shot("res://out_v4_6_skills.png")
			if is_instance_valid(foe2) and foe2.get("state") != "dead":
				print("SKILL thunder dmg=%.1f stun=%.2f (harus > 0)" % [hp1 - foe2.hp, foe2.stun_t])
			else:
				print("SKILL thunder membunuh musuh (dmg=%.1f tersalurkan)" % (hp1))

	# pause menu: buka -> screenshot -> resume, tidak boleh soft-lock
	_toggle_pause()
	for _i in range(6):
		await get_tree().process_frame
	_shot("res://out_v5_12_pause.png")
	print("PAUSE open=%s paused=%s (harus true)" % [pause_panel.visible, get_tree().paused])
	_toggle_pause()
	await get_tree().process_frame
	print("PAUSE resume=%s (harus true)" % (not get_tree().paused and not pause_panel.visible))

	# layar hero + ganti senjata dari inventaris
	_toggle_hero(true)
	await get_tree().process_frame
	await get_tree().process_frame
	_shot("res://out_v4_7_hero.png")
	var other: String = "rusty_blade" if Stats.weapon_id != "rusty_blade" else ("bone_axe" if Stats.owned_weapons.has("bone_axe") else String(Stats.owned_weapons[0]))
	_hero_equip(other)
	await get_tree().process_frame
	print("EQUIP weapon=%s (berubah dari layar hero)" % Stats.weapon_id)
	_toggle_hero(false)

	# mati -> retry dari lantai 1
	player.invuln = 0.0
	player.take_hit(player.global_position + Vector3(1, 0, 0), 999)
	await get_tree().create_timer(0.6).timeout
	_shot("res://out_v4_8_died.png")
	print("DEATH state=%s" % run_state)
	_on_banner_tap()
	for i in range(12):
		await get_tree().process_frame
	print("RETRY floor=%d state=%s" % [Stats.floor_num, run_state])
	# ---- v5: lantai BOSS (loncat ke 5 lewat jalur normal) ----
	Stats.floor_num = 4
	run_state = "cleared"
	_on_banner_tap()
	for i in range(16):
		await get_tree().process_frame
	var boss = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_boss:
			boss = e
	print("BOSS spawned=%s quest_idx=%d steps=%d" % [str(boss != null), quest_idx, quest_steps.size()])
	if boss != null:
		# aktifkan boss + cek bar HP
		player.global_position = boss.global_position + Vector3(0, 0, 3.0 * info.tile)
		await get_tree().create_timer(0.4).timeout
		print("BOSS activated=%s bar=%s hp=%.0f/%.0f" % [str(boss.activated), str(ui.boss_bar.visible), boss.hp, boss.hp_max])
		_shot("res://out_v5_9_boss.png")
		# enrage saat hp < 50%
		player.invuln = 9.0
		boss.hp = boss.hp_max * 0.45
		await get_tree().create_timer(0.4).timeout
		print("BOSS enraged=%s (harus true)" % str(boss.enraged))
		# slam AoE
		player.global_position = boss.global_position + Vector3(0.5 * info.tile, 0, 0.5 * info.tile)
		boss.slam_t = 0.0
		await get_tree().create_timer(1.3).timeout
		_shot("res://out_v5_10_slam.png")
		# summon antek
		var n0 := get_tree().get_nodes_in_group("enemies").size()
		boss.summon_t = 0.0
		await get_tree().create_timer(0.35).timeout
		var n1 := get_tree().get_nodes_in_group("enemies").size()
		print("BOSS summon %d -> %d (harus naik)" % [n0, n1])
		# bunuh boss -> quest boss_kill + victory
		boss.take_hit(player.global_position, 9999)
		await get_tree().create_timer(0.9).timeout
		print("BOSS dead=%s boss_kills=%d quest_idx=%d" % [str(boss_ref == null), Stats.boss_kills, quest_idx])
		_shot("res://out_v5_11_bossdown.png")

	# altar: kalau ada di lantai ini, picu + pilih berkat
	if shrine_ref != null and is_instance_valid(shrine_ref):
		_on_shrine_invoked(shrine_ref)
		for i in range(24):
			await get_tree().process_frame
			if dlg == null or not dlg.active:
				break
			if i > 4 and dlg._choices.size() > 0:
				dlg.choose(0)
		await get_tree().process_frame
		print("SHRINE buff_atk=%.2f paused=%s" % [Stats.buff_atk_pct, str(get_tree().paused)])

	print("FPS=", Engine.get_frames_per_second())
	print("SAVE=", FileAccess.get_file_as_string("user://save.json"))
	print("AUTOTEST V5 DONE")
	get_tree().quit()
