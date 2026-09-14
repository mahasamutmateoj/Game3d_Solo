extends SceneTree
func _initialize():
	call_deferred("apply")

func own(node, scene):
	node.scene_file_path = ""
	node.owner = scene
	for child in node.get_children():
		own(child, scene)

func apply():
	var scene = load("res://Scenes/demo_scene.tscn").instantiate()
	root.add_child(scene)
	var names := ["PlatformBlue", "PlatformBlue2", "PlatformBlue3", "PlatformBlue4"]
	var cells := ["Coin", "Coin2", "Coin4", "Coin5"]
	for i in names.size():
		var old = scene.get_node("Platforms/" + names[i])
		if old is AnimatableBody3D:
			continue
		var parent = old.get_parent()
		var original: Transform3D = old.transform
		var body := AnimatableBody3D.new()
		body.sync_to_physics = false
		parent.remove_child(old)
		body.name = names[i]
		parent.add_child(body)
		body.position = original.origin
		body.set_script(load("res://Scripts/moving_platform.gd"))
		body.travel = Vector3(1.0, 0, 0) if i in [0, 3] else Vector3(0, 0, 0.65)
		body.period = 10.0 + i
		var collider = old.get_node("StaticBody3D/CollisionShape3D")
		var shape := ConcavePolygonShape3D.new()
		var points: PackedVector3Array = collider.shape.get_faces()
		var conversion: Transform3D = Transform3D(original.basis, Vector3.ZERO) * old.get_node("StaticBody3D").transform * collider.transform
		for j in points.size():
			points[j] = conversion * points[j]
		shape.set_faces(points)
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = shape
		body.add_child(collision)
		var old_body = old.get_node("StaticBody3D")
		old.remove_child(old_body)
		old_body.free()
		old.name = "Visuals"
		body.add_child(old)
		old.transform = Transform3D(original.basis, Vector3.ZERO)
		var coin = scene.get_node("Coins/" + cells[i])
		coin.set("platform_path", NodePath("../../Platforms/" + names[i]))
	for child in scene.get_children():
		own(child, scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://Scenes/demo_scene.tscn") == OK)
	print("MOTION SAVED: four moving platforms; launch, rest and extraction pads stay stationary.")
	quit()
