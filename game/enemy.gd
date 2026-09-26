extends CharacterBody3D
class_name Enemy
const M = preload("res://materials.gd")
const EDB = preload("res://enemies_db.gd")
const PROJ = preload("res://projectile.gd")
# Musuh berbasis arketipe (enemies_db.gd): chaser, rogue (dash), mage (ranged),
# brute (tanky). Varian elite = stat multiplier + tint merah.
# AI: idle -> chase (mage jaga jarak) -> windup (telegraph) -> strike -> recover.

signal died(enemy)
const FPOOL = preload("res://fire_pool.gd")
signal summon_requested(boss)

var arch_id := "chaser"
var elite := false
var hp := 3.0
var hp_max := 3.0
var xp_val := 1
var state := "idle"
var aggro_range := 9.0
var attack_range := 2.2
var prefer_range := 0.0
var ranged := false
var dash := false
var is_boss := false
var tier_idx := 0
var is_bomber := false
var is_summoner := false
var proj_speed := 0.0
var kb_resist := 0.0
var dmg_reduce := 0.0
var tidal_t := 0.0
var was_low := false
var fs_hit := false
var tender_t := 0.0
var speed := 4.0
var dmg := 1
var windup_t := 0.45
var bounds := {}
var room_tile := 4.0
var mat: ShaderMaterial
var _tint0 := Color(1, 1, 1)
var ap: AnimationPlayer
var kb := Vector3.ZERO
var state_t := 0.0
var anim_lock := 0.0

# bilah hp mini di atas kepala (khusus elite, muncul setelah kena hit)
var hpbar_bg: Sprite3D = null
var hpbar_shown_frac := -1.0
var hpbar_fg: Sprite3D = null
var hpbar_tag: Label3D = null
var mark_tag: Label3D = null
static var _bar_tex: Texture2D = null
const BAR_W := 0.6


