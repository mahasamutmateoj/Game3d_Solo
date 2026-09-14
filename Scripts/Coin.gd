extends Area3D
@export var amplitude: float = 0.16
@export var frequency: float = 4.0
@export var platform_path: NodePath
var time_passed := 0.0
var initial_position := Vector3.ZERO
var platform: Node3D
var platform_origin := Vector3.ZERO
var collected := false

func _ready():
	initial_position = global_position
	platform = get_node_or_null(platform_path) as Node3D if not platform_path.is_empty() else null
	if platform:
		platform_origin = platform.global_position
	collision_layer = 0
	collision_mask = 1
	var collider := get_node("CollisionShape3D") as CollisionShape3D
	collider.scale = Vector3.ONE
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	collider.shape = shape
	# The legacy proximity area must never shrink or attract the collectible.
	var proximity := get_node_or_null("Range") as Area3D
	if proximity:
		proximity.monitoring = false
		proximity.monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if collected:
		return
	time_passed += delta
	var target := initial_position
	if is_instance_valid(platform):
		target += platform.global_position - platform_origin
	target.y += amplitude * sin(frequency * time_passed)
	global_position = target
	rotate_y(delta * 1.8)

func _on_body_entered(body):
	if collected or not body.is_in_group("Player"):
		return
	collected = true
	GameManager.add_score()
	AudioManager.coin_sfx.play()
	hide()
	set_deferred("monitoring", false)
	queue_free()

func _on_range_body_entered(_body):
	pass
