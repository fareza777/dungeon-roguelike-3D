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
const DUNGEON := "res://assets/dungeon/"

# baris lore dunia — bisikan Oracle saat menyentuh batu pengetahuan
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
	"Somewhere below, the Soul Forge still burns for a smith who never came back for his blade."
]

var dungeon_tex: Texture2D
var skeleton_tex: Texture2D

var room: Node3D = null
var info := {}
var biome := {}
var _biomes_seen := {}
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
var storm_t := 0.0
var nemesis_spawned := false # musuh yang membunuhmu run lalu — kembali lebih kuat
var nemesis_warned := false # nemesis story beat — 1だけ
var toast_tween: Tween = null

# polish r2: pause, ringkasan run, transisi fade, juice vfx
var paused_ui := false
var kills_run := 0
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

# prestasi lintas run (definisi di stats.gd: ACH_DEF) + varian bos per 5 lantai
const BOSS_TIERS := [
	{"name": "BONE KING", "tint": Color(1.05, 1.05, 1.05),
		"warn": "Careful — the Bone King lurks at the end of this corridor. If the ground shakes red, GET OUT.",
		"taunt": "YOU AGAIN, LITTLE FRAGRANT ONE. I'll add your bones to my throne.",
		"banter": ["RATTLE ME HARDER, WORM.", "THE THRONE... TREMBLES?"],
		"death": "...impossible... my throne... cracking..."},
	{"name": "EMBER KING", "tint": Color(1.4, 0.65, 0.4),
		"warn": "He rose from his own ashes — the Ember King burns through this floor.",
		"taunt": "YOU AGAIN? I'LL BURN THE FLESH OFF YOUR BONES THIS TIME.",
		"banter": ["YOUR FLESH SMELLS DONE ALREADY.", "ASHES... I NEED NO FLESH TO KILL YOU."],
		"death": "...embers... dying... again..."},
	{"name": "FROST KING", "tint": Color(0.55, 0.85, 1.45),
		"warn": "His bones turned to ice — the Frost King chills the air itself.",
		"taunt": "BONES DON'T SHIVER. YOURS WILL, WHEN I FREEZE THEM SOLID.",
		"banter": ["FEEL YOUR BLOOD TURN TO ICE?", "COLD... I AM THE COLD ITSELF!"],
		"death": "...cold... so cold... the throne... melts..."},
	{"name": "FERAL KING", "tint": Color(0.65, 1.35, 0.55),
		"warn": "Last warning — the Feral King has lost all patience. And all mercy.",
		"taunt": "THE THRONE IS MINE FOREVER. I'LL WEAR YOUR SKULL AS A CROWN.",
		"banter": ["RAAAGH! HOLD STILL, PREY!", "NO — NO PREY BITES THE KING!"],
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
	"weeper": ["The Weeper", "A wailing priest who knits his flock's bones back together. Silence him first."],
	"bone_king": ["The Kings", "One throne, many forms. Every five floors he waits."],
}
const VANE_BIOME := {
	"Catacombs": "I marched these halls a captain, boy. Now I rattle in them.",
	"Ember Crypt": "I burned once. Trust me — the bones complain.",
	"Frozen Deep": "Aldric left me to freeze once. I prefer the sword.",
	"Verdant Ruin": "The Oracle's gardens... she wept the day we walled them in.",
	"The Abyss": "Down here even my chains feel heavier. Stay close.",
}
const KILLER_NAMES := {
	"chaser": "a Skeleton Chaser", "rogue": "a Shadow Rogue", "mage": "a Bone Mage",
	"brute": "a Bone Brute", "bomber": "a Boom Bones", "archer": "a Skeletal Archer",
	"necromancer": "the Necromancer", "crawler": "a Crypt Crawler", "gaoler": "the Gaoler", "weeper": "the Weeper", "sentinel": "a Bone Sentinel", "shade": "the Shade", "hexer": "the Hex Priest", "spiker": "a Spiked Cadaver", "lurker": "the Dweller", "golem": "the Bone Golem",
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
		"The Abyss":
			return "frozen"
	return "dungeon"


func _boss_tier() -> Dictionary:
	# final run: lantai 25 = wujud sejati Bone King
	if Stats.floor_num >= 25:
		return {"name": "THE UNDYING KING", "tint": Color(1.5, 0.3, 0.7),
			"warn": "This is his deepest hall — the throne beneath all thrones. End this, Kael.",
			"taunt": "I HAVE WORN A THOUSAND CROWNS. YOURS WILL BE THE FINEST.",
			"banter": ["I HAVE DIED A THOUSAND DEATHS. YOURS IS NEXT.", "THE CROWN... WILL NOT... FALL!"],
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
var dlg: DialogueUI = null
var dlg_pending_choice := -1
var oracle_bargained := false # Oracle's Bargain: sekali per run
var mahzan_met := 0 # kunjungan Mahzan dalam run ini — dialognya berevolusi
var map_dots: Array = []
var map_t := 0.0

# gerbang / ruangan
var gates := {}
var current_room := -1

# skill
var skill_cd := {"dash": 0.0, "whirl": 0.0, "thunder": 0.0, "warcry": 0.0, "nova": 0.0, "judge": 0.0, "sunder": 0.0, "chains": 0.0, "storm": 0.0, "mend": 0.0, "rites": 0.0, "seismic": 0.0}
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
		kills_run = 0
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
		sun.light_color = Color(0.7, 0.6, 1.05)
		sun.light_energy = 1.05


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

func _new_run(new_seed: int) -> void:
	seed_val = new_seed
	run_state = "playing"
	chest_opened = false
	current_room = -1
	for id in skill_cd:
		skill_cd[id] = 0.0
	biome = BIO.for_floor(Stats.floor_num)
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = Node3D.new()
	room.name = "Room"
	add_child(room)
	info = RG.build_floor(room, seed_val, Stats.floor_num)
	stain_count = 0
	var boss_floor: bool = QDB.is_boss_floor(Stats.floor_num)
	# event langka: blood moon — langit merah, musuh lebih keras, XP lebih kaya
	blood_moon = Stats.floor_num >= 3 and not boss_floor and rng.randf() < 0.07
	# event langka #2: soul rush — kabut ungu, permata XP berlimpah, tithe jiwa saat clear
	soul_rush = not blood_moon and Stats.floor_num >= 4 and not boss_floor and rng.randf() < 0.07
	# event langka #3: fading light — obor padam, musuh lebih ganas, tithe jiwa saat clear
	fading_light = not blood_moon and not soul_rush and Stats.floor_num >= 6 and not boss_floor and rng.randf() < 0.06
	# event langka #4: echoing halls — lorong bergema, skill recharge 25% lebih cepat
	echoing = not blood_moon and not soul_rush and not fading_light and Stats.floor_num >= 5 and not boss_floor and rng.randf() < 0.06
	storm_cellar = not blood_moon and not soul_rush and not fading_light and not echoing and Stats.floor_num >= 10 and not boss_floor and rng.randf() < 0.05
	# event langka #6: gilded tides — timbunan muncul ke permukaan (lantai 12+): peti gilded + jiwa +1/kill
	gilded_tides = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and Stats.floor_num >= 12 and not boss_floor and rng.randf() < 0.05
	if gilded_tides:
		Stats.event_soul_bonus = 1
	# event langka #8: soul drift — nafas orang mati mengembara (lantai 13+): kunang berlimpah
	soul_drift = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and Stats.floor_num >= 13 and not boss_floor and rng.randf() < 0.05
	grave_hunger = not blood_moon and not soul_rush and not fading_light and not echoing and not storm_cellar and not gilded_tides and not soul_drift and Stats.floor_num >= 15 and not boss_floor and rng.randf() < 0.05
	storm_t = 4.0
	nemesis_spawned = false
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
	gilded_chest = (not mimic_pending and Stats.floor_num >= 4 and rng.randf() < 0.12) or (not mimic_pending and Stats.floor_num >= 2 and Stats.relics.has("kunci_osuarium"))
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
	var elite_chance: float = minf(0.08 + 0.02 * Stats.floor_num, 0.3)
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
		var is_elite := rng.randf() < elite_chance
		_spawn_enemy(sp, table[rng.randi_range(0, table.size() - 1)], is_elite, not is_elite and rng.randf() < 0.05)
	if boss_floor:
		var lr: Dictionary = info.ranges[last_room]
		_spawn_enemy({"pos": Vector3((lr["x0"] + lr["x1"]) * 0.5, 0.0, lr["z1"] + 1.6 * info.tile), "room": last_room}, "bone_king", false)
	else:
		# sarang sang juara (lantai 6+): satu ruangan berisi elite bergaransi
		champ_room = -1
		if Stats.floor_num >= 6 and last_room >= 2:
			champ_room = rng.randi_range(1, last_room - 1)
			if champ_room == ambush_room:
				champ_room = last_room - 1 if ambush_room != last_room - 1 else 1
			var cr: Dictionary = info.ranges[champ_room]
			var cpos := Vector3((cr["x0"] + cr["x1"]) * 0.5, 0.0, (cr["z0"] + cr["z1"]) * 0.5)
			_spawn_enemy({"pos": cpos, "room": champ_room}, table[rng.randi_range(0, table.size() - 1)], true)
			var cnd := get_tree().get_nodes_in_group("enemies")[get_tree().get_nodes_in_group("enemies").size() - 1]
			cnd.champion = true
		_spawn_traps(last_room)
		_spawn_urns(last_room)
		_spawn_shrine(last_room)
		_spawn_lore_stone(last_room)
		_spawn_cage(last_room)
		_spawn_wisps(last_room)
		_spawn_obelisks(last_room)
		_spawn_motes()
		if Stats.relics.has("tulang_kesatria"):
			_spawn_squire()
	# Sir Vane yang terbebaskan bertempur di setiap lantai hingga run berakhir
	if vane_freed_n > 0:
		_spawn_knight()
	else:
		vane_floors = 0
	_start_quests(boss_floor, int(info.get("room_count", 1)))
	_build_minimap()
	Sfx.play_music("boss" if boss_floor else _biome_track())
	ui.floor_label.text = "Floor %d • %s%s" % [Stats.floor_num, biome["name"], " (NG+%d)" % Stats.ng_plus if Stats.ng_plus > 0 else ""]
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
	_quest_event("reach_room", ri)
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
	_lvl_banner("SOUL RISEN!")
	_burst(player.global_position, Color(1.0, 0.9, 0.5))
	_souls(player.global_position, 16, Color(0.6, 1.0, 0.75))
	toast("Soul Risen saved you — half HP restored")


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
	if blood_moon and not e.is_boss:
		e.hp *= 1.25
		e.hp_max = e.hp
		e.xp_val = int(ceilf(e.xp_val * 1.5))
		e.speed *= 1.08
	if fading_light and not e.is_boss:
		e.speed *= 1.12
	if omen_hp_mult > 1.0 and not e.is_boss:
		e.hp *= omen_hp_mult
		e.hp_max = e.hp
		M.paint(e, M.toon(skeleton_tex, tint.lerp(Color(0.85, 0.08, 0.08), 0.4), 0.35, true))
	# nemesis: arketipe yang membunuhmu run lalu — kembali lebih keras sampai dibunuh
	if Stats.nemesis != "" and arch_id == Stats.nemesis and not e.is_boss and not nemesis_spawned:
		nemesis_spawned = true
		e.nemesis = true
		e.hp *= 1.6
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
	room.add_child(e)
	# spawn-in: muncul pop supaya tidak hard-cut
	var esc: Vector3 = e.scale
	e.scale = Vector3(0.01, 0.01, 0.01)
	var stw := e.create_tween()
	stw.tween_property(e, "scale", esc, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	e.died.connect(_on_enemy_died)
	if not elite and not e.is_boss and not _warned.has(arch_id) and FIRST_SEEN.has(arch_id) and player != null:
		_warned[arch_id] = 1
		Sfx.play("page")
		_damage_number(player.global_position + Vector3(0, 0.9 * info.tile, 0), String(FIRST_SEEN[arch_id]), Color(0.55, 1.0, 0.75), true)
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
	if _room_alive(n.room_idx) >= 8:
		return
	Sfx.play("thunder")
	toast("A necromancer raises the dead!")
	_burst(n.global_position + Vector3(0, 0.5, 0), Color(0.8, 0.4, 1.0))
	_spawn_enemy({"pos": n.global_position + Vector3(0, 0, 0.6 * info.tile), "room": n.room_idx}, "chaser", false)


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
func _spawn_traps(last_room: int) -> void:
	var count: int = mini(maxi(Stats.floor_num - 1, 0), 3)
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
		tr.setup(info.tile, rng.randf_range(0.0, 1.9), 4 if rk < 0.08 else (5 if rk < 0.2 else (3 if rk < 0.34 else (2 if rk < 0.48 else (1 if rk < 0.68 else 0)))))


func _spawn_urns(last_room: int) -> void:
	# guci tulang: 1-3 per lantai, dipecahkan untuk permata jiwa
	for i in range(rng.randi_range(2, 4)):
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
		u.setup(info.tile)


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
	if Stats.floor_num >= 6 and rng.randf() < 0.12:
		skind = 4
	elif Stats.floor_num >= 4 and rng.randf() < 0.18:
		skind = 3
	elif Stats.floor_num >= 3 and rng.randf() < 0.3:
		skind = 1
	elif Stats.floor_num >= 2 and rng.randf() < 0.22:
		skind = 2
	s.setup(info.tile, skind)
	shrine_ref = s
	match skind:
		1:
			s.invoked.connect(_on_mahzan_invoked)
		2:
			s.invoked.connect(_on_curse_invoked)
		3:
			s.invoked.connect(_on_forge_invoked)
		4:
			s.invoked.connect(_on_mirror_invoked)
		_:
			s.invoked.connect(_on_shrine_invoked)


var lore_ref = null
var motes_ref: GPUParticles3D = null
var stain_count := 0
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


func _spawn_squire() -> void:
	if squire_ref != null and is_instance_valid(squire_ref):
		return
	if player == null or not is_instance_valid(player):
		return
	squire_ref = SQUIRE.new()
	room.add_child(squire_ref)
	squire_ref.global_position = player.global_position + Vector3(0.4 * info.tile, 0, 0.3 * info.tile)
	squire_ref.setup(info.tile, maxf(1.0, Stats.get_stat("atk") * 0.35))
	toast("Your squire kneels... then rises to fight")


func _on_lore_stone(s) -> void:
	Sfx.play("page")
	s.consume()
	lore_ref = null
	Stats.add_xp(1)
	_quest_event("page")
	var line: String = LORE_LINES[rng.randi_range(0, LORE_LINES.size() - 1)]
	if not Stats.lore_seen.has(line):
		Stats.lore_seen.append(line)
		Stats.save_game()
		if Stats.lore_seen.size() >= 10:
			_ach("lore10")
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
	orb.setup(1.0, info.tile)


func _spawn_obelisks(last_room: int) -> void:
	# dread obelisk: menara perusak jiwa — 60% satu di lantai 7+, 25% dua
	var oquest := Stats.floor_num >= 7 and Stats.floor_num % 5 == 2
	if Stats.floor_num < 7 or (not oquest and rng.randf() > 0.6):
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
	var guaranteed := (Stats.floor_num >= 6 and Stats.floor_num % 4 == 0) or soul_drift
	if not guaranteed and rng.randf() > 0.55:
		return
	var wcount := 4 if soul_drift else (2 if (guaranteed or rng.randf() < 0.36) else 1)
	for _wi in range(wcount):
		var ri := rng.randi_range(1, last_room)
		var rr: Dictionary = info.ranges[ri]
		_spawn_wisp_at(Vector3((rr["x0"] + rr["x1"]) * 0.5 + randf_range(-0.8, 0.8) * info.tile, 0.0, (rr["z0"] + rr["z1"]) * 0.5 + randf_range(-0.8, 0.8) * info.tile))


func _spawn_wisp_at(pos: Vector3) -> void:
	var w := WISP.new()
	w.setup(info.tile)
	room.add_child(w)
	w.global_position = pos


func _spawn_vial(pos: Vector3) -> void:
	var v = VIAL.new()
	room.add_child(v)
	v.global_position = pos + Vector3(0, 0.5, 0)
	v.setup(info.tile)


func _add_vial() -> void:
	if vials >= 2:
		# satchel penuh — langsung diminum di tempat
		if player != null and is_instance_valid(player):
			var mh := Stats.get_stat("max_hp")
			player.hp = minf(mh, player.hp + mh * 0.2)
			player.hp_changed.emit(player.hp)
		toast("Satchel full — drank it on the spot (+20% HP)")
	else:
		vials += 1
		toast("+1 ⚗ SOUL VIAL (tap VIAL to drink)")
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
	player.hp = minf(mh, player.hp + mh * 0.3)
	player.hp_changed.emit(player.hp)
	Sfx.play("shrine")
	_burst(player.global_position + Vector3(0, 0.8, 0), Color(0.3, 0.95, 0.8))
	toast("⚗ Soul Vial — +30% HP")
	_vial_btn()


func _vial_btn() -> void:
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


func _souls_l() -> void:
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
	Sfx.play("death")
	kills_run += 1
	if ui.has("kills_label"):
		ui.kills_label.text = "☠ %d" % kills_run
	# Sir Vane: celoteh perang tiap ~15 kill bersama
	if kills_run % 15 == 0 and knight_ref != null and is_instance_valid(knight_ref):
		var vbarks := [
			"FOR THE OLD KINGDOM!",
			"A fine mess of bones we're making.",
			"That one had a brother. Send him over.",
			"Ha! Still got it, boy.",
			"The King hears you rattling, wretch!",
		]
		_damage_number(knight_ref.global_position + Vector3(0, 0.9 * info.tile, 0), vbarks[int(kills_run / 15) % vbarks.size()], Color(0.7, 0.9, 1.1), false)
	if player != null and is_instance_valid(player) and player.hp <= player.max_hp * 0.2:
		last_stand_kills += 1
		if last_stand_kills >= 5:
			_ach("st5")
	Stats.count_kill()
	Stats.bestiary[e.arch_id] = int(Stats.bestiary.get(e.arch_id, 0)) + 1
	if Stats.bestiary.size() >= BESTIARY.size():
		_ach("scholar")
	if rng.randf() < 0.05:
		_spawn_vial(e.global_position)
	if bool(e.get("nemesis")):
		Stats.nemesis = ""
		Stats.nemesis_name = ""
		Stats.souls += 10
		_souls_l()
		Stats.save_game()
		Sfx.play("victory")
		_burst(e.global_position, Color(0.9, 0.15, 0.25))
		_lvl_banner("◆ NEMESIS SLAIN — +10 souls")
		_say([{"who": "oracle", "text": "The ledger crosses a name tonight, Kael. Yours is still being written."}])
		_damage_number(e.global_position + Vector3(0, 0.9 * info.tile, 0), "YOUR DEBT IS PAID", Color(1.0, 0.85, 0.35), true)
		_ach("nem1")
	# weapon mastery: 25 kill dengan senjata yang sama -> +1 ATK permanen
	var wid := Stats.weapon_id
	var wk_old: int = int(Stats.weapon_kills.get(wid, 0))
	Stats.weapon_kills[wid] = wk_old + 1
	_souls_l()
	if wk_old < Stats.MASTERY_N and wk_old + 1 >= Stats.MASTERY_N and not bool(Stats.mastered.get(wid, false)):
		Stats.mastered[wid] = 1
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
	if e.arch_id == "gaoler":
		_quest_event("gaoler_kill")
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
	if grave_hunger and not e.get("is_boss") and rng.randf() < 0.12:
		_spawn_wisp_at(e.global_position + Vector3(0, 0.3, 0))
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
	elif rng.randf() < 0.06:
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
			_quest_event("clear_floor")
			_set_room_gates(e.room_idx, true)
			if not get_tree().get_nodes_in_group("enemies").is_empty():
				toast("Room clear — gates open!")
		if get_tree().get_nodes_in_group("enemies").is_empty():
			if Stats.floor_num >= 25:
				_run_victory()
				return
			run_state = "cleared"
			if blood_moon:
				Stats.souls += 5
				_souls_l()
				Stats.save_game()
				toast("☽ BLOOD MOON TITHE — +5 souls")
			elif soul_rush:
				Stats.souls += 3
				_souls_l()
				Stats.save_game()
				toast("✦ SOUL RUSH TITHE — +3 souls")
			elif fading_light:
				Stats.souls += 4
				_souls_l()
				Stats.save_game()
				toast("◈ GLOOM TITHE — +4 souls")
			elif echoing:
				Stats.souls += 3
				_souls_l()
				Stats.save_game()
				toast("◈ ECHO TITHE — +3 souls")
			elif gilded_tides:
				Stats.souls += 4
				_souls_l()
				Stats.save_game()
				toast("★ HOARD TITHE — +4 souls")
			elif storm_cellar:
				Stats.souls += 2
				_souls_l()
				Stats.save_game()
				toast("⚡ STORM TITHE — +2 souls")
			elif soul_drift:
				Stats.souls += 3
				_souls_l()
				Stats.save_game()
				toast("☆ DRIFT TITHE — +3 souls")
			elif grave_hunger:
				Stats.souls += 2
				_souls_l()
				Stats.save_game()
				toast("☠ HUNGER TITHE — +2 souls")
			# bonus sapuan kilat: lantai bersih di bawah 90 detik
			if floor_t < 90.0 and Stats.floor_num > 1:
				Stats.souls += 2
				_souls_l()
				Stats.save_game()
				toast("⚡ SWEEP BONUS — cleared in %ds (+2 souls)" % int(floor_t))
			if not floor_hurt and Stats.floor_num > 1:
				Stats.souls += 3
				_souls_l()
				Stats.save_game()
				toast("★ UNTOUCHED — flawless floor (+3 souls)")
			Stats.note_floor()
			Stats.save_run()
			for gi in gates:
				gates[gi].set_open(true)
			if tut_active and tut_step >= 2:
				tut_active = false
				Stats.tutorial_done = true
				Stats.save_game()
				_tut_hide()
			_show_banner("FLOOR %d CLEARED" % Stats.floor_num, "%d kills this run • best combo ×%d • %d:%02d — tap to descend to Floor %d" % [kills_run, combo_max, int(run_time) / 60, int(run_time) % 60, Stats.floor_num + 1])
			if player != null and is_instance_valid(player):
				_burst(player.global_position, Color(1.0, 0.85, 0.3))
				_souls(player.global_position, 12, Color(1.0, 0.8, 0.35))
				Sfx.play("victory")
	# permata XP terakhir, supaya logika gerbang di atas tidak keganggu bila gem gagal
	if e.golden:
		_damage_number(e.global_position, "LUCKY ×3", Color(1.0, 0.85, 0.3), true)
	if e.elite:
		_quest_event("elite_kill", 1)
	# bonus XP dari kombo aktif: +5% per streak (maks +50%)
	var xp_bonus := 1.0 + minf(float(combo), 10.0) * 0.05
	if soul_rush:
		xp_bonus *= 1.6
	_spawn_gems(e.global_position, int(e.xp_val * xp_bonus))


func _on_boss_died(_e) -> void:
	# slow-mo saat raja tumbang
	Engine.time_scale = 0.25
	get_tree().create_timer(0.7, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	boss_ref = null
	Stats.boss_kills += 1
	Stats.souls += 15
	if Stats.nemesis == "bone_king":
		Stats.nemesis = ""
		Stats.nemesis_name = ""
		Stats.souls += 10
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


func _on_player_died() -> void:
	print("PLAYER DIED floor=%d" % Stats.floor_num)
	if not oracle_bargained and Stats.souls >= 15:
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
	if player != null and is_instance_valid(player):
		ktip = "\n" + String(KILLER_TIPS.get(player.last_killer, ""))
	_show_banner("YOU DIED", "Floor %d • %s — slain by %s\n%d kills • Lv %d • %d relics • best combo ×%d • %d:%02d\nBest: Floor %d — tap to retry%s%s" % [Stats.floor_num, biome["name"], killer, kills_run, Stats.level, Stats.relics.size(), combo_max, mins, secs, Stats.best_floor, rec, ktip], Color(1.0, 0.32, 0.28))


func _offer_oracle_bargain() -> void:
	run_state = "dead"
	Engine.time_scale = 0.15
	get_tree().create_timer(0.5, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	_tut_hide()
	Input.vibrate_handheld(160)
	dlg_pending_choice = 4
	_say(
		[{"who": "oracle", "text": "Your thread frays, Kael — but I can knot it back. Fifteen souls, and you rise where you fell."}],
		[{"text": "RISE AGAIN — pay 15 souls (◈ %d held)" % Stats.souls},
		 {"text": "Let the dark take me"}])


func _oracle_deal(idx: int) -> void:
	if idx != 0 or Stats.souls < 15 or player == null or not is_instance_valid(player):
		_finalize_death()
		return
	Stats.souls -= 15
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
	if player != null and is_instance_valid(player):
		ktip = "\n" + String(KILLER_TIPS.get(player.last_killer, ""))
	_show_banner("YOU DIED", "Floor %d • %s — slain by %s\n%d kills • Lv %d • %d relics • best combo ×%d • %d:%02d\nBest: Floor %d — tap to retry%s%s" % [Stats.floor_num, biome["name"], killer, kills_run, Stats.level, Stats.relics.size(), combo_max, mins, secs, Stats.best_floor, rec, ktip], Color(1.0, 0.32, 0.28))


func _run_victory() -> void:
	run_state = "won"
	Stats.note_floor()
	Stats.clear_run()
	Stats.runs += 1
	Stats.ng_plus += 1
	Stats.souls += 25
	_souls_l()
	Stats.save_game()
	_ach("s25")
	_tut_hide()
	if player != null and is_instance_valid(player):
		_burst(player.global_position, Color(0.6, 1.0, 0.75))
		_souls(player.global_position, 20, Color(0.6, 1.0, 0.75))
	Sfx.play("victory")
	Input.vibrate_handheld(400)
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	_show_banner("THE THRONE FALLS", "The Bone King's crown shatters.\n%d kills • Lv %d • %d relics • best combo ×%d • %d:%02d\nNG+%d unlocked — the depths grow crueler\nTap to return to the surface" % [kills_run, Stats.level, Stats.relics.size(), combo_max, mins, secs, Stats.ng_plus], Color(0.55, 1.0, 0.72))


func _on_banner_tap() -> void:
	if run_state == "won":
		await _fade_to(1.0, 0.4)
		get_tree().change_scene_to_file("res://app/menu.tscn")
	elif run_state == "cleared":
		_quest_event("descend")
		Stats.floor_num += 1
		Stats.note_floor()
		if Stats.floor_num >= 5:
			_ach("f5")
		if Stats.floor_num >= 10:
			_ach("f10")
		if Stats.floor_num >= 20:
			_ach("f20")
		await _fade_to(1.0, 0.3)
		_new_run(rng.randi())
		_fade_to(0.0, 0.45)
	elif run_state == "dead":
		Stats.reset_run()
		kills_run = 0
		last_stand_kills = 0
		vials = 1
		run_time = 0.0
		combo_max = 0
		mahzan_met = 0
		vane_floors = 0
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
		player.hp_changed.emit(player.hp)
	_lvl_banner("LEVEL UP — Lv %d" % lv)
	for id in SK.ORDER:
		if int(SK.DB[id]["unlock"]) == lv:
			toast("Skill unlocked: %s!" % SK.DB[id]["name"])
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
	draft_choices = ITEMS.roll_choices(Stats.relics, rng)
	_build_draft_cards()
	ui.draft.visible = true
	ui.dim.visible = true
	get_tree().paused = true
	print("DRAFT terbuka: %s (Lv %d)" % [str(draft_choices), Stats.level])


func _draft_reroll() -> void:
	if not Stats.draft_open or draft_rerolls <= 0:
		return
	draft_rerolls -= 1
	ui.draft_reroll.visible = draft_rerolls > 0
	Sfx.play("click")
	draft_choices = ITEMS.roll_choices(Stats.relics, rng)
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
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for cc in [chip, nl, dl]:
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cvb.add_child(cc)
		card.add_child(cvb)
		var idx := i
		card.gui_input.connect(func(e: InputEvent) -> void:
			if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
				Sfx.play("click")
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
	match id:
		"dash":
			var dir := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			if player.move_input.length() > 0.1:
				dir = Vector3(player.move_input.x, 0, player.move_input.y).normalized()
			player.dash_burst(dir)
			Sfx.play("dash")
			_burst(player.global_position + Vector3(0, 0.4, 0), Color(0.5, 0.9, 1.0))
		"whirl":
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
					Stats.souls += 2
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
	skill_cd[id] = float(SK.DB[id]["cd"]) * (1.0 - 0.08 * float(Stats.meta.get("arcane", 0))) * (1.0 - Stats.cd_reduction) * (0.75 if echoing else 1.0)


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
	trauma = 0.7
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
		b.offset_left = -118
		b.offset_right = -40
		b.offset_top = -318 - (SK.ORDER.size() - 1 - i) * 88
		b.offset_bottom = -240 - (SK.ORDER.size() - 1 - i) * 88
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
		var sid := id
		b.pressed.connect(func() -> void: _cast_skill(sid))
		layer.add_child(b)
		skill_ui[id] = {"btn": b, "cd": cd, "name": String(SK.DB[id]["name"])}


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
		else:
			b.modulate = Color(1, 1, 1, 1)
			b.text = String(SK.DB[id]["short"])
			lab.text = ""
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
	toast("Swapped to " + String(WDB.get_w(nxt)["name"]))


func _hero_equip(wid: String) -> void:
	if player != null and is_instance_valid(player):
		player.equip_weapon(wid)
	else:
		Stats.equip_weapon(wid)
	Sfx.play("pickup")
	if Stats.owned_weapons.size() >= 5:
		_ach("w5")
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
	l.global_position = pos + Vector3(0, 1.3, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.2, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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


func toast(txt: String) -> void:
	ui.toast.text = txt
	ui.toast_panel.visible = true
	ui.toast_panel.modulate.a = 1.0
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(ui.toast_panel, "modulate:a", 0.0, 0.4)
	toast_tween.tween_callback(func() -> void: ui.toast_panel.visible = false)


func _lvl_banner(txt: String) -> void:
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
	quest_steps = QDB.for_floor(Stats.floor_num, room_count, n_elites)
	for st in quest_steps:
		st["done"] = 0
	quest_idx = 0
	_quest_render()


func _quest_event(kind: String, num: int = 1) -> void:
	# total per-kind dihitung apa pun langkah aktifnya — langkah berurutan
	# tidak boleh kehilangan progres yang terjadi sebelum gilirannya
	if kind == "trap_disarm":
		Stats.traps_defused += num
		if Stats.traps_defused >= 5:
			_ach("trap5")
	if kind == "wisp":
		Stats.wisps_caught += num
		if Stats.wisps_caught >= 8:
			_ach("wisp8")
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


# ---------------- kombo kill ----------------

func _combo_set(n: int) -> void:
	combo = n
	combo_max = maxi(combo_max, n)
	combo_t = 4.0
	# tier buff nyata: streak tinggi = tambah kuat (hilang saat streak putus)
	if combo == 8:
		_quest_event("combo")
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
		ui.combo_l.visible = false
		if ui.has("combo_bar"):
			ui.combo_bar.visible = false


# ---------------- bar HP boss ----------------

func _boss_bar_show() -> void:
	ui.boss_bar.visible = true
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
			Stats.souls += 12
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
		]
	)


func _omen_deal(idx: int) -> void:
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
	omen_name = oname if omen_name == "" else omen_name + "+" + oname
	_ach("omen1")
	Sfx.play("shrine")
	if player != null and is_instance_valid(player):
		player.refresh_stats()
	_refresh_buffs()
	toast("Omen sworn: " + omen_name)


func _on_mahzan_invoked(s) -> void:
	shrine_used = true
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 1
	mahzan_met += 1
	var mlines := [
		"Ah — living blood in my halls. Rare merchandise... rarer currency. Pick a deal.",
		"The Bone King pays me in bones. You'd pay in something warmer. Choose.",
		"A customer! It's been a century since the last. Don't make me regret it, Kael.",
	]
	if mahzan_met == 2:
		mlines = [
			"Back already? You spend souls like water, Kael. I approve.",
			"Twice in one descent. The crown must be worried about you.",
		]
	elif mahzan_met >= 3:
		mlines = [
			"My most faithful customer. When you take the throne, remember who stocked your satchel.",
			"Kael. Again. I'd offer you credit, but the dead don't have wallets.",
		]
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
		]
	)


func _on_forge_invoked(s) -> void:
	shrine_used = true
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 6
	_say([{"who": "oracle", "text": "A smith's altar, cold these hundred years — but its flame remembers blades, Kael."}],
		[{"text": "Quench the Blade — pay 6 souls: +1 weapon level"},
		{"text": "Sharpen Fully — pay 10 souls: +2 weapon levels"},
		{"text": "Leave the cold anvil"}])


func _forge_deal(idx: int) -> void:
	var wid: String = Stats.weapon_id
	var wname: String = String(WDB.get_w(wid)["name"])
	var wlv: int = int(Stats.weapon_lv.get(wid, 1))
	if idx == 0:
		if wlv >= 6:
			toast("The blade is perfect — it can go no further")
			return
		elif Stats.souls < 6:
			toast("Not enough souls (need 6)")
			return
		Stats.souls -= 6
		Stats.weapon_lv[wid] = wlv + 1
	elif idx == 1:
		if wlv >= 5:
			toast("The blade nears perfection — one quench at a time")
			return
		elif Stats.souls < 10:
			toast("Not enough souls (need 10)")
			return
		Stats.souls -= 10
		Stats.weapon_lv[wid] = wlv + 2
	else:
		return
	_souls_l()
	Stats.save_game()
	Sfx.play("levelup")
	toast("%s forged to +%d" % [wname, int(Stats.weapon_lv[wid]) - 1])
	if int(Stats.weapon_lv[wid]) >= 6:
		_ach("forge5")
	_refresh_buffs()
	if player != null and is_instance_valid(player):
		player.refresh_stats()
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.15))


func _on_mirror_invoked(s) -> void:
	shrine_used = true
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 7
	var wname := String(WDB.get_w(Stats.weapon_id)["name"])
	_say([{"who": "oracle", "text": "The mirror shows not your face, Kael — but another warrior's blade. Feed it and it will trade yours."}],
		[{"text": "Gaze — pay 4 souls: swap %s for a stranger's blade" % wname},
		{"text": "Look away"}])


func _mirror_deal(idx: int) -> void:
	if idx != 0:
		return
	if Stats.souls < 4:
		toast("Not enough souls (need 4)")
		return
	var opts: Array = []
	for wid in WDB.POOL:
		if wid != Stats.weapon_id:
			opts.append(wid)
	if opts.is_empty():
		toast("The mirror finds nothing worth trading")
		return
	Stats.souls -= 4
	_souls_l()
	var nid: String = String(opts[rng.randi() % opts.size()])
	player.equip_weapon(nid)
	Stats.save_game()
	Sfx.play("levelup")
	toast("The mirror trades — %s drawn" % String(WDB.get_w(nid)["name"]))
	_ach("mirror1")
	if player != null and is_instance_valid(player):
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.7, 1.0))