static func _get_bar_tex() -> Texture2D:
	if _bar_tex == null:
		var img := Image.create(64, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_bar_tex = ImageTexture.create_from_image(img)
	return _bar_tex
var room_idx := 0
var activated := true
var stun_t := 0.0
var enraged := false
var golden := false
var nemesis := false
var is_lurker := false
var orator := false
var warlock := false
var war_t := 5.0
var gnawer := false
var bride := false
var cantor := false
var husk := false
var fanatic := false
var brood := false
var chime := false
var sprite := false
var leech := false
var charged := false
var keel_marked := false
var chaplain := false
var chap_t := 0.0
var warden_bell := false
var bell_t := 0.0
var hookshot := false
var eel := false
var slow_immune := false
var fey := false
var sawblade := false
var coward := false
var fey_t := 2.0
var eel_t := 0.0
var eel_dash_t := 0.0
var eel_dir := Vector3.ZERO
var chime_t := 7.0
var husk_shell := false
var halfshell_shell := false
var cantor_t := 6.5
var bride_t := 5.5
var oath_t := 3.0
var fest_t := 6.0
var fest_n := 0
var slip_n := 0

var healer := false
var heal_t := 4.0
var crowned := false
var tither := false
var digger := false
var keelh := false
var mire := false
var siren := false
var _siren_pulled := false
var _shell_cracked := false
var _shell_hits := 0
var digger_dug := false
var phase_foe := false
var pack_bounty := false
var orator_t := 3.0
var dmg_max := 0 # orator chant cap
var spd_boost := 0 # bride chant cap counter
var is_slammer := false
var wailer := false
var wisp_drop := false
var revenant := false
var shielded := false
var herald := false
var herald_buffed := false
var knocker := false # golem: pukulannya mengguncang tanah di radius lebar
var lurk_revealed := false
var lurk_warned := false
var model_ref: Node3D = null
var affix := ""
var jailer := false
var is_weeper := false
var is_warper := false
var is_hexer := false
var is_waver := false
var is_gale := false
var kiter := false
var is_chiller := false
var is_venom := false
var is_ruster := false
var is_widow := false
var burst := false
var sheared := false
var is_spiky := false
var warp_t := 4.0
var champion := false # elite sarang sang juara — drop senjata terjamin
var sunder_t := 0.0 # debuff SUNDERING BLOW: terima +30% damage
var chant_t := 2.5
var _base_scale := Vector3.ONE
var slam_t := 4.0
var summon_t := 11.0
var banter_75 := false
var banter_25 := false
var banter_10 := false
var hex_t := 0.0   # Hex Staff: musuh bertanda menerima +25% damage
var slow_t := 0.0
var mark_t := 0.0  # Frost Fang: beku — 50% speed
var vuln_t := 0.0
var haste_t := 0.0
var burn_t := 0.0  # Ember Mace: terbakar — damage berkala
var _burn_acc := 0.0


func stun(t: float) -> void:
	if affix == "soulbound":
		return
	if state == "dead" or affix == "adamant":
		return
	stun_t = maxf(stun_t, t)
	state = "recover"
	state_t = maxf(state_t, t)
	scale = _base_scale
	if mat != null:
		mat.set_shader_parameter("flash", 0.6)
	var mgu := get_tree().current_scene
	if mgu != null and mgu.has_method("_damage_number"):
		mgu._damage_number(global_position + Vector3(0, 0.75 * room_tile, 0), "☆ STUNNED", Color(1.0, 0.9, 0.45), true)


func setup(p_mat: ShaderMaterial, tile: float, b: Dictionary, p_arch: String, p_elite: bool, floor_num: int) -> void:
	mat = p_mat
	room_tile = tile
	bounds = b
	arch_id = p_arch
	elite = p_elite
	var a: Dictionary = EDB.get_arch(arch_id)
	var hp_growth := 1.0 + 0.15 * float(floor_num - 1)
	# New Game+: tiap kemenangan menambah kedalaman — musuh lebih keras + cepat
	var ng: float = float(Stats.ng_plus)
	hp_growth += 0.35 * ng
	hp = a["hp"] * hp_growth
	speed = a["spd"] * tile * (1.0 + 0.08 * ng)
	aggro_range = a["aggro"] * tile
	attack_range = a["reach"] * tile
	prefer_range = a.get("prefer", 0.0) * tile
	windup_t = a["windup"]
	dmg = a["dmg"] + int(ng)
	xp_val = a["xp"] + int(ng)
	ranged = a.get("ranged", false)
	dash = a.get("dash", false)
	proj_speed = a.get("proj_speed", 0.0) * tile
	kb_resist = a.get("kb_resist", 0.0)
	_tint0 = mat.get_shader_parameter("tint")
	is_boss = a.get("boss", false)
	is_bomber = a.get("bomber", false)
	is_summoner = a.get("summoner", false)
	jailer = bool(a.get("jailer", false))
	is_weeper = bool(a.get("chanter", false))
	is_warper = bool(a.get("warper", false))
	is_hexer = bool(a.get("hexer", false))
	is_waver = bool(a.get("waver", false))
	is_gale = bool(a.get("gale", false))
	kiter = bool(a.get("kiter", false))
	is_chiller = bool(a.get("chiller", false))
	is_venom = bool(a.get("venomshot", false))
	is_ruster = bool(a.get("ruster", false))
	is_widow = bool(a.get("widow", false))
	burst = bool(a.get("burst", false))
	is_spiky = bool(a.get("spiky", false))
	is_lurker = bool(a.get("lurks", false))
	orator = bool(a.get("orator", false))
	warlock = bool(a.get("warlock", false))
	gnawer = bool(a.get("gnawer", false))
	bride = bool(a.get("bride", false))
	cantor = bool(a.get("cantor", false))
	husk = bool(a.get("husk", false))
	husk_shell = husk
	fanatic = bool(a.get("fanatic", false))
	brood = bool(a.get("brood", false))
	chime = bool(a.get("chime", false))
	sprite = bool(a.get("sprite", false))
	leech = bool(a.get("leech", false))
	chaplain = bool(a.get("chaplain", false))
	warden_bell = bool(a.get("warden_bell", false))
	hookshot = bool(a.get("hookshot", false))
	eel = bool(a.get("eel", false))
	sawblade = bool(a.get("sawblade", false))
	coward = bool(a.get("coward", false))
	healer = bool(a.get("healer", false))
	crowned = bool(a.get("crowned", false))
	tither = bool(a.get("tither", false))
	phase_foe = bool(a.get("phase", false))
	digger = bool(a.get("digger", false))
	keelh = bool(a.get("keelh", false))
	mire = bool(a.get("mire", false))
	siren = bool(a.get("siren", false))
	is_slammer = bool(a.get("slams", false))
	wailer = bool(a.get("wailer", false))
	wisp_drop = bool(a.get("wisp_drop", false))
	revenant = bool(a.get("revenant", false))
	shielded = bool(a.get("shielded", false))
	herald = bool(a.get("herald", false))
	knocker = bool(a.get("knocker", false))
	if is_summoner:
		summon_t = 9.0
	var sc: float = a["scale"]
	if elite:
		hp *= EDB.ELITE["hp_mult"]
		dmg += EDB.ELITE["dmg_add"]
		xp_val *= EDB.ELITE["xp_mult"]
		sc *= EDB.ELITE["scale_mult"]
		speed *= EDB.ELITE["spd_mult"]
		affix = ["swift", "bulwark", "vengeful", "siphon", "volatile", "mother", "frostbite", "warden", "thorned", "nightmare", "hoarded", "phantom", "regal", "reaper", "vampiric", "adamant", "shattered", "umbral", "wispsborn", "keelborn", "clamworn", "sirensong", "pearlbound", "barnacled", "tidal", "venomed", "riptide", "brinebound", "feral", "miser", "tideworn", "keelbound", "corroded", "salted", "webbed", "grim", "doomsayer", "drowning", "parched", "wrack", "crushing", "oathbound", "slippery", "mirrorhide", "keelmark", "tidebound", "charged", "bloated", "tarred", "seafaring", "feytouched", "knotted", "belltoll", "soulfed", "gutted", "beacon", "spry", "keenedged", "tidewrought", "lurker", "hoarfrost", "reefbound", "flotsam", "brinetouched", "bilged", "gilded", "saltbitten", "leeched", "windlashed", "halfshell", "soulwrought", "leaden", "grasping", "hungry", "numbing", "soulbound", "saltkin", "powderkeg", "hollow", "tarbound", "lagged", "bitter", "leviathan", "stormborn", "sundered", "reefsplit", "warped", "rusted", "embittered", "deathwarm", "tideheld", "marrowed", "keelmaw", "gloomtouched", "pitchwell", "giltborn", "bellchime", "riptorn", "tithed", "soulspill", "mossback", "charborn", "rimeborn", "keelhauled", "saltwept", "grimwater", "keelplated", "grimwrought", "wakehardened", "fathomborn", "soulheavy", "grimhull", "soulshell", "deckbound", "tollbound", "wakesworn", "deepworn", "crestbound", "crestworn", "wakebound", "saltworn", "greysworn", "palemarked", "saltbled", "reckoned", "audited", "enrolled", "enlisted", "censused", "tallied", "writbound", "galeswept", "ballasted", "trenchborn", "festering"][randi() % 135]
		match affix:
			"swift":
				speed *= 1.45
			"bulwark":
				hp *= 1.5
				xp_val = int(xp_val * 1.25)
			"siphon":
				# pukulan elite ini menyedot kombo pemain sampai nol
				xp_val = int(xp_val * 1.25)
			"frostbite":
				# pukulan elite ini mendinginkan pemain 55% speed 3s
				xp_val = int(xp_val * 1.25)
			"warden":
				# pukulan elite ini MENJERAT pemain di tempat 1s
				xp_val = int(xp_val * 1.25)
			"volatile":
				# meledak saat mati — bonus XP sebagai imbalan bahayanya
				xp_val = int(xp_val * 1.5)
			"thorned":
				# pukulan jarak dekat melukai penyerang — bonus XP
				xp_val = int(xp_val * 1.25)
			"nightmare":
				# elite ini bangkit sekali lagi pada 40% HP — bonus XP
				xp_val = int(xp_val * 1.6)
			"hoarded":
				# elite ini menelan senjata — dijatuhkan saat mati
				xp_val = int(xp_val * 1.3)
			"phantom":
				# elite ini berkedip ke sisi pemain tiap beberapa detik
				is_warper = true
				prefer_range = maxf(prefer_range, 0.9 * room_tile)
				warp_t = 1.2
				xp_val = int(xp_val * 1.3)
			"regal":
				# elite ini memakai mahkota harta — dijatuhkan saat mati sebagai permata bonus
				hp *= 1.3
				xp_val = int(xp_val * 1.4)
			"reaper":
				# elite ini mengincar nyawa — +50% dmg ke pemain sekarat
				dmg += 1
				xp_val = int(xp_val * 1.3)
			"vampiric":
				# elite ini minum darah — 35% lukanya kembali sebagai HP
				hp *= 1.15
				xp_val = int(xp_val * 1.3)
			"adamant":
				# elite ini tak bisa di-stun sama sekali
				hp *= 1.4
				xp_val = int(xp_val * 1.3)
			"shattered":
				# elite ini pecah jadi dua crawler saat mati
				hp *= 0.9
				xp_val = int(xp_val * 1.2)
			"wispsborn":
				# mati menumpahkan kunang jiwa — bonus XP
				xp_val = int(xp_val * 1.2)
			"keelborn":
				# jiwa-jiwa menempel di tulangnya — bayaran saat mati
				xp_val = int(xp_val * 1.15)
			"umbral":
				# elite ini tak terlihat sampai jarak dekat — seperti dweller
				is_lurker = true
				xp_val = int(xp_val * 1.3)
			"sirensong":
				# bernyanyi: pada 40% HP menarik pemain ke mulutnya sekali
				xp_val = int(xp_val * 1.2)
			"pearlbound":
				# cangkang mutiara: separuh damage sampai retak — hit pertama memecahkannya
				hp *= 1.2
				xp_val = int(xp_val * 1.25)
			"barnacled":
				# kerak: perisai baja, gerak berat
				dmg_reduce = 0.25
				speed *= 0.8
				hp *= 1.1
				xp_val = int(xp_val * 1.3)
			"tidal":
				# pasang: denyut menyembuhkan sekutunya perlahan
				hp *= 1.15
				xp_val = int(xp_val * 1.3)
			"venomed":
				# bisa: gigitnya meracunimu
				hp *= 1.1
				xp_val = int(xp_val * 1.3)
			"riptide":
				# arus balik: pukulannya menghempaskanmu jauh
				hp *= 1.1
				xp_val = int(xp_val * 1.3)
			"feral":
				# buas: tiap sekutu tumbang membuatnya makin cepat
				hp *= 0.95
				xp_val = int(xp_val * 1.25)
			"keelbound":
				# jangkar berjalan: tak bisa didorong, tapi lambat — matinya mentitahkan jiwa
				hp *= 1.2
				speed *= 0.9
				kb_resist = 1.0
				xp_val = int(xp_val * 1.3)
			"corroded":
				# berkarat hidup: lambat tapi gigitannya merusak baja — matinya mentitahkan jiwa
				hp *= 1.15
				speed *= 0.9
				xp_val = int(xp_val * 1.2)
			"salted":
				# encharcado de sal: mais lento, mas sua queda derrama jiwa extra
				hp *= 1.1
				speed *= 0.95
				xp_val = int(xp_val * 1.1)
			"webbed":
				# benang sari: pukulannya menjerat kaki — elit jaring
				hp *= 1.1
				speed *= 1.05
				xp_val = int(xp_val * 1.15)
			"grim":
				# pucat kelam: pukulannya melunakkan lenganmu — weakness
				hp *= 1.15
				speed *= 0.95
				xp_val = int(xp_val * 1.2)
			"doomsayer":
				# pendoa kiamat: pukulannya berat — tapi imannya rapuh
				dmg += 1
				hp *= 0.9
				xp_val = int(xp_val * 1.2)
			"drowning":
				# basah kuyup: pukulannya membuatmu kedinginan — chill
				hp *= 1.1
				speed *= 1.1
				xp_val = int(xp_val * 1.2)
			"parched":
				# kehausan: setiap pukulan menyeruput 1 jiwa
				hp *= 1.15
				xp_val = int(xp_val * 1.25)
			"wrack":
				# pukulan yang merongrong bekal — menambah cooldown skill +1s
				hp *= 1.2
				speed *= 0.9
				xp_val = int(xp_val * 1.3)
			"crushing":
				# pukulan berat — mendorongmu jauh ke belakang
				hp *= 1.15
				speed *= 0.85
				xp_val = int(xp_val * 1.25)
			"oathbound":
				# sumpah setia: denyutnya menyembuhkan sekutunya perlahan
				hp *= 1.25
				speed *= 0.85
				xp_val = int(xp_val * 1.4)
			"slippery":
				# licin seperti belut: tiap pukulan ke-4 meleset
				hp *= 1.1
				speed *= 1.1
				xp_val = int(xp_val * 1.35)
			"mirrorhide":
				# kulit cermin: memantulkan sebagian lukamu padamu sendiri
				hp *= 1.3
				speed *= 0.9
				xp_val = int(xp_val * 1.45)
			"keelmark":
				# membawa besi perbekalan kapal — matinya menjatuhkan senjata
				hp *= 1.15
				speed *= 0.95
				xp_val = int(xp_val * 1.3)
			"tidebound":
				# terikat pada arusnya sendiri — tak ada yang bisa memperlambatnya
				hp *= 1.2
				speed *= 1.05
			"charged":
				# makin terluka makin geram — windup makin pendek tiap darah tertumpah
				hp *= 1.15
				speed *= 1.0
				xp_val = int(xp_val * 1.4)
			"feytouched":
				fey = true
				xp_val = int(xp_val * 1.3)
			"knotted":
				# ototnya terlilit tali kusut — tebal, tapi lamban
				hp *= 1.4
				speed *= 0.9
				xp_val = int(xp_val * 1.4)
			"reefbound":
				# teritip — pukulan yang mendarat menumbuhkan karang (heal di blok hit)
				hp *= 1.25
				hp_max = hp
				speed *= 0.85
				xp_val = int(xp_val * 1.4)
			"bilged":
				hp *= 1.2
				xp_val = int(ceilf(xp_val * 1.35))
			"gilded":
				hp *= 1.05
				xp_val = int(ceilf(xp_val * 1.4))
			"saltbitten":
				hp *= 1.1
				xp_val = int(ceilf(xp_val * 1.35))
			"leeched":
				hp *= 1.1
				xp_val = int(ceilf(xp_val * 1.35))
			"windlashed":
				hp *= 1.05
				xp_val = int(ceilf(xp_val * 1.3))
			"halfshell":
				hp *= 0.9
				xp_val = int(ceilf(xp_val * 1.4))
				halfshell_shell = true
			"soulwrought":
				hp *= 1.0
				xp_val = int(ceilf(xp_val * 1.35))
			"leaden":
				hp *= 1.2
				speed *= 0.7
				dmg = int(ceilf(float(dmg) * 1.3))
				xp_val = int(ceilf(xp_val * 1.4))
			"grasping":
				hp *= 1.15
				dmg = int(ceilf(float(dmg) * 1.1))
				xp_val = int(ceilf(xp_val * 1.4))
			"hungry":
				hp *= 1.1
				xp_val = int(ceilf(xp_val * 1.4))
			"numbing":
				hp *= 1.15
				dmg = int(ceilf(float(dmg) * 1.05))
				xp_val = int(ceilf(xp_val * 1.4))
			"soulbound":
				hp *= 1.2
				xp_val = int(ceilf(xp_val * 1.45))
			"saltkin":
				hp *= 0.85
				speed *= 0.9
				xp_val = int(ceilf(xp_val * 1.3))
			"powderkeg":
				hp *= 0.9
				xp_val = int(ceilf(xp_val * 1.35))
			"hollow":
				hp *= 0.7
				speed *= 1.25
				xp_val = int(ceilf(xp_val * 1.3))
			"tarbound":
				hp *= 1.1
				speed *= 0.85
				xp_val = int(ceilf(xp_val * 1.3))
			"lagged":
				hp *= 1.15
				speed *= 0.9
				xp_val = int(ceilf(xp_val * 1.35))
			"bitter":
				hp *= 1.1
				speed *= 0.95
				xp_val = int(ceilf(xp_val * 1.35))
			"leviathan":
				hp *= 2.0
				speed *= 0.7
				xp_val = int(ceilf(xp_val * 2.5))
				sc *= 1.4
			"stormborn":
				speed *= 1.2
				xp_val = int(ceilf(xp_val * 1.4))
			"sundered":
				hp *= 0.7
				hp_max = hp
				vuln_t = 9999.0
				xp_val = int(ceilf(xp_val * 1.4))
			"reefsplit":
				speed *= 0.85
				xp_val = int(ceilf(xp_val * 1.3))
			"warped":
				hp *= 1.1
				hp_max = hp
				xp_val = int(ceilf(xp_val * 1.3))
			"deathwarm":
				hp *= 1.1
				hp_max = hp
			"tideheld":
				dmg *= 1.05
			"marrowed":
				hp = int(hp * 1.15)
				xp_val = int(xp_val * 1.1)
			"keelmaw":
				dmg *= 1.1
			"gloomtouched":
				speed *= 1.05
			"pitchwell":
				hp *= 1.1
				hp_max *= 1.1
				xp_val += 2
			"giltborn":
				speed *= 0.92
				xp_val += 3
			"bellchime":
				hp *= 0.95
				hp_max *= 0.95
			"riptorn":
				hp *= 1.05
				hp_max *= 1.05
			"tithed":
				hp *= 1.08
				hp_max *= 1.08
				dmg += 1.0
			"soulspill":
				hp *= 1.05
				hp_max *= 1.05
				xp_val += 2.0
			"mossback":
				hp *= 1.45
				hp_max *= 1.45
				speed *= 0.72
				dmg = int(ceilf(float(dmg) * 1.1))
				xp_val = int(ceilf(xp_val * 1.5))
			"charborn":
				hp *= 1.2
				hp_max *= 1.2
				speed *= 1.15
				dmg = int(ceilf(float(dmg) * 1.2))
				xp_val = int(ceilf(xp_val * 1.35))
			"rimeborn":
				hp *= 1.4
				hp_max *= 1.4
				speed *= 0.7
				dmg = int(ceilf(float(dmg) * 1.15))
				xp_val = int(ceilf(xp_val * 1.4))
			"keelhauled":
				speed *= 0.72
				dmg = int(ceilf(float(dmg) * 1.3))
				xp_val = int(ceilf(xp_val * 1.3))
			"saltwept":
				speed *= 0.9
				dmg = int(ceilf(float(dmg) * 1.3))
				xp_val = int(ceilf(xp_val * 1.4))
			"grimwater":
				speed *= 1.05
				dmg = int(ceilf(float(dmg) * 1.25))
				xp_val = int(ceilf(xp_val * 0.9))
			"keelplated":
				hp = int(ceilf(float(hp) * 1.25))
				speed *= 0.90
				xp_val = int(ceilf(xp_val * 1.1))
			"grimwrought":
				hp = int(ceilf(float(hp) * 1.20))
				speed *= 0.85
				dmg = int(ceilf(float(dmg) * 1.10))
				xp_val = int(ceilf(xp_val * 1.2))
			"wakehardened":
				speed *= 1.10
				hp = int(ceilf(float(hp) * 1.10))
				xp_val = int(ceilf(xp_val * 1.05))
			"fathomborn":
				hp = int(ceilf(float(hp) * 1.15))
				dmg = int(ceilf(float(dmg) * 1.05))
				speed *= 0.95
				xp_val = int(ceilf(xp_val * 1.10))
			"soulheavy":
				hp = int(ceilf(float(hp) * 1.20))
				speed *= 0.90
				xp_val = int(ceilf(xp_val * 1.30))
			"grimhull":
				hp = int(ceilf(float(hp) * 1.25))
				dmg = int(ceilf(float(dmg) * 1.05))
				speed *= 0.90
			"soulshell":
				hp = int(ceilf(float(hp) * 1.15))
				xp_val = int(ceilf(xp_val * 1.15))
			"deckbound":
				speed *= 0.85
				hp = int(ceilf(float(hp) * 1.10))
				xp_val = int(ceilf(xp_val * 1.10))
			"tollbound":
				hp = int(ceilf(float(hp) * 1.12))
				dmg = int(ceilf(float(dmg) * 1.05))
			"wakesworn":
				speed *= 1.12
				xp_val = int(ceilf(xp_val * 1.05))
			"deepworn":
				hp = int(hp * 1.08)
				hp_max = hp
				dmg = int(ceilf(dmg * 1.08))
			"crestbound":
				speed *= 1.10
				hp = int(hp * 0.94)
				hp_max = hp
			"crestworn":
				hp = int(hp * 0.92)
				hp_max = hp
				dmg = int(ceilf(float(dmg) * 1.18))
				xp_val = int(ceilf(xp_val * 1.1))
			"wakebound":
				speed = float(speed) * 0.9
				xp_val = int(ceilf(float(xp_val) * 1.25))
				sc = float(sc) * 1.12
			"enlisted":
				speed = float(speed) * 1.08
				dmg = int(ceilf(float(dmg) * 1.08))
			"censused":
				hp = int(ceilf(float(hp) * 1.08))
				hp_max = int(ceilf(float(hp_max) * 1.08))
				dmg = int(ceilf(float(dmg) * 1.08))
			"tallied":
				speed = float(speed) * 1.08
				hp = int(ceilf(float(hp) * 0.96))
				hp_max = int(ceilf(float(hp_max) * 0.96))
				sc *= 1.07
			"writbound":
				dmg = int(ceilf(float(dmg) * 1.08))
				speed = float(speed) * 1.06
				hp = int(ceilf(float(hp) * 0.95))
				hp_max = int(ceilf(float(hp_max) * 0.95))
			"enrolled":
				hp = float(hp) * 1.1
				hp_max = float(hp_max) * 1.1
				dmg = int(ceilf(float(dmg) * 1.1))
				sc *= 1.1
			"audited":
				dmg = int(ceilf(float(dmg) * 1.12))
				speed = float(speed) * 0.9
				sc *= 1.1
			"reckoned":
				speed = float(speed) * 1.1
				xp_val = float(xp_val) * 1.15
				sc *= 1.06
			"saltbled":
				hp = float(hp) * 1.15
				hp_max = float(hp_max) * 1.15
				speed = float(speed) * 0.9
				sc *= 1.08
			"palemarked":
				dmg = int(ceilf(float(dmg) * 1.12))
				xp_val = int(ceilf(float(xp_val) * 1.2))
				sc *= 1.08
			"greysworn":
				speed = float(speed) * 1.1
				hp = float(hp) * 0.85
				hp_max = float(hp_max) * 0.85
				dmg = int(ceilf(float(dmg) * 1.1))
			"saltworn":
				speed = float(speed) * 0.92
				dmg = int(ceilf(float(dmg) * 1.15))
				xp_val = int(ceilf(float(xp_val) * 1.15))
				sc *= 1.1
			"embittered":
				sc = 0.95
				hp = int(hp * 1.0)
				hp_max = hp
				dmg *= 1.1
			"rusted":
				dmg = int(ceilf(dmg * 1.1))
				xp_val = int(ceilf(xp_val * 1.3))
			"brinetouched":
				hp *= 1.15
				xp_val = int(ceilf(xp_val * 1.3))
			"flotsam":
				hp *= 1.1
				xp_val = int(ceilf(xp_val * 1.3))
			"hoarfrost":
				# beku — pukulan mendinginkan darah pemain (chill_t di blok hit)
				hp *= 1.15
				hp_max = hp
				xp_val = int(xp_val * 1.3)
			"lurker":
				# pengintai — menunggu di pinggir cahaya, lalu menyergap
				aggro_range *= 0.5
				speed *= 1.3
				xp_val = int(xp_val * 1.3)
			"tidewrought":
				# tebal oleh tekanan — lambat tapi membandel
				hp *= 1.35
				hp_max = hp
				speed *= 0.85
				xp_val = int(xp_val * 1.4)
			"keenedged":
				# tajam — semua ujung, tanpa pertahanan
				dmg = int(dmg * 1.4)
				hp *= 0.85
				hp_max = hp
				xp_val = int(xp_val * 1.3)
			"spry":
				# cepat — sendi kendor, langkah tergesa
				speed *= 1.3
				hp *= 0.9
				hp_max = hp
				xp_val = int(xp_val * 1.25)
			"beacon":
				# lentera tengkorak — mengendusmu dari kejauhan
				aggro_range = float(aggro_range) * 1.6
				xp_val = int(xp_val * 1.3)
			"gutted":
				# belah — kematiannya menumpahkan kesembuhan
				hp *= 1.15
				hp_max = hp
				xp_val = int(xp_val * 1.2)
			"soulfed":
				# pesta bangkai — tiap sekutu yang jatuh di dekatnya mengenyangkannya
				hp *= 1.25
				hp_max = hp
				xp_val = int(xp_val * 1.3)
			"belltoll":
				# genta kematian — matinya membisukan gerombolannya sesaat
				hp *= 1.2
				xp_val = int(xp_val * 1.5)
			"seafaring":
				slow_immune = true
				xp_val = int(xp_val * 1.25)
			"tarred":
				# lengket — tiap pukulan menyeret kaki ke aspal
				hp *= 1.1
				speed *= 0.95
				xp_val = int(xp_val * 1.3)
			"bloated":
				# gemuk busuk — susah dibunuh, susah kabur
				hp *= 1.6
				speed *= 0.85
				sc *= 1.15
				xp_val = int(xp_val * 1.5)
				xp_val = int(xp_val * 1.4)
			"tideworn":
				# usang air asin: lambat namun berlapis — matinya mentitahkan 1 jiwa
				hp *= 1.3
				speed *= 0.85
				xp_val = int(xp_val * 1.3)
			"miser":
				# kikir: kematiannya mencuri 2 jiwa dari dompetmu
				hp *= 1.15
				xp_val = int(xp_val * 1.3)
			"brinebound":
				# tahanan garam: kematiannya meneteskan jiwa ekstra
				hp *= 1.1
				xp_val = int(xp_val * 1.3)
			"galeswept":
				# disapu badai: datang cepat, memukul lebih keras — lambungnya tipis
				speed *= 1.3
				dmg += 1
				hp *= 0.9
				xp_val = int(xp_val * 1.3)
			"ballasted":
				# pemberat kapal: nyaris tak bergerak, tebal sekali, pecah membayar jiwa
				speed *= 0.72
				hp *= 1.45
				hp_max = hp
				dmg += 1
				xp_val = int(xp_val * 1.4)
			"trenchborn":
				# dibesarkan di palung terdalam: lambat, tebal, memukul keras, pecah membayar jiwa
				speed *= 0.75
				hp *= 1.4
				hp_max = hp
				dmg += 2
				xp_val = int(xp_val * 1.4)
			"festering":
				# membusuk hidup: mulai biasa, membengkak makin kuat tiap denyut
				hp *= 1.15
				speed *= 0.95
				xp_val = int(xp_val * 1.35)
	scale = Vector3.ONE * sc
	_base_scale = scale
	hp_max = hp
	dmg_max = dmg + 4
	if elite:
		print("SPAWN ELITE ", arch_id)
	if is_boss:
		print("SPAWN BOSS hp=%.0f" % hp)


func _ready() -> void:
	add_to_group("enemies")
	ap = M.anim_player(self)
	# spawn pop: tumbuh dari tanah agar kemunculan terasa hidup
	if not is_boss:
		var s0 := scale
		scale = s0 * 0.2
		var stw: Tween = create_tween()
		stw.tween_property(self, "scale", s0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if mat != null:
		M.paint(self, mat)
	# kapsul tabrakan: layer 4 (musuh), menabrak world(1) + player(2) + musuh(4)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.15 * room_tile
	cap.height = 0.5 * room_tile
	cs.shape = cap
	cs.position.y = 0.28 * room_tile
	add_child(cs)
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	if (elite or nemesis) and not is_boss:
		_mk_hpbar()
		_mk_aura()
	if is_lurker:
		model_ref = get_child(0)
		if model_ref != null:
			model_ref.visible = false
	M.play_fuzzy(ap, ["idle"])


func _mk_hpbar() -> void:
	var t := _get_bar_tex()
	var bw := BAR_W * room_tile
	hpbar_bg = Sprite3D.new()
	hpbar_bg.texture = t
	hpbar_bg.pixel_size = bw / 64.0
	hpbar_bg.modulate = Color(0.1, 0.08, 0.1, 0.85)
	hpbar_bg.position = Vector3(0, 1.12 * room_tile, 0)
	hpbar_bg.visible = false
	add_child(hpbar_bg)
	hpbar_fg = Sprite3D.new()
	hpbar_fg.texture = t
	hpbar_fg.pixel_size = bw / 64.0
	hpbar_fg.modulate = Color(1.0, 0.3, 0.22, 0.95) if not elite else Color(1.0, 0.6, 0.15, 0.98)
	hpbar_fg.position = Vector3(0, 1.12 * room_tile, 0.02)
	hpbar_fg.visible = false
	add_child(hpbar_fg)
	if affix != "" or nemesis:
		hpbar_tag = Label3D.new()
		hpbar_tag.text = ("NEMESIS " + affix.to_upper()).strip_edges() if nemesis else affix.to_upper()
		hpbar_tag.font_size = 42
		hpbar_tag.modulate = Color(1.0, 0.25, 0.5) if nemesis else Color(1.0, 0.75, 0.3)
		hpbar_tag.outline_size = 14
		hpbar_tag.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
		hpbar_tag.position = Vector3(0, 1.26 * room_tile, 0)
		hpbar_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		hpbar_tag.visible = false
		add_child(hpbar_tag)


func _mk_aura() -> void:
	# cincin merah berdenyut di bawah elite — penanda bahaya instan
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.30
	torus.outer_radius = 0.40
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if nemesis:
		rm.albedo_color = Color(1.0, 0.15, 0.45, 0.8)
		rm.emission = Color(1.0, 0.1, 0.4)
		rm.emission_energy_multiplier = 2.4
	else:
		rm.albedo_color = Color(1.0, 0.25, 0.18, 0.7)
		rm.emission = Color(1.0, 0.2, 0.12)
		rm.emission_energy_multiplier = 1.8
	rm.emission_enabled = true
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = rm
	ring.mesh = torus
	ring.position.y = 0.06
	add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "scale", Vector3(1.15, 1.15, 1.15), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ring, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _mk_gold_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26
	torus.outer_radius = 0.38
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.85, 0.3, 0.75)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.8, 0.25)
	rm.emission_energy_multiplier = 2.2
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = rm
	ring.mesh = torus
	ring.position.y = 0.08
	add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "scale", Vector3(1.25, 1.25, 1.25), 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ring, "scale", Vector3.ONE, 0.55).set_trans(Tween.TRANS_SINE)


