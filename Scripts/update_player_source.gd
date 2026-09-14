extends SceneTree
func _initialize():
	call_deferred("update_player")
func own_children(node: Node, owner_root: Node):
	for child in node.get_children():
		child.scene_file_path = ""
		child.owner = owner_root
		own_children(child, owner_root)
func update_player():
	var level = load("res://Scenes/demo_scene.tscn").instantiate()
	var player = level.get_node("Player")
	level.remove_child(player)
	player.owner = null
	player.scene_file_path = ""
	player.position = Vector3.ZERO
	player.get_node("Gimbal").position = Vector3(0,1,0)
	var skeletons = player.find_children("*","Skeleton3D",true,false)
	assert(skeletons.size() == 1)
	var rig: Skeleton3D = skeletons[0]
	assert(rig.find_bone("mixamorig_Hips") >= 0)
	for data in [["mixamorig_LeftArm",1.12],["mixamorig_RightArm",-1.12]]:
		var index := rig.find_bone(data[0])
		var axis := rig.get_bone_global_rest(index).basis.inverse() * Vector3.FORWARD
		rig.set_bone_pose_rotation(index, rig.get_bone_rest(index).basis.get_rotation_quaternion() * Quaternion(axis.normalized(),data[1]))
	own_children(player,player)
	var packed := PackedScene.new()
	assert(packed.pack(player) == OK)
	var uid := ResourceLoader.get_resource_uid("res://Scenes/player.tscn")
	assert(ResourceSaver.save(packed,"res://Scenes/player.tscn") == OK)
	if uid != -1:
		assert(ResourceSaver.set_uid("res://Scenes/player.tscn",uid) == OK)
	player.free()
	level.free()
	var saved = ResourceLoader.load("res://Scenes/player.tscn","",ResourceLoader.CACHE_MODE_REPLACE).instantiate()
	assert(saved.has_node("gobot/Model"))
	assert(saved.get_node("gobot").find_children("*","Skeleton3D",true,false).size() == 1)
	assert(saved.find_children("Gobot","MeshInstance3D",true,false).is_empty())
	root.add_child(saved)
	await process_frame
	assert(saved.model == saved.get_node("gobot"))
	assert(saved.animation.has_animation("Jump"))
	print("PASS: player.tscn now contains the astronaut, working rig, camera, collider and jump animations; original scene UID retained.")
	saved.free()
	quit()
