extends SceneTree
var game: Node3D

func _initialize():
	call_deferred("run_checks")

func settle(frames: int):
	for i in frames:
		await physics_frame
		await process_frame

func run_checks():
	game = load("res://Scenes/demo_scene.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle(90)
	var player = game.get_node("Player")
	print("PLAYER ", player.global_position, " floor=", player.is_on_floor())
	print("ASTRONAUT RIGS ", player.get_node("gobot").find_children("*", "Skeleton3D", true, false).size())
	for coin in game.get_node("Coins").get_children():
		for shape in coin.find_children("*", "CollisionShape3D", true, false):
			print("COIN SHAPE ", shape.get_path(), " ", shape.shape.get_class())
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Windows/Temp/space-preview.png")
	assert(player.is_on_floor(), "Player must land on launch pad")
	var start_y: float = player.position.y
	Input.action_press("jump")
	await settle(2)
	Input.action_release("jump")
	await settle(8)
	print("JUMP y=", player.position.y, " baseline=", start_y, " velocity=", player.velocity); assert(player.position.y > start_y + 0.25, "First jump must rise")
	Input.action_press("move_forward")
	Input.action_press("jump")
	await settle(2)
	Input.action_release("jump")
	assert(player.velocity.y > 0, "Second jump must add upward velocity")
	Input.action_release("move_forward")
	await settle(60)
	player.position = Vector3(0, -5, 0)
	player.velocity = Vector3.ZERO
	await settle(20)
	assert(player.position.y > 0, "Fall must respawn")
	var manager = root.get_node("GameManager")
	for coin in game.get_node("Coins").get_children():
		player.position = coin.global_position
		player.velocity = Vector3.ZERO
		await settle(8)
	print("SCORE ", manager.score)
	assert(manager.score == 5, "All five energy cells must be collectable")
	player.position = Vector3(18.02, 10.0, 2.0)
	await settle(30)
	assert(game.get_node("UserInterface/GameUI").complete, "Extraction must complete mission")
	print("PASS: spawn, astronaut rig, first jump, double jump, respawn, five pickups, extraction")
	quit()