func _upd_hpbar() -> void:
	if hpbar_bg == null:
		return
	var frac := clampf(hp / hp_max, 0.0, 1.0)
	var show := frac < 1.0 and frac > 0.0
	hpbar_bg.visible = show
	hpbar_fg.visible = show
	if hpbar_tag != null:
		hpbar_tag.visible = show
	if hpbar_shown_frac < 0.0:
		hpbar_shown_frac = frac
	hpbar_fg.scale.x = hpbar_shown_frac
	hpbar_fg.position.x = -0.5 * BAR_W * room_tile * (1.0 - hpbar_shown_frac)


func _player() -> Node3D:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return null
	return ps[0]


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self:
			continue
		var d: Vector3 = global_position - o.global_position
		d.y = 0
		var dd := d.length()
		if dd < 0.9 and dd > 0.001:
			push += d.normalized() * (0.9 - dd) * room_tile * 1.5
	return push


func _alert_mark() -> void:
	var al := Label3D.new()
	al.text = "!!" if elite else "!"
	al.font_size = 110 if elite else 96
	al.modulate = Color(1.0, 0.85, 0.25) if elite else Color(1.0, 0.6, 0.3)
	al.outline_size = 16
	al.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	al.position = Vector3(0, 1.7, 0)
	add_child(al)
	var atw := al.create_tween()
	atw.set_parallel(true)
	atw.tween_property(al, "position:y", 2.4, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	atw.tween_property(al, "modulate:a", 0.0, 0.8)
	atw.chain().tween_callback(al.queue_free)

func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	if hpbar_shown_frac >= 0.0:
		var frac_t := clampf(hp / hp_max, 0.0, 1.0)
		if hpbar_shown_frac != frac_t:
			hpbar_shown_frac = move_toward(hpbar_shown_frac, frac_t, delta * 3.5)
			if hpbar_fg != null:
				hpbar_fg.scale.x = hpbar_shown_frac
				# sekarat: bar berdenyut memanggil eksekusi
				if frac_t < 0.25 and frac_t > 0.0:
					hpbar_fg.modulate.a = 0.65 + 0.35 * absf(sin(Time.get_ticks_msec() / 1000.0 * 9.0))
				else:
					hpbar_fg.modulate.a = 0.98
				hpbar_fg.position.x = -0.5 * BAR_W * room_tile * (1.0 - hpbar_shown_frac)
	anim_lock = max(0.0, anim_lock - delta)
	hex_t = maxf(0.0, hex_t - delta)
	if warden_bell:
		bell_t += delta
		if bell_t >= 6.0:
			bell_t = 0.0
			var bpl_ = get_tree().get_first_node_in_group("player")
			if bpl_ != null and global_position.distance_to(bpl_.global_position) < 5.0 * room_tile:
				bpl_.set("chill_t", maxf(float(bpl_.get("chill_t")), 2.0))
				var bsc_ = get_tree().current_scene
				if bsc_ != null and bsc_.has_method("_damage_number"):
					bsc_._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "TOLLED!", Color(0.85, 0.7, 0.3), false)
	if chaplain:
		chap_t += delta
		if chap_t >= 4.0:
			chap_t = 0.0
			var cpl_ = get_tree().get_first_node_in_group("player")
			if cpl_ != null and global_position.distance_to(cpl_.global_position) < 6.0 * room_tile:
				cpl_.set("weak_t", maxf(float(cpl_.get("weak_t")), 3.0))
				var csc_ = get_tree().current_scene
				if csc_ != null and csc_.has_method("_damage_number"):
					csc_._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "LITANY!", Color(0.6, 0.4, 0.8), false)
	if affix == "tidebound":
		slow_t = 0.0
	slow_t = maxf(0.0, slow_t - delta)
	mark_t = maxf(0.0, mark_t - delta)
	haste_t = maxf(0.0, haste_t - delta)
	if arch_id == "bilge_cantor":
		cantor_t += delta
		if cantor_t >= 3.0:
			cantor_t = 0.0
			for ca in get_tree().get_nodes_in_group("enemies"):
				if ca != self and ca.get("state") != "dead" and ca.global_position.distance_to(global_position) < 3.5 * room_tile:
					ca.set("haste_t", 3.5)
	vuln_t = maxf(0.0, vuln_t - delta)
	if slow_immune:
		slow_t = 0.0
	if fey and state == "chase":
		fey_t -= delta
		if fey_t <= 0.0:
			fey_t = randf_range(2.0, 3.5)
			var fp_ := _player()
			if fp_ != null:
				var fd_: Vector3 = fp_.global_position - global_position
				fd_.y = 0
				global_position += fd_.normalized() * minf(fd_.length() * 0.35, 0.8 * room_tile)
				if mat != null:
					mat.set_shader_parameter("flash", 0.7)
	sunder_t = maxf(0.0, sunder_t - delta)
	tender_t = maxf(0.0, tender_t - delta)
	if affix == "tidal":
		tidal_t += delta
		if tidal_t >= 2.0:
			tidal_t = 0.0
			for tf2 in get_tree().get_nodes_in_group("enemies"):
				if tf2 == self or tf2.get("state") == "dead":
					continue
				if tf2.global_position.distance_to(global_position) < 2.5 * room_tile:
					tf2.hp = minf(float(tf2.get("hp_max")), float(tf2.get("hp")) + float(tf2.get("hp_max")) * 0.04)
	# tanda debuff melayang: BURNING / HEXED / SUNDERED
	var mtxt := ""
	var mcol := Color(1.0, 0.55, 0.4)
	if burn_t > 0.0:
		mtxt = "BURNING"
	elif hex_t > 0.0:
		mtxt = "HEXED"
		mcol = Color(0.9, 0.5, 1.0)
	elif sunder_t > 0.0:
		mtxt = "SUNDERED"
		mcol = Color(1.0, 0.8, 0.35)
	if mtxt != "":
		if mark_tag == null:
			mark_tag = Label3D.new()
			mark_tag.font_size = 38
			mark_tag.outline_size = 10
			mark_tag.outline_modulate = Color(0.08, 0.02, 0.08, 0.9)
			mark_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			mark_tag.position = Vector3(0, 1.0 * room_tile, 0)
			add_child(mark_tag)
		mark_tag.text = mtxt
		mark_tag.modulate = mcol
		mark_tag.visible = true
	elif mark_tag != null:
		mark_tag.visible = false
	if burn_t > 0.0:
		burn_t -= delta
		_burn_acc += delta
		if _burn_acc >= 0.7:
			_burn_acc = 0.0
			take_hit(global_position, maxf(1.0, hp_max * 0.06))
			return
	if orator and activated:
		orator_t -= delta
		if orator_t <= 0.0:
			orator_t = 6.0
			_orator_pulse()
	if healer and activated:
		heal_t -= delta
		if heal_t <= 0.0:
			heal_t = 4.5
			_jack_pulse()
	if warlock and activated:
		war_t -= delta
		if war_t <= 0.0:
			war_t = 5.0
			_caller_pulse()
	if affix == "oathbound" and activated and state != "dead":
		oath_t -= delta
		if oath_t <= 0.0:
			oath_t = 4.0
			_oath_pulse()
	if affix == "festering" and activated and state != "dead":
		fest_t -= delta
		if fest_t <= 0.0:
			fest_t = 6.0
			_fest_swell()
	if bride and activated:
		bride_t -= delta
		if bride_t <= 0.0:
			bride_t = 5.5
			_bride_pulse()
	if cantor and activated:
		cantor_t -= delta
		if cantor_t <= 0.0:
			cantor_t = 6.5
			_cantor_call()
	if chime and activated and state != "dead":
		chime_t -= delta
		if chime_t <= 0.0:
			chime_t = 7.5
			_chime_toll()
	if is_warper and activated:
		warp_t -= delta
		if warp_t <= 0.0:
			var pw := _player()
			if pw != null and global_position.distance_to(pw.global_position) < aggro_range * 1.3:
				warp_t = randf_range(3.5, 5.0)
				var off := Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				if off.length() < 0.3:
					off = Vector3(0.6, 0, 0)
				global_position = pw.global_position + off.normalized() * prefer_range
				global_position.x = clampf(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
				global_position.z = clampf(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
				Sfx.play("dash", 0.9 + randf() * 0.25)
				var mw := get_tree().current_scene
				if mw != null and mw.has_method("_burst"):
					mw._burst(global_position, Color(0.6, 0.4, 1.0))
			else:
				warp_t = 0.5
	if stun_t > 0.0:
		stun_t -= delta
		if mat != null:
			mat.set_shader_parameter("flash", 0.2 + 0.18 * absf(sin(stun_t * 9.0)))
			mat.set_shader_parameter("tint", Color(0.75, 0.85, 1.25))
		velocity = kb
		kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
		move_and_slide()
		global_position.y = 0.0
		if stun_t <= 0.0 and mat != null:
			mat.set_shader_parameter("flash", 0.0)
			mat.set_shader_parameter("tint", Color(1.35, 0.35, 0.3) if enraged else _tint0)
		return
	if is_lurker and not lurk_revealed:
		var lp := _player()
		var lrange := 1.3
		if Stats.relics.has("mata_perenungan"):
			lrange = 2.6
		if activated and lp != null and lp.get("dead") != true:
			var ld := global_position.distance_to(lp.global_position)
			if ld < lrange * room_tile:
				_lurk_reveal()
				return
			if ld < 2.4 * room_tile and not lurk_warned:
				lurk_warned = true
				Sfx.play("page")
				var m2 := get_tree().current_scene
				if m2 != null and m2.has_method("_damage_number"):
					m2._damage_number(global_position + Vector3(0, 0.5 * room_tile, 0), "...", Color(0.45, 0.45, 0.65), false)
			return
		return
	if not activated:
		velocity = kb
		kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
		move_and_slide()
		global_position.y = 0.0
		if anim_lock <= 0.0:
			M.play_fuzzy(ap, ["idle"])
		return
	var p := _player()
	if p == null:
		return
	var to: Vector3 = p.global_position - global_position
	to.y = 0
	var dist := to.length()
	state_t -= delta
	if is_weeper:
		chant_t -= delta
		if chant_t <= 0.0:
			chant_t = 3.0
			_chant()

	if p.get("dead") == true and state != "idle":
		state = "idle"
		if anim_lock <= 0.0:
			M.play_fuzzy(ap, ["idle"])

	if herald and activated and not herald_buffed and state != "dead":
		herald_buffed = true
		Sfx.play("roar")
		for h in get_tree().get_nodes_in_group("enemies"):
			if h == self or String(h.get("state")) == "dead":
				continue
			if int(h.get("room_idx")) == int(room_idx):
				h.dmg += 1
				h.speed *= 1.12
		var mh := get_tree().current_scene
		if mh != null and mh.has_method("_damage_number"):
			mh._damage_number(global_position + Vector3(0, 1.1 * room_tile, 0), "HERALD'S CRY", Color(1.05, 0.95, 0.4), true)
	# boss: fase 2 enrage + timer slam + panggil anak buah
	if is_boss and activated and state != "dead":
		if not enraged and hp <= hp_max * 0.5:
			enraged = true
			speed *= 1.4
			windup_t *= 0.7
			Sfx.play("roar")
			if mat != null:
				mat.set_shader_parameter("tint", Color(1.35, 0.35, 0.3))
			var m := get_tree().current_scene
			if m != null and m.has_method("_boss_enraged"):
				m._boss_enraged()
			print("BOSS ENRAGE")
		slam_t -= delta
		summon_t -= delta
		if state == "chase" and slam_t <= 0.0 and dist < 1.5 * room_tile:
			slam_t = 7.5 if not enraged else 5.5
			state = "slamming"
			state_t = 0.95
			_slam_telegraph()
		if summon_t <= 0.0:
			summon_t = 15.0 if not enraged else 9.0
			summon_requested.emit(self)
	# necromancer: membangkitkan antek tulang berkala
	if is_summoner and activated and state != "dead":
		summon_t -= delta
		if summon_t <= 0.0:
			summon_t = 13.0
			summon_requested.emit(self)

	match state:
		"idle":
			velocity = Vector3.ZERO
			if dist < aggro_range:
				state = "chase"
				_alert_mark()
				if randf() < 0.35:
					Sfx.play("whisper", 0.85 + randf() * 0.2)
				if digger and not digger_dug:
					digger_dug = true
					var mdig := get_tree().current_scene
					if mdig != null and mdig.has_method("_dig_trap"):
						mdig._dig_trap(global_position)
		"chase":
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 10.0)
			var engage := attack_range
			if ranged:
				engage = prefer_range
			if dist < engage:
				state = "windup"
				state_t = windup_t * (1.0 - 0.4 * (1.0 - hp / hp_max) if (affix == "charged" or arch_id == "bilge_fury") else 1.0) * (0.75 if haste_t > 0.0 else 1.0) * (1.45 if affix == "lagged" else 1.0)
				velocity = Vector3.ZERO
				scale = _base_scale * 1.06
				if mat != null:
					mat.set_shader_parameter("flash", 0.4)
				if anim_lock <= 0.0:
					M.play_fuzzy(ap, ["idle_combat", "idle"])
			else:
				var dir := to.normalized()
				if coward:
					dir = -dir
				# DESPERATE: nyawa tipis melarikan diri (gerombolan saja)
				elif not ranged and not elite and not is_boss and hp < hp_max * 0.18 and ["chaser", "crawler", "hound", "moth"].has(arch_id):
					dir = -dir
				# mage mundur kalau player terlalu dekat
				elif ranged and dist < prefer_range * 0.55:
					dir = -dir
				var mv_: Vector3 = dir * speed * (0.5 if slow_t > 0.0 else 1.0) * (1.0 + 0.5 * (1.0 - hp / hp_max) if arch_id == "bilge_fury" else 1.0)
				if eel:
					eel_t -= delta
					if eel_t <= 0.0 and dist < 2.4 * room_tile and dist > engage * 1.2:
						eel_t = 2.5
						eel_dash_t = 0.35
						eel_dir = dir
						if mat != null:
							mat.set_shader_parameter("flash", 0.5)
					if eel_dash_t > 0.0:
						eel_dash_t -= delta
						mv_ = eel_dir * speed * 3.2
				velocity = mv_ + _separation() + kb
				if anim_lock <= 0.0:
					M.play_fuzzy(ap, ["run", "walk"])
		"windup":
			velocity = Vector3.ZERO
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 6.0)
			if is_bomber and mat != null:
				mat.set_shader_parameter("flash", 0.4 + 0.5 * absf(sin(state_t * 22.0)))
			elif mat != null:
				mat.set_shader_parameter("flash", 0.12 + 0.18 * absf(sin(state_t * 12.0)))
			# squash antisipasi: balik ke ukuran normal begitu strike tiba
			var wp := clampf(state_t / maxf(windup_t, 0.001), 0.0, 1.0)
			scale = _base_scale * (1.0 + 0.06 * wp)
			if state_t <= 0.0:
				state = "strike"
				scale = _base_scale
				if mat != null:
					var tw := create_tween()
					tw.tween_property(mat, "shader_parameter/flash", 0.0, 0.1)
				if is_bomber:
					_explode()
				elif ranged:
					anim_lock = M.play_action(ap, ["spellcast_shoot", "spellcast"], 1.2) * 0.7
					await get_tree().create_timer(0.22).timeout
					if state == "strike":
						var q2 := _player()
						if q2 != null and q2.get("dead") != true:
							var pr = null
							if not siren:
								pr = PROJ.new()
								get_parent().add_child(pr)
								if is_hexer:
									pr.effect = "silence"
									if pr.orb != null:
										var hm: StandardMaterial3D = pr.orb.mesh.material
										hm.albedo_color = Color(1.0, 0.25, 0.4)
								if is_chiller:
									pr.effect = "chill"
									if pr.orb != null:
										var cm: StandardMaterial3D = pr.orb.mesh.material
										cm.albedo_color = Color(0.5, 0.85, 1.0)
										cm.emission = Color(0.4, 0.7, 1.0)
								if hookshot:
									pr.effect = "hook"
									pr.hook_src = global_position
									if pr.orb != null:
										var hm2: StandardMaterial3D = pr.orb.mesh.material
										hm2.albedo_color = Color(0.5, 0.85, 0.9)
										hm2.emission = Color(0.4, 0.7, 0.85)
								if is_gale:
									pr.effect = "gale"
									if pr.orb != null:
										var gm: StandardMaterial3D = pr.orb.mesh.material
										gm.albedo_color = Color(0.6, 0.9, 1.0)
										gm.emission = Color(0.4, 0.8, 0.95)
								if is_venom:
									pr.effect = "venom"
									if pr.orb != null:
										var vm: StandardMaterial3D = pr.orb.mesh.material
										vm.albedo_color = Color(0.45, 0.85, 0.3)
										vm.emission = Color(0.3, 0.7, 0.2)
								if is_waver:
									pr.effect = "weak"
									if pr.orb != null:
										var wm: StandardMaterial3D = pr.orb.mesh.material
										wm.albedo_color = Color(0.95, 0.65, 0.3)
										wm.emission = Color(0.9, 0.5, 0.15)
							if siren and Stats.relics.has("deaf_cap"):
								var msr0 := get_tree().current_scene
								if msr0 != null and msr0.has_method("_damage_number"):
									msr0._damage_number(q2.global_position + Vector3(0, 0.8 * room_tile, 0), "DEAFENED", Color(0.6, 0.9, 0.9), false)
							elif siren:
								# hisap: seret pemain ke arah sirene
								var pd: Vector3 = global_position - q2.global_position
								pd.y = 0
								if pd.length() > 0.8 * room_tile:
									q2.global_position += pd.normalized() * 1.1 * room_tile
								q2.velocity += pd.normalized() * room_tile * 5.0
								var msr := get_tree().current_scene
								if msr != null and msr.has_method("_damage_number"):
									msr._damage_number(q2.global_position + Vector3(0, 0.8 * room_tile, 0), "ENCHANTED", Color(0.7, 0.5, 1.15), false)
								Sfx.play("souls", 0.95 + randf() * 0.15)
							elif burst:
								# dua peluru berurutan — bidak pertama lurus, kedua mengejar
								pr.launch(global_position + Vector3(0, 1.0 * scale.x, 0), q2.global_position + Vector3(0, 0.9, 0), proj_speed, dmg, 0.35 * room_tile)
								if mat != null:
									mat.set_shader_parameter("flash", 0.85)
								await get_tree().create_timer(0.22).timeout
								if state != "dead":
									var pr2 = PROJ.new()
									get_tree().current_scene.add_child(pr2)
									pr2.launch(global_position + Vector3(0, 1.0 * scale.x, 0), q2.global_position + Vector3(0, 0.9, 0), proj_speed, dmg, 0.35 * room_tile)
							else:
								pr.launch(global_position + Vector3(0, 1.0 * scale.x, 0), q2.global_position + Vector3(0, 0.9, 0), proj_speed, dmg, 0.35 * room_tile)
								if mat != null:
									mat.set_shader_parameter("flash", 0.85)
						state = "recover"
						state_t = 1.1
				else:
					anim_lock = M.play_action(ap, ["melee_attack"], 1.3) * 0.7
					Sfx.play("swing", 0.92 + randf() * 0.16)
					if dash:
						kb += Vector3(sin(rotation.y), 0, cos(rotation.y)) * room_tile * 2.8
					await get_tree().create_timer(0.13).timeout
					if state == "strike":
						var q := _player()
						if q != null and q.get("dead") != true:
							var dto: Vector3 = q.global_position - global_position
							dto.y = 0
							if dto.length() < attack_range * 1.3:
								var dmulti := 1.0
								if affix == "reaper" and float(q.get("hp")) <= float(q.get("max_hp")) * 0.25:
									dmulti = 1.5
									var mm6 := get_tree().current_scene
									if mm6 != null and mm6.has_method("_damage_number"):
										mm6._damage_number(q.global_position + Vector3(0, 0.8 * room_tile, 0), "REAPED!", Color(1.0, 0.3, 0.2), true)
								q.take_hit(global_position, dmg * dmulti)
								if affix == "venomed" and q == p:
									p.set("venom_t", 4.0)
								if affix == "corroded" and q == p:
									p.set("rust_t", 3.0)
								if affix == "saltbitten" and q == p:
									p.set("weak_t", maxf(float(p.get("weak_t")), 2.0))
								if affix == "numbing" and q == p:
									p.set("cd", maxf(float(p.get("cd")), 0.9))
								if affix == "hungry" and q == p:
									speed *= 1.06
								if affix == "grasping" and q == p:
									var gdir: Vector3 = global_position - p.global_position
									gdir.y = 0.0
									if gdir.length() > 0.01:
										p.velocity += gdir.normalized() * 6.0
								if affix == "leeched" and q == p:
									hp = minf(hp_max, hp + dmg * 0.4)
								if affix == "tarbound" and q == p:
									p.set("chill_t", maxf(float(p.get("chill_t")), 1.5))
								if affix == "windlashed" and q == p:
									var wdir: Vector3 = (p.global_position - global_position).normalized()
									p.velocity += wdir * 14.0
								if affix == "stormborn" and q == p:
									var sdir: Vector3 = (p.global_position - global_position).normalized()
									p.velocity += sdir * 10.0
									if mat != null:
										mat.set_shader_parameter("flash", 0.6)
								if arch_id == "quarter_ghost" and q == p:
									hp = minf(hp_max, hp + dmg * 0.4)
								if arch_id == "brine_monk" and q == p:
									p.set("weak_t", maxf(float(p.get("weak_t")), 2.5))
								if arch_id == "salt_devout" and q == p:
									p.set("silence_t", maxf(float(p.get("silence_t")), 1.5))
								if arch_id == "jeerjack" and q == p:
									var mjj := get_tree().current_scene
									if mjj != null and int(mjj.get("combo") or 0) > 0:
										mjj.set("combo", maxi(0, int(mjj.get("combo")) - 2))
										if mjj.has_method("_damage_number"):
											mjj._damage_number(p.global_position + Vector3(0, 1.0 * room_tile, 0), "RATTLED!", Color(0.9, 0.5, 0.9), true)
								if arch_id == "tide_bailiff" and q == p:
									var mtb := get_tree().current_scene
									if mtb != null and int(Stats.souls) > 0:
										Stats.souls -= 1
										if mtb.has_method("_souls_l"):
											mtb._souls_l()
										if mtb.has_method("_damage_number"):
											mtb._damage_number(p.global_position + Vector3(0, 1.0 * room_tile, 0), "SEIZED -1", Color(0.9, 0.75, 0.3), true)
								var mlt := get_tree().current_scene
								if mlt != null and bool(mlt.get("leech_tide")) and q == p and int(Stats.souls) > 0:
									Stats.souls -= 1
									if mlt.has_method("_souls_l"):
										mlt._souls_l()
									if mlt.has_method("_damage_number"):
										mlt._damage_number(p.global_position + Vector3(0, 1.0 * room_tile, 0), "LEECH -1", Color(0.6, 0.3, 0.4), false)
								if affix == "rusted" and q == p:
									p.set("weak_t", maxf(float(p.get("weak_t")), 2.0))
								if affix == "brinetouched" and q == p:
									p.set("chill_t", maxf(float(p.get("chill_t")), 1.5))
								if affix == "gloomtouched" and q == p:
									p.set("root_t", maxf(float(p.get("root_t") or 0.0), 0.8))
								if affix == "pitchwell" and q == p:
									var mpw := get_tree().current_scene
									if mpw != null and int(Stats.souls) > 0:
										Stats.souls -= 1
										if mpw.has_method("_souls_l"):
											mpw._souls_l()
										if mpw.has_method("_damage_number"):
											mpw._damage_number(p.global_position + Vector3(0, 1.0 * room_tile, 0), "DRAINED -1", Color(0.5, 0.45, 0.6), true)
								if affix == "giltborn" and q == p and randf() < 0.35:
									Stats.earn_souls(1)
									var mgb2 := get_tree().current_scene
									if mgb2 != null and mgb2.has_method("_souls_l"):
										mgb2._souls_l()
									if mgb2 != null and mgb2.has_method("_damage_number"):
										mgb2._damage_number(p.global_position + Vector3(0, 1.1 * room_tile, 0), "GILT +1", Color(1.0, 0.85, 0.3), true)
								if affix == "hoarfrost" and q == p:
									p.set("chill_t", maxf(float(p.get("chill_t")), 2.5))
								if affix == "reefbound" and q == p:
									hp = minf(hp_max, hp + dmg * 0.5)
								if affix == "riptide" and q == p:
									var rdir: Vector3 = p.global_position - global_position
									rdir.y = 0
									p.kb += rdir.normalized() * room_tile * 3.0
									var mrt := get_tree().current_scene
									if mrt != null and mrt.has_method("_damage_number"):
										mrt._damage_number(p.global_position + Vector3(0, 0.8 * room_tile, 0), "SWEPT!", Color(0.4, 0.75, 1.0), false)
								if mire and q == p:
									p.set("chill_t", 2.0)
									var mm7 := get_tree().current_scene
									if mm7 != null and mm7.has_method("_damage_number"):
										mm7._damage_number(p.global_position, "MIRED", Color(0.5, 0.85, 0.55), true)
								if is_ruster and q == p:
									p.set("rust_t", 2.0 if Stats.relics.has("polishing_rag") else 4.0)
									var mrj := get_tree().current_scene
									if mrj != null and mrj.has_method("_damage_number"):
										mrj._damage_number(p.global_position + Vector3(0, 0.8 * room_tile, 0), "RUSTED!", Color(0.75, 0.55, 0.35), true)
								if affix == "webbed" and q == p:
									p.set("root_t", 1.5)
								if affix == "grim" and q == p:
									p.set("weak_t", 3.0)
								if affix == "drowning" and q == p:
									p.set("chill_t", 2.0)
								if sawblade and q == p:
									p.set("rust_t", 4.0)
								if affix == "tarred" and q == p:
									p.set("chill_t", maxf(float(p.get("chill_t")), 1.5))
								if leech and q == p:
									hp = minf(hp_max, hp + 1.0)
									var ls_ := get_tree().current_scene
									if ls_ != null and ls_.has_method("_damage_number"):
										ls_._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "DRANK +1", Color(0.8, 0.5, 0.8), false)
								if sprite and q == p:
									var sm_ := get_tree().current_scene
									if sm_ != null and int(Stats.souls) > 0:
										Stats.souls -= 1
										if sm_.has_method("_souls_l"):
											sm_._souls_l()
										if sm_.has_method("_damage_number"):
											sm_._damage_number(p.global_position + Vector3(0, 1.1 * room_tile, 0), "SKIMMED −1", Color(0.4, 0.9, 0.7), true)
								if fanatic and q == p:
									p.set("rust_t", maxf(float(p.get("rust_t")), 3.0))
								if affix == "crushing" and q == p:
									var cdir: Vector3 = p.global_position - global_position
									cdir.y = 0
									p.kb += cdir.normalized() * room_tile * 5.0
								if affix == "wrack" and q == p:
									var mw_ := get_tree().current_scene
									if mw_ != null and mw_.get("skill_cd") is Dictionary:
										for sk3 in mw_.get("skill_cd").keys():
											mw_.get("skill_cd")[sk3] = float(mw_.get("skill_cd")[sk3]) + 1.0
										if mw_.has_method("_damage_number"):
											mw_._damage_number(p.global_position + Vector3(0, 1.1 * room_tile, 0), "WRACKED — skill charge −1s", Color(0.5, 0.4, 0.7), true)
										if mw_.has_method("_hud_silence_flash"):
											mw_._hud_silence_flash()
								if affix == "parched" and q == p:
									var mp_ := get_tree().current_scene
									if mp_ != null and Stats.souls > 0:
										Stats.souls -= 1
										if mp_.has_method("_souls_l"):
											mp_._souls_l()
										if mp_.has_method("_damage_number"):
											mp_._damage_number(q.global_position + Vector3(0, 0.9 * room_tile, 0), "PARCHED — -1 soul", Color(0.5, 0.9, 0.6), true)
								var mb_ := get_tree().current_scene
								if mb_ != null and bool(mb_.get("bile_tide")) and q == p:
									p.set("venom_t", 1.5)
								if is_widow and q == p:
									p.set("root_t", 2.0)
									var mw := get_tree().current_scene
									if mw != null and mw.has_method("_damage_number"):
										mw._damage_number(p.global_position + Vector3(0, 0.8 * room_tile, 0), "WEBBED!", Color(0.6, 0.55, 0.75), true)
								if keelh and q == p:
									var mkh := get_tree().current_scene
									if Stats.souls > 0:
										Stats.souls -= 1
										if mkh != null and mkh.has_method("_souls_l"):
											mkh._souls_l()
										if mkh != null and mkh.has_method("_damage_number"):
											mkh._damage_number(q.global_position + Vector3(0, 0.9 * room_tile, 0), "SNATCHED — -1 soul", Color(0.4, 0.9, 0.95), false)
										if mkh != null and mkh.has_method("_quest_event"):
											mkh._quest_event("snatched")
								if tither and q == p:
									var mt2 := get_tree().current_scene
									var stol := mini(2, Stats.souls)
									if stol > 0:
										Stats.souls -= stol
										if mt2 != null and mt2.has_method("_souls_l"):
											mt2._souls_l()
										if mt2 != null and mt2.has_method("_damage_number"):
											mt2._damage_number(q.global_position + Vector3(0, 0.9 * room_tile, 0), "TITHED — -%d souls" % stol, Color(0.5, 0.95, 0.6), true)
								if knocker:
									var kdir: Vector3 = q.global_position - global_position
									kdir.y = 0
									q.velocity += kdir.normalized() * room_tile * 6.0
									var mkn := get_tree().current_scene
									if mkn != null and mkn.has_method("_damage_number"):
										mkn._damage_number(q.global_position + Vector3(0, 0.7 * room_tile, 0), "BATTERED!", Color(1.0, 0.6, 0.25), true)
								if affix == "vampiric":
									hp = minf(hp_max, hp + dmg * dmulti * 0.35)
								if gnawer:
									hp = minf(hp_max, hp + 1.0)
								if is_slammer:
									_shock()
								if jailer and q.get("dead") != true:
									q.set("root_t", 1.2)
									var mm3 := get_tree().current_scene
									if mm3 != null and mm3.has_method("_damage_number"):
										mm3._damage_number(q.global_position, "CAGED!", Color(0.65, 0.45, 1.0), true)
									Sfx.play("gate")
								if affix == "frostbite":
									q.set("chill_t", 3.0)
									var mm4 := get_tree().current_scene
									if mm4 != null and mm4.has_method("_damage_number"):
										mm4._damage_number(q.global_position, "CHILLED", Color(0.5, 0.75, 1.0), true)
								if affix == "warden" and q.get("dead") != true:
									q.set("root_t", 1.0)
									var mm5 := get_tree().current_scene
									if mm5 != null and mm5.has_method("_damage_number"):
										mm5._damage_number(q.global_position, "BOUND", Color(0.8, 0.5, 1.1), true)
									Sfx.play("gate")
								if affix == "siphon":
									var mm := get_tree().current_scene
									if mm != null and mm.get("combo") != null and int(mm.combo) > 0 and mm.has_method("_combo_set"):
										mm._combo_set(0)
										if mm.has_method("_damage_number"):
											mm._damage_number(q.global_position, "COMBO SIPHONED", Color(0.5, 0.65, 1.0), true)
										Sfx.play("deny")
						state = "recover"
						state_t = 0.7
						if kiter:
							var qk := _player()
							if qk != null:
								var bk: Vector3 = global_position - qk.global_position
								bk.y = 0
								if bk.length() > 0.01:
									global_position += bk.normalized() * 1.3 * room_tile
		"slamming":
			velocity = Vector3.ZERO
			if state_t <= 0.0:
				var dto2: Vector3 = p.global_position - global_position
				dto2.y = 0
				if dto2.length() < 1.35 * room_tile and p.get("dead") != true:
					p.take_hit(global_position, dmg + 1)
			if affix == "bitter":
				dmg += 2
				_shock()
				_tier_slam()
				state = "recover"
				state_t = 0.8
		"strike":
			velocity = Vector3.ZERO
		"recover":
			velocity = Vector3.ZERO
			if state_t <= 0.0:
				state = "chase"

	kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
	if phase_foe:
		global_position += velocity * delta
	else:
		move_and_slide()
	global_position.x = clamp(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
	global_position.z = clamp(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
	global_position.y = 0.0


# lingkar telegraph merah sebelum slam boss
func _slam_telegraph() -> void:
	var mi := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.42
	tor.outer_radius = 0.5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.2, 0.15, 0.85)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.15, 0.1)
	m.emission_energy_multiplier = 3.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = m
	mi.mesh = tor
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.2, 0)
	mi.scale = Vector3.ONE * 0.4 * room_tile
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.35 * room_tile, 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mi.queue_free)


