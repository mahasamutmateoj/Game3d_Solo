extends SceneTree
func _initialize():
	call_deferred("verify")
func frames(count: int):
	for i in count:
		await physics_frame
		await process_frame
func verify():
	var game = load("res://Scenes/demo_scene.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(60)
	var player = game.get_node("Player")
	var manager = root.get_node("GameManager")
	var coin = game.get_node("Coins/Coin3")
	player.position = coin.position + Vector3(1.6,-0.5,0)
	player.velocity = Vector3.ZERO
	await frames(100)
	assert(is_instance_valid(coin) and coin.scale.is_equal_approx(Vector3.ONE) and coin.visible, "Nearby pickup must stay visible and full size")
	assert(manager.score == 0, "Proximity must not collect")
	print("PASS: near pickup for 100 frames, still visible, score zero.")
	player.position = coin.global_position - Vector3(0,0.5,0)
	player.velocity = Vector3.ZERO
	await frames(8)
	assert(not is_instance_valid(coin) and manager.score == 1, "Contact must collect once")
	await frames(15)
	assert(manager.score == 1)
	for remaining in game.get_node("Coins").get_children():
		player.position = remaining.global_position - Vector3(0,0.5,0)
		player.velocity = Vector3.ZERO
		await frames(10)
	assert(manager.score == 5)
	player.position = Vector3(18.02,10,2)
	player.velocity = Vector3.ZERO
	await frames(40)
	var hud = game.get_node("UserInterface/GameUI")
	assert(hud.complete, "Level 1 extraction")
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	hud._unhandled_input(event)
	await frames(8)
	game = current_scene
	assert(game.scene_file_path == "res://Scenes/level_2.tscn", "Enter must load level 2")
	player = game.get_node("Player")
	hud = game.get_node("UserInterface/GameUI")
	assert(manager.score == 0 and hud.required_cells == 8)
	assert(game.get_node("Platforms").get_child_count() == 12)
	print("PASS: level 1 contact pickups, extraction, Enter transition and level 2 score reset.")
	await frames(45)
	assert(player.is_on_floor())
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Windows/Temp/level2-preview.png")
	var checkpoint = game.get_node("Platforms/Pad05/Checkpoint")
	player.position = checkpoint.spawn_at
	player.velocity = Vector3.ZERO
	await frames(30)
	assert(checkpoint.activated, "Checkpoint must activate on entry")
	var spawn: Vector3 = game.get_node("Extras/SpawnPosition").global_position
	assert(spawn.is_equal_approx(checkpoint.spawn_at))
	var laser = game.get_node("Platforms/Pad02/LaserGate")
	laser.elapsed = 3.0
	player.respawn_grace = 0.0
	player.position = laser.global_position - Vector3(0,0.65,0)
	player.velocity = Vector3.ZERO
	await frames(8)
	assert(player.position.distance_to(spawn) > 5.0, "Inactive laser must be safe")
	laser.elapsed = 0.0
	await frames(8)
	assert(player.position.distance_to(spawn) < 1.5 and player.respawn_grace > 0.0, "Active laser must respawn at checkpoint")
	player.respawn_grace = 0.0
	player.position = Vector3(10,-5,-35)
	player.velocity = Vector3.ZERO
	await frames(12)
	assert(player.position.distance_to(spawn) < 1.5, "Falling must return to checkpoint")
	print("PASS: checkpoint, inactive laser safe, active laser respawn, fall respawn.")
	# Test pickup/completion independently of timed obstacles.
	for hazard in get_nodes_in_group("Hazards"):
		hazard.set_physics_process(false)
		hazard.active = false
	for cell in game.get_node("Coins").get_children():
		player.position = cell.global_position - Vector3(0,0.5,0)
		player.velocity = Vector3.ZERO
		await frames(10)
	assert(manager.score == 8, "All level 2 pickups collectable")
	player.position = hud.extraction_position + Vector3(0,0.5,0)
	player.velocity = Vector3.ZERO
	await frames(35)
	assert(hud.complete and hud.next_scene.is_empty(), "Level 2 final completion")
	print("PASS: all eight level 2 cells and final extraction.")
	quit()
