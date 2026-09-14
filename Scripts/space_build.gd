extends SceneTree

const KIT := "res://Assets/SpaceKit/"
var scene: Node3D

func _initialize():
	call_deferred("build")

func material(color: Color, glow := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = 0.45
	result.roughness = 0.55
	if glow:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 2.0
	return result

func attach(parent: Node, child: Node, title: String) -> Node:
	child.name = title
	parent.add_child(child)
	child.owner = scene
	return child

func own_all(node: Node):
	node.scene_file_path = ""
	node.owner = scene
	for child in node.get_children():
		own_all(child)

func bounds(node: Node3D) -> AABB:
	var result := AABB()
	var started := false
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = node.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		result = result.merge(box) if started else box
		started = true
	return result

func asset(parent: Node3D, path: String, width: float, at: Vector3) -> Node3D:
	var model: Node3D = load(KIT + path).instantiate()
	parent.add_child(model)
	var box := bounds(model)
	var factor := width / maxf(box.size.x, box.size.z)
	model.scale = Vector3.ONE * factor
	model.position = at - Vector3(box.get_center().x, box.position.y, box.get_center().z) * factor
	model.name = path.get_file().get_basename()
	own_all(model)
	return model

func box_mesh(parent: Node3D, at: Vector3, size: Vector3, mat: Material, title: String):
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = at
	attach(parent, mesh, title)

func label3(parent: Node3D, text: String, at: Vector3, size := 70):
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.outline_size = 5
	label.modulate = Color("#8ceeff")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	attach(parent, label, "MissionSign")

func build():
	scene = load("res://Scenes/original_demo.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody3D = scene.get_node("Player")
	var old_visual := player.get_node("gobot")
	player.remove_child(old_visual)
	old_visual.free()
	var visual := Node3D.new()
	visual.name = "gobot"
	visual.rotation.y = PI
	player.add_child(visual)
	visual.owner = scene
	visual.set_script(load("res://Scripts/astronaut_visual.gd"))
	var model_root := Node3D.new()
	attach(visual, model_root, "Model")
	var astronaut: Node3D = load("res://Assets/Astronaut/AstronautRigged.fbx").instantiate()
	model_root.add_child(astronaut)
	astronaut.scale = Vector3.ONE * 0.65
	astronaut.position.y = 0.015
	own_all(astronaut)
	for old_animation in astronaut.find_children("*", "AnimationPlayer", true, false):
		old_animation.get_parent().remove_child(old_animation)
		old_animation.free()
	for mesh in astronaut.find_children("*", "MeshInstance3D", true, false):
		mesh.custom_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
		for i in mesh.mesh.get_surface_count():
			var source: Material = mesh.mesh.surface_get_material(i)
			if source is StandardMaterial3D:
				var mat: StandardMaterial3D = source.duplicate()
				if source.resource_name == "transparent_mask":
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					mat.albedo_color = Color("#dca84b")
					mat.metallic = 0.8
					mat.roughness = 0.2
				mesh.set_surface_override_material(i, mat)
	var animation := AnimationPlayer.new()
	attach(visual, animation, "AnimationPlayer")
	var library := AnimationLibrary.new()
	for animation_name in ["Idle", "Run", "Jump", "Flip"]:
		var clip := Animation.new()
		clip.length = 0.7 if animation_name == "Flip" else 1.0
		clip.loop_mode = Animation.LOOP_NONE if animation_name in ["Jump", "Flip"] else Animation.LOOP_LINEAR
		if animation_name == "Flip":
			var track := clip.add_track(Animation.TYPE_VALUE)
			clip.track_set_path(track, NodePath("Model:rotation:x"))
			clip.track_insert_key(track, 0.0, 0.0)
			clip.track_insert_key(track, 0.7, TAU)
		else:
			var track := clip.add_track(Animation.TYPE_VALUE)
			clip.track_set_path(track, NodePath("Model:rotation:x"))
			clip.track_insert_key(track, 0.0, 0.0)
		library.add_animation(animation_name, clip)
	animation.add_animation_library("", library)
	var trail: CPUParticles3D = player.get_node("ParticleTrail")
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.045
	particle_mesh.height = 0.09
	particle_mesh.radial_segments = 6
	particle_mesh.rings = 3
	trail.mesh = particle_mesh
	trail.material_override = material(Color("#56dfff"), true)
	trail.scale_amount_min = 0.35
	trail.scale_amount_max = 0.9
	trail.lifetime = 0.35

	var deck := material(Color("#22354c"))
	var cyan := material(Color("#3ce6ff"), true)
	var amber := material(Color("#ffb44b"), true)
	var index := 0
	for platform in scene.get_node("Platforms").get_children():
		var is_large: bool = "Red" in platform.name
		var model: Node3D = load(KIT + "Base Large/Base_Large.fbx").instantiate()
		platform.add_child(model)
		var b := bounds(model)
		var bottom := -3.31 if is_large else -1.0
		var dimensions := Vector3(2.0 / b.size.x, (1.0 - bottom) / b.size.y, 2.0 / b.size.z)
		model.scale = dimensions
		model.position = Vector3(-b.get_center().x * dimensions.x, bottom - b.position.y * dimensions.y, -b.get_center().z * dimensions.z)
		model.name = "SpaceBase"
		own_all(model)
		platform.mesh = null
		box_mesh(platform, Vector3(0, 0.97, 0), Vector3(1.56, 0.05, 1.56), deck, "LandingDeck")
		for side in [-1.0, 1.0]:
			box_mesh(platform, Vector3(side * 0.80, 1.01, 0), Vector3(0.025, 0.025, 1.60), amber if is_large else cyan, "EdgeLight")
			box_mesh(platform, Vector3(0, 1.01, side * 0.80), Vector3(1.60, 0.025, 0.025), amber if is_large else cyan, "EdgeLight")
		index += 1

	for coin in scene.get_node("Coins").get_children():
		var pickup_shape := SphereShape3D.new()
		pickup_shape.radius = 0.5
		coin.get_node("CollisionShape3D").shape = pickup_shape
		for child in coin.get_children():
			if child is VisualInstance3D or child.name == "coin":
				coin.remove_child(child)
				child.free()
		asset(coin, "Pickup Thunder/Pickup_Thunder.fbx", 0.7, Vector3(0, -0.25, 0))
		var light := OmniLight3D.new()
		light.light_color = Color("#6eeaff")
		light.light_energy = 1.4
		light.omni_range = 2.0
		attach(coin, light, "EnergyGlow")

	var env: Environment = scene.get_node("Environment/WorldEnvironment").environment.duplicate()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#030816")
	env.ambient_light_color = Color("#a4bddd")
	env.ambient_light_energy = 0.8
	env.tonemap_exposure = 1.0
	env.fog_enabled = false
	env.ssao_enabled = false
	env.ssr_enabled = false
	env.ssil_enabled = false
	scene.get_node("Environment/WorldEnvironment").environment = env
	var sunlight: DirectionalLight3D = scene.get_node("Environment/DirectionalLight3D")
	sunlight.light_color = Color("#d8eaff")
	sunlight.light_energy = 1.6

	for name in ["Sprite3D", "Features", "Credits"]:
		var old := scene.get_node("Extras/" + name)
		old.get_parent().remove_child(old)
		old.free()
	var scenery := Node3D.new()
	attach(scene, scenery, "SpaceScenery")
	asset(scenery, "Planet-B7xd3SZq0z/Planet_1.fbx", 95.0, Vector3(-110, -35, -210))
	asset(scenery, "Planet/Planet_6.fbx", 40.0, Vector3(95, 20, -180))
	asset(scenery, "Spaceship/Spaceship_RaeTheRedPanda.fbx", 3.8, Vector3(18.0, 9.56, 3.1))
	label3(scenery, "ORBITAL OUTPOST", Vector3(0, 10, -17), 100)
	label3(scenery, "01 / LAUNCH PAD", Vector3(-2.3, 4.2, -2.1), 22)
	label3(scenery, "EXTRACTION", Vector3(18, 12.3, 4.6), 50)
	for at in [Vector3(-17, -3, -20), Vector3(35, 1, -35), Vector3(8, -8, -55)]:
		asset(scenery, "Base Large/Base_Large.fbx", 13.0, at)
		asset(scenery, "House Pod/HousePod.fbx", 5.0, at + Vector3(0, 7.58, 0))
		asset(scenery, "Solar Panel Ground/SolarPanel_Ground.fbx", 3.3, at + Vector3(-4, 7.58, 0))
		asset(scenery, "Roof Radar/Roof_Radar.fbx", 2.4, at + Vector3(3.0, 7.58, -2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260914
	for i in 22:
		var at := Vector3(rng.randf_range(-85, 85), rng.randf_range(-40, -15), rng.randf_range(-95, 35))
		var rock := asset(scenery, "Rock Large/Rock_Large_2.fbx", rng.randf_range(2.0, 7.0), at)
		rock.rotation = Vector3(rng.randf(), rng.randf(), rng.randf()) * TAU
	var stars := MultiMeshInstance3D.new()
	stars.set_script(load("res://Scripts/starfield.gd"))
	attach(scenery, stars, "Stars")

	var old_ui := scene.get_node("UserInterface/GameUI")
	old_ui.get_parent().remove_child(old_ui)
	old_ui.free()
	var hud := Control.new()
	attach(scene.get_node("UserInterface"), hud, "GameUI")
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_script(load("res://Scripts/space_hud.gd"))
	var panel := Panel.new()
	attach(hud, panel, "Panel")
	panel.position = Vector2(24, 24)
	panel.size = Vector2(470, 125)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.1, 0.92)
	style.border_color = Color("#3de6ff")
	style.border_width_left = 3
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	for data in [["Title", "ORBITAL / ASTRONAUT MISSION", 16, 14, 16], ["Counter", "ENERGY CELLS   00 / 05", 16, 41, 26], ["Status", "JUMP BETWEEN OUTPOSTS / COLLECT ALL CELLS", 16, 88, 13]]:
		var label := Label.new()
		attach(panel, label, data[0])
		label.text = data[1]
		label.position = Vector2(data[2], data[3])
		label.add_theme_font_size_override("font_size", data[4])
		label.add_theme_color_override("font_color", Color("#c4f6ff"))
	var controls := Label.new()
	attach(hud, controls, "Controls")
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(24, -44)
	controls.text = "WASD  MOVE     SPACE  JUMP / DOUBLE JUMP     MOUSE  LOOK     ESC  CURSOR     R  RESTART"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("#a5c7dc"))
	for child in scene.get_children():
		own_all(child)
	remove_text(scene)
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	assert(result == OK)
	assert(ResourceSaver.save(packed, "res://Scenes/demo_scene.tscn") == OK)
	print("SPACE BUILD OK: supplied astronaut, seven bases, five energy cells, outposts, planets and HUD.")
	quit()

func remove_text(parent: Node):
	for child in parent.get_children():
		if child is Label or child is Label3D or child is RichTextLabel or (child is Panel and child.get_parent().name == "GameUI"):
			parent.remove_child(child)
			child.free()
		else:
			remove_text(child)