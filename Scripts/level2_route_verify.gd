extends SceneTree
var game: Node3D
var player: CharacterBody3D
func _initialize():
	call_deferred("verify")
func tick():
	await physics_frame
	await process_frame
func wait_frames(n: int):
	for i in n:
		await tick()
func release():
	for key in ["move_left","move_right","move_forward","move_back","jump"]:
		Input.action_release(key)
func steer(direction: Vector3):
	Input.action_press("move_right",maxf(direction.x,0.0))
	Input.action_press("move_left",maxf(-direction.x,0.0))
	Input.action_press("move_back",maxf(direction.z,0.0))
	Input.action_press("move_forward",maxf(-direction.z,0.0))
func verify():
	game = load("res://Scenes/level_2.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	player = game.get_node("Player")
	await wait_frames(40)
	for hazard in get_nodes_in_group("Hazards"):
		hazard.set_physics_process(false)
		hazard.active = false
	var widths := [8.0,4.6,4.6,4.2,4.2,6.0,4.0,4.2,4.0,5.0,4.5,8.0]
	for index in 11:
		release()
		var source = game.get_node("Platforms/Pad%02d" % index)
		var destination = game.get_node("Platforms/Pad%02d" % (index+1))
		var direction: Vector3 = destination.global_position - source.global_position
		direction.y = 0
		direction = direction.normalized()
		var edge: Vector3 = direction * (widths[index]*0.5-0.9) / maxf(absf(direction.x),absf(direction.z))
		player.position = source.global_position + edge + Vector3(0,0.35,0)
		player.velocity = Vector3.ZERO
		player.get_node("Gimbal").rotation = Vector3.ZERO
		await wait_frames(22)
		assert(player.is_on_floor(),"Jump setup must be grounded")
		var landed := false
		for frame in 100:
			var toward: Vector3 = destination.global_position - player.global_position
			toward.y = 0
			steer(toward.normalized())
			if frame in [0,18]:
				Input.action_press("jump")
			if frame in [2,20]:
				Input.action_release("jump")
			await tick()
			var local: Vector3 = player.global_position - destination.global_position
			if frame > 10 and player.is_on_floor() and absf(local.x) < widths[index+1]*0.5 and absf(local.z) < widths[index+1]*0.5 and absf(local.y) < 0.1:
				landed = true
				break
		release()
		print("JUMP ",index," -> ",index+1," landed=",landed)
		assert(landed,"Adjacent platform must be reachable with double jump")
	print("PASS: all 11 level 2 gaps reachable with actual movement and double jump; moving platforms active, lasers disabled for traversal isolation.")
	quit()