func _on_curse_invoked(s) -> void:
	s.consume()
	Sfx.play("shrine")
	dlg_pending_choice = 2
	_say([{"who": "oracle", "text": "A cursed obelisk... it hums with hungry promises, Kael."}],
		[{"text": "Blood Pact — foes hit 30% harder, souls pay +50% XP"},
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


func _mahzan_deal(idx: int) -> void:
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
				Stats.souls += 10
				_souls_l()
				_ach("pawn1")
				toast("Pawned %s for +10 souls" % String(ITEMS.DB[rid3]["name"]))
				if rid3 == "tulang_kesatria" and squire_ref != null and is_instance_valid(squire_ref):
					_souls(squire_ref.global_position, 8, Color(0.9, 0.85, 0.5))
					squire_ref.queue_free()
					squire_ref = null
		4:
			if Stats.souls < 5:
				toast("Not enough souls (need 5)")
			else:
				Stats.souls -= 5
				_souls_l()
				vials = 2
				_vial_btn()
				toast("Satchel filled — 2 ⚗ vials")
		5:
			if Stats.mahzan_debt <= 0.0:
				toast("Your ledger is clean, warrior")
			elif Stats.souls < 15:
				toast("Not enough souls (need 15)")
			else:
				Stats.souls -= 15
				_souls_l()
				Stats.mahzan_debt = 0.0
				toast("Debt settled — Max HP restored")
		6:
			if Stats.curse_dmg <= 0.0:
				toast("You carry no pacts to shed, warrior")
			elif Stats.souls < 8:
				toast("Not enough souls (need 8)")
			else:
				Stats.souls -= 8
				_souls_l()
				Stats.curse_dmg = maxf(0.0, Stats.curse_dmg - 0.3)
				Stats.curse_xp = maxf(0.0, Stats.curse_xp - 0.5)
				toast("Curse eaten — the obelisk's hold weakens")
		7:
			if Stats.souls < 8:
				toast("Not enough souls (need 8)")
			else:
				Stats.souls -= 8
				_souls_l()
				Stats.reroll_extra += 1
				toast("Kismet Thread — every draft gains a second reroll")
		8:
			if Stats.souls < 6:
				toast("Not enough souls (need 6)")
			else:
				Stats.souls -= 6
				_souls_l()
				Stats.buff_xp_pct += 0.3
				toast("Pale Pawn — +30% XP this run")
	if player != null and is_instance_valid(player):
		player.hp = minf(player.hp, Stats.get_stat("max_hp"))
		player.refresh_stats()
		player.hp_changed.emit(player.hp)
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.7, 1.0))


