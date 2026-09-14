extends SceneTree
func _initialize():
	call_deferred("verify")
func verify():
	for i in 3:
		var packed = ResourceLoader.load("res://Scenes/demo_scene.tscn", "", ResourceLoader.CACHE_MODE_REPLACE)
		var scene = packed.instantiate()
		root.add_child(scene)
		await process_frame
		var field: MultiMesh = scene.get_node("SpaceScenery/Stars").multimesh
		assert(field.instance_count == 900)
		assert(field.transform_format == MultiMesh.TRANSFORM_3D)
		assert(scene.get_node("Platforms/PlatformBlue") is AnimatableBody3D)
		scene.free()
		await process_frame
	print("PASS: three scene reloads; 900 3D stars each time; moving platforms retained.")
	quit()