func _shock() -> void:
	var mi := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.44
	tor.outer_radius = 0.5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.5, 0.2, 0.9)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.4, 0.1)
	m.emission_energy_multiplier = 4.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = m
	mi.mesh = tor
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.25, 0)
	mi.scale = Vector3.ONE * 0.3 * room_tile
	Sfx.play("thunder")
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.6 * room_tile, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.2)
	tw.tween_callback(mi.queue_free)


# gimmick per-tipe raja setelah slam
func _tier_slam() -> void:
	match tier_idx:
		1:  # EMBER — meneteskan 3 kolam api bertahan 4s
			for _i in range(3):
				var fp := FPOOL.new()
				get_parent().add_child(fp)
				fp.global_position = global_position + Vector3(randf_range(-1.1, 1.1), 0, randf_range(-1.1, 1.1)) * room_tile
				fp.setup(room_tile)
		2:  # FROST — membekukan: pemain 55% speed selama 3s
			var p2 := _player()
			if p2 != null and p2.get("dead") != true:
				p2.set("chill_t", 3.0)
		3:  # FERAL — makin cepat setiap slam
			speed = minf(speed * 1.12, 4.5 * room_tile)
		_:  # UNDYING (lantai 25) — mewarisi semua kekuatan
			for _i in range(2):
				var fp2 := FPOOL.new()
				get_parent().add_child(fp2)
				fp2.global_position = global_position + Vector3(randf_range(-1.1, 1.1), 0, randf_range(-1.1, 1.1)) * room_tile
				fp2.setup(room_tile)
			var p3 := _player()
			if p3 != null and p3.get("dead") != true:
				p3.set("chill_t", 2.5)
				# UNDYING: seruan siren — slam juga menarik pemain ke mulutnya
				if not Stats.relics.has("deaf_cap"):
					var pull: Vector3 = global_position - p3.global_position
					pull.y = 0
					if pull.length() > 1.0 * room_tile:
						p3.global_position += pull.normalized() * 0.7 * room_tile
					p3.velocity += pull.normalized() * room_tile * 4.0
					var mu := get_tree().current_scene
					if mu != null and mu.has_method("_damage_number"):
						mu._damage_number(p3.global_position + Vector3(0, 0.8 * room_tile, 0), "CALLED", Color(0.7, 0.5, 1.15), false)
			speed = minf(speed * 1.08, 4.5 * room_tile)


