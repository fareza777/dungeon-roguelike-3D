class_name QuestsDb
# Rantai quest per lantai — urutan jelas, satu aktif dalam satu waktu.
# kind: "moved", "kill", "clear_floor", "reach_room", "boss_kill",
#       "open_chest", "descend", "custom"
# need: jumlah untuk kind berhitung (kill/reach_room); 0/1 utk toggle.

static func is_boss_floor(floor_num: int) -> bool:
	return floor_num % 5 == 0


static func for_floor(floor_num: int, room_count: int, n_elites: int = 0) -> Array:
	var steps: Array = []
	if floor_num == 1:
		steps.append({"title": "Awaken", "desc": "Move — tilt the left stick", "kind": "moved", "need": 1})
		steps.append({"title": "Sweep", "desc": "Clear %d rooms of skeletons" % room_count, "kind": "clear_floor", "need": room_count})
		steps.append({"title": "First Spoils", "desc": "Open the treasure chest at the floor's end", "kind": "open_chest", "need": 1})
		steps.append({"title": "Descend", "desc": "Tap the screen to descend to Floor 2", "kind": "descend", "need": 1})
	elif is_boss_floor(floor_num):
		steps.append({"title": "Throne Room", "desc": "Fight through to the last room of this floor", "kind": "reach_room", "need": room_count - 1})
		steps.append({"title": "Bone King", "desc": "Defeat the Throne's ruler", "kind": "boss_kill", "need": 1})
		steps.append({"title": "The Crown", "desc": "Claim the King's spoils chest", "kind": "open_chest", "need": 1})
		steps.append({"title": "Descend", "desc": "Tap to descend deeper", "kind": "descend", "need": 1})
	else:
		if floor_num >= 3 and n_elites > 0:
			var n_hunt := mini(n_elites, 2)
			steps.append({"title": "Elite Hunter", "desc": "Slay %d crimson elite%s" % [n_hunt, "s" if n_hunt > 1 else ""], "kind": "elite_kill", "need": n_hunt})
		if floor_num >= 4:
			if floor_num % 2 == 0:
				steps.append({"title": "Gem Rush", "desc": "Absorb 6 soul gems", "kind": "gem", "need": 6})
			else:
				steps.append({"title": "Battle Frenzy", "desc": "Reach a x8 kill combo", "kind": "combo", "need": 1})
				if Stats.floor_num >= 10:
					steps.append({"title": "Crescendo", "desc": "Reach a x40 kill combo", "kind": "combo40", "need": 1})
		if floor_num >= 6:
			steps.append({"title": "Skillful Hands", "desc": "Unleash 2 skills", "kind": "skill", "need": 2})
		if floor_num >= 8 and floor_num % 4 == 3:
			steps.append({"title": "Grave Robbing", "desc": "Smash 2 bone urns", "kind": "urn", "need": 2})
		if floor_num >= 13 and floor_num % 4 == 1:
			steps.append({"title": "Porcelain Storm", "desc": "Smash 4 bone urns", "kind": "urn", "need": 4})
		if floor_num >= 10 and floor_num % 4 == 2:
			steps.append({"title": "Gaoler Breaker", "desc": "Slay 2 faceless Gaolers", "kind": "gaoler_kill", "need": 2})
		if floor_num >= 12 and floor_num % 4 == 0:
			steps.append({"title": "Dead Letters", "desc": "Read the lore stone on this floor", "kind": "page", "need": 1})
		if floor_num >= 11 and floor_num % 4 == 3:
			steps.append({"title": "Frenzied", "desc": "Trigger a RAMPAGE (3 kills in 2.5s)", "kind": "rampage", "need": 1})
		if floor_num >= 5 and floor_num % 4 == 1:
			steps.append({"title": "Siege Breaker", "desc": "Topple 2 Bone Sentinels", "kind": "sentinel_kill", "need": 2})
		if floor_num >= 6 and floor_num % 4 == 2:
			steps.append({"title": "Hammer of Dawn", "desc": "Land a HEAVY attack", "kind": "heavy", "need": 1})
		if floor_num >= 4 and floor_num % 5 == 4:
			steps.append({"title": "Soul Bargainer", "desc": "Strike a deal with Mahzan", "kind": "mahzan", "need": 1})
		if floor_num >= 6 and floor_num % 5 == 1:
			steps.append({"title": "Hex Plunderer", "desc": "Open a CURSED CHEST", "kind": "cursed_chest", "need": 1})
		if floor_num >= 7 and floor_num % 4 == 3:
			steps.append({"title": "Phantom Hunt", "desc": "Slay 2 Shades", "kind": "shade_kill", "need": 2})
		if floor_num >= 7 and floor_num % 4 == 0:
			steps.append({"title": "Curse Silencer", "desc": "Slay 2 Hex Priests", "kind": "hexer_kill", "need": 2})
		if floor_num >= 7 and floor_num % 3 == 1:
			steps.append({"title": "Ghost Dancer", "desc": "Dash through 2 attacks at the last instant", "kind": "pdodge", "need": 2})
		if floor_num >= 17 and floor_num % 4 == 2:
			steps.append({"title": "Tempest Herald", "desc": "Unleash a SOUL STORM", "kind": "storm", "need": 1})
		if floor_num >= 8 and floor_num % 4 == 1:
			steps.append({"title": "Thorn Proof", "desc": "Slay 2 Spiked Cadavers", "kind": "spiker_kill", "need": 2})
		if floor_num >= 5 and floor_num % 4 == 2:
			steps.append({"title": "Trap Dancer", "desc": "Defuse 3 traps while they sleep", "kind": "trap_disarm", "need": 3})
		if floor_num >= 8 and floor_num % 5 == 3:
			steps.append({"title": "Hoard Diver", "desc": "Crack a GILDED chest", "kind": "gilded_chest", "need": 1})
		if floor_num >= 7 and floor_num % 5 == 4:
			steps.append({"title": "Dark Watch", "desc": "Slay 2 Dwellers after they reveal", "kind": "lurker_kill", "need": 2})
		if floor_num >= 6 and floor_num % 4 == 0:
			steps.append({"title": "Ghost Hunter", "desc": "Catch 2 wandering wisps", "kind": "wisp", "need": 2})
		if floor_num >= 7 and floor_num % 5 == 2:
			steps.append({"title": "Purge", "desc": "Smash the Dread Obelisk", "kind": "obelisk", "need": 1})
		if floor_num >= 22 and floor_num % 4 == 1:
			steps.append({"title": "Toll Keeper", "desc": "Unleash the REAPER'S TOLL", "kind": "rites", "need": 1})
	if Stats.floor_num >= 22 and Stats.floor_num % 5 == 3:
		steps.append({"title": "Earthshaker", "desc": "Slam the floor — strike & stun foes with SEISMIC", "kind": "seismic", "need": 1})
	if Stats.floor_num >= 8 and Stats.floor_num % 6 == 0:
		steps.append({"title": "Grief Silencer", "desc": "Silence 2 Wailing Maidens", "kind": "maiden_kill", "need": 2})
	if Stats.floor_num >= 6 and Stats.floor_num % 7 == 3:
		steps.append({"title": "Grave Denier", "desc": "Shatter 2 Revenant tombstones", "kind": "tomb", "need": 2})
	if Stats.floor_num >= 25 and Stats.floor_num % 5 == 0:
		steps.append({"title": "Crown's Edge", "desc": "Unleash KINGSFALL on the throne floor", "kind": "kingsfall", "need": 1})
	if Stats.floor_num >= 6 and Stats.floor_num % 5 == 3:
		steps.append({"title": "Grave Etiquette", "desc": "Hold a prayer over a blood stain (0/1)", "kind": "pray", "need": 1})
	if Stats.floor_num >= 8 and Stats.floor_num % 6 == 4:
		steps.append({"title": "Firefly Hunt", "desc": "Catch three wandering wisps (0/3)", "kind": "wisp", "need": 3})
	if Stats.floor_num >= 13 and Stats.floor_num % 7 == 1:
		steps.append({"title": "Commuter of the Dead", "desc": "Let the Ferryman carry you (0/1)", "kind": "ferry", "need": 1})
	if Stats.floor_num >= 14 and Stats.floor_num % 8 == 6:
		steps.append({"title": "Silence the Choir", "desc": "Slay a Grave Orator (0/1)", "kind": "orator_kill", "need": 1})
	if Stats.floor_num >= 10 and Stats.floor_num % 7 == 3:
		steps.append({"title": "Ghost Hunter", "desc": "Slay an UMBRAL elite (0/1)", "kind": "umbral_kill", "need": 1})
	if Stats.floor_num >= 11 and Stats.floor_num % 6 == 5:
		steps.append({"title": "Pale Fencer", "desc": "Answer two Pale Duelists in kind (0/2)", "kind": "duelist_kill", "need": 2})
	if Stats.floor_num >= 10 and Stats.floor_num % 8 == 4:
		steps.append({"title": "Grave Robber", "desc": "Unlock a Soul Vault", "kind": "vault", "need": 1})
	if Stats.floor_num >= 20 and Stats.floor_num % 6 == 2:
		steps.append({"title": "Deathwalk", "desc": "Blink through the dark twice (0/2)", "kind": "gravestep", "need": 2})
	if Stats.floor_num >= 26 and Stats.floor_num % 4 == 2:
		steps.append({"title": "Spear of Dawn", "desc": "Impale foes with SOUL LANCE", "kind": "lance", "need": 1})
	if Stats.floor_num >= 15 and Stats.floor_num % 9 == 4:
		steps.append({"title": "Wisp Keeper", "desc": "Catch six wandering wisps (0/6)", "kind": "wisp", "need": 6})
	if Stats.floor_num >= 14 and Stats.floor_num % 9 == 5:
		steps.append({"title": "Lucky Soul", "desc": "Gamble at the Gambler's Well (0/1)", "kind": "well", "need": 1})
	if Stats.floor_num >= 9 and Stats.floor_num % 5 == 0:
		steps.append({"title": "Lantern-Blessed", "desc": "Soak 30% HP from a Soul Lantern (0/1)", "kind": "lantern", "need": 1})
	if Stats.floor_num >= 8 and Stats.floor_num % 6 == 1:
		steps.append({"title": "Mapmaker", "desc": "Clear four rooms this floor (0/4)", "kind": "room_clear", "need": 4})
	if Stats.floor_num >= 12 and Stats.floor_num % 7 == 4:
		steps.append({"title": "Deep Pockets", "desc": "Offer the Well three tosses in one visit (0/1)", "kind": "deep_pockets", "need": 1})
	if Stats.floor_num >= 14 and Stats.floor_num % 8 == 6:
		steps.append({"title": "Dethroned", "desc": "Cut down a Crowned paladin (0/2)", "kind": "crowned_kill", "need": 2})
	if Stats.floor_num >= 16 and Stats.floor_num % 12 == 8:
		steps.append({"title": "Thirsting", "desc": "Drink from a Soul Fountain (0/1)", "kind": "fountain", "need": 1})
	if Stats.floor_num >= 12 and Stats.floor_num % 7 == 3:
		steps.append({"title": "Pack Breaker", "desc": "Slay five hounds under the Wolfsbane (0/5)", "kind": "pack_hound", "need": 5})
	if Stats.floor_num >= 15 and Stats.floor_num % 9 == 2:
		steps.append({"title": "Tax Revolt", "desc": "Refuse two Tithings (0/2)", "kind": "tither_kill", "need": 2})
	if Stats.floor_num >= 7 and Stats.floor_num % 6 == 3:
		steps.append({"title": "Wisp Hunt", "desc": "Catch three wandering wisps (0/3)", "kind": "wisp", "need": 3})
	if Stats.floor_num >= 20 and Stats.floor_num % 9 == 4:
		steps.append({"title": "Tide Caller", "desc": "Call the drowned tide once (0/1)", "kind": "tidecall", "need": 1})
	if Stats.floor_num >= 18 and Stats.floor_num % 11 == 7:
		steps.append({"title": "Steel Scrounger", "desc": "Take a blade from a Scavenger's Cache (0/1)", "kind": "cache", "need": 1})
	if Stats.floor_num >= 7 and Stats.floor_num % 7 == 0:
		steps.append({"title": "Bounty Hunter", "desc": "Claim a Bounty Stone contract", "kind": "bounty", "need": 1})
	if Stats.floor_num >= 11 and Stats.floor_num <= 12:
		steps.append({"title": "Vault Thief", "desc": "Claim the Reliquary's gilded hoard (0/1)", "kind": "gilded_chest", "need": 1})
	if Stats.floor_num == 12:
		steps.append({"title": "Sea Prayer", "desc": "Answer a Drowned Altar's offer (0/1)", "kind": "drowned", "need": 1})
		steps.append({"title": "Emissary's Fall", "desc": "Cut down the vault's sworn guard (0/1)", "kind": "emissary_kill", "need": 1})
		steps.append({"title": "Pearl Diver", "desc": "Pry open a Snap Clam while it sleeps (0/1)", "kind": "clam", "need": 1})
		steps.append({"title": "Glasswalker", "desc": "Survive a Glass Sea floor (0/1)", "kind": "glasswalk", "need": 1})
		steps.append({"title": "Keel Breaker", "desc": "Slay 2 soul-snatching Keelhounds (0/2)", "kind": "keelhound_kill", "need": 2})
		steps.append({"title": "Poolside", "desc": "Mend your wounds in a tidepool (0/1)", "kind": "pool", "need": 1})
		steps.append({"title": "Snap Shut", "desc": "Clamp 3 foes with a single Snapjaw (0/1)", "kind": "snapjaw3", "need": 1})
		steps.append({"title": "Lamplighter", "desc": "Bask in a lantern's glow to mend (0/1)", "kind": "lantern", "need": 1})
		steps.append({"title": "Dread Toll", "desc": "Survive a Dread Tide floor (0/1)", "kind": "dreadtide", "need": 1})
		steps.append({"title": "Shellcracker", "desc": "Crack 2 Barnacle Maws (0/2)", "kind": "maw_kill", "need": 2})
		steps.append({"title": "Seaworthy Deal", "desc": "Strike a bargain at a Keelstone (0/1)", "kind": "keelstone", "need": 1})
		steps.append({"title": "Ringing Haul", "desc": "Crack a golden Bell Urn (0/1)", "kind": "bellurn", "need": 1})
		steps.append({"title": "Tidewriter", "desc": "Read a lore stone in the Reliquary (0/1)", "kind": "tidepage", "need": 1})
		steps.append({"title": "Starved Pilgrim", "desc": "Survive a Starved Deep floor (0/1)", "kind": "starved", "need": 1})
		steps.append({"title": "Shark Week", "desc": "Cull 3 Keelhounds on one floor (0/3)", "kind": "keelh3", "need": 1})
	if Stats.floor_num == 11:
		steps.append({"title": "Soul Fisher", "desc": "Net three drifting wisps (0/3)", "kind": "wisp", "need": 3})
	if Stats.floor_num >= 13 and Stats.floor_num % 8 == 5:
		steps.append({"title": "Ten-Soul Net", "desc": "Bless yourself with the Lucky Net (0/1)", "kind": "lucky_net", "need": 1})
	if Stats.floor_num >= 9 and Stats.floor_num % 6 == 3:
		steps.append({"title": "Shieldbreaker", "desc": "Slay Shieldbearers (0/3)", "kind": "shield_kill", "need": 3})
	if Stats.floor_num >= 5 and Stats.floor_num % 5 == 1:
		steps.append({"title": "Forge-Fed", "desc": "Forge your blade at a Soul Forge", "kind": "forge", "need": 1})
		steps.append({"title": "Floor Sweep", "desc": "Clear %d rooms of skeletons" % room_count, "kind": "clear_floor", "need": room_count})
		steps.append({"title": "Treasure Chest", "desc": "Find & open the chest in the final room", "kind": "open_chest", "need": 1})
		steps.append({"title": "Descend", "desc": "Tap to descend to the next floor", "kind": "descend", "need": 1})
	for i in range(steps.size()):
		steps[i]["num"] = i + 1
		steps[i]["total"] = steps.size()
	return steps
