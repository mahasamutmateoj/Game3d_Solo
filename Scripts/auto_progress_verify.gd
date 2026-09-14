extends SceneTree
func _initialize():
	call_deferred("verify")
func frames(n: int):
	for i in n:
		await physics_frame
		await process_frame
func check_text(node: Node):
	assert(not (node is Label or node is Label3D or node is RichTextLabel), "No text nodes may remain")
	for child in node.get_children():
		check_text(child)
func verify():
	var game = load("res://Scenes/demo_scene.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(45)
	check_text(game)
	var player = game.get_node("Player")
	player.position = Vector3(18.02,10,2)
	player.velocity = Vector3.ZERO
	await frames(40)
	assert(current_scene == game, "Ship alone must not advance")
	for cell in game.get_node("Coins").get_children():
		player.position = cell.global_position - Vector3(0,0.5,0)
		player.velocity = Vector3.ZERO
		await frames(10)
	assert(root.get_node("GameManager").score == 5)
	await frames(15)
	assert(current_scene == game, "All cells without ship must not advance")
	player.position = Vector3(18.02,10,2)
	player.velocity = Vector3.ZERO
	await frames(45)
	assert(current_scene.scene_file_path == "res://Scenes/level_2.tscn", "All cells and ship must automatically advance")
	game = current_scene
	check_text(game)
	assert(root.get_node("GameManager").score == 0, "New level resets score")
	await frames(30)
	player = game.get_node("Player")
	var checkpoint = game.get_node("Platforms/Pad05/Checkpoint")
	player.position = checkpoint.spawn_at
	player.velocity = Vector3.ZERO
	await frames(25)
	assert(checkpoint.activated)
	for hazard in get_nodes_in_group("Hazards"):
		hazard.set_physics_process(false)
	for cell in game.get_node("Coins").get_children():
		player.position = cell.global_position - Vector3(0,0.5,0)
		player.velocity = Vector3.ZERO
		await frames(10)
	player.position = Vector3(0.2,8,-55)
	player.velocity = Vector3.ZERO
	await frames(30)
	assert(current_scene == game and game.get_node("UserInterface/GameUI").complete, "Final level finishes without loading a nonexistent level")
	assert(game.get_node("UserInterface/GameUI/WinOverlay/WinLabel").text == "You win", "Final completion must show You win")
	print("PASS: You win banner; no text in both levels; ship/collectible gating; automatic transition with no key input; score reset; checkpoint; final-level completion.")
	quit()