# bomber: meledak — luka player DAN musuh lain di radius
func _explode() -> void:
	var p := _player()
	var r := 1.0 * room_tile
	if p != null and p.get("dead") != true:
		var dto: Vector3 = p.global_position - global_position
		dto.y = 0
		if dto.length() < r:
			p.take_hit(global_position, dmg)
			if affix == "bitter":
				dmg += 2
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self:
			continue
		var d2: Vector3 = o.global_position - global_position
		d2.y = 0
		if d2.length() < r:
			o.take_hit(global_position, dmg * 0.5)
	_shock()
	hp = 0.0
	state = "dead"
	remove_from_group("enemies")
	if mat != null:
		mat.set_shader_parameter("flash", 1.0)
	anim_lock = M.play_action(ap, ["death"], 1.2)
	died.emit(self)
	var ctm := get_tree().create_timer(2.4)
	ctm.timeout.connect(_corpse_fade)


func _corpse_fade() -> void:
	if not is_inside_tree():
		return
	var ctw := create_tween()
	ctw.set_parallel(true)
	ctw.tween_property(self, "modulate:a", 0.0, 1.1)
	ctw.tween_property(self, "position:y", position.y - 0.35 * room_tile, 1.1)


func _jack_pulse() -> void:
	# lentera hijau: semua musuh di ruangan ini pulih +1 HP (hingga max)
	var mj := get_tree().current_scene
	if mj != null and mj.has_method("_burst"):
		mj._burst(global_position + Vector3(0, 0.6 * room_tile, 0), Color(0.4, 0.95, 0.5))
	if mj != null and mj.has_method("_damage_number"):
		mj._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "LANTERN GLOW", Color(0.45, 0.95, 0.5), false)
	Sfx.play("shrine")
	for e3 in get_tree().get_nodes_in_group("enemies"):
		if e3 == self or not is_instance_valid(e3) or String(e3.get("state")) == "dead":
			continue
		if int(e3.get("room_idx")) != room_idx:
			continue
		e3.hp = minf(float(e3.hp) + 1.0, float(e3.hp_max))


