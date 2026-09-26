class_name RoomGen
# Generator LANTAI ber-seed: 3-5 ruangan berbaris ke utara, pintu selaras,
# prop dengan tabrakan fisik (StaticBody3D + BoxShape dari AABB aset).
# build_floor() mengembalikan semua yang main butuhkan.

const DUNGEON := "res://assets/dungeon/"


static func _scene(p: String) -> PackedScene:
	return load(DUNGEON + p) as PackedScene


static func _meshes(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_meshes(c))
	return out


static func _aabb_of(node: Node3D) -> AABB:
	var a := AABB()
	var first := true
	for mi in _meshes(node):
		mi.force_update_transform()
		var ta: AABB = mi.global_transform * mi.get_aabb()
		if first:
			a = ta
			first = false
		else:
			a = a.merge(ta)
	return a


static func _place(parent: Node3D, ps: PackedScene, target: Vector3, rot := 0.0) -> Node3D:
	var inst: Node3D = ps.instantiate()
	parent.add_child(inst)
	inst.rotation_degrees.y = rot
	var a := _aabb_of(inst)
	var c := a.get_center()
	inst.global_position += Vector3(target.x - c.x, target.y - a.position.y, target.z - c.z)
	return inst


static func _solid(parent: Node3D, ab: AABB) -> void:
	if ab.size.x <= 0.01 or ab.size.z <= 0.01:
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = ab.size
	cs.shape = box
	body.add_child(cs)
	body.global_position = ab.get_center()


# tembok berpintu: dua kotak mengapit celah tengah
static func _solid_door(parent: Node3D, ab: AABB, gap_half: float) -> void:
	var c := ab.get_center()
	var lw := (c.x - gap_half) - ab.position.x
	if lw > 0.05:
		_solid(parent, AABB(ab.position, Vector3(lw, ab.size.y, ab.size.z)))
	var rx := c.x + gap_half
	var rw := ab.end.x - rx
	if rw > 0.05:
		_solid(parent, AABB(Vector3(rx, ab.position.y, ab.position.z), Vector3(rw, ab.size.y, ab.size.z)))


