extends SceneTree
const KIT := "res://Assets/SpaceKit/"
var scene: Node3D
var platforms: Array[Node3D] = []
var positions := [
	Vector3(0,3,0), Vector3(0,3.5,-7), Vector3(0,4,-13.4),
	Vector3(5.8,4.4,-17), Vector3(11.3,4.8,-20.5), Vector3(16.5,5.1,-24),
	Vector3(16.5,5.5,-31), Vector3(11,5.9,-35), Vector3(5.6,6.3,-38.7),
	Vector3(0.2,6.7,-42), Vector3(0.2,7.1,-48.3), Vector3(0.2,7.5,-55)]
var widths := [8.0,4.6,4.6,4.2,4.2,6.0,4.0,4.2,4.0,5.0,4.5,8.0]

func _initialize():
	call_deferred("build")
func own(node: Node):
	if scene.is_ancestor_of(node):
		node.owner = scene
	node.scene_file_path = ""
	for child in node.get_children():
		own(child)
func add(parent: Node, node: Node, title: String):
	node.name = title
	parent.add_child(node)
	if scene.is_ancestor_of(node):
		node.owner = scene
func mat(color: Color, glow := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = 0.45
	result.roughness = 0.55
	if glow:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 1.2
	return result
func mesh_box(parent: Node3D, title: String, size: Vector3, at: Vector3, material: Material):
	var node := MeshInstance3D.new()
	node.position = at
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	add(parent,node,title)
func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in node.find_children("*","MeshInstance3D",true,false):
		var b: AABB = node.global_transform.affine_inverse() * child.global_transform * child.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
func model(parent: Node3D, path: String, size: Vector3, at: Vector3):
	var node: Node3D = load(KIT + path).instantiate()
	parent.add_child(node)
	var box := bounds(node)
	var factor := size / box.size
	node.scale = factor
	node.position = at - Vector3(box.get_center().x, box.position.y, box.get_center().z) * factor
	own(node)
	return node
func make_sign(parent: Node3D, text: String, at: Vector3, color := Color("#b8edff")):
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 48
	label.outline_size = 5
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add(parent,label,"Sign")
	return label
func collision(parent: Node3D, size: Vector3, at := Vector3.ZERO):
	var node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	node.shape = shape
	node.position = at
	add(parent,node,"CollisionShape3D")
func clear_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.free()
func save_scene(path: String):
	remove_text(scene)
	# The starfield script creates fresh render data on load.
	scene.get_node("SpaceScenery/Stars").multimesh = null
	for child in scene.get_children():
		own(child)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed,path) == OK)
func laser(index: int, cycle: float, travel := Vector3.ZERO):
	var pad := platforms[index]
	var node := Area3D.new()
	node.position = Vector3(0,0.7,0.5)
	node.set_script(load("res://Scripts/laser_hazard.gd"))
	node.cycle = cycle
	node.travel = travel
	node.phase = 1.0 if index == 7 else 0.0
	mesh_box(node,"Beam",Vector3(widths[index]-0.25,0.16,0.20),Vector3.ZERO,mat(Color("#ff3c55"),true))
	collision(node,Vector3(widths[index]-0.25,0.16,0.20))
	var label: Label3D = make_sign(node,"DANGER",Vector3(0,0.85,0),Color("#ff647a"))
	label.name = "State"
	add(pad,node,"LaserGate")
	for side in [-1.0,1.0]:
		mesh_box(pad,"Emitter",Vector3(0.22,1.1,0.32),Vector3(side*(widths[index]*0.5-0.1),0.55,0.5),mat(Color("#7c344e")))