func _oath_pulse() -> void:
	var sc := get_tree().current_scene
	if sc == null:
		return
	for e2 in sc.enemies:
		if is_instance_valid(e2) and e2 != self and e2.state != "dead":
			var dd: float = (e2.global_position - global_position).length()
			if dd < 8.0 * room_tile:
				e2.hp = minf(e2.hp_max, e2.hp + 1.0)
				if sc.has_method("_burst"):
					sc._burst(e2.global_position + Vector3(0, 0.6 * room_tile, 0), Color(0.5, 1.0, 0.8))

func _fest_swell() -> void:
	# membusuk: tiap denyut membengkak — dmg & speed naik, maksimal 5 bengkak
	if fest_n >= 5:
		return
	fest_n += 1
	dmg += 1
	dmg_max += 1
	speed *= 1.05
	var sc := get_tree().current_scene
	if sc != null and sc.has_method("_burst"):
		sc._burst(global_position + Vector3(0, 0.6 * room_tile, 0), Color(0.55, 0.85, 0.35))
	if sc != null and sc.has_method("_damage_number"):
		sc._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "SWELLS", Color(0.6, 0.9, 0.4), true)
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.06, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _bride_pulse() -> void:
	# pengantin busuk: nyanyiannya mempercepat sekutu ruangan (+8% per chant, cap +24%)
	var mb := get_tree().current_scene
	if mb != null and mb.has_method("_burst"):
		mb._burst(global_position + Vector3(0, 0.6 * room_tile, 0), Color(0.9, 0.5, 0.6))
	if mb != null and mb.has_method("_damage_number"):
		mb._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "BRIDE'S REEL", Color(0.9, 0.55, 0.65), false)
	Sfx.play("roar")
	for e5 in get_tree().get_nodes_in_group("enemies"):
		if e5 == self or not is_instance_valid(e5) or String(e5.get("state")) == "dead":
			continue
		if int(e5.get("room_idx")) != room_idx:
			continue
		if int(e5.get("spd_boost")) < 3:
			e5.set("speed", float(e5.get("speed")) * 1.08)
			e5.set("spd_boost", int(e5.get("spd_boost")) + 1)