func _on_shrine_invoked(s) -> void:
	shrine_used = true
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
	elif Stats.floor_num == 3:
		lines = [
			{"who": "kael", "text": "Oracle... how do you know these halls so well?"},
			{"who": "oracle", "text": "I walked them when they were bright, Kael — long before the bone took the throne."},
		]
	elif Stats.floor_num == 7:
		lines = [
			{"who": "oracle", "text": "One throne shattered. He rebuilds it deeper, out of angrier bones."},
			{"who": "kael", "text": "Then I keep swinging until there are no thrones left."},
		]
	elif Stats.floor_num == 9:
		lines = [
			{"who": "oracle", "text": "The walls stop pretending to be a crypt down here. This is the Abyss — the dungeon's own grave."},
			{"who": "kael", "text": "Then it's fitting. I brought a shovel."},
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
	elif Stats.floor_num == 14:
		lines = [
			{"who": "kael", "text": "Oracle — the halls whisper back down here. Are they yours?"},
			{"who": "oracle", "text": "Not all of them, Kael. Some of them are his."},
		]
	elif Stats.floor_num == 16:
		lines = [
			{"who": "oracle", "text": "Halfway to his deepest hall. The air itself is starting to hate you."},
			{"who": "kael", "text": "Good. Let it try to stop me."},
		]
	elif Stats.floor_num == 18:
		lines = [
			{"who": "knight", "text": "I died on a floor like this, Kael. The dark does not forgive — it only waits."},
			{"who": "kael", "text": "Then we'll make it keep waiting."},
			{"who": "oracle", "text": "The Abyss does not end, Kael — it only agrees to be walked."},
		]
	elif Stats.floor_num == 21:
		lines = [
			{"who": "oracle", "text": "Even I don't know what waits below the twenty-fifth. No soul has returned to tell it."},
			{"who": "kael", "text": "Then I'll be the first to come back and tell you."},
		]
	elif Stats.floor_num == 24:
		lines = [
			{"who": "oracle", "text": "One floor below waits the throne beneath all thrones. He knows you're coming, Kael."},
			{"who": "kael", "text": "Tell him to keep the crown warm."},
			{"who": "mahzan", "text": "Twenty-four floors of carnage. Even I feel... almost... sentimental."},
		]
	elif Stats.nemesis != "" and not nemesis_warned:
		nemesis_warned = true
		lines = [
			{"who": "oracle", "text": "Kael — %s walks these halls again. The one that ended you last descent." % Stats.nemesis_name},
			{"who": "kael", "text": "Then the ledger and I both have a page to close."},
		]
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
	ui.map.visible = true
	var sc: float = minf(130.0 / xs, 178.0 / zs)
	for r in info.ranges:
		var rc := ColorRect.new()
		rc.color = Color(0.32, 0.3, 0.42, 0.9)
		rc.position = Vector2((r["x0"] - info["min_x"]) * sc, (r["z1"] - info["min_z"]) * sc)
		rc.size = Vector2(maxf((r["x1"] - r["x0"]) * sc, 4.0), maxf((r["z0"] - r["z1"]) * sc, 4.0))
		mv.add_child(rc)
	if info.get("chest") != null:
		var cd := ColorRect.new()
		cd.color = Color(1.0, 0.8, 0.2)
		cd.size = Vector2(5, 5)
		cd.position = _map_pos(info.chest.global_position, sc)
		mv.add_child(cd)
	# penanda altar (cyan), batu lore (ungu), dan tujuan akhir lantai (emas besar)
	if shrine_ref != null and is_instance_valid(shrine_ref):
		var sd := ColorRect.new()
		sd.color = Color(0.45, 0.85, 1.0)
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
	ui["map_scale"] = sc
	_update_minimap()


func _update_minimap() -> void:
	if not ui.has("map_view") or not ui.map.visible or player == null or not is_instance_valid(player):
		return
	var sc: float = ui["map_scale"]
	ui.map_pdot.position = _map_pos(player.global_position, sc)
	for d in map_dots:
		if is_instance_valid(d):
			d.queue_free()
	map_dots.clear()
	for f in get_tree().get_nodes_in_group("enemies"):
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
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.18, 0.15, 0.24, 0.98)
	sbh.border_color = Color(1.0, 0.88, 0.5, 0.9)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.3, 0.24, 0.12, 1.0)
	b.add_theme_stylebox_override("pressed", sbp)
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
	if not paused_ui and lore_panel != null:
		lore_panel.visible = false
	if not paused_ui and bestiary_panel != null:
		bestiary_panel.visible = false
	if paused_ui and ui.has("pause_stats"):
		var pm := int(run_time) / 60
		var ps := int(run_time) % 60
		ui.pause_stats.text = "Floor %d  •  %d kills  •  best combo ×%d  •  %d:%02d" % [Stats.floor_num, kills_run, combo_max, pm, ps]
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
			cells[i].color = Color(0.9, 0.16, 0.22)
	if ui.has("hp_text"):
		ui.hp_text.text = "%d/%d" % [maxi(int(ceil(hp)), 0), maxh]
	if prev_hp >= 0.0 and hp < prev_hp - 0.001:
		trauma = maxf(trauma, 0.6)
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
	ui.lv_label.text = "Lv %d" % lv


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
	if omen_name != "":
		list.append(["☗ " + omen_name, Color(0.9, 0.7, 1.0)])
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
	if player.hp <= player.max_hp * 0.2 and not player.dead:
		list.append(["⚑ LAST STAND +25% ATK", Color(1.0, 0.35, 0.25)])
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


