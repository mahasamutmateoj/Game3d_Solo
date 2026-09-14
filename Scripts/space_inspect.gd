extends SceneTree

func _initialize():
	call_deferred("inspect")

func inspect():
	for path in ["res://Assets/Astronaut/AstronautRigged.fbx", "res://Assets/SpaceKit/Base Large/Base_Large.fbx", "res://Assets/SpaceKit/Connector/Connector.fbx"]:
		var scene = load(path)
		if scene == null:
			continue
		var node = scene.instantiate()
		root.add_child(node)
		print("ASSET ", path)
		walk(node)
		node.free()
	quit()

func walk(node):
	if node is MeshInstance3D:
		print("MESH ", node.name, " bounds=", node.get_aabb(), " transform=", node.global_transform)
		for i in node.mesh.get_surface_count():
			var mat = node.mesh.surface_get_material(i)
			print("MAT ", mat.resource_name if mat else "none", " tex=", mat.albedo_texture if mat is StandardMaterial3D else "")
	if node is Skeleton3D:
		for i in node.get_bone_count():
			if i in [0, 5, 9, 18, 28, 34]: print("BONE ", node.get_bone_name(i), " rest=", node.get_bone_global_rest(i))
	if node is AnimationPlayer:
		print("ANIMS ", node.get_animation_list())
		for key in node.get_animation_list(): print(key, ' length=', node.get_animation(key).length)
	for child in node.get_children():
		walk(child)