func _chime_toll() -> void:
	var sc := get_tree().current_scene
	if sc == null:
		return
	for e2 in sc.enemies:
		if is_instance_valid(e2) and e2 != self and e2.state != "dead":
			var dd: float = (e2.global_position - global_position).length()
			if dd < 9.0 * room_tile and not bool(e2.get("activated")):
				e2.set("activated", true)
	Sfx.play("quest")
	if sc.has_method("_damage_number"):
		sc._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "TOLL!", Color(0.9, 0.8, 0.4), false)

func _cantor_call() -> void:
	# salt cantor: panggilannya membangunkan seluruh ruangan
	var mb := get_tree().current_scene
	if mb != null and mb.has_method("_damage_number"):
		mb._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "THE CALL", Color(0.6, 0.9, 0.8), true)
	Sfx.play("roar")
	for e6 in get_tree().get_nodes_in_group("enemies"):
		if e6 == self or not is_instance_valid(e6) or String(e6.get("state")) == "dead":
			continue
		if int(e6.get("room_idx")) != room_idx:
			continue
		e6.set("activated", true)


func _caller_pulse() -> void:
	# karang pemanggil: setiap denyut memberi sekutu ruangan +1 dmg (hingga +4)
	var mw := get_tree().current_scene
	if mw != null and mw.has_method("_burst"):
		mw._burst(global_position + Vector3(0, 0.6 * room_tile, 0), Color(0.95, 0.5, 0.3))
	if mw != null and mw.has_method("_damage_number"):
		mw._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "CALL OF THE REEF", Color(0.95, 0.6, 0.35), false)
	Sfx.play("shrine")
	for e4 in get_tree().get_nodes_in_group("enemies"):
		if e4 == self or not is_instance_valid(e4) or String(e4.get("state")) == "dead":
			continue
		if int(e4.get("room_idx")) != room_idx:
			continue
		if int(e4.get("dmg")) < int(e4.get("dmg_max")):
			e4.set("dmg", int(e4.get("dmg")) + 1)


func _orator_pulse() -> void:
	# nyanyian perang: semua musuh di ruangan ini +1 dmg (hingga cap +4)
	var mo := get_tree().current_scene
	if mo != null and mo.has_method("_burst"):
		mo._burst(global_position + Vector3(0, 0.6 * room_tile, 0), Color(1.0, 0.7, 0.3))
	if mo != null and mo.has_method("_damage_number"):
		mo._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "WAR CHANT!", Color(1.0, 0.75, 0.35), false)
	Sfx.play("roar")
	for e2 in get_tree().get_nodes_in_group("enemies"):
		if e2 == self or not is_instance_valid(e2) or String(e2.get("state")) == "dead":
			continue
		if int(e2.get("room_idx")) != room_idx:
			continue
		if int(e2.get("dmg")) < int(e2.get("dmg_max")):
			e2.dmg = int(e2.get("dmg")) + 1


func _lurk_reveal() -> void:
	lurk_revealed = true
	if model_ref != null:
		model_ref.visible = true
	speed *= 1.3
	Sfx.play("roar")
	var ml3 := get_tree().current_scene
	if ml3 != null:
		if ml3.has_method("_burst"):
			ml3._burst(global_position, Color(0.9, 0.85, 1.15))
		if ml3.has_method("_damage_number"):
			ml3._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "LURKER!", Color(0.9, 0.85, 1.2), false)