static func build_floor(parent: Node3D, seed_val: int, floor_num: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var floor_ps := _scene("floor_tile_large.gltf.glb")
	var probe := _place(parent, floor_ps, Vector3(0, -500, 0))
	var s: float = _aabb_of(probe).size.x
	probe.queue_free()

	var wall_ps := _scene("wall.gltf.glb")
	var door_ps := _scene("wall_doorway.glb")
	var room_count: int = clampi(3 + (floor_num - 1) / 2, 3, 5)

	var wall_probe := _place(parent, wall_ps, Vector3(0, -500, 0))
	var wall_h: float = _aabb_of(wall_probe).size.y
	wall_probe.queue_free()

	var floors: Array = []
	var walls: Array = []
	var props: Array = []
	var torches: Array = []
	var enemy_spawns: Array = []
	var doors: Array = []
	var ranges: Array = []
	var chest = null

	var z_cursor := 0.0
	var prev_door_x := 0.0
	var min_x := 1e9
	var max_x := -1e9
	var min_z := 1e9
	var player_pos := Vector3.ZERO

	for ri in range(room_count):
		var w := rng.randi_range(4, 6)
		var h := rng.randi_range(5, 7)
		var door_i := rng.randi_range(1, w - 2)
		var pcol := int(floor((w - 1) * 0.5))
		# ruangan baru: kolom tengahnya selaras dengan pintu ruangan sebelumnya
		var xoff := float(-pcol) * s if ri == 0 else prev_door_x - pcol * s
		var zoff := z_cursor

		for i in range(w):
			for j in range(h):
				floors.append(_place(parent, floor_ps, Vector3(xoff + i * s, 0.0, zoff - j * s)))

		# tembok utara dengan pintu + tabrakan
		for i in range(w):
			var is_door := i == door_i
			var ps: PackedScene = door_ps if is_door else wall_ps
			var wn := _place(parent, ps, Vector3(xoff + i * s, 0.0, zoff - (h - 0.5) * s))
			walls.append(wn)
			var ab := _aabb_of(wn)
			if is_door and ri < room_count - 1:
				_solid_door(parent, ab, 0.3 * s)
				doors.append({"pos": Vector3(xoff + door_i * s, 0.0, zoff - (h - 0.5) * s), "room": ri})
			else:
				_solid(parent, ab)
		ranges.append({"z0": zoff + 0.5 * s, "z1": zoff - (h - 0.5) * s, "x0": xoff, "x1": xoff + (w - 1) * s})
		# tembok barat & timur + tabrakan
		for j in range(h):
			var ww := _place(parent, wall_ps, Vector3(xoff - s, 0.0, zoff - j * s), 90.0)
			walls.append(ww)
			_solid(parent, _aabb_of(ww))
			var we := _place(parent, wall_ps, Vector3(xoff + w * s, 0.0, zoff - j * s), -90.0)
			walls.append(we)
			_solid(parent, _aabb_of(we))

		# sel terlarang: jalur pintu + jalur masuk/spawn player
		var occupied := {}
		occupied["%d,%d" % [door_i, h - 1]] = true
		occupied["%d,%d" % [door_i, h - 2]] = true
		for dc in [pcol, pcol + 1]:
			for dj in range(2):
				occupied["%d,%d" % [dc, dj]] = true

		# spawn musuh di paruh atas ruangan (ruangan pertama lebih ramah)
		var ecount: int = clampi(1 + ri + int((floor_num - 1) * 0.5), 1, 4)
		var spawn_cells: Array = []
		var tries := 0
		while spawn_cells.size() < ecount and tries < 80:
			tries += 1
			var ci := rng.randi_range(1, w - 2)
			var cj := rng.randi_range(h - 3, h - 1)
			var key := "%d,%d" % [ci, cj]
			if occupied.has(key):
				continue
			occupied[key] = true
			spawn_cells.append(Vector2i(ci, cj))
			enemy_spawns.append({"pos": Vector3(xoff + ci * s, 0.0, zoff - cj * s), "room": ri})

		# jalur pandang kamera: kolom tengah bersih + kolom musuh bersih ke bawah
		for c in [pcol, pcol + 1]:
			for lj in range(h):
				occupied["%d,%d" % [c, lj]] = true
		for scell in spawn_cells:
			for lj in range(1, scell.y):
				occupied["%d,%d" % [scell.x, lj]] = true

		# prop + tabrakan
		var prop_pool := ["barrel_large.gltf.glb", "crates_stacked.gltf.glb", "rubble_half.gltf.glb", "pillar_decorated.gltf.glb"]
		var prop_count := rng.randi_range(2, 4)
		var tries2 := 0
		while prop_count > 0 and tries2 < 60:
			tries2 += 1
			var ci := rng.randi_range(0, w - 1)
			var cj := rng.randi_range(1, h - 2)
			var key := "%d,%d" % [ci, cj]
			if occupied.has(key):
				continue
			occupied[key] = true
			var pr := _place(parent, _scene(prop_pool[rng.randi_range(0, prop_pool.size() - 1)]), Vector3(xoff + ci * s, 0.0, zoff - cj * s), rng.randf_range(0.0, 360.0))
			props.append(pr)
			_solid(parent, _aabb_of(pr))
			prop_count -= 1

		# chest hanya di ruangan terakhir
		if ri == room_count - 1:
			chest = _place(parent, _scene("chest_gold.glb"), Vector3(xoff + door_i * s, 0.0, zoff - (h - 1.7) * s), 180.0)
			_solid(parent, _aabb_of(chest))

		var torch_cols: Array = []
		if door_i > 0:
			torch_cols.append(door_i - 1)
		if door_i < w - 1:
			torch_cols.append(door_i + 1)
		for tc in torch_cols:
			torches.append(_place(parent, _scene("torch_mounted.gltf.glb"), Vector3(xoff + tc * s, 1.5, zoff - (h - 0.68) * s)))

		if ri == 0:
			player_pos = Vector3(0.0, 0.0, zoff)

		prev_door_x = xoff + door_i * s
		min_x = minf(min_x, xoff - 0.25 * s)
		max_x = maxf(max_x, xoff + (w - 0.75) * s)
		min_z = zoff - (h - 1.35) * s
		z_cursor = zoff - h * s

	return {
		"tile": s, "seed": seed_val, "room_count": room_count,
		"player_pos": player_pos,
		"enemy_spawns": enemy_spawns,
		"doors": doors, "ranges": ranges, "wall_h": wall_h,
		"min_x": min_x, "max_x": max_x, "min_z": min_z, "max_z": 0.2 * s,
		"floors": floors, "walls": walls, "props": props, "torches": torches, "chest": chest,
	}