func _hide_banner() -> void:
	ui.banner.visible = false
	if not Stats.draft_open:
		ui.dim.visible = false


# ---------------- per-frame ----------------

func _process(delta: float) -> void:
	if player != null and is_instance_valid(player) and run_state == "playing":
		run_time += delta
		floor_t += delta
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
			if atk_hold_t >= 0.6 and not atk_charged:
				atk_charged = true
				Input.vibrate_handheld(60)
				ui.atk_btn.modulate = Color(1.35, 1.15, 0.6)
		else:
			if atk_hold_t >= 0.6:
				_heavy_attack()
			atk_hold_t = 0.0
			atk_charged = false
			ui.atk_btn.modulate = Color.WHITE
		if Input.is_key_pressed(KEY_H):
			_toggle_hero(true)

		_tick_skill_ui(delta)
		_refresh_buffs()

		# pelacakan ruangan -> kunci arena
		var ri := _room_at(player.global_position.z)
		if ri >= 0 and ri != current_room:
			current_room = ri
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
		if combo_t > 0.0:
			combo_t -= delta
			if ui.has("combo_bar"):
				var cbf: ColorRect = ui.combo_bar
				var f2: float = clampf(combo_t / 4.0, 0.0, 1.0)
				cbf.offset_right = -140 + 280.0 * f2
				cbf.offset_left = -140
				cbf.visible = combo >= 3
			if combo_t <= 0.0:
				_combo_set(0)

		# bar HP boss mengikuti sisa nyawa
		if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.activated:
			_boss_bar_show()
			var frac: float = clampf(boss_ref.hp / boss_ref.hp_max, 0.0, 1.0)
			ui.boss_fill.value = frac * 100.0
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
					Stats.souls += 8
					_souls_l()
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
						toast("Gilded chest — relic inside: " + String(ITEMS.DB[rid2]["name"]) + "!")

	if player != null and is_instance_valid(player) and cam != null:
		var s: float = info.get("tile", 4.0)
		var target: Vector3 = player.global_position + Vector3(0.0, 3.0 * s, 2.6 * s)
		cam.global_position = cam.global_position.lerp(target, 1.0 - pow(0.0001, delta))
		if trauma > 0.0:
			trauma = max(0.0, trauma - delta * 1.8)
			cam.global_position += Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)) * trauma * 0.18
		cam.look_at(player.global_position + Vector3(0, 0, -0.9 * s))


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
