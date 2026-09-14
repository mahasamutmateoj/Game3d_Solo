# Controller based on the SD Studios starter. Space adaptation.
extends CharacterBody3D
@export_category("Player Properties")
@export var move_speed: float = 6.0
@export var jump_force: float = 6.0
@export var follow_lerp_factor: float = 4.0
@export var jump_limit: int = 2
var can_double_jump := false
var is_grounded := false
var jumps_used := 0
var respawn_grace := 0.0
@onready var model = $gobot
@onready var animation = $gobot/AnimationPlayer
@onready var spring_arm = %Gimbal
@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0

func _physics_process(delta):
	respawn_grace = maxf(0.0, respawn_grace - delta)
	is_grounded = is_on_floor()
	if is_grounded:
		jumps_used = 0
		can_double_jump = jump_limit > 1
	var direction := Vector3(Input.get_axis("move_left", "move_right"), 0, Input.get_axis("move_forward", "move_back"))
	direction = direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if not is_grounded:
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump"):
		if is_grounded:
			perform_jump()
		elif can_double_jump:
			perform_flip_jump()
	move_and_slide()
	if is_moving():
		model.rotation.y = lerp_angle(model.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-12.0 * delta))
	spring_arm.position = spring_arm.position.lerp(position, 1.0 - exp(-follow_lerp_factor * delta))
	player_animations()

func perform_jump():
	jumps_used = 1
	can_double_jump = jumps_used < jump_limit
	velocity.y = jump_force
	AudioManager.jump_sfx.pitch_scale = 1.12
	AudioManager.jump_sfx.play()
	animation.play("Jump", 0.12)

func perform_flip_jump():
	# Keep the old method name for compatibility, but use a stable boost pose.
	jumps_used += 1
	can_double_jump = jumps_used < jump_limit
	velocity.y = jump_force
	AudioManager.jump_sfx.pitch_scale = 0.9
	AudioManager.jump_sfx.play()
	animation.play("Jump", 0.12)

func is_moving():
	return Vector2(velocity.x, velocity.z).length() > 0.1

func player_animations():
	var walking: bool = is_on_floor() and is_moving()
	particle_trail.emitting = walking
	footsteps.stream_paused = not walking
	if is_on_floor():
		animation.play("Run" if walking else "Idle", 0.15)

func respawn(at: Vector3):
	global_position = at
	velocity = Vector3.ZERO
	respawn_grace = 0.8
	jumps_used = 0
	can_double_jump = true
	spring_arm.global_position = at
	animation.play("Idle", 0.1)