func build():
	scene = load("res://Scenes/demo_scene.tscn").instantiate()
	root.add_child(scene)
	# Save tighter, contact-only pickup colliders in level 1 as well.
	save_scene("res://Scenes/demo_scene.tscn")
	var cell_template = scene.get_node("Coins/Coin").duplicate()
	clear_children(scene.get_node("Coins"))
	clear_children(scene.get_node("Platforms"))
	scene.name = "ReactorRun"
	var hud = scene.get_node("UserInterface/GameUI")
	hud.level_number = 2
	hud.required_cells = 8
	hud.extraction_position = positions[11]
	hud.next_scene = ""
	var pad_parent = scene.get_node("Platforms")
	for i in positions.size():
		var moving: bool = i in [1,3,6,8,10]
		var pad: Node3D
		if moving:
			var body := AnimatableBody3D.new()
			body.sync_to_physics = false
			body.set_script(load("res://Scripts/moving_platform.gd"))
			body.travel = Vector3(0.9,0,0) if i in [1,6,10] else Vector3(0,0,0.65)
			body.period = 6.0 if i < 5 else 5.0
			pad = body
		else:
			pad = StaticBody3D.new()
		pad.position = positions[i]
		add(pad_parent,pad,"Pad%02d" % i)
		platforms.append(pad)
		collision(pad,Vector3(widths[i],0.5,widths[i]),Vector3(0,-0.25,0))
		model(pad,"Base Large/Base_Large.fbx",Vector3(widths[i],1.4,widths[i]),Vector3(0,-1.5,0))
		mesh_box(pad,"Deck",Vector3(widths[i],0.12,widths[i]),Vector3(0,-0.06,0),mat(Color("#21354f")))
		var rim := mat(Color("#5bf2a5") if i == 5 else (Color("#b588ff") if moving else Color("#ffbc69")),true)
		for side in [-1.0,1.0]:
			mesh_box(pad,"RimX",Vector3(0.045,0.03,widths[i]),Vector3(side*widths[i]*0.5,0.02,0),rim)
			mesh_box(pad,"RimZ",Vector3(widths[i],0.03,0.045),Vector3(0,0.02,side*widths[i]*0.5),rim)
		make_sign(pad,"%02d" % (i+1),Vector3(-widths[i]*0.35,0.45,-widths[i]*0.35)).font_size = 24
	var pickup_indices := [1,2,3,4,6,7,8,10]
	for i in pickup_indices.size():
		var index: int = pickup_indices[i]
		var coin: Area3D = cell_template.duplicate()
		coin.name = "Cell%02d" % (i+1)
		coin.position = positions[index] + Vector3(0,0.7,-0.55)
		coin.scale = Vector3.ONE
		coin.set("platform_path",NodePath("../../Platforms/Pad%02d" % index))
		scene.get_node("Coins").add_child(coin)
		own(coin)
	cell_template.free()
	laser(2,5.0)
	laser(7,4.4)
	laser(9,5.2,Vector3(0,0,1.0))
	for side in [-1.0,1.0]:
		var crate := StaticBody3D.new()
		crate.position = Vector3(side*1.45,0,0)
		add(platforms[4],crate,"CargoObstacle")
		collision(crate,Vector3(1.1,0.85,1.1),Vector3(0,0.425,0))
		model(crate,"Pickup Crate/Pickup_Crate.fbx",Vector3(1.1,0.85,1.1),Vector3.ZERO)
	var checkpoint := Area3D.new()
	checkpoint.set_script(load("res://Scripts/checkpoint.gd"))
	checkpoint.spawn_at = positions[5] + Vector3(0,1.0,0)
	collision(checkpoint,Vector3(5.5,2,5.5),Vector3(0,1.0,0))
	make_sign(checkpoint,"CHECKPOINT",Vector3(0,1.8,0),Color("#74ffb4"))
	add(platforms[5],checkpoint,"Checkpoint")
	var player = scene.get_node("Player")
	player.position = positions[0] + Vector3(0,1.5,0)
	scene.get_node("Extras/SpawnPosition").position = player.position
	var death_shape := BoxShape3D.new()
	death_shape.size = Vector3(160,17,180)
	scene.get_node("DeadZone/CollisionShape3D").shape = death_shape
	scene.get_node("DeadZone/CollisionShape3D").position = Vector3(0,-9,-25)
	var scenery = scene.get_node("SpaceScenery")
	for child in scenery.get_children():
		if child is Label3D or "Spaceship" in child.name:
			scenery.remove_child(child)
			child.free()
	model(scenery,"Spaceship/Spaceship_RaeTheRedPanda.fbx",Vector3(3.4,1.3,3.2),positions[11]+Vector3(0,0.06,-1.2))
	make_sign(scenery,"SECTOR 02 / REACTOR RUN",Vector3(0,9,-15))
	make_sign(scenery,"EXTRACTION",positions[11]+Vector3(0,2.6,-1.2))
	make_sign(platforms[0],"8 CELLS / TIME YOUR JUMPS",Vector3(-2,0.8,-2)).font_size = 24
	save_scene("res://Scenes/level_2.tscn")
	print("LEVEL 2 SAVED: 12 pads, 5 moving, 8 cells, 3 timed laser gates, 2 cargo obstacles, midpoint checkpoint.")
	quit()

func remove_text(parent: Node):
	for child in parent.get_children():
		if child is Label or child is Label3D or child is RichTextLabel or (child is Panel and child.get_parent().name == "GameUI"):
			parent.remove_child(child)
			child.free()
		else:
			remove_text(child)