func take_hit(from_pos: Vector3, dmg_taken: float) -> void:
	if state == "dead":
		return
	if affix == "warped" and randf() < 0.3:
		var wdir2: Vector3 = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
		if wdir2.length() > 0.01:
			global_position += wdir2.normalized() * room_tile * 0.9
			var mwarp := get_tree().current_scene
			if mwarp != null and mwarp.has_method("_burst"):
				mwarp._burst(global_position, Color(0.5, 0.3, 0.9))
	if affix == "saltkin":
		dmg_taken *= 1.15
	if slow_t > 0.0 and Stats.relics.has("frostbrand"):
		dmg_taken *= 1.12
	if stun_t > 0.0 and Stats.relics.has("mooring_knot"):
		dmg_taken *= 1.15
	if vuln_t > 0.0:
		dmg_taken *= 1.25
	if is_lurker and not lurk_revealed:
		_lurk_reveal()
	if halfshell_shell:
		halfshell_shell = false
		dmg_taken = 0.0
		var hs2_ := get_tree().current_scene
		if hs2_ != null and hs2_.has_method("_damage_number"):
			hs2_._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "SHELL CRACKED", Color(0.7, 0.75, 0.6), false)
	if husk_shell:
		# kelter husk: pukulan pertama pecahkan cangkang saja
		husk_shell = false
		dmg_taken = 0.0
		var mh_ := get_tree().current_scene
		if mh_ != null and mh_.has_method("_burst"):
			mh_._burst(global_position + Vector3(0, 0.5 * room_tile, 0), Color(0.8, 0.75, 0.5))
		if mh_ != null and mh_.has_method("_damage_number"):
			mh_._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "HUSK CRACKED", Color(0.85, 0.8, 0.55), false)
		Sfx.play("hit")
	if affix == "slippery":
		slip_n += 1
		if slip_n >= 4:
			slip_n = 0
			dmg_taken = 0.0
			var ms_ := get_tree().current_scene
			if ms_ != null and ms_.has_method("_damage_number"):
				ms_._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "SLIPPED", Color(0.6, 0.8, 1.0), false)
	if affix == "mirrorhide" and dmg_taken > 0.0:
		var mp_ := _player()
		if mp_ != null and mp_.has_method("take_hit"):
			mp_.take_hit(global_position, maxi(1, int(ceil(dmg_taken * 0.1))))
	if hex_t > 0.0:
		dmg_taken *= 1.25
	if mark_t > 0.0:
		dmg_taken *= 1.15
	if sunder_t > 0.0:
		dmg_taken *= 1.3
	if not crowned and not is_boss:
		# THE CROWNED: paladin yang mengangkat musuh-musuh di sekitarnya
		for e3 in get_tree().get_nodes_in_group("enemies"):
			if e3 != self and is_instance_valid(e3) and bool(e3.get("crowned")) and String(e3.get("state")) != "dead" and int(e3.get("room_idx")) == room_idx:
				dmg_taken *= 0.75
				if randf() < 0.3:
					var mcr := get_tree().current_scene
					if mcr != null and mcr.has_method("_damage_number"):
						mcr._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "CROWNED", Color(0.75, 0.8, 1.0), false)
				break
	if shielded and dmg_taken > 0.0:
		var fwd2: Vector3 = -global_transform.basis.z
		var toh: Vector3 = from_pos - global_position
		toh.y = 0
		if toh.length() > 0.01 and fwd2.normalized().dot(toh.normalized()) > 0.55:
			dmg_taken *= 0.4
			var msh := get_tree().current_scene
			if msh != null and msh.has_method("_damage_number"):
				msh._damage_number(global_position + Vector3(0, 1.0 * room_tile, 0), "BLOCKED", Color(0.55, 0.7, 1.0), false)
	if affix == "pearlbound" and not _shell_cracked and dmg_taken > 0.0:
		_shell_hits += 1
		dmg_taken *= 0.5
		if _shell_hits >= 3:
			_shell_cracked = true
			var msh2 := get_tree().current_scene
			if msh2 != null and msh2.has_method("_damage_number"):
				msh2._damage_number(global_position + Vector3(0, 1.1 * room_tile, 0), "SHELL CRACKED", Color(0.9, 0.95, 1.0), true)
			var mq := get_tree().current_scene
			if mq != null and mq.has_method("_quest_event"):
				mq._quest_event("shellcrack")
	if dmg_reduce > 0.0 and dmg_taken > 0.0:
		dmg_taken *= (1.0 - dmg_reduce)
	was_low = hp > 0.0 and hp <= hp_max * 0.3
	if tender_t > 0.0:
		dmg_taken *= 1.25
	hp -= dmg_taken
	if dmg_taken > 0.0 and state != "dead":
		var htw := create_tween()
		htw.tween_property(self, "scale", _base_scale * Vector3(1.16, 0.82, 1.16), 0.05)
		htw.tween_property(self, "scale", _base_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if mat != null:
			mat.set_shader_parameter("flash", 0.7)
			var ftw := create_tween()
			ftw.tween_property(mat, "shader_parameter/flash", 0.0, 0.14)
	if affix == "sirensong" and not _siren_pulled and not Stats.relics.has("deaf_cap") and hp > 0.0 and hp <= hp_max * 0.4:
		_siren_pulled = true
		var p5 := _player()
		if p5 != null and p5.get("dead") != true:
			var pd2: Vector3 = global_position - p5.global_position
			pd2.y = 0
			if pd2.length() > 0.9 * room_tile:
				p5.global_position += pd2.normalized() * 1.2 * room_tile
			p5.velocity += pd2.normalized() * room_tile * 5.0
			var mu2 := get_tree().current_scene
			if mu2 != null and mu2.has_method("_damage_number"):
				mu2._damage_number(p5.global_position + Vector3(0, 0.8 * room_tile, 0), "ENCHANTED", Color(0.7, 0.5, 1.15), false)
	Sfx.play("hit", 0.9 + randf() * 0.2)
	if (is_spiky or affix == "thorned") and state != "dead":
		var p3 := _player()
		if p3 != null and p3.get("dead") != true and p3.global_position.distance_to(from_pos) < 0.5 * room_tile:
			p3.take_hit(global_position, 0.5)
			var msp := get_tree().current_scene
			if msp != null and msp.has_method("_damage_number"):
				msp._damage_number(p3.global_position + Vector3(0, 0.5 * room_tile, 0), "SPIKED", Color(1.0, 0.6, 0.2), false)
	if is_boss and hp > 0.0:
		var frac: float = hp / hp_max
		var mb := get_tree().current_scene
		if not banter_75 and frac <= 0.75:
			banter_75 = true
			if mb != null and mb.has_method("_boss_banter"):
				mb._boss_banter(0)
		elif not banter_10 and frac <= 0.1:
			banter_10 = true
			if mb != null and mb.has_method("_boss_banter"):
				mb._boss_banter(2)
		elif not banter_25 and frac <= 0.25:
			banter_25 = true
			if mb != null and mb.has_method("_boss_banter"):
				mb._boss_banter(1)
	var away: Vector3 = global_position - from_pos
	away.y = 0
	var kbf := 1.4
	var rime_scene := get_tree().current_scene
	if rime_scene != null and bool(rime_scene.get("rime_tide") or false):
		kbf *= 1.4
	kb = away.normalized() * room_tile * kbf * (1.0 - kb_resist)
	if mat != null:
		mat.set_shader_parameter("flash", 1.0)
		var tw := create_tween()
		tw.tween_property(mat, "shader_parameter/flash", 0.0, 0.2)
	if hp <= 0:
		state = "dead"
		remove_from_group("enemies")
		if affix == "vengeful":
			var p := _player()
			if p != null and p.get("dead") != true:
				var dv: Vector3 = p.global_position - global_position
				dv.y = 0
				if dv.length() < 1.0 * room_tile:
					p.take_hit(global_position, dmg * 0.6)
		if arch_id == "brood_keel":
			var mbk := get_tree().current_scene
			if mbk != null and mbk.has_method("_spawn_enemy"):
				for bkn in [Vector3(0.35, 0, 0.15), Vector3(-0.35, 0, -0.15)]:
					mbk._spawn_enemy({"pos": global_position + bkn * room_tile, "room": room_idx}, "gunnel_gnat", false)
				if mbk.has_method("_damage_number"):
					mbk._damage_number(global_position + Vector3(0, 1.0 * room_tile, 0), "BROOD!", Color(0.5, 0.8, 0.4), false)
		if arch_id == "powder_monkey":
			_explode()
		if affix == "volatile":
			var p2 := _player()
			if p2 != null and p2.get("dead") != true:
				var dv2: Vector3 = p2.global_position - global_position
				dv2.y = 0
				if dv2.length() < 1.6 * room_tile:
					p2.take_hit(global_position, dmg * 0.8)
			var mm2 := get_tree().current_scene
			if mm2 != null:
				if mm2.has_method("_shock_ring"):
					mm2._shock_ring(global_position)
				if mm2.has_method("_burst"):
					mm2._burst(global_position, Color(1.0, 0.4, 1.0))
		if affix == "belltoll":
			for bt_ in get_tree().get_nodes_in_group("enemies"):
				if bt_ != self and bt_.get("state") != "dead" and bt_.global_position.distance_to(global_position) < 3.0 * room_tile:
					if bt_.has_method("stun"):
						bt_.stun(1.5)
			var mbt := get_tree().current_scene
			if mbt != null:
				if mbt.has_method("_shock_ring"):
					mbt._shock_ring(global_position)
				if mbt.has_method("_damage_number"):
					mbt._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "TOLLED", Color(0.95, 0.8, 0.3), false)
		if affix == "reefsplit":
			var mrs := get_tree().current_scene
			if mrs != null and mrs.has_method("_spawn_enemy"):
				for rsn in [Vector3(0.3, 0, 0.0), Vector3(-0.3, 0, 0.0)]:
					mrs._spawn_enemy({"pos": global_position + rsn * room_tile, "room": room_idx}, "gunnel_gnat", false)
				if mrs.has_method("_damage_number"):
					mrs._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "SPLIT!", Color(0.5, 0.7, 0.4), false)
		if affix == "deathwarm":
			var foesw: Array = get_tree().get_nodes_in_group("enemies")
			for wf in foesw:
				if wf != null and wf != self and wf.global_position.distance_to(global_position) < 3.0 * room_tile:
					wf.hp = minf(float(wf.get("hp_max") or wf.hp), wf.hp + float(wf.get("hp_max") or wf.hp) * 0.2)
					var mw := get_tree().current_scene
					if mw != null and mw.has_method("_damage_number"):
						mw._damage_number(wf.global_position + Vector3(0, 0.8 * room_tile, 0), "WARMED", Color(0.5, 0.9, 0.5), true)
		if affix == "keelmaw":
			var mkm := get_tree().current_scene
			if mkm != null:
				Stats.earn_souls(2)
				if mkm.has_method("_damage_number"):
					mkm._damage_number(global_position + Vector3(0, 0.8 * room_tile, 0), "+2 ◈ KEELMAW", Color(0.8, 0.7, 0.4), true)
				if mkm.has_method("_souls_l"):
					mkm._souls_l()
		if affix == "tideheld":
			var foest: Array = get_tree().get_nodes_in_group("enemies")
			for tf in foest:
				if tf != null and tf != self and tf.global_position.distance_to(global_position) < 4.0 * room_tile:
					tf.set("slow_t", maxf(float(tf.get("slow_t") or 0.0), 1.5))
			var mt2 := get_tree().current_scene
			if mt2 != null and mt2.has_method("_damage_number"):
				mt2._damage_number(global_position + Vector3(0, 0.8 * room_tile, 0), "THE TIDE TAKES THEM", Color(0.4, 0.8, 0.9), true)
		if affix == "embittered":
			for be_ in get_tree().get_nodes_in_group("enemies"):
				if be_ != self and be_.get("state") != "dead" and be_.global_position.distance_to(global_position) < 3.5 * room_tile:
					be_.set("haste_t", 4.0)
			var mbe := get_tree().current_scene
			if mbe != null and mbe.has_method("_damage_number"):
				mbe._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "BITTERNESS SPREADS", Color(1.0, 0.35, 0.3), false)
		if affix == "keelborn":
			Stats.earn_souls(3)
			var mm4 := get_tree().current_scene
			if mm4 != null and mm4.has_method("_souls_l"):
				mm4._souls_l()
			if mm4 != null and mm4.has_method("_damage_number"):
				mm4._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "KEELBORN +3", Color(0.4, 0.9, 0.9), true)
		if arch_id == "pale_lantern":
			for ple in get_tree().get_nodes_in_group("enemies"):
				if ple != self and ple.get("state") != "dead":
					ple.stun(0.8)
			var mpl := get_tree().current_scene
			if mpl != null and mpl.has_method("_shock_ring"):
				mpl._shock_ring(global_position)
		if affix == "powderkeg":
			var matk: float = float(dmg)
			for pkf in get_tree().get_nodes_in_group("enemies"):
				if pkf != self and pkf.get("state") != "dead" and pkf.global_position.distance_to(global_position) < 2.5 * room_tile:
					pkf.take_hit(global_position, matk * 0.6)
			var mpk := get_tree().current_scene
			if mpk != null and mpk.has_method("_shock_ring"):
				mpk._shock_ring(global_position)
		if affix == "saltkin":
			Stats.earn_souls(2)
			var msk := get_tree().current_scene
			if msk != null and msk.has_method("_souls_l"):
				msk._souls_l()
			if msk != null and msk.has_method("_damage_number"):
				msk._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "SALTKIN +2", Color(0.4, 0.9, 0.9), true)
		if arch_id == "siren_thrall":
			var mst := get_tree().current_scene
			if mst != null and mst.has_method("_spawn_wisp_at"):
				mst._spawn_wisp_at(global_position + Vector3(0, 0.6 * room_tile, 0))
		if affix == "soulwrought":
			var msw := get_tree().current_scene
			if msw != null and msw.has_method("_spawn_wisp_at"):
				msw._spawn_wisp_at(global_position + Vector3(0, 0.6 * room_tile, 0))
		if affix == "bilged":
			var mbg := get_tree().current_scene
			if mbg != null and mbg.has_method("_spawn_health_orb"):
				mbg._spawn_health_orb(global_position)
		if affix == "gilded":
			Stats.earn_souls(1)
			var mgu := get_tree().current_scene
			if mgu != null and mgu.has_method("_damage_number"):
				mgu._damage_number(global_position + Vector3(0, 1.0, 0), "GILDED +1", Color(1.0, 0.9, 0.4), true)
			if mgu != null and mgu.has_method("_souls_l"):
				mgu._souls_l()
		if affix == "ballasted":
			Stats.earn_souls(2)
			var mmb := get_tree().current_scene
			if mmb != null and mmb.has_method("_souls_l"):
				mmb._souls_l()
			if mmb != null and mmb.has_method("_damage_number"):
				mmb._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "BALLAST +2", Color(0.5, 0.85, 0.6), true)
		if affix == "trenchborn":
			Stats.earn_souls(2)
			var mmt := get_tree().current_scene
			if mmt != null and mmt.has_method("_souls_l"):
				mmt._souls_l()
			if mmt != null and mmt.has_method("_damage_number"):
				mmt._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "TRENCH +2", Color(0.45, 0.75, 0.95), true)
		if affix == "flotsam":
			Stats.earn_souls(1)
			var mmf := get_tree().current_scene
			if mmf != null and mmf.has_method("_souls_l"):
				mmf._souls_l()
			if mmf != null and mmf.has_method("_damage_number"):
				mmf._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "FLOTSAM +1", Color(0.5, 0.85, 0.6), true)
		if affix == "clamworn":
			var mm5 := get_tree().current_scene
			if mm5 != null and mm5.get("room") != null:
				var TRAPR = load("res://trap.gd")
				var ctr = TRAPR.new()
				mm5.get("room").add_child(ctr)
				ctr.global_position = global_position
				var ctile: float = float(mm5.get("info").get("tile", 1.6) if mm5.get("info") is Dictionary else 1.6)
				ctr.setup(ctile, 0.0, 6)
		if affix == "wispsborn":
			var mm3 := get_tree().current_scene
			if mm3 != null and mm3.has_method("_spawn_wisp_at"):
				for wi in range(2):
					var woff := Vector3((wi - 0.5) * 0.6 * room_tile, 0, 0.3 * room_tile)
					mm3._spawn_wisp_at(global_position + woff)
		anim_lock = M.play_action(ap, ["death"], 1.0)
		died.emit(self)
	else:
		anim_lock = max(anim_lock, M.play_action(ap, ["hit_"], 1.4) * 0.6)
	_upd_hpbar()


func _chant() -> void:
	var m := get_tree().current_scene
	var healed := 0
	for f in get_tree().get_nodes_in_group("enemies"):
		if f == self or f.get("state") == "dead":
			continue
		if f.global_position.distance_to(global_position) < 2.0 * room_tile and float(f.hp) < float(f.hp_max):
			f.hp = minf(f.hp_max, f.hp + 1.0)
			healed += 1
			if m != null and m.has_method("_damage_number"):
				m._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "+1", Color(0.4, 1.0, 0.55), false)
	if healed > 0:
		Sfx.play("shrine")
		if m != null and m.has_method("_shock_ring"):
			m._shock_ring(global_position)
		if m != null and m.has_method("_damage_number"):
			m._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "WAILS...", Color(0.5, 1.0, 0.6), true)
