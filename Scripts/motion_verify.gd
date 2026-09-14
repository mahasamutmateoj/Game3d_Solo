extends SceneTree
func _initialize():
	call_deferred("verify")
func frames(count: int):
	for i in count:
		await physics_frame
		await process_frame
func verify():
	var scene = load("res://Scenes/demo_scene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(90)
	var player = scene.get_node("Player")
	var platform = scene.get_node("Platforms/PlatformBlue")
	var coin = scene.get_node("Coins/Coin")
	# Disable pickup monitoring only for the carry check.
	coin.monitoring = false
	coin.get_node("Range").monitoring = false
	var offset: Vector3 = coin.global_position - platform.global_position
	player.position = platform.global_position + Vector3(1.5, 1.3, 0)
	player.velocity = Vector3.ZERO
	await frames(35)
	print("LAND player=", player.position, " platform=", platform.position, " velocity=", player.velocity, " floor=", player.is_on_floor(), " shape=", platform.get_node("CollisionShape3D").shape.get_faces().slice(0, 3)); assert(player.is_on_floor(), "Must land on moving platform")
	var relative: Vector3 = player.global_position - platform.global_position
	var initial_platform: Vector3 = platform.global_position
	await frames(100)
	var drift: Vector3 = (player.global_position - platform.global_position) - relative
	print("RIDE platform travel=", platform.global_position.distance_to(initial_platform), " relative drift=", drift.length())
	assert(platform.global_position.distance_to(initial_platform) > 0.2, "Platform must move")
	assert(drift.length() < 0.1, "Rider must travel with platform")
	print("CELL drift=", (coin.global_position - platform.global_position).x - offset.x, " path=", coin.platform_path); assert(absf((coin.global_position - platform.global_position).x - offset.x) < 0.03, "Cell must follow platform")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await frames(8)
	assert(not player.is_on_floor() and player.velocity.y > 0, "Must jump off moving platform")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	assert(player.velocity.y > 4.0, "Stationary double jump must work")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Windows/Temp/motion-jump.png")
	var vy: float = player.velocity.y
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	assert(player.velocity.y < vy, "Third jump must be blocked")
	assert(player.scale.is_equal_approx(Vector3.ONE), "Physics body must not stretch")
	assert(absf(player.get_node("gobot/Model").rotation.x) < 0.01, "Jump must not somersault")
	await frames(50)
	print("PASS: platform motion, rider carry, moving pickup, jump-off, stationary double jump, no third jump, stable scale and pose.")
	quit